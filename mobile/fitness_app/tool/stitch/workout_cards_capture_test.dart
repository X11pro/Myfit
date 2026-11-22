import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fitness_app/features/workout/domain/weekly_workout_routine.dart';
import 'package:fitness_app/features/workout/presentation/manual_workout_screen.dart';
import 'package:fitness_app/features/workout/presentation/weekly_workout_routine_screen.dart';
import 'package:fitness_app/features/workout/presentation/workout_editor_dialog.dart';
import 'package:fitness_app/shared/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final (family, path) in [
      ('Inter', 'assets/fonts/inter.ttf'),
      ('Plus Jakarta Sans', 'assets/fonts/plusjakartasans.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(path))).load();
    }
  });
  testWidgets('Weekly routine applies once, then Add Set edits one movement',
      (t) async {
    final today = DateTime.now().weekday;
    const normal =
        WorkoutRoutineBlock(type: WorkoutRoutineBlockType.normal, exercises: [
      WorkoutRoutineExercise(
          exerciseName: 'Incline Barbell Bench Press',
          muscleGroup: 'Chest',
          sets: 3,
          reps: 8,
          weightKg: 82.5)
    ]);
    const triset =
        WorkoutRoutineBlock(type: WorkoutRoutineBlockType.triset, exercises: [
      WorkoutRoutineExercise(
          exerciseName: 'Lateral Raise',
          muscleGroup: 'Shoulders',
          sets: 1,
          reps: 12,
          weightKg: 10),
      WorkoutRoutineExercise(
          exerciseName: 'Reverse Fly',
          muscleGroup: 'Shoulders',
          sets: 1,
          reps: 10,
          weightKg: 8),
      WorkoutRoutineExercise(
          exerciseName: 'Face Pull',
          muscleGroup: 'Back',
          sets: 1,
          reps: 12,
          weightKg: 15),
    ]);
    const superset =
        WorkoutRoutineBlock(type: WorkoutRoutineBlockType.superset, exercises: [
      WorkoutRoutineExercise(
          exerciseName: 'Cable Tricep Pushdown',
          muscleGroup: 'Triceps',
          sets: 3,
          reps: 12,
          weightKg: 27),
      WorkoutRoutineExercise(
          exerciseName: 'Cable Bayesian Curl',
          muscleGroup: 'Biceps',
          sets: 3,
          reps: 10,
          weightKg: 14)
    ]);
    final routine = WeeklyWorkoutRoutine(
        id: 'qa',
        name: '4-Day Push/Pull Split',
        blocksByWeekday: {
          today: [normal, superset, triset]
        });
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'weekly_workout_routine': jsonEncode(
          WorkoutRoutineLibrary(activeRoutineId: 'qa', routines: [routine])
              .toJson())
    });
    t.view.devicePixelRatio = 1;
    final height = double.parse(Platform.environment['STITCH_HEIGHT'] ?? '884');
    t.view.physicalSize = Size(412, height);
    await t.binding.setSurfaceSize(Size(412, height));
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(() => t.binding.setSurfaceSize(null));
    final key = GlobalKey();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const ManualWorkoutScreen()),
      GoRoute(
          path: '/workout/routine',
          builder: (_, state) => WeeklyWorkoutRoutineScreen(
              request: state.extra as WeeklyRoutineRequest)),
      GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Saved')))
    ]);
    addTearDown(router.dispose);
    await t.pumpWidget(ProviderScope(
        child: RepaintBoundary(
            key: key,
            child: MaterialApp.router(
                theme: AppTheme.dark(),
                debugShowCheckedModeBanner: false,
                routerConfig: router))));
    await t.pumpAndSettle();
    Future<void> reveal(Finder target) async {
      if (target.hitTestable().evaluate().isEmpty) {
        await t.dragUntilVisible(target.hitTestable(),
            find.byType(ListView).first, const Offset(0, -180));
      }
      await t.pumpAndSettle();
    }

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

    final weekly = find.byKey(const Key('edit-weekly-routine-button'));
    await reveal(weekly);
    await t.tap(weekly);
    await t.pumpAndSettle();
    expect(find.text('Incline Barbell Bench Press'), findsOneWidget);
    await reveal(find.text('BLOCK 3 · Triset'));
    expect(find.text('1 round'), findsOneWidget);
    t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
    await t.pumpAndSettle();
    await capture('weekly-routine');
    for (final (label, count) in [('Superset', 2), ('Triset', 3)]) {
      final addBlock = find.text(label);
      await reveal(addBlock);
      await t.tap(addBlock);
      await t.pumpAndSettle();
      final dialog = find.byType(WorkoutEditorDialog);
      expect(dialog, findsOneWidget);
      final lastExercise =
          find.descendant(of: dialog, matching: find.text('Exercise $count'));
      await t.ensureVisible(lastExercise);
      await t.pumpAndSettle();
      expect(lastExercise.hitTestable(), findsOneWidget);
      expect(t.takeException(), isNull);
      await capture(label.toLowerCase());
      await t.tap(find.widgetWithText(TextButton, 'Cancel'));
      await t.pumpAndSettle();
    }
    final apply = find.text('Apply to this workout');
    await reveal(apply);
    final applyPoint = t.getCenter(apply);
    await t.tapAt(applyPoint);
    await t.tapAt(applyPoint);
    await t.pumpAndSettle();
    expect(find.text('Incline Barbell Bench Press'), findsOneWidget);
    final card = find
        .byKey(const ValueKey('exercise-group-Incline Barbell Bench Press'));
    await t.ensureVisible(card);
    await t.tap(card);
    await t.pumpAndSettle();
    final add = find.descendant(of: card, matching: find.text('Add set'));
    await reveal(add);
    await t.tap(add);
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final sameExercise = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Incline Barbell Bench Press'));
    expect(sameExercise, findsOneWidget);
    await capture('add-set');
    final submit = find.widgetWithText(FilledButton, 'Add');
    final submitPoint = t.getCenter(submit);
    await t.tapAt(submitPoint);
    await t.tapAt(submitPoint);
    await t.pumpAndSettle();
    final scrollable = t.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(0);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('save-workout-button')));
    await t.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    final sessions =
        jsonDecode(prefs.getString('manual_workout_sessions')!) as List;
    expect(sessions, hasLength(1));
    final sets = sessions.single['sets'] as List;
    expect(sets, hasLength(13));
    expect(sets.map((s) => s['setNumber']).toSet(), hasLength(13));
    expect(
        sets.where((s) => s['exerciseName'] == 'Incline Barbell Bench Press'),
        hasLength(4));
    expect(t.takeException(), isNull);
  });
}
