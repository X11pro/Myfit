# ExecPlan: workout duration dashboard

Fecha: 2026-07-26

## Goal

Mostrar los tiempos total, activo y de descanso ya guardados por los workouts manuales dentro del resumen de actividad diario.

## Current state

- Cada `ManualWorkoutSession` persiste `totalDurationSeconds`, `activeDurationSeconds` y `restDurationSeconds` local y remotamente.
- La QA Android confirmo que los timers se guardan y que workouts rehidratan despues de reinstalar.
- El dashboard actual muestra calorias, sets y repeticiones, pero no consume esos tiempos.

## Implementation steps

- [x] Crear un agregado reutilizable de los tres tiempos para las sesiones del dia.
- [x] Mostrar el resumen de tiempos en la actividad del dashboard.
- [x] Cubrir el agregado con test de varias sesiones.
- [x] Ejecutar formato, analisis y tests.

## Non-goals

- Cambiar calculos de calorias o balance energetico.
- Crear metricas historicas nuevas o rediseñar progreso.
