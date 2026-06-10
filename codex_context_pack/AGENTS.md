# AGENTS.md

## Project

This repository contains the source code and documentation for **Myfit**, a Flutter-based Android/iOS app for:

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

Codex must read that document before making architecture or implementation decisions.

---

## Language and communication

- Communicate with the user in Spanish unless the user asks otherwise.
- Use clear, practical explanations.
- The user is learning mobile development, so explain important decisions without overcomplicating.
- Do not hide uncertainty. If something depends on a platform policy, API limit, or health/legal risk, say so clearly.

---

## Product priorities

Build in this order:

1. Flutter app scaffold.
2. Supabase backend integration.
3. Auth and onboarding.
4. Manual food tracking.
5. Nutrition database lookup.
6. Barcode scan.
7. Food photo upload and AI estimation.
8. Daily dashboard.
9. Health Connect on Android.
10. HealthKit on iOS.
11. Manual gym workout tracking.
12. Work/NEAT energy estimation.
13. Coach summary.
14. Safe supplement guidance.
15. Beta release preparation.

Do not start with complex AI agents before the base app works.

---

## Technical stack

Preferred stack:

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

---

## Architecture rules

Use feature-first clean architecture:

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

Inside each feature:

```text
data/
domain/
presentation/
```

Follow these rules:

- Keep UI separate from business logic.
- Use immutable models.
- Use typed DTOs.
- Add tests for calculation logic.
- Keep platform-specific code isolated.
- Prefer simple maintainable code over over-engineered abstractions.

---

## AI rules

Use AI carefully:

- Food image estimation must always show a confidence score.
- The user must confirm food/portion before saving.
- AI must return structured JSON.
- Never rely only on an LLM for nutrition facts if a reliable food database can be queried.
- Never give medical diagnosis.
- Supplement advice must be educational, conservative and safety-aware.
- If data comes from Strava, do not use it for AI/ML processing unless current Strava policy explicitly allows it.

---

## Health and privacy rules

Health, food, body and exercise data are sensitive.

Requirements:

- Ask only for necessary permissions.
- Explain why each permission is needed.
- Allow disconnecting health data sources.
- Allow data deletion and export.
- Do not sell health data.
- Do not use health data for ads.
- Avoid storing GPS routes in MVP.
- Use Row Level Security in Supabase.
- Store secrets only in backend environment variables.

---

## Development workflow

Before implementing a significant feature:

1. Read `docs/product/fitness_product_plan.md`.
2. Create or update an ExecPlan in `.agent/`.
3. Explain the approach briefly.
4. Implement in small steps.
5. Add/update tests.
6. Run formatting, analysis and tests.
7. Summarize changed files and next steps.

For Flutter changes, run when available:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

For backend/Supabase changes, document manual setup steps.

---

## Git rules

- Make small commits.
- Use meaningful commit messages.
- Do not commit secrets, `.env`, API keys or private tokens.
- Keep generated files out of Git unless required.
- Update documentation whenever behavior changes.

---

## First implementation target

The first coding milestone is:

> A runnable Flutter app with onboarding, local profile model, manual food entry, daily calories/protein dashboard, and placeholder Supabase configuration.

Do not implement photo AI or health integrations before this first milestone is stable.
