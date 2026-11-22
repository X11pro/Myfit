import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../../shared/date_format.dart';
import '../../../shared/widgets/myfit_bottom_nav.dart';
import '../../dashboard/application/daily_targets_calculator.dart';
import '../../../shared/ui/theme/app_theme.dart';
import '../application/manual_food_entries_controller.dart';
import '../domain/manual_food_entry.dart';
import 'widgets/meal_photo_view.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override
  ConsumerState<NutritionScreen> createState() => _NutritionState();
}

class _NutritionState extends ConsumerState<NutritionScreen> {
  DateTime date = DateUtils.dateOnly(DateTime.now());
  String query = '';
  String? mealType;
  int sum(List<ManualFoodEntry> rows, int Function(ManualFoodEntry) field) =>
      rows.fold(0, (v, e) => v + field(e));
  @override
  Widget build(BuildContext c) {
    final s = stringsFor(ref), en = s.isEnglish, t = Theme.of(c).textTheme;
    final all = ref.watch(manualFoodEntriesProvider),
        targets = ref.watch(dailyTargetsProvider);
    final signed = ref.watch(appStateProvider).isAuthenticated;
    final entries = all
        .where((m) => DateUtils.isSameDay(m.createdAt.toLocal(), date))
        .toList();
    final today = DateUtils.isSameDay(DateTime.now(), date);
    final kcal = sum(entries, (m) => m.calories);
    final goal = targets?.targetCalories;
    final groups = {
      'breakfast': s.mealTypeBreakfast,
      'lunch': s.mealTypeLunch,
      'snack': s.mealTypeSnack,
      'dinner': s.mealTypeDinner
    };
    final photos = all.where((e) => e.photoPath?.isNotEmpty == true).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final normalized = query.trim().toLowerCase();
    final matched = entries
        .where((e) =>
            e.name.toLowerCase().contains(normalized) ||
            (e.ingredientsText ?? '').toLowerCase().contains(normalized))
        .toList();
    final selectableGroups = groups.entries
        .where((group) =>
            normalized.isEmpty || matched.any((e) => e.mealType == group.key))
        .toList();
    final selectedGroup =
        selectableGroups.where((group) => group.key == mealType).firstOrNull ??
            (normalized.isEmpty ? null : selectableGroups.firstOrNull);
    final selectedRows =
        matched.where((entry) => entry.mealType == selectedGroup?.key).toList();
    void day(int d) =>
        setState(() => date = DateTime(date.year, date.month, date.day + d));
    void log([String? type, String? action]) =>
        c.push(Uri(path: '/food/manual', queryParameters: {
          if (type != null) 'meal': type,
          if (action != null) 'action': action,
          'from': 'nutrition'
        }).toString());
    Widget card(Widget child) =>
        Card(child: Padding(padding: const EdgeInsets.all(16), child: child));
    Widget header(String title, Widget trailing) => Row(children: [
          Expanded(child: Text(title, style: t.titleLarge)),
          trailing
        ]);
    Widget badge(String text, [Color accent = AppTheme.charcoal]) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: t.labelSmall?.copyWith(color: accent)));
    Widget thumb(ManualFoodEntry e, double w, double h) => e.photoPath == null
        ? SizedBox(
            width: w,
            height: h,
            child: const Icon(Icons.restaurant_outlined, size: 20))
        : MealPhotoView(photoPath: e.photoPath!, width: w, height: h);
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
                  tooltip: s.accountTabLabel,
                  onPressed: () => c.push('/auth'),
                  icon: const Icon(Icons.account_circle_outlined))
            ]),
        bottomNavigationBar: MyfitBottomNav(strings: s, index: 2),
        body: SafeArea(
            top: false,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(children: [
                    IconButton(
                        tooltip: en ? 'Previous day' : 'Día anterior',
                        onPressed: () => day(-1),
                        icon: const Icon(Icons.chevron_left)),
                    Expanded(
                        child: TextButton.icon(
                            onPressed: () async {
                              final end = DateTime.now();
                              final d = await showDatePicker(
                                  context: c,
                                  initialDate: date,
                                  firstDate: DateTime(1900),
                                  lastDate: end);
                              if (d != null && mounted) {
                                setState(() => date = d);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined,
                                size: 16),
                            label: Text(
                                '${today ? (en ? 'Today, ' : 'Hoy, ') : ''}${MaterialLocalizations.of(c).formatShortMonthDay(date)}'))),
                    IconButton(
                        tooltip: en ? 'Next day' : 'Día siguiente',
                        onPressed: today ? null : () => day(1),
                        icon: const Icon(Icons.chevron_right)),
                    badge(signed
                        ? (en ? 'Account' : 'Cuenta')
                        : (en ? 'Local' : 'Local'))
                  ]),
                  TextField(
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: en
                              ? 'Search food in this diary'
                              : 'Buscar en el diario')),
                  const SizedBox(height: 16),
                  card(Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    en
                                        ? 'CALORIES CONSUMED'
                                        : 'CALORÍAS CONSUMIDAS',
                                    style: t.labelSmall),
                                Text.rich(TextSpan(children: [
                                  TextSpan(
                                      text: '$kcal',
                                      style: t.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.w800)),
                                  TextSpan(
                                      text: ' / ${goal ?? '—'} kcal',
                                      style: t.bodySmall)
                                ]))
                              ])),
                          SizedBox.square(
                              dimension: 58,
                              child: Stack(fit: StackFit.expand, children: [
                                CircularProgressIndicator(
                                    value: goal == null || goal <= 0
                                        ? 0
                                        : (kcal / goal).clamp(0, 1),
                                    strokeWidth: 5,
                                    backgroundColor: AppTheme.surfaceMuted),
                                Center(
                                    child: Text(
                                        goal == null || goal <= 0
                                            ? '—'
                                            : '${(100 * kcal / goal).round()}%',
                                        style: t.labelMedium))
                              ]))
                        ]),
                        const Divider(height: 28),
                        Row(children: [
                          for (final m in [
                            (
                              s.protein,
                              sum(entries, (e) => e.proteinGrams),
                              targets?.targetProteinGrams,
                              AppTheme.primary
                            ),
                            (
                              s.carbs,
                              sum(entries, (e) => e.carbsGrams),
                              targets?.targetCarbsGrams,
                              AppTheme.warning
                            ),
                            (
                              s.fat,
                              sum(entries, (e) => e.fatGrams),
                              targets?.targetFatGrams,
                              AppTheme.danger
                            )
                          ])
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(m.$1,
                                                    style: t.labelMedium)),
                                            if ((m.$3 ?? 0) > 0)
                                              Text(
                                                  '${(100 * m.$2 / m.$3!).round()}%',
                                                  style: t.labelSmall
                                                      ?.copyWith(color: m.$4))
                                          ]),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                              value: (m.$3 ?? 0) > 0
                                                  ? (m.$2 / m.$3!).clamp(0, 1)
                                                  : 0,
                                              color: m.$4,
                                              backgroundColor:
                                                  AppTheme.surfaceMuted),
                                          const SizedBox(height: 6),
                                          Text('${m.$2}g / ${m.$3 ?? '—'}g',
                                              style: t.labelSmall)
                                        ])))
                        ]),
                        const Divider(height: 24),
                        Wrap(spacing: 12, children: [
                          badge(
                              '${en ? 'Fiber' : 'Fibra'}: ${sum(entries, (e) => e.fiberGrams)} g',
                              AppTheme.charcoal),
                          badge(
                              '${en ? 'Sugar' : 'Azúcar'}: ${sum(entries, (e) => e.sugarGrams)} g',
                              AppTheme.secondary)
                        ])
                      ])),
                  const SizedBox(height: 20),
                  header(
                      en ? 'Log Food' : 'Registrar comida',
                      Text(
                          today
                              ? (en ? 'Quick entry' : 'Registro rápido')
                              : (en ? 'Logs to today' : 'Registra para hoy'),
                          style: t.labelSmall)),
                  const SizedBox(height: 8),
                  Row(children: [
                    for (final a in [
                      (
                        'photo',
                        en ? 'AI Photo' : 'Foto IA',
                        Icons.camera_alt_outlined,
                        AppTheme.primary
                      ),
                      (
                        'barcode',
                        en ? 'Barcode' : 'Código',
                        Icons.qr_code_scanner,
                        AppTheme.warning
                      ),
                      (
                        'manual',
                        en ? 'Manual' : 'Manual',
                        Icons.edit_note,
                        AppTheme.charcoal
                      )
                    ])
                      Expanded(
                          child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                  onTap: () => log(null, a.$1),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      child: Column(children: [
                                        CircleAvatar(
                                            backgroundColor:
                                                a.$4.withValues(alpha: .14),
                                            child: Icon(a.$3, color: a.$4)),
                                        const SizedBox(height: 6),
                                        Text(a.$2, style: t.titleSmall)
                                      ])))))
                  ]),
                  const SizedBox(height: 24),
                  header(
                      en ? 'Daily Meals' : 'Comidas del día',
                      Text('${entries.length} ${en ? 'entries' : 'registros'}',
                          style: t.labelSmall)),
                  const SizedBox(height: 8),
                  if (normalized.isNotEmpty && matched.isEmpty)
                    Text(en
                        ? 'No matching meals for this day.'
                        : 'Sin coincidencias para este día.'),
                  if (selectableGroups.isNotEmpty)
                    InputDecorator(
                      decoration: const InputDecoration(),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: const Key('daily-meal-selector'),
                          isExpanded: true,
                          isDense: true,
                          value: selectedGroup?.key,
                          hint: Text(en ? 'Select a meal' : 'Elegí una comida'),
                          items: [
                            for (final option in selectableGroups)
                              DropdownMenuItem(
                                value: option.key,
                                child: Text(option.value),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => mealType = value),
                        ),
                      ),
                    ),
                  if (selectedGroup case final group?)
                    Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Card(
                            key: const Key('selected-daily-meal'),
                            child: Column(children: [
                              ListTile(
                                leading: Icon(switch (group.key) {
                                  'breakfast' => Icons.breakfast_dining,
                                  'lunch' => Icons.lunch_dining,
                                  'dinner' => Icons.dinner_dining,
                                  _ => Icons.local_cafe_outlined
                                }),
                                title: Text(
                                    selectedRows.isEmpty
                                        ? (en ? 'Not logged' : 'Sin registrar')
                                        : '${sum(selectedRows, (e) => e.calories)} kcal · ${sum(selectedRows, (e) => e.proteinGrams)}g P · ${sum(selectedRows, (e) => e.carbsGrams)}g C · ${sum(selectedRows, (e) => e.fatGrams)}g F',
                                    style: t.labelSmall),
                              ),
                              for (final e in selectedRows)
                                Card(
                                    color: AppTheme.surfaceMuted,
                                    child: ListTile(
                                        leading: thumb(e, 44, 44),
                                        title: Text(e.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        subtitle: Text(
                                            '${e.calories} kcal · ${e.proteinGrams}g ${s.protein}',
                                            style: t.labelSmall),
                                        onTap: () => c.push(
                                            '/food/manual?from=nutrition',
                                            extra: e))),
                              if (today)
                                TextButton.icon(
                                    onPressed: () => log(group.key),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: Text(selectedRows.isEmpty
                                        ? '${en ? 'Log' : 'Registrar'} ${group.value}'
                                        : '${en ? 'Add to' : 'Añadir a'} ${group.value}'))
                            ]))),
                  const SizedBox(height: 16),
                  header(
                      en ? 'Visual Food Gallery' : 'Galería de comidas',
                      TextButton(
                          onPressed: () => c.push('/food/gallery'),
                          child: Text(en ? 'View all' : 'Ver todo'))),
                  Text(
                      en
                          ? 'Recent photo entries'
                          : 'Registros recientes con foto',
                      style: t.bodySmall),
                  const SizedBox(height: 10),
                  if (photos.isEmpty)
                    card(Text(en
                        ? 'Meals with photos will appear here.'
                        : 'Aquí aparecerán tus comidas con foto.'))
                  else
                    SizedBox(
                        height: 192,
                        child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.take(8).length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final e = photos[i];
                              return SizedBox(
                                  width: 158,
                                  child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: InkWell(
                                          onTap: () => c.push(
                                              '/food/manual?from=nutrition',
                                              extra: e),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                thumb(e, 158, 92),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(e.name,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  t.titleSmall),
                                                          Text(
                                                              '${e.calories} kcal · ${e.proteinGrams}g P',
                                                              style:
                                                                  t.bodySmall),
                                                          Text(
                                                              formatDisplayDate(
                                                                  e.createdAt),
                                                              style:
                                                                  t.labelSmall)
                                                        ]))
                                              ]))));
                            })),
                  const SizedBox(height: 16),
                  card(Text(
                      en
                          ? 'Nutrition values and photo estimates depend on the recorded portion. Review serving sizes and ingredients.'
                          : 'Los valores nutricionales dependen de la porción registrada. Revisa las cantidades y los ingredientes.',
                      style: t.bodySmall))
                ])));
  }
}
