import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ManualWorkoutSessionsNotifier
    extends Notifier<List<ManualWorkoutSession>> {
  static const _storageKey = 'manual_workout_sessions';

  @override
  List<ManualWorkoutSession> build() {
    Future<void>.microtask(_loadEntries);
    return const [];
  }

  Future<void> addSession({
    required String title,
    required DateTime date,
    required int durationMinutes,
    required int estimatedActiveCalories,
    required List<GymSetEntry> sets,
    String? notes,
  }) async {
    state = [
      ManualWorkoutSession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        dateKey: dateKeyFor(date),
        durationMinutes: durationMinutes,
        estimatedActiveCalories: estimatedActiveCalories,
        createdAt: date,
        sets: sets,
        notes: notes,
      ),
      ...state,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await _persistEntries();
  }

  Future<void> updateSession({
    required String id,
    required String title,
    required DateTime date,
    required int durationMinutes,
    required int estimatedActiveCalories,
    required List<GymSetEntry> sets,
    String? notes,
  }) async {
    state = [
      for (final entry in state)
        if (entry.id == id)
          ManualWorkoutSession(
            id: entry.id,
            title: title,
            dateKey: dateKeyFor(date),
            durationMinutes: durationMinutes,
            estimatedActiveCalories: estimatedActiveCalories,
            createdAt: date,
            sets: sets,
            notes: notes,
          )
        else
          entry,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await _persistEntries();
  }

  Future<void> deleteSession(String id) async {
    state = state.where((entry) => entry.id != id).toList();
    await _persistEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(_storageKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return;
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;
    state = decoded
        .map((item) =>
            ManualWorkoutSession.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((entry) => entry.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

String dateKeyFor(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
