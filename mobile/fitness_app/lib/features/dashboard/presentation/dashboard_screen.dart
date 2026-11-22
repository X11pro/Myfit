// ignore_for_file: unused_element, unused_element_parameter

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_language.dart';
import '../../../shared/date_format.dart';
import '../../../shared/app_state.dart';
import '../../../shared/widgets/myfit_bottom_nav.dart';
import 'dashboard_theme.dart';
import 'widgets/stitch_daily_cards.dart';
import '../../../shared/ui/widgets/crystal_progress_ring.dart';
import '../../food/application/manual_food_entries_controller.dart';
import '../../food/domain/manual_food_entry.dart';
import '../../food/presentation/widgets/meal_photo_view.dart';
import '../../workout/application/manual_workout_controller.dart';
import '../../workout/domain/manual_workout_session.dart';
import '../application/daily_targets_calculator.dart';
import '../application/daily_weight_controller.dart';
import '../domain/daily_targets.dart';
import '../domain/daily_weight_entry.dart';
import 'widgets/progress_chart_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      Theme(data: DashboardTheme.dark(), child: const _DashboardBody());
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
              onPressed: () => context.push('/dashboard/progress'),
              icon: const Icon(Icons.trending_up),
              tooltip: strings.progressScreenTitle),
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
                  DashboardTheme.primary
                ),
                (
                  strings.carbs,
                  summary.totalCarbsGrams.toDouble(),
                  dailyTargets?.targetCarbsGrams,
                  const Color(0xffd4ffec)
                ),
                (
                  strings.fat,
                  summary.totalFatGrams.toDouble(),
                  dailyTargets?.targetFatGrams,
                  DashboardTheme.warning
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
              accent: DashboardTheme.warning,
              children: [
                Text(
                    dailyTargets == null
                        ? '—'
                        : '~${dailyTargets.estimatedBurnCalories} kcal/${en ? 'day' : 'día'}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: DashboardTheme.warning)),
                Text(dailyTargets?.usesPersonalizedEnergyEstimate == true
                    ? (en
                        ? 'Calculated using the Mifflin–St Jeor equation and your activity profile.'
                        : 'Calculado con la ecuación de Mifflin–St Jeor y tu nivel de actividad.')
                    : strings.energyEstimateMethod(personalized: false)),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: DashboardTheme.surfaceMuted,
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
                        backgroundColor: DashboardTheme.surfaceMuted,
                        foregroundColor: DashboardTheme.charcoal),
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
                  onPressed: () => _showWeightDialog(context, ref, strings),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(strings.logWeightTitle)),
              children: [
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: DashboardTheme.backgroundSecondary,
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

  Future<void> _showWeightDialog(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final todayWeight = ref.read(todayWeightEntryProvider);
    final controller = TextEditingController(
      text: todayWeight?.weightKg.toString() ?? '',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(strings.logWeightTitle),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: strings.weightInputLabel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.saveWeightButton),
            ),
          ],
        );
      },
    );

    if (saved != true) {
      return;
    }

    final weight = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    if (weight == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.invalidWeightMessage)),
        );
      }
      return;
    }

    await ref
        .read(dailyWeightEntriesProvider.notifier)
        .upsertTodayWeight(weight);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.weightSavedMessage)),
    );
  }
}

class _PremiumBalanceCard extends StatelessWidget {
  const _PremiumBalanceCard({
    required this.strings,
    required this.balanceCalories,
    required this.isOnTarget,
    required this.remainingCalories,
    required this.consumedProgress,
  });

  final AppStrings strings;
  final int balanceCalories;
  final bool isOnTarget;
  final int remainingCalories;
  final double consumedProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              strings.dailyEnergyBalanceTitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 14),
            CrystalProgressRing(
              progress: consumedProgress,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$remainingCalories',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.caloriesRemainingLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: (isOnTarget ? DashboardTheme.success : colors.tertiary)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                strings.energyBalanceStatus(balanceCalories),
                style: TextStyle(
                  color: isOnTarget ? DashboardTheme.success : colors.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumNutritionCard extends StatelessWidget {
  const _PremiumNutritionCard({
    required this.strings,
    required this.summary,
    required this.dailyTargets,
  });

  final AppStrings strings;
  final ManualFoodSummary summary;
  final DailyTargets? dailyTargets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final targetCalories = dailyTargets?.targetCalories ?? 2200;
    final progress = targetCalories <= 0
        ? 0.0
        : (summary.totalCalories / targetCalories).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  strings.nutritionSectionTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.restaurant_menu_outlined,
                      color: colors.primary, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              strings.caloriesEatenTitle.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.caloriesProgressLabel(
                  summary.totalCalories, targetCalories),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DashboardMacroTile(
                    label: strings.protein,
                    value: '${summary.totalProteinGrams} g',
                    color: const Color(0xFFD8A55D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DashboardMacroTile(
                    label: strings.carbs,
                    value: '${summary.totalCarbsGrams} g',
                    color: const Color(0xFF8DC3F2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DashboardMacroTile(
                    label: strings.fat,
                    value: '${summary.totalFatGrams} g',
                    color: const Color(0xFF6C7483),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactNutritionCard extends StatelessWidget {
  const _CompactNutritionCard({
    required this.strings,
    required this.eatenCalories,
    required this.targetCalories,
    required this.progress,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final AppStrings strings;
  final int eatenCalories;
  final int targetCalories;
  final double progress;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(strings.nutritionSectionTitle,
                    style: theme.textTheme.titleMedium),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.restaurant_menu_outlined,
                      color: colors.primary, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(strings.caloriesEatenTitle.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                )),
            const SizedBox(height: 6),
            Text(
              strings.caloriesProgressLabel(eatenCalories, targetCalories),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DashboardMacroTile(
                    label: strings.protein,
                    value: '${proteinGrams}g',
                    color: const Color(0xFFD8A55D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DashboardMacroTile(
                    label: strings.carbs,
                    value: '${carbsGrams}g',
                    color: const Color(0xFF8DC3F2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DashboardMacroTile(
                    label: strings.fat,
                    value: '${fatGrams}g',
                    color: const Color(0xFF6C7483),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricInfoCard extends StatelessWidget {
  const _MetricInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 14),
              Text(title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      )),
              const SizedBox(height: 6),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: accent,
                      )),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivitySummaryTile extends StatelessWidget {
  const _ActivitySummaryTile({
    required this.strings,
    required this.latestWorkout,
    required this.durations,
  });

  final AppStrings strings;
  final ManualWorkoutSession? latestWorkout;
  final WorkoutDurationSummary durations;

  @override
  Widget build(BuildContext context) {
    final workout = latestWorkout;
    if (workout == null) {
      return Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          title: Text(strings.noWorkoutsYet),
          trailing: const Icon(Icons.chevron_right_outlined),
        ),
      );
    }

    return Card(
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(workout.title),
              trailing: const Icon(Icons.check_circle_outline,
                  color: DashboardTheme.primary)),
          SizedBox(
              height: 105,
              child:
                  Image.asset('assets/stitch/training.jpg', fit: BoxFit.cover)),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.workoutActivitySummary(
                        minutes: workout.durationMinutes,
                        calories: workout.estimatedActiveCalories)),
                    Text(strings.workoutTimeSummary(
                        total: _formatWorkoutDuration(durations.totalSeconds),
                        active: _formatWorkoutDuration(durations.activeSeconds),
                        rest: _formatWorkoutDuration(durations.restSeconds))),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: [
                      for (final name
                          in workout.sets.map((s) => s.exerciseName).toSet())
                        Chip(label: Text(name))
                    ]),
                    OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/workout/manual', extra: workout),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(strings.editWorkoutButton))
                  ]))
        ]));
  }
}

String _formatWorkoutDuration(int seconds) {
  final duration = Duration(seconds: seconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final remainingSeconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
}

class _RecentLogsPanel extends StatelessWidget {
  const _RecentLogsPanel({
    required this.strings,
    required this.recentMeal,
    required this.totalSets,
    required this.totalReps,
  });

  final AppStrings strings;
  final ManualFoodEntry? recentMeal;
  final int totalSets;
  final int totalReps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.recentLogsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            if (recentMeal != null)
              _DashboardLogRow(
                icon: Icons.local_cafe_outlined,
                title: recentMeal!.name,
                trailing: '${recentMeal!.calories} kcal',
              ),
            _DashboardLogRow(
              icon: Icons.directions_walk_outlined,
              title: strings.workoutTodayTitle,
              trailing: totalSets > 0 || totalReps > 0
                  ? '$totalSets sets • $totalReps reps'
                  : 'Pending',
              accentColor:
                  totalSets > 0 || totalReps > 0 ? Colors.green.shade400 : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardActionButton extends StatelessWidget {
  const _DashboardActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(84),
        ),
        child: child,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(84),
      ),
      child: child,
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

class _DashboardMacroTile extends StatelessWidget {
  const _DashboardMacroTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBurnCard extends StatelessWidget {
  const _PremiumBurnCard({
    required this.strings,
    required this.workoutCalories,
  });

  final AppStrings strings;
  final int workoutCalories;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        title: Text(strings.caloriesBurnedTitle.toUpperCase()),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(strings.caloriesBurnedSubtitle),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$workoutCalories kcal',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFD8A55D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Icon(Icons.local_fire_department_outlined, color: colors.tertiary),
          ],
        ),
      ),
    );
  }
}

class _PremiumWeightCard extends StatelessWidget {
  const _PremiumWeightCard({
    required this.strings,
    required this.weightKg,
    required this.onLogWeightPressed,
  });

  final AppStrings strings;
  final double? weightKg;
  final VoidCallback onLogWeightPressed;

  @override
  Widget build(BuildContext context) {
    final value = weightKg == null ? '--' : weightKg!.toStringAsFixed(1);
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        title: Text(strings.currentWeightCardTitle.toUpperCase()),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            weightKg == null ? strings.noWeightLogged : '$value kg',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        trailing: FilledButton.tonal(
          onPressed: onLogWeightPressed,
          child: const Icon(Icons.monitor_weight_outlined),
        ),
      ),
    );
  }
}

class _PremiumActivityCard extends StatelessWidget {
  const _PremiumActivityCard({
    required this.strings,
    required this.latestWorkout,
    required this.totalSets,
    required this.totalReps,
  });

  final AppStrings strings;
  final ManualWorkoutSession? latestWorkout;
  final int totalSets;
  final int totalReps;

  @override
  Widget build(BuildContext context) {
    final workout = latestWorkout;
    if (workout == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.todaysActivityTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(strings.noWorkoutsYet),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.todaysActivityTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.fitness_center_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(workout.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        strings.workoutActivitySummary(
                          minutes: workout.durationMinutes,
                          calories: workout.estimatedActiveCalories,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF8DC3F2)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
                '${strings.workoutSetsToday}: $totalSets • ${strings.workoutRepsToday}: $totalReps'),
          ],
        ),
      ),
    );
  }
}

class _PremiumRecentLogsCard extends StatelessWidget {
  const _PremiumRecentLogsCard({
    required this.strings,
    required this.recentMeal,
    required this.currentWeightKg,
  });

  final AppStrings strings;
  final ManualFoodEntry? recentMeal;
  final double? currentWeightKg;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.recentLogsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            if (recentMeal != null)
              _DashboardLogRow(
                icon: Icons.restaurant_outlined,
                title: recentMeal!.name,
                trailing: '${recentMeal!.calories} kcal',
              ),
            if (currentWeightKg != null)
              _DashboardLogRow(
                icon: Icons.monitor_weight_outlined,
                title: strings.currentWeightCardTitle,
                trailing: '${currentWeightKg!.toStringAsFixed(1)} kg',
                accentColor: Colors.green.shade400,
              ),
            if (recentMeal == null && currentWeightKg == null)
              Text(strings.noDailySummaryYet),
          ],
        ),
      ),
    );
  }
}

class _DashboardLogRow extends StatelessWidget {
  const _DashboardLogRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(
            trailing,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumInsightsCard extends StatelessWidget {
  const _PremiumInsightsCard({required this.strings, required this.onPressed});

  final AppStrings strings;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFD8A55D).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.insights_outlined, color: Color(0xFFD8A55D)),
        ),
        title: Text(strings.weeklyInsightsTitle),
        subtitle: Text(strings.weeklyInsightsSubtitle),
        trailing: const Icon(Icons.chevron_right_outlined),
        onTap: onPressed,
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.strings,
    required this.summary,
    required this.todayWeight,
    required this.onLogWeightPressed,
  });

  final AppStrings strings;
  final DailyNutritionSummary? summary;
  final DailyWeightEntry? todayWeight;
  final VoidCallback onLogWeightPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.todaySummaryTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: strings.caloriesConsumed,
                    value: '${summary?.totalCalories ?? 0} kcal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: strings.protein,
                    value: '${summary?.totalProteinGrams ?? 0} g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: strings.carbs,
                    value: '${summary?.totalCarbsGrams ?? 0} g',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: strings.fat,
                    value: '${summary?.totalFatGrams ?? 0} g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: strings.todayWeightTitle,
                    value: todayWeight == null
                        ? strings.noWeightLogged
                        : '${todayWeight!.weightKg} kg',
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onLogWeightPressed,
                  child: Text(strings.logWeightTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutTodayCard extends StatelessWidget {
  const _WorkoutTodayCard({
    required this.strings,
    required this.sessions,
    required this.workoutCalories,
    required this.totalSets,
    required this.totalReps,
  });

  final AppStrings strings;
  final List<ManualWorkoutSession> sessions;
  final int workoutCalories;
  final int totalSets;
  final int totalReps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.workoutTodayTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: strings.workoutCaloriesToday,
                    value: '$workoutCalories kcal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: strings.workoutSetsToday,
                    value: '$totalSets',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: strings.workoutRepsToday,
                    value: '$totalReps',
                  ),
                ),
              ],
            ),
            if (sessions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...sessions.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• ${session.title}: ${strings.maxWeightLabel(session.heaviestWeightKg)}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyTargetsCard extends StatelessWidget {
  const _DailyTargetsCard({
    required this.strings,
    required this.summary,
    required this.targets,
    required this.estimatedBalance,
  });

  final AppStrings strings;
  final ManualFoodSummary summary;
  final DailyTargets targets;
  final int estimatedBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.dailyTargetsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.goalSummary(targets.goal)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: strings.targetCaloriesTitle,
                    value: '${targets.targetCalories} kcal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: strings.targetProteinTitle,
                    value: '${targets.targetProteinGrams} g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: strings.estimatedBurnTitle,
                    value: '${targets.estimatedBurnCalories} kcal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: strings.workoutCaloriesToday,
                    value: '${targets.workoutCalories} kcal',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: strings.carbs,
                    value:
                        '${summary.totalCarbsGrams}/${targets.targetCarbsGrams} g',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: strings.fat,
                    value:
                        '${summary.totalFatGrams}/${targets.targetFatGrams} g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(strings.calorieDeltaMessage(estimatedBalance)),
          ],
        ),
      ),
    );
  }
}

class _WorkoutRecommendationCard extends StatelessWidget {
  const _WorkoutRecommendationCard({
    required this.strings,
    required this.recommendation,
  });

  final AppStrings strings;
  final GoalRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.workoutRecommendationsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(recommendation.routineName,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(recommendation.headline),
            const SizedBox(height: 12),
            ...recommendation.exercises.map((exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $exercise'),
                )),
            const SizedBox(height: 12),
            Text(
                '${strings.nutritionFocusTitle}: ${recommendation.nutritionFocus}'),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends ConsumerStatefulWidget {
  const _ProgressCard({this.selectedExercise});

  final String? selectedExercise;

  @override
  ConsumerState<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends ConsumerState<_ProgressCard> {
  ProgressMode _mode = ProgressMode.strength;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref);
    final points = switch (_mode) {
      ProgressMode.strength => ref.watch(progressStrengthProvider),
      ProgressMode.bodyWeight => ref.watch(progressBodyWeightProvider),
      ProgressMode.calories => ref.watch(progressCaloriesProvider),
      ProgressMode.combined => ref.watch(progressCombinedProvider),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.progressDiagramTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.workoutProgressHint),
            if (widget.selectedExercise != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  strings.filteredExerciseLabel(widget.selectedExercise!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/dashboard/progress'),
                icon: const Icon(Icons.insights_outlined),
                label: Text(strings.openProgressButton),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProgressModeChip(
                  label: strings.progressStrength,
                  selected: _mode == ProgressMode.strength,
                  onTap: () => setState(() => _mode = ProgressMode.strength),
                ),
                _ProgressModeChip(
                  label: strings.progressBodyWeight,
                  selected: _mode == ProgressMode.bodyWeight,
                  onTap: () => setState(() => _mode = ProgressMode.bodyWeight),
                ),
                _ProgressModeChip(
                  label: strings.progressCaloriesBurned,
                  selected: _mode == ProgressMode.calories,
                  onTap: () => setState(() => _mode = ProgressMode.calories),
                ),
                _ProgressModeChip(
                  label: strings.progressCombined,
                  selected: _mode == ProgressMode.combined,
                  onTap: () => setState(() => _mode = ProgressMode.combined),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (points.isEmpty)
              Text(strings.noProgressDataYet)
            else ...[
              if (_mode == ProgressMode.bodyWeight)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(strings.bodyWeightTrendDown),
                ),
              ProgressLineAreaChart(points: points, height: 200),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.strings,
    required this.entriesCount,
    required this.workoutCount,
    required this.proteinGap,
  });

  final AppStrings strings;
  final int entriesCount;
  final int workoutCount;
  final int? proteinGap;

  @override
  Widget build(BuildContext context) {
    late final String headline;
    late final String subtitle;
    late final String buttonLabel;
    late final VoidCallback onPressed;

    if (workoutCount == 0) {
      headline = strings.ctaLogWorkoutHeadline;
      subtitle = strings.ctaLogWorkoutSubtitle;
      buttonLabel = strings.quickActionWorkout;
      onPressed = () => context.go('/workout/manual');
    } else if (entriesCount == 0) {
      headline = strings.ctaAddMealHeadline;
      subtitle = strings.ctaAddMealSubtitle;
      buttonLabel = strings.addMealTitle;
      onPressed = () => context.go('/food/manual');
    } else if (proteinGap != null && proteinGap! > 0) {
      headline = strings.ctaProteinHeadline;
      subtitle = strings.ctaProteinSubtitle(proteinGap!);
      buttonLabel = strings.addMealTitle;
      onPressed = () => context.go('/food/manual');
    } else {
      headline = strings.ctaReviewProgressHeadline;
      subtitle = strings.ctaReviewProgressSubtitle;
      buttonLabel = strings.reviewProgressButton;
      onPressed = () => context.push('/dashboard/progress');
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
            Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.nextBestActionTitle,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Colors.white70)),
            const SizedBox(height: 10),
            Text(
              headline,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              icon: const Icon(Icons.arrow_forward_outlined),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressModeChip extends StatelessWidget {
  const _ProgressModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.tertiaryLabel,
    this.onTertiaryPressed,
  });

  final String title;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;
  final String? tertiaryLabel;
  final VoidCallback? onTertiaryPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: onPrimaryPressed,
                  icon: const Icon(Icons.restaurant_outlined),
                  label: Text(primaryLabel),
                ),
                OutlinedButton.icon(
                  onPressed: onSecondaryPressed,
                  icon: const Icon(Icons.fitness_center_outlined),
                  label: Text(secondaryLabel),
                ),
                if (tertiaryLabel != null && onTertiaryPressed != null)
                  OutlinedButton.icon(
                    onPressed: onTertiaryPressed,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: Text(tertiaryLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.strings,
    required this.summary,
    required this.dailyTargets,
    required this.estimatedBalance,
  });

  final AppStrings strings;
  final ManualFoodSummary summary;
  final DailyTargets? dailyTargets;
  final int? estimatedBalance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.dashboardFocusTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
                '${summary.totalCalories} kcal • ${summary.totalProteinGrams} g ${strings.protein}'),
            const SizedBox(height: 8),
            Text(
              dailyTargets == null
                  ? strings.proteinGoalPending
                  : strings.remainingProteinMessage(
                      max(
                        0,
                        dailyTargets!.targetProteinGrams -
                            summary.totalProteinGrams,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              estimatedBalance == null
                  ? strings.activityPending
                  : strings.calorieDeltaMessage(estimatedBalance!),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInfoCard extends StatelessWidget {
  const _EmptyInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message),
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        children: [child],
      ),
    );
  }
}

class _WorkoutHistoryCard extends ConsumerWidget {
  const _WorkoutHistoryCard({required this.strings, required this.session});

  final AppStrings strings;
  final ManualWorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        strings.workoutDateSetsSummary(
                          formatDisplayDateKey(session.dateKey),
                          session.totalSets,
                          session.totalReps,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${session.estimatedActiveCalories} kcal'),
                    const SizedBox(height: 4),
                    Text(strings.maxWeightLabel(session.heaviestWeightKg)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...session.sets.take(4).map(
                  (set) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      strings.exerciseWeightRepsLabel(
                        exerciseName: set.exerciseName,
                        weightKg: set.weightKg,
                        reps: set.reps,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () async {
                  await ref
                      .read(manualWorkoutSessionsProvider.notifier)
                      .deleteSession(session.id);

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.workoutDeletedMessage)),
                  );
                },
                child: Text(strings.deleteWorkoutButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({required this.entry, required this.strings});

  final ManualFoodEntry entry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.photoPath != null) ...[
                  MealPhotoView(
                    photoPath: entry.photoPath!,
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(strings.mealTypeName(entry.mealType)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${entry.calories} kcal'),
                    const SizedBox(height: 4),
                    Text('${entry.proteinGrams} g'),
                    const SizedBox(height: 4),
                    Text('${entry.carbsGrams} g C / ${entry.fatGrams} g F'),
                    const SizedBox(height: 4),
                    Text('${entry.sugarGrams} g S / ${entry.fiberGrams} g Fi'),
                    if (entry.confidence != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          '${strings.confidence}: ${(entry.confidence! * 100).round()}%'),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '/food/manual',
                      extra: entry,
                    ),
                    child: Text(strings.editMealButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      return OutlinedButton(
                        onPressed: () async {
                          await ref
                              .read(manualFoodEntriesProvider.notifier)
                              .deleteEntry(entry.id);

                          if (!context.mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(strings.mealDeletedMessage)),
                          );
                        },
                        child: Text(strings.deleteMealButton),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
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
                                color: DashboardTheme.primary)),
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
                          backgroundColor: DashboardTheme.surfaceMuted),
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
                      color: DashboardTheme.surfaceMuted,
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
                          backgroundColor: DashboardTheme.surfaceMuted)
                    ])),
              if (macros.first.$3 != null)
                Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: DashboardTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.insights,
                          size: 18, color: DashboardTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              '${strings.protein}: ${macros.first.$2.round()} / ${macros.first.$3} g',
                              style: t.bodySmall))
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
          color: DashboardTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall));
}
