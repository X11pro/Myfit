import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'workout_editor_dialog.dart';
import '../../../shared/ui/theme/app_theme.dart';
import '../../../shared/widgets/myfit_bottom_nav.dart';

import '../../../shared/app_language.dart';
import '../../../shared/ui/widgets/premium_card.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/weekly_workout_routine_controller.dart';
import '../domain/weekly_workout_routine.dart';
import '../domain/workout_exercise_catalog.dart';

class WeeklyWorkoutRoutineScreen extends ConsumerStatefulWidget {
  const WeeklyWorkoutRoutineScreen({super.key, this.request});
  final WeeklyRoutineRequest? request;
  @override
  ConsumerState<WeeklyWorkoutRoutineScreen> createState() =>
      _WeeklyRoutineState();
}

const _customExerciseValue = '__custom_exercise__';

class _WeeklyRoutineState extends ConsumerState<WeeklyWorkoutRoutineScreen> {
  late int _day = (widget.request?.date ?? DateTime.now()).weekday;
  bool _busy = false;
  bool _applying = false;
  Future<void> _once(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref), en = strings.isEnglish;
    final library = ref.watch(weeklyWorkoutRoutineProvider),
        notifier = ref.read(weeklyWorkoutRoutineProvider.notifier);
    final routine = library.activeRoutine;
    final blocks =
        routine?.blocksByWeekday[_day] ?? const <WorkoutRoutineBlock>[];
    final repeated = duplicateRoutineMovements(blocks);
    final exercises = blocks.expand((block) => block.exercises).toList();
    final sets = exercises.fold<int>(0, (n, e) => n + e.sets);
    final muscles = <String>{
      for (final exercise in exercises)
        if (exercise.muscleGroup.trim().isNotEmpty) exercise.muscleGroup.trim(),
    };
    final requestedDay = widget.request?.date.weekday;
    final pickedDay = _day;
    final isWorkoutDay = _day == (requestedDay ?? DateTime.now().weekday);
    return Scaffold(
        appBar: AppTopBar(title: strings.weeklyRoutineTitle, strings: strings),
        bottomNavigationBar: MyfitBottomNav(strings: strings, index: 1),
        body: SafeArea(
            top: false,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                      en
                          ? 'TRAINING / WEEKLY PLAN'
                          : 'ENTRENAMIENTO / PLAN SEMANAL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.secondary, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Row(children: [
                    if (routine != null)
                      Expanded(
                          child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: routine.id,
                              decoration: InputDecoration(
                                  labelText: strings.routineNameLabel),
                              items: [
                                for (final item in library.routines)
                                  DropdownMenuItem(
                                      value: item.id,
                                      child: Text(item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis))
                              ],
                              onChanged: _busy
                                  ? null
                                  : (id) {
                                      if (id != null) {
                                        _once(() => notifier.selectRoutine(id));
                                      }
                                    }))
                    else
                      Expanded(child: Text(strings.noSavedRoutines)),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.neutral,
                          foregroundColor: AppTheme.charcoal,
                        ),
                        onPressed: _busy
                            ? null
                            : () => _once(
                                () => _createRoutine(context, ref, strings)),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(en ? 'New' : 'Nueva')),
                    if (routine != null)
                      PopupMenuButton<String>(
                          enabled: !_busy,
                          onSelected: (action) => _once(() async {
                                if (action == 'rename') {
                                  await _renameRoutine(
                                      context, ref, routine, strings);
                                } else {
                                  final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                              title: Text(
                                                  strings.deleteRoutineButton),
                                              content: Text(routine.name),
                                              actions: [
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, false),
                                                    child: Text(
                                                        strings.cancelButton)),
                                                FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, true),
                                                    style:
                                                        FilledButton.styleFrom(
                                                      backgroundColor:
                                                          AppTheme.tertiary,
                                                      foregroundColor:
                                                          AppTheme.background,
                                                    ),
                                                    child: Text(strings
                                                        .deleteRoutineButton))
                                              ]));
                                  if (mounted && confirmed == true) {
                                    await notifier.deleteRoutine(routine.id);
                                  }
                                }
                              }),
                          itemBuilder: (_) => [
                                PopupMenuItem(
                                    value: 'rename',
                                    child: Text(strings.renameRoutineButton)),
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Text(strings.deleteRoutineButton))
                              ])
                  ]),
                  if (routine != null) ...[
                    const SizedBox(height: 12),
                    LayoutBuilder(builder: (context, constraints) {
                      final width = ((constraints.maxWidth - 24) / 7)
                          .clamp(44.0, 88.0)
                          .toDouble();
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (int d = 1; d <= 7; d++) ...[
                            if (d > 1) const SizedBox(width: 4),
                            SizedBox(
                              width: width,
                              child: _RoutineDay(
                                key: ValueKey('routine-day-$d'),
                                label: strings.weekdayLabel(d),
                                blockCount:
                                    routine.blocksByWeekday[d]?.length ?? 0,
                                current: d ==
                                    (requestedDay ?? DateTime.now().weekday),
                                selected: d == _day,
                                en: en,
                                onTap: _busy
                                    ? null
                                    : () => setState(() => _day = d),
                              ),
                            ),
                          ],
                        ]),
                      );
                    }),
                    const SizedBox(height: 12),
                    PremiumCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              isWorkoutDay
                                  ? (en ? 'WORKOUT DAY' : 'DÍA DE ENTRENO')
                                  : (en
                                      ? 'PLANNED SESSION'
                                      : 'SESIÓN PLANIFICADA'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppTheme.secondary)),
                          const SizedBox(height: 4),
                          Text(strings.weekdayLabel(_day),
                              style: Theme.of(context).textTheme.titleLarge),
                          if (muscles.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(muscles.join(' · '),
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                          const SizedBox(height: 14),
                          Wrap(spacing: 16, runSpacing: 8, children: [
                            _PlanMetric(
                                label: en ? 'Blocks' : 'Bloques',
                                value: '${blocks.length}'),
                            _PlanMetric(
                                label: en ? 'Exercises' : 'Ejercicios',
                                value: '${exercises.length}'),
                            _PlanMetric(
                                label: en ? 'Sets' : 'Series',
                                value: '$sets',
                                accent: AppTheme.secondary),
                          ]),
                        ])),
                    if (repeated.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                              en
                                  ? 'Repeated movements: ${repeated.join(', ')}. Edit this day before applying.'
                                  : 'Movimientos repetidos: ${repeated.join(', ')}. Corrige el día antes de aplicar.',
                              style: const TextStyle(color: AppTheme.warning))),
                    if (blocks.isEmpty)
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(strings.noRoutineForDay)),
                    for (final (index, block) in blocks.indexed)
                      Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _MovementCard(
                              index: index,
                              block: block,
                              label: _blockLabel(block.type, strings),
                              en: en,
                              onEdit: _busy
                                  ? null
                                  : () => _once(() => _editBlock(
                                      context,
                                      ref,
                                      routine.id,
                                      pickedDay,
                                      blocks,
                                      index,
                                      strings)),
                              onRemove: _busy
                                  ? null
                                  : () => _once(() => _removeBlock(ref,
                                      routine.id, pickedDay, blocks, index)))),
                    const SizedBox(height: 16),
                    Text(en ? 'Add movement block' : 'Añadir bloque',
                        style: Theme.of(context).textTheme.titleMedium),
                    Wrap(spacing: 6, children: [
                      for (final type in WorkoutRoutineBlockType.values)
                        OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _once(() => _addBlock(
                                    context,
                                    ref,
                                    routine.id,
                                    pickedDay,
                                    blocks,
                                    type,
                                    strings)),
                            icon: Icon(_blockIcon(type),
                                color: _blockAccent(type), size: 16),
                            label: Text(_blockLabel(type, strings)))
                    ]),
                  ],
                  const SizedBox(height: 12),
                  PremiumCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.sync,
                                color: AppTheme.secondary),
                            title: Text(en
                                ? 'Routine library'
                                : 'Biblioteca de rutinas'),
                            subtitle: Text(en
                                ? 'Reload routines to check for updates.'
                                : 'Volvé a cargar las rutinas para buscar cambios.'),
                          ),
                          OutlinedButton.icon(
                              key: const Key('reload-routines-button'),
                              onPressed: _busy
                                  ? null
                                  : () => _once(notifier.refreshFromRemote),
                              icon: const Icon(Icons.refresh),
                              label: Text(strings.reloadRoutinesButton)),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  if (widget.request?.canApply == true &&
                      requestedDay == _day &&
                      blocks.isNotEmpty)
                    FilledButton.icon(
                        onPressed: _busy || repeated.isNotEmpty
                            ? null
                            : () {
                                if (_applying) return;
                                _applying = true;
                                context.pop(
                                    List<WorkoutRoutineBlock>.unmodifiable(
                                        blocks));
                              },
                        icon: const Icon(Icons.play_circle_outline),
                        label: Text(en
                            ? 'Apply to this workout'
                            : 'Aplicar a este entreno')),
                ])));
  }

  bool _checkLatest(String id, int day, List<WorkoutRoutineBlock> original,
      List<WorkoutRoutineBlock> next, AppStrings strings) {
    final current = ref
        .read(weeklyWorkoutRoutineProvider)
        .routines
        .where((r) => r.id == id)
        .firstOrNull;
    if (current == null ||
        !identical(
            current.blocksByWeekday[day] ?? const <WorkoutRoutineBlock>[],
            original)) {
      _warn(strings.isEnglish
          ? 'The routine changed while editing. Reopen the day.'
          : 'La rutina cambió. Volvé a abrir el día.');
      return false;
    }
    if (increasesRoutineMovementDuplicates(original, next)) {
      _warn(strings.isEnglish
          ? 'This movement is already in this day. Edit the existing block.'
          : 'Este movimiento ya está en este día. Editá el bloque existente.');
      return false;
    }
    return true;
  }

  void _warn(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

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
    if (block == null ||
        !mounted ||
        !_checkLatest(
            routineId, weekday, blocks, [...blocks, block], strings)) {
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
    if (updatedBlock == null || !mounted) {
      return;
    }
    final updatedBlocks = List<WorkoutRoutineBlock>.from(blocks)
      ..[index] = updatedBlock;
    if (!_checkLatest(routineId, weekday, blocks, updatedBlocks, strings)) {
      return;
    }
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
    if (name == null || !mounted) {
      return;
    }
    final notifier = ref.read(weeklyWorkoutRoutineProvider.notifier);
    if (notifier.routineNameInUse(name)) {
      _warn(strings.isEnglish
          ? 'A routine already uses that name.'
          : 'Ya existe una rutina con ese nombre.');
      return;
    }
    await notifier.createRoutine(name);
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
    if (name == null || !mounted) {
      return;
    }
    final notifier = ref.read(weeklyWorkoutRoutineProvider.notifier);
    if (notifier.routineNameInUse(name, exceptId: routine.id)) {
      _warn(strings.isEnglish
          ? 'A routine already uses that name.'
          : 'Ya existe una rutina con ese nombre.');
      return;
    }
    await notifier.renameRoutine(routine.id, name);
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

    var submitted = false;
    String? validation;
    final route = DialogRoute<WorkoutRoutineBlock>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => WorkoutEditorDialog(
          title: _blockLabel(type, strings),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < drafts.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                PremiumCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.routineExerciseLabel(index),
                        style: Theme.of(dialogContext).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
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
                          .followedBy([
                        if (drafts[index].muscleGroup case final group?
                            when !workoutMuscleGroups.contains(group))
                          DropdownMenuItem(value: group, child: Text(group)),
                      ]).toList(),
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
                      key: ValueKey((index, drafts[index].muscleGroup)),
                      value: drafts[index].selectedExercise,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: strings.exerciseNameLabel,
                      ),
                      items: [
                        if (drafts[index].muscleGroup != null)
                          ...exercisesForMuscleGroup(
                              drafts[index].muscleGroup!),
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
                                  drafts[index]
                                      .customExerciseController
                                      .clear();
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
                  ]),
                ),
              ],
            ],
          ),
          actions: [
            if (validation != null)
              Text(validation!, style: const TextStyle(color: AppTheme.danger)),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                if (submitted) return;
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
                      !weight.isFinite ||
                      weight < 0 ||
                      sets > 100 ||
                      sets < 1 ||
                      reps < 1) {
                    setDialogState(() => validation = strings.isEnglish
                        ? 'Choose each exercise and enter valid sets, reps and weight.'
                        : 'Elegí cada ejercicio e ingresá series, repeticiones y peso válidos.');
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
                submitted = true;
                Navigator.of(dialogContext).pop(
                  WorkoutRoutineBlock(type: type, exercises: exercises),
                );
              },
              child: Text(initialBlock == null
                  ? strings.addButton
                  : strings.updateSetButton),
            ),
          ],
        ),
      ),
    );

    final result = await Navigator.of(context, rootNavigator: true).push(route);
    await route.completed;
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

Color _blockAccent(WorkoutRoutineBlockType type) => switch (type) {
      WorkoutRoutineBlockType.normal => AppTheme.charcoal,
      WorkoutRoutineBlockType.superset => AppTheme.secondary,
      WorkoutRoutineBlockType.triset => AppTheme.tertiary,
    };

IconData _blockIcon(WorkoutRoutineBlockType type) => switch (type) {
      WorkoutRoutineBlockType.normal => Icons.fitness_center,
      WorkoutRoutineBlockType.superset => Icons.link,
      WorkoutRoutineBlockType.triset => Icons.view_agenda_outlined,
    };

class _RoutineDay extends StatelessWidget {
  const _RoutineDay({
    super.key,
    required this.label,
    required this.blockCount,
    required this.current,
    required this.selected,
    required this.en,
    this.onTap,
  });

  final String label;
  final int blockCount;
  final bool current, selected, en;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = selected ? AppTheme.background : AppTheme.charcoal;
    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? AppTheme.primary : AppTheme.neutral,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              child: Column(children: [
                Text(label.substring(0, 3).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(blockCount == 0 ? (en ? 'Rest' : 'Pausa') : '$blockCount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelSmall?.copyWith(color: color)),
                const SizedBox(height: 4),
                Icon(blockCount == 0 ? Icons.horizontal_rule : Icons.circle,
                    size: 7,
                    color: selected
                        ? AppTheme.background
                        : current
                            ? AppTheme.secondary
                            : AppTheme.mutedText),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  const _PlanMetric({required this.label, required this.value, this.accent});

  final String label, value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutral,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: t.labelSmall),
        Text(value, style: t.titleMedium?.copyWith(color: accent)),
      ]),
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard(
      {required this.index,
      required this.block,
      required this.label,
      required this.en,
      this.onEdit,
      this.onRemove});
  final int index;
  final WorkoutRoutineBlock block;
  final String label;
  final bool en;
  final VoidCallback? onEdit, onRemove;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final linked = block.type != WorkoutRoutineBlockType.normal;
    final accent = _blockAccent(block.type);
    final rounds = block.exercises.firstOrNull?.sets;
    final uniformRounds = linked &&
        rounds != null &&
        block.exercises.every((exercise) => exercise.sets == rounds);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
            color: linked ? accent.withValues(alpha: .38) : AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(_blockIcon(block.type), size: 17, color: accent),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: linked
                          ? accent.withValues(alpha: .14)
                          : AppTheme.neutral,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      child: Text(
                          '${en ? 'BLOCK' : 'BLOQUE'} ${index + 1} · $label',
                          style: t.labelSmall?.copyWith(color: accent)),
                    ),
                  ),
                  if (uniformRounds)
                    Text(
                      en
                          ? '$rounds ${rounds == 1 ? 'round' : 'rounds'}'
                          : '$rounds ${rounds == 1 ? 'ronda' : 'rondas'}',
                      style: t.labelSmall,
                    ),
                ],
              ),
            ),
            IconButton(
                tooltip: en ? 'Edit block' : 'Editar bloque',
                onPressed: onEdit,
                icon: const Icon(Icons.tune, size: 19)),
            IconButton(
                tooltip: en ? 'Remove block' : 'Quitar bloque',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline,
                    size: 19, color: AppTheme.tertiary))
          ]),
          for (final (i, e) in block.exercises.indexed)
            Padding(
                padding: EdgeInsets.only(top: i == 0 ? 4 : 8),
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppTheme.backgroundSecondary,
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (linked) ...[
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: accent,
                              foregroundColor: AppTheme.background,
                              child: Text(String.fromCharCode(65 + i)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(e.exerciseName, style: t.titleMedium),
                                if (e.muscleGroup.isNotEmpty)
                                  Text(e.muscleGroup, style: t.bodySmall),
                                const SizedBox(height: 6),
                                if (linked)
                                  Text(
                                      '${uniformRounds ? '' : '${e.sets} × '}${e.reps} ${en ? 'reps' : 'rep.'} · ${e.weightKg} kg',
                                      style: t.labelMedium
                                          ?.copyWith(color: accent))
                                else
                                  Wrap(spacing: 6, runSpacing: 6, children: [
                                    _PlanMetric(
                                        label: en ? 'Sets' : 'Series',
                                        value: '${e.sets}'),
                                    _PlanMetric(
                                        label: 'Reps', value: '${e.reps}'),
                                    _PlanMetric(
                                        label: en ? 'Load' : 'Carga',
                                        value: '${e.weightKg} kg'),
                                  ])
                              ])),
                        ]))),
        ]),
      ),
    );
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
                : _customExerciseValue,
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
