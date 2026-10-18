import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_language.dart';
import '../../../shared/ui/widgets/premium_card.dart';
import '../../../shared/ui/widgets/premium_screen.dart';
import '../../../shared/ui/widgets/section_header.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/weekly_workout_routine_controller.dart';
import '../domain/weekly_workout_routine.dart';
import '../domain/workout_exercise_catalog.dart';

class WeeklyWorkoutRoutineScreen extends ConsumerWidget {
  const WeeklyWorkoutRoutineScreen({super.key});

  static const _customExerciseValue = '__custom_exercise__';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = stringsFor(ref);
    final library = ref.watch(weeklyWorkoutRoutineProvider);
    final routine = library.activeRoutine;

    return Scaffold(
      appBar: AppTopBar(title: strings.weeklyRoutineTitle, strings: strings),
      body: PremiumScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: strings.weeklyRoutineTitle,
              subtitle: strings.weeklyRoutineSubtitle,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _createRoutine(context, ref, strings),
              icon: const Icon(Icons.add),
              label: Text(strings.newRoutineButton),
            ),
            const SizedBox(height: 12),
            if (routine == null)
              Text(strings.noSavedRoutines)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: routine.id,
                      decoration: InputDecoration(
                        labelText: strings.routineNameLabel,
                      ),
                      items: library.routines
                          .map(
                            (savedRoutine) => DropdownMenuItem(
                              value: savedRoutine.id,
                              child: Text(savedRoutine.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(weeklyWorkoutRoutineProvider.notifier)
                              .selectRoutine(value);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: strings.renameRoutineButton,
                    onPressed: () =>
                        _renameRoutine(context, ref, routine, strings),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: strings.deleteRoutineButton,
                    onPressed: () => ref
                        .read(weeklyWorkoutRoutineProvider.notifier)
                        .deleteRoutine(routine.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RoutineDayCard(
                    weekday: weekday,
                    blocks: routine.blocksByWeekday[weekday] ?? const [],
                    strings: strings,
                    onAddBlock: (type) => _addBlock(
                      context,
                      ref,
                      routine.id,
                      weekday,
                      routine.blocksByWeekday[weekday] ?? const [],
                      type,
                      strings,
                    ),
                    onRemoveBlock: (index) => _removeBlock(
                      ref,
                      routine.id,
                      weekday,
                      routine.blocksByWeekday[weekday] ?? const [],
                      index,
                    ),
                    onEditBlock: (index) => _editBlock(
                      context,
                      ref,
                      routine.id,
                      weekday,
                      routine.blocksByWeekday[weekday] ?? const [],
                      index,
                      strings,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addBlock(
    BuildContext context,
    WidgetRef ref,
    String routineId,
    int weekday,
    List<WorkoutRoutineBlock> blocks,
    WorkoutRoutineBlockType type,
    AppStrings strings,
  ) async {
    final block = await _showBlockDialog(context, type, strings);
    if (block == null) {
      return;
    }
    await ref
        .read(weeklyWorkoutRoutineProvider.notifier)
        .setDayBlocks(routineId, weekday, [...blocks, block]);
  }

  Future<void> _removeBlock(
    WidgetRef ref,
    String routineId,
    int weekday,
    List<WorkoutRoutineBlock> blocks,
    int index,
  ) {
    final updated = List<WorkoutRoutineBlock>.from(blocks)..removeAt(index);
    return ref
        .read(weeklyWorkoutRoutineProvider.notifier)
        .setDayBlocks(routineId, weekday, updated);
  }

  Future<void> _editBlock(
    BuildContext context,
    WidgetRef ref,
    String routineId,
    int weekday,
    List<WorkoutRoutineBlock> blocks,
    int index,
    AppStrings strings,
  ) async {
    final existingBlock = blocks[index];
    final updatedBlock = await _showBlockDialog(
      context,
      existingBlock.type,
      strings,
      initialBlock: existingBlock,
    );
    if (updatedBlock == null) {
      return;
    }
    final updatedBlocks = List<WorkoutRoutineBlock>.from(blocks)
      ..[index] = updatedBlock;
    await ref
        .read(weeklyWorkoutRoutineProvider.notifier)
        .setDayBlocks(routineId, weekday, updatedBlocks);
  }

  Future<void> _createRoutine(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final name = await _showRoutineNameDialog(context, strings);
    if (name == null) {
      return;
    }
    await ref.read(weeklyWorkoutRoutineProvider.notifier).createRoutine(name);
  }

  Future<void> _renameRoutine(
    BuildContext context,
    WidgetRef ref,
    WeeklyWorkoutRoutine routine,
    AppStrings strings,
  ) async {
    final name = await _showRoutineNameDialog(
      context,
      strings,
      initialName: routine.name,
    );
    if (name == null) {
      return;
    }
    await ref
        .read(weeklyWorkoutRoutineProvider.notifier)
        .renameRoutine(routine.id, name);
  }

  Future<String?> _showRoutineNameDialog(
    BuildContext context,
    AppStrings strings, {
    String initialName = '',
  }) async {
    final controller = TextEditingController(text: initialName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.routineNameLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: strings.routineNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.cancelButton),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.of(dialogContext).pop(name);
              }
            },
            child: Text(strings.addButton),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.dispose();
    return result;
  }

  Future<WorkoutRoutineBlock?> _showBlockDialog(
      BuildContext context, WorkoutRoutineBlockType type, AppStrings strings,
      {WorkoutRoutineBlock? initialBlock}) async {
    final drafts = List.generate(
      type.exerciseCount,
      (index) => _RoutineExerciseDraft(
        initialBlock == null || index >= initialBlock.exercises.length
            ? null
            : initialBlock.exercises[index],
      ),
    );

    final result = await showDialog<WorkoutRoutineBlock>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(_blockLabel(type, strings)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < drafts.length; index++) ...[
                  if (index > 0) const Divider(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.routineExerciseLabel(index),
                      style: Theme.of(dialogContext).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: drafts[index].muscleGroup,
                    decoration: InputDecoration(
                      labelText: strings.muscleGroupLabel,
                    ),
                    items: workoutMuscleGroups
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(group),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        drafts[index].muscleGroup = value;
                        drafts[index].selectedExercise = null;
                        drafts[index].isCustomExercise = false;
                        drafts[index].customExerciseController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: drafts[index].selectedExercise,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: strings.exerciseNameLabel,
                    ),
                    items: [
                      if (drafts[index].muscleGroup != null)
                        ...exercisesForMuscleGroup(drafts[index].muscleGroup!),
                      _customExerciseValue,
                    ]
                        .map(
                          (exercise) => DropdownMenuItem(
                            value: exercise,
                            child: Text(
                              exercise == _customExerciseValue
                                  ? strings.addCustomExerciseOption
                                  : exercise,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: drafts[index].muscleGroup == null
                        ? null
                        : (value) => setDialogState(() {
                              drafts[index].selectedExercise = value;
                              drafts[index].isCustomExercise =
                                  value == _customExerciseValue;
                              if (!drafts[index].isCustomExercise) {
                                drafts[index].customExerciseController.clear();
                              }
                            }),
                  ),
                  if (drafts[index].isCustomExercise) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: drafts[index].customExerciseController,
                      decoration: InputDecoration(
                        labelText: strings.customExerciseLabel,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: drafts[index].setsController,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: strings.setsLabel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: drafts[index].repsController,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: strings.repsLabel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: drafts[index].weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration:
                        InputDecoration(labelText: strings.setWeightLabel),
                  ),
                ],
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
                final exercises = <WorkoutRoutineExercise>[];
                for (final draft in drafts) {
                  final exerciseName = draft.isCustomExercise
                      ? draft.customExerciseController.text.trim()
                      : (draft.selectedExercise ?? '').trim();
                  final sets = int.tryParse(draft.setsController.text.trim());
                  final reps = int.tryParse(draft.repsController.text.trim());
                  final weight = double.tryParse(
                    draft.weightController.text.trim().replaceAll(',', '.'),
                  );
                  if (draft.muscleGroup == null ||
                      exerciseName.isEmpty ||
                      sets == null ||
                      reps == null ||
                      weight == null ||
                      sets < 1 ||
                      reps < 1) {
                    return;
                  }
                  exercises.add(
                    WorkoutRoutineExercise(
                      exerciseName: exerciseName,
                      muscleGroup: draft.muscleGroup!,
                      sets: sets,
                      reps: reps,
                      weightKg: weight,
                    ),
                  );
                }
                Navigator.of(dialogContext).pop(
                  WorkoutRoutineBlock(type: type, exercises: exercises),
                );
              },
              child: Text(strings.addButton),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final draft in drafts) {
      draft.dispose();
    }
    return result;
  }

  String _blockLabel(WorkoutRoutineBlockType type, AppStrings strings) {
    return switch (type) {
      WorkoutRoutineBlockType.normal => strings.normalBlockLabel,
      WorkoutRoutineBlockType.superset => strings.supersetBlockLabel,
      WorkoutRoutineBlockType.triset => strings.trisetBlockLabel,
    };
  }
}

class _RoutineDayCard extends StatelessWidget {
  const _RoutineDayCard({
    required this.weekday,
    required this.blocks,
    required this.strings,
    required this.onAddBlock,
    required this.onRemoveBlock,
    required this.onEditBlock,
  });

  final int weekday;
  final List<WorkoutRoutineBlock> blocks;
  final AppStrings strings;
  final ValueChanged<WorkoutRoutineBlockType> onAddBlock;
  final ValueChanged<int> onRemoveBlock;
  final ValueChanged<int> onEditBlock;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(strings.weekdayLabel(weekday)),
        subtitle: Text(strings.setsCountLabel(blocks.length)),
        children: [
          if (blocks.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(strings.noRoutineForDay),
              ),
            )
          else
            ...blocks.indexed.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_blockLabel(entry.$2.type)),
                subtitle: Text(
                  entry.$2.exercises
                      .map(
                        (exercise) =>
                            '${exercise.exerciseName} ${exercise.sets}x${exercise.reps} @ ${exercise.weightKg.toStringAsFixed(1)} kg',
                      )
                      .join('  •  '),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: strings.editWorkoutButton,
                      onPressed: () => onEditBlock(entry.$1),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: strings.deleteWorkoutButton,
                      onPressed: () => onRemoveBlock(entry.$1),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: () => onAddBlock(WorkoutRoutineBlockType.normal),
                child: Text(strings.addNormalBlockButton),
              ),
              OutlinedButton(
                onPressed: () => onAddBlock(WorkoutRoutineBlockType.superset),
                child: Text(strings.addSupersetButton),
              ),
              OutlinedButton(
                onPressed: () => onAddBlock(WorkoutRoutineBlockType.triset),
                child: Text(strings.addTrisetButton),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _blockLabel(WorkoutRoutineBlockType type) {
    return switch (type) {
      WorkoutRoutineBlockType.normal => strings.normalBlockLabel,
      WorkoutRoutineBlockType.superset => strings.supersetBlockLabel,
      WorkoutRoutineBlockType.triset => strings.trisetBlockLabel,
    };
  }
}

class _RoutineExerciseDraft {
  _RoutineExerciseDraft(WorkoutRoutineExercise? initial)
      : setsController = TextEditingController(text: '${initial?.sets ?? 3}'),
        repsController = TextEditingController(text: '${initial?.reps ?? 10}'),
        weightController = TextEditingController(
          text: '${initial?.weightKg ?? 0}',
        ),
        customExerciseController = TextEditingController(
          text: initial != null &&
                  !exercisesForMuscleGroup(initial.muscleGroup)
                      .contains(initial.exerciseName)
              ? initial.exerciseName
              : '',
        ),
        muscleGroup = initial?.muscleGroup,
        selectedExercise = initial == null
            ? null
            : exercisesForMuscleGroup(initial.muscleGroup)
                    .contains(initial.exerciseName)
                ? initial.exerciseName
                : WeeklyWorkoutRoutineScreen._customExerciseValue,
        isCustomExercise = initial != null &&
            !exercisesForMuscleGroup(initial.muscleGroup)
                .contains(initial.exerciseName);

  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController weightController;
  final TextEditingController customExerciseController;
  String? muscleGroup;
  String? selectedExercise;
  bool isCustomExercise;

  void dispose() {
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    customExerciseController.dispose();
  }
}
