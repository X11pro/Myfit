import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/features/workout/presentation/manual_workout_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('adds multiple identical sets from the add set dialog', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ManualWorkoutScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const Scaffold(body: Text('Dashboard')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    final dropdowns = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(DropdownButtonFormField<String>),
    );

    await tester.tap(dropdowns.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chest').last);
    await tester.pumpAndSettle();

    await tester.tap(dropdowns.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bench press').last);
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );

    await tester.enterText(fields.at(0), '3');
    await tester.enterText(fields.at(1), '10');
    await tester.enterText(fields.at(2), '80');

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('10 reps • Set 1 • Chest'), findsOneWidget);
    expect(find.text('10 reps • Set 2 • Chest'), findsOneWidget);
    expect(find.text('10 reps • Set 3 • Chest'), findsOneWidget);
    expect(find.text('Bench press • 80.0 kg'), findsNWidgets(3));
  });
}
