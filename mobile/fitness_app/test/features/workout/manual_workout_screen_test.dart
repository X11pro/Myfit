import 'dart:convert';

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
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);
    await _addBasicSet(tester, sets: '3');

    expect(find.text('10 reps • Set 1 • Chest'), findsOneWidget);
    expect(find.text('10 reps • Set 2 • Chest'), findsOneWidget);
    expect(find.text('10 reps • Set 3 • Chest'), findsOneWidget);
    expect(find.text('Bench press • 80.0 kg'), findsNWidgets(3));
  });

  testWidgets('rest timer switches from countdown to overtime', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);

    await tester.enterText(
      find.byKey(const Key('rest-goal-seconds-field')),
      '1',
    );

    await tester.tap(find.byKey(const Key('rest-toggle-button')));
    await tester.pump();

    expect(find.text('Counting down'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('+00:01'), findsOneWidget);
  });

  testWidgets('rest alert toggle persists user preference', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);

    await tester.ensureVisible(find.byKey(const Key('rest-alert-toggle')));
    await tester.tap(find.byKey(const Key('rest-alert-toggle')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('manual_workout_rest_alert_enabled'), isTrue);
  });

  testWidgets('rest alert settings persist sound volume and vibration', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);

    await tester.ensureVisible(find.byKey(const Key('rest-vibration-toggle')));
    await tester.tap(find.byKey(const Key('rest-vibration-toggle')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('rest-sound-dropdown')));
    await tester.tap(find.byKey(const Key('rest-sound-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ping').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('rest-volume-slider')));
    await tester.drag(
      find.byKey(const Key('rest-volume-slider')),
      const Offset(-150, 0),
    );
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getBool('manual_workout_rest_alert_vibration_enabled'), isTrue);
    expect(prefs.getString('manual_workout_rest_alert_sound'), 'ping');
    expect(
      (prefs.getDouble('manual_workout_rest_alert_volume') ?? 0) < 0.7,
      isTrue,
    );
  });

  testWidgets('saves total active and rest durations in workout session', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);
    await _addBasicSet(tester);

    await tester.tap(find.byKey(const Key('rest-toggle-button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('workout-session-button')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(
      find.byKey(const Key('rest-goal-seconds-field')),
      '1',
    );
    await tester.tap(find.byKey(const Key('rest-toggle-button')));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('rest-toggle-button')));
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('save-workout-button')));
    await tester.tap(find.byKey(const Key('save-workout-button')));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('manual_workout_sessions');

    expect(raw, isNotNull);

    final decoded = jsonDecode(raw!) as List<dynamic>;
    final session = decoded.single as Map<String, dynamic>;

    expect(session['totalDurationSeconds'], greaterThanOrEqualTo(4));
    expect(session['restDurationSeconds'], greaterThanOrEqualTo(2));
    expect(session['activeDurationSeconds'], greaterThanOrEqualTo(1));
    expect(
      session['activeDurationSeconds'] + session['restDurationSeconds'],
      session['totalDurationSeconds'],
    );
  });
}

Future<void> _pumpManualWorkoutScreen(WidgetTester tester) async {
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
}

Future<void> _addBasicSet(WidgetTester tester, {String sets = '1'}) async {
  await tester.ensureVisible(find.text('Add set'));
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

  await tester.enterText(fields.at(0), sets);
  await tester.enterText(fields.at(1), '10');
  await tester.enterText(fields.at(2), '80');

  await tester.tap(find.widgetWithText(FilledButton, 'Add'));
  await tester.pumpAndSettle();
}
