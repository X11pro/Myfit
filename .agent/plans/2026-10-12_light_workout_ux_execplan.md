# Light Workout UX ExecPlan

## Objetivo

Crear la primera iteracion visual light de Myfit y priorizar el registro de sets durante el entrenamiento para que peso y repeticiones se puedan completar en segundos.

## Alcance

- Cambiar el tema global de la app a light mode.
- Adaptar la superficie compartida para fondos claros y legibles.
- Reorganizar el workout manual alrededor de ejercicios y sets visibles.
- Permitir editar reps y kg directamente en cada set.
- Mantener timers, rutinas, edicion detallada, historial y persistencia existentes.

## Criterios de aceptacion

- La app arranca en light mode.
- En workout, el usuario ve los ejercicios cargados sin expandir tarjetas.
- Peso y reps se pueden cambiar desde cada fila de set sin abrir el modal de edicion.
- Las acciones secundarias no compiten visualmente con el registro de sets.
- Las pruebas existentes siguen pasando y se agrega una prueba del flujo directo.

## Verificacion

1. `dart format` sobre los Dart modificados.
2. `flutter analyze`.
3. `flutter test`.
