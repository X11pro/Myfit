# Update PC App

## Estado

No iniciar desarrollo antes del 2026-08-25. Este documento define el trabajo necesario para que Myfit tenga una app de escritorio Windows/macOS conectada con la app movil.

## Objetivo

Permitir que una persona cree y actualice rutinas desde una pantalla amplia de PC, y que esas rutinas se sincronicen de forma segura con Android/iOS para cargarlas en el workout del dia.

La primera version desktop debe reutilizar el mismo proyecto Flutter. No se creara un backend separado ni una aplicacion web independiente.

## Alcance MVP

- Flutter para Windows y macOS desde `mobile/fitness_app`.
- Inicio de sesion Supabase OTP igual que en movil.
- Biblioteca de rutinas nombradas: crear, seleccionar, renombrar, duplicar, editar y borrar.
- Editor semanal de lunes a domingo.
- Bloques normales, superseries y triseries.
- Ejercicio, grupo muscular, sets, reps y peso inicial por ejercicio.
- Sincronizacion PC <-> movil al guardar y al abrir la app.
- Cache local para poder consultar y editar sin conexion.
- Resolucion simple de conflictos: ultima actualizacion guardada gana, mostrando fecha de ultima sincronizacion.

## Fuera de alcance inicial

- Planes creados por IA.
- Colaboracion entre usuarios o entrenadores.
- Edicion simultanea en tiempo real.
- Integracion Health Connect/HealthKit desde desktop.
- Sincronizacion de workouts en vivo.
- Publicacion en Microsoft Store o Mac App Store antes de QA interna.

## Arquitectura

### Cliente

- Mantener Flutter como unica base de codigo.
- Extraer la logica actual de rutinas locales a un repositorio de rutinas con cache local + Supabase.
- Mantener UI movil compacta y crear breakpoints desktop para dos paneles:
  - izquierda: biblioteca de rutinas y dias;
  - derecha: bloques, ejercicios y valores editables.
- El movil conserva la accion `Load <day> routine` y descarga la rutina activa actualizada.

### Supabase

Crear migraciones nuevas, sin alterar el historial existente de `gym_sets`.

Tablas propuestas:

```text
workout_routines
  id uuid primary key
  user_id uuid not null references auth.users
  name text not null
  is_active boolean not null default false
  created_at timestamptz not null
  updated_at timestamptz not null

workout_routine_days
  id uuid primary key
  routine_id uuid not null references workout_routines on delete cascade
  weekday smallint not null check (weekday between 1 and 7)
  updated_at timestamptz not null

workout_routine_blocks
  id uuid primary key
  routine_day_id uuid not null references workout_routine_days on delete cascade
  position integer not null
  block_type text not null check (block_type in ('normal', 'superset', 'triset'))
  updated_at timestamptz not null

workout_routine_exercises
  id uuid primary key
  routine_block_id uuid not null references workout_routine_blocks on delete cascade
  position integer not null
  exercise_name text not null
  muscle_group text not null
  sets integer not null check (sets > 0)
  reps integer not null check (reps > 0)
  weight_kg numeric not null default 0
  updated_at timestamptz not null
```

Reglas:

- Habilitar RLS en las cuatro tablas.
- Cada politica debe permitir solo filas cuyo `user_id` sea `auth.uid()` o cuyo `routine_id` pertenezca al usuario.
- Crear indice por `workout_routines(user_id, updated_at desc)`.
- Mantener una sola rutina activa por usuario con indice unico parcial o transaccion de activacion.
- Las claves Supabase solo se inyectan con `--dart-define-from-file`; nunca se guardan en Git.

## Migracion local

La app movil actual guarda la biblioteca de rutinas en `shared_preferences` bajo `weekly_workout_routine`.

Al iniciar sesion con la version que incluya sync:

1. Leer la biblioteca local.
2. Descargar rutinas remotas.
3. Si el remoto esta vacio y la biblioteca local tiene datos, subirla una sola vez.
4. Guardar IDs remotos en la cache local para evitar duplicados.
5. Si ambas fuentes tienen datos, comparar `updated_at` y conservar la mas reciente por rutina.
6. Mostrar un error recuperable si el sync falla; nunca borrar la copia local por un error de red.

## Plan de accion

### Fase 1: esquema y contratos

1. Crear ExecPlan de implementacion.
2. Añadir migracion SQL, RLS, indices y `updated_at` triggers.
3. Documentar contract DTO JSON para rutina, dia, bloque y ejercicio.
4. Aplicar migracion en Supabase y comprobar politicas con un usuario de prueba.

### Fase 2: dominio y sync Flutter

1. Reemplazar el provider local de rutinas por repositorio hibrido.
2. Crear DTOs tipados para remoto y cache local.
3. Implementar rehidratacion, upload, download y migracion guest -> cuenta.
4. Añadir indicador de estado: local, sincronizando, sincronizado o error.
5. Añadir tests de conflicto, migracion y no duplicacion.

### Fase 3: UX desktop

1. Añadir layout responsive para Windows/macOS.
2. Biblioteca lateral con selector de rutina activa, crear, duplicar, renombrar y borrar.
3. Editor de dia con drag/reorder opcional solo si la base funciona.
4. Bloques visuales claramente etiquetados: normal, superserie y triserie.
5. Mantener equivalencia funcional con movil.

### Fase 4: QA multiplataforma

1. Android real: crear rutina y comprobar carga por fecha.
2. Windows: editar peso/sets/reps y guardar.
3. macOS: editar bloque y cambiar rutina activa.
4. Confirmar que Android, Windows y macOS reciben el cambio tras cerrar/reabrir.
5. Probar sin conexion y recuperacion posterior.
6. Revisar RLS con dos cuentas distintas.

### Fase 5: empaquetado

1. Generar builds Windows y macOS firmadas cuando existan certificados.
2. Preparar instalador Windows y notarizacion macOS si se distribuye fuera de stores.
3. Ejecutar beta cerrada con datos no sensibles.

## Criterios de aceptacion

- Una rutina creada en Windows aparece en Android tras sync.
- Un peso actualizado en Android aparece en Windows tras sync.
- La rutina activa carga el dia correcto segun la fecha del workout.
- Superseries y triseries conservan orden, ejercicios y valores.
- Un usuario no puede leer ni modificar las rutinas de otro usuario.
- La app conserva la ultima rutina local si no hay red.

## Riesgos

- El formato actual es local y no tiene IDs remotos; la migracion debe ser idempotente.
- La regla de ultima edicion puede sobrescribir cambios simultaneos; mostrar la hora de sincronizacion reduce confusion en MVP.
- No iniciar desktop antes de cerrar las pruebas pendientes de rutina movil, audio REST y QA secundaria.

## Inicio recomendado

Empezar el 2026-08-25 por Fase 1, leyendo primero `AGENTS.md`, `docs/handoff/current_status.md` y este documento.
