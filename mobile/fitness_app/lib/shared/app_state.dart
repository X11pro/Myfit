import 'package:flutter_riverpod/flutter_riverpod.dart';

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

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
  @override
  AppState build() => AppState.initial;

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }

  void completeOnboarding({
    required String displayName,
    required String goal,
    required String jobActivityLevel,
    double? heightCm,
    double? currentWeightKg,
  }) {
    state = state.copyWith(
      displayName: displayName,
      goal: goal,
      jobActivityLevel: jobActivityLevel,
      heightCm: heightCm,
      currentWeightKg: currentWeightKg,
      isOnboardingComplete: true,
    );
  }

  void reset() {
    state = AppState.initial;
  }
}
