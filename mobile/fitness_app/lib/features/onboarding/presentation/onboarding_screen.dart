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
  String _activityLevel = 'low';
  String? _sex;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();

    final state = ref.read(appStateProvider);
    _nameController.text = state.displayName ?? '';
    _heightController.text = state.heightCm?.toString() ?? '';
    _weightController.text = state.currentWeightKg?.toString() ?? '';
    _goal = state.goal ?? _goal;
    _activityLevel = state.activityLevel ?? _activityLevel;
    _sex = state.sex;
    _dateOfBirth = state.dateOfBirth;
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
          Text(strings.energyProfileTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(strings.energyProfileHint),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickDateOfBirth,
            icon: const Icon(Icons.cake_outlined),
            label: Text(
              _dateOfBirth == null
                  ? strings.selectBirthDate
                  : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _sex,
            decoration: InputDecoration(labelText: strings.sexLabel),
            items: [
              DropdownMenuItem(
                  value: null, child: Text(strings.sexUnspecified)),
              DropdownMenuItem(value: 'female', child: Text(strings.sexFemale)),
              DropdownMenuItem(value: 'male', child: Text(strings.sexMale)),
            ],
            onChanged: (value) => setState(() => _sex = value),
          ),
          const SizedBox(height: 16),
          Text(strings.dailyActivityLabel,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'low', label: Text(strings.activityLow)),
              ButtonSegment(
                  value: 'medium', label: Text(strings.activityMedium)),
              ButtonSegment(
                value: 'medium_high',
                label: Text(strings.activityMediumHigh),
              ),
              ButtonSegment(value: 'high', label: Text(strings.activityHigh)),
            ],
            selected: {_activityLevel},
            onSelectionChanged: (value) =>
                setState(() => _activityLevel = value.first),
          ),
          const SizedBox(height: 8),
          Text(_activityHint(strings),
              style: Theme.of(context).textTheme.bodySmall),
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
    final heightCm = double.tryParse(_heightController.text.trim());
    final currentWeightKg = double.tryParse(_weightController.text.trim());

    if (heightCm == null ||
        heightCm <= 0 ||
        currentWeightKg == null ||
        currentWeightKg <= 0 ||
        _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.energyProfileRequiredMessage)),
      );
      return;
    }

    try {
      await ref.read(appStateProvider.notifier).completeOnboarding(
            displayName: _nameController.text.trim().isEmpty
                ? strings.defaultUserName
                : _nameController.text.trim(),
            goal: _goal,
            jobActivityLevel: _jobActivityForDailyActivity(_activityLevel),
            activityLevel: _activityLevel,
            sex: _sex,
            dateOfBirth: _dateOfBirth,
            heightCm: heightCm,
            currentWeightKg: currentWeightKg,
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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  String _activityHint(AppStrings strings) {
    switch (_activityLevel) {
      case 'medium':
        return strings.activityMediumHint;
      case 'medium_high':
        return strings.activityMediumHighHint;
      case 'high':
        return strings.activityHighHint;
      case 'low':
      default:
        return strings.activityLowHint;
    }
  }

  String _jobActivityForDailyActivity(String activityLevel) {
    switch (activityLevel) {
      case 'medium':
        return 'standing';
      case 'medium_high':
        return 'moderate';
      case 'high':
        return 'intense';
      case 'low':
      default:
        return 'sedentary';
    }
  }
}
