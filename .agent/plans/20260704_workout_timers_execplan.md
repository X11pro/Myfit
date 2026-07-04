# ExecPlan: workout timers

## Objetivo

Agregar dos herramientas utiles al flujo actual de gym manual:

- cronometro de inicio/fin para medir la duracion total de la sesion,
- cronometro de descanso entre series.

## Decision

- Implementar ambos timers solo en `manual_workout_screen.dart` por ahora.
- Reusar el campo existente `durationMinutes` para persistir el tiempo total final.
- Mantener el timer de descanso como ayuda de sesion local, sin persistirlo todavia.

## Pasos

1. Agregar estado local para ambos cronometros.
2. Mostrar controles simples de iniciar, pausar/finalizar y reset.
3. Sincronizar el cronometro de sesion con `Duration (min)` para que el usuario pueda seguir editandolo si quiere.
4. Mantener layout responsive en movil.
5. Validar con `flutter analyze` y generar `app-debug.apk`.

## Riesgos

- Si el usuario edita manualmente la duracion mientras corre el timer, el timer debe poder sobrescribir ese valor al pausar/finalizar sin dejar el campo inconsistente.
- No se debe introducir complejidad de background timers ni notificaciones en esta iteracion.
