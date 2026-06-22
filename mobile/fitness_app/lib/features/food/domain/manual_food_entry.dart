class ManualFoodEntry {
  const ManualFoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.proteinGrams,
    required this.createdAt,
    this.photoPath,
  });

  final String id;
  final String name;
  final String mealType;
  final int calories;
  final int proteinGrams;
  final DateTime createdAt;
  final String? photoPath;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'createdAt': createdAt.toIso8601String(),
      'photoPath': photoPath,
    };
  }

  factory ManualFoodEntry.fromJson(Map<String, dynamic> json) {
    return ManualFoodEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      mealType: json['mealType'] as String,
      calories: json['calories'] as int,
      proteinGrams: json['proteinGrams'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoPath: json['photoPath'] as String?,
    );
  }
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

class DailyNutritionSummary {
  const DailyNutritionSummary({
    required this.dateKey,
    required this.totalCalories,
    required this.totalProteinGrams,
    required this.entryCount,
  });

  final String dateKey;
  final int totalCalories;
  final int totalProteinGrams;
  final int entryCount;
}
