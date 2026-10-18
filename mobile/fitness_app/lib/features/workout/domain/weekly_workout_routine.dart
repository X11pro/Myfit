enum WorkoutRoutineBlockType {
  normal('normal'),
  superset('superset'),
  triset('triset');

  const WorkoutRoutineBlockType(this.id);

  final String id;

  int get exerciseCount => switch (this) {
        WorkoutRoutineBlockType.normal => 1,
        WorkoutRoutineBlockType.superset => 2,
        WorkoutRoutineBlockType.triset => 3,
      };

  static WorkoutRoutineBlockType fromId(String? id) {
    return WorkoutRoutineBlockType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => WorkoutRoutineBlockType.normal,
    );
  }
}

class WorkoutRoutineExercise {
  const WorkoutRoutineExercise({
    required this.exerciseName,
    required this.muscleGroup,
    this.sets = 3,
    this.reps = 10,
    this.weightKg = 0,
  });

  final String exerciseName;
  final String muscleGroup;
  final int sets;
  final int reps;
  final double weightKg;

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        'muscleGroup': muscleGroup,
        'sets': sets,
        'reps': reps,
        'weightKg': weightKg,
      };

  factory WorkoutRoutineExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutineExercise(
      exerciseName: json['exerciseName'] as String? ?? '',
      muscleGroup: json['muscleGroup'] as String? ?? '',
      sets: (json['sets'] as num?)?.toInt() ?? 3,
      reps: (json['reps'] as num?)?.toInt() ?? 10,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WorkoutRoutineBlock {
  const WorkoutRoutineBlock({
    required this.type,
    required this.exercises,
  });

  final WorkoutRoutineBlockType type;
  final List<WorkoutRoutineExercise> exercises;

  Map<String, dynamic> toJson() => {
        'type': type.id,
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      };

  factory WorkoutRoutineBlock.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'] as List<dynamic>? ?? const [];
    return WorkoutRoutineBlock(
      type: WorkoutRoutineBlockType.fromId(json['type'] as String?),
      exercises: rawExercises
          .map(
            (item) => WorkoutRoutineExercise.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class WeeklyWorkoutRoutine {
  const WeeklyWorkoutRoutine({
    required this.id,
    required this.name,
    this.blocksByWeekday = const {},
  });

  final String id;
  final String name;
  final Map<int, List<WorkoutRoutineBlock>> blocksByWeekday;

  List<WorkoutRoutineBlock> blocksFor(DateTime date) =>
      blocksByWeekday[date.weekday] ?? const [];

  WeeklyWorkoutRoutine copyWithDay(
    int weekday,
    List<WorkoutRoutineBlock> blocks,
  ) {
    return WeeklyWorkoutRoutine(
      id: id,
      name: name,
      blocksByWeekday: {
        ...blocksByWeekday,
        weekday: List.unmodifiable(blocks),
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'days': {
          for (final entry in blocksByWeekday.entries)
            entry.key.toString():
                entry.value.map((block) => block.toJson()).toList(),
        },
      };

  factory WeeklyWorkoutRoutine.fromJson(Map<String, dynamic> json) {
    final rawDays = Map<String, dynamic>.from(json['days'] as Map? ?? const {});
    final blocksByWeekday = <int, List<WorkoutRoutineBlock>>{};
    for (final entry in rawDays.entries) {
      final weekday = int.tryParse(entry.key);
      if (weekday == null ||
          weekday < DateTime.monday ||
          weekday > DateTime.sunday) {
        continue;
      }
      final rawBlocks = entry.value as List<dynamic>? ?? const [];
      blocksByWeekday[weekday] = rawBlocks
          .map(
            (item) => WorkoutRoutineBlock.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }
    return WeeklyWorkoutRoutine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'My routine',
      blocksByWeekday: blocksByWeekday,
    );
  }
}

class WorkoutRoutineLibrary {
  const WorkoutRoutineLibrary({
    this.routines = const [],
    this.activeRoutineId,
  });

  final List<WeeklyWorkoutRoutine> routines;
  final String? activeRoutineId;

  WeeklyWorkoutRoutine? get activeRoutine {
    for (final routine in routines) {
      if (routine.id == activeRoutineId) {
        return routine;
      }
    }
    return routines.isEmpty ? null : routines.first;
  }

  WorkoutRoutineLibrary copyWith({
    List<WeeklyWorkoutRoutine>? routines,
    String? activeRoutineId,
    bool clearActiveRoutine = false,
  }) {
    return WorkoutRoutineLibrary(
      routines: routines ?? this.routines,
      activeRoutineId:
          clearActiveRoutine ? null : activeRoutineId ?? this.activeRoutineId,
    );
  }

  Map<String, dynamic> toJson() => {
        'routines': routines.map((routine) => routine.toJson()).toList(),
        'activeRoutineId': activeRoutineId,
      };

  factory WorkoutRoutineLibrary.fromJson(Map<String, dynamic> json) {
    final rawRoutines = json['routines'] as List<dynamic>? ?? const [];
    return WorkoutRoutineLibrary(
      routines: rawRoutines
          .map(
            (item) => WeeklyWorkoutRoutine.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      activeRoutineId: json['activeRoutineId'] as String?,
    );
  }
}
