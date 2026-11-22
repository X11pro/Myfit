// Render the real logger with an offline Stitch design fixture.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fitness_app/shared/ui/theme/app_theme.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitness_app/features/workout/presentation/manual_workout_screen.dart';
import 'package:fitness_app/features/workout/domain/gym_set_entry.dart';
import 'package:fitness_app/features/workout/domain/manual_workout_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Active logger: adjust a working set and explicitly start its rest',
      (t) async {
    for (final f in [
      ('Inter', 'assets/fonts/inter.ttf'),
      ('Plus Jakarta Sans', 'assets/fonts/plusjakartasans.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf')
    ]) {
      await (FontLoader(f.$1)..addFont(rootBundle.load(f.$2))).load();
    }
    final date = DateTime(2024, 10, 24);
    final bench = 'Barbell Incline Bench Press';
    final sets = [
      for (var i = 0; i < 7; i++)
        GymSetEntry(
            exerciseName: i < 3 ? bench : 'Standing Dumbbell Lateral Raise',
            muscleGroup:
                i < 3 ? 'Chest · Anterior Deltoid' : 'Lateral Deltoids',
            setNumber: i + 1,
            reps: i < 3 ? 8 : 12,
            weightKg: i == 0
                ? 80
                : i < 3
                    ? 82.5
                    : 14,
            rpe: i == 0 ? 8 : 8.5)
    ];
    final session = ManualWorkoutSession(
        id: 'fixture',
        title: 'Upper Body Hypertrophy – Push A',
        dateKey: '2024-10-24',
        durationMinutes: 34,
        totalDurationSeconds: 2058,
        activeDurationSeconds: 1300,
        restDurationSeconds: 758,
        estimatedActiveCalories: 0,
        createdAt: date,
        sets: sets);
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'manual_workout_sessions': jsonEncode([
        {
          ...session.toJson(),
          'id': 'previous',
          'createdAt': '2024-10-20T09:00:00',
          'dateKey': '2024-10-20'
        }
      ]),
      'weekly_workout_routine': jsonEncode({
        'activeRoutineId': 'split',
        'routines': [
          {
            'id': 'split',
            'name': '4-Day Push/Pull Split',
            'days': {
              '4': [
                {
                  'type': 'superset',
                  'exercises': [
                    for (final x in [
                      'Cable Tricep Pushdown',
                      'Cable Bayesian Curl'
                    ])
                      {
                        'exerciseName': x,
                        'muscleGroup': 'Arms',
                        'sets': 3,
                        'reps': 12,
                        'weightKg': 27
                      }
                  ]
                }
              ]
            }
          }
        ]
      })
    });
    final height = double.parse(Platform.environment['STITCH_HEIGHT'] ?? '884');
    final size = Size(412, height);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    await t.binding.setSurfaceSize(size);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(() => t.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await t.pumpWidget(ProviderScope(
        child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                theme: AppTheme.dark(),
                debugShowCheckedModeBanner: false,
                home: ManualWorkoutScreen(session: session)))));
    await t.pumpAndSettle();
    for (final index in [1, 2]) {
      final b = find.byKey(ValueKey('log-set-$index'));
      await t.ensureVisible(b);
      await t.pumpAndSettle();
      await t.tap(b);
      await t.pumpAndSettle();
    }
    final scroll = t.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(0);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('rest-toggle-button')));
    await t.pump(const Duration(seconds: 19));
    await t.pump();
    final dir = Platform.environment['STITCH_CAPTURE_DIR'];
    if (dir != null) {
      await t.runAsync(() async {
        await Directory(dir).create(recursive: true);
        final image = await (key.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$dir/logger.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await t.tap(find.byKey(const Key('rest-toggle-button')));
    await t.pump();
    final more = find.byTooltip('+ KG');
    await t.dragUntilVisible(
        more.hitTestable(), find.byType(ListView).first, const Offset(0, -160));
    await t.pumpAndSettle();
    await t.tap(more);
    await t.pumpAndSettle();
    expect(find.text('85'), findsWidgets);
    final done = find.text('Complete set & start 90s rest');
    await t.ensureVisible(done);
    await t.pumpAndSettle();
    await t.tap(done);
    await t.pump();
    scroll.position.jumpTo(0);
    await t.pump();
    expect(find.text('Counting down'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });
}
