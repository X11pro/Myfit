import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_state.dart';
import '../domain/manual_food_entry.dart';

final manualFoodEntriesProvider =
    NotifierProvider<ManualFoodEntriesNotifier, List<ManualFoodEntry>>(
  ManualFoodEntriesNotifier.new,
);

final manualFoodSummaryProvider = Provider<ManualFoodSummary>((ref) {
  final entries = ref.watch(manualFoodEntriesProvider);

  var totalCalories = 0;
  var totalProteinGrams = 0;
  var totalCarbsGrams = 0;
  var totalFatGrams = 0;

  for (final entry in entries) {
    totalCalories += entry.calories;
    totalProteinGrams += entry.proteinGrams;
    totalCarbsGrams += entry.carbsGrams;
    totalFatGrams += entry.fatGrams;
  }

  return ManualFoodSummary(
    totalCalories: totalCalories,
    totalProteinGrams: totalProteinGrams,
    totalCarbsGrams: totalCarbsGrams,
    totalFatGrams: totalFatGrams,
    entryCount: entries.length,
  );
});

final dailyNutritionSummariesProvider =
    Provider<List<DailyNutritionSummary>>((ref) {
  final entries = ref.watch(manualFoodEntriesProvider);
  final totals =
      <String, ({int calories, int protein, int carbs, int fat, int count})>{};

  for (final entry in entries) {
    final dateKey = _dateKey(entry.createdAt);
    final current = totals[dateKey] ??
        (calories: 0, protein: 0, carbs: 0, fat: 0, count: 0);
    totals[dateKey] = (
      calories: current.calories + entry.calories,
      protein: current.protein + entry.proteinGrams,
      carbs: current.carbs + entry.carbsGrams,
      fat: current.fat + entry.fatGrams,
      count: current.count + 1,
    );
  }

  final summaries = totals.entries
      .map(
        (entry) => DailyNutritionSummary(
          dateKey: entry.key,
          totalCalories: entry.value.calories,
          totalProteinGrams: entry.value.protein,
          totalCarbsGrams: entry.value.carbs,
          totalFatGrams: entry.value.fat,
          entryCount: entry.value.count,
        ),
      )
      .toList()
    ..sort((a, b) => b.dateKey.compareTo(a.dateKey));

  return summaries;
});

final todayNutritionSummaryProvider = Provider<DailyNutritionSummary?>((ref) {
  final summaries = ref.watch(dailyNutritionSummariesProvider);
  final todayKey = _dateKey(DateTime.now());

  for (final summary in summaries) {
    if (summary.dateKey == todayKey) {
      return summary;
    }
  }

  return null;
});

class ManualFoodEntriesNotifier extends Notifier<List<ManualFoodEntry>> {
  static const _guestStorageKey = 'manual_food_entries';
  static const _authCacheStorageKey = 'manual_food_entries_auth_cache';
  String? _lastScopeKey;
  int _loadToken = 0;
  bool _didSetupScopeListener = false;

  @override
  List<ManualFoodEntry> build() {
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
    final scopeKey = _currentScopeKey();
    if (_lastScopeKey == scopeKey) {
      return;
    }

    _lastScopeKey = scopeKey;
    final token = ++_loadToken;
    if (!_isAuthenticated) {
      await _loadGuestEntries(token);
      return;
    }

    await _loadRemoteEntries(token: token, seedFromGuestIfEmpty: true);
  }

  Future<void> addEntry({
    required String name,
    required String mealType,
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    int sugarGrams = 0,
    int fiberGrams = 0,
    double? confidence,
    String? photoPath,
    String? remotePhotoId,
    String? remotePhotoStoragePath,
  }) async {
    _lastScopeKey ??= _currentScopeKey();
    _loadToken++;

    final draft = ManualFoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      mealType: mealType,
      calories: calories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      sugarGrams: sugarGrams,
      fiberGrams: fiberGrams,
      createdAt: DateTime.now(),
      confidence: confidence,
      photoPath: photoPath,
      remotePhotoId: remotePhotoId,
      remotePhotoStoragePath: remotePhotoStoragePath,
    );

    if (_isAuthenticated) {
      final inserted = await _insertRemoteEntry(draft);
      state = [inserted, ...state]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _persistEntries(_authCacheStorageKey);
      return;
    }

    state = [
      draft,
      ...state,
    ];

    await _persistEntries(_guestStorageKey);
  }

  Future<void> updateEntry({
    required String id,
    required String name,
    required String mealType,
    required int calories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    int sugarGrams = 0,
    int fiberGrams = 0,
    double? confidence,
    String? photoPath,
    String? remotePhotoId,
    String? remotePhotoStoragePath,
  }) async {
    _lastScopeKey ??= _currentScopeKey();
    _loadToken++;

    state = [
      for (final entry in state)
        if (entry.id == id)
          ManualFoodEntry(
            id: entry.id,
            name: name,
            mealType: mealType,
            calories: calories,
            proteinGrams: proteinGrams,
            carbsGrams: carbsGrams,
            fatGrams: fatGrams,
            sugarGrams: sugarGrams,
            fiberGrams: fiberGrams,
            createdAt: entry.createdAt,
            confidence: confidence,
            photoPath: photoPath,
            remotePhotoId: remotePhotoId,
            remotePhotoStoragePath: remotePhotoStoragePath,
          )
        else
          entry,
    ];

    if (_isAuthenticated) {
      final updated = state.firstWhere((entry) => entry.id == id);
      await _updateRemoteEntry(updated);
      await _persistEntries(_authCacheStorageKey);
      return;
    }

    await _persistEntries(_guestStorageKey);
  }

  Future<void> deleteEntry(String id) async {
    _lastScopeKey ??= _currentScopeKey();
    _loadToken++;
    final removedEntry = state.cast<ManualFoodEntry?>().firstWhere(
          (entry) => entry?.id == id,
          orElse: () => null,
        );
    state = state.where((entry) => entry.id != id).toList();
    if (_isAuthenticated) {
      if (removedEntry != null) {
        await _deleteRemotePhoto(removedEntry);
      }
      await Supabase.instance.client.from('meal_entries').delete().eq('id', id);
      await _persistEntries(_authCacheStorageKey);
      return;
    }

    await _persistEntries(_guestStorageKey);
  }

  bool get _isAuthenticated =>
      AppEnv.hasSupabaseConfig &&
      ref.read(appStateProvider).isAuthenticated &&
      Supabase.instance.client.auth.currentUser != null;

  String _currentScopeKey() {
    final appState = ref.read(appStateProvider);
    final userId = AppEnv.hasSupabaseConfig && appState.isAuthenticated
        ? Supabase.instance.client.auth.currentUser?.id
        : null;
    return userId ?? 'guest';
  }

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
      final remoteRows = await Supabase.instance.client
          .from('meal_entries')
          .select(
            'id, meal_date, meal_type, name, calories, protein_g, carbs_g, fat_g, sugar_g, fiber_g, confidence, created_at, photo_id, meal_photos(storage_path)',
          )
          .eq('source', 'manual')
          .order('meal_date', ascending: false)
          .order('created_at', ascending: false);

      final cachedEntries = await _readEntries(_authCacheStorageKey);
      var entries = await _mapRemoteEntries(
        remoteRows,
        cachedEntries: cachedEntries,
      );

      if (entries.isEmpty && seedFromGuestIfEmpty) {
        final guestEntries = await _readEntries(_guestStorageKey);
        if (guestEntries.isNotEmpty) {
          final seeded = <ManualFoodEntry>[];
          for (final entry in guestEntries) {
            seeded.add(await _insertRemoteEntry(entry));
          }
          entries = seeded..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  Future<ManualFoodEntry> _insertRemoteEntry(ManualFoodEntry entry) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return entry;
    }

    final inserted = await Supabase.instance.client
        .from('meal_entries')
        .insert({
          'user_id': user.id,
          'meal_date': _dateKey(entry.createdAt),
          'meal_type': entry.mealType,
          'name': entry.name,
          'calories': entry.calories,
          'protein_g': entry.proteinGrams,
          'carbs_g': entry.carbsGrams,
          'fat_g': entry.fatGrams,
          'sugar_g': entry.sugarGrams,
          'fiber_g': entry.fiberGrams,
          'source': 'manual',
          'confidence': entry.confidence,
          'photo_id': entry.remotePhotoId,
        })
        .select(
          'id, meal_date, meal_type, name, calories, protein_g, carbs_g, fat_g, sugar_g, fiber_g, confidence, created_at, photo_id, meal_photos(storage_path)',
        )
        .single();

    return await _remoteEntryFromMap(
          Map<String, dynamic>.from(inserted),
          cachedEntry: entry,
        ) ??
        entry;
  }

  Future<void> _updateRemoteEntry(ManualFoodEntry entry) async {
    await Supabase.instance.client.from('meal_entries').update({
      'meal_date': _dateKey(entry.createdAt),
      'meal_type': entry.mealType,
      'name': entry.name,
      'calories': entry.calories,
      'protein_g': entry.proteinGrams,
      'carbs_g': entry.carbsGrams,
      'fat_g': entry.fatGrams,
      'sugar_g': entry.sugarGrams,
      'fiber_g': entry.fiberGrams,
      'confidence': entry.confidence,
      'photo_id': entry.remotePhotoId,
    }).eq('id', entry.id);
  }

  Future<void> _deleteRemotePhoto(ManualFoodEntry entry) async {
    final storagePath = entry.remotePhotoStoragePath;
    final photoId = entry.remotePhotoId;

    if (storagePath != null && storagePath.trim().isNotEmpty) {
      await Supabase.instance.client.storage.from('meal-photos').remove([
        storagePath,
      ]);
    }

    if (photoId != null && photoId.trim().isNotEmpty) {
      await Supabase.instance.client
          .from('meal_photos')
          .delete()
          .eq('id', photoId);
    }
  }

  Future<List<ManualFoodEntry>> _mapRemoteEntries(
    List<dynamic> rows, {
    required List<ManualFoodEntry> cachedEntries,
  }) async {
    final cachedById = {
      for (final entry in cachedEntries) entry.id: entry,
    };

    final entries = <ManualFoodEntry>[];
    for (final item in rows) {
      final entry = await _remoteEntryFromMap(
        Map<String, dynamic>.from(item as Map),
        cachedEntry: cachedById[item['id']?.toString()],
      );
      if (entry != null) {
        entries.add(entry);
      }
    }

    return entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ManualFoodEntry?> _remoteEntryFromMap(
    Map<String, dynamic> item, {
    ManualFoodEntry? cachedEntry,
  }) async {
    final photoId = item['photo_id'] as String?;
    final photoPayload = item['meal_photos'];
    final storagePath = photoPayload is Map<String, dynamic>
        ? photoPayload['storage_path'] as String?
        : (photoPayload is Map
            ? photoPayload['storage_path'] as String?
            : null);

    String? photoPath;
    if (storagePath == null || storagePath.trim().isEmpty) {
      photoPath = cachedEntry?.photoPath;
    } else if (cachedEntry?.remotePhotoStoragePath == storagePath &&
        (cachedEntry?.photoPath ?? '').startsWith('http')) {
      photoPath = cachedEntry?.photoPath;
    } else {
      photoPath = await createSignedMealPhotoUrl(storagePath);
    }

    return ManualFoodEntry(
      id: item['id'] as String,
      name: item['name'] as String? ?? '',
      mealType: item['meal_type'] as String? ?? 'breakfast',
      calories: (item['calories'] as num?)?.toInt() ?? 0,
      proteinGrams: (item['protein_g'] as num?)?.toInt() ?? 0,
      carbsGrams: (item['carbs_g'] as num?)?.toInt() ?? 0,
      fatGrams: (item['fat_g'] as num?)?.toInt() ?? 0,
      sugarGrams: (item['sugar_g'] as num?)?.toInt() ?? 0,
      fiberGrams: (item['fiber_g'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(item['created_at'] as String).toLocal(),
      confidence: (item['confidence'] as num?)?.toDouble(),
      photoPath: photoPath,
      remotePhotoId: photoId,
      remotePhotoStoragePath: storagePath,
    );
  }

  Future<String> createSignedMealPhotoUrl(String storagePath) {
    return Supabase.instance.client.storage
        .from('meal-photos')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 30);
  }

  Future<List<ManualFoodEntry>> _readEntries(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getString(storageKey);

    if (rawEntries == null || rawEntries.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawEntries) as List<dynamic>;
    return decoded
        .map(
            (item) => ManualFoodEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
