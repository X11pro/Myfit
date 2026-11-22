// Offline design fixtures only. Run with flutter test tool/stitch/capture_test.dart
// and set STITCH_CAPTURE_DIR to an output directory outside the repository.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/shared/ui/theme/app_theme.dart';
import 'package:fitness_app/features/dashboard/presentation/progress_screen.dart';
import 'package:fitness_app/features/dashboard/application/daily_targets_calculator.dart';
import 'package:fitness_app/features/dashboard/domain/daily_targets.dart';
import 'package:fitness_app/features/food/domain/manual_food_entry.dart';
import 'package:fitness_app/features/workout/domain/manual_workout_session.dart';
import 'package:fitness_app/features/workout/domain/gym_set_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final f in [
      ('Inter', 'inter'),
      ('Plus Jakarta Sans', 'plusjakartasans'),
      ('MaterialIcons', 'MaterialIcons-Regular')
    ]) {
      await (FontLoader(f.$1)
            ..addFont(rootBundle.load(f.$1 == 'MaterialIcons'
                ? 'fonts/${f.$2}.otf'
                : 'assets/fonts/${f.$2}.ttf')))
          .load();
    }
  });
  final height = double.parse(Platform.environment['STITCH_HEIGHT'] ?? '884');
  final now = DateTime.now();
  final sets = [
    for (var i = 1; i <= 3; i++)
      GymSetEntry(
          exerciseName: [
            'Bench Press',
            'Incline DB Press',
            'Lateral Raises'
          ][i % 3],
          muscleGroup: 'Chest',
          setNumber: i,
          reps: 8,
          weightKg: i == 1 ? 80 : 82.5,
          rpe: 8)
  ];
  final session = ManualWorkoutSession(
      id: 'qa',
      title: 'Upper Body Hypertrophy',
      dateKey: now.toIso8601String().split('T')[0],
      durationMinutes: 48,
      totalDurationSeconds: 2892,
      activeDurationSeconds: 1920,
      restDurationSeconds: 960,
      estimatedActiveCalories: 420,
      createdAt: now,
      sets: sets);
  final meal = ManualFoodEntry(
      id: 'meal',
      name: 'Citrus Chicken & Grains',
      mealType: 'lunch',
      calories: 640,
      proteinGrams: 54,
      carbsGrams: 62,
      fatGrams: 16,
      sugarGrams: 0,
      fiberGrams: 8,
      createdAt: now,
      estimatedGrams: 470,
      ingredientsText: 'Chicken, broccoli, quinoa, sweet potato',
      confidence: .92,
      photoPath: null);
  testWidgets('Period selection filters real records and CSV preview',
      (tester) async {
// ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'guest_display_name': 'Alex',
      'guest_current_weight_kg': 78.4,
      'guest_height_cm': 180.0,
      'guest_goal': 'maintain',
      'guest_job_activity_level': 'moderate',
      'manual_workout_sessions': jsonEncode([
        for (final i in [0, 7, 14, 21])
          {
            ...session.toJson(),
            'dateKey': now
                .subtract(Duration(days: i))
                .toIso8601String()
                .split('T')
                .first,
            'sets': [
              for (final x in sets) {...x.toJson(), 'weightKg': 85 - i * .5}
            ]
          }
      ]),
      'manual_food_entries': jsonEncode([
        for (int i = 0; i < 12; i++)
          {
            ...meal.toJson(),
            'id': 'day-$i',
            'createdAt': now.subtract(Duration(days: i)).toIso8601String(),
            'calories': 1870 + i % 3 * 180,
            'proteinGrams': 152,
            'carbsGrams': 210,
            'fatGrams': 58
          }
      ]),
      'daily_weight_entries': jsonEncode([
        for (var i = 0; i < 21; i++)
          {
            'dateKey': now
                .subtract(Duration(days: i))
                .toIso8601String()
                .split('T')
                .first,
            'weightKg': 78.4 + i * .1
          }
      ]),
    });
    await tester.binding.setSurfaceSize(Size(412, height));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(412, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          dailyTargetsProvider.overrideWithValue(const DailyTargets(
              goal: 'maintain',
              targetCalories: 2200,
              targetProteinGrams: 160,
              targetCarbsGrams: 240,
              targetFatGrams: 65,
              estimatedBurnCalories: 2420,
              bmrCalories: 1800,
              usesPersonalizedEnergyEstimate: true,
              jobActivityCalories: 200,
              workoutCalories: 420,
              isTrainingDay: true,
              basedOnWeightKg: 78.4))
        ],
        child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark(),
                home: const ProgressScreen()))));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final dir = Platform.environment['STITCH_CAPTURE_DIR'];
      if (dir == null) return;
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(dir).create(recursive: true);
        await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('progress');
    expect(find.text('12 / 30 days logged'), findsOneWidget);
    await tester.tap(find.text('7D'));
    await tester.pumpAndSettle();
    expect(find.text('7 / 7 days logged'), findsOneWidget);
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(find.textContaining('date,weight_kg,food_kcal'), findsOneWidget);
    await capture('progress-export');
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log'));
    await tester.tap(find.text('Log'));
    await tester.pumpAndSettle();
    expect(find.text('Log today weight'), findsOneWidget);
    await capture('progress-weight');
    expect(tester.takeException(), isNull);
  });
}
