import 'gym_set_entry.dart';

class ManualWorkoutSession {
  const ManualWorkoutSession({
    required this.id,
    required this.title,
    required this.dateKey,
    required this.durationMinutes,
    required this.estimatedActiveCalories,
    required this.createdAt,
    required this.sets,
    this.notes,
  });

  final String id;
  final String title;
  final String dateKey;
  final int durationMinutes;
  final int estimatedActiveCalories;
  final DateTime createdAt;
  final List<GymSetEntry> sets;
  final String? notes;

  int get totalSets => sets.length;

  int get totalReps {
    var total = 0;
    for (final set in sets) {
      total += set.reps;
    }
    return total;
  }

  double get heaviestWeightKg {
    var maxWeight = 0.0;
    for (final set in sets) {
      if (set.weightKg > maxWeight) {
        maxWeight = set.weightKg;
      }
    }
    return maxWeight;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dateKey': dateKey,
      'durationMinutes': durationMinutes,
      'estimatedActiveCalories': estimatedActiveCalories,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'sets': sets.map((set) => set.toJson()).toList(),
    };
  }

  factory ManualWorkoutSession.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'] as List<dynamic>? ?? const [];

    return ManualWorkoutSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      estimatedActiveCalories:
          (json['estimatedActiveCalories'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      sets: rawSets
          .map((item) => GymSetEntry.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
