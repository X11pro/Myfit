class DailyTargets {
  const DailyTargets({
    required this.goal,
    required this.targetCalories,
    required this.targetProteinGrams,
    required this.targetCarbsGrams,
    required this.targetFatGrams,
    required this.estimatedBurnCalories,
    required this.jobActivityCalories,
    required this.workoutCalories,
    required this.isTrainingDay,
    required this.basedOnWeightKg,
  });

  final String goal;
  final int targetCalories;
  final int targetProteinGrams;
  final int targetCarbsGrams;
  final int targetFatGrams;
  final int estimatedBurnCalories;
  final int jobActivityCalories;
  final int workoutCalories;
  final bool isTrainingDay;
  final double basedOnWeightKg;
}

class GoalRecommendation {
  const GoalRecommendation({
    required this.headline,
    required this.routineName,
    required this.exercises,
    required this.nutritionFocus,
  });

  final String headline;
  final String routineName;
  final List<String> exercises;
  final String nutritionFocus;
}

class ProgressPoint {
  const ProgressPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

enum ProgressMode {
  strength,
  bodyWeight,
  calories,
  combined,
}
