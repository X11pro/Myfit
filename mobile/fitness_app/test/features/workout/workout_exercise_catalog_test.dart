import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/features/workout/domain/workout_exercise_catalog.dart';

void main() {
  test('catalog meets the minimum exercise coverage for each muscle group', () {
    final exercisesByGroup = <String, List<WorkoutExercise>>{};
    for (final exercise in workoutExerciseCatalog) {
      exercisesByGroup
          .putIfAbsent(exercise.muscleGroup, () => [])
          .add(exercise);
    }

    for (final group in ['Chest', 'Back', 'Legs']) {
      expect(exercisesByGroup[group], hasLength(greaterThanOrEqualTo(10)));
    }
    for (final group in ['Shoulders', 'Biceps', 'Triceps', 'Core', 'Calves']) {
      expect(exercisesByGroup[group], hasLength(greaterThanOrEqualTo(6)));
    }
  });

  test('catalog returns exercises only for the selected muscle group', () {
    expect(
      exercisesForMuscleGroup('Chest'),
      contains('Flat barbell or dumbbell bench press'),
    );
    expect(
      exercisesForMuscleGroup('Back'),
      contains('Bent over barbell or dumbbell rows'),
    );
    expect(
      exercisesForMuscleGroup('Chest'),
      isNot(contains('Bent over barbell or dumbbell rows')),
    );
    expect(exercisesForMuscleGroup('Legs'), contains('Barbell squat'));
    expect(workoutMuscleGroups, containsAll(['Chest', 'Back', 'Legs']));
  });
}
