import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_state.dart';
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
  static const _guestStorageKey = 'daily_weight_entries';
  static const _authCacheStorageKey = 'daily_weight_entries_auth_cache';
  String? _lastScopeKey;
  int _loadToken = 0;
  bool _didSetupScopeListener = false;

  @override
  List<DailyWeightEntry> build() {
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

  Future<void> upsertTodayWeight(double weightKg) async {
    _lastScopeKey ??= _currentScopeKey();
    _loadToken++;
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

    if (_isAuthenticated) {
      await _upsertRemoteTodayWeight(todayKey, weightKg);
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
          .from('body_metrics')
          .select('id, date, weight_kg, created_at')
          .not('weight_kg', 'is', null)
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      var entries = _mapRemoteWeights(rows);
      if (entries.isEmpty && seedFromGuestIfEmpty) {
        final guestEntries = await _readEntries(_guestStorageKey);
        if (guestEntries.isNotEmpty) {
          for (final entry in guestEntries) {
            await _upsertRemoteTodayWeight(entry.dateKey, entry.weightKg);
          }
          final seededRows = await client
              .from('body_metrics')
              .select('id, date, weight_kg, created_at')
              .not('weight_kg', 'is', null)
              .order('date', ascending: false)
              .order('created_at', ascending: false);
          entries = _mapRemoteWeights(seededRows);
        }
      }

      if (token != _loadToken) {
        return;
      }

      state = entries;
      await _persistEntries(_authCacheStorageKey);
    } catch (_) {
      final cached = await _readEntries(_authCacheStorageKey);
      if (token != _loadToken) {
        return;
      }
      state = cached;
    }
  }

  Future<void> _upsertRemoteTodayWeight(String dateKey, double weightKg) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      return;
    }

    final existing = await client
        .from('body_metrics')
        .select('id')
        .eq('user_id', user.id)
        .eq('date', dateKey)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      await client.from('body_metrics').update({
        'weight_kg': weightKg,
        'source': 'manual',
      }).eq('id', existing['id']);
      return;
    }

    await client.from('body_metrics').insert({
      'user_id': user.id,
      'date': dateKey,
      'weight_kg': weightKg,
      'source': 'manual',
    });
  }

  List<DailyWeightEntry> _mapRemoteWeights(List<dynamic> rows) {
    final latestByDate = <String, DailyWeightEntry>{};
    for (final row in rows) {
      final item = Map<String, dynamic>.from(row as Map);
      final dateKey = item['date']?.toString();
      final weightKg = (item['weight_kg'] as num?)?.toDouble();
      if (dateKey == null || dateKey.isEmpty || weightKg == null) {
        continue;
      }
      latestByDate.putIfAbsent(
        dateKey,
        () => DailyWeightEntry(dateKey: dateKey, weightKg: weightKg),
      );
    }

    final entries = latestByDate.values.toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return entries;
  }

  Future<List<DailyWeightEntry>> _readEntries(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(storageKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;
    return decoded
        .map((item) =>
            DailyWeightEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  Future<void> _persistEntries(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((entry) => entry.toJson()).toList());
    await prefs.setString(storageKey, encoded);
  }
}

String _dateKey(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
