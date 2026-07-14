class ManualFoodEntry {
  const ManualFoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.sugarGrams,
    required this.fiberGrams,
    required this.createdAt,
    this.estimatedGrams,
    this.ingredientsText,
    this.confidence,
    this.photoPath,
    this.remotePhotoId,
    this.remotePhotoStoragePath,
  });

  final String id;
  final String name;
  final String mealType;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int sugarGrams;
  final int fiberGrams;
  final DateTime createdAt;
  final int? estimatedGrams;
  final String? ingredientsText;
  final double? confidence;
  final String? photoPath;
  final String? remotePhotoId;
  final String? remotePhotoStoragePath;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'sugarGrams': sugarGrams,
      'fiberGrams': fiberGrams,
      'createdAt': createdAt.toIso8601String(),
      'estimatedGrams': estimatedGrams,
      'ingredientsText': ingredientsText,
      'confidence': confidence,
      'photoPath': photoPath,
      'remotePhotoId': remotePhotoId,
      'remotePhotoStoragePath': remotePhotoStoragePath,
    };
  }

  factory ManualFoodEntry.fromJson(Map<String, dynamic> json) {
    return ManualFoodEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      mealType: json['mealType'] as String,
      calories: json['calories'] as int,
      proteinGrams: json['proteinGrams'] as int,
      carbsGrams: (json['carbsGrams'] as num?)?.toInt() ?? 0,
      fatGrams: (json['fatGrams'] as num?)?.toInt() ?? 0,
      sugarGrams: (json['sugarGrams'] as num?)?.toInt() ?? 0,
      fiberGrams: (json['fiberGrams'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      estimatedGrams: (json['estimatedGrams'] as num?)?.toInt(),
      ingredientsText: json['ingredientsText'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      photoPath: json['photoPath'] as String?,
      remotePhotoId: json['remotePhotoId'] as String?,
      remotePhotoStoragePath: json['remotePhotoStoragePath'] as String?,
    );
  }
}

class ManualFoodSummary {
  const ManualFoodSummary({
    required this.totalCalories,
    required this.totalProteinGrams,
    required this.totalCarbsGrams,
    required this.totalFatGrams,
    required this.entryCount,
  });

  final int totalCalories;
  final int totalProteinGrams;
  final int totalCarbsGrams;
  final int totalFatGrams;
  final int entryCount;
}

class DailyNutritionSummary {
  const DailyNutritionSummary({
    required this.dateKey,
    required this.totalCalories,
    required this.totalProteinGrams,
    required this.totalCarbsGrams,
    required this.totalFatGrams,
    required this.entryCount,
  });

  final String dateKey;
  final int totalCalories;
  final int totalProteinGrams;
  final int totalCarbsGrams;
  final int totalFatGrams;
  final int entryCount;
}
