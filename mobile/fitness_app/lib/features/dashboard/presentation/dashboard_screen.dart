import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_language.dart';
import '../../../shared/date_format.dart';
import '../../../shared/app_state.dart';
import '../../../shared/widgets/myfit_bottom_nav.dart';
import '../../../shared/ui/theme/app_theme.dart';
import 'widgets/stitch_daily_cards.dart';
import 'widgets/log_weight_dialog.dart';
import '../../food/application/manual_food_entries_controller.dart';
import '../../food/domain/manual_food_entry.dart' show DailyNutritionSummary;
import '../../workout/application/manual_workout_controller.dart';
import '../application/daily_targets_calculator.dart';
import '../application/daily_weight_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _DashboardBody();
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final strings = stringsFor(ref);
    final displayName = state.displayName ?? strings.defaultUserName;
    final summary = ref.watch(todayNutritionSummaryProvider) ??
        const DailyNutritionSummary(
            dateKey: '',
            totalCalories: 0,
            totalProteinGrams: 0,
            totalCarbsGrams: 0,
            totalFatGrams: 0,
            entryCount: 0);
    final entries = ref.watch(manualFoodEntriesProvider);
    final dailySummaries = ref.watch(dailyNutritionSummariesProvider);
    final todayWeight = ref.watch(todayWeightEntryProvider);
    final dailyTargets = ref.watch(dailyTargetsProvider);
    final todayWorkouts = ref.watch(todayWorkoutSessionsProvider);
    final todayWorkoutCalories = ref.watch(todayWorkoutCaloriesProvider);

    final currentWeightKg = todayWeight?.weightKg ?? state.currentWeightKg;
    final latestWorkout = todayWorkouts.isNotEmpty ? todayWorkouts.first : null;
    final en = strings.isEnglish;
    final targetCalories = dailyTargets?.targetCalories ?? 2200;
    final calorieProgress = targetCalories <= 0
        ? 0.0
        : (summary.totalCalories / targetCalories).clamp(0.0, 1.0);
    final remainingCalories =
        max(0, targetCalories - summary.totalCalories).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Myfit',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.8),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
              onPressed: () => ref.read(appLanguageProvider.notifier).state =
                  strings.isEnglish ? AppLanguage.es : AppLanguage.en,
              child: const Text('EN / ES')),
          IconButton(
              onPressed: () => context.go('/auth'),
              icon: const Icon(Icons.account_circle),
              tooltip: strings.accountTabLabel)
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(formatDisplayDate(DateTime.now()),
                style: Theme.of(context).textTheme.labelSmall),
            Text(
                state.isAuthenticated
                    ? strings.accountTabLabel
                    : (strings.isEnglish
                        ? '●  Local profile'
                        : '●  Perfil local'),
                style: Theme.of(context).textTheme.labelSmall)
          ]),
          Text(
            strings.goodMorningUser(displayName),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.isEnglish
                ? 'You have ~$remainingCalories kcal remaining to reach today’s energy target.'
                : 'Te quedan ~$remainingCalories kcal para alcanzar tu objetivo diario.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          _Snapshot(
              strings: strings,
              personalized:
                  dailyTargets?.usesPersonalizedEnergyEstimate ?? false,
              target: targetCalories,
              eaten: summary.totalCalories,
              burn: todayWorkoutCalories,
              remaining: remainingCalories,
              balance: dailyTargets == null
                  ? null
                  : summary.totalCalories - dailyTargets.estimatedBurnCalories,
              progress: calorieProgress,
              macros: [
                (
                  strings.protein,
                  summary.totalProteinGrams.toDouble(),
                  dailyTargets?.targetProteinGrams,
                  AppTheme.primary
                ),
                (
                  strings.carbs,
                  summary.totalCarbsGrams.toDouble(),
                  dailyTargets?.targetCarbsGrams,
                  AppTheme.secondary
                ),
                (
                  strings.fat,
                  summary.totalFatGrams.toDouble(),
                  dailyTargets?.targetFatGrams,
                  AppTheme.tertiary
                )
              ]),
          const SizedBox(height: 20),
          _QuickActions(
            addMealLabel: strings.addMealTitle,
            workoutLabel: strings.startWorkoutButton,
            onAddMeal: () => context.go('/food/manual'),
            onWorkout: () => context.go('/workout/manual'),
          ),
          const SizedBox(height: 16),
          TrainingPanel(
              strings: strings,
              session: latestWorkout,
              open: () =>
                  context.push('/workout/manual', extra: latestWorkout)),
          const SizedBox(height: 16),
          DailyPanel(
              label: en ? 'Metabolism' : 'Metabolismo',
              title: strings.estimatedDailyBurnTitle,
              icon: Icons.local_fire_department_outlined,
              accent: AppTheme.warning,
              children: [
                Text(
                    dailyTargets == null
                        ? '—'
                        : '~${dailyTargets.estimatedBurnCalories} kcal/${en ? 'day' : 'día'}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: AppTheme.warning)),
                Text(dailyTargets?.usesPersonalizedEnergyEstimate == true
                    ? (en
                        ? 'Calculated using the Mifflin–St Jeor equation and your activity profile.'
                        : 'Calculado con la ecuación de Mifflin–St Jeor y tu nivel de actividad.')
                    : strings.energyEstimateMethod(personalized: false)),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.info_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              en
                                  ? 'Calculated estimate · Not a medical diagnosis or sensor measurement.'
                                  : 'Estimación calculada · No es un diagnóstico ni una medición por sensor.',
                              style: Theme.of(context).textTheme.bodySmall))
                    ])),
                FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.surfaceMuted,
                        foregroundColor: AppTheme.charcoal),
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(Icons.tune),
                    label: Text(en
                        ? 'Adjust Energy Profile & Targets'
                        : 'Ajustar perfil y objetivos'))
              ]),
          const SizedBox(height: 16),
          DailyPanel(
              label: en ? 'Body composition' : 'Composición corporal',
              title: en ? 'Body Weight' : 'Peso corporal',
              icon: Icons.monitor_weight_outlined,
              action: TextButton.icon(
                  onPressed: () => showLogWeightDialog(context, ref, strings),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(strings.logWeightTitle)),
              children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                              currentWeightKg == null
                                  ? '—'
                                  : '${currentWeightKg.toStringAsFixed(1)} kg',
                              style:
                                  Theme.of(context).textTheme.headlineMedium)),
                      if (todayWeight != null)
                        Text(en ? 'Logged today' : 'Registrado hoy',
                            style: Theme.of(context).textTheme.labelSmall)
                    ])),
                Text(
                    en
                        ? 'Consistent weigh-ins help you see trends beyond day-to-day fluctuations.'
                        : 'El registro regular permite ver tendencias más allá de las fluctuaciones diarias.',
                    style: Theme.of(context).textTheme.bodySmall)
              ]),
          const SizedBox(height: 16),
          DailyLogsPanel(
              strings: strings,
              meals: entries
                  .where((m) => DateUtils.isSameDay(
                      m.createdAt.toLocal(), DateTime.now()))
                  .toList(),
              workouts: todayWorkouts,
              progress: () => context.push('/dashboard/progress')),
          const SizedBox(height: 12),
          Text(
              en
                  ? 'Myfit provides calculated estimates. Not intended for clinical or medical decision making.'
                  : 'Myfit proporciona estimaciones. No está destinado a decisiones clínicas o médicas.',
              style: Theme.of(context).textTheme.bodySmall),
          if (dailySummaries.isNotEmpty) ...[
            const SizedBox(height: 16),
            _CollapsibleSection(
              title: strings.dailyHistorySection,
              subtitle: strings.collapseSectionHint,
              child: Column(
                children: dailySummaries
                    .take(7)
                    .map(
                      (summary) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DailyHistoryCard(
                          strings: strings,
                          summary: summary,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: MyfitBottomNav(strings: strings, index: 0),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.addMealLabel,
    required this.workoutLabel,
    required this.onAddMeal,
    required this.onWorkout,
  });

  final String addMealLabel;
  final String workoutLabel;
  final VoidCallback onAddMeal;
  final VoidCallback onWorkout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddMeal,
            icon: const Icon(Icons.add_rounded),
            label: Text(addMealLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: onWorkout,
            icon: const Icon(Icons.fitness_center_outlined),
            label: Text(workoutLabel),
          ),
        ),
      ],
    );
  }
}

class _DailyHistoryCard extends StatelessWidget {
  const _DailyHistoryCard({required this.strings, required this.summary});

  final AppStrings strings;
  final DailyNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(formatDisplayDateKey(summary.dateKey)),
                  const SizedBox(height: 4),
                  Text(strings.dateSummarySubtitle(
                      summary.dateKey, summary.entryCount)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${summary.totalCalories} kcal'),
                const SizedBox(height: 4),
                Text('${summary.totalProteinGrams} g'),
                const SizedBox(height: 4),
                Text(
                    '${summary.totalCarbsGrams} g C / ${summary.totalFatGrams} g F'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        children: [child],
      ),
    );
  }
}

class _Snapshot extends StatelessWidget {
  const _Snapshot(
      {required this.strings,
      required this.personalized,
      required this.target,
      required this.eaten,
      required this.burn,
      required this.balance,
      required this.remaining,
      required this.progress,
      required this.macros});
  final int? balance;
  final bool personalized;
  final AppStrings strings;
  final int target, eaten, burn, remaining;
  final double progress;
  final List<(String, double, int?, Color)> macros;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  strings.isEnglish
                      ? 'METABOLIC SNAPSHOT'
                      : 'RESUMEN METABÓLICO',
                  style: t.labelSmall),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Text(
                        strings.isEnglish
                            ? 'Daily Energy Balance'
                            : strings.dailyEnergyBalanceTitle,
                        style: t.titleLarge)),
                const SizedBox(width: 12),
                _Pill(personalized ? 'Est. (Mifflin–St Jeor)' : 'Est.')
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '$remaining',
                            style: const TextStyle(
                                fontSize: 36,
                                height: 40 / 36,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                        TextSpan(text: ' kcal', style: t.labelMedium)
                      ])),
                      Text(strings.caloriesRemainingLabel, style: t.labelMedium)
                    ])),
                SizedBox.square(
                    dimension: 88,
                    child: Stack(fit: StackFit.expand, children: [
                      CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: AppTheme.surfaceMuted),
                      Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('${(100 * progress).round()}%',
                            style: t.titleMedium),
                        Text(strings.isEnglish ? 'Target' : 'Objetivo',
                            style: t.labelSmall)
                      ]))
                    ]))
              ]),
              if (balance != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(strings.energyBalanceStatus(balance!),
                        style: t.bodySmall)),
              const SizedBox(height: 18),
              Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    for (final x in [
                      (strings.isEnglish ? 'Base target' : 'Objetivo', target),
                      (strings.isEnglish ? 'Food intake' : 'Consumo', eaten),
                      (strings.isEnglish ? 'Active burn' : 'Actividad', burn)
                    ])
                      Expanded(
                          child: Column(children: [
                        Text(x.$1, style: t.labelSmall),
                        Text('${x.$2}', style: t.titleMedium),
                        Text('kcal', style: t.bodySmall)
                      ]))
                  ])),
              const SizedBox(height: 16),
              Text(
                  strings.isEnglish
                      ? 'Macronutrient distribution'
                      : 'Distribución de macros',
                  style: t.titleSmall),
              for (final m in macros)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: Text(m.$1, style: t.labelMedium)),
                        Text('${m.$2.round()}g / ${m.$3 ?? '—'}g',
                            style: t.labelSmall)
                      ]),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                          value: m.$3 == null || m.$3 == 0
                              ? 0
                              : (m.$2 / m.$3!).clamp(0, 1).toDouble(),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                          color: m.$4,
                          backgroundColor: AppTheme.surfaceMuted)
                    ])),
            ])));
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall));
}
