import 'dart:convert';

import 'package:fitness_app/features/workout/application/manual_workout_controller.dart';
import 'package:fitness_app/features/workout/application/weekly_workout_routine_controller.dart';
import 'package:fitness_app/features/workout/domain/gym_set_entry.dart';
import 'package:fitness_app/features/workout/domain/weekly_workout_routine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitness_app/shared/submission_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

WorkoutRoutineBlock block(String name, {double kg = 80}) => WorkoutRoutineBlock(
      type: WorkoutRoutineBlockType.normal,
      exercises: [
        WorkoutRoutineExercise(
          exerciseName: name,
          muscleGroup: 'Chest',
          weightKg: kg,
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('same draft ID saves once; identical numbered sets survive', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(manualWorkoutSessionsProvider.notifier);
    final id = newSubmissionId();
    Future<void> save(String submissionId) => notifier.addSession(
          submissionId: submissionId,
          title: 'Push',
          date: DateTime(2026, 11, 22),
          durationMinutes: 10,
          estimatedActiveCalories: 0,
          sets: [
            for (final number in [1, 2, 3])
              GymSetEntry(
                exerciseName: 'Bench press',
                muscleGroup: 'Chest',
                setNumber: number,
                reps: 8,
                weightKg: 80,
              ),
          ],
        );

    await Future.wait([save(id), save(id)]);
    expect(container.read(manualWorkoutSessionsProvider), hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    final rows =
        jsonDecode(prefs.getString('manual_workout_sessions')!) as List;
    expect(rows, hasLength(1));
    expect(
      (rows.single['sets'] as List).map((set) => set['setNumber']),
      [1, 2, 3],
    );
    await save(newSubmissionId());
    expect(container.read(manualWorkoutSessionsProvider), hasLength(2));
  });

  test('routine names and movements reject duplicates across actions',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(weeklyWorkoutRoutineProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await Future.wait([
      notifier.createRoutine('Push Day A'),
      notifier.createRoutine(' push   day a '),
    ]);
    final id = container.read(weeklyWorkoutRoutineProvider).routines.single.id;
    await notifier.createRoutine('Pull');
    final second = container.read(weeklyWorkoutRoutineProvider).activeRoutine!;
    await notifier.renameRoutine(second.id, ' PUSH DAY A ');
    expect(container.read(weeklyWorkoutRoutineProvider).activeRoutine!.name,
        'Pull');

    final bench = block('Bench Press');
    final duplicate = block('  bench   PRESS ', kg: 82.5);
    await notifier.setDayBlocks(id, DateTime.monday, [bench]);
    await notifier.setDayBlocks(id, DateTime.monday, [bench, duplicate]);
    await notifier.setDayBlocks(id, DateTime.thursday, [duplicate]);
    final library = container.read(weeklyWorkoutRoutineProvider);
    final routine = library.routines.first;
    expect(routine.blocksByWeekday[DateTime.monday], [bench]);
    expect(routine.blocksByWeekday[DateTime.thursday], [duplicate]);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('weekly_workout_routine')!),
        library.toJson());
  });

  test('legacy duplicates can be reduced but not multiplied', () {
    final first = block('Bench Press');
    final other = block('bench press');
    final linked = WorkoutRoutineBlock(
      type: WorkoutRoutineBlockType.superset,
      exercises: [...first.exercises, ...other.exercises],
    );
    expect(duplicateRoutineMovements([linked]), {'bench press'});
    expect(
        increasesRoutineMovementDuplicates([linked], [linked, other]), isTrue);
    expect(increasesRoutineMovementDuplicates([linked], [first]), isFalse);
  });
}
