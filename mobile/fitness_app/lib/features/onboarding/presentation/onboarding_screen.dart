import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../../shared/widgets/app_top_bar.dart';

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
    final strings = stringsFor(ref);

    return Scaffold(
      appBar: AppTopBar(
        title: strings.setupProfile,
        strings: strings,
        backPath: '/splash',
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(strings.onboardingTitle,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: strings.nameLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.heightLabel),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: strings.weightLabel),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _goal,
            decoration: InputDecoration(labelText: strings.goalLabel),
            items: [
              DropdownMenuItem(
                  value: 'lose_fat', child: Text(strings.goalLoseFat)),
              DropdownMenuItem(
                  value: 'gain_muscle', child: Text(strings.goalGainMuscle)),
              DropdownMenuItem(
                  value: 'maintain', child: Text(strings.goalMaintain)),
              DropdownMenuItem(
                  value: 'recomp', child: Text(strings.goalRecomp)),
            ],
            onChanged: (value) => setState(() => _goal = value ?? _goal),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _jobActivity,
            decoration: InputDecoration(labelText: strings.workLabel),
            items: [
              DropdownMenuItem(
                  value: 'sedentary', child: Text(strings.jobSedentary)),
              DropdownMenuItem(
                  value: 'standing', child: Text(strings.jobStanding)),
              DropdownMenuItem(value: 'light', child: Text(strings.jobLight)),
              DropdownMenuItem(
                  value: 'moderate', child: Text(strings.jobModerate)),
              DropdownMenuItem(
                  value: 'intense', child: Text(strings.jobIntense)),
            ],
            onChanged: (value) =>
                setState(() => _jobActivity = value ?? _jobActivity),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: appState.isLoading ? null : _save,
              child: Text(strings.saveProfile),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final strings = stringsFor(ref);

    try {
      await ref.read(appStateProvider.notifier).completeOnboarding(
            displayName: _nameController.text.trim().isEmpty
                ? strings.defaultUserName
                : _nameController.text.trim(),
            goal: _goal,
            jobActivityLevel: _jobActivity,
            heightCm: double.tryParse(_heightController.text.trim()),
            currentWeightKg: double.tryParse(_weightController.text.trim()),
          );

      if (!mounted) {
        return;
      }

      context.go('/dashboard');
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.saveOnboardingError}: $error')),
      );
    }
  }
}
