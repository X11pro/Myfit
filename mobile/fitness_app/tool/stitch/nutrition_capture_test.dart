import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/features/food/domain/manual_food_entry.dart';
import 'package:fitness_app/features/food/presentation/nutrition_screen.dart';
import 'package:fitness_app/features/food/presentation/manual_food_entry_screen.dart';
import 'package:fitness_app/shared/ui/theme/app_theme.dart';
import 'package:fitness_app/features/dashboard/application/daily_targets_calculator.dart';
import 'package:fitness_app/features/dashboard/domain/daily_targets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Daily nutrition totals follow the selected day; search filters meals',
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
        createdAt: DateTime.now(),
        photoPath: file.path);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'manual_food_entries': jsonEncode([
        meal.toJson(),
        for (final e in [
          ('Breakfast', 'Rolled Oats with Whey', 510),
          ('Snack', 'Whey Isolate Shake', 490),
          ('Dinner', 'Previous day entry', 200)
        ])
          {
            ...meal.toJson(),
            'id': e.$1,
            'name': e.$2,
            'mealType': e.$1.toLowerCase(),
            'calories': e.$3,
            'createdAt': (e.$1 == 'Dinner'
                    ? DateTime.now().subtract(const Duration(days: 1))
                    : DateTime.now())
                .toIso8601String()
          }
      ])
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
      GoRoute(path: '/', builder: (_, __) => const NutritionScreen()),
      GoRoute(
          path: '/food/manual',
          builder: (_, state) => ManualFoodEntryScreen(
              initialMealType: state.uri.queryParameters['meal'])),
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
              targetCalories: 2250,
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
    Future<void> capture(String name) async {
      final dir = Platform.environment['STITCH_CAPTURE_DIR'];
      if (dir == null) return;
      await t.runAsync(() async {
        await Directory(dir).create(recursive: true);
        final image = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/$name.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('nutrition');
    expect(find.textContaining('1640', findRichText: true), findsWidgets);
    await t.tap(find.byTooltip('Previous day'));
    await t.pumpAndSettle();
    expect(find.textContaining('200 /', findRichText: true), findsWidgets);
    expect(find.textContaining('1640', findRichText: true), findsNothing);
    await t.tap(find.byTooltip('Next day'));
    await t.pumpAndSettle();
    final selector = find.byKey(const Key('daily-meal-selector'));
    await t.scrollUntilVisible(selector, 220,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('selected-daily-meal')), findsNothing);
    for (final (category, food) in [
      ('Breakfast', 'Rolled Oats with Whey'),
      ('Lunch', 'Herbed Grilled Chicken & Quinoa')
    ]) {
      await t.tap(selector);
      await t.pumpAndSettle();
      await t.tap(find.text(category).hitTestable().last);
      await t.pumpAndSettle();
      final card = find.byKey(const Key('selected-daily-meal'));
      expect(card, findsOneWidget);
      expect(
          find.descendant(of: card, matching: find.text(food)), findsOneWidget);
    }
    await t.ensureVisible(find.byKey(const Key('selected-daily-meal')));
    await t.pumpAndSettle();
    await capture('daily-meals');
    await t.scrollUntilVisible(find.byType(TextField), -220,
        scrollable: find.byType(Scrollable).first);
    await t.enterText(find.byType(TextField), 'rolled oats');
    await t.pump();
    expect(t.widget<DropdownButton<String>>(selector).value, 'breakfast');
    await t.enterText(find.byType(TextField), 'unmatched');
    await t.pump();
    expect(find.text('No matching meals for this day.'), findsOneWidget);
    await t.enterText(find.byType(TextField), '');
    await t.pumpAndSettle();
    final add = find.text('Add to Lunch');
    await t.scrollUntilVisible(add, 200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(add);
    await t.pumpAndSettle();
    final totals = find.text('Nutrition totals');
    await t.ensureVisible(totals);
    await t.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Calories'), findsNothing);
    await capture('add-meal');
    await t.tap(totals);
    await t.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Calories'), findsOneWidget);
    await capture('add-meal-totals');
    expect(t.takeException(), isNull);
  });
}
