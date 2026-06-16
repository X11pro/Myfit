import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../../shared/app_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final authController = ref.read(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => authController.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Hola, ${state.displayName ?? 'usuario'}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const _MetricCard(
              title: 'Calorias consumidas',
              value: '0 kcal',
              subtitle: 'Pendiente de conectar meals'),
          const SizedBox(height: 12),
          const _MetricCard(
              title: 'Proteina',
              value: '0 g',
              subtitle: 'Objetivo pendiente de perfil'),
          const SizedBox(height: 12),
          const _MetricCard(
              title: 'Balance estimado',
              value: '0 kcal',
              subtitle: 'Sin actividad importada aun'),
          const SizedBox(height: 24),
          Text(
              'Siguiente integracion: meals + daily summary + Health Connect/HealthKit.',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}
