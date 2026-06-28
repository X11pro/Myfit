import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/features/workout/application/manual_workout_controller.dart';
import 'package:fitness_app/features/workout/domain/gym_set_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists workouts with sets and date key', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(manualWorkoutSessionsProvider.notifier).addSession(
          title: 'Push day',
          date: DateTime(2026, 6, 27),
          durationMinutes: 70,
          estimatedActiveCalories: 420,
          sets: const [
            GymSetEntry(
              exerciseName: 'Bench press',
              muscleGroup: 'Chest',
              setNumber: 1,
              reps: 8,
              weightKg: 80,
              rpe: 8,
            ),
          ],
          notes: 'Good session',
        );

    final rehydratedContainer = ProviderContainer();
    addTearDown(rehydratedContainer.dispose);

    rehydratedContainer.read(manualWorkoutSessionsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final sessions = rehydratedContainer.read(manualWorkoutSessionsProvider);
    expect(sessions, hasLength(1));
    expect(sessions.single.title, 'Push day');
    expect(sessions.single.dateKey, '2026-06-27');
    expect(sessions.single.estimatedActiveCalories, 420);
    expect(sessions.single.heaviestWeightKg, 80);
    expect(sessions.single.totalSets, 1);
  });

  test('updates existing workout session and replaces sets', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(manualWorkoutSessionsProvider.notifier);

    await notifier.addSession(
      title: 'Leg day',
      date: DateTime(2026, 6, 26),
      durationMinutes: 60,
      estimatedActiveCalories: 350,
      sets: const [
        GymSetEntry(
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          setNumber: 1,
          reps: 5,
          weightKg: 100,
        ),
      ],
    );

    final created = container.read(manualWorkoutSessionsProvider).single;

    await notifier.updateSession(
      id: created.id,
      title: 'Leg day heavy',
      date: DateTime(2026, 6, 28),
      durationMinutes: 75,
      estimatedActiveCalories: 480,
      sets: const [
        GymSetEntry(
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          setNumber: 1,
          reps: 4,
          weightKg: 110,
        ),
        GymSetEntry(
          exerciseName: 'Leg press',
          muscleGroup: 'Legs',
          setNumber: 2,
          reps: 10,
          weightKg: 180,
        ),
      ],
      notes: 'Updated',
    );

    final updated = container.read(manualWorkoutSessionsProvider).single;
    expect(updated.title, 'Leg day heavy');
    expect(updated.dateKey, '2026-06-28');
    expect(updated.durationMinutes, 75);
    expect(updated.estimatedActiveCalories, 480);
    expect(updated.totalSets, 2);
    expect(updated.heaviestWeightKg, 180);
    expect(updated.notes, 'Updated');
  });

  test('builds recent exercise suggestions without duplicates', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(manualWorkoutSessionsProvider.notifier);

    await notifier.addSession(
      title: 'Upper',
      date: DateTime(2026, 6, 28),
      durationMinutes: 55,
      estimatedActiveCalories: 300,
      sets: const [
        GymSetEntry(
          exerciseName: 'Bench press',
          muscleGroup: 'Chest',
          setNumber: 1,
          reps: 8,
          weightKg: 80,
        ),
        GymSetEntry(
          exerciseName: 'Row',
          muscleGroup: 'Back',
          setNumber: 2,
          reps: 10,
          weightKg: 60,
        ),
      ],
    );

    await notifier.addSession(
      title: 'Upper 2',
      date: DateTime(2026, 6, 29),
      durationMinutes: 50,
      estimatedActiveCalories: 290,
      sets: const [
        GymSetEntry(
          exerciseName: 'Bench press',
          muscleGroup: 'Chest',
          setNumber: 1,
          reps: 6,
          weightKg: 85,
        ),
        GymSetEntry(
          exerciseName: 'Pull up',
          muscleGroup: 'Back',
          setNumber: 2,
          reps: 8,
          weightKg: 0,
        ),
      ],
    );

    expect(
      container.read(recentWorkoutExerciseNamesProvider),
      ['Bench press', 'Pull up', 'Row'],
    );
  });
}
