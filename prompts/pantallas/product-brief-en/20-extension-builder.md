# Chrome Routine Builder · signed-in popup

Design a compact desktop editor for the same weekly routine library used by Myfit on mobile. Organize it from account to routine to day to individual exercise:

1. **Header and sync row:** product title, signed-in email, Sign out, prominent Save changes, and a readable status region. Distinguish editing the draft from a confirmed save.
2. **Routine card:** active routine selector, editable name, New routine, and a separate destructive Delete action.
3. **Week navigation:** seven weekday tabs with a visible selected state. Follow with the full day name and Add exercise block.
4. **Block cards:** choose a single exercise, superset, or triset. Group exercise name and muscle with sets, reps, and kg for each exercise. Keep remove controls associated with the correct block or exercise. Wrap inputs at popup widths rather than hiding units.
5. **Empty and feedback states:** a day with no exercises offers a clear next action. Show save errors separately from sign-in problems; do not signal success before the server responds.

Use the mobile app’s dark layered surfaces, mint action, visible focus rings, and soft red destructive actions. Save writes to the current user’s Supabase routine document. To see a desktop change on mobile, use the same project and account, then Manual workout → Edit weekly routine → Reload routines. Do not claim real-time updates or automatic cross-device merging.
