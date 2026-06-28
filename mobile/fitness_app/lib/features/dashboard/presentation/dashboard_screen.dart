import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../food/application/manual_food_entries_controller.dart';
import '../../food/domain/manual_food_entry.dart';
import '../../workout/application/manual_workout_controller.dart';
import '../../workout/domain/manual_workout_session.dart';
import '../application/daily_targets_calculator.dart';
import '../application/daily_weight_controller.dart';
import '../domain/daily_targets.dart';
import '../domain/daily_weight_entry.dart';
import 'widgets/progress_chart_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final strings = stringsFor(ref);
    final displayName = state.displayName ?? strings.defaultUserName;
    final summary = ref.watch(manualFoodSummaryProvider);
    final entries = ref.watch(manualFoodEntriesProvider);
    final todaySummary = ref.watch(todayNutritionSummaryProvider);
    final dailySummaries = ref.watch(dailyNutritionSummariesProvider);
    final todayWeight = ref.watch(todayWeightEntryProvider);
    final dailyTargets = ref.watch(dailyTargetsProvider);
    final workoutRecommendation = ref.watch(workoutRecommendationProvider);
    final selectedExercise = ref.watch(strengthExerciseFilterProvider);
    final todayWorkouts = ref.watch(todayWorkoutSessionsProvider);
    final todayWorkoutCalories = ref.watch(todayWorkoutCaloriesProvider);
    final totalSetsToday = todayWorkouts.fold<int>(
      0,
      (value, session) => value + session.totalSets,
    );
    final totalRepsToday = todayWorkouts.fold<int>(
      0,
      (value, session) => value + session.totalReps,
    );
    final estimatedBalance = dailyTargets == null
        ? null
        : summary.totalCalories - dailyTargets.estimatedBurnCalories;
    final proteinGap = dailyTargets == null
        ? null
        : max(0, dailyTargets.targetProteinGrams - summary.totalProteinGrams);

    return Scaffold(
      appBar: AppTopBar(title: strings.dashboardTitle, strings: strings),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(strings.helloUser(displayName),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _PrimaryActionCard(
            strings: strings,
            entriesCount: summary.entryCount,
            workoutCount: todayWorkouts.length,
            proteinGap: proteinGap,
          ),
          const SizedBox(height: 16),
          _QuickActionCard(
            title: strings.quickActionsTitle,
            primaryLabel: strings.addMealTitle,
            onPrimaryPressed: () => context.go('/food/manual'),
            secondaryLabel: strings.quickActionWorkout,
            onSecondaryPressed: () => context.go('/workout/manual'),
            tertiaryLabel: strings.addSharedFoodTitle,
            onTertiaryPressed: () => context.go('/food/shared-catalog'),
          ),
          const SizedBox(height: 16),
          _DailySummaryCard(
            strings: strings,
            summary: todaySummary,
            todayWeight: todayWeight,
            onLogWeightPressed: () => _showWeightDialog(context, ref, strings),
          ),
          const SizedBox(height: 16),
          _WorkoutTodayCard(
            strings: strings,
            sessions: todayWorkouts,
            workoutCalories: todayWorkoutCalories,
            totalSets: totalSetsToday,
            totalReps: totalRepsToday,
          ),
          const SizedBox(height: 16),
          if (dailyTargets != null) ...[
            _DailyTargetsCard(
              strings: strings,
              summary: summary,
              targets: dailyTargets,
              estimatedBalance: estimatedBalance ?? 0,
            ),
            const SizedBox(height: 16),
          ],
          if (workoutRecommendation != null) ...[
            _WorkoutRecommendationCard(
              strings: strings,
              recommendation: workoutRecommendation,
            ),
            const SizedBox(height: 16),
          ],
          _ProgressCard(selectedExercise: selectedExercise),
          const SizedBox(height: 16),
          _FocusCard(
            strings: strings,
            summary: summary,
            dailyTargets: dailyTargets,
            estimatedBalance: estimatedBalance,
          ),
          const SizedBox(height: 24),
          _CollapsibleSection(
            title: strings.recentMealsSection,
            subtitle: strings.collapseSectionHint,
            initiallyExpanded: true,
            child: entries.isEmpty
                ? _EmptyInfoCard(message: strings.noMealsYet)
                : Column(
                    children: entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _MealEntryCard(
                                  entry: entry, strings: strings),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _CollapsibleSection(
            title: strings.recentWorkoutsSection,
            subtitle: strings.collapseSectionHint,
            child: Consumer(
              builder: (context, ref, child) {
                final workouts = ref.watch(manualWorkoutSessionsProvider);
                if (workouts.isEmpty) {
                  return _EmptyInfoCard(message: strings.noWorkoutsYet);
                }

                return Column(
                  children: workouts
                      .take(5)
                      .map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WorkoutHistoryCard(
                            strings: strings,
                            session: session,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _CollapsibleSection(
            title: strings.dailyHistorySection,
            subtitle: strings.collapseSectionHint,
            child: dailySummaries.isEmpty
                ? _EmptyInfoCard(message: strings.noDailySummaryYet)
                : Column(
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
      ),
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
      child: ListTile(
        title: Text(summary.dateKey),
        subtitle: Text(
            strings.dateSummarySubtitle(summary.dateKey, summary.entryCount)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${summary.totalCalories} kcal'),
            const SizedBox(height: 4),
            Text('${summary.totalProteinGrams} g'),
            const SizedBox(height: 4),
            Text(
                '${summary.totalCarbsGrams} g C / ${summary.totalFatGrams} g F'),
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
                          session.dateKey,
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(entry.photoPath!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          child: const Icon(Icons.image_not_supported_outlined),
                        );
                      },
                    ),
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
