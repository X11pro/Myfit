import 'dart:convert';

import 'package:fitness_app/features/food/application/manual_food_entries_controller.dart';
import 'package:fitness_app/features/food/presentation/manual_food_entry_screen.dart';
import 'package:fitness_app/shared/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/shared/submission_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retrying one meal keeps one entry; identical separate meals survive',
      () async {
    SharedPreferences.setMockInitialValues({});
    final scope = ProviderContainer();
    addTearDown(scope.dispose);
    final notifier = scope.read(manualFoodEntriesProvider.notifier);
    final id = newSubmissionId();
    Future<void> save(String id) => notifier.addEntry(
          submissionId: id,
          name: 'Lunch',
          mealType: 'lunch',
          calories: 350,
          proteinGrams: 20,
          carbsGrams: 30,
          fatGrams: 8,
        );
    await Future.wait([save(id), save(id)]);
    expect(scope.read(manualFoodEntriesProvider).single.id, id);
    await save(newSubmissionId());
    expect(scope.read(manualFoodEntriesProvider), hasLength(2));
  });

  testWidgets('double tap Save logs exactly one meal', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const ManualFoodEntryScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const Scaffold()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();
    const s = AppStrings(AppLanguage.en);
    await tester.enterText(
        find.widgetWithText(TextField, s.foodNameLabel), 'Lunch');
    await tester.tap(find.text('Nutrition totals'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, s.caloriesLabel), '350');
    await tester.enterText(
        find.widgetWithText(TextField, s.proteinLabel), '20');
    await tester.tap(find.text('Nutrition totals'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, s.saveMealButton);
    await tester.ensureVisible(save);
    final point = tester.getCenter(save);
    await tester.tapAt(point);
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final rows = jsonDecode(prefs.getString('manual_food_entries')!) as List;
    expect(rows, hasLength(1));
  });

  testWidgets('nutrition totals hide and reopen without clearing edits',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: ManualFoodEntryScreen())));
    await tester.pumpAndSettle();
    final section = find.text('Nutrition totals');
    final calories = find.widgetWithText(
        TextField, const AppStrings(AppLanguage.en).caloriesLabel);
    expect(calories, findsNothing);
    await tester.tap(section);
    await tester.pumpAndSettle();
    await tester.enterText(calories, '325');
    await tester.tap(section);
    await tester.pumpAndSettle();
    expect(calories, findsNothing);
    await tester.tap(section);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(calories).controller?.text, '325');
  });
}
