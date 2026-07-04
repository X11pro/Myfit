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
  static const _rpeOptions = <double>[6, 7, 7.5, 8, 8.5, 9, 9.5, 10];
  static const _customExerciseValue = '__custom_exercise__';
  static const _muscleGroupExercises = <String, List<String>>{
    'Chest': ['Bench press', 'Incline dumbbell press', 'Chest fly', 'Dips'],
    'Back': ['Pull up', 'Barbell row', 'Lat pulldown', 'Seated cable row'],
    'Legs': ['Squat', 'Leg press', 'Romanian deadlift', 'Lunge'],
    'Shoulders': [
      'Overhead press',
      'Lateral raise',
      'Rear delt fly',
      'Arnold press',
    ],
    'Arms': [
      'Barbell curl',
      'Hammer curl',
      'Triceps pushdown',
      'Skull crusher'
    ],
    'Core': ['Cable crunch', 'Plank', 'Hanging leg raise', 'Ab wheel'],
    'Glutes': [
      'Hip thrust',
      'Bulgarian split squat',
      'Glute bridge',
      'Kickback'
    ],
    'Full body': ['Deadlift', 'Clean and press', 'Thruster', 'Farmer carry'],
  };

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
    final recentExercises = ref.watch(recentWorkoutExerciseNamesProvider);

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.loggedSetsTitle,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_draftSets.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: _duplicateLastSet,
                              icon: const Icon(Icons.content_copy_outlined),
                              label: Text(strings.repeatLastSetButton),
                            ),
                          FilledButton.tonalIcon(
                            onPressed: () => _openSetDialog(
                              recentExercises: recentExercises,
                            ),
                            icon: const Icon(Icons.fitness_center_outlined),
                            label: Text(strings.addSetButton),
                          ),
                        ],
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
                          onEdit: () => _openSetDialog(
                            index: index,
                            recentExercises: recentExercises,
                          ),
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

  Future<void> _openSetDialog({
    int? index,
    List<String> recentExercises = const [],
  }) async {
    final strings = stringsFor(ref);
    final existingSet = index == null ? null : _draftSets[index];
    final exerciseController = TextEditingController();
    final repsController =
        TextEditingController(text: existingSet?.reps.toString() ?? '');
    final setsController = TextEditingController(text: '1');
    final weightController = TextEditingController(
      text: existingSet == null ? '' : existingSet.weightKg.toString(),
    );
    double? selectedRpe = existingSet?.rpe;
    String? selectedMuscleGroup = existingSet?.muscleGroup;
    var useCustomExercise = false;

    final availableMuscleGroups =
        _buildMuscleGroupOptions(existingSet?.muscleGroup);
    if (selectedMuscleGroup != null &&
        !availableMuscleGroups.contains(selectedMuscleGroup)) {
      selectedMuscleGroup = null;
    }

    var exerciseOptions = _exerciseOptionsFor(
      muscleGroup: selectedMuscleGroup,
      existingExercise: existingSet?.exerciseName,
    );
    String? selectedExercise = existingSet?.exerciseName;
    if (selectedExercise != null &&
        !exerciseOptions.contains(selectedExercise)) {
      useCustomExercise = true;
      exerciseController.text = selectedExercise;
      selectedExercise = _customExerciseValue;
    }

    final result = await showDialog<_SetDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            exerciseOptions = _exerciseOptionsFor(
              muscleGroup: selectedMuscleGroup,
              existingExercise: existingSet?.exerciseName,
            );
            if (selectedExercise != _customExerciseValue &&
                selectedExercise != null &&
                !exerciseOptions.contains(selectedExercise)) {
              selectedExercise = null;
            }

            return AlertDialog(
              title: Text(
                  index == null ? strings.addSetButton : strings.editSetButton),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMuscleGroup,
                      items: availableMuscleGroups
                          .map(
                            (group) => DropdownMenuItem(
                              value: group,
                              child: Text(group),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: strings.muscleGroupLabel,
                        hintText: strings.selectMuscleGroupLabel,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMuscleGroup = value;
                          useCustomExercise = false;
                          selectedExercise = null;
                          exerciseController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedExercise,
                      items: exerciseOptions
                          .map(
                            (exercise) => DropdownMenuItem(
                              value: exercise,
                              child: Text(
                                exercise == _customExerciseValue
                                    ? strings.addCustomExerciseOption
                                    : exercise,
                              ),
                            ),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        labelText: strings.exerciseNameLabel,
                        hintText: strings.selectExerciseLabel,
                      ),
                      onChanged: selectedMuscleGroup == null
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedExercise = value;
                                useCustomExercise =
                                    value == _customExerciseValue;
                                if (!useCustomExercise) {
                                  exerciseController.clear();
                                }
                              });
                            },
                    ),
                    if (useCustomExercise) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: exerciseController,
                        decoration: InputDecoration(
                          labelText: strings.customExerciseLabel,
                        ),
                      ),
                    ],
                    if (index == null && recentExercises.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          strings.recentExercisesTitle,
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentExercises.take(6).map((exercise) {
                          return ActionChip(
                            label: Text(exercise),
                            onPressed: () {
                              setDialogState(() {
                                selectedExercise = _customExerciseValue;
                                useCustomExercise = true;
                                exerciseController.text = exercise;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: setsController,
                            keyboardType: TextInputType.number,
                            enabled: index == null,
                            decoration:
                                InputDecoration(labelText: strings.setsLabel),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            decoration: InputDecoration(
                              labelText: strings.setWeightLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.rpeLabel,
                        style: Theme.of(dialogContext).textTheme.bodyLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.rpeHelpLabel,
                        style: Theme.of(dialogContext).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedRpe != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(dialogContext)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              strings.rpeValueLabel(selectedRpe!),
                              style: Theme.of(dialogContext)
                                  .textTheme
                                  .headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(strings.rpeEffortTitle(selectedRpe!)),
                            const SizedBox(height: 4),
                            Text(
                              strings.rpeReserveHint(selectedRpe!),
                              textAlign: TextAlign.center,
                              style:
                                  Theme.of(dialogContext).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(strings.noRpeLabel),
                          selected: selectedRpe == null,
                          onSelected: (_) {
                            setDialogState(() => selectedRpe = null);
                          },
                        ),
                        ..._rpeOptions.map((value) {
                          return ChoiceChip(
                            label: Text(strings.rpeValueLabel(value)),
                            selected: selectedRpe == value,
                            onSelected: (_) {
                              setDialogState(() => selectedRpe = value);
                            },
                          );
                        }),
                      ],
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
                    final exercise = useCustomExercise
                        ? exerciseController.text.trim()
                        : (selectedExercise ?? '').trim();
                    final muscleGroup = (selectedMuscleGroup ?? '').trim();
                    final setsCount =
                        int.tryParse(setsController.text.trim()) ?? 1;
                    final reps = int.tryParse(repsController.text.trim());
                    final weight = double.tryParse(
                      weightController.text.trim().replaceAll(',', '.'),
                    );

                    if (muscleGroup.isEmpty ||
                        exercise.isEmpty ||
                        reps == null ||
                        weight == null ||
                        setsCount < 1) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _SetDialogResult(
                        set: GymSetEntry(
                          exerciseName: exercise,
                          muscleGroup: muscleGroup,
                          setNumber:
                              index == null ? _draftSets.length + 1 : index + 1,
                          reps: reps,
                          weightKg: weight,
                          rpe: selectedRpe,
                        ),
                        setsCount: index == null ? setsCount : 1,
                      ),
                    );
                  },
                  child: Text(index == null
                      ? strings.addButton
                      : strings.updateSetButton),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      if (index == null) {
        for (var i = 0; i < result.setsCount; i++) {
          _draftSets.add(
            GymSetEntry(
              exerciseName: result.set.exerciseName,
              muscleGroup: result.set.muscleGroup,
              setNumber: _draftSets.length + 1,
              reps: result.set.reps,
              weightKg: result.set.weightKg,
              rpe: result.set.rpe,
            ),
          );
        }
      } else {
        _draftSets[index] = result.set;
      }
      _reindexSets();
    });
  }

  List<String> _buildMuscleGroupOptions(String? existingMuscleGroup) {
    final groups = _muscleGroupExercises.keys.toList();
    if (existingMuscleGroup != null &&
        existingMuscleGroup.isNotEmpty &&
        !groups.contains(existingMuscleGroup)) {
      groups.add(existingMuscleGroup);
    }
    return groups;
  }

  List<String> _exerciseOptionsFor({
    required String? muscleGroup,
    String? existingExercise,
  }) {
    final options = <String>[
      ...?_muscleGroupExercises[muscleGroup],
    ];

    if (existingExercise != null &&
        existingExercise.isNotEmpty &&
        !options.contains(existingExercise)) {
      options.add(existingExercise);
    }

    options.add(_customExerciseValue);
    return options;
  }

  void _removeSet(int index) {
    setState(() {
      _draftSets.removeAt(index);
      _reindexSets();
    });
  }

  void _duplicateLastSet() {
    final strings = stringsFor(ref);
    if (_draftSets.isEmpty) {
      return;
    }

    final lastSet = _draftSets.last;
    setState(() {
      _draftSets.add(
        GymSetEntry(
          exerciseName: lastSet.exerciseName,
          muscleGroup: lastSet.muscleGroup,
          setNumber: _draftSets.length + 1,
          reps: lastSet.reps,
          weightKg: lastSet.weightKg,
          rpe: lastSet.rpe,
        ),
      );
      _reindexSets();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(strings.repeatLastSetMessage(lastSet.exerciseName))),
    );
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

class _SetDialogResult {
  const _SetDialogResult({
    required this.set,
    required this.setsCount,
  });

  final GymSetEntry set;
  final int setsCount;
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
