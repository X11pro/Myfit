import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';

final appStateProvider =
    NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

class AppState {
  const AppState({
    required this.isLoading,
    required this.isAuthenticated,
    required this.isOnboardingComplete,
    this.authEmail,
    this.displayName,
    this.goal,
    this.jobActivityLevel,
    this.activityLevel,
    this.sex,
    this.dateOfBirth,
    this.heightCm,
    this.currentWeightKg,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final bool isOnboardingComplete;
  final String? authEmail;
  final String? displayName;
  final String? goal;
  final String? jobActivityLevel;
  final String? activityLevel;
  final String? sex;
  final DateTime? dateOfBirth;
  final double? heightCm;
  final double? currentWeightKg;

  bool get hasEnergyProfile =>
      heightCm != null &&
      currentWeightKg != null &&
      dateOfBirth != null &&
      activityLevel != null;

  AppState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isOnboardingComplete,
    String? authEmail,
    String? displayName,
    String? goal,
    String? jobActivityLevel,
    String? activityLevel,
    String? sex,
    DateTime? dateOfBirth,
    double? heightCm,
    double? currentWeightKg,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      authEmail: authEmail ?? this.authEmail,
      displayName: displayName ?? this.displayName,
      goal: goal ?? this.goal,
      jobActivityLevel: jobActivityLevel ?? this.jobActivityLevel,
      activityLevel: activityLevel ?? this.activityLevel,
      sex: sex ?? this.sex,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
    );
  }

  static const initial = AppState(
    isLoading: false,
    isAuthenticated: false,
    isOnboardingComplete: false,
  );
}

class AppStateNotifier extends Notifier<AppState> {
  static const _displayNameKey = 'guest_display_name';
  static const _goalKey = 'guest_goal';
  static const _jobActivityLevelKey = 'guest_job_activity_level';
  static const _activityLevelKey = 'guest_activity_level';
  static const _sexKey = 'guest_sex';
  static const _dateOfBirthKey = 'guest_date_of_birth';
  static const _heightCmKey = 'guest_height_cm';
  static const _currentWeightKgKey = 'guest_current_weight_kg';

  StreamSubscription<AuthState>? _authSubscription;

  @override
  AppState build() {
    if (!AppEnv.hasSupabaseConfig) {
      Future<void>.microtask(_loadLocalState);

      return const AppState(
        isLoading: true,
        isAuthenticated: false,
        isOnboardingComplete: false,
      );
    }

    final client = Supabase.instance.client;

    _authSubscription ??= client.auth.onAuthStateChange.listen((data) {
      unawaited(_syncFromSession(data.session));
    });

    ref.onDispose(() {
      _authSubscription?.cancel();
      _authSubscription = null;
    });

    Future<void>.microtask(() => _syncFromSession(client.auth.currentSession));

    return const AppState(
      isLoading: true,
      isAuthenticated: false,
      isOnboardingComplete: false,
    );
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }

  Future<void> completeOnboarding({
    required String displayName,
    required String goal,
    required String jobActivityLevel,
    required String activityLevel,
    String? sex,
    DateTime? dateOfBirth,
    double? heightCm,
    double? currentWeightKg,
  }) async {
    final session = AppEnv.hasSupabaseConfig
        ? Supabase.instance.client.auth.currentSession
        : null;
    final user = session?.user;

    if (!AppEnv.hasSupabaseConfig || user == null) {
      await _saveLocalState(
        displayName: displayName,
        goal: goal,
        jobActivityLevel: jobActivityLevel,
        activityLevel: activityLevel,
        sex: sex,
        dateOfBirth: dateOfBirth,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: user != null,
        authEmail: user?.email,
        displayName: displayName,
        goal: goal,
        jobActivityLevel: jobActivityLevel,
        activityLevel: activityLevel,
        sex: sex,
        dateOfBirth: dateOfBirth,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        isOnboardingComplete: true,
      );
      return;
    }

    setLoading(true);

    try {
      final client = Supabase.instance.client;

      await client.from('profiles').upsert({
        'user_id': user.id,
        'display_name': displayName,
        'goal': goal,
        'job_activity_level': jobActivityLevel,
        'activity_level': activityLevel,
        'sex': sex,
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'height_cm': heightCm,
      }, onConflict: 'user_id');

      if (currentWeightKg != null) {
        await client.from('body_metrics').insert({
          'user_id': user.id,
          'date': DateTime.now().toUtc().toIso8601String().split('T').first,
          'weight_kg': currentWeightKg,
          'source': 'onboarding',
        });
      }

      state = AppState(
        isLoading: false,
        isAuthenticated: true,
        isOnboardingComplete: true,
        authEmail: user.email,
        displayName: displayName,
        goal: goal,
        jobActivityLevel: jobActivityLevel,
        activityLevel: activityLevel,
        sex: sex,
        dateOfBirth: dateOfBirth,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
      );
    } catch (_) {
      setLoading(false);
      rethrow;
    }
  }

  void reset() {
    state = AppState.initial;
  }

  Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    final displayName = prefs.getString(_displayNameKey);
    final goal = prefs.getString(_goalKey);
    final jobActivityLevel = prefs.getString(_jobActivityLevelKey);
    final activityLevel = prefs.getString(_activityLevelKey);
    final sex = prefs.getString(_sexKey);
    final dateOfBirth = _asDate(prefs.getString(_dateOfBirthKey));
    final heightCm = prefs.getDouble(_heightCmKey);
    final currentWeightKg = prefs.getDouble(_currentWeightKgKey);

    state = AppState(
      isLoading: false,
      isAuthenticated: false,
      isOnboardingComplete: displayName != null &&
          goal != null &&
          jobActivityLevel != null &&
          heightCm != null &&
          currentWeightKg != null &&
          activityLevel != null &&
          dateOfBirth != null,
      displayName: displayName,
      goal: goal,
      jobActivityLevel: jobActivityLevel,
      activityLevel: activityLevel,
      sex: sex,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
    );
  }

  Future<void> _saveLocalState({
    required String displayName,
    required String goal,
    required String jobActivityLevel,
    required String activityLevel,
    String? sex,
    DateTime? dateOfBirth,
    required double? heightCm,
    required double? currentWeightKg,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_displayNameKey, displayName);
    await prefs.setString(_goalKey, goal);
    await prefs.setString(_jobActivityLevelKey, jobActivityLevel);
    await prefs.setString(_activityLevelKey, activityLevel);
    if (sex == null) {
      await prefs.remove(_sexKey);
    } else {
      await prefs.setString(_sexKey, sex);
    }
    if (dateOfBirth == null) {
      await prefs.remove(_dateOfBirthKey);
    } else {
      await prefs.setString(
        _dateOfBirthKey,
        dateOfBirth.toIso8601String().split('T').first,
      );
    }

    if (heightCm != null) {
      await prefs.setDouble(_heightCmKey, heightCm);
    } else {
      await prefs.remove(_heightCmKey);
    }

    if (currentWeightKg != null) {
      await prefs.setDouble(_currentWeightKgKey, currentWeightKg);
    } else {
      await prefs.remove(_currentWeightKgKey);
    }
  }

  Future<void> _syncFromSession(Session? session) async {
    if (!AppEnv.hasSupabaseConfig) {
      state = AppState.initial;
      return;
    }

    final user = session?.user;

    if (user == null) {
      await _loadLocalState();
      return;
    }

    state = state.copyWith(isLoading: true, isAuthenticated: true);

    try {
      final client = Supabase.instance.client;
      final profile = await client
          .from('profiles')
          .select(
              'display_name, goal, job_activity_level, activity_level, sex, date_of_birth, height_cm')
          .eq('user_id', user.id)
          .maybeSingle();
      final bodyMetric = await client
          .from('body_metrics')
          .select('weight_kg')
          .eq('user_id', user.id)
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      state = AppState(
        isLoading: false,
        isAuthenticated: true,
        isOnboardingComplete: _isOnboardingComplete(profile, bodyMetric),
        authEmail: user.email,
        displayName: _asString(profile?['display_name']),
        goal: _asString(profile?['goal']),
        jobActivityLevel: _asString(profile?['job_activity_level']),
        activityLevel: _asString(profile?['activity_level']),
        sex: _asString(profile?['sex']),
        dateOfBirth: _asDate(profile?['date_of_birth']),
        heightCm: _asDouble(profile?['height_cm']),
        currentWeightKg: _asDouble(bodyMetric?['weight_kg']),
      );
    } catch (_) {
      state = const AppState(
        isLoading: false,
        isAuthenticated: true,
        isOnboardingComplete: false,
      );
    }
  }

  bool _isOnboardingComplete(
    Map<String, dynamic>? profile,
    Map<String, dynamic>? bodyMetric,
  ) {
    return _asString(profile?['display_name']) != null &&
        _asString(profile?['goal']) != null &&
        _asString(profile?['job_activity_level']) != null &&
        _asDouble(profile?['height_cm']) != null &&
        _asString(profile?['activity_level']) != null &&
        _asDate(profile?['date_of_birth']) != null &&
        _asDouble(bodyMetric?['weight_kg']) != null;
  }

  String? _asString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    return null;
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  DateTime? _asDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
