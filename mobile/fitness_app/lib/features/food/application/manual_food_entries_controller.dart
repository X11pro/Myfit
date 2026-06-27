import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/manual_food_entry.dart';

final manualFoodEntriesProvider =
    NotifierProvider<ManualFoodEntriesNotifier, List<ManualFoodEntry>>(
  ManualFoodEntriesNotifier.new,
);

final manualFoodSummaryProvider = Provider<ManualFoodSummary>((ref) {
  final entries = ref.watch(manualFoodEntriesProvider);

  var totalCalories = 0;
  var totalProteinGrams = 0;
  var totalCarbsGrams = 0;
  var totalFatGrams = 0;

  for (final entry in entries) {
    totalCalories += entry.calories;
    totalProteinGrams += entry.proteinGrams;
    totalCarbsGrams += entry.carbsGrams;
    totalFatGrams += entry.fatGrams;
  }

  return ManualFoodSummary(
    totalCalories: totalCalories,
    totalProteinGrams: totalProteinGrams,
    totalCarbsGrams: totalCarbsGrams,
    totalFatGrams: totalFatGrams,
    entryCount: entries.length,
  );
});

final dailyNutritionSummariesProvider =
    Provider<List<DailyNutritionSummary>>((ref) {
  final entries = ref.watch(manualFoodEntriesProvider);
  final totals =
      <String, ({int calories, int protein, int carbs, int fat, int count})>{};

  for (final entry in entries) {
    final dateKey = _dateKey(entry.createdAt);
    final current = totals[dateKey] ??
        (calories: 0, protein: 0, carbs: 0, fat: 0, count: 0);
    totals[dateKey] = (
      calories: current.calories + entry.calories,
      protein: current.protein + entry.proteinGrams,
      carbs: current.carbs + entry.carbsGrams,
      fat: current.fat + entry.fatGrams,
      count: current.count + 1,
    );
  }

  final summaries = totals.entries
      .map(
        (entry) => DailyNutritionSummary(
          dateKey: entry.key,
          totalCalories: entry.value.calories,
          totalProteinGrams: entry.value.protein,
          totalCarbsGrams: entry.value.carbs,
          totalFatGrams: entry.value.fat,
          entryCount: entry.value.count,
        ),
      )
      .toList()
    ..sort((a, b) => b.dateKey.compareTo(a.dateKey));

  return summaries;
});

final todayNutritionSummaryProvider = Provider<DailyNutritionSummary?>((ref) {
  final summaries = ref.watch(dailyNutritionSummariesProvider);
  final todayKey = _dateKey(DateTime.now());

  for (final summary in summaries) {
    if (summary.dateKey == todayKey) {
      return summary;
    }
  }

  return null;
});

class ManualFoodEntriesNotifier extends Notifier<List<ManualFoodEntry>> {
  static const _storageKey = 'manual_food_entries';

  @override
  List<ManualFoodEntry> build() {
    Future<void>.microtask(_loadEntries);

    return const [];
  }

  Future<void> addEntry({
    required String name,
    required String mealType,
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    int sugarGrams = 0,
    int fiberGrams = 0,
    double? confidence,
    String? photoPath,
  }) async {
    state = [
      ManualFoodEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        mealType: mealType,
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
        sugarGrams: sugarGrams,
        fiberGrams: fiberGrams,
        createdAt: DateTime.now(),
        confidence: confidence,
        photoPath: photoPath,
      ),
      ...state,
    ];

    await _persistEntries();
  }

  Future<void> updateEntry({
    required String id,
    required String name,
    required String mealType,
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    int sugarGrams = 0,
    int fiberGrams = 0,
    double? confidence,
    String? photoPath,
  }) async {
    state = [
      for (final entry in state)
        if (entry.id == id)
          ManualFoodEntry(
            id: entry.id,
            name: name,
            mealType: mealType,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            sugarGrams: sugarGrams,
            fiberGrams: fiberGrams,
            createdAt: entry.createdAt,
            confidence: confidence,
            photoPath: photoPath,
          )
        else
          entry,
    ];

    await _persistEntries();
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((entry) => entry.id != id).toList();
    await _persistEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(_storageKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return;
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;
    state = decoded
        .map(
            (item) => ManualFoodEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((entry) => entry.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

String _dateKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
