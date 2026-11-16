import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 28),
    this.scrollable = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: SafeArea(
        top: false,
        child: scrollable ? ListView(children: [body]) : body,
      ),
    );
  }
}
