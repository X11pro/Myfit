import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'workout_editor_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../../../shared/app_language.dart';
import '../../../shared/date_format.dart';
import '../../../shared/ui/widgets/premium_card.dart';
import '../../../shared/ui/theme/app_theme.dart';
import '../../../shared/submission_id.dart';
import '../../../shared/widgets/myfit_bottom_nav.dart';

import '../application/manual_workout_controller.dart';
import '../application/weekly_workout_routine_controller.dart';
import '../domain/gym_set_entry.dart';
import '../domain/manual_workout_session.dart';
import '../domain/weekly_workout_routine.dart';
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
  static final _restAlertAudioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();
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
  bool _setEditorOpen = false;
  bool _savingWorkout = false;
  bool _routineEditorOpen = false;
  String? _submissionId;

  Timer? _sessionTimer;
  Timer? _restTimer;
  AudioPlayer? _restAlertPlayer;
  Duration _sessionElapsed = Duration.zero;
  Duration _restAccumulated = Duration.zero;
  Duration _restCurrentElapsed = Duration.zero;
  final Set<int> _completed = {};
  final _appliedRoutineTargets = <String, WorkoutRoutineExercise>{};
  bool _loadingRoutine = false;
  int _stepRevision = 0;
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
      _titleController.text = dateKeyFor(_selectedDate);
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
    final en = strings.isEnglish;
    final sessions = ref.watch(manualWorkoutSessionsProvider);
    final recentExercises = ref.watch(recentWorkoutExerciseNamesProvider);
    final weeklyRoutineLibrary = ref.watch(weeklyWorkoutRoutineProvider);
    final groupedDraftSets = _groupDraftSets();
    final routineBlocks =
        weeklyRoutineLibrary.activeRoutine?.blocksFor(_selectedDate) ??
            const [];
    final hasRoutineToLoad = _pendingRoutineExercises(routineBlocks).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Myfit',
              style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800)),
          actions: [
            TextButton(
                onPressed: () => ref.read(appLanguageProvider.notifier).state =
                    en ? AppLanguage.es : AppLanguage.en,
                child: const Text('EN / ES')),
            IconButton(
                tooltip: strings.accountTabLabel,
                onPressed: () => context.push('/auth'),
                icon: const Icon(Icons.account_circle_outlined))
          ]),
      bottomNavigationBar: MyfitBottomNav(strings: strings, index: 1),
      body: SafeArea(
          top: false,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(en ? '●  ACTIVE SESSION' : '●  SESIÓN ACTIVA',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppTheme.primary)),
                      TextButton(
                          onPressed: _pickDate,
                          child: Text(formatDisplayDate(_selectedDate))),
                      FilledButton.icon(
                          key: const Key('save-workout-button'),
                          onPressed: _savingWorkout ? null : _saveWorkout,
                          icon:
                              const Icon(Icons.check_circle_outline, size: 16),
                          label: Text(en ? 'Finish' : 'Finalizar'))
                    ]),
                TextField(
                    key: const Key('workout-title-field'),
                    maxLines: 2,
                    minLines: 1,
                    controller: _titleController,
                    style: Theme.of(context).textTheme.titleLarge,
                    decoration: InputDecoration(
                        hintText: strings.workoutNameLabel,
                        suffixIcon: const Icon(Icons.edit_outlined, size: 16),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero)),
                Text(
                    '${strings.weeklyRoutineTitle}: ${weeklyRoutineLibrary.activeRoutine?.name ?? (en ? "Manual session" : "Sesión manual")}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(en ? 'ELAPSED TIME' : 'TIEMPO TOTAL',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall),
                                      Text(
                                          _formatSessionDuration(
                                              _sessionElapsed),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium)
                                    ])),
                                Column(children: [
                                  Text(en ? '● Work' : '● Activo',
                                      style: const TextStyle(
                                          color: AppTheme.primary)),
                                  Text(_formatRestDuration(
                                      _activeTrainingElapsed))
                                ]),
                                const SizedBox(width: 12),
                                Column(children: [
                                  Text(en ? '● Rest' : '● Pausa',
                                      style: const TextStyle(
                                          color: AppTheme.warning)),
                                  Text(_formatRestDuration(_totalRestElapsed))
                                ]),
                                IconButton(
                                    key: const Key('workout-session-button'),
                                    tooltip: _isSessionRunning
                                        ? strings.stopTimerButton
                                        : strings.startTimerButton,
                                    onPressed: _isSessionRunning
                                        ? _stopSessionTimer
                                        : _startSessionTimer,
                                    icon: Icon(_isSessionRunning
                                        ? Icons.pause
                                        : Icons.play_arrow))
                              ]),
                              const SizedBox(height: 12),
                              DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: AppTheme.surfaceMuted,
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              const Icon(Icons.timer_outlined,
                                                  color: AppTheme.primary,
                                                  size: 18),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                  child: Text(en
                                                      ? 'Auto-Rest Countdown'
                                                      : 'Cuenta atrás de descanso')),
                                              Text(_restStateLabel(strings),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall)
                                            ]),
                                            const SizedBox(height: 10),
                                            Row(children: [
                                              SizedBox.square(
                                                  dimension: 44,
                                                  child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        CircularProgressIndicator(
                                                            strokeWidth: 3,
                                                            value: _isRestRunning &&
                                                                    _restTargetDuration
                                                                            .inMilliseconds >
                                                                        0
                                                                ? (1 -
                                                                        _restCurrentElapsed.inMilliseconds /
                                                                            _restTargetDuration
                                                                                .inMilliseconds)
                                                                    .clamp(0.0,
                                                                        1.0)
                                                                : 0,
                                                            backgroundColor:
                                                                AppTheme
                                                                    .border),
                                                        const Icon(
                                                            Icons
                                                                .bedtime_outlined,
                                                            size: 18)
                                                      ])),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: FittedBox(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                          _formatRestCycleDuration(),
                                                          style: Theme.of(
                                                                  context)
                                                              .textTheme
                                                              .headlineMedium))),
                                              TextButton(
                                                  onPressed: () => setState(
                                                      () => _restGoalController
                                                              .text =
                                                          '${_restTargetDuration.inSeconds + 30}'),
                                                  child: const Text('+30s')),
                                              TextButton(
                                                  key: const Key(
                                                      'rest-toggle-button'),
                                                  onPressed: _toggleRestTimer,
                                                  child: Text(_isRestRunning
                                                      ? (en ? 'Skip' : 'Omitir')
                                                      : strings.restButton))
                                            ]),
                                            Wrap(spacing: 4, children: [
                                              for (final sec in [
                                                45,
                                                60,
                                                90,
                                                120,
                                                180
                                              ])
                                                ChoiceChip(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    labelPadding:
                                                        EdgeInsets.zero,
                                                    showCheckmark: false,
                                                    label: Text('${sec}s'),
                                                    selected:
                                                        _restTargetDuration
                                                                .inSeconds ==
                                                            sec,
                                                    onSelected: (_) => setState(
                                                        () =>
                                                            _restGoalController
                                                                .text = '$sec'))
                                            ]),
                                            Wrap(children: [
                                              TextButton.icon(
                                                  onPressed: () =>
                                                      _setRestAlertEnabled(
                                                          !_restAlertEnabled),
                                                  icon: Icon(
                                                      _restAlertEnabled
                                                          ? Icons.volume_up
                                                          : Icons.volume_off,
                                                      size: 16),
                                                  label: Text(
                                                      en ? 'Audio' : 'Sonido')),
                                              TextButton.icon(
                                                  onPressed: () =>
                                                      _setRestVibrationEnabled(
                                                          !_restVibrationEnabled),
                                                  icon: Icon(Icons.vibration,
                                                      size: 16,
                                                      color:
                                                          _restVibrationEnabled
                                                              ? AppTheme.primary
                                                              : AppTheme
                                                                  .mutedText),
                                                  label: Text(en
                                                      ? 'Haptics'
                                                      : 'Vibración'))
                                            ])
                                          ]))),
                              ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(strings.restTimerSettings),
                                children: [
                                  const SizedBox(height: 8),
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
                                    title:
                                        Text(strings.restVibrationToggleLabel),
                                  ),
                                  DropdownButtonFormField<
                                      _RestAlertSoundProfile>(
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
                                              _labelForRestSound(
                                                  profile, strings),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _setRestAlertSound(value,
                                            preview: true);
                                      }
                                    },
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Text(
                                              strings.restAlertVolumeLabel)),
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
                                  if (_sessionElapsed > Duration.zero)
                                    TextButton(
                                        onPressed: _resetSessionTimer,
                                        child: Text(en
                                            ? "Reset session timer"
                                            : "Reiniciar tiempo total")),
                                  if (_totalRestElapsed > Duration.zero)
                                    TextButton(
                                        onPressed: _resetRestTimer,
                                        child: Text(en
                                            ? "Reset rest time"
                                            : "Reiniciar descanso")),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _durationController,
                                          focusNode: _durationFocusNode,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            labelText:
                                                strings.durationMinutesLabel,
                                          ),
                                          onChanged:
                                              _handleManualDurationChanged,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _caloriesController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText:
                                                strings.workoutCaloriesLabel,
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
                                    decoration: InputDecoration(
                                        labelText: strings.notesLabel),
                                  ),
                                ],
                              ),
                            ]))),
                const SizedBox(height: 16),
                for (final group in groupedDraftSets.entries)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ExerciseSetCard(
                          exerciseName: group.key,
                          sets: group.value,
                          strings: strings,
                          completed: _completed,
                          revision: _stepRevision,
                          restSeconds: _restTargetDuration.inSeconds,
                          expandedInitially: _isEditing &&
                              group.key == groupedDraftSets.keys.first,
                          previous: sessions
                              .where((s) =>
                                  s.id != widget.session?.id &&
                                  !s.createdAt.isAfter(_selectedDate))
                              .expand((s) => s.sets)
                              .where((s) => s.exerciseName == group.key)
                              .firstOrNull,
                          onStep: (i, {reps, weightKg}) {
                            _stepRevision++;
                            _updateSet(i, reps: reps, weightKg: weightKg);
                          },
                          onToggle: (i) => setState(() {
                                if (!_completed.remove(i)) _completed.add(i);
                              }),
                          onAdd: () =>
                              _openQuickSetDialog(seed: group.value.last.value),
                          onComplete: (i) {
                            if (_completed.contains(i)) return;
                            setState(() => _completed.add(i));
                            if (_isRestRunning) _finishRestCycle();
                            if (_restTargetDuration.inSeconds > 0) {
                              _startRestTimer();
                            }
                          },
                          onRepeat: () =>
                              _duplicateLastSet(group.value.last.value),
                          onNote: (i, label) => _addSetNote(i, label),
                          onSetChanged: _updateSet,
                          onEdit: (i) => _openQuickSetDialog(
                              index: i, recentExercises: recentExercises),
                          onRemove: _removeSet)),
                OutlinedButton.icon(
                    onPressed: () =>
                        _openQuickSetDialog(recentExercises: recentExercises),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(_draftSets.isEmpty
                        ? strings.addSetButton
                        : (en ? 'Add exercise' : 'Añadir ejercicio'))),
                const SizedBox(height: 12),
                if (!_isEditing && routineBlocks.isNotEmpty)
                  FilledButton.icon(
                    key: const Key('load-routine-button'),
                    onPressed:
                        _savingWorkout || _loadingRoutine || !hasRoutineToLoad
                            ? null
                            : () => _loadRoutine(routineBlocks),
                    icon: const Icon(Icons.playlist_add),
                    label: Text(
                      !hasRoutineToLoad
                          ? (en
                              ? 'Routine exercises already in workout'
                              : 'Los ejercicios de la rutina ya están cargados')
                          : strings.loadRoutineForDay(
                              strings.weekdayLabel(_selectedDate.weekday)),
                    ),
                  ),
                Card(
                    child: ListTile(
                        key: const Key('edit-weekly-routine-button'),
                        onTap: _editWeeklyRoutine,
                        leading: const Icon(Icons.calendar_month_outlined,
                            color: AppTheme.warning),
                        title: Text(strings.editWeeklyRoutineButton),
                        trailing: const Icon(Icons.chevron_right))),
                const SizedBox(height: 24),
                ExpansionTile(
                    title: Text(strings.workoutHistoryTitle),
                    children: [
                      if (sessions.isEmpty)
                        PremiumCard(child: Text(strings.noWorkoutsYet))
                      else
                        ...sessions.take(10).map(
                              (session) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _WorkoutHistoryCard(session: session),
                              ),
                            ),
                    ]),
              ])),
    );
  }

  Future<void> _addSetNote(int index, String label) async {
    final s = _draftSets[index];
    final prefix = '${s.exerciseName} · Set ${s.setNumber}';
    String text = label;
    if (label.isEmpty) {
      final en = stringsFor(ref).isEnglish;
      var draft = '';
      final result = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
                  title: Text(en ? 'Set note' : 'Nota de serie'),
                  content:
                      TextField(autofocus: true, onChanged: (v) => draft = v),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: Text(
                            MaterialLocalizations.of(c).cancelButtonLabel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(c, draft.trim()),
                        child: Text(en ? 'Save' : 'Guardar'))
                  ]));
      if (!mounted || result == null || result.isEmpty) return;
      text = result;
    }
    if (_notesController.text.split('\n').any(
        (line) => routineNameKey(line) == routineNameKey('$prefix: $text'))) {
      return;
    }
    _notesController.text = [
      if (_notesController.text.isNotEmpty) _notesController.text,
      '$prefix: $text'
    ].join('\n');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$prefix: $text')));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final previousDateTitle = dateKeyFor(_selectedDate);
      setState(() {
        _selectedDate = picked;
        if (!_isEditing && _titleController.text == previousDateTitle) {
          _titleController.text = dateKeyFor(picked);
        }
      });
    }
  }

  Future<void> _openQuickSetDialog(
      {int? index,
      GymSetEntry? seed,
      List<String> recentExercises = const []}) async {
    if (_setEditorOpen || _savingWorkout) return;
    _setEditorOpen = true;
    try {
      await _showSetEditor(
          index: index, seed: seed, recentExercises: recentExercises);
    } finally {
      _setEditorOpen = false;
    }
  }

  Future<void> _showSetEditor({
    int? index,
    GymSetEntry? seed,
    List<String> recentExercises = const [],
  }) async {
    final strings = stringsFor(ref);
    final existingSet = index == null ? seed : _draftSets[index];
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

    var submitted = false;
    String? validation;
    final en = strings.isEnglish;
    final theme = Theme.of(context);
    void shiftLoad(double delta) {
      final raw = double.tryParse(weightController.text.replaceAll(',', '.'));
      final current = raw != null && raw.isFinite ? raw : 0.0;
      weightController.text = math.max(0, current + delta).toString();
    }

    void shiftReps(int delta) {
      repsController.text = math
          .max(1, (int.tryParse(repsController.text) ?? 0) + delta)
          .toString();
    }

    final route = DialogRoute<_SetDialogResult>(
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

            void submit({bool rest = false}) {
              if (submitted) return;
              final name = (useCustomExercise
                      ? exerciseController.text
                      : selectedExercise ?? '')
                  .trim();
              final group = (selectedMuscleGroup ?? '').trim();
              final count =
                  index == null ? int.tryParse(setsController.text.trim()) : 1;
              final reps = int.tryParse(repsController.text.trim());
              final kg = double.tryParse(
                  weightController.text.trim().replaceAll(',', '.'));
              if (name.isEmpty ||
                  group.isEmpty ||
                  count == null ||
                  count < 1 ||
                  count > 100 ||
                  reps == null ||
                  reps < 1 ||
                  kg == null ||
                  !kg.isFinite ||
                  kg < 0) {
                setDialogState(() => validation = en
                    ? 'Choose an exercise, enter 1–100 sets, positive reps and a valid load.'
                    : 'Elige un ejercicio e ingresa de 1 a 100 series, repeticiones positivas y una carga válida.');
                return;
              }
              submitted = true;
              Navigator.of(dialogContext).pop(_SetDialogResult(
                  set: GymSetEntry(
                      exerciseName: name,
                      muscleGroup: group,
                      setNumber: 0,
                      reps: reps,
                      weightKg: kg,
                      rpe: selectedRpe),
                  setsCount: count,
                  startRest: rest));
            }

            return WorkoutEditorDialog(
              title: index == null
                  ? (en ? 'Add & log set' : 'Añadir serie')
                  : strings.editSetButton,
              content: Column(
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
                    isExpanded: true,
                    items: exerciseOptions
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
                    decoration: InputDecoration(
                      labelText: strings.exerciseNameLabel,
                      hintText: strings.selectExerciseLabel,
                    ),
                    onChanged: selectedMuscleGroup == null
                        ? null
                        : (value) {
                            setDialogState(() {
                              selectedExercise = value;
                              useCustomExercise = value == _customExerciseValue;
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
                  if (index == null &&
                      seed == null &&
                      recentExercises.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        strings.recentExercisesTitle,
                        style: theme.textTheme.bodySmall,
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
                  DecoratedBox(
                      decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(children: [
                            if (index == null) ...[
                              TextField(
                                  controller: setsController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                      labelText: strings.setsLabel)),
                              const SizedBox(height: 10)
                            ],
                            Row(children: [
                              Expanded(
                                  child: TextField(
                                      controller: repsController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                          labelText: strings.repsLabel))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: TextField(
                                      controller: weightController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      decoration: InputDecoration(
                                          labelText: strings.setWeightLabel))),
                            ]),
                            const SizedBox(height: 4),
                            Wrap(spacing: 5, children: [
                              for (final delta in [-5.0, -2.5, 2.5, 5.0])
                                ActionChip(
                                    label: Text(
                                        '${delta > 0 ? '+' : ''}$delta kg'),
                                    onPressed: () => shiftLoad(delta)),
                              for (final delta in [-1, 1, 2])
                                ActionChip(
                                    label: Text(
                                        '${delta > 0 ? '+' : ''}$delta reps'),
                                    onPressed: () => shiftReps(delta))
                            ]),
                          ]))),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.rpeLabel,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      strings.rpeHelpLabel,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 8),
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
              actions: [
                if (validation != null)
                  Text(validation!,
                      style: const TextStyle(color: AppTheme.danger)),
                if (index == null && _restTargetDuration > Duration.zero)
                  OutlinedButton.icon(
                      onPressed: () => submit(rest: true),
                      icon: const Icon(Icons.timer_outlined),
                      label: Text(en
                          ? 'Save & start ${_restTargetDuration.inSeconds}s rest'
                          : 'Guardar y descansar ${_restTargetDuration.inSeconds}s')),
                FilledButton(
                    onPressed: submit,
                    child: Text(index == null
                        ? strings.addButton
                        : strings.updateSetButton)),
              ],
            );
          },
        );
      },
    );
    final result = await Navigator.of(context, rootNavigator: true).push(route);
    if (result != null && mounted) {
      _applySetDialogResult(result, index: index);
      if (result.startRest && _restTargetDuration > Duration.zero) {
        if (_isRestRunning) _finishRestCycle();
        _startRestTimer();
      }
    }
    await route.completed;
    for (final controller in [
      exerciseController,
      repsController,
      setsController,
      weightController
    ]) {
      controller.dispose();
    }
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
    final name = _draftSets
            .where((entry) =>
                routineNameKey(entry.exerciseName) ==
                routineNameKey(result.set.exerciseName))
            .firstOrNull
            ?.exerciseName ??
        result.set.exerciseName;
    setState(() {
      if (index == null) {
        for (var i = 0; i < result.setsCount; i++) {
          _draftSets.add(
            GymSetEntry(
              exerciseName: name,
              muscleGroup: result.set.muscleGroup,
              setNumber: _draftSets.length + 1,
              reps: result.set.reps,
              weightKg: result.set.weightKg,
              rpe: result.set.rpe,
            ),
          );
        }
      } else {
        _draftSets[index] = GymSetEntry(
            exerciseName: name,
            muscleGroup: result.set.muscleGroup,
            setNumber: index + 1,
            reps: result.set.reps,
            weightKg: result.set.weightKg,
            rpe: result.set.rpe);
      }
      _reindexSets();
    });
  }

  void _removeSet(int index) {
    setState(() {
      final shifted = _completed
          .where((i) => i != index)
          .map((i) => i > index ? i - 1 : i)
          .toList();
      _completed
        ..clear()
        ..addAll(shifted);
      _draftSets.removeAt(index);
      _reindexSets();
    });
  }

  void _updateSet(int index, {int? reps, double? weightKg}) {
    final existing = _draftSets[index];
    setState(() {
      _draftSets[index] = GymSetEntry(
        exerciseName: existing.exerciseName,
        muscleGroup: existing.muscleGroup,
        setNumber: existing.setNumber,
        reps: reps ?? existing.reps,
        weightKg: weightKg ?? existing.weightKg,
        rpe: existing.rpe,
      );
    });
  }

  Future<void> _editWeeklyRoutine() async {
    if (_routineEditorOpen || _savingWorkout) return;
    _routineEditorOpen = true;
    try {
      final result = await context.push<List<WorkoutRoutineBlock>>(
          '/workout/routine',
          extra: (date: _selectedDate, canApply: !_isEditing));
      if (mounted && result != null) await _loadRoutine(result);
    } finally {
      _routineEditorOpen = false;
    }
  }

  List<WorkoutRoutineExercise> _pendingRoutineExercises(
      List<WorkoutRoutineBlock> blocks) {
    final existing = {
      for (final set in _draftSets) routineNameKey(set.exerciseName),
    };
    return [
      for (final block in blocks)
        for (final exercise in block.exercises)
          if (!existing.contains(routineNameKey(exercise.exerciseName)) ||
              _routineTarget(_appliedRoutineTargets[
                      routineNameKey(exercise.exerciseName)]) !=
                  _routineTarget(exercise))
            exercise,
    ];
  }

  (String, int, int, double)? _routineTarget(
          WorkoutRoutineExercise? exercise) =>
      exercise == null
          ? null
          : (
              exercise.muscleGroup,
              exercise.sets,
              exercise.reps,
              exercise.weightKg
            );

  Future<void> _loadRoutine(List<WorkoutRoutineBlock> blocks) async {
    if (_isEditing || _savingWorkout || _setEditorOpen || _loadingRoutine) {
      return;
    }
    final strings = stringsFor(ref);
    if (duplicateRoutineMovements(blocks).isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(strings.isEnglish
              ? 'Fix repeated movements in the weekly routine before applying.'
              : 'Corrige los movimientos repetidos de la rutina antes de aplicarla.')));
      return;
    }
    final pending = _pendingRoutineExercises(blocks);
    if (pending.isEmpty) return;
    final keys = pending.map((e) => routineNameKey(e.exerciseName)).toSet();
    final replaces =
        _draftSets.any((s) => keys.contains(routineNameKey(s.exerciseName)));
    final en = strings.isEnglish;
    _loadingRoutine = true;
    try {
      if (replaces) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => WorkoutEditorDialog(
            title: en ? 'Use weekly routine' : 'Usar rutina semanal',
            content: Text(en
                ? 'For matching exercises, the routine will replace the current sets and their completion marks. Extra exercises will stay.'
                : 'En los ejercicios que coincidan, la rutina reemplazará las series actuales y sus marcas de completado. Los ejercicios adicionales se conservan.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(strings.cancelButton)),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(en ? 'Load routine' : 'Cargar rutina')),
            ],
          ),
        );
        if (!mounted || confirmed != true) return;
      }
      setState(() {
        final kept = <GymSetEntry>[];
        final completed = <int>{};
        for (final (index, set) in _draftSets.indexed) {
          if (keys.contains(routineNameKey(set.exerciseName))) continue;
          if (_completed.contains(index)) completed.add(kept.length);
          kept.add(set);
        }
        _completed
          ..clear()
          ..addAll(completed);
        _draftSets
          ..clear()
          ..addAll(kept);
        for (final exercise in pending) {
          _appliedRoutineTargets[routineNameKey(exercise.exerciseName)] =
              exercise;
          for (var set = 0; set < exercise.sets; set++) {
            _draftSets.add(GymSetEntry(
              exerciseName: exercise.exerciseName.trim(),
              muscleGroup: exercise.muscleGroup,
              setNumber: _draftSets.length + 1,
              reps: exercise.reps,
              weightKg: exercise.weightKg,
            ));
          }
        }
        _stepRevision++;
        _reindexSets();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(en ? 'Daily routine loaded.' : 'Se cargó la rutina del día.'),
      ));
    } finally {
      _loadingRoutine = false;
      if (mounted) setState(() {});
    }
  }

  Map<String, List<MapEntry<int, GymSetEntry>>> _groupDraftSets() {
    final grouped = <String, List<MapEntry<int, GymSetEntry>>>{};
    final displayNames = <String, String>{};
    for (var index = 0; index < _draftSets.length; index++) {
      final set = _draftSets[index];
      final label = displayNames.putIfAbsent(
          routineNameKey(set.exerciseName), () => set.exerciseName);
      grouped.putIfAbsent(label, () => []).add(MapEntry(index, set));
    }
    return grouped;
  }

  void _duplicateLastSet(GymSetEntry last) {
    final strings = stringsFor(ref);
    if (_draftSets.isEmpty) {
      return;
    }

    final lastSet = last;
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
    if (_savingWorkout || _setEditorOpen || _loadingRoutine) return;
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
    final routine = _isEditing
        ? null
        : ref.read(weeklyWorkoutRoutineProvider).activeRoutine;
    final date = _selectedDate;
    final sets = List<GymSetEntry>.of(_draftSets);

    setState(() => _savingWorkout = true);
    try {
      if (_isEditing) {
        await notifier.updateSession(
          id: widget.session!.id,
          title: title,
          date: date,
          durationMinutes: effectiveDurationMinutes,
          totalDurationSeconds: effectiveTotalDuration.inSeconds,
          activeDurationSeconds: effectiveActiveDuration.inSeconds,
          restDurationSeconds: effectiveRestDuration.inSeconds,
          estimatedActiveCalories: calories,
          sets: sets,
          notes: notes,
        );
      } else {
        await notifier.addSession(
          submissionId: _submissionId ??= newSubmissionId(),
          title: title,
          date: date,
          durationMinutes: effectiveDurationMinutes,
          totalDurationSeconds: effectiveTotalDuration.inSeconds,
          activeDurationSeconds: effectiveActiveDuration.inSeconds,
          restDurationSeconds: effectiveRestDuration.inSeconds,
          estimatedActiveCalories: calories,
          sets: sets,
          notes: notes,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _savingWorkout = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.remoteSaveFailedMessage)));
      }
      return;
    }
    if (!mounted) {
      return;
    }

    final templateMessage = routine == null
        ? null
        : await _offerExtraExercises(routine, date, sets, strings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          templateMessage ??
              (_isEditing
                  ? strings.workoutUpdatedMessage
                  : strings.workoutSavedMessage),
        ),
      ),
    );
    context.go('/dashboard');
  }

  Future<String?> _offerExtraExercises(WeeklyWorkoutRoutine routine,
      DateTime date, List<GymSetEntry> sets, AppStrings strings) async {
    final existing = {
      ..._appliedRoutineTargets.keys,
      for (final block in routine.blocksFor(date))
        for (final exercise in block.exercises)
          routineNameKey(exercise.exerciseName),
    };
    final groups = <String, List<GymSetEntry>>{};
    for (final set in sets) {
      final key = routineNameKey(set.exerciseName);
      if (!existing.contains(key)) groups.putIfAbsent(key, () => []).add(set);
    }
    if (groups.isEmpty) return null;
    final en = strings.isEnglish;
    final extras = [
      for (final group in groups.values)
        WorkoutRoutineExercise(
          exerciseName: group.first.exerciseName,
          muscleGroup: group.first.muscleGroup,
          sets: group.length,
          reps: group.first.reps,
          weightKg: group.first.weightKg,
        ),
    ];
    final selected = <int>{};
    final day = strings.weekdayLabel(date.weekday);
    final add = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => WorkoutEditorDialog(
          title: en ? 'Add to $day routine?' : '¿Añadir a la rutina de $day?',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(en
                  ? 'Workout saved. All exercises count toward Progress. Select any extras to add to ${routine.name}. The plan uses the first set’s reps and weight as targets.'
                  : 'Entrenamiento guardado. Todos los ejercicios cuentan para Progreso. Elegí cuáles añadir a ${routine.name}. La plantilla usa las repeticiones y el peso de la primera serie como objetivo.'),
              for (final (index, exercise) in extras.indexed)
                CheckboxListTile(
                  value: selected.contains(index),
                  contentPadding: EdgeInsets.zero,
                  title: Text(exercise.exerciseName),
                  subtitle: Text(
                      '${exercise.sets} × ${exercise.reps} · ${exercise.weightKg} kg'),
                  onChanged: (checked) => setDialogState(() {
                    if (checked == true) {
                      selected.add(index);
                    } else {
                      selected.remove(index);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(en ? 'Workout only' : 'Solo entrenamiento'),
            ),
            FilledButton(
              onPressed:
                  selected.isEmpty ? null : () => Navigator.pop(context, true),
              child: Text(en ? 'Add to routine' : 'Añadir a rutina'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || add != true) return null;
    try {
      final added = await ref
          .read(weeklyWorkoutRoutineProvider.notifier)
          .appendDayExercises(routine.id, date.weekday, [
        for (final (index, exercise) in extras.indexed)
          if (selected.contains(index)) exercise,
      ]);
      if (added) {
        return en
            ? 'Workout saved and weekly routine updated.'
            : 'Entrenamiento guardado y rutina semanal actualizada.';
      }
      return en
          ? 'Workout saved. No new exercises were added to the routine.'
          : 'Entrenamiento guardado. No se añadieron ejercicios nuevos a la rutina.';
    } catch (_) {
      return en
          ? 'Workout saved. Could not update the weekly routine.'
          : 'Entrenamiento guardado. No se pudo actualizar la rutina semanal.';
    }
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
      });

      if (_restTargetDuration > Duration.zero &&
          _restCurrentElapsed >= _restTargetDuration) {
        unawaited(_maybePlayRestAlert());
        _finishRestCycle();
        return;
      }

      _maybePlayRestAlert();
    });
    setState(() {});
  }

  void _finishRestCycle() {
    _restTimer?.cancel();
    _restTimer = null;
    setState(() {
      _restAccumulated += _restCurrentElapsed;
      _restCurrentElapsed = Duration.zero;
    });
  }

  void _resetRestTimer() {
    _restTimer?.cancel();
    _restTimer = null;
    setState(() {
      _restAccumulated = Duration.zero;
      _restCurrentElapsed = Duration.zero;
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
    await _playCurrentRestAlertSound(repetitions: 2);

    if (_restVibrationEnabled) {
      await _triggerRestVibration();
    }
  }

  Future<void> _playCurrentRestAlertSound({int repetitions = 1}) async {
    _restAlertPlayer ??= AudioPlayer();

    try {
      await _restAlertPlayer!.stop();
      await _restAlertPlayer!.setAudioContext(_restAlertAudioContext);
      await _restAlertPlayer!.setVolume(_restAlertVolume);

      for (var index = 0; index < repetitions; index++) {
        await _restAlertPlayer!.play(
          BytesSource(
            _restAlertSoundBytes[_restAlertSound]!,
            mimeType: 'audio/wav',
          ),
        );

        if (index < repetitions - 1) {
          await _restAlertPlayer!.onPlayerComplete.first;
        }
      }
    } catch (_) {
      // No bloquear el registro del entrenamiento si el sonido falla.
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
    if (_isRestRunning && !_isRestOverTarget) return _formatRestDuration(delta);
    final sign = _isRestOverTarget ? '+' : '-';
    return '$sign${_formatRestDuration(delta)}';
  }
}

class _SetDialogResult {
  const _SetDialogResult({
    required this.set,
    required this.setsCount,
    this.startRest = false,
  });

  final GymSetEntry set;
  final int setsCount;
  final bool startRest;
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

class _ExerciseSetCard extends StatelessWidget {
  const _ExerciseSetCard({
    required this.exerciseName,
    required this.sets,
    required this.strings,
    required this.completed,
    required this.revision,
    required this.restSeconds,
    required this.expandedInitially,
    required this.previous,
    required this.onStep,
    required this.onComplete,
    required this.onToggle,
    required this.onAdd,
    required this.onRepeat,
    required this.onNote,
    required this.onSetChanged,
    required this.onEdit,
    required this.onRemove,
  });

  final AppStrings strings;
  final Set<int> completed;
  final int revision, restSeconds;
  final bool expandedInitially;
  final GymSetEntry? previous;
  final void Function(int, {int? reps, double? weightKg}) onStep;
  final ValueChanged<int> onComplete, onToggle;
  final VoidCallback onAdd;
  final VoidCallback onRepeat;
  final void Function(int, String) onNote;
  final String exerciseName;
  final List<MapEntry<int, GymSetEntry>> sets;
  final void Function(int index, {int? reps, double? weightKg}) onSetChanged;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final en = strings.isEnglish;
    final working = sets.where((e) => !completed.contains(e.key)).firstOrNull;
    return Container(
      key: ValueKey('exercise-group-$exerciseName'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: expandedInitially,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(sets.first.value.muscleGroup,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppTheme.primary)),
          Text(exerciseName, style: theme.textTheme.titleLarge)
        ]),
        subtitle: Text(
          _setSummary(),
          style: theme.textTheme.bodySmall,
        ),
        children: [
          if (previous != null)
            Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    '${en ? "Last session" : "Sesión anterior"}: ${previous!.weightKg} kg × ${previous!.reps}',
                    style: theme.textTheme.bodySmall)),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(children: [
            for (final label in [
              'SET',
              en ? 'PREV.' : 'ANT.',
              'KG',
              'REPS',
              'RPE',
              en ? 'LOG' : 'REG.'
            ])
              Expanded(
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall))
          ]),
          ...sets.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _QuickSetRow(
                key: ValueKey('${entry.key}-$revision'),
                ordinal: sets.indexOf(entry) + 1,
                previous: previous,
                logged: completed.contains(entry.key),
                toggle: () => onToggle(entry.key),
                en: en,
                set: entry.value,
                onRepsChanged: (value) =>
                    onSetChanged(entry.key, reps: value.toInt()),
                onWeightChanged: (value) =>
                    onSetChanged(entry.key, weightKg: value.toDouble()),
                onEdit: () => onEdit(entry.key),
                onRemove: () => onRemove(entry.key),
              ),
            ),
          ),
          if (working != null)
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          '${en ? 'Working set' : 'Serie activa'} · ${sets.indexOf(working) + 1}',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: _Stepper(
                                label: 'KG',
                                value: _formatWeight(working.value.weightKg),
                                less: () => onStep(working.key,
                                    weightKg: math.max(
                                        0, working.value.weightKg - 2.5)),
                                more: () => onStep(working.key,
                                    weightKg: working.value.weightKg + 2.5))),
                        const SizedBox(width: 6),
                        Expanded(
                            child: _Stepper(
                                label: 'REPS',
                                value: '${working.value.reps}',
                                less: () => onStep(working.key,
                                    reps: math.max(1, working.value.reps - 1)),
                                more: () => onStep(working.key,
                                    reps: working.value.reps + 1)))
                      ]),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                          onPressed: () => onComplete(working.key),
                          icon: const Icon(Icons.check),
                          label: Text(restSeconds == 0
                              ? (en ? 'Complete set' : 'Completar serie')
                              : (en
                                  ? 'Complete set & start ${restSeconds}s rest'
                                  : 'Completar serie y descansar ${restSeconds}s'))),
                      Wrap(children: [
                        for (final tag in [
                          en ? 'Warm-up' : 'Calentamiento',
                          en ? 'Drop set' : 'Descendente',
                          ''
                        ])
                          TextButton(
                              onPressed: () => onNote(working.key, tag),
                              child: Text(tag.isEmpty
                                  ? (en ? 'Set note' : 'Nota')
                                  : tag))
                      ])
                    ])),
          Wrap(alignment: WrapAlignment.spaceBetween, children: [
            TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(strings.addSetButton)),
            TextButton.icon(
                onPressed: onRepeat,
                icon: const Icon(Icons.replay),
                label: Text(strings.repeatLastSetButton))
          ]),
        ],
      ),
    );
  }

  String _setSummary() {
    final firstSet = sets.first.value;
    final allSetsMatch = sets.every(
      (entry) =>
          entry.value.weightKg == firstSet.weightKg &&
          entry.value.reps == firstSet.reps,
    );
    final count = sets.length == 1 ? '1 set' : '${sets.length} sets';
    if (!allSetsMatch) {
      return count;
    }
    return '$count · ${_formatWeight(firstSet.weightKg)} kg × ${firstSet.reps} reps';
  }

  String _formatWeight(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : '$value';
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper(
      {required this.label,
      required this.value,
      required this.less,
      required this.more});
  final String label, value;
  final VoidCallback less, more;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Row(children: [
          IconButton(
              tooltip: '− $label',
              onPressed: less,
              icon: const Icon(Icons.remove, size: 16),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
              padding: EdgeInsets.zero),
          Expanded(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      style: Theme.of(context).textTheme.titleMedium))),
          IconButton(
              tooltip: '+ $label',
              onPressed: more,
              icon: const Icon(Icons.add, size: 16),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
              padding: EdgeInsets.zero)
        ])
      ]));
}

class _QuickSetRow extends StatelessWidget {
  const _QuickSetRow({
    super.key,
    required this.ordinal,
    required this.previous,
    required this.logged,
    required this.toggle,
    required this.en,
    required this.set,
    required this.onRepsChanged,
    required this.onWeightChanged,
    required this.onEdit,
    required this.onRemove,
  });

  final int ordinal;
  final GymSetEntry? previous;
  final bool logged, en;
  final VoidCallback toggle;
  final GymSetEntry set;
  final ValueChanged<int> onRepsChanged;
  final ValueChanged<double> onWeightChanged;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
              child: PopupMenuButton<_SetAction>(
            padding: EdgeInsets.zero,
            tooltip: 'Set options',
            child: Center(
                child: Text('$ordinal ⋮', style: theme.textTheme.titleSmall)),
            onSelected: (action) {
              if (action == _SetAction.edit) {
                onEdit();
              } else {
                onRemove();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: _SetAction.edit, child: Text('More details')),
              PopupMenuItem(
                  value: _SetAction.remove, child: Text('Delete set')),
            ],
          )),
          Expanded(
              child: Text(
                  previous == null
                      ? '—'
                      : '${_formatWeight(previous!.weightKg)} × ${previous!.reps}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall)),
          Expanded(
            child: _InlineNumberField(
              label: 'KG',
              setNumber: set.setNumber,
              initialValue: _formatWeight(set.weightKg),
              decimal: true,
              onChanged: (value) => onWeightChanged(value.toDouble()),
            ),
          ),
          Expanded(
            child: _InlineNumberField(
              label: 'REPS',
              setNumber: set.setNumber,
              initialValue: '${set.reps}',
              onChanged: (value) => onRepsChanged(value.toInt()),
            ),
          ),
          Expanded(
              child: Text(set.rpe?.toString() ?? '—',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall)),
          Expanded(
              child: IconButton(
                  key: ValueKey('log-set-${set.setNumber}'),
                  tooltip: en ? 'Toggle set completion' : 'Marcar serie',
                  onPressed: toggle,
                  icon: Icon(
                      logged
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: logged ? AppTheme.primary : null,
                      size: 20))),
        ],
      ),
    );
  }

  String _formatWeight(double value) {
    return value == value.roundToDouble() ? value.toInt().toString() : '$value';
  }
}

class _InlineNumberField extends StatelessWidget {
  const _InlineNumberField({
    required this.label,
    required this.setNumber,
    required this.initialValue,
    required this.onChanged,
    this.decimal = false,
  });

  final String label;
  final int setNumber;
  final String initialValue;
  final bool decimal;
  final ValueChanged<num> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('quick-set-$setNumber-$label'),
      initialValue: initialValue,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      ),
      onChanged: (value) {
        final parsed = decimal
            ? double.tryParse(value.replaceAll(',', '.'))
            : int.tryParse(value);
        if (parsed != null && parsed >= 0) {
          onChanged(parsed);
        }
      },
    );
  }
}

enum _SetAction { edit, remove }

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
                        formatDisplayDateKey(session.dateKey),
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
