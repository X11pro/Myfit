import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_weight_entry.dart';

final dailyWeightEntriesProvider =
    NotifierProvider<DailyWeightEntriesNotifier, List<DailyWeightEntry>>(
  DailyWeightEntriesNotifier.new,
);

final todayWeightEntryProvider = Provider<DailyWeightEntry?>((ref) {
  final entries = ref.watch(dailyWeightEntriesProvider);
  final todayKey = _dateKey(DateTime.now());

  for (final entry in entries) {
    if (entry.dateKey == todayKey) {
      return entry;
    }
  }

  return null;
});

class DailyWeightEntriesNotifier extends Notifier<List<DailyWeightEntry>> {
  static const _storageKey = 'daily_weight_entries';

  @override
  List<DailyWeightEntry> build() {
    Future<void>.microtask(_loadEntries);
    return const [];
  }

  Future<void> upsertTodayWeight(double weightKg) async {
    final todayKey = _dateKey(DateTime.now());
    var replaced = false;

    state = [
      for (final entry in state)
        if (entry.dateKey == todayKey)
          () {
            replaced = true;
            return DailyWeightEntry(dateKey: todayKey, weightKg: weightKg);
          }()
        else
          entry,
      if (!replaced) DailyWeightEntry(dateKey: todayKey, weightKg: weightKg),
    ]..sort((a, b) => b.dateKey.compareTo(a.dateKey));

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
            DailyWeightEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  Future<void> _persistEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((entry) => entry.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}

String _dateKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
