# ExecPlan: workout tracker simplification

Fecha: 2026-07-26

## Goal

Convertir el registro de workout en un flujo movil directo: sesion y descanso compactos, ejercicios agrupados y alta de sets desde un catalogo local, ejercicios recientes o texto libre, peso y repeticiones.

## Decisions

- Usar un catalogo local data-driven, separado de la UI, para elegir primero grupo muscular y luego ejercicio.
- Definir pecho, espalda y piernas como grupos grandes con al menos 10 ejercicios cada uno; hombros, biceps, triceps, core y pantorrillas como grupos pequenos con al menos 6 cada uno.
- Mantener ejercicios recientes y permitir texto libre para ejercicios personalizados.
- Mantener `GymSetEntry`, RPE, timers, alertas, persistencia local/remota y edicion de sesiones existentes.
- Mantener REST bajo control manual: agregar, editar o repetir un set no debe iniciarlo ni reiniciarlo.
- Mover alertas REST y campos secundarios a controles plegables.

## Implementation steps

- [x] Simplificar el selector de ejercicio a recientes + texto libre.
- [x] Conectar el dialogo rapido a un catalogo local por grupo muscular sin eliminar recientes ni texto libre.
- [x] Reorganizar la pantalla en cabecera de sesion, timers compactos y sets agrupados por ejercicio.
- [x] Mantener acciones de editar, borrar, repetir y guardar funcionales.
- [x] Actualizar tests de widget para el nuevo flujo de alta de sets.
- [x] Ejecutar formato, analisis y tests.
- [ ] Realizar QA Android en dispositivo real.

## Non-goals

- Añadir rutinas predefinidas, catalogo externo o IA de ejercicios.
- Cambiar el esquema remoto de workouts.
