class DailyWeightEntry {
  const DailyWeightEntry({
    required this.dateKey,
    required this.weightKg,
  });

  final String dateKey;
  final double weightKg;

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'weightKg': weightKg,
    };
  }

  factory DailyWeightEntry.fromJson(Map<String, dynamic> json) {
    return DailyWeightEntry(
      dateKey: json['dateKey'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
    );
  }
}
