class WorkoutExercise {
  const WorkoutExercise({
    required this.name,
    required this.muscleGroup,
  });

  final String name;
  final String muscleGroup;
}

const workoutExerciseCatalog = <WorkoutExercise>[
  WorkoutExercise(
      name: 'Flat barbell or dumbbell bench press', muscleGroup: 'Chest'),
  WorkoutExercise(
      name: 'Incline barbell or dumbbell bench press', muscleGroup: 'Chest'),
  WorkoutExercise(
      name: 'Decline barbell or dumbbell bench press', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Flat chest press machine', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Incline chest press machine', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Decline chest press machine', muscleGroup: 'Chest'),
  WorkoutExercise(
      name: 'Dips (parallel bars, slight forward lean)', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Push-ups', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Flat dumbbell flyes', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Incline dumbbell flyes', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Decline dumbbell flyes', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Pec deck machine', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Cable crossovers/cable flyes', muscleGroup: 'Chest'),
  WorkoutExercise(name: 'Pull-ups', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Chin-ups', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Lat pull-downs', muscleGroup: 'Back'),
  WorkoutExercise(
      name: 'Bent over barbell or dumbbell rows', muscleGroup: 'Back'),
  WorkoutExercise(name: 'T-bar rows', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Seated cable rows', muscleGroup: 'Back'),
  WorkoutExercise(
      name: 'Chest supported barbell or dumbbell rows', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Chest supported machine rows', muscleGroup: 'Back'),
  WorkoutExercise(name: 'Inverted rows', muscleGroup: 'Back'),
  WorkoutExercise(
      name: 'Barbell, dumbbell or machine shrugs', muscleGroup: 'Back'),
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
  WorkoutExercise(
      name: 'Seated overhead barbell or dumbbell press',
      muscleGroup: 'Shoulders'),
  WorkoutExercise(
      name: 'Standing overhead barbell or dumbbell press',
      muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Overhead machine press', muscleGroup: 'Shoulders'),
  WorkoutExercise(name: 'Arnold press', muscleGroup: 'Shoulders'),
  WorkoutExercise(
      name: 'Barbell, dumbbell or machine upright rows',
      muscleGroup: 'Shoulders'),
  WorkoutExercise(
      name: 'Dumbbell, cable or machine lateral raises',
      muscleGroup: 'Shoulders'),
  WorkoutExercise(
      name: 'Dumbbell, cable or machine front raises',
      muscleGroup: 'Shoulders'),
  WorkoutExercise(
      name: 'Barbell, dumbbell or machine rear delt rows, raises or flyes',
      muscleGroup: 'Shoulders'),
  WorkoutExercise(
      name: 'Standing barbell or dumbbell curls', muscleGroup: 'Biceps'),
  WorkoutExercise(
      name: 'Barbell or dumbbell preacher curls', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Seated dumbbell curls', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Incline dumbbell curls', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Hammer curls', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Concentration curls', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Cable curls', muscleGroup: 'Biceps'),
  WorkoutExercise(name: 'Biceps curl machine', muscleGroup: 'Biceps'),
  WorkoutExercise(
      name: 'Dips (parallel bars, elbows close)', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Flat close grip bench press', muscleGroup: 'Triceps'),
  WorkoutExercise(
      name: 'Decline close grip bench press', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Close grip push-ups', muscleGroup: 'Triceps'),
  WorkoutExercise(
      name: 'Lying barbell or dumbbell triceps extensions',
      muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Skull crushers', muscleGroup: 'Triceps'),
  WorkoutExercise(
      name: 'Overhead barbell or dumbbell triceps extensions',
      muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Cable press-downs', muscleGroup: 'Triceps'),
  WorkoutExercise(name: 'Bench dips', muscleGroup: 'Triceps'),
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
