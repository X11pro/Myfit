# Weekly routine library · `/workout/routine`

Design the screen reached via Manual workout → Edit weekly routine. It edits reusable plans, not completed workout history.

- **Library controls:** New routine, Reload routines, named routine selector, rename, and delete. Distinguish the active routine from the weekday being edited.
- **Seven day cards:** Monday through Sunday, each showing its planned blocks or an empty state. Single exercises, supersets, and trisets contain one, two, and three exercises respectively. For each exercise show name, muscle group, sets, reps, and kg; expose add, edit, and remove actions in context.
- **Using a plan:** a new empty workout can load the active plan for its selected day. Scheduling a block must not create a completed session.
- **Sync:** Flutter retains a local cache. Authenticated users share one `public.workout_routines` document with the Chrome extension under Supabase row-level security. Reload routines reads the same account’s remote library. Sync is manual rather than live, simultaneous edits are last-write-wins, and end-to-end QA is pending. Do not depict guaranteed conflict resolution.
