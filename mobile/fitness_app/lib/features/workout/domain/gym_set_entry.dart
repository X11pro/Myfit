class GymSetEntry {
  const GymSetEntry({
    required this.exerciseName,
    required this.muscleGroup,
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.rpe,
  });

  final String exerciseName;
  final String muscleGroup;
  final int setNumber;
  final int reps;
  final double weightKg;
  final double? rpe;

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'setNumber': setNumber,
      'reps': reps,
      'weightKg': weightKg,
      'rpe': rpe,
    };
  }

  factory GymSetEntry.fromJson(Map<String, dynamic> json) {
    return GymSetEntry(
      exerciseName: json['exerciseName'] as String? ?? '',
      muscleGroup: json['muscleGroup'] as String? ?? '',
      setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      rpe: (json['rpe'] as num?)?.toDouble(),
    );
  }
}
