# Manual workout · `/workout/manual`

Design a screen usable between sets in a gym. Separate **the session being logged** from **the weekly plan**.

- **Session details:** date and editable title; new sessions initially use the date. Preserve a customized title on date change. Put optional notes, duration, and estimated calories behind secondary controls.
- **Timer card:** show independent workout and rest timers with total, active, and rest time. Rest starts manually, stops at its target, and never restarts merely because a set changed. Group duration, sound profile, volume, and vibration in rest settings.
- **Logged sets:** group sets inside collapsed exercise cards. Expand for inline KG and REPS, detailed editing, and removal. Provide Add set and Repeat last set where applicable.
- **Routine access:** show “Edit weekly routine” as a labeled action. On a new empty workout, offer to load the active routine for the selected weekday only when blocks exist.
- **Completion and history:** save or update the session, then show dated history cards with available duration, set and repetition summaries, and edit/delete actions. Preserve a useful empty state. Guest workouts are local; account workouts support remote storage.
