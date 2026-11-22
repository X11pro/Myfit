import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_app/features/workout/presentation/manual_workout_screen.dart';
import 'package:fitness_app/features/workout/domain/weekly_workout_routine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('keeps new sets collapsed until the exercise is opened', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);
    await _addBasicSet(tester, sets: '3');

    expect(
      find.text('Flat barbell or dumbbell bench press'),
      findsOneWidget,
    );
    expect(find.text('3 sets · 80 kg × 10 reps'), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-set-1-KG')), findsNothing);

    await tester.tap(
      find.byKey(
        const ValueKey('exercise-group-Flat barbell or dumbbell bench press'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quick-set-1-KG')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-set-2-KG')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-set-3-KG')), findsOneWidget);
  });

  testWidgets('double Add and double Finish produce one set in one session',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpManualWorkoutScreen(tester);
    await _addBasicSet(tester, doubleTap: true);
    final finish = find.byKey(const Key('save-workout-button'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final rows =
        jsonDecode(prefs.getString('manual_workout_sessions')!) as List;
    expect(rows, hasLength(1));
    expect(rows.single['sets'], hasLength(1));
  });

  testWidgets('updates a set weight directly from the workout screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);
    await _addBasicSet(tester);

    await tester.tap(
      find.byKey(
        const ValueKey('exercise-group-Flat barbell or dumbbell bench press'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('quick-set-1-KG')), '85');
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byKey(const ValueKey('quick-set-1-KG')),
    );
    expect(field.initialValue, '85');
  });

  testWidgets('routine wins overlap and does not reload edited session sets',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final routine = WeeklyWorkoutRoutine(
      id: 'weekly',
      name: 'Week 1',
      blocksByWeekday: {
        DateTime.now().weekday: const [
          WorkoutRoutineBlock(
            type: WorkoutRoutineBlockType.superset,
            exercises: [
              WorkoutRoutineExercise(
                exerciseName: ' flat barbell  or dumbbell bench press ',
                muscleGroup: 'Chest',
                sets: 4,
                reps: 8,
                weightKg: 90,
              ),
              WorkoutRoutineExercise(
                exerciseName: 'Cable row',
                muscleGroup: 'Back',
                sets: 2,
                reps: 10,
                weightKg: 30,
              ),
            ],
          ),
        ],
      },
    );
    final library =
        WorkoutRoutineLibrary(activeRoutineId: 'weekly', routines: [routine]);
    SharedPreferences.setMockInitialValues(
        {'weekly_workout_routine': jsonEncode(library.toJson())});
    await _pumpManualWorkoutScreen(tester);
    await _addBasicSet(tester);
    final load = find.byKey(const Key('load-routine-button'));
    await tester.ensureVisible(load);
    final point = tester.getCenter(load);
    await tester.tapAt(point);
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Load routine'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(load).onPressed, isNull);
    expect(find.text('flat barbell  or dumbbell bench press'), findsOneWidget);
    final row = find.byKey(const ValueKey('exercise-group-Cable row'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    final weight = find.byKey(const ValueKey('quick-set-5-KG'));
    await tester.ensureVisible(weight);
    await tester.enterText(weight, '35');
    await tester.pump();
    final finish = find.byKey(const Key('save-workout-button'));
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final sessions =
        jsonDecode(prefs.getString('manual_workout_sessions')!) as List;
    final sets = sessions.single['sets'] as List;
    expect(sets.map((s) => s['setNumber']), [1, 2, 3, 4, 5, 6]);
    expect(sets.map((s) => s['weightKg']), [90, 90, 90, 90, 35, 30]);
    expect(jsonDecode(prefs.getString('weekly_workout_routine')!),
        library.toJson());
  });

  for (final addToPlan in [false, true]) {
    testWidgets('manual extra counts in saved workout; add to plan: $addToPlan',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const library =
          WorkoutRoutineLibrary(activeRoutineId: 'weekly', routines: [
        WeeklyWorkoutRoutine(id: 'weekly', name: 'Week 1'),
      ]);
      SharedPreferences.setMockInitialValues(
          {'weekly_workout_routine': jsonEncode(library.toJson())});
      await _pumpManualWorkoutScreen(tester);
      await _addBasicSet(tester, sets: '2');
      await tester.tap(find.byKey(const Key('save-workout-button')));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsOneWidget);
      if (addToPlan) {
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Add to routine'));
      } else {
        await tester.tap(find.text('Workout only'));
      }
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final sessions =
          jsonDecode(prefs.getString('manual_workout_sessions')!) as List;
      expect(sessions.single['sets'], hasLength(2));
      final updated = WorkoutRoutineLibrary.fromJson(
          jsonDecode(prefs.getString('weekly_workout_routine')!));
      final blocks = updated.activeRoutine!.blocksFor(DateTime.now());
      if (addToPlan) {
        expect(blocks.single.exercises.single.sets, 2);
        expect(blocks.single.exercises.single.weightKg, 80);
      } else {
        expect(blocks, isEmpty);
      }
    });
  }

  testWidgets('adding a set does not start the rest timer', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);
    await _addBasicSet(tester);

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Counting down'), findsNothing);
  });

  testWidgets('new workout uses its date as the default title', (
    WidgetTester tester,
  ) async {
    await _pumpManualWorkoutScreen(tester);

    final titleField = tester.widget<TextField>(
      find.byKey(const Key('workout-title-field')),
    );

    expect(titleField.controller!.text, matches(r'^\d{4}-\d{2}-\d{2}$'));
  });

  testWidgets('adds a custom exercise after choosing a muscle group', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('muscle-group-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add custom exercise').last);
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Cable pullover');
    await tester.enterText(fields.at(1), '2');
    await tester.enterText(fields.at(2), '12');
    await tester.enterText(fields.at(3), '35');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Cable pullover'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('exercise-group-Cable pullover')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('quick-set-1-KG')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-set-2-KG')), findsOneWidget);
  });

  testWidgets('rest timer stops at its target and is ready for the next rest', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);

    await _openTimerSettings(tester);

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

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('-00:01'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rest-toggle-button')));
    await tester.pump();

    expect(find.text('Counting down'), findsOneWidget);
  });

  testWidgets('rest alert toggle persists user preference', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpManualWorkoutScreen(tester);
    await _openTimerSettings(tester);

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
    await _openTimerSettings(tester);

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

    await _openTimerSettings(tester);
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

    expect(session['totalDurationSeconds'], greaterThanOrEqualTo(3));
    expect(session['restDurationSeconds'], greaterThanOrEqualTo(2));
    expect(session['activeDurationSeconds'], greaterThanOrEqualTo(1));
    expect(
      session['activeDurationSeconds'] + session['restDurationSeconds'],
      inInclusiveRange(
        session['totalDurationSeconds'] - 1,
        session['totalDurationSeconds'] + 1,
      ),
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

Future<void> _addBasicSet(WidgetTester tester,
    {String sets = '1', bool doubleTap = false}) async {
  await tester.ensureVisible(find.text('Add set'));
  await tester.tap(find.text('Add set'));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('muscle-group-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Chest').last);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('exercise-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.text('Flat barbell or dumbbell bench press').last,
  );
  await tester.pumpAndSettle();

  final fields = find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );

  await tester.enterText(fields.at(0), sets);
  await tester.enterText(fields.at(1), '10');
  await tester.enterText(fields.at(2), '80');

  final button = find.widgetWithText(FilledButton, 'Add');
  final point = tester.getCenter(button);
  await tester.tapAt(point);
  if (doubleTap) await tester.tapAt(point);
  await tester.pumpAndSettle();
}

Future<void> _openTimerSettings(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Timer settings'));
  await tester.tap(find.text('Timer settings'));
  await tester.pumpAndSettle();
}
