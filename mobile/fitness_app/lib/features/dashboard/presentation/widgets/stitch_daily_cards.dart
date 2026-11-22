import 'package:flutter/material.dart';
import '../../../../shared/app_language.dart';
import '../../../food/domain/manual_food_entry.dart';
import '../../../workout/domain/manual_workout_session.dart';
import '../dashboard_theme.dart' as design;

typedef Ink = design.DashboardTheme;

class DailyPanel extends StatelessWidget {
  const DailyPanel(
      {super.key,
      required this.label,
      required this.title,
      required this.children,
      this.icon,
      this.action,
      this.accent = Ink.primary});
  final String label, title;
  final IconData? icon;
  final Widget? action;
  final Color accent;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              if (icon != null) ...[
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 20, color: accent)),
                const SizedBox(width: 8)
              ],
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall),
                    Text(title,
                        style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 24 / 18))
                  ])),
              if (action != null) action!
            ]),
            for (final w in children) ...[const SizedBox(height: 16), w]
          ])));
}

class TrainingPanel extends StatelessWidget {
  const TrainingPanel(
      {super.key,
      required this.strings,
      required this.session,
      required this.open});
  final AppStrings strings;
  final ManualWorkoutSession? session;
  final VoidCallback open;
  @override
  Widget build(BuildContext context) {
    final s = session, en = strings.isEnglish;
    final counts = <String, int>{};
    for (final set in s?.sets ?? []) {
      counts.update(set.exerciseName, (v) => v + 1, ifAbsent: () => 1);
    }
    return DailyPanel(
        icon: Icons.fitness_center,
        label: strings.todaysActivityTitle,
        title: s?.title ?? strings.noWorkoutsYet,
        action: s == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Ink.primary.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(16)),
                child: Text(en ? '✓ Completed' : '✓ Completado',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Ink.primary))),
        children: [
          if (s != null) ...[
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(alignment: Alignment.bottomLeft, children: [
                  Image.asset('assets/stitch/training.jpg',
                      width: double.infinity, height: 128, fit: BoxFit.cover),
                  Container(
                      height: 128,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                            Ink.backgroundSecondary,
                            Colors.transparent
                          ]))),
                  Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                          '${en ? 'Session logged' : 'Sesión registrada'} · ${TimeOfDay.fromDateTime(s.createdAt).format(context)}'))
                ])),
            Row(children: [
              for (final m in [
                (
                  Icons.schedule,
                  strings.totalGymTimeLabel,
                  s.totalDurationSeconds,
                  Ink.charcoal
                ),
                (
                  Icons.directions_run,
                  strings.activeTrainingTimeLabel,
                  s.activeDurationSeconds,
                  Ink.primary
                ),
                (
                  Icons.pause_circle_outline,
                  strings.totalRestTimeLabel,
                  s.restDurationSeconds,
                  Ink.warning
                )
              ])
                Expanded(
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                            color: Ink.backgroundSecondary,
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(children: [
                          Icon(m.$1, size: 18, color: m.$4),
                          Text(m.$2,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall),
                          Text('${m.$3 ~/ 60} m',
                              style: TextStyle(fontSize: 18, color: m.$4))
                        ])))
            ]),
            Wrap(spacing: 6, runSpacing: 4, children: [
              for (final e in counts.entries)
                DecoratedBox(
                    decoration: BoxDecoration(
                        color: Ink.surfaceMuted,
                        borderRadius: BorderRadius.circular(6)),
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text('${e.key} · ${e.value} sets',
                            style: Theme.of(context).textTheme.labelSmall)))
            ])
          ],
          FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                  backgroundColor: Ink.surfaceMuted,
                  foregroundColor: Ink.charcoal),
              onPressed: open,
              icon: Icon(s == null ? Icons.play_arrow : Icons.chevron_right),
              label: Text(s == null
                  ? strings.startWorkoutButton
                  : strings.editWorkoutButton))
        ]);
  }
}

class DailyLogsPanel extends StatelessWidget {
  const DailyLogsPanel(
      {super.key,
      required this.meals,
      required this.workouts,
      required this.strings,
      required this.progress});
  final List<ManualFoodEntry> meals;
  final List<ManualWorkoutSession> workouts;
  final AppStrings strings;
  final VoidCallback progress;
  @override
  Widget build(BuildContext context) {
    final en = strings.isEnglish;
    final items = [
      for (final m in meals)
        (
          m.createdAt,
          m.name,
          '${m.mealType} · ${TimeOfDay.fromDateTime(m.createdAt).format(context)}',
          '${m.calories} kcal',
          '${m.proteinGrams}g ${strings.protein}',
          Icons.restaurant
        ),
      for (final s in workouts)
        (
          s.createdAt,
          s.title,
          TimeOfDay.fromDateTime(s.createdAt).format(context),
          '+${s.estimatedActiveCalories} kcal',
          '${s.durationMinutes} min',
          Icons.fitness_center
        )
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return DailyPanel(
        label: en ? 'Activity stream' : 'Actividad',
        title: en ? "Today’s Logs" : 'Registros de hoy',
        action: Text('${items.length} ${en ? 'events' : 'eventos'}'),
        children: [
          if (items.isEmpty) Text(strings.noDailySummaryYet),
          for (final i in items.take(3))
            Container(
                decoration: BoxDecoration(
                    color: Ink.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                    dense: true,
                    leading: Icon(i.$6, size: 20, color: Ink.primary),
                    title: Text(i.$2,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(i.$3),
                    trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(i.$4),
                          Text(i.$5,
                              style: Theme.of(context).textTheme.labelSmall)
                        ]))),
          TextButton.icon(
              onPressed: progress,
              icon: const Icon(Icons.trending_up),
              label: Text(strings.openProgressButton))
        ]);
  }
}
