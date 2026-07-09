import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../workout/application/manual_workout_controller.dart';
import '../../workout/domain/gym_set_entry.dart';
import '../../workout/domain/manual_workout_session.dart';
import '../domain/daily_targets.dart';
import '../application/daily_weight_controller.dart';

final dailyTargetsProvider = Provider<DailyTargets?>((ref) {
  final appState = ref.watch(appStateProvider);
  final todayWeight = ref.watch(todayWeightEntryProvider);
  final workoutCalories = ref.watch(todayWorkoutCaloriesProvider);

  final goal = appState.goal;
  final weightKg = todayWeight?.weightKg ?? appState.currentWeightKg;
  final jobActivityLevel = appState.jobActivityLevel;

  if (goal == null || weightKg == null || jobActivityLevel == null) {
    return null;
  }

  return calculateDailyTargets(
    goal: goal,
    weightKg: weightKg,
    jobActivityLevel: jobActivityLevel,
    workoutCalories: workoutCalories,
  );
});

final workoutRecommendationProvider = Provider<GoalRecommendation?>((ref) {
  final goal = ref.watch(appStateProvider).goal;
  if (goal == null) {
    return null;
  }

  return recommendationForGoal(goal, ref.watch(appLanguageProvider));
});

final strengthExerciseFilterProvider = StateProvider<String?>((ref) => null);

final strengthProgressMetricProvider = StateProvider<StrengthProgressMetric>(
  (ref) => StrengthProgressMetric.heaviestWeight,
);

final strengthExerciseOptionsProvider = Provider<List<String>>((ref) {
  final sessions = ref.watch(manualWorkoutSessionsProvider);
  final exercises = <String>{};
  for (final session in sessions) {
    for (final set in session.sets) {
      final name = set.exerciseName.trim();
      if (name.isNotEmpty) {
        exercises.add(name);
      }
    }
  }
  final items = exercises.toList()..sort();
  return items;
});

final progressStrengthProvider = Provider<List<ProgressPoint>>((ref) {
  final sessions = ref.watch(manualWorkoutSessionsProvider);
  final selectedExercise = ref.watch(strengthExerciseFilterProvider);
  final metric = ref.watch(strengthProgressMetricProvider);
  return _groupWorkoutSeries(
    sessions,
    valueForSession: (session) => _strengthValueForSession(
      session,
      selectedExercise: selectedExercise,
      metric: metric,
    ),
    aggregateForDate: metric == StrengthProgressMetric.totalVolume
        ? _sumAggregate
        : _maxAggregate,
  );
});

final progressCaloriesProvider = Provider<List<ProgressPoint>>((ref) {
  final sessions = ref.watch(manualWorkoutSessionsProvider);
  return _groupWorkoutSeries(
    sessions,
    valueForSession: (session) => session.estimatedActiveCalories.toDouble(),
    aggregateForDate: _sumAggregate,
  );
});

final progressBodyWeightProvider = Provider<List<ProgressPoint>>((ref) {
  final weights = ref.watch(dailyWeightEntriesProvider);
  final points = weights
      .take(8)
      .toList()
      .reversed
      .map((entry) => ProgressPoint(
          label: _shortDate(entry.dateKey), value: entry.weightKg))
      .toList();
  return points;
});

final progressCombinedProvider = Provider<List<ProgressPoint>>((ref) {
  final strength = ref.watch(progressStrengthProvider);
  final bodyWeight = ref.watch(progressBodyWeightProvider);
  final calories = ref.watch(progressCaloriesProvider);

  final length = min(strength.length, min(bodyWeight.length, calories.length));
  if (length == 0) {
    return const [];
  }

  final normStrength = _normalize(strength.take(length).toList());
  final normWeight = _normalize(bodyWeight.take(length).toList(), invert: true);
  final normCalories = _normalize(calories.take(length).toList());

  return List.generate(length, (index) {
    final value = (normStrength[index].value +
            normWeight[index].value +
            normCalories[index].value) /
        3;
    return ProgressPoint(label: normStrength[index].label, value: value);
  });
});

DailyTargets calculateDailyTargets({
  required String goal,
  required double weightKg,
  required String jobActivityLevel,
  required int workoutCalories,
}) {
  final baseMaintenance = (weightKg * 30).round();
  final jobActivityCalories = estimateJobActivityCalories(jobActivityLevel);
  final estimatedBurnCalories =
      baseMaintenance + jobActivityCalories + workoutCalories;

  final proteinTarget = (weightKg * proteinMultiplierForGoal(goal)).round();
  final calorieAdjustment = calorieAdjustmentForGoal(goal);
  final targetCalories = max(1400, estimatedBurnCalories + calorieAdjustment);
  final targetFat = max(40, (weightKg * 0.8).round());
  final caloriesFromProtein = proteinTarget * 4;
  final caloriesFromFat = targetFat * 9;
  final remainingCalories =
      max(0, targetCalories - caloriesFromProtein - caloriesFromFat);
  final targetCarbs = (remainingCalories / 4).round();

  return DailyTargets(
    goal: goal,
    targetCalories: targetCalories,
    targetProteinGrams: proteinTarget,
    targetCarbsGrams: targetCarbs,
    targetFatGrams: targetFat,
    estimatedBurnCalories: estimatedBurnCalories,
    jobActivityCalories: jobActivityCalories,
    workoutCalories: workoutCalories,
    isTrainingDay: workoutCalories > 0,
    basedOnWeightKg: weightKg,
  );
}

int estimateJobActivityCalories(String jobActivityLevel) {
  switch (jobActivityLevel) {
    case 'standing':
      return 150;
    case 'light':
      return 250;
    case 'moderate':
      return 400;
    case 'intense':
      return 600;
    case 'sedentary':
    default:
      return 0;
  }
}

double _strengthValueForSession(
  ManualWorkoutSession session, {
  required String? selectedExercise,
  required StrengthProgressMetric metric,
}) {
  final matchingSets = _matchingSetsForSession(
    session,
    selectedExercise: selectedExercise,
  );
  if (matchingSets.isEmpty) {
    return 0;
  }

  switch (metric) {
    case StrengthProgressMetric.heaviestWeight:
      return _heaviestWeightForSets(matchingSets);
    case StrengthProgressMetric.totalVolume:
      return _totalVolumeForSets(matchingSets);
    case StrengthProgressMetric.estimatedOneRepMax:
      return _estimatedOneRepMaxForSets(matchingSets);
  }
}

List<GymSetEntry> _matchingSetsForSession(
  ManualWorkoutSession session, {
  required String? selectedExercise,
}) {
  if (selectedExercise == null || selectedExercise.isEmpty) {
    return session.sets;
  }

  return session.sets
      .where((set) => _matchesExercise(set, selectedExercise))
      .toList();
}

bool _matchesExercise(GymSetEntry set, String selectedExercise) {
  return set.exerciseName.trim().toLowerCase() ==
      selectedExercise.trim().toLowerCase();
}

double proteinMultiplierForGoal(String goal) {
  switch (goal) {
    case 'lose_fat':
      return 2.0;
    case 'gain_muscle':
      return 1.8;
    case 'recomp':
      return 2.0;
    case 'maintain':
    default:
      return 1.6;
  }
}

int calorieAdjustmentForGoal(String goal) {
  switch (goal) {
    case 'lose_fat':
      return -300;
    case 'gain_muscle':
      return 200;
    case 'recomp':
      return 0;
    case 'maintain':
    default:
      return 0;
  }
}

GoalRecommendation recommendationForGoal(
  String goal, [
  AppLanguage language = AppLanguage.en,
]) {
  final isEnglish = language == AppLanguage.en;

  switch (goal) {
    case 'lose_fat':
      return GoalRecommendation(
        headline: isEnglish
            ? 'Prioritize useful energy expenditure and sustainable volume.'
            : 'Prioriza gasto util y volumen sostenible.',
        routineName: isEnglish
            ? 'Full body 3 days + walking'
            : 'Full body 3 dias + caminata',
        exercises: isEnglish
            ? const [
                'Goblet squat 4x10',
                'Bench press or push-ups 4x8-12',
                'Dumbbell row 4x10',
                'Romanian deadlift 3x10',
                '15-25 min easy cardio',
              ]
            : const [
                'Sentadilla goblet 4x10',
                'Press banca o flexiones 4x8-12',
                'Remo mancuerna 4x10',
                'Peso muerto rumano 3x10',
                '15-25 min cardio suave',
              ],
        nutritionFocus: isEnglish
            ? 'Moderate deficit, high protein, and controlled sugar intake.'
            : 'Deficit moderado, proteina alta y azucar controlada.',
      );
    case 'gain_muscle':
      return GoalRecommendation(
        headline: isEnglish
            ? 'Aim for load progression and enough volume per muscle group.'
            : 'Busca progresion de cargas y volumen por grupo muscular.',
        routineName:
            isEnglish ? 'Upper / Lower 4 days' : 'Upper / Lower 4 dias',
        exercises: isEnglish
            ? const [
                'Bench press 4x6-8',
                'Pull-ups or lat pulldown 4x8-10',
                'Squat 4x6-8',
                'Hip thrust 4x8-10',
                'Shoulder press 3x8-10',
              ]
            : const [
                'Press banca 4x6-8',
                'Dominadas o jalon 4x8-10',
                'Sentadilla 4x6-8',
                'Hip thrust 4x8-10',
                'Press hombro 3x8-10',
              ],
        nutritionFocus: isEnglish
            ? 'Light surplus, stable protein intake, and carbs around training.'
            : 'Ligero superavit, proteina estable y carbs alrededor del entreno.',
      );
    case 'recomp':
      return GoalRecommendation(
        headline: isEnglish
            ? 'Keep intensity high and protect week-to-week adherence.'
            : 'Mantén intensidad y cuida la adherencia semanal.',
        routineName: isEnglish
            ? 'Push / Pull / Legs 3-5 days'
            : 'Push / Pull / Legs 3-5 dias',
        exercises: isEnglish
            ? const [
                'Incline press 4x8',
                'Barbell row 4x8',
                'Leg press 4x10',
                'Romanian deadlift 3x8',
                'Lateral raises 3x15',
              ]
            : const [
                'Press inclinado 4x8',
                'Remo barra 4x8',
                'Prensa 4x10',
                'Peso muerto rumano 3x8',
                'Elevaciones laterales 3x15',
              ],
        nutritionFocus: isEnglish
            ? 'Calories near maintenance and high protein every day.'
            : 'Calorias cerca de mantenimiento y proteina alta todos los dias.',
      );
    case 'maintain':
    default:
      return GoalRecommendation(
        headline: isEnglish
            ? 'Train to maintain strength and consistency.'
            : 'Entrena para mantener fuerza y consistencia.',
        routineName: isEnglish ? 'Full body 2-3 days' : 'Full body 2-3 dias',
        exercises: isEnglish
            ? const [
                'Squat 3x8',
                'Bench press 3x8',
                'Row 3x10',
                'Hip hinge 3x10',
                'Core 3x12-15',
              ]
            : const [
                'Sentadilla 3x8',
                'Press banca 3x8',
                'Remo 3x10',
                'Bisagra de cadera 3x10',
                'Core 3x12-15',
              ],
        nutritionFocus: isEnglish
            ? 'Maintenance calories, enough protein, and regular meals.'
            : 'Mantenimiento, proteina suficiente y comidas regulares.',
      );
  }
}

List<ProgressPoint> _groupWorkoutSeries(
  List<ManualWorkoutSession> sessions, {
  required double Function(ManualWorkoutSession session) valueForSession,
  required double Function(double current, double next) aggregateForDate,
}) {
  final grouped = <String, double>{};
  for (final session in sessions) {
    final value = valueForSession(session);
    if (value <= 0) {
      continue;
    }
    final current = grouped[session.dateKey];
    grouped[session.dateKey] =
        current == null ? value : aggregateForDate(current, value);
  }

  final keys = grouped.keys.toList()..sort();
  final visibleKeys = keys.length > 8 ? keys.sublist(keys.length - 8) : keys;

  return visibleKeys
      .map((key) =>
          ProgressPoint(label: _shortDate(key), value: grouped[key] ?? 0))
      .toList();
}

double _maxAggregate(double current, double next) => max(current, next);

double _sumAggregate(double current, double next) => current + next;

double _heaviestWeightForSets(List<GymSetEntry> sets) {
  var maxWeight = 0.0;
  for (final set in sets) {
    if (set.weightKg > maxWeight) {
      maxWeight = set.weightKg;
    }
  }
  return maxWeight;
}

double _totalVolumeForSets(List<GymSetEntry> sets) {
  var total = 0.0;
  for (final set in sets) {
    total += set.weightKg * set.reps;
  }
  return total;
}

double _estimatedOneRepMaxForSets(List<GymSetEntry> sets) {
  var bestEstimate = 0.0;
  for (final set in sets) {
    if (set.reps <= 0 || set.weightKg <= 0) {
      continue;
    }
    final estimate = set.weightKg * (1 + (set.reps / 30));
    if (estimate > bestEstimate) {
      bestEstimate = estimate;
    }
  }
  return bestEstimate;
}

List<ProgressPoint> _normalize(List<ProgressPoint> points,
    {bool invert = false}) {
  if (points.isEmpty) {
    return const [];
  }

  var minValue = points.first.value;
  var maxValue = points.first.value;
  for (final point in points) {
    minValue = min(minValue, point.value);
    maxValue = max(maxValue, point.value);
  }

  if (maxValue == minValue) {
    return points
        .map((point) => ProgressPoint(label: point.label, value: 1))
        .toList();
  }

  return points.map((point) {
    final normalized = (point.value - minValue) / (maxValue - minValue);
    return ProgressPoint(
      label: point.label,
      value: invert ? 1 - normalized : normalized,
    );
  }).toList();
}

String _shortDate(String dateKey) {
  if (dateKey.length < 10) {
    return dateKey;
  }
  return dateKey.substring(5);
}
