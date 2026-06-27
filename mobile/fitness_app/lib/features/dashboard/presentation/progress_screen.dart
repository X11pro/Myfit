import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_language.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/daily_targets_calculator.dart';
import '../domain/daily_targets.dart';
import 'widgets/progress_chart_widgets.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  ProgressMode _mode = ProgressMode.strength;

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref);
    final points = switch (_mode) {
      ProgressMode.strength => ref.watch(progressStrengthProvider),
      ProgressMode.bodyWeight => ref.watch(progressBodyWeightProvider),
      ProgressMode.calories => ref.watch(progressCaloriesProvider),
      ProgressMode.combined => ref.watch(progressCombinedProvider),
    };
    final exerciseOptions = ref.watch(strengthExerciseOptionsProvider);
    final selectedExercise = ref.watch(strengthExerciseFilterProvider);

    return Scaffold(
      appBar: AppTopBar(title: strings.progressScreenTitle, strings: strings),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(strings.progressScreenSubtitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModeChip(
                label: strings.progressStrength,
                selected: _mode == ProgressMode.strength,
                onTap: () => setState(() => _mode = ProgressMode.strength),
              ),
              _ModeChip(
                label: strings.progressBodyWeight,
                selected: _mode == ProgressMode.bodyWeight,
                onTap: () => setState(() => _mode = ProgressMode.bodyWeight),
              ),
              _ModeChip(
                label: strings.progressCaloriesBurned,
                selected: _mode == ProgressMode.calories,
                onTap: () => setState(() => _mode = ProgressMode.calories),
              ),
              _ModeChip(
                label: strings.progressCombined,
                selected: _mode == ProgressMode.combined,
                onTap: () => setState(() => _mode = ProgressMode.combined),
              ),
            ],
          ),
          if (_mode == ProgressMode.strength) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: selectedExercise,
              decoration:
                  InputDecoration(labelText: strings.exerciseFilterLabel),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(strings.allExercisesOption),
                ),
                ...exerciseOptions.map(
                  (exercise) => DropdownMenuItem<String?>(
                    value: exercise,
                    child: Text(exercise),
                  ),
                ),
              ],
              onChanged: (value) => ref
                  .read(strengthExerciseFilterProvider.notifier)
                  .state = value,
            ),
            if (selectedExercise != null) ...[
              const SizedBox(height: 12),
              Text(
                strings.filteredExerciseLabel(selectedExercise),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.progressDiagramTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(strings.workoutProgressHint),
                  const SizedBox(height: 16),
                  if (points.isEmpty)
                    Text(strings.noProgressDataYet)
                  else ...[
                    if (_mode == ProgressMode.bodyWeight)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(strings.bodyWeightTrendDown),
                      ),
                    ProgressLineAreaChart(points: points, height: 240),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProgressSummaryCard(points: points, strings: strings, mode: _mode),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.points,
    required this.strings,
    required this.mode,
  });

  final List<ProgressPoint> points;
  final AppStrings strings;
  final ProgressMode mode;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }

    final first = points.first.value;
    final last = points.last.value;
    final delta = last - first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.progressDeltaTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              delta >= 0
                  ? '+${delta.toStringAsFixed(1)}'
                  : delta.toStringAsFixed(1),
            ),
            const SizedBox(height: 8),
            Text(_summaryText(delta)),
          ],
        ),
      ),
    );
  }

  String _summaryText(double delta) {
    if (mode == ProgressMode.bodyWeight) {
      return strings.bodyWeightDeltaMessage(delta);
    }

    return strings.trendDirectionMessage(delta);
  }
}
