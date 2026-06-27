import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/progress_screen.dart';
import '../features/food/domain/manual_food_entry.dart';
import '../features/food/presentation/manual_food_entry_screen.dart';
import '../features/food/presentation/shared_food_catalog_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/workout/domain/manual_workout_session.dart';
import '../features/workout/presentation/manual_workout_screen.dart';
import '../shared/app_state.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final appState = ref.watch(appStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen()),
      GoRoute(
          path: '/dashboard/progress',
          builder: (context, state) => const ProgressScreen()),
      GoRoute(
        path: '/food/manual',
        builder: (context, state) => ManualFoodEntryScreen(
          entry: state.extra is ManualFoodEntry
              ? state.extra as ManualFoodEntry
              : null,
        ),
      ),
      GoRoute(
          path: '/food/shared-catalog',
          builder: (context, state) => const SharedFoodCatalogScreen()),
      GoRoute(
        path: '/workout/manual',
        builder: (context, state) => ManualWorkoutScreen(
          session: state.extra is ManualWorkoutSession
              ? state.extra as ManualWorkoutSession
              : null,
        ),
      ),
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    ],
    redirect: (_, state) {
      if (state.matchedLocation == '/') {
        return '/splash';
      }

      if (state.matchedLocation == '/dashboard' &&
          !appState.isOnboardingComplete) {
        return '/onboarding';
      }

      return null;
    },
  );
});
