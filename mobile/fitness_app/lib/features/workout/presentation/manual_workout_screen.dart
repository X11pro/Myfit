import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../../../shared/app_language.dart';
import '../../../shared/ui/widgets/premium_card.dart';
import '../../../shared/ui/widgets/premium_screen.dart';
import '../../../shared/ui/widgets/section_header.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/manual_workout_controller.dart';
import '../domain/gym_set_entry.dart';
import '../domain/manual_workout_session.dart';
import '../domain/workout_exercise_catalog.dart';

class ManualWorkoutScreen extends ConsumerStatefulWidget {
  const ManualWorkoutScreen({super.key, this.session});

  final ManualWorkoutSession? session;

  @override
  ConsumerState<ManualWorkoutScreen> createState() =>
      _ManualWorkoutScreenState();
}

class _ManualWorkoutScreenState extends ConsumerState<ManualWorkoutScreen> {
  static const _restAlertEnabledStorageKey =
      'manual_workout_rest_alert_enabled';
  static const _restAlertVibrationStorageKey =
      'manual_workout_rest_alert_vibration_enabled';
  static const _restAlertVolumeStorageKey = 'manual_workout_rest_alert_volume';
  static const _restAlertSoundStorageKey = 'manual_workout_rest_alert_sound';
  static const _rpeOptions = <double>[6, 7, 7.5, 8, 8.5, 9, 9.5, 10];
  static const _customExerciseValue = '__custom_exercise__';
  static final Map<_RestAlertSoundProfile, Uint8List> _restAlertSoundBytes = {
    _RestAlertSoundProfile.whistle: _buildRestAlertSoundBytes(
      startFrequency: 1350,
      endFrequency: 1700,
      durationMs: 280,
    ),
    _RestAlertSoundProfile.chirp: _buildRestAlertSoundBytes(
      startFrequency: 1100,
      endFrequency: 2200,
      durationMs: 220,
    ),
    _RestAlertSoundProfile.ping: _buildRestAlertSoundBytes(
      startFrequency: 920,
      endFrequency: 920,
      durationMs: 360,
    ),
  };

  final _titleController = TextEditingController();
  final _durationController = TextEditingController();
  final _durationFocusNode = FocusNode();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  final _restGoalController = TextEditingController(text: '90');
  DateTime _selectedDate = DateTime.now();
  final List<GymSetEntry> _draftSets = [];
  Timer? _sessionTimer;
  Timer? _restTimer;
  AudioPlayer? _restAlertPlayer;
  Duration _sessionElapsed = Duration.zero;
  Duration _restAccumulated = Duration.zero;
  Duration _restCurrentElapsed = Duration.zero;
  bool _restBlinkOn = false;
  bool _restAlertEnabled = false;
  bool _restVibrationEnabled = false;
  double _restAlertVolume = 0.7;
  _RestAlertSoundProfile _restAlertSound = _RestAlertSoundProfile.whistle;
  bool _restAlertPlayedForCurrentCycle = false;

  bool get _isEditing => widget.session != null;
  bool get _isSessionRunning => _sessionTimer != null;
  bool get _isRestRunning => _restTimer != null;
  Duration get _restTargetDuration {
    final seconds = int.tryParse(_restGoalController.text.trim()) ?? 0;
    return Duration(seconds: math.max(0, seconds));
  }

  Duration get _totalRestElapsed =>
      _restAccumulated + (_isRestRunning ? _restCurrentElapsed : Duration.zero);

  Duration get _activeTrainingElapsed {
    final difference = _sessionElapsed - _totalRestElapsed;
    return difference.isNegative ? Duration.zero : difference;
  }

  bool get _isRestOverTarget =>
      _isRestRunning && _restCurrentElapsed >= _restTargetDuration;

  @override
  void initState() {
    super.initState();

    final session = widget.session;
    unawaited(_loadRestAlertPreferences());
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
    _sessionElapsed = Duration(seconds: session.totalDurationSeconds);
    _restAccumulated = Duration(seconds: session.restDurationSeconds);
    _durationController.text = _sessionElapsed.inMinutes.toString();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _restTimer?.cancel();
    _titleController.dispose();
    _durationController.dispose();
    _durationFocusNode.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    _restGoalController.dispose();
    unawaited(_restAlertPlayer?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = stringsFor(ref);
    final sessions = ref.watch(manualWorkoutSessionsProvider);
    final recentExercises = ref.watch(recentWorkoutExerciseNamesProvider);
    final groupedDraftSets = _groupDraftSets();

    return Scaffold(
      appBar: AppTopBar(
        title: _isEditing ? strings.editWorkoutTitle : strings.gymTitle,
        strings: strings,
      ),
      body: PremiumScreen(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: _isEditing
                  ? strings.editWorkoutTitle
                  : strings.logWorkoutTitle,
              subtitle: strings.gymSubtitle,
            ),
            const SizedBox(height: 12),
            PremiumCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fitness_center_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: strings.workoutNameLabel,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: strings.workoutDateLabel,
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ],
                  ),
                  Text(
                    '${strings.workoutDateLabel}: ${dateKeyFor(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactTimerCard(
                          title: strings.workoutSessionTimerTitle,
                          timeText: _formatSessionDuration(_sessionElapsed),
                          accentColor: Theme.of(context).colorScheme.primary,
                          primaryKey: const Key('workout-session-button'),
                          primaryLabel: _isSessionRunning
                              ? strings.stopTimerButton
                              : strings.startTimerButton,
                          onPrimaryPressed: _isSessionRunning
                              ? _stopSessionTimer
                              : _startSessionTimer,
                          onReset: _sessionElapsed > Duration.zero
                              ? _resetSessionTimer
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompactTimerCard(
                          title: strings.restTimerTitle,
                          timeText: _formatRestCycleDuration(),
                          accentColor: _restPrimaryColor(context),
                          primaryKey: const Key('rest-toggle-button'),
                          primaryLabel: strings.restButton,
                          onPrimaryPressed: _toggleRestTimer,
                          onReset: _totalRestElapsed > Duration.zero
                              ? _resetRestTimer
                              : null,
                          blink: _isRestRunning,
                          visible: !_isRestRunning || _restBlinkOn,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _WorkoutTimeSummary(
                    total: _formatSessionDuration(_sessionElapsed),
                    active: _formatSessionDuration(_activeTrainingElapsed),
                    rest: _formatSessionDuration(_totalRestElapsed),
                    strings: strings,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _restStateLabel(strings),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(strings.restTimerSettings),
                    children: [
                      TextField(
                        key: const Key('rest-goal-seconds-field'),
                        controller: _restGoalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: strings.restGoalSecondsLabel,
                        ),
                      ),
                      SwitchListTile(
                        key: const Key('rest-alert-toggle'),
                        contentPadding: EdgeInsets.zero,
                        value: _restAlertEnabled,
                        onChanged: _setRestAlertEnabled,
                        title: Text(strings.restSoundToggleLabel),
                      ),
                      SwitchListTile(
                        key: const Key('rest-vibration-toggle'),
                        contentPadding: EdgeInsets.zero,
                        value: _restVibrationEnabled,
                        onChanged: _setRestVibrationEnabled,
                        title: Text(strings.restVibrationToggleLabel),
                      ),
                      DropdownButtonFormField<_RestAlertSoundProfile>(
                        key: const Key('rest-sound-dropdown'),
                        value: _restAlertSound,
                        decoration: InputDecoration(
                          labelText: strings.restSoundProfileLabel,
                        ),
                        items: _RestAlertSoundProfile.values
                            .map(
                              (profile) => DropdownMenuItem(
                                value: profile,
                                child: Text(
                                  _labelForRestSound(profile, strings),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _setRestAlertSound(value, preview: true);
                          }
                        },
                      ),
                      Row(
                        children: [
                          Expanded(child: Text(strings.restAlertVolumeLabel)),
                          Expanded(
                            child: Slider(
                              key: const Key('rest-volume-slider'),
                              value: _restAlertVolume,
                              onChanged: _setRestAlertVolume,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(strings.notesLabel),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _durationController,
                              focusNode: _durationFocusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: strings.durationMinutesLabel,
                              ),
                              onChanged: _handleManualDurationChanged,
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
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration:
                            InputDecoration(labelText: strings.notesLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: strings.loggedSetsTitle),
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
                        onPressed: () => _openQuickSetDialog(
                          recentExercises: recentExercises,
                        ),
                        icon: const Icon(Icons.fitness_center_outlined),
                        label: Text(strings.addSetButton),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_draftSets.isEmpty)
                    Text(strings.noSetsAddedYet)
                  else
                    ...groupedDraftSets.entries.expand((group) => [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6),
                            child: Text(
                              group.key,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          ...group.value.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DraftSetTile(
                                set: item.value,
                                onEdit: () => _openQuickSetDialog(
                                  index: item.key,
                                  recentExercises: recentExercises,
                                ),
                                onRemove: () => _removeSet(item.key),
                              ),
                            ),
                          ),
                        ]),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('save-workout-button'),
                onPressed: _saveWorkout,
                child: Text(
                  _isEditing
                      ? strings.updateWorkoutButton
                      : strings.saveWorkoutButton,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(title: strings.workoutHistoryTitle),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              PremiumCard(child: Text(strings.noWorkoutsYet))
            else
              ...sessions.take(10).map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _WorkoutHistoryCard(session: session),
                    ),
                  ),
          ],
        ),
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

  // ignore: unused_element
  Future<void> _openLegacyQuickSetDialog({
    int? index,
    List<String> recentExercises = const [],
  }) async {
    final strings = stringsFor(ref);
    final existingSet = index == null ? null : _draftSets[index];
    final exerciseController =
        TextEditingController(text: existingSet?.exerciseName ?? '');
    final muscleGroupController =
        TextEditingController(text: existingSet?.muscleGroup ?? '');
    final setsController = TextEditingController(text: '1');
    final repsController =
        TextEditingController(text: existingSet?.reps.toString() ?? '');
    final weightController = TextEditingController(
      text: existingSet?.weightKg.toString() ?? '',
    );
    double? selectedRpe = existingSet?.rpe;

    final result = await showDialog<_SetDialogResult>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
              index == null ? strings.addSetButton : strings.editSetButton),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: exerciseController,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  decoration:
                      InputDecoration(labelText: strings.exerciseNameLabel),
                ),
                if (index == null && recentExercises.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recentExercises.take(6).map((exercise) {
                      return ActionChip(
                        label: Text(exercise),
                        onPressed: () => setDialogState(
                          () => exerciseController.text = exercise,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            InputDecoration(labelText: strings.setWeightLabel),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        decoration:
                            InputDecoration(labelText: strings.repsLabel),
                      ),
                    ),
                    if (index == null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: setsController,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(labelText: strings.setsLabel),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(strings.rpeLabel),
                  children: [
                    TextField(
                      controller: muscleGroupController,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          InputDecoration(labelText: strings.muscleGroupLabel),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: Text(strings.noRpeLabel),
                          selected: selectedRpe == null,
                          onSelected: (_) =>
                              setDialogState(() => selectedRpe = null),
                        ),
                        ..._rpeOptions.map((value) => ChoiceChip(
                              label: Text(strings.rpeValueLabel(value)),
                              selected: selectedRpe == value,
                              onSelected: (_) => setDialogState(
                                () => selectedRpe = value,
                              ),
                            )),
                      ],
                    ),
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
                final exercise = exerciseController.text.trim();
                final reps = int.tryParse(repsController.text.trim());
                final weight = double.tryParse(
                  weightController.text.trim().replaceAll(',', '.'),
                );
                final setsCount = int.tryParse(setsController.text.trim()) ?? 1;
                if (exercise.isEmpty ||
                    reps == null ||
                    weight == null ||
                    setsCount < 1) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  _SetDialogResult(
                    set: GymSetEntry(
                      exerciseName: exercise,
                      muscleGroup: muscleGroupController.text.trim(),
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
              child: Text(
                  index == null ? strings.addButton : strings.updateSetButton),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    exerciseController.dispose();
    muscleGroupController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();

    if (result == null) {
      return;
    }

    _applySetDialogResult(result, index: index);
  }

  Future<void> _openQuickSetDialog({
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
                      key: const Key('muscle-group-dropdown'),
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
                      key: const Key('exercise-dropdown'),
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
    final groups = List<String>.from(workoutMuscleGroups);
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
    final options = muscleGroup == null
        ? <String>[]
        : List<String>.from(exercisesForMuscleGroup(muscleGroup));

    if (existingExercise != null &&
        existingExercise.isNotEmpty &&
        !options.contains(existingExercise)) {
      options.add(existingExercise);
    }

    options.add(_customExerciseValue);
    return options;
  }

  void _applySetDialogResult(_SetDialogResult result, {int? index}) {
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

  void _removeSet(int index) {
    setState(() {
      _draftSets.removeAt(index);
      _reindexSets();
    });
  }

  Map<String, List<MapEntry<int, GymSetEntry>>> _groupDraftSets() {
    final grouped = <String, List<MapEntry<int, GymSetEntry>>>{};
    for (var index = 0; index < _draftSets.length; index++) {
      final set = _draftSets[index];
      grouped.putIfAbsent(set.exerciseName, () => []).add(MapEntry(index, set));
    }
    return grouped;
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

    if (_isRestRunning) {
      _finishRestCycle();
    }

    if (_isSessionRunning) {
      _stopSessionTimer();
    }

    final effectiveTotalDuration = _sessionElapsed > Duration.zero
        ? _sessionElapsed
        : Duration(minutes: duration);
    final effectiveRestDuration = _totalRestElapsed > effectiveTotalDuration
        ? effectiveTotalDuration
        : _totalRestElapsed;
    final effectiveActiveDuration =
        effectiveTotalDuration - effectiveRestDuration;
    final effectiveDurationMinutes = effectiveTotalDuration.inMinutes > 0
        ? effectiveTotalDuration.inMinutes
        : duration;

    final notifier = ref.read(manualWorkoutSessionsProvider.notifier);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (_isEditing) {
      await notifier.updateSession(
        id: widget.session!.id,
        title: title,
        date: _selectedDate,
        durationMinutes: effectiveDurationMinutes,
        totalDurationSeconds: effectiveTotalDuration.inSeconds,
        activeDurationSeconds: effectiveActiveDuration.inSeconds,
        restDurationSeconds: effectiveRestDuration.inSeconds,
        estimatedActiveCalories: calories,
        sets: List<GymSetEntry>.from(_draftSets),
        notes: notes,
      );
    } else {
      await notifier.addSession(
        title: title,
        date: _selectedDate,
        durationMinutes: effectiveDurationMinutes,
        totalDurationSeconds: effectiveTotalDuration.inSeconds,
        activeDurationSeconds: effectiveActiveDuration.inSeconds,
        restDurationSeconds: effectiveRestDuration.inSeconds,
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

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sessionElapsed += const Duration(seconds: 1);
        _syncDurationFieldWithTimer();
      });
    });
    setState(() {});
  }

  void _stopSessionTimer() {
    _finishRestCycle();
    _sessionTimer?.cancel();
    _sessionTimer = null;
    setState(_syncDurationFieldWithTimer);
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _restTimer?.cancel();
    _restTimer = null;
    setState(() {
      _sessionElapsed = Duration.zero;
      _restAccumulated = Duration.zero;
      _restCurrentElapsed = Duration.zero;
      _restBlinkOn = false;
      _durationController.clear();
    });
  }

  void _toggleRestTimer() {
    if (_isRestRunning) {
      _finishRestCycle();
      return;
    }

    _startRestTimer();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restCurrentElapsed = Duration.zero;
    _restAlertPlayedForCurrentCycle = false;
    _restTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _restCurrentElapsed += const Duration(milliseconds: 500);
        _restBlinkOn = !_restBlinkOn;
      });

      _maybePlayRestAlert();
    });
    setState(() {
      _restBlinkOn = true;
    });
  }

  void _finishRestCycle() {
    _restTimer?.cancel();
    _restTimer = null;
    setState(() {
      _restAccumulated += _restCurrentElapsed;
      _restCurrentElapsed = Duration.zero;
      _restBlinkOn = false;
    });
  }

  void _resetRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    setState(() {
      _restAccumulated = Duration.zero;
      _restCurrentElapsed = Duration.zero;
      _restBlinkOn = false;
      _restAlertPlayedForCurrentCycle = false;
    });
  }

  Future<void> _loadRestAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_restAlertEnabledStorageKey) ?? false;
    final vibration = prefs.getBool(_restAlertVibrationStorageKey) ?? false;
    final volume = prefs.getDouble(_restAlertVolumeStorageKey) ?? 0.7;
    final soundId = prefs.getString(_restAlertSoundStorageKey);
    if (!mounted) {
      return;
    }

    setState(() {
      _restAlertEnabled = enabled;
      _restVibrationEnabled = vibration;
      _restAlertVolume = volume.clamp(0.0, 1.0);
      _restAlertSound = _restAlertSoundProfileFromId(soundId);
    });
  }

  Future<void> _setRestAlertEnabled(bool value) async {
    setState(() {
      _restAlertEnabled = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_restAlertEnabledStorageKey, value);
  }

  Future<void> _setRestVibrationEnabled(bool value) async {
    setState(() {
      _restVibrationEnabled = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_restAlertVibrationStorageKey, value);
  }

  Future<void> _setRestAlertSound(
    _RestAlertSoundProfile value, {
    bool preview = false,
  }) async {
    setState(() {
      _restAlertSound = value;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_restAlertSoundStorageKey, value.id);

    if (preview) {
      await _playCurrentRestAlertSound();
    }
  }

  Future<void> _setRestAlertVolume(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    setState(() {
      _restAlertVolume = clamped;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_restAlertVolumeStorageKey, clamped);
  }

  Future<void> _maybePlayRestAlert() async {
    if (!_restAlertEnabled || _restAlertPlayedForCurrentCycle) {
      return;
    }

    final target = _restTargetDuration;
    if (target <= Duration.zero || _restCurrentElapsed < target) {
      return;
    }

    _restAlertPlayedForCurrentCycle = true;
    await _playCurrentRestAlertSound();

    if (_restVibrationEnabled) {
      await _triggerRestVibration();
    }
  }

  Future<void> _playCurrentRestAlertSound() async {
    _restAlertPlayer ??= AudioPlayer();

    try {
      await _restAlertPlayer!.stop();
      await _restAlertPlayer!.setVolume(_restAlertVolume);
      await _restAlertPlayer!.play(
        BytesSource(_restAlertSoundBytes[_restAlertSound]!),
      );
    } catch (_) {
      // Ignore audio failures to avoid blocking workout logging.
    }
  }

  Future<void> _triggerRestVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        return;
      }

      await Vibration.vibrate(duration: 180, amplitude: 180);
    } catch (_) {
      // Ignore vibration failures to avoid blocking workout logging.
    }
  }

  String _labelForRestSound(
    _RestAlertSoundProfile profile,
    AppStrings strings,
  ) {
    switch (profile) {
      case _RestAlertSoundProfile.whistle:
        return strings.restSoundWhistleLabel;
      case _RestAlertSoundProfile.chirp:
        return strings.restSoundChirpLabel;
      case _RestAlertSoundProfile.ping:
        return strings.restSoundPingLabel;
    }
  }

  _RestAlertSoundProfile _restAlertSoundProfileFromId(String? id) {
    for (final profile in _RestAlertSoundProfile.values) {
      if (profile.id == id) {
        return profile;
      }
    }

    return _RestAlertSoundProfile.whistle;
  }

  void _syncDurationFieldWithTimer() {
    if (_durationFocusNode.hasFocus) {
      return;
    }
    _durationController.text = _sessionElapsed.inMinutes.toString();
  }

  void _handleManualDurationChanged(String value) {
    if (_isSessionRunning) {
      return;
    }

    final minutes = int.tryParse(value.trim()) ?? 0;
    setState(() {
      _sessionElapsed = Duration(minutes: minutes);
    });
  }

  String _restStateLabel(AppStrings strings) {
    if (_isRestRunning) {
      return _isRestOverTarget
          ? strings.restOvertimeState
          : strings.restCountdownState;
    }

    return strings.restIdleState;
  }

  Color _restPrimaryColor(BuildContext context) {
    if (!_isRestRunning) {
      return Theme.of(context).colorScheme.primary;
    }

    return _isRestOverTarget ? Colors.green : Colors.red;
  }

  String _formatSessionDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '${value.inMinutes.toString().padLeft(2, '0')}:$seconds';
  }

  String _formatRestDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatRestCycleDuration() {
    final target = _restTargetDuration;
    final delta = _isRestOverTarget
        ? _restCurrentElapsed - target
        : target - _restCurrentElapsed;
    final sign = _isRestOverTarget ? '+' : '-';
    return '$sign${_formatRestDuration(delta)}';
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

class _CompactTimerCard extends StatelessWidget {
  const _CompactTimerCard({
    required this.title,
    required this.timeText,
    this.primaryKey,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.accentColor,
    this.blink = false,
    this.visible = true,
    this.onReset,
  });

  final String title;
  final String timeText;
  final Key? primaryKey;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final Color accentColor;
  final bool blink;
  final bool visible;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(timeText,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: blink ? (visible ? 1 : 0.35) : 1,
                  child: FilledButton(
                    key: primaryKey,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: onPrimaryPressed,
                    child: Text(primaryLabel, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              if (onReset != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Reset',
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutTimeSummary extends StatelessWidget {
  const _WorkoutTimeSummary({
    required this.total,
    required this.active,
    required this.rest,
    required this.strings,
  });

  final String total;
  final String active;
  final String rest;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _TimeMetric(
            label: strings.totalGymTimeLabel,
            value: total,
            color: scheme.primary),
        _TimeMetric(
            label: strings.activeTrainingTimeLabel,
            value: active,
            color: Colors.green),
        _TimeMetric(
            label: strings.totalRestTimeLabel,
            value: rest,
            color: Colors.orange),
      ],
    );
  }
}

class _TimeMetric extends StatelessWidget {
  const _TimeMetric(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

enum _RestAlertSoundProfile {
  whistle('whistle'),
  chirp('chirp'),
  ping('ping');

  const _RestAlertSoundProfile(this.id);

  final String id;
}

Uint8List _buildRestAlertSoundBytes({
  required double startFrequency,
  required double endFrequency,
  required int durationMs,
}) {
  const sampleRate = 22050;
  final sampleCount = sampleRate * durationMs ~/ 1000;
  final dataLength = sampleCount * 2;
  final byteData = ByteData(44 + dataLength);

  void writeString(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      byteData.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  writeString(0, 'RIFF');
  byteData.setUint32(4, 36 + dataLength, Endian.little);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, 1, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * 2, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  writeString(36, 'data');
  byteData.setUint32(40, dataLength, Endian.little);

  for (var index = 0; index < sampleCount; index++) {
    final time = index / sampleRate;
    final progress = index / sampleCount;
    final frequency =
        startFrequency + ((endFrequency - startFrequency) * progress);
    final envelope = math.sin(math.pi * progress);
    final sample = math.sin(2 * math.pi * frequency * time) * envelope * 0.45;
    final pcm = (sample * 32767).round().clamp(-32768, 32767);
    byteData.setInt16(44 + (index * 2), pcm, Endian.little);
  }

  return byteData.buffer.asUint8List();
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${strings.setNumberLabel(set.setNumber)} • ${set.weightKg} kg • ${strings.repsCountLabel(set.reps)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (set.rpe != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('RPE ${strings.rpeValueLabel(set.rpe!)}'),
            ),
          IconButton(
            tooltip: strings.editSetButton,
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: strings.deleteWorkoutButton,
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
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
                      const SizedBox(height: 4),
                      Text(
                        strings.workoutTimeSummary(
                          total: _formatTimelineDuration(
                            Duration(seconds: session.totalDurationSeconds),
                          ),
                          active: _formatTimelineDuration(
                            Duration(seconds: session.activeDurationSeconds),
                          ),
                          rest: _formatTimelineDuration(
                            Duration(seconds: session.restDurationSeconds),
                          ),
                        ),
                      ),
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

  String _formatTimelineDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '${value.inMinutes.toString().padLeft(2, '0')}:$seconds';
  }
}
