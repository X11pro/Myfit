# UI clarity refresh

## Goal

Improve the shared mobile interface and dashboard readability without changing
health calculations, persistence, navigation, or authentication.

## Approach

- Refine the existing dark color system, typography, inputs, buttons, and cards.
- Improve section header hierarchy and replace the dashboard's hard-coded weight
  change with an honest action label.
- Align the Chrome routine builder's surfaces, controls, and focus treatment
  with the mobile palette without changing authentication or synchronization.
- Preserve existing translations, accessibility, and functionality.

## Verification

- Run targeted widget tests, Flutter analysis, and the full test suite where the
  installed Flutter version permits; record environmental blockers.
- Visually verify on Android and iOS with large text before release.
