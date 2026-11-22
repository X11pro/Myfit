import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_language.dart';

class MyfitBottomNav extends StatelessWidget {
  const MyfitBottomNav({super.key, required this.strings, required this.index});
  final int index;

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (index) {
        if (index == this.index) return;
        switch (index) {
          case 0:
            context.go('/dashboard');
            break;
          case 1:
            context.go('/workout/manual');
            break;
          case 2:
            context.go('/nutrition');
            break;
          case 3:
            context.push('/dashboard/progress');
            break;
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: strings.isEnglish ? 'Home' : 'Inicio',
        ),
        NavigationDestination(
          icon: const Icon(Icons.fitness_center_outlined),
          selectedIcon: const Icon(Icons.fitness_center),
          label: strings.isEnglish ? 'Workout' : 'Entreno',
        ),
        NavigationDestination(
          icon: const Icon(Icons.restaurant_outlined),
          selectedIcon: const Icon(Icons.restaurant),
          label: strings.nutritionTabLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.show_chart_outlined),
          selectedIcon: const Icon(Icons.show_chart),
          label: strings.progressScreenTitle,
        ),
      ],
    );
  }
}
