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
- Android release usa `com.x11pro.myfit`, label `Myfit` y callback Android base configurado.
- Ya existen checklist de QA/release y borradores de privacidad, export y borrado; falta validarlos de punta a punta en dispositivo y cerrar la policy publica.

## Non-goals

- Publicacion final en stores hoy.
- Rediseño total de UI/UX.
- Health Connect / HealthKit.

## Implementation steps

- [x] Endurecer mensajes de error principales en auth/food.
- [x] Ajustar `applicationId`, `namespace`, label y callback Android base.
- [x] Agregar checklist de QA Android real.
- [x] Agregar base de privacy policy, export y data deletion.
- [x] Validar con analyze y tests.

## Continuacion

- [ ] Ejecutar QA real en `SM S916B`, incluyendo rehidratacion tras reinstalacion.
- [ ] Confirmar export/delete remoto de punta a punta.
- [ ] Definir firma release, publicar la policy final y completar smoke tests de pre-publicacion.

## Validation commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```
