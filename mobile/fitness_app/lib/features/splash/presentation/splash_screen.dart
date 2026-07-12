import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../../shared/widgets/app_top_bar.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = stringsFor(ref);
    final appState = ref.watch(appStateProvider);
    final language = ref.watch(appLanguageProvider);
    final showAuthButton =
        AppEnv.hasSupabaseConfig && !appState.isAuthenticated;

    return Scaffold(
      appBar: AppTopBar(title: strings.welcomeScreenTitle, strings: strings),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(value: AppLanguage.en, label: Text('EN')),
                    ButtonSegment(value: AppLanguage.es, label: Text('ESP')),
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
              ),
              const Spacer(),
              Text('Myfit', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 12),
              Text(
                strings.welcomeTagline,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                appState.isAuthenticated
                    ? strings.signedInDescription(appState.authEmail)
                    : strings.welcomeDescription,
              ),
              const Spacer(),
              if (showAuthButton) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/auth'),
                    child: Text(strings.signInWithEmailButton),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(
                    appState.isOnboardingComplete
                        ? '/dashboard'
                        : '/onboarding',
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
                  child: OutlinedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: Text(strings.continueGuest),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
