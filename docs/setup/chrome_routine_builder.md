# Myfit Routine Builder for Chrome

The extension lets an authenticated Myfit user build weekly gym routines from a desktop browser. It syncs its routine library with the Flutter app through Supabase.

## Prerequisites

- The migration `backend/supabase/migrations/20261117_000004_workout_routines.sql` has been applied to the linked Supabase project.
- Email OTP is enabled in Supabase Auth.
- The Flutter app is run with `SUPABASE_URL` and `SUPABASE_ANON_KEY` configured.

## Load locally in Chrome

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Select **Load unpacked**.
4. Select `extensions/myfit-routine-builder` from this repository.
5. Pin **Myfit Routine Builder** from Chrome's extensions menu.

## Connect and sign in

1. Open the extension and choose **Open connection settings**.
2. Enter the same `SUPABASE_URL` and `SUPABASE_ANON_KEY` used by Flutter. The anonymous key is safe for a client application; never use a `service_role` key.
3. Enter the same email used in Myfit and request a code.
4. Paste the email OTP in the extension. Pasting is intentionally allowed for accessibility and password-manager support.
5. Create/edit routines and select **Push Routine to Mobile** (`Ctrl+S` or `⌘S`). **Cloud saved** means Supabase accepted the save; in the mobile app, use **Reload routines** to fetch it.

If the popup was already open before this update, reload the extension from `chrome://extensions`. Version `0.1.1` renews a valid saved session automatically; if it cannot be renewed, it shows the OTP sign-in form again.

## Synchronization behavior

- The browser stores one `WorkoutRoutineLibrary` document per authenticated user in `public.workout_routines`.
- Flutter reads that document after authentication and writes each later routine edit to it.
- In Flutter, open **Manual workout** → **Edit weekly routine** → **Reload routines** to force a manual download after a browser save.
- The local Flutter data remains an offline cache.
- Simultaneous browser and phone edits use last-write-wins. Avoid editing the same routine in both places at once.

## Security and privacy

- The extension requests only Chrome's local storage permission and access to the configured Supabase project endpoint.
- It does not read web pages, browser history or browsing activity.
- The user's short-lived Supabase session is stored in Chrome extension storage.
- Row Level Security restricts every routine document to its authenticated owner.
