import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/daily_weight_controller.dart';
import '../domain/daily_weight_entry.dart';
import '../../food/application/manual_food_entries_controller.dart';
import '../../food/domain/manual_food_entry.dart';
import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.dashboardTitle),
        actions: [
          IconButton(
            onPressed: () => context.go('/splash'),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(strings.helloUser(displayName),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _QuickActionCard(
            title: strings.quickActionsTitle,
            primaryLabel: strings.addMealTitle,
            onPrimaryPressed: () => context.go('/food/manual'),
            secondaryLabel: strings.addSharedFoodTitle,
            onSecondaryPressed: () => context.go('/food/shared-catalog'),
          ),
          const SizedBox(height: 16),
          _DailySummaryCard(
            strings: strings,
            summary: todaySummary,
            todayWeight: todayWeight,
            onLogWeightPressed: () => _showWeightDialog(context, ref, strings),
          ),
          const SizedBox(height: 16),
          _MetricCard(
            title: strings.caloriesConsumed,
            value: '${summary.totalCalories} kcal',
            subtitle: summary.entryCount == 0
                ? strings.mealsPending
                : strings.entriesCount(summary.entryCount),
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: strings.protein,
            value: '${summary.totalProteinGrams} g',
            subtitle: strings.proteinGoalPending,
          ),
          const SizedBox(height: 12),
          _MetricCard(
            title: strings.estimatedBalance,
            value: '0 kcal',
            subtitle: strings.activityPending,
          ),
          const SizedBox(height: 24),
          Text(strings.nextIntegration,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text(strings.mealsTodayTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            _EmptyMealsCard(message: strings.noMealsYet)
          else
            ...entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MealEntryCard(entry: entry, strings: strings),
                )),
          const SizedBox(height: 24),
          Text(strings.dailyHistoryTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (dailySummaries.isEmpty)
            _EmptyMealsCard(message: strings.noDailySummaryYet)
          else
            ...dailySummaries.take(7).map(
                  (summary) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DailyHistoryCard(
                      strings: strings,
                      summary: summary,
                    ),
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
              child: const Text('Cancel'),
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
  });

  final String title;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;

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
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPrimaryPressed,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(primaryLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _EmptyMealsCard extends StatelessWidget {
  const _EmptyMealsCard({required this.message});

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
