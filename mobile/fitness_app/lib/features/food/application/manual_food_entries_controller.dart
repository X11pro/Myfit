import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/manual_food_entry.dart';

final manualFoodEntriesProvider =
    NotifierProvider<ManualFoodEntriesNotifier, List<ManualFoodEntry>>(
  ManualFoodEntriesNotifier.new,
);

final manualFoodSummaryProvider = Provider<ManualFoodSummary>((ref) {
  final entries = ref.watch(manualFoodEntriesProvider);

  var totalCalories = 0;
  var totalProteinGrams = 0;

  for (final entry in entries) {
    totalCalories += entry.calories;
    totalProteinGrams += entry.proteinGrams;
  }

  return ManualFoodSummary(
    totalCalories: totalCalories,
    totalProteinGrams: totalProteinGrams,
    entryCount: entries.length,
  );
});

class ManualFoodEntriesNotifier extends Notifier<List<ManualFoodEntry>> {
  @override
  List<ManualFoodEntry> build() => const [];

  void addEntry({
    required String name,
    required String mealType,
    required int calories,
    required int proteinGrams,
  }) {
    state = [
      ManualFoodEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        mealType: mealType,
        calories: calories,
        proteinGrams: proteinGrams,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
  }
}
