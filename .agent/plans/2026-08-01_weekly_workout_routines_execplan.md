# ExecPlan: weekly workout routines

Fecha: 2026-08-01

## Goal

Permitir crear una rutina propia para cada dia de lunes a domingo y cargar, bajo demanda, la rutina correspondiente a la fecha elegida en un workout nuevo.

## Decisions

- Guardar las plantillas localmente con `shared_preferences`; la sincronizacion remota de plantillas queda fuera de este bloque para no agregar una migracion mientras se cierra la persistencia remota existente.
- El usuario configura los siete dias, pudiendo dejar vacios los dias de descanso.
- Cada bloque de rutina puede ser normal, superserie (2 ejercicios) o triserie (3 ejercicios).
- Cada ejercicio nuevo parte de 3 series y 10 repeticiones; esos valores quedan visibles y editables en el editor.
- La pantalla de workout muestra un boton para cargar la rutina del dia de la fecha seleccionada. Solo se habilita en una sesion nueva sin sets, para no duplicar datos.
- Al cargar, el peso inicial es 0 kg y el usuario lo ajusta durante el entrenamiento.

## Implementation steps

- [x] Crear modelos inmutables/serializables para rutina semanal, bloques y ejercicios.
- [x] Implementar provider local-first para leer y guardar la rutina semanal.
- [x] Agregar pantalla de editor semanal con bloques normal, superserie y triserie.
- [x] Agregar acceso desde workout y carga explicita segun el dia de la fecha.
- [x] Agregar tests de persistencia, seleccion por fecha y carga con defaults 3 x 10.
- [x] Ejecutar formato, analisis y tests.
- [x] Agregar peso inicial por ejercicio y aplicarlo al cargar una rutina.
- [x] Convertir la rutina unica en una biblioteca local de rutinas nombradas, seleccionables y renombrables.
- [x] Actualizar editor, tests y verificaciones para la biblioteca de rutinas.

## Non-goals

- Sincronizar plantillas de rutina con Supabase.
- Cambiar el esquema remoto de `gym_sets`.
- Crear planes automaticos o recomendaciones de entrenamiento.
