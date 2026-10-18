import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/weekly_workout_routine.dart';

final weeklyWorkoutRoutineProvider =
    NotifierProvider<WeeklyWorkoutRoutineNotifier, WorkoutRoutineLibrary>(
  WeeklyWorkoutRoutineNotifier.new,
);

class WeeklyWorkoutRoutineNotifier extends Notifier<WorkoutRoutineLibrary> {
  static const _storageKey = 'weekly_workout_routine';

  @override
  WorkoutRoutineLibrary build() {
    Future<void>.microtask(_load);
    return const WorkoutRoutineLibrary();
  }

  Future<void> setDayBlocks(
    String routineId,
    int weekday,
    List<WorkoutRoutineBlock> blocks,
  ) async {
    state = state.copyWith(
      routines: [
        for (final routine in state.routines)
          if (routine.id == routineId)
            routine.copyWithDay(weekday, blocks)
          else
            routine,
      ],
    );
    await _persist();
  }

  Future<void> createRoutine(String name) async {
    final routine = WeeklyWorkoutRoutine(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    state = state.copyWith(
      routines: [...state.routines, routine],
      activeRoutineId: routine.id,
    );
    await _persist();
  }

  Future<void> selectRoutine(String routineId) async {
    state = state.copyWith(activeRoutineId: routineId);
    await _persist();
  }

  Future<void> renameRoutine(String routineId, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }
    state = state.copyWith(
      routines: [
        for (final routine in state.routines)
          if (routine.id == routineId)
            WeeklyWorkoutRoutine(
              id: routine.id,
              name: trimmedName,
              blocksByWeekday: routine.blocksByWeekday,
            )
          else
            routine,
      ],
    );
    await _persist();
  }

  Future<void> deleteRoutine(String routineId) async {
    final routines = state.routines
        .where((routine) => routine.id != routineId)
        .toList(growable: false);
    state = WorkoutRoutineLibrary(
      routines: routines,
      activeRoutineId: routines.isEmpty ? null : routines.first.id,
    );
    await _persist();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRoutine = prefs.getString(_storageKey);
    if (rawRoutine == null || rawRoutine.isEmpty) {
      return;
    }

    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(rawRoutine) as Map);
      if (decoded.containsKey('routines')) {
        state = WorkoutRoutineLibrary.fromJson(decoded);
      } else {
        final routine = WeeklyWorkoutRoutine.fromJson(decoded);
        final migrated = WeeklyWorkoutRoutine(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          name: routine.name,
          blocksByWeekday: routine.blocksByWeekday,
        );
        state = WorkoutRoutineLibrary(
          routines: [migrated],
          activeRoutineId: migrated.id,
        );
        await _persist();
      }
    } catch (_) {
      state = const WorkoutRoutineLibrary();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }
}
