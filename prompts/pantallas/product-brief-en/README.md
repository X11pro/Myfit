# Myfit — screen prompts

Each linked file is an English prompt that can be copied independently into a design tool. Route names describe the current app. Dialogs and embedded flows are separate briefs for convenience, not additional navigation destinations.

| Area | Screen prompts, in journey order |
| --- | --- |
| Entry and identity | [Welcome](01-welcome.md) → [Email sign-in](02-sign-in.md) → [Verify code](03-verify-code.md) → [Energy profile](04-energy-profile.md) |
| Home | [Daily dashboard](05-dashboard.md) → [Log weight dialog](06-log-weight.md) |
| Nutrition | [Add or edit a meal](07-meal-entry.md) → [Barcode scanner](08-barcode-scanner.md) → [Lookup result](09-barcode-result.md) or [Meal photo review](10-meal-photo.md); [Food gallery](11-food-gallery.md) and [Shared catalog](12-shared-catalog.md) |
| Training | [Manual workout](13-manual-workout.md) → [Add or edit sets](14-set-editor.md) or [Weekly routines](15-weekly-routines.md) |
| Review and account | [Progress](16-progress.md); [Account and data controls](17-account.md) |
| Chrome companion | [Connection settings](18-extension-settings.md) → [OTP sign-in](19-extension-sign-in.md) → [Routine builder](20-extension-builder.md) |

**Shared design context.** Myfit is a guest-first Flutter app for Android and iOS. Its four main destinations are Home, Workout, Nutrition, and Progress. Use the current dark palette: background `#10151B`, secondary background `#171E26`, card `#1C252E`, raised control `#27323D`, border `#3B4854`, primary text `#F3F6F8`, secondary text `#BCC9D1`, mint action `#9EE8CC`, warning `#FFBA87`, error `#FFA5A5`. Keep English and Spanish labels localizable; use DD/MM/YYYY for visible English dates. Pair color with labels, preserve keyboard focus, and accommodate large text. Use illustrative data only when clearly identified.

**Service boundaries.** Riverpod coordinates UI state, go_router handles routes, and SharedPreferences supports guest data and local caches. Supabase supplies email OTP, PostgreSQL with row-level security, photo storage, and backend functions. Cloud support varies by feature; offline conflict handling and guest-to-account migration are not universally guaranteed. HealthKit, Health Connect, wearable imports, advanced export, automated coaching, NEAT modeling, and supplement advice are roadmap items. Keep them out of current screen mockups.

**Expected deliverable.** For each selected screen, show its layout, the user's primary task, supporting controls, transitions, and relevant empty, loading, error, and success states. Distinguish what exists from any proposed improvement. The briefs describe the product, not proof of production readiness.
