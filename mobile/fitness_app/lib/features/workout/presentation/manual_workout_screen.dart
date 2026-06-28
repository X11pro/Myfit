import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/app_language.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../dashboard/application/daily_targets_calculator.dart';
import '../../dashboard/domain/daily_targets.dart';
import '../application/manual_workout_controller.dart';
import '../domain/gym_set_entry.dart';
import '../domain/manual_workout_session.dart';

class ManualWorkoutScreen extends ConsumerStatefulWidget {
  const ManualWorkoutScreen({super.key, this.session});

  final ManualWorkoutSession? session;

  @override
  ConsumerState<ManualWorkoutScreen> createState() =>
      _ManualWorkoutScreenState();
}

class _ManualWorkoutScreenState extends ConsumerState<ManualWorkoutScreen> {
  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final List<GymSetEntry> _draftSets = [];

  bool get _isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();

    final session = widget.session;
    if (session == null) {
      _titleController.text =
          AppStrings(ref.read(appLanguageProvider)).defaultWorkoutTitle;
      return;
    }

    _titleController.text = session.title;
    _durationController.text = session.durationMinutes.toString();
    _caloriesController.text = session.estimatedActiveCalories.toString();
    _notesController.text = session.notes ?? '';
    _selectedDate = session.createdAt;
    _draftSets.addAll(session.sets);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref);
    final sessions = ref.watch(manualWorkoutSessionsProvider);
    final recommendation = ref.watch(workoutRecommendationProvider);

    return Scaffold(
      appBar: AppTopBar(
        title: _isEditing ? strings.editWorkoutTitle : strings.gymTitle,
        strings: strings,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.gymSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (recommendation != null) ...[
            _RoutineRecommendationCard(recommendation: recommendation),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? strings.editWorkoutTitle
                        : strings.logWorkoutTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration:
                        InputDecoration(labelText: strings.workoutNameLabel),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${strings.workoutDateLabel}: ${dateKeyFor(_selectedDate)}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.durationMinutesLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: strings.workoutCaloriesLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: strings.notesLabel),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(strings.loggedSetsTitle,
                          style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () => _openSetDialog(),
                        icon: const Icon(Icons.fitness_center_outlined),
                        label: Text(strings.addSetButton),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_draftSets.isEmpty)
                    Text(strings.noSetsAddedYet)
                  else
                    ...List.generate(
                      _draftSets.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DraftSetTile(
                          set: _draftSets[index],
                          onEdit: () => _openSetDialog(index: index),
                          onRemove: () => _removeSet(index),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saveWorkout,
                      child: Text(
                        _isEditing
                            ? strings.updateWorkoutButton
                            : strings.saveWorkoutButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.workoutHistoryTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(strings.noWorkoutsYet),
              ),
            )
          else
            ...sessions.take(10).map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _WorkoutHistoryCard(session: session),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _openSetDialog({int? index}) async {
    final strings = stringsFor(ref);
    final existingSet = index == null ? null : _draftSets[index];
    final exerciseController =
        TextEditingController(text: existingSet?.exerciseName ?? '');
    final muscleController =
        TextEditingController(text: existingSet?.muscleGroup ?? '');
    final repsController =
        TextEditingController(text: existingSet?.reps.toString() ?? '');
    final weightController = TextEditingController(
      text: existingSet == null ? '' : existingSet.weightKg.toString(),
    );
    final rpeController = TextEditingController(
      text: existingSet?.rpe?.toString() ?? '',
    );

    final set = await showDialog<GymSetEntry>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
              index == null ? strings.addSetButton : strings.editSetButton),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: exerciseController,
                  decoration:
                      InputDecoration(labelText: strings.exerciseNameLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: muscleController,
                  decoration:
                      InputDecoration(labelText: strings.muscleGroupLabel),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: strings.repsLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            InputDecoration(labelText: strings.setWeightLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rpeController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: strings.rpeLabel),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final exercise = exerciseController.text.trim();
                final reps = int.tryParse(repsController.text.trim());
                final weight = double.tryParse(
                  weightController.text.trim().replaceAll(',', '.'),
                );

                if (exercise.isEmpty || reps == null || weight == null) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  GymSetEntry(
                    exerciseName: exercise,
                    muscleGroup: muscleController.text.trim(),
                    setNumber:
                        index == null ? _draftSets.length + 1 : index + 1,
                    reps: reps,
                    weightKg: weight,
                    rpe: double.tryParse(
                      rpeController.text.trim().replaceAll(',', '.'),
                    ),
                  ),
                );
              },
              child: Text(
                  index == null ? strings.addButton : strings.updateSetButton),
            ),
          ],
        );
      },
    );

    if (set == null) {
      return;
    }

    setState(() {
      if (index == null) {
        _draftSets.add(set);
      } else {
        _draftSets[index] = set;
      }
      _reindexSets();
    });
  }

  void _removeSet(int index) {
    setState(() {
      _draftSets.removeAt(index);
      _reindexSets();
    });
  }

  void _reindexSets() {
    final reindexed = <GymSetEntry>[];
    for (var index = 0; index < _draftSets.length; index++) {
      final set = _draftSets[index];
      reindexed.add(
        GymSetEntry(
          exerciseName: set.exerciseName,
          muscleGroup: set.muscleGroup,
          setNumber: index + 1,
          reps: set.reps,
          weightKg: set.weightKg,
          rpe: set.rpe,
        ),
      );
    }
    _draftSets
      ..clear()
      ..addAll(reindexed);
  }

  Future<void> _saveWorkout() async {
    final strings = stringsFor(ref);
    final title = _titleController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final calories = int.tryParse(_caloriesController.text.trim()) ?? 0;

    if (title.isEmpty || _draftSets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.invalidWorkoutMessage)),
      );
      return;
    }

    final notifier = ref.read(manualWorkoutSessionsProvider.notifier);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (_isEditing) {
      await notifier.updateSession(
        id: widget.session!.id,
        title: title,
        date: _selectedDate,
        durationMinutes: duration,
        estimatedActiveCalories: calories,
        sets: List<GymSetEntry>.from(_draftSets),
        notes: notes,
      );
    } else {
      await notifier.addSession(
        title: title,
        date: _selectedDate,
        durationMinutes: duration,
        estimatedActiveCalories: calories,
        sets: List<GymSetEntry>.from(_draftSets),
        notes: notes,
      );
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? strings.workoutUpdatedMessage
              : strings.workoutSavedMessage,
        ),
      ),
    );
    context.go('/dashboard');
  }
}

class _RoutineRecommendationCard extends StatelessWidget {
  const _RoutineRecommendationCard({required this.recommendation});

  final GoalRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.routineName,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(recommendation.headline),
            const SizedBox(height: 12),
            ...recommendation.exercises.map<Widget>(
              (exercise) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $exercise'),
              ),
            ),
            const SizedBox(height: 12),
            Text(recommendation.nutritionFocus),
          ],
        ),
      ),
    );
  }
}

class _DraftSetTile extends ConsumerWidget {
  const _DraftSetTile({
    required this.set,
    required this.onEdit,
    required this.onRemove,
  });

  final GymSetEntry set;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = stringsFor(ref);

    return Card(
      child: ListTile(
        title: Text('${set.exerciseName} • ${set.weightKg} kg'),
        subtitle: Text(
          strings.draftSetSubtitle(
            reps: set.reps,
            setNumber: set.setNumber,
            muscleGroup: set.muscleGroup,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutHistoryCard extends ConsumerWidget {
  const _WorkoutHistoryCard({required this.session});

  final ManualWorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = stringsFor(ref);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(strings.workoutDateSetsSummary(
                        session.dateKey,
                        session.totalSets,
                        session.totalReps,
                      )),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${session.estimatedActiveCalories} kcal'),
                    const SizedBox(height: 4),
                    Text(strings.maxWeightLabel(session.heaviestWeightKg)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...session.sets.take(4).map(
                  (set) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      strings.exerciseWeightRepsLabel(
                        exerciseName: set.exerciseName,
                        weightKg: set.weightKg,
                        reps: set.reps,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        context.push('/workout/manual', extra: session),
                    child: Text(strings.editWorkoutButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(manualWorkoutSessionsProvider.notifier)
                          .deleteSession(session.id);

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.workoutDeletedMessage)),
                      );
                    },
                    child: Text(strings.deleteWorkoutButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
