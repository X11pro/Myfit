import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/features/dashboard/application/daily_targets_calculator.dart';
import 'package:fitness_app/features/dashboard/domain/daily_targets.dart';
import 'package:fitness_app/features/workout/application/manual_workout_controller.dart';
import 'package:fitness_app/features/workout/domain/gym_set_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('calculates fat loss targets using goal and workout calories', () {
    final targets = calculateDailyTargets(
      goal: 'lose_fat',
      weightKg: 80,
      jobActivityLevel: 'moderate',
      workoutCalories: 350,
    );

    expect(targets.estimatedBurnCalories, 3150);
    expect(targets.targetCalories, 2850);
    expect(targets.targetProteinGrams, 160);
    expect(targets.targetFatGrams, 64);
    expect(targets.targetCarbsGrams, 409);
    expect(targets.isTrainingDay, isTrue);
  });

  test('builds muscle gain recommendation and multiplier', () {
    expect(proteinMultiplierForGoal('gain_muscle'), 1.8);
    expect(calorieAdjustmentForGoal('gain_muscle'), 200);

    final recommendation = recommendationForGoal('gain_muscle');
    expect(recommendation.routineName, 'Upper / Lower 4 days');
    expect(recommendation.exercises.first, 'Bench press 4x6-8');
    expect(recommendation.exercises, isNotEmpty);
  });

  test('filters strength progress by selected exercise', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(manualWorkoutSessionsProvider.notifier);
    await notifier.addSession(
      title: 'Session A',
      date: DateTime(2026, 6, 20),
      durationMinutes: 50,
      estimatedActiveCalories: 300,
      sets: const [
        GymSetEntry(
          exerciseName: 'Bench press',
          muscleGroup: 'Chest',
          setNumber: 1,
          reps: 5,
          weightKg: 80,
        ),
        GymSetEntry(
          exerciseName: 'Squat',
          muscleGroup: 'Legs',
          setNumber: 2,
          reps: 5,
          weightKg: 100,
        ),
      ],
    );
    await notifier.addSession(
      title: 'Session B',
      date: DateTime(2026, 6, 21),
      durationMinutes: 55,
      estimatedActiveCalories: 320,
      sets: const [
        GymSetEntry(
          exerciseName: 'Bench press',
          muscleGroup: 'Chest',
          setNumber: 1,
          reps: 5,
          weightKg: 85,
        ),
      ],
    );

    final allStrength = container.read(progressStrengthProvider);
    expect(allStrength.map((point) => point.value), [100, 85]);

    container.read(strengthExerciseFilterProvider.notifier).state =
        'Bench press';
    final filteredStrength = container.read(progressStrengthProvider);
    expect(filteredStrength.map((point) => point.value), [80, 85]);
  });

  test('calculates strength volume and estimated 1RM by selected exercise',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(manualWorkoutSessionsProvider.notifier);
    await notifier.addSession(
      title: 'Bench volume',
      date: DateTime(2026, 6, 22),
      durationMinutes: 60,
      estimatedActiveCalories: 250,
      sets: const [
        GymSetEntry(
          exerciseName: 'Bench press',
          muscleGroup: 'Chest',
          setNumber: 1,
          reps: 8,
          weightKg: 80,
        ),
        GymSetEntry(
          exerciseName: 'Bench press',
          muscleGroup: 'Chest',
          setNumber: 2,
          reps: 6,
          weightKg: 85,
        ),
      ],
    );
    await notifier.addSession(
      title: 'Bench intensity',
      date: DateTime(2026, 6, 23),
      durationMinutes: 55,
      estimatedActiveCalories: 260,
      sets: const [
        GymSetEntry(
          exerciseName: 'Bench press',
          muscleGroup: 'Chest',
          setNumber: 1,
          reps: 4,
          weightKg: 92.5,
        ),
      ],
    );

    container.read(strengthExerciseFilterProvider.notifier).state =
        'Bench press';
    container.read(strengthProgressMetricProvider.notifier).state =
        StrengthProgressMetric.totalVolume;

    final volumePoints = container.read(progressStrengthProvider);
    expect(volumePoints.map((point) => point.value), [1150, 370]);

    container.read(strengthProgressMetricProvider.notifier).state =
        StrengthProgressMetric.estimatedOneRepMax;

    final oneRepMaxPoints = container.read(progressStrengthProvider);
    expect(oneRepMaxPoints.first.value, closeTo(102, 0.01));
    expect(oneRepMaxPoints.last.value, closeTo(104.83, 0.01));
  });

  test('sums workout calories from multiple sessions on the same day',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(manualWorkoutSessionsProvider.notifier);
    await notifier.addSession(
      title: 'AM session',
      date: DateTime(2026, 6, 24),
      durationMinutes: 30,
      estimatedActiveCalories: 180,
      sets: const [
        GymSetEntry(
          exerciseName: 'Row',
          muscleGroup: 'Back',
          setNumber: 1,
          reps: 10,
          weightKg: 50,
        ),
      ],
    );
    await notifier.addSession(
      title: 'PM session',
      date: DateTime(2026, 6, 24),
      durationMinutes: 40,
      estimatedActiveCalories: 220,
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

    final caloriesPoints = container.read(progressCaloriesProvider);
    expect(caloriesPoints, hasLength(1));
    expect(caloriesPoints.single.value, 400);
  });
}
