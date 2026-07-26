class WorkoutExercise {
  const WorkoutExercise({
    required this.name,
    required this.muscleGroup,
  });

  final String name;
  final String muscleGroup;
}

const workoutExerciseCatalog = <WorkoutExercise>[
  WorkoutExercise(name: 'Barbell bench press', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Dumbbell bench press', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Incline barbell press', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Incline dumbbell press', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Chest fly', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Cable crossover', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Push-up', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Chest dip', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Machine chest press', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Pec deck', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Pull-up', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Lat pulldown', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Barbell row', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Dumbbell row', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Seated cable row', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Chest-supported row', muscleGroup: 'Back'),
  WorkoutExercise(name: 'T-bar row', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Straight-arm pulldown', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Face pull', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Back extension', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Barbell squat', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Front squat', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Leg press', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Romanian deadlift', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Leg extension', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Lying leg curl', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Bulgarian split squat', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Walking lunge', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Hack squat', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Hip thrust', muscleGroup: 'Legs'),
  WorkoutExercise(name: 'Overhead press', muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Dumbbell shoulder press', muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Lateral raise', muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Front raise', muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Rear delt fly', muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Upright row', muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Barbell curl', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Dumbbell curl', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Hammer curl', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Incline dumbbell curl', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Preacher curl', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Cable curl', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Triceps pushdown', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Skull crusher', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Close-grip bench press', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Overhead triceps extension', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Triceps dip', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Cable triceps kickback', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Plank', muscleGroup: 'Core'),
  WorkoutExercise(name: 'Crunch', muscleGroup: 'Core'),
  WorkoutExercise(name: 'Hanging knee raise', muscleGroup: 'Core'),
  WorkoutExercise(name: 'Cable crunch', muscleGroup: 'Core'),
  WorkoutExercise(name: 'Russian twist', muscleGroup: 'Core'),
  WorkoutExercise(name: 'Ab wheel rollout', muscleGroup: 'Core'),
  WorkoutExercise(name: 'Standing calf raise', muscleGroup: 'Calves'),
  WorkoutExercise(name: 'Seated calf raise', muscleGroup: 'Calves'),
  WorkoutExercise(name: 'Donkey calf raise', muscleGroup: 'Calves'),
  WorkoutExercise(name: 'Single-leg calf raise', muscleGroup: 'Calves'),
  WorkoutExercise(name: 'Calf press on leg press', muscleGroup: 'Calves'),
  WorkoutExercise(name: 'Jump rope', muscleGroup: 'Calves'),
];

List<String> get workoutMuscleGroups {
  final groups = <String>[];
  for (final exercise in workoutExerciseCatalog) {
    if (!groups.contains(exercise.muscleGroup)) {
      groups.add(exercise.muscleGroup);
    }
  }
  return groups;
}

List<String> exercisesForMuscleGroup(String muscleGroup) => [
      for (final exercise in workoutExerciseCatalog)
        if (exercise.muscleGroup == muscleGroup) exercise.name,
    ];
