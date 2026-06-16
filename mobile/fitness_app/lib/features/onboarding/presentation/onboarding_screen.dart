import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_state.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _goal = 'lose_fat';
  String _jobActivity = 'sedentary';

  @override
  void initState() {
    super.initState();

    final state = ref.read(appStateProvider);
    _nameController.text = state.displayName ?? '';
    _heightController.text = state.heightCm?.toString() ?? '';
    _weightController.text = state.currentWeightKg?.toString() ?? '';
    _goal = state.goal ?? _goal;
    _jobActivity = state.jobActivityLevel ?? _jobActivity;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Configura tu punto de partida',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Altura (cm)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Peso actual (kg)'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _goal,
            decoration: const InputDecoration(labelText: 'Objetivo'),
            items: const [
              DropdownMenuItem(value: 'lose_fat', child: Text('Perder grasa')),
              DropdownMenuItem(
                  value: 'gain_muscle', child: Text('Ganar musculo')),
              DropdownMenuItem(value: 'maintain', child: Text('Mantener peso')),
              DropdownMenuItem(value: 'recomp', child: Text('Recomposicion')),
            ],
            onChanged: (value) => setState(() => _goal = value ?? _goal),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _jobActivity,
            decoration: const InputDecoration(labelText: 'Trabajo'),
            items: const [
              DropdownMenuItem(value: 'sedentary', child: Text('Sedentario')),
              DropdownMenuItem(value: 'standing', child: Text('De pie')),
              DropdownMenuItem(value: 'light', child: Text('Fisico ligero')),
              DropdownMenuItem(
                  value: 'moderate', child: Text('Fisico moderado')),
              DropdownMenuItem(value: 'intense', child: Text('Fisico intenso')),
            ],
            onChanged: (value) =>
                setState(() => _jobActivity = value ?? _jobActivity),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: appState.isLoading ? null : _save,
              child: const Text('Guardar perfil inicial'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      await ref.read(appStateProvider.notifier).completeOnboarding(
            displayName: _nameController.text.trim().isEmpty
                ? 'Usuario'
                : _nameController.text.trim(),
            goal: _goal,
            jobActivityLevel: _jobActivity,
            heightCm: double.tryParse(_heightController.text.trim()),
            currentWeightKg: double.tryParse(_weightController.text.trim()),
          );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el onboarding: $error')),
      );
    }
  }
}
