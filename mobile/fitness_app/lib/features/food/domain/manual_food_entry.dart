class ManualFoodEntry {
  const ManualFoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.proteinGrams,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String mealType;
  final int calories;
  final int proteinGrams;
  final DateTime createdAt;
}

class ManualFoodSummary {
  const ManualFoodSummary({
    required this.totalCalories,
    required this.totalProteinGrams,
    required this.entryCount,
  });

  final int totalCalories;
  final int totalProteinGrams;
  final int entryCount;
}
