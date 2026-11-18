import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_state.dart';
import '../domain/weekly_workout_routine.dart';

final weeklyWorkoutRoutineProvider =
    NotifierProvider<WeeklyWorkoutRoutineNotifier, WorkoutRoutineLibrary>(
  WeeklyWorkoutRoutineNotifier.new,
);

class WeeklyWorkoutRoutineNotifier extends Notifier<WorkoutRoutineLibrary> {
  static const _storageKey = 'weekly_workout_routine';
  bool _localLoaded = false;
  bool _localReady = false;
  String? _remoteUserId;

  @override
  WorkoutRoutineLibrary build() {
    ref.listen<AppState>(appStateProvider, (previous, next) {
      if (next.isAuthenticated &&
          previous?.isAuthenticated != true &&
          _localReady) {
        Future<void>.microtask(_rehydrateRemote);
      }
      if (!next.isAuthenticated) {
        _remoteUserId = null;
      }
    });
    if (!_localLoaded) {
      _localLoaded = true;
      Future<void>.microtask(_loadLocal);
    }
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
    await _persistAndSync();
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
    await _persistAndSync();
  }

  Future<void> selectRoutine(String routineId) async {
    state = state.copyWith(activeRoutineId: routineId);
    await _persistAndSync();
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
    await _persistAndSync();
  }

  Future<void> deleteRoutine(String routineId) async {
    final routines = state.routines
        .where((routine) => routine.id != routineId)
        .toList(growable: false);
    state = WorkoutRoutineLibrary(
      routines: routines,
      activeRoutineId: routines.isEmpty ? null : routines.first.id,
    );
    await _persistAndSync();
  }

  Future<void> refreshFromRemote() async {
    _remoteUserId = null;
    await _rehydrateRemote();
  }

  Future<void> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final rawRoutine = prefs.getString(_storageKey);
    if (rawRoutine == null || rawRoutine.isEmpty) {
      _localReady = true;
      await _rehydrateRemote();
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
        await _persistLocal();
      }
    } catch (_) {
      state = const WorkoutRoutineLibrary();
    }
    _localReady = true;
    await _rehydrateRemote();
  }

  Future<void> _persistAndSync() async {
    await _persistLocal();
    await _syncRemote();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> _rehydrateRemote() async {
    if (!AppEnv.hasSupabaseConfig) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || _remoteUserId == user.id) {
      return;
    }
    _remoteUserId = user.id;

    try {
      final row = await Supabase.instance.client
          .from('workout_routines')
          .select('library')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row == null) {
        await _syncRemote();
        return;
      }

      final library = WorkoutRoutineLibrary.fromJson(
        Map<String, dynamic>.from(row['library'] as Map),
      );
      state = library;
      await _persistLocal();
    } catch (_) {
      // Keep the local routine library available while offline or before migration.
    }
  }

  Future<void> _syncRemote() async {
    if (!AppEnv.hasSupabaseConfig) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await Supabase.instance.client.from('workout_routines').upsert({
        'user_id': user.id,
        'library': state.toJson(),
      }, onConflict: 'user_id');
    } catch (_) {
      // The local copy is the offline fallback; a later user edit retries sync.
    }
  }
}
