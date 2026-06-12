# Execution Plans for Myfit

Use this document when creating implementation plans for larger features.

## When to create an ExecPlan

Create an ExecPlan before:

- adding a major feature,
- changing architecture,
- adding Supabase schema or migrations,
- adding Health Connect or HealthKit,
- adding AI food photo estimation,
- adding supplement recommendation logic,
- changing authentication,
- changing privacy or security behavior.

Small bug fixes do not need an ExecPlan.

## Path

Create plans under:

```text
.agent/plans/YYYY-MM-DD-feature-name.md
```

## Template

```markdown
# ExecPlan: <feature name>

## Goal

## Current state

## Relevant documents

- docs/product/fitness_product_plan.md
- AGENTS.md
- any related files

## Non-goals

## User stories

## Technical design

## Data model

## Privacy and safety

## Implementation steps

- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Tests

## Validation commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

## Risks

## Rollback plan

## Completion criteria
```
