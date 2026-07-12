# ExecPlan: v1 remote sync foundation

Fecha: 2026-07-11

## Goal

Empezar el camino real hacia `v1.0` cerrando la base de identidad y persistencia remota multiusuario sin romper el guest mode actual.

## Current state

- Auth OTP con Supabase ya existe, pero el producto sigue usable en guest mode.
- `body_metrics` ya se usa remotamente desde onboarding autenticado.
- `manual food entry`, `daily weight` y `manual workout` siguen persistiendo localmente en `shared_preferences`.
- `workout_sessions` remoto no alcanza para representar bien el flujo manual actual porque no guarda titulo de sesion ni tiempos `total / activo / descanso`.
- `meal_entries` remoto existe, pero el flujo local actual permite fotos locales y todavia no tiene subida/Storage remotos cerrados.

## Relevant documents

- `docs/product/fitness_product_plan.md`
- `AGENTS.md`
- `docs/handoff/current_status.md`
- `backend/supabase/migrations/20260612_000001_initial_schema.sql`

## Non-goals

- Rediseño total de UI/UX.
- Health Connect / HealthKit.
- Persistencia remota completa de fotos de comida en esta misma iteracion.
- Coach, suplementos o analytics avanzados.

## User stories

- Como usuario autenticado, quiero que mi peso diario se sincronice con mi cuenta.
- Como usuario autenticado, quiero que mis sesiones manuales de gym se guarden en Supabase y reaparezcan al volver a entrar.
- Como usuario invitado que luego inicia sesion, quiero que mis datos locales basicos no se pierdan.

## Technical design

### Slice 1

- Mantener guest mode local tal como esta.
- Cuando hay sesion autenticada:
  - `daily weight` lee/escribe remoto.
  - `manual workout` lee/escribe remoto.
- Agregar migracion SQL minima para que `workout_sessions` soporte:
  - `title`
  - `total_duration_seconds`
  - `active_duration_seconds`
  - `rest_duration_seconds`
- En el primer login autenticado, si remoto esta vacio, sembrar con datos locales actuales de peso/workout.

### Slice 2

- Diseñar `manual food entry` remoto sin perder fotos.
- Resolver Storage + `meal_photos` + relacion con `meal_entries`.

## Data model

- `body_metrics`: usar la tabla actual.
- `workout_sessions`: extender con columnas nuevas para manual workout.
- `gym_sets`: reutilizar la tabla actual.

## Privacy and safety

- No guardar secretos en Flutter cliente.
- Respetar RLS por usuario existente.
- No borrar datos locales automaticamente al autenticar sin confirmar que remoto quedo cargado.

## Implementation steps

- [ ] Agregar migracion SQL para extender `workout_sessions`.
- [ ] Implementar carga/escritura remota de `daily weight` para usuarios autenticados.
- [ ] Implementar carga/escritura remota de `manual workout` y `gym_sets` para usuarios autenticados.
- [ ] Sembrar remoto desde local cuando aplique y mantener fallback guest.
- [ ] Validar con analyze y tests existentes.

## Tests

- Mantener los tests actuales pasando.
- Agregar tests de mapping si aparece logica nueva aislable sin mocks complejos.

## Validation commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

## Risks

- Duplicacion de datos locales/remotos si la migracion inicial no se controla bien.
- `manual food entry` no debe entrar todavia a remoto si eso implica perder fotos locales.

## Rollback plan

- Revertir la migracion nueva y volver a controladores local-first solamente.

## Completion criteria

- Usuario autenticado: peso y workouts manuales sobreviven reinstalacion/sesion nueva porque viven en Supabase.
- Usuario guest: todo sigue funcionando local.
- No se rompe el flujo actual de workout/timers.
