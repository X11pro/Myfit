part of 'manual_food_entry_screen.dart';

extension _ReviewPresentation on _ManualFoodEntryScreenState {
  List<String> get _ingredients => _ingredientsController.text
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  Future<String?> _reviewInput(
      BuildContext context, String label, String initial,
      {bool number = false}) async {
    var draft = initial;
    return showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(label),
                content: TextFormField(
                    initialValue: initial,
                    autofocus: true,
                    keyboardType:
                        number ? TextInputType.number : TextInputType.text,
                    inputFormatters: number
                        ? [FilteringTextInputFormatter.digitsOnly]
                        : null,
                    onChanged: (v) => draft = v),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child:
                          Text(MaterialLocalizations.of(c).cancelButtonLabel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, draft.trim()),
                      child: Text(MaterialLocalizations.of(c).okButtonLabel))
                ]));
  }

  Widget _reviewScreen(BuildContext c, AppStrings s, int? target) {
    final en = s.isEnglish, t = Theme.of(c).textTheme;
    final ingredients = _ingredients;
    final grams = int.tryParse(_mealWeightController.text) ?? 0;
    final categories = {
      'breakfast': s.mealTypeBreakfast,
      'lunch': s.mealTypeLunch,
      'dinner': s.mealTypeDinner,
      'snack': s.mealTypeSnack
    };
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final macros = [
      (s.protein, _proteinController, DashboardTheme.primary, 4),
      (s.carbs, _carbsController, const Color(0xffd4ffec), 4),
      (s.fat, _fatController, DashboardTheme.warning, 9),
      (s.fiberLabel, _fiberController, DashboardTheme.mutedText, 0)
    ];
    final energy = macros
        .map((m) => (int.tryParse(m.$2.text) ?? 0) * m.$4)
        .reduce((a, b) => a + b);
    final busy = _isAnalyzing || _confirming;
    void weight(int g) {
      if (g > 0) _changeReview(() => _mealWeightController.text = '$g');
    }

    Future<void> editIngredient(int? i) async {
      final result = await _reviewInput(
          c, s.ingredientsLabel, i == null ? '' : ingredients[i]);
      if (result == null || result.isEmpty || !mounted) return;
      if (i == null) {
        ingredients.add(result);
      } else {
        ingredients[i] = result;
      }
      _changeReview(() => _ingredientsController.text = ingredients.join('\n'));
    }

    Widget panel(List<Widget> children) => Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children)));
    final portionPattern =
        RegExp(r'\s*\((\d+)\s*g\)\s*$', caseSensitive: false);
    void ingredientWeight(int i, int value) {
      if (value <= 0) return;
      final name = ingredients[i].replaceFirst(portionPattern, '').trim();
      ingredients[i] = '$name ($value g)';
      _changeReview(() => _ingredientsController.text = ingredients.join('\n'));
    }

    Widget ingredientCard(int i, String item) {
      final parsed = portionPattern.firstMatch(item);
      final quantity = int.tryParse(parsed?.group(1) ?? '');
      return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: panel([
            Row(children: [
              Expanded(
                  child: Text(item.replaceFirst(portionPattern, ''),
                      style: t.titleMedium)),
              IconButton(
                  tooltip: en ? 'Edit' : 'Editar',
                  onPressed: busy ? null : () => editIngredient(i),
                  icon: const Icon(Icons.edit_outlined, size: 18)),
              IconButton(
                  tooltip: en ? 'Remove' : 'Eliminar',
                  onPressed: busy
                      ? null
                      : () => _changeReview(() => _ingredientsController.text =
                          (ingredients..removeAt(i)).join('\n')),
                  icon: const Icon(Icons.delete_outline, size: 18))
            ]),
            const Divider(),
            Row(children: [
              Expanded(
                  child: Text(
                      en
                          ? 'Portion for re-analysis'
                          : 'Porción para reanálisis',
                      style: t.labelSmall)),
              if (quantity != null)
                IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: busy || quantity <= 5
                        ? null
                        : () => ingredientWeight(i, quantity - 5)),
              TextButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final v = await _reviewInput(
                              c, s.mealWeightLabel, quantity?.toString() ?? '',
                              number: true);
                          if (mounted) {
                            ingredientWeight(i, int.tryParse(v ?? '') ?? 0);
                          }
                        },
                  child: Text(quantity == null
                      ? (en ? 'Set grams' : 'Indicar gramos')
                      : '$quantity g')),
              if (quantity != null)
                IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed:
                        busy ? null : () => ingredientWeight(i, quantity + 5))
            ])
          ]));
    }

    final help = en
        ? 'Photo analysis estimates the whole meal. Check the ingredients and portion before logging.'
        : 'El análisis estima el plato completo. Revisa los ingredientes y la porción antes de guardar.';
    Widget metric(String name, TextEditingController field, String unit,
            Color color) =>
        InkWell(
            onTap: busy
                ? null
                : () async {
                    final v =
                        await _reviewInput(c, name, field.text, number: true);
                    if (v != null && int.tryParse(v) != null && mounted) {
                      _changeReview(() => field.text = v);
                      _resetReviewBaseline();
                    }
                  },
            child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: DashboardTheme.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(10),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: t.labelMedium),
                      Text('${field.text} $unit',
                          style: t.titleLarge?.copyWith(color: color)),
                      Text(en ? 'Estimated amount' : 'Cantidad estimada',
                          style: t.bodySmall)
                    ])));
    return Scaffold(
        appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Myfit'),
            actions: [
              TextButton(
                  onPressed: () => ref
                      .read(appLanguageProvider.notifier)
                      .state = en ? AppLanguage.es : AppLanguage.en,
                  child: const Text('EN / ES')),
              IconButton(
                  tooltip: s.progressScreenTitle,
                  onPressed: () => c.push('/dashboard/progress'),
                  icon: const Icon(Icons.trending_up)),
              IconButton(
                  tooltip: s.accountTabLabel,
                  onPressed: () => c.push('/auth'),
                  icon: const Icon(Icons.account_circle_outlined))
            ]),
        bottomNavigationBar: MyfitBottomNav(strings: s, index: 2),
        body: SafeArea(
            top: false,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(children: [
                    IconButton(
                        tooltip: s.backButtonTooltip,
                        onPressed: busy
                            ? null
                            : () => _changeReview(() => _review = false),
                        icon: const Icon(Icons.arrow_back)),
                    Expanded(
                        child: Text(
                            en
                                ? 'Review Meal Analysis'
                                : 'Revisar análisis de comida',
                            textAlign: TextAlign.center,
                            style: t.titleMedium)),
                    IconButton(
                        tooltip: MaterialLocalizations.of(c)
                            .aboutListTileTitle('Myfit'),
                        icon: const Icon(Icons.help_outline),
                        onPressed: () => showDialog<void>(
                            context: c,
                            builder: (ctx) =>
                                AlertDialog(content: Text(help), actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text(MaterialLocalizations.of(ctx)
                                          .okButtonLabel))
                                ])))
                  ]),
                  panel([
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                              backgroundColor: DashboardTheme.surfaceMuted,
                              foregroundColor: DashboardTheme.primary,
                              child: Icon(Icons.auto_awesome)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    en
                                        ? 'AI Estimation Complete'
                                        : 'Estimación completada',
                                    style: t.titleLarge),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: DashboardTheme.primary
                                            .withValues(alpha: .12),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Text(
                                        '${(_confidence! * 100).round()}% ${s.confidence}',
                                        style: t.labelMedium?.copyWith(
                                            color: DashboardTheme.primary))),
                                const SizedBox(height: 4),
                                Text(
                                    en
                                        ? 'Estimated from your meal photo.'
                                        : 'Estimación basada en tu foto.',
                                    style: t.bodySmall)
                              ]))
                        ])
                  ]),
                  const SizedBox(height: 16),
                  AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(fit: StackFit.expand, children: [
                            MealPhotoView(
                                photoPath: _photoPath!,
                                width: double.infinity,
                                height: double.infinity),
                            const DecoratedBox(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                  Colors.transparent,
                                  Colors.black54
                                ]))),
                            Positioned(
                                right: 8,
                                top: 8,
                                child: PopupMenuButton<ImageSource>(
                                    enabled: !busy,
                                    onSelected: _pickPhoto,
                                    itemBuilder: (_) => [
                                          PopupMenuItem(
                                              value: ImageSource.camera,
                                              child: Text(s.addPhotoButton)),
                                          PopupMenuItem(
                                              value: ImageSource.gallery,
                                              child: Text(s.choosePhotoButton))
                                        ],
                                    child: Chip(
                                        avatar: const Icon(
                                            Icons.camera_alt_outlined,
                                            size: 16),
                                        label: Text(en
                                            ? 'Retake Photo'
                                            : 'Cambiar foto')))),
                            Positioned(
                                left: 10,
                                right: 10,
                                bottom: 8,
                                child:
                                    Wrap(spacing: 4, runSpacing: 3, children: [
                                  for (final item in ingredients.take(4))
                                    Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: DashboardTheme
                                                .backgroundSecondary,
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Text(item,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: t.labelSmall))
                                ]))
                          ]))),
                  const SizedBox(height: 16),
                  panel([
                    Text(en ? 'MEAL TITLE' : 'NOMBRE', style: t.labelSmall),
                    TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            suffixIcon: Icon(Icons.edit_outlined, size: 18))),
                    const SizedBox(height: 12),
                    Text(s.mealTypeLabel.toUpperCase(), style: t.labelSmall),
                    Wrap(spacing: 4, children: [
                      for (final e in categories.entries)
                        ChoiceChip(
                            showCheckmark: false,
                            label: Text(e.value),
                            selected: e.key == _mealType,
                            onSelected: busy
                                ? null
                                : (_) => _changeReview(() => _mealType = e.key))
                    ]),
                    if (widget.entry != null)
                      Text(
                          TimeOfDay.fromDateTime(
                                  widget.entry!.createdAt.toLocal())
                              .format(c),
                          style: t.bodySmall)
                  ]),
                  const SizedBox(height: 16),
                  panel([
                    Row(children: [
                      Expanded(
                          child: Text(
                              en
                                  ? 'TOTAL ESTIMATED ENERGY'
                                  : 'ENERGÍA ESTIMADA',
                              style: t.labelSmall)),
                      if (target != null && target > 0)
                        Text(
                            '${(100 * calories / target).round()}% / $target kcal',
                            style: t.labelSmall)
                    ]),
                    Text('~ $calories kcal',
                        style: t.headlineMedium
                            ?.copyWith(color: DashboardTheme.primary)),
                    const SizedBox(height: 10),
                    if (energy > 0)
                      Row(children: [
                        for (final m in macros)
                          if ((int.tryParse(m.$2.text) ?? 0) * m.$4 > 0)
                            Expanded(
                                flex: (int.parse(m.$2.text)) * m.$4,
                                child: Container(height: 8, color: m.$3))
                      ]),
                    if (energy > 0)
                      Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 6,
                          children: [
                            for (final m in macros.take(3))
                              Text(
                                  '${(100 * (int.tryParse(m.$2.text) ?? 0) * m.$4 / energy).round()}% ${m.$1}',
                                  style: t.labelSmall)
                          ]),
                    const Divider(height: 24),
                    for (final row in [macros.take(2), macros.skip(2)])
                      Row(children: [
                        for (final m in row)
                          Expanded(child: metric(m.$1, m.$2, 'g', m.$3))
                      ]),
                    const Divider(),
                    Row(children: [
                      const Icon(Icons.scale_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(en
                              ? 'Total Serving Weight'
                              : 'Peso de la porción')),
                      IconButton(
                          tooltip: '−10 g',
                          onPressed: busy || grams <= 10
                              ? null
                              : () => weight(grams - 10),
                          icon: const Icon(Icons.remove)),
                      TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  final v = await _reviewInput(
                                      c, s.mealWeightLabel, '$grams',
                                      number: true);
                                  if (mounted) {
                                    weight(int.tryParse(v ?? '') ?? 0);
                                  }
                                },
                          child: Text('$grams g')),
                      IconButton(
                          tooltip: '+10 g',
                          onPressed: busy ? null : () => weight(grams + 10),
                          icon: const Icon(Icons.add))
                    ]),
                    Text(
                        en
                            ? 'Changing serving weight scales the meal totals proportionally.'
                            : 'Cambiar el peso ajusta los totales del plato proporcionalmente.',
                        style: t.bodySmall)
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                        child: Text(
                            '${en ? 'Detected Ingredients' : 'Ingredientes detectados'} (${ingredients.length})',
                            style: t.titleMedium)),
                    TextButton.icon(
                        onPressed: busy ? null : () => editIngredient(null),
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(en ? 'Add item' : 'Añadir'))
                  ]),
                  for (final (i, item) in ingredients.indexed)
                    ingredientCard(i, item),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: busy ? null : _analyzeWithAi,
                      icon: const Icon(Icons.sync),
                      label: Text(_isAnalyzing
                          ? '${s.analyzeWithAiButton}…'
                          : en
                              ? 'Re-analyze with manual adjustments'
                              : 'Reanalizar con los cambios')),
                  const SizedBox(height: 8),
                  panel([Text(help, style: t.bodySmall)]),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              if (grams <= 0) {
                                ScaffoldMessenger.of(c).showSnackBar(
                                    SnackBar(content: Text(s.mealWeightLabel)));
                                return;
                              }
                              _changeReview(() => _confirming = true);
                              try {
                                await _save();
                              } catch (e) {
                                if (c.mounted) {
                                  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
                                      content: Text(_userFacingError(e, s))));
                                }
                              } finally {
                                if (mounted) {
                                  _changeReview(() => _confirming = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(_confirming
                          ? '…'
                          : en
                              ? 'Confirm & log to ${categories[_mealType]}'
                              : 'Confirmar y guardar en ${categories[_mealType]}')),
                  TextButton(
                      onPressed: busy
                          ? null
                          : () => _changeReview(() => _review = false),
                      child: Text(en
                          ? 'Edit all meal details'
                          : 'Editar todos los datos'))
                ])));
  }
}
