import 'package:fitness_app/app/app.dart';
import 'package:fitness_app/app/router.dart';
import 'package:fitness_app/shared/app_language.dart';
import 'package:fitness_app/shared/app_state.dart';
import 'package:fitness_app/shared/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuditProfile extends AppStateNotifier {
  _AuditProfile(this.complete);
  final bool complete;

  @override
  AppState build() => AppState.initial.copyWith(
        isOnboardingComplete: complete,
        displayName: 'QA',
      );
}

void main() {
  for (final (language, size) in [
    (AppLanguage.en, const Size(390, 844)),
    (AppLanguage.es, const Size(360, 780)),
  ]) {
    testWidgets(
        'app routes and Progress dialogs share the Stitch theme: $language',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final scope = ProviderContainer(overrides: [
        appStateProvider.overrideWith(() => _AuditProfile(true)),
      ]);
      scope.read(appLanguageProvider.notifier).state = language;
      addTearDown(scope.dispose);
      await tester.pumpWidget(
          UncontrolledProviderScope(container: scope, child: const MyfitApp()));
      await tester.pumpAndSettle();
      final router = scope.read(appRouterProvider);

      for (final route in [
        '/splash',
        '/profile',
        '/auth',
        '/auth/verify?email=qa@example.test',
        '/dashboard',
        '/dashboard/progress',
        '/nutrition',
        '/food/manual',
        '/food/shared-catalog',
        '/food/gallery',
        '/workout/manual',
        '/workout/routine',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        final scaffold = find.byType(Scaffold);
        expect(scaffold, findsOneWidget, reason: route);
        final theme = Theme.of(tester.element(scaffold));
        expect(theme.scaffoldBackgroundColor, AppTheme.background,
            reason: route);
        expect(theme.cardTheme.color, AppTheme.surface, reason: route);
        expect(theme.dialogTheme.backgroundColor, AppTheme.surface,
            reason: route);
        for (final card in tester.elementList(find.byType(Card))) {
          final widget = card.widget as Card;
          final color = widget.color ?? Theme.of(card).cardTheme.color;
          expect([AppTheme.surface, AppTheme.surfaceMuted], contains(color),
              reason: route);
        }
        expect(tester.takeException(), isNull, reason: route);
      }

      router.go('/dashboard/progress');
      await tester.pumpAndSettle();
      final en = language == AppLanguage.en;
      final strings = AppStrings(language);
      for (final (trigger, title, close) in [
        (
          en ? 'Log' : 'Registrar',
          strings.logWeightTitle,
          strings.cancelButton
        ),
        (
          en ? 'Export' : 'Exportar',
          en ? 'Export progress (CSV)' : 'Exportar progreso (CSV)',
          en ? 'Close' : 'Cerrar'
        ),
      ]) {
        final button = find.text(trigger);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        final dialog = find.byType(Dialog);
        expect(dialog, findsOneWidget);
        expect(
            find
                .descendant(of: dialog, matching: find.byType(Material))
                .evaluate()
                .map((element) => (element.widget as Material).color),
            contains(AppTheme.surface));
        await tester.tap(find.text(close));
        await tester.pumpAndSettle();
      }
      final details =
          find.text(en ? 'Explore detailed charts' : 'Ver gráficos detallados');
      await tester.ensureVisible(details);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.text(strings.progressScreenTitle), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
