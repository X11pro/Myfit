import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../../shared/widgets/myfit_bottom_nav.dart';
import '../../food/application/manual_food_entries_controller.dart';
import '../../workout/application/manual_workout_controller.dart';
import '../application/daily_targets_calculator.dart';
import '../application/daily_weight_controller.dart';
import '../domain/daily_targets.dart';
import 'dashboard_theme.dart';
import 'progress_detail_screen.dart';
import 'widgets/progress_chart_widgets.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressState();
}

class _ProgressState extends ConsumerState<ProgressScreen> {
  int days = 30, section = 0;
  String? exercise;
  final anchors = List.generate(3, (_) => GlobalKey());
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Theme(data: DashboardTheme.dark(), child: Builder(builder: _screen));
  Widget _screen(BuildContext c) {
    final s = stringsFor(ref), en = s.isEnglish, t = Theme.of(c).textTheme;
    final today = DateUtils.dateOnly(DateTime.now());
    final start = DateTime(today.year, today.month, today.day - days + 1);
    bool inside(String key) {
      final d = DateTime.tryParse(key);
      return d != null && !d.isBefore(start) && !d.isAfter(today);
    }

    final allWeights = [...ref.watch(dailyWeightEntriesProvider)]
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final weights = allWeights.where((e) => inside(e.dateKey)).toList();
    final trend = [
      for (final w in weights)
        (() {
          final d = DateTime.parse(w.dateKey);
          final lower = DateTime(d.year, d.month, d.day - 6);
          final window = allWeights.where((a) =>
              a.dateKey.compareTo(w.dateKey) <= 0 &&
              !DateTime.parse(a.dateKey).isBefore(lower));
          return ProgressPoint(
              label: w.dateKey.substring(5),
              value: window.fold<double>(0, (n, a) => n + a.weightKg) /
                  window.length);
        })()
    ];
    final meals = ref
        .watch(dailyNutritionSummariesProvider)
        .where((e) => inside(e.dateKey))
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final targets = ref.watch(dailyTargetsProvider);
    final goal = targets?.targetCalories;
    final workouts = ref
        .watch(manualWorkoutSessionsProvider)
        .where((e) => inside(e.dateKey))
        .toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    final exercises = workouts
        .expand((w) => w.sets)
        .map((x) => x.exerciseName)
        .toSet()
        .toList();
    final name =
        exercises.contains(exercise) ? exercise : exercises.firstOrNull;
    final sets = workouts
        .expand((w) => w.sets)
        .where((x) => x.exerciseName == name)
        .toList();
    final series = <String, double>{};
    double volume = 0, peak = 0;
    for (final w in workouts) {
      for (final x in w.sets.where((x) => x.exerciseName == name)) {
        volume += x.reps * x.weightKg;
        if (x.reps > 0 && x.weightKg > 0) {
          peak = math.max(peak, x.weightKg);
          series.update(
              w.dateKey, (v) => math.max(v, x.weightKg * (1 + x.reps / 30)),
              ifAbsent: () => x.weightKg * (1 + x.reps / 30));
        }
      }
    }
    final lifts = [
      for (final e in series.entries)
        ProgressPoint(label: e.key.substring(5), value: e.value)
    ];
    List<ProgressPoint> sample(List<ProgressPoint> pts) => pts.length <= 6
        ? pts
        : [for (int i = 0; i < 6; i++) pts[(i * (pts.length - 1) / 5).round()]];
    Widget card(String eyebrow, String title, List<Widget> content,
            {Key? key, Widget? action}) =>
        Card(
            key: key,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(eyebrow.toUpperCase(), style: t.labelSmall),
                      Row(children: [
                        Expanded(child: Text(title, style: t.titleLarge)),
                        if (action != null) action
                      ]),
                      const SizedBox(height: 12),
                      ...content
                    ])));
    Widget note(String v) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: DashboardTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(12)),
        child: Text(v, style: t.bodySmall));
    Future<void> export() async {
      final summary = {for (final m in meals) m.dateKey: m};
      final bodyWeight = {for (final w in weights) w.dateKey: w.weightKg};
      final vol = <String, double>{};
      for (final w in workouts) {
        vol.update(
            w.dateKey,
            (v) =>
                v + w.sets.fold<double>(0, (n, x) => n + x.weightKg * x.reps),
            ifAbsent: () =>
                w.sets.fold<double>(0, (n, x) => n + x.weightKg * x.reps));
      }
      final dates = {...summary.keys, ...bodyWeight.keys, ...vol.keys}.toList()
        ..sort();
      final csv = [
        'date,weight_kg,food_kcal,protein_g,training_volume_kg',
        for (final d in dates)
          [
            d,
            bodyWeight[d] ?? '',
            summary[d]?.totalCalories ?? '',
            summary[d]?.totalProteinGrams ?? '',
            vol[d] ?? ''
          ].join(',')
      ].join('\n');
      await showDialog<void>(
          context: c,
          builder: (ctx) => AlertDialog(
                  title: Text(
                      en ? 'Export progress (CSV)' : 'Exportar progreso (CSV)'),
                  content: SingleChildScrollView(child: SelectableText(csv)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                            MaterialLocalizations.of(ctx).closeButtonLabel)),
                    FilledButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: csv));
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(en ? 'Copy CSV' : 'Copiar CSV'))
                  ]));
    }

    Future<void> log() async {
      var value = '';
      final v = await showDialog<double>(
          context: c,
          builder: (ctx) => AlertDialog(
                  title: Text(s.logWeightTitle),
                  content: TextField(
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          InputDecoration(labelText: s.weightInputLabel),
                      onChanged: (v) => value = v),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(s.cancelButton)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx,
                            double.tryParse(value.replaceAll(',', '.')) ?? 0),
                        child: Text(s.saveWeightButton))
                  ]));
      if (v == null || !c.mounted) return;
      if (!v.isFinite || v <= 0) {
        ScaffoldMessenger.of(c)
            .showSnackBar(SnackBar(content: Text(s.invalidWeightMessage)));
        return;
      }
      await ref.read(dailyWeightEntriesProvider.notifier).upsertTodayWeight(v);
    }

    final labels = [
      en ? 'Body Weight & Energy' : 'Peso y energía',
      en ? 'Energy Balance' : 'Balance energético',
      en ? 'Strength & 1RM' : 'Fuerza y 1RM'
    ];
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
        bottomNavigationBar: MyfitBottomNav(strings: s, index: 3),
        body: SafeArea(
            top: false,
            child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          en
                              ? '●  TELEMETRY & TRENDS'
                              : '●  MÉTRICAS Y TENDENCIAS',
                          style: t.labelSmall),
                      Row(children: [
                        Expanded(
                            child: Text(
                                en
                                    ? 'Progress & Analytics'
                                    : 'Progreso y análisis',
                                style: t.headlineMedium)),
                        TextButton.icon(
                            onPressed: export,
                            icon: const Icon(Icons.ios_share, size: 16),
                            label: Text(en ? 'Export' : 'Exportar'))
                      ]),
                      const SizedBox(height: 8),
                      Card(
                          child: Row(children: [
                        for (final n in [7, 30, 90, 365])
                          Expanded(
                              child: TextButton(
                                  style: TextButton.styleFrom(
                                      backgroundColor: n == days
                                          ? DashboardTheme.surfaceMuted
                                          : null),
                                  onPressed: () => setState(() => days = n),
                                  child: Text(
                                      n == 365 ? (en ? '1Y' : '1A') : '${n}D')))
                      ])),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (final (i, label) in labels.indexed)
                              Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                      selected: section == i,
                                      label: Text(label),
                                      onSelected: (_) {
                                        setState(() => section = i);
                                        Scrollable.ensureVisible(
                                            anchors[i].currentContext!,
                                            duration: const Duration(
                                                milliseconds: 250));
                                      }))
                          ])),
                      const SizedBox(height: 12),
                      card(
                          en
                              ? '7-day smoothed trend'
                              : 'Tendencia media de 7 días',
                          weights.isEmpty
                              ? s.progressBodyWeight
                              : '${trend.last.value.toStringAsFixed(1)} kg',
                          [
                            if (trend.isEmpty)
                              Text(s.noProgressDataYet)
                            else ...[
                              Text(
                                  '${en ? 'Latest weigh-in' : 'Último registro'}: ${weights.last.weightKg} kg · ${weights.last.dateKey}',
                                  style: t.bodySmall),
                              const SizedBox(height: 12),
                              ProgressLineAreaChart(
                                  points: sample(trend), height: 220)
                            ],
                            const SizedBox(height: 10),
                            note(en
                                ? 'The trend averages recorded weigh-ins over seven calendar days. Daily fluctuations are normal.'
                                : 'La tendencia promedia los registros de siete días. Las fluctuaciones diarias son normales.')
                          ],
                          key: anchors[0],
                          action: FilledButton.icon(
                              onPressed: log,
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(en ? 'Log' : 'Registrar'))),
                      const SizedBox(height: 16),
                      card(
                          labels[1],
                          en
                              ? 'Caloric Target Adherence'
                              : 'Consumo y objetivo calórico',
                          [
                            Text(
                                '${meals.length} / $days ${en ? 'days logged' : 'días registrados'}',
                                style: t.bodySmall),
                            const SizedBox(height: 8),
                            if (meals.isEmpty)
                              Text(s.noProgressDataYet)
                            else ...[
                              if (goal != null && goal > 0)
                                note(
                                    '${(100 * meals.where((m) => (m.totalCalories - goal).abs() <= goal * .10).length / meals.length).round()}% · ${en ? 'Logged days within ±10% of the current target' : 'Días registrados dentro de ±10% del objetivo actual'}'),
                              const SizedBox(height: 12),
                              _EnergyBars(
                                  values: meals.reversed
                                      .take(7)
                                      .toList()
                                      .reversed
                                      .map((m) => (
                                            m.dateKey.substring(5),
                                            m.totalCalories
                                          ))
                                      .toList(),
                                  goal: goal),
                              Text(
                                  en
                                      ? 'Intake (kcal) · Orange line: current target'
                                      : 'Consumo (kcal) · Línea naranja: objetivo actual',
                                  style: t.labelSmall),
                              const Divider(height: 24),
                              Text(
                                  '${days}D · ${en ? 'Average macronutrients' : 'Macros medios'}',
                                  style: t.titleSmall),
                              for (final m in [
                                (
                                  s.protein,
                                  meals.fold<int>(
                                      0, (n, m) => n + m.totalProteinGrams),
                                  targets?.targetProteinGrams,
                                  DashboardTheme.primary
                                ),
                                (
                                  s.carbs,
                                  meals.fold<int>(
                                      0, (n, m) => n + m.totalCarbsGrams),
                                  targets?.targetCarbsGrams,
                                  DashboardTheme.charcoal
                                ),
                                (
                                  s.fat,
                                  meals.fold<int>(
                                      0, (n, m) => n + m.totalFatGrams),
                                  targets?.targetFatGrams,
                                  DashboardTheme.warning
                                )
                              ])
                                Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${m.$1}: ${(m.$2 / meals.length).round()}g / ${m.$3 ?? '—'}g'),
                                          LinearProgressIndicator(
                                              value: (m.$3 ?? 0) > 0
                                                  ? (m.$2 /
                                                          meals.length /
                                                          m.$3!)
                                                      .clamp(0, 1)
                                                  : 0,
                                              color: m.$4)
                                        ]))
                            ]
                          ],
                          key: anchors[1]),
                      const SizedBox(height: 16),
                      card(
                          en ? 'Progressive overload' : 'Sobrecarga progresiva',
                          en
                              ? 'Strength & Theoretical 1RM'
                              : 'Fuerza y 1RM estimado',
                          [
                            if (sets.isEmpty)
                              Text(s.noProgressDataYet)
                            else ...[
                              SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(children: [
                                    for (final x in exercises)
                                      ChoiceChip(
                                          label: Text(x),
                                          selected: x == name,
                                          onSelected: (_) =>
                                              setState(() => exercise = x))
                                  ])),
                              const SizedBox(height: 12),
                              Text(
                                  lifts.isEmpty
                                      ? '—'
                                      : '${lifts.last.value.toStringAsFixed(1)} kg',
                                  style: t.headlineMedium),
                              Text(
                                  en
                                      ? 'Estimated 1RM · Epley formula'
                                      : '1RM estimado · Fórmula de Epley',
                                  style: t.bodySmall),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(child: note(s.maxWeightLabel(peak))),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: note(
                                        '${s.progressTrainingVolume}: ${volume.round()} kg'))
                              ]),
                              if (lifts.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ProgressLineAreaChart(
                                    points: sample(lifts), height: 180)
                              ]
                            ]
                          ],
                          key: anchors[2]),
                      const SizedBox(height: 16),
                      note(ref.watch(appStateProvider).isAuthenticated
                          ? (en ? 'Account history' : 'Historial de la cuenta')
                          : (en ? 'Local guest history' : 'Historial local')),
                      OutlinedButton.icon(
                          onPressed: export,
                          icon: const Icon(Icons.download_outlined),
                          label: Text(en
                              ? 'Export Progress History (CSV)'
                              : 'Exportar historial (CSV)')),
                      TextButton(
                          onPressed: () => Navigator.push(
                              c,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ProgressDetailScreen())),
                          child: Text(en
                              ? 'Explore detailed charts'
                              : 'Ver gráficos detallados')),
                      Text(
                          en
                              ? 'Energy and strength estimates are informational, not clinical measurements.'
                              : 'Las estimaciones de energía y fuerza no son mediciones clínicas.',
                          style: t.bodySmall)
                    ]))));
  }
}

class _EnergyBars extends StatelessWidget {
  const _EnergyBars({required this.values, this.goal});
  final List<(String, int)> values;
  final int? goal;
  @override
  Widget build(BuildContext context) {
    final max =
        values.fold<int>(math.max(1, goal ?? 0), (n, v) => math.max(n, v.$2));
    return Column(children: [
      SizedBox(
          height: 105,
          child: Stack(children: [
            Positioned.fill(
                child:
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final e in values)
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Semantics(
                            label: '${e.$1}: ${e.$2} kcal',
                            child: Container(
                                height: 98 * e.$2 / max,
                                color: DashboardTheme.primary))))
            ])),
            if (goal != null)
              Positioned(
                  left: 0,
                  right: 0,
                  bottom: 98 * goal! / max,
                  child:
                      const Divider(height: 1, color: DashboardTheme.warning))
          ])),
      Row(children: [
        for (final e in values)
          Expanded(
              child: Text(e.$1,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall))
      ])
    ]);
  }
}
