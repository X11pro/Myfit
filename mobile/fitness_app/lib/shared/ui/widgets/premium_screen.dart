import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 24),
    this.scrollable = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundSecondary,
            AppTheme.background,
          ],
        ),
      ),
      child: SafeArea(
        child: scrollable ? ListView(children: [body]) : body,
      ),
    );
  }
}
