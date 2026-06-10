# Codex Execution Plans for Myfit

Use this document when creating implementation plans for larger features.

An ExecPlan is a self-contained plan that a coding agent can follow from design to implementation. It must assume the reader has only the current repository and this plan.

---

## When to create an ExecPlan

Create an ExecPlan before:

- adding a major feature,
- changing architecture,
- adding Supabase schema/migrations,
- adding Health Connect or HealthKit,
- adding AI food photo estimation,
- adding supplement recommendation logic,
- changing authentication,
- changing privacy/security behavior.

Small bug fixes do not need an ExecPlan.

---

## ExecPlan template

Create plans under:

```text
.agent/plans/YYYY-MM-DD-feature-name.md
```

Use this template:

```markdown
# ExecPlan: <feature name>

## Goal

Describe what this feature accomplishes from the user perspective.

## Current state

Describe what exists in the repository now.

## Relevant documents

- docs/product/fitness_product_plan.md
- AGENTS.md
- any related files

## Non-goals

List what this plan will not do.

## User stories

- As a user, I can...
- As a user, I see...
- As a user, I can correct...

## Technical design

Describe:

- Flutter screens/widgets.
- State management.
- Domain models.
- Repositories/services.
- Backend changes.
- Database changes.
- External APIs.
- Error handling.
- Offline/cache behavior if relevant.

## Data model

Show affected models/tables.

## Privacy and safety

Explain:

- permissions,
- sensitive data,
- what is stored,
- what is not stored,
- disclaimers,
- deletion/export impact.

## Implementation steps

Use a checklist:

- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Tests

List:

- unit tests,
- widget tests,
- integration tests,
- manual test cases.

## Validation commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

## Risks

List technical, product and policy risks.

## Rollback plan

Explain how to undo the change safely.

## Completion criteria

The feature is complete when:

- ...
```
