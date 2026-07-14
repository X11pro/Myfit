import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_language.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/manual_food_entries_controller.dart';
import '../domain/manual_food_entry.dart';
import 'widgets/meal_photo_view.dart';

class FoodGalleryScreen extends ConsumerWidget {
  const FoodGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = stringsFor(ref);
    final entries = ref.watch(manualFoodEntriesProvider);
    final photoEntries = entries
        .where((entry) => (entry.photoPath ?? '').trim().isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppTopBar(title: strings.foodGalleryTitle, strings: strings),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.foodGallerySubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            strings.savedMealPhotosCount(photoEntries.length),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (photoEntries.isEmpty)
            _EmptyGalleryCard(strings: strings)
          else
            ...photoEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _FoodGalleryCard(entry: entry, strings: strings),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyGalleryCard extends StatelessWidget {
  const _EmptyGalleryCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.noMealPhotosYet,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(strings.foodGalleryEmptyHint),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => context.go('/food/manual'),
              child: Text(strings.addMealTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoodGalleryCard extends ConsumerWidget {
  const _FoodGalleryCard({required this.entry, required this.strings});

  final ManualFoodEntry entry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoPath = entry.photoPath!;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MealPhotoView(
            photoPath: photoPath,
            width: double.infinity,
            height: 220,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  '${strings.mealTypeName(entry.mealType)} • ${_formatDate(entry.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MacroChip(
                        label: strings.caloriesLabel,
                        value: '${entry.calories} kcal'),
                    _MacroChip(
                        label: strings.protein,
                        value: '${entry.proteinGrams} g'),
                    _MacroChip(
                        label: strings.carbs, value: '${entry.carbsGrams} g'),
                    _MacroChip(
                        label: strings.fat, value: '${entry.fatGrams} g'),
                    _MacroChip(
                        label: strings.sugar, value: '${entry.sugarGrams} g'),
                    _MacroChip(
                        label: strings.fiber, value: '${entry.fiberGrams} g'),
                    if (entry.confidence != null)
                      _MacroChip(
                        label: strings.confidence,
                        value: '${(entry.confidence! * 100).round()}%',
                      ),
                    if (entry.estimatedGrams != null)
                      _MacroChip(
                        label: strings.mealWeightLabel,
                        value: '${entry.estimatedGrams} g',
                      ),
                  ],
                ),
                if ((entry.ingredientsText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(strings.ingredientsLabel,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(entry.ingredientsText!),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            context.push('/food/manual', extra: entry),
                        child: Text(strings.editMealButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
