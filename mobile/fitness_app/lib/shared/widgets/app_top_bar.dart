import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app_language.dart';

enum _TopBarMenuAction {
  profile,
  dashboard,
  addMeal,
  addWorkout,
  progress,
  foodGallery,
  sharedCatalog,
  welcome,
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.strings,
  });

  final String title;
  final AppStrings strings;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        tooltip: strings.backButtonTooltip,
        onPressed: () => _handleBack(context),
        icon: const Icon(Icons.arrow_back_outlined),
      ),
      title: Text(title),
      actions: [
        IconButton(
          tooltip: strings.homeButtonTooltip,
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.home_outlined),
        ),
        PopupMenuButton<_TopBarMenuAction>(
          tooltip: strings.menuButtonTooltip,
          icon: const Icon(Icons.menu),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _TopBarMenuAction.dashboard,
              child: Text(strings.dashboardTitle),
            ),
            PopupMenuItem(
              value: _TopBarMenuAction.profile,
              child: Text(strings.setupProfile),
            ),
            PopupMenuItem(
              value: _TopBarMenuAction.addMeal,
              child: Text(strings.addMealTitle),
            ),
            PopupMenuItem(
              value: _TopBarMenuAction.addWorkout,
              child: Text(strings.quickActionWorkout),
            ),
            PopupMenuItem(
              value: _TopBarMenuAction.progress,
              child: Text(strings.progressScreenTitle),
            ),
            PopupMenuItem(
              value: _TopBarMenuAction.foodGallery,
              child: Text(strings.foodGalleryTitle),
            ),
            PopupMenuItem(
              value: _TopBarMenuAction.sharedCatalog,
              child: Text(strings.addSharedFoodTitle),
            ),
            PopupMenuItem(
              value: _TopBarMenuAction.welcome,
              child: Text(strings.welcomeScreenTitle),
            ),
          ],
        ),
      ],
    );
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.of(context);
    final currentLocation = GoRouterState.of(context).matchedLocation;

    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }

    if (currentLocation != '/dashboard') {
      router.go('/dashboard');
      return;
    }

    if (currentLocation != '/splash') {
      router.go('/splash');
    }
  }

  void _handleMenuAction(BuildContext context, _TopBarMenuAction value) {
    switch (value) {
      case _TopBarMenuAction.profile:
        context.go('/auth');
        return;
      case _TopBarMenuAction.dashboard:
        context.go('/dashboard');
        return;
      case _TopBarMenuAction.addMeal:
        context.go('/food/manual');
        return;
      case _TopBarMenuAction.addWorkout:
        context.go('/workout/manual');
        return;
      case _TopBarMenuAction.progress:
        context.go('/dashboard/progress');
        return;
      case _TopBarMenuAction.foodGallery:
        context.go('/food/gallery');
        return;
      case _TopBarMenuAction.sharedCatalog:
        context.go('/food/shared-catalog');
        return;
      case _TopBarMenuAction.welcome:
        context.go('/splash');
        return;
    }
  }
}
