import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../../shared/ui/widgets/premium_card.dart';
import '../../../shared/ui/widgets/premium_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = stringsFor(ref);
    final appState = ref.watch(appStateProvider);
    final language = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showAuthButton =
        AppEnv.hasSupabaseConfig && !appState.isAuthenticated;

    return Scaffold(
      body: PremiumScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _BrandLockup(colors: colors),
                const Spacer(),
                SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(
                      value: AppLanguage.en,
                      label: Text('EN'),
                    ),
                    ButtonSegment(
                      value: AppLanguage.es,
                      label: Text('ESP'),
                    ),
                  ],
                  selected: {language},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelectionChanged: (selection) {
                    ref.read(appLanguageProvider.notifier).state =
                        selection.first;
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            _HeroCard(
              title: 'Myfit',
              subtitle: strings.welcomeTagline,
              supportingText: appState.isAuthenticated
                  ? strings.signedInDescription(appState.authEmail)
                  : strings.welcomeDescription,
              isAuthenticated: appState.isAuthenticated,
            ),
            const SizedBox(height: 20),
            const _FeatureRow(),
            const SizedBox(height: 32),
            if (showAuthButton) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/auth'),
                  icon: const Icon(Icons.alternate_email_outlined),
                  label: Text(strings.signInWithEmailButton),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go(
                  appState.isOnboardingComplete ? '/dashboard' : '/onboarding',
                ),
                child: Text(
                  appState.isAuthenticated
                      ? strings.openProfileOrDashboardButton
                      : (appState.isOnboardingComplete
                          ? strings.continueGuest
                          : strings.setupProfile),
                ),
              ),
            ),
            if (!appState.isAuthenticated &&
                !appState.isOnboardingComplete) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: Text(strings.continueGuest),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Icon(
            Icons.insights_outlined,
            color: colors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Myfit',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.supportingText,
    required this.isAuthenticated,
  });

  final String title;
  final String subtitle;
  final String supportingText;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAuthenticated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: colors.primary.withValues(alpha: 0.16),
              ),
              child: Text(
                'Signed in',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          if (isAuthenticated) const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            supportingText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _FeatureCard(
            icon: Icons.restaurant_menu_outlined,
            title: 'Food',
            subtitle: 'Track meals, barcode, and AI photo analysis.',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _FeatureCard(
            icon: Icons.fitness_center_outlined,
            title: 'Training',
            subtitle: 'Log workouts, sets, timers, and daily progress.',
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 20),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}
