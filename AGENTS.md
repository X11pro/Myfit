# AGENTS.md

## Project

This repository contains the source code and documentation for `Myfit`, a Flutter-based Android/iOS app for:

- food tracking,
- estimated calories, protein, sugar and macros,
- photo-based food estimation,
- barcode-based food lookup,
- exercise/workout import,
- daily energy balance,
- safe educational supplement guidance,
- AI-assisted coaching.

The main product document is:

- `docs/product/fitness_product_plan.md`

Read that document before making architecture or implementation decisions.

## Language and communication

- Communicate with the user in Spanish unless asked otherwise.
- Be direct and practical.
- Explain important decisions without overcomplicating them.
- If something depends on platform policy, API limits, health/privacy risk, or missing setup, say so clearly.

## Current repository state

- Flutter project exists at `mobile/fitness_app`.
- Base screens implemented: `login`, `onboarding`, `dashboard`, `splash`.
- App state is local placeholder state using `Riverpod`.
- Supabase bootstrap exists but auth is not connected yet.
- Initial SQL migration exists at `backend/supabase/migrations/20260612_000001_initial_schema.sql`.
- Latest known checks passed in Windows: `flutter analyze`, `flutter test`.

## Product priorities

Build in this order:

1. Supabase backend integration.
2. Auth and onboarding persistence.
3. Manual food tracking.
4. Nutrition database lookup.
5. Barcode scan.
6. Food photo upload and AI estimation.
7. Daily dashboard.
8. Health Connect on Android.
9. HealthKit on iOS.
10. Manual gym workout tracking.
11. Work/NEAT energy estimation.
12. Coach summary.
13. Safe supplement guidance.
14. Beta release preparation.

Do not start with complex AI agents before the base app works.

## Technical stack

- Flutter + Dart.
- Riverpod for state management.
- go_router for navigation.
- Supabase for Auth, PostgreSQL, Storage and Edge Functions.
- PostgreSQL with Row Level Security.
- Health Connect for Android.
- HealthKit for iOS.
- Open Food Facts and USDA FoodData Central for nutrition lookup.
- AI models only through backend functions, not directly from the mobile app.

Do not put API keys in Flutter client code.

## Architecture rules

Use feature-first structure:

```text
lib/
  app/
  core/
  features/
    auth/
    onboarding/
    dashboard/
    food/
    workout/
    coach/
    settings/
  shared/
```

Follow these rules:

- Keep UI separate from business logic.
- Use typed DTOs and immutable models when adding persistence.
- Add tests for calculations and core flows.
- Keep platform-specific code isolated.
- Prefer simple maintainable code over abstractions that are not needed yet.

## AI rules

- Food image estimation must always show a confidence score.
- The user must confirm food and portion before saving.
- AI must return structured JSON.
- Do not rely only on an LLM for nutrition facts if a reliable food database can be queried.
- Never give medical diagnosis.
- Supplement advice must be educational, conservative and safety-aware.
- If data comes from Strava, do not use it for AI/ML processing unless current Strava policy explicitly allows it.

## Health and privacy rules

- Ask only for necessary permissions.
- Explain why each permission is needed.
- Allow disconnecting health data sources.
- Allow data deletion and export.
- Do not sell health data.
- Do not use health data for ads.
- Avoid storing GPS routes in MVP.
- Use Row Level Security in Supabase.
- Store secrets only in backend environment variables.

## Development workflow

Before implementing a significant feature:

1. Read `docs/product/fitness_product_plan.md`.
2. Create or update an ExecPlan in `.agent/plans/`.
3. Explain the approach briefly.
4. Implement in small steps.
5. Add or update tests.
6. Run formatting, analysis and tests.
7. Summarize changed files and next steps.

Use these commands when available:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

For backend or Supabase changes, document manual setup steps.

## Git rules

- Make small commits.
- Use meaningful commit messages.
- Do not commit secrets, `.env`, API keys or private tokens.
- Keep generated files out of Git unless they are required by Flutter platforms.
- Update documentation whenever behavior changes.

## First active implementation target

The next milestone is:

> Connect real Supabase auth and persist onboarding/profile data to `profiles`.
