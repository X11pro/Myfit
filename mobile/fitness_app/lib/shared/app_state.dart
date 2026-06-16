import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_env.dart';

final appStateProvider =
    NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

class AppState {
  const AppState({
    required this.isLoading,
    required this.isAuthenticated,
    required this.isOnboardingComplete,
    this.displayName,
    this.goal,
    this.jobActivityLevel,
    this.heightCm,
    this.currentWeightKg,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final bool isOnboardingComplete;
  final String? displayName;
  final String? goal;
  final String? jobActivityLevel;
  final double? heightCm;
  final double? currentWeightKg;

  AppState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isOnboardingComplete,
    String? displayName,
    String? goal,
    String? jobActivityLevel,
    double? heightCm,
    double? currentWeightKg,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboardingComplete: isOnboardingComplete ?? this.isOnboardingComplete,
      displayName: displayName ?? this.displayName,
      goal: goal ?? this.goal,
      jobActivityLevel: jobActivityLevel ?? this.jobActivityLevel,
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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AppState build() {
    if (!AppEnv.hasSupabaseConfig) {
      return AppState.initial;
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
    double? heightCm,
    double? currentWeightKg,
  }) async {
    if (!AppEnv.hasSupabaseConfig) {
      state = state.copyWith(
        displayName: displayName,
        goal: goal,
        jobActivityLevel: jobActivityLevel,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        isOnboardingComplete: true,
      );
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    if (user == null) {
      throw StateError('No hay una sesion activa para guardar el onboarding.');
    }

    setLoading(true);

    try {
      final client = Supabase.instance.client;

      await client.from('profiles').upsert({
        'user_id': user.id,
        'display_name': displayName,
        'goal': goal,
        'job_activity_level': jobActivityLevel,
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
        displayName: displayName,
        goal: goal,
        jobActivityLevel: jobActivityLevel,
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

  Future<void> _syncFromSession(Session? session) async {
    if (!AppEnv.hasSupabaseConfig) {
      state = AppState.initial;
      return;
    }

    final user = session?.user;

    if (user == null) {
      state = AppState.initial;
      return;
    }

    state = state.copyWith(isLoading: true, isAuthenticated: true);

    try {
      final client = Supabase.instance.client;
      final profile = await client
          .from('profiles')
          .select('display_name, goal, job_activity_level, height_cm')
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
        isOnboardingComplete: _isOnboardingComplete(profile),
        displayName: _asString(profile?['display_name']),
        goal: _asString(profile?['goal']),
        jobActivityLevel: _asString(profile?['job_activity_level']),
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

  bool _isOnboardingComplete(Map<String, dynamic>? profile) {
    return _asString(profile?['display_name']) != null &&
        _asString(profile?['goal']) != null &&
        _asString(profile?['job_activity_level']) != null;
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
}
