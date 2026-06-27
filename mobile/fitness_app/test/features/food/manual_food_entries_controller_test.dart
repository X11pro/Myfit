import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/features/food/application/manual_food_entries_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists manual food entries with extended nutrition fields', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(manualFoodEntriesProvider.notifier).addEntry(
          name: 'Chicken bowl',
          mealType: 'lunch',
          calories: 620,
          proteinGrams: 42,
          carbsGrams: 55,
          fatGrams: 18,
          sugarGrams: 6,
          fiberGrams: 8,
          confidence: 0.84,
          photoPath: '/tmp/meal.jpg',
        );

    final rehydratedContainer = ProviderContainer();
    addTearDown(rehydratedContainer.dispose);

    rehydratedContainer.read(manualFoodEntriesProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final entries = rehydratedContainer.read(manualFoodEntriesProvider);

    expect(entries, hasLength(1));
    expect(entries.single.name, 'Chicken bowl');
    expect(entries.single.carbsGrams, 55);
    expect(entries.single.fatGrams, 18);
    expect(entries.single.sugarGrams, 6);
    expect(entries.single.fiberGrams, 8);
    expect(entries.single.confidence, 0.84);
    expect(entries.single.photoPath, '/tmp/meal.jpg');
  });

  test('builds nutrition summaries with carbs and fat totals', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(manualFoodEntriesProvider.notifier);
    await notifier.addEntry(
      name: 'Oats',
      mealType: 'breakfast',
      calories: 320,
      proteinGrams: 12,
      carbsGrams: 48,
      fatGrams: 7,
    );
    await notifier.addEntry(
      name: 'Yogurt',
      mealType: 'snack',
      calories: 180,
      proteinGrams: 15,
      carbsGrams: 16,
      fatGrams: 4,
    );

    final summary = container.read(manualFoodSummaryProvider);
    final dailySummary = container.read(todayNutritionSummaryProvider);

    expect(summary.totalCalories, 500);
    expect(summary.totalProteinGrams, 27);
    expect(summary.totalCarbsGrams, 64);
    expect(summary.totalFatGrams, 11);
    expect(summary.entryCount, 2);

    expect(dailySummary, isNotNull);
    expect(dailySummary!.totalCalories, 500);
    expect(dailySummary.totalProteinGrams, 27);
    expect(dailySummary.totalCarbsGrams, 64);
    expect(dailySummary.totalFatGrams, 11);
    expect(dailySummary.entryCount, 2);
  });
}
