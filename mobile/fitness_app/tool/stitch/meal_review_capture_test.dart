import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fitness_app/shared/ui/theme/app_theme.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/features/food/domain/manual_food_entry.dart';
import 'package:fitness_app/features/food/presentation/manual_food_entry_screen.dart';
import 'package:fitness_app/features/dashboard/application/daily_targets_calculator.dart';
import 'package:fitness_app/features/dashboard/domain/daily_targets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Review a photo, correct portion, then confirm the edited meal',
      (t) async {
    for (final f in [
      ('Inter', 'assets/fonts/inter.ttf'),
      ('Plus Jakarta Sans', 'assets/fonts/plusjakartasans.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf')
    ]) {
      await (FontLoader(f.$1)..addFont(rootBundle.load(f.$2))).load();
    }
    final file = File('tool/stitch/fixtures/meal-review.jpg').absolute;
    final meal = ManualFoodEntry(
        id: 'qa',
        name: 'Herbed Grilled Chicken & Quinoa',
        mealType: 'lunch',
        calories: 640,
        proteinGrams: 54,
        carbsGrams: 62,
        fatGrams: 16,
        sugarGrams: 3,
        fiberGrams: 8,
        estimatedGrams: 470,
        confidence: .92,
        ingredientsText:
            'Grilled Chicken Breast (160 g)\nSteamed Broccoli (90 g)\nCooked Quinoa (120 g)\nRoasted Sweet Potato (100 g)',
        createdAt: DateTime(2024, 10, 24, 12, 45),
        photoPath: file.path);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'manual_food_entries': jsonEncode([meal.toJson()])
    });
    final height = double.parse(Platform.environment['STITCH_HEIGHT'] ?? '884');
    final size = Size(412, height);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    await t.binding.setSurfaceSize(size);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(() => t.binding.setSurfaceSize(null));
    final router = GoRouter(routes: [
      GoRoute(
          path: '/', builder: (_, __) => ManualFoodEntryScreen(entry: meal)),
      GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Saved')))
    ]);
    addTearDown(router.dispose);
    final key = GlobalKey();
    await t.pumpWidget(
        MaterialApp(home: Builder(builder: (_) => SizedBox(key: key))));
    await t.runAsync(() => precacheImage(FileImage(file), key.currentContext!)
        .timeout(const Duration(seconds: 10)));
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(ProviderScope(
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
            child: MaterialApp.router(
                theme: AppTheme.dark(),
                debugShowCheckedModeBanner: false,
                routerConfig: router))));
    await t.pumpAndSettle();

    await t.pumpAndSettle();
    final dir = Platform.environment['STITCH_CAPTURE_DIR'];
    if (dir != null) {
      await t.runAsync(() async {
        await Directory(dir).create(recursive: true);
        final image = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/meal-review.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    final plus = find.byTooltip('+10 g');
    await t.scrollUntilVisible(plus, 180,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    await t.tap(plus);
    await t.pump();
    expect(find.text('480 g'), findsOneWidget);
    expect(find.text('~ 654 kcal'), findsOneWidget);
    await t.tap(find.byTooltip('−10 g'));
    await t.pump();
    expect(find.text('~ 640 kcal'), findsOneWidget);
    final save = find.text('Confirm & log to Lunch');
    await t.dragUntilVisible(
        save.hitTestable(), find.byType(ListView).first, const Offset(0, -200));
    await t.tap(save);
    await t.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
