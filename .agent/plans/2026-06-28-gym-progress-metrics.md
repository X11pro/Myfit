# ExecPlan: metricas de progreso gym local-first

## Goal

Mejorar la utilidad real de la pantalla de progreso de gym sin salir del modelo guest-first/local-first.

## Current state

- El progreso de fuerza usa solo el peso maximo por sesion.
- Existe filtro por ejercicio, pero no hay otras metricas para evaluar volumen o rendimiento estimado.
- El agrupado diario reutiliza la misma logica para fuerza y calorias, lo que no refleja bien el total por dia en todos los casos.

## Relevant documents

- `docs/product/fitness_product_plan.md`
- `AGENTS.md`
- `docs/handoff/current_status.md`
- `mobile/fitness_app/lib/features/dashboard/application/daily_targets_calculator.dart`
- `mobile/fitness_app/lib/features/dashboard/presentation/progress_screen.dart`

## Non-goals

- Persistencia remota de workouts.
- Health Connect o HealthKit.
- Cambios de autenticacion.

## User stories

- Como usuario quiero ver no solo mi peso maximo, sino tambien si mi volumen total sube o baja.
- Como usuario quiero una referencia simple de fuerza estimada por ejercicio para detectar progreso aunque cambien las repeticiones.

## Technical design

- Agregar una metrica de progreso de fuerza seleccionable: `heaviest weight`, `total volume`, `estimated 1RM`.
- Mantener el filtro por ejercicio para las tres metricas.
- Ajustar el agrupado diario para usar `max` o `sum` segun la metrica.
- Actualizar el resumen visible de progreso para mostrar unidades y mensajes mas utiles.

## Data model

- Sin cambios de persistencia.
- Solo se agregan enums/helpers derivados en memoria.

## Privacy and safety

- Sin nuevos permisos.
- Sin nuevos datos sensibles.

## Implementation steps

- [ ] Agregar enum y estado para la metrica de progreso de fuerza.
- [ ] Ajustar calculos de progreso para peso maximo, volumen y e1RM.
- [ ] Actualizar UI de progreso y textos EN/ES.
- [ ] Agregar tests de metricas y agrupado.

## Tests

- Providers de progreso por ejercicio.
- Calculo de volumen total y e1RM.
- Agrupado diario correcto por tipo de metrica.

## Validation commands

```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

## Risks

- e1RM es una estimacion educativa, no una medicion exacta.
- Si el usuario mezcla ejercicios en una sesion, el peso maximo global sigue siendo una señal limitada sin filtro por ejercicio.

## Rollback plan

- Volver a la metrica unica de peso maximo y eliminar el selector de metricas.

## Completion criteria

- La pantalla de progreso permite cambiar entre tres metricas de fuerza.
- El grafico y el resumen reflejan la metrica elegida.
- Los tests cubren los nuevos calculos.
