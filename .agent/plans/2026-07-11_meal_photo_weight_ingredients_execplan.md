# ExecPlan: meal photo weight and ingredients

Fecha: 2026-07-11

## Goal

Permitir que el usuario:

- ingrese el peso total de la comida,
- vea una lista editable de ingredientes detectados por IA,
- agregue, quite o corrija ingredientes antes de guardar.

## Current state

- `manual food entry` ya soporta foto, analisis IA y persistencia local/remota.
- `meal_entries` ya tiene `estimated_grams` pero todavia no se usa en Flutter.
- no existe todavia un campo persistido para ingredientes corregidos por el usuario.

## Technical design

- reutilizar `estimated_grams` para peso total.
- agregar `ingredients_text` en `meal_entries` para guardar la lista editable.
- extender el payload de `meal-photo-analyze` para devolver `identifiedIngredients`.
- prellenar un `TextField` multilínea con ingredientes separados por linea.

## Validation

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```
