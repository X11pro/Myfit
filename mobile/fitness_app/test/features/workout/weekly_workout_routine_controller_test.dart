import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/features/workout/application/weekly_workout_routine_controller.dart';
import 'package:fitness_app/features/workout/domain/weekly_workout_routine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists a weekly routine and selects blocks by date', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const block = WorkoutRoutineBlock(
      type: WorkoutRoutineBlockType.superset,
      exercises: [
        WorkoutRoutineExercise(
          exerciseName: 'Flat barbell or dumbbell bench press',
          muscleGroup: 'Chest',
          weightKg: 20,
        ),
        WorkoutRoutineExercise(
          exerciseName: 'Seated cable rows',
          muscleGroup: 'Back',
        ),
      ],
    );

    final notifier = container.read(weeklyWorkoutRoutineProvider.notifier);
    await notifier.createRoutine('Ernesto beginner');
    final routineId =
        container.read(weeklyWorkoutRoutineProvider).activeRoutine!.id;
    await notifier.setDayBlocks(routineId, DateTime.monday, const [block]);
    await notifier.createRoutine('Ernesto advanced');
    await notifier.selectRoutine(routineId);
    await notifier.renameRoutine(routineId, 'Ernesto intermediate');

    final rehydratedContainer = ProviderContainer();
    addTearDown(rehydratedContainer.dispose);
    rehydratedContainer.read(weeklyWorkoutRoutineProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final library = rehydratedContainer.read(weeklyWorkoutRoutineProvider);
    final routine = library.activeRoutine!;
    final mondayBlocks = routine.blocksFor(DateTime(2026, 8, 3));

    expect(library.routines, hasLength(2));
    expect(routine.name, 'Ernesto intermediate');
    expect(mondayBlocks, hasLength(1));
    expect(mondayBlocks.single.type, WorkoutRoutineBlockType.superset);
    expect(mondayBlocks.single.exercises, hasLength(2));
    expect(mondayBlocks.single.exercises.first.sets, 3);
    expect(mondayBlocks.single.exercises.first.reps, 10);
    expect(mondayBlocks.single.exercises.first.weightKg, 20);
    expect(routine.blocksFor(DateTime(2026, 8, 4)), isEmpty);
  });
}
