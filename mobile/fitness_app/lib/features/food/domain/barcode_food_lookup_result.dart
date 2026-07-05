class BarcodeFoodLookupResult {
  const BarcodeFoodLookupResult({
    required this.name,
    this.brand,
    this.source,
    this.sourceId,
    this.cached = false,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.sugarPer100g,
    this.fiberPer100g,
    this.confidence,
    this.nutritionQualityScore,
    this.nutritionQualityReason,
  });

  final String name;
  final String? brand;
  final String? source;
  final String? sourceId;
  final bool cached;
  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? sugarPer100g;
  final double? fiberPer100g;
  final double? confidence;
  final double? nutritionQualityScore;
  final String? nutritionQualityReason;
}
