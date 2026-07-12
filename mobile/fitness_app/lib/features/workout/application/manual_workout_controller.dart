import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_state.dart';
import '../domain/gym_set_entry.dart';
import '../domain/manual_workout_session.dart';

final manualWorkoutSessionsProvider =
    NotifierProvider<ManualWorkoutSessionsNotifier, List<ManualWorkoutSession>>(
  ManualWorkoutSessionsNotifier.new,
);

final todayWorkoutSessionsProvider =
    Provider<List<ManualWorkoutSession>>((ref) {
  final entries = ref.watch(manualWorkoutSessionsProvider);
  final todayKey = dateKeyFor(DateTime.now());
  return entries.where((entry) => entry.dateKey == todayKey).toList();
});

final todayWorkoutCaloriesProvider = Provider<int>((ref) {
  final entries = ref.watch(todayWorkoutSessionsProvider);
  var total = 0;
  for (final entry in entries) {
    total += entry.estimatedActiveCalories;
  }
  return total;
});

final recentWorkoutExerciseNamesProvider = Provider<List<String>>((ref) {
  final sessions = ref.watch(manualWorkoutSessionsProvider);
  final names = <String>[];
  final seen = <String>{};

  for (final session in sessions) {
    for (final set in session.sets) {
      final name = set.exerciseName.trim();
      final normalized = name.toLowerCase();
      if (name.isEmpty || !seen.add(normalized)) {
        continue;
      }
      names.add(name);
    }
  }

  return names;
});

class ManualWorkoutSessionsNotifier
    extends Notifier<List<ManualWorkoutSession>> {
  static const _guestStorageKey = 'manual_workout_sessions';
  static const _authCacheStorageKey = 'manual_workout_sessions_auth_cache';
  String? _lastScopeKey;
  int _loadToken = 0;
  bool _didSetupScopeListener = false;

  @override
  List<ManualWorkoutSession> build() {
    if (!_didSetupScopeListener) {
      _didSetupScopeListener = true;
      ref.listen<AppState>(appStateProvider, (_, __) {
        unawaited(_refreshScope());
      });
      Future<void>.microtask(_refreshScope);
    }

    return const [];
  }

  Future<void> _refreshScope() async {
    final appState = ref.read(appStateProvider);
    final userId = AppEnv.hasSupabaseConfig && appState.isAuthenticated
        ? Supabase.instance.client.auth.currentUser?.id
        : null;
    final scopeKey = userId ?? 'guest';
    if (_lastScopeKey == scopeKey) {
      return;
    }

    _lastScopeKey = scopeKey;
    final token = ++_loadToken;
    if (userId == null) {
      await _loadGuestEntries(token);
      return;
    }

    await _loadRemoteEntries(token: token, seedFromGuestIfEmpty: true);
  }

  String _currentScopeKey() {
    final appState = ref.read(appStateProvider);
    final userId = AppEnv.hasSupabaseConfig && appState.isAuthenticated
        ? Supabase.instance.client.auth.currentUser?.id
        : null;
    return userId ?? 'guest';
  }

  Future<void> addSession({
    required String title,
    required DateTime date,
    required int durationMinutes,
    int? totalDurationSeconds,
    int? activeDurationSeconds,
    int? restDurationSeconds,
    required int estimatedActiveCalories,
    required List<GymSetEntry> sets,
    String? notes,
  }) async {
    _lastScopeKey ??= _currentScopeKey();
    _loadToken++;
    final resolvedTotalDurationSeconds =
        totalDurationSeconds ?? durationMinutes * 60;
    final resolvedRestDurationSeconds = restDurationSeconds ?? 0;
    final resolvedActiveDurationSeconds = activeDurationSeconds ??
        (resolvedTotalDurationSeconds >= resolvedRestDurationSeconds
            ? resolvedTotalDurationSeconds - resolvedRestDurationSeconds
            : 0);

    state = [
      ManualWorkoutSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        dateKey: dateKeyFor(date),
        durationMinutes: durationMinutes,
        totalDurationSeconds: resolvedTotalDurationSeconds,
        activeDurationSeconds: resolvedActiveDurationSeconds,
        restDurationSeconds: resolvedRestDurationSeconds,
        estimatedActiveCalories: estimatedActiveCalories,
        createdAt: date,
        sets: sets,
        notes: notes,
      ),
      ...state,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_isAuthenticated) {
      await _insertRemoteSession(state.first);
      await _loadRemoteEntries(
        token: _loadToken,
        seedFromGuestIfEmpty: false,
      );
      return;
    }

    await _persistEntries(_guestStorageKey);
  }

  Future<void> updateSession({
    required String id,
    required String title,
    required DateTime date,
    required int durationMinutes,
    int? totalDurationSeconds,
    int? activeDurationSeconds,
    int? restDurationSeconds,
    required int estimatedActiveCalories,
    required List<GymSetEntry> sets,
    String? notes,
  }) async {
    _lastScopeKey ??= _currentScopeKey();
    _loadToken++;
    final resolvedTotalDurationSeconds =
        totalDurationSeconds ?? durationMinutes * 60;
    final resolvedRestDurationSeconds = restDurationSeconds ?? 0;
    final resolvedActiveDurationSeconds = activeDurationSeconds ??
        (resolvedTotalDurationSeconds >= resolvedRestDurationSeconds
            ? resolvedTotalDurationSeconds - resolvedRestDurationSeconds
            : 0);

    state = [
      for (final entry in state)
        if (entry.id == id)
          ManualWorkoutSession(
            id: entry.id,
            title: title,
            dateKey: dateKeyFor(date),
            durationMinutes: durationMinutes,
            totalDurationSeconds: resolvedTotalDurationSeconds,
            activeDurationSeconds: resolvedActiveDurationSeconds,
            restDurationSeconds: resolvedRestDurationSeconds,
            estimatedActiveCalories: estimatedActiveCalories,
            createdAt: date,
            sets: sets,
            notes: notes,
          )
        else
          entry,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (_isAuthenticated) {
      final updated = state.firstWhere((entry) => entry.id == id);
      await _updateRemoteSession(updated);
      await _loadRemoteEntries(
        token: _loadToken,
        seedFromGuestIfEmpty: false,
      );
      return;
    }

    await _persistEntries(_guestStorageKey);
  }

  Future<void> deleteSession(String id) async {
    _lastScopeKey ??= _currentScopeKey();
    _loadToken++;
    state = state.where((entry) => entry.id != id).toList();
    if (_isAuthenticated) {
      await Supabase.instance.client
          .from('workout_sessions')
          .delete()
          .eq('id', id);
      await _persistEntries(_authCacheStorageKey);
      return;
    }

    await _persistEntries(_guestStorageKey);
  }

  bool get _isAuthenticated =>
      AppEnv.hasSupabaseConfig &&
      ref.read(appStateProvider).isAuthenticated &&
      Supabase.instance.client.auth.currentUser != null;

  Future<void> _loadGuestEntries(int token) async {
    final entries = await _readEntries(_guestStorageKey);
    if (token != _loadToken) {
      return;
    }
    state = entries;
  }

  Future<void> _loadRemoteEntries({
    required int token,
    required bool seedFromGuestIfEmpty,
  }) async {
    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('workout_sessions')
          .select(
            'id, title, started_at, duration_minutes, active_calories, notes, total_duration_seconds, active_duration_seconds, rest_duration_seconds, gym_sets(exercise_name, muscle_group, set_number, reps, weight_kg, rpe)',
          )
          .eq('source', 'manual')
          .order('started_at', ascending: false);

      var sessions = _mapRemoteSessions(rows);
      if (sessions.isEmpty && seedFromGuestIfEmpty) {
        final guestEntries = await _readEntries(_guestStorageKey);
        if (guestEntries.isNotEmpty) {
          for (final session in guestEntries) {
            await _insertRemoteSession(session);
          }
          final seededRows = await client
              .from('workout_sessions')
              .select(
                'id, title, started_at, duration_minutes, active_calories, notes, total_duration_seconds, active_duration_seconds, rest_duration_seconds, gym_sets(exercise_name, muscle_group, set_number, reps, weight_kg, rpe)',
              )
              .eq('source', 'manual')
              .order('started_at', ascending: false);
          sessions = _mapRemoteSessions(seededRows);
        }
      }

      if (token != _loadToken) {
        return;
      }

      state = sessions;
      await _persistEntries(_authCacheStorageKey);
    } catch (_) {
      final cached = await _readEntries(_authCacheStorageKey);
      if (token != _loadToken) {
        return;
      }
      state = cached;
    }
  }

  Future<void> _insertRemoteSession(ManualWorkoutSession session) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return;
    }

    final startedAt = _remoteStartedAtForDate(session.createdAt);
    final totalSeconds = session.totalDurationSeconds > 0
        ? session.totalDurationSeconds
        : session.durationMinutes * 60;
    final endedAt =
        startedAt.add(Duration(seconds: totalSeconds <= 0 ? 60 : totalSeconds));

    final inserted = await client
        .from('workout_sessions')
        .insert({
          'user_id': user.id,
          'source': 'manual',
          'started_at': startedAt.toIso8601String(),
          'ended_at': endedAt.toIso8601String(),
          'activity_type': 'strength_training',
          'title': session.title,
          'duration_minutes': session.durationMinutes,
          'active_calories': session.estimatedActiveCalories,
          'notes': session.notes,
          'total_duration_seconds': session.totalDurationSeconds,
          'active_duration_seconds': session.activeDurationSeconds,
          'rest_duration_seconds': session.restDurationSeconds,
        })
        .select('id')
        .single();

    await _replaceRemoteSets(
      inserted['id'] as String,
      session.sets,
    );
  }

  Future<void> _updateRemoteSession(ManualWorkoutSession session) async {
    final client = Supabase.instance.client;
    final startedAt = _remoteStartedAtForDate(session.createdAt);
    final totalSeconds = session.totalDurationSeconds > 0
        ? session.totalDurationSeconds
        : session.durationMinutes * 60;
    final endedAt =
        startedAt.add(Duration(seconds: totalSeconds <= 0 ? 60 : totalSeconds));

    await client.from('workout_sessions').update({
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'title': session.title,
      'duration_minutes': session.durationMinutes,
      'active_calories': session.estimatedActiveCalories,
      'notes': session.notes,
      'total_duration_seconds': session.totalDurationSeconds,
      'active_duration_seconds': session.activeDurationSeconds,
      'rest_duration_seconds': session.restDurationSeconds,
    }).eq('id', session.id);

    await _replaceRemoteSets(session.id, session.sets);
  }

  Future<void> _replaceRemoteSets(
      String sessionId, List<GymSetEntry> sets) async {
    final client = Supabase.instance.client;
    await client.from('gym_sets').delete().eq('workout_session_id', sessionId);
    if (sets.isEmpty) {
      return;
    }

    await client.from('gym_sets').insert([
      for (final set in sets)
        {
          'workout_session_id': sessionId,
          'exercise_name': set.exerciseName,
          'muscle_group': set.muscleGroup,
          'set_number': set.setNumber,
          'reps': set.reps,
          'weight_kg': set.weightKg,
          'rpe': set.rpe,
        },
    ]);
  }

  List<ManualWorkoutSession> _mapRemoteSessions(List<dynamic> rows) {
    return rows.map((row) {
      final item = Map<String, dynamic>.from(row as Map);
      final startedAt = DateTime.parse(item['started_at'] as String).toLocal();
      final rawSets = item['gym_sets'] as List<dynamic>? ?? const [];
      final sets = rawSets.map((set) {
        final value = Map<String, dynamic>.from(set as Map);
        return GymSetEntry(
          exerciseName: value['exercise_name'] as String? ?? '',
          muscleGroup: value['muscle_group'] as String? ?? '',
          setNumber: (value['set_number'] as num?)?.toInt() ?? 1,
          reps: (value['reps'] as num?)?.toInt() ?? 0,
          weightKg: (value['weight_kg'] as num?)?.toDouble() ?? 0,
          rpe: (value['rpe'] as num?)?.toDouble(),
        );
      }).toList()
        ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

      final durationMinutes = (item['duration_minutes'] as num?)?.toInt() ?? 0;
      final totalDurationSeconds =
          (item['total_duration_seconds'] as num?)?.toInt() ??
              durationMinutes * 60;
      final restDurationSeconds =
          (item['rest_duration_seconds'] as num?)?.toInt() ?? 0;
      final activeDurationSeconds =
          (item['active_duration_seconds'] as num?)?.toInt() ??
              (totalDurationSeconds >= restDurationSeconds
                  ? totalDurationSeconds - restDurationSeconds
                  : 0);

      return ManualWorkoutSession(
        id: item['id'] as String,
        title: item['title'] as String? ?? 'Gym session',
        dateKey: dateKeyFor(startedAt),
        durationMinutes: durationMinutes,
        totalDurationSeconds: totalDurationSeconds,
        activeDurationSeconds: activeDurationSeconds,
        restDurationSeconds: restDurationSeconds,
        estimatedActiveCalories:
            (item['active_calories'] as num?)?.toInt() ?? 0,
        createdAt: startedAt,
        sets: sets,
        notes: item['notes'] as String?,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ManualWorkoutSession>> _readEntries(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(storageKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;
    return decoded
        .map((item) =>
            ManualWorkoutSession.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persistEntries(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((entry) => entry.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }

  DateTime _remoteStartedAtForDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 12).toUtc();
  }
}

String dateKeyFor(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
