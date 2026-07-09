import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

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
                  _TimerSummaryCard(
                    title: strings.workoutTimelineTitle,
                    timeText: _formatSessionDuration(_sessionElapsed),
                    primaryKey: const Key('workout-session-button'),
                    detailLines: [
                      '${strings.totalGymTimeLabel}: ${_formatSessionDuration(_sessionElapsed)}',
                      '${strings.activeTrainingTimeLabel}: ${_formatSessionDuration(_activeTrainingElapsed)}',
                      '${strings.totalRestTimeLabel}: ${_formatSessionDuration(_totalRestElapsed)}',
                    ],
                    primaryLabel: _isSessionRunning
                        ? strings.stopTimerButton
                        : strings.startTimerButton,
                    onPrimaryPressed: _isSessionRunning
                        ? _stopSessionTimer
                        : _startSessionTimer,
                    secondaryLabel: strings.resetTimerButton,
                    onSecondaryPressed: _sessionElapsed > Duration.zero
                        ? _resetSessionTimer
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _TimerSummaryCard(
                    title: strings.restTimerTitle,
                    timeText: _formatRestCycleDuration(),
                    primaryKey: const Key('rest-toggle-button'),
                    detailLines: [
                      '${strings.currentRestCycleLabel}: ${_formatRestCycleDuration()}',
                      '${strings.totalRestTimeLabel}: ${_formatSessionDuration(_totalRestElapsed)}',
                      _restStateLabel(strings),
                    ],
                    leading: TextField(
                      key: const Key('rest-goal-seconds-field'),
                      controller: _restGoalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.restGoalSecondsLabel,
                      ),
                    ),
                    footer: Column(
                      children: [
                        SwitchListTile(
                          key: const Key('rest-alert-toggle'),
                          contentPadding: EdgeInsets.zero,
                          value: _restAlertEnabled,
                          onChanged: _setRestAlertEnabled,
                          title: Text(strings.restSoundToggleLabel),
                          subtitle: Text(strings.restSoundToggleHelp),
                          secondary: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                        ),
                        SwitchListTile(
                          key: const Key('rest-vibration-toggle'),
                          contentPadding: EdgeInsets.zero,
                          value: _restVibrationEnabled,
                          onChanged: _setRestVibrationEnabled,
                          title: Text(strings.restVibrationToggleLabel),
                          subtitle: Text(strings.restVibrationToggleHelp),
                          secondary: const Icon(Icons.vibration_outlined),
                        ),
                        DropdownButtonFormField<_RestAlertSoundProfile>(
                          key: const Key('rest-sound-dropdown'),
                          value: _restAlertSound,
                          decoration: InputDecoration(
                            labelText: strings.restSoundProfileLabel,
                            helperText: strings.restSoundProfileHelp,
                          ),
                          items: _RestAlertSoundProfile.values
                              .map(
                                (profile) => DropdownMenuItem(
                                  value: profile,
                                  child: Text(
                                      _labelForRestSound(profile, strings)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _setRestAlertSound(value, preview: true);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(strings.restAlertVolumeLabel),
                                  Text(
                                    strings.restAlertVolumeValueLabel(
                                      (_restAlertVolume * 100).round(),
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
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
                    primaryLabel: strings.restButton,
                    onPrimaryPressed: _toggleRestTimer,
                    primaryBackgroundColor: _restPrimaryColor(context),
                    primaryForegroundColor: Colors.white,
                    blinkPrimary: _isRestRunning,
                    primaryVisible: !_isRestRunning || _restBlinkOn,
                    secondaryLabel: strings.resetTimerButton,
                    onSecondaryPressed: _totalRestElapsed > Duration.zero
                        ? _resetRestTimer
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(strings.nextRestHint),
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
                      key: const Key('save-workout-button'),
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

    if (_isRestRunning) {
      _finishRestCycle();
    }
    _startRestTimer();
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

    if (_isRestRunning) {
      _finishRestCycle();
    }
    _startRestTimer();

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
      _durationController.text = '0';
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
    _durationController.text = _sessionElapsed.inMinutes.toString();
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

class _TimerSummaryCard extends StatelessWidget {
  const _TimerSummaryCard({
    required this.title,
    required this.timeText,
    this.detailLines = const [],
    this.leading,
    this.footer,
    this.primaryKey,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.primaryBackgroundColor,
    this.primaryForegroundColor,
    this.blinkPrimary = false,
    this.primaryVisible = true,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
  });

  final String title;
  final String timeText;
  final List<String> detailLines;
  final Widget? leading;
  final Widget? footer;
  final Key? primaryKey;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final Color? primaryBackgroundColor;
  final Color? primaryForegroundColor;
  final bool blinkPrimary;
  final bool primaryVisible;
  final String secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(timeText, style: Theme.of(context).textTheme.headlineMedium),
          if (detailLines.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in detailLines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
          ],
          if (leading != null) ...[
            const SizedBox(height: 12),
            leading!,
          ],
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: blinkPrimary ? (primaryVisible ? 1 : 0.35) : 1,
                child: FilledButton(
                  key: primaryKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryBackgroundColor,
                    foregroundColor: primaryForegroundColor,
                  ),
                  onPressed: onPrimaryPressed,
                  child: Text(primaryLabel),
                ),
              ),
              OutlinedButton(
                onPressed: onSecondaryPressed,
                child: Text(secondaryLabel),
              ),
            ],
          ),
        ],
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
