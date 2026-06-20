import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        ],
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(entry.name),
        subtitle: Text(strings.mealTypeName(entry.mealType)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${entry.calories} kcal'),
            const SizedBox(height: 4),
            Text('${entry.proteinGrams} g'),
          ],
        ),
      ),
    );
  }
}
