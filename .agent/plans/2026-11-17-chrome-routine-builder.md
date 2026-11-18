# ExecPlan: Chrome routine builder synchronization

## Goal

Provide a Chrome extension where an authenticated Myfit user can create and edit weekly training routines on desktop, then use the same routines in the Flutter application.

## Current state

- Flutter stores `WorkoutRoutineLibrary` only in SharedPreferences.
- Supabase authentication uses email OTP and row-level security.
- There is no remote routine table or browser client.

## Relevant documents

- `docs/product/fitness_product_plan.md`
- `AGENTS.md`
- `mobile/fitness_app/lib/features/workout/domain/weekly_workout_routine.dart`
- `mobile/fitness_app/lib/features/workout/application/weekly_workout_routine_controller.dart`

## Non-goals

- Importing routines from third-party websites.
- Recording completed workouts from the extension.
- Using a Supabase service-role key in a browser client.
- Realtime subscriptions in the first release; reads occur when Flutter initializes and after every local save.

## User stories

- As a signed-in user, I can enter my Supabase URL and anonymous key in the extension once.
- I can request and verify the same email OTP used by Myfit.
- I can create, edit, select and delete routines with exercises for each weekday.
- When I save, the Flutter app can load the same library for that account.

## Technical design

- Add `public.workout_routines` with one JSONB library document per authenticated user.
- Use a `version` timestamp (`updated_at`) with RLS policies restricted to `auth.uid()`.
- Add remote load/upsert to Flutter's routine notifier. Local storage remains the offline cache and guest implementation.
- Create a Manifest V3 extension under `extensions/myfit-routine-builder` with no external dependencies. It uses Supabase REST/Auth endpoints directly and stores the browser session in `chrome.storage.local`.
- The extension popup is a focused routine editor. Its Options page holds the Supabase public configuration.

## Data model

`workout_routines`:

- `user_id uuid primary key` referencing `auth.users`
- `library jsonb not null`
- `created_at timestamptz`
- `updated_at timestamptz`

The JSON is the existing `WorkoutRoutineLibrary.toJson()` output, preserving the exact Flutter model contract.

## Privacy and safety

- The extension requests no browsing permissions and reads no page data.
- It stores only a Supabase public key, endpoint, access token, refresh token and the user's routines in Chrome extension storage.
- It never contains a service-role key.
- RLS protects the table on every request.

## Implementation steps

- [x] Inspect routine model, existing authentication and migrations.
- [x] Add remote routine migration and Flutter synchronization.
- [x] Build the Manifest V3 extension and accessible routine editor.
- [x] Add setup documentation and test coverage.
- [x] Format, analyze and test relevant targets.
- [x] Refresh Supabase browser sessions on popup initialization; an invalid refresh token returns the user to OTP sign-in rather than leaving the editor blocked by `JWT expired`.
- [x] Accept successful empty Supabase responses when saving a routine library.
- [x] Make the mobile weekly-routine editor discoverable with a labeled action and let users manually refresh its remote library.

## Tests

- Flutter unit tests for routine serialization and remote/local reconciliation behavior.
- Static JavaScript syntax checks for extension scripts.
- Manual Chrome load-unpacked and OTP validation documented.

## Validation commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
node --check extensions/myfit-routine-builder/*.js
```

## Risks

- Browser and mobile simultaneous edits are last-write-wins.
- Supabase email OTP must be enabled for the configured project.
- A user must authenticate in the extension separately; mobile sessions cannot be read by Chrome.

## Rollback plan

Do not apply the new migration and remove the extension directory. Flutter retains its local cache when the table is unavailable.

## Completion criteria

- A signed-in user can save a weekly routine from Chrome.
- The Flutter app reads and writes the same routine library under RLS.
- No privileged credential is committed or required by the extension.
