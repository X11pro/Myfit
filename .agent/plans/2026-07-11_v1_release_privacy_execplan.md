# ExecPlan: v1 release privacy hardening

Fecha: 2026-07-11

## Goal

Avanzar el bloque posterior a persistencia remota base:

- mejorar manejo de errores y estados vacios,
- dejar base de release Android menos provisional,
- documentar privacidad, export/delete y QA real.

## Current state

- Auth y persistencia remota base ya existen.
- La app sigue mostrando algunos errores crudos de Supabase/functions.
- Android sigue con `com.example.fitness_app` y label provisional.
- Faltan documentos claros de privacidad/release/QA.

## Non-goals

- Publicacion final en stores hoy.
- Rediseño total de UI/UX.
- Health Connect / HealthKit.

## Implementation steps

- [ ] Endurecer mensajes de error principales en auth/food.
- [ ] Ajustar `applicationId`, `namespace`, label y callback Android base.
- [ ] Agregar checklist de QA Android real.
- [ ] Agregar base de privacy policy, export y data deletion.
- [ ] Validar con analyze y tests.

## Validation commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```
