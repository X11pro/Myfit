import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../shared/app_state.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final appState = ref.watch(appStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    ],
    redirect: (_, state) {
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (appState.isLoading) {
        return isSplash ? null : '/splash';
      }

      if (!appState.isAuthenticated) {
        return isLogin ? null : '/login';
      }

      if (!appState.isOnboardingComplete) {
        return isOnboarding ? null : '/onboarding';
      }

      if (isSplash || isLogin || isOnboarding || state.matchedLocation == '/') {
        return '/dashboard';
      }

      return null;
    },
  );
});
