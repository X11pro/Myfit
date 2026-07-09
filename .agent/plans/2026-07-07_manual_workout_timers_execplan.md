# ExecPlan: manual workout timers

Fecha: 2026-07-07

## Objetivo

Agregar al flujo de entrenamiento manual:

- un cronometro general de sesion con inicio y fin manual,
- un cronometro de descanso configurable por el usuario,
- guardado persistente de tres tiempos: total, activo y descanso.

## Alcance

- UI en `manual_workout_screen.dart`
- modelo persistido en `manual_workout_session.dart`
- notifier/persistencia en `manual_workout_controller.dart`
- textos en `app_language.dart`
- tests de widget para el comportamiento principal

## Decisiones

1. Guardar los tiempos en segundos para no perder precision.
2. Mantener `durationMinutes` por compatibilidad con datos ya guardados y usos existentes.
3. Calcular tiempo activo como `total - descanso`, limitado a cero.
4. Usar un unico boton `REST` como toggle del ciclo de descanso.
5. Mientras el descanso no venza, mostrar cuenta regresiva y estado visual rojo.
6. Cuando el descanso vence, mostrar tiempo excedido y estado visual verde.

## Verificacion

- `dart format .`
- `flutter analyze`
- `flutter test test/features/workout/manual_workout_screen_test.dart`
