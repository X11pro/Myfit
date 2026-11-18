import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import '../shared/app_language.dart';
import '../shared/ui/theme/app_theme.dart';

class MyfitApp extends ConsumerWidget {
  const MyfitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final language = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'Myfit',
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: language == AppLanguage.en
          ? const Locale('en', 'GB')
          : const Locale('es', 'ES'),
      supportedLocales: const [Locale('en', 'GB'), Locale('es', 'ES')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
    );
  }
}
