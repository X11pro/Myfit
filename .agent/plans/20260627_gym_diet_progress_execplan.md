# ExecPlan: gym manual + dieta + progreso local-first

## Objetivo

Conectar el objetivo corporal del onboarding con:

- targets diarios de calorias y proteina,
- registro manual de sesiones de gym con sets y peso,
- recomendaciones simples de ejercicios/rutinas,
- visualizacion de progreso en fuerza, peso corporal, calorias o combinado.

## Alcance MVP

- Crear feature `workout/` en Flutter.
- Persistir sesiones y sets localmente con `shared_preferences`.
- Guardar cada sesion con fecha para seguimiento historico.
- Derivar targets diarios desde `goal`, `jobActivityLevel`, peso y calorias de entrenamiento.
- Mostrar recomendaciones de rutina alineadas con el objetivo.
- Agregar un panel visual simple de progreso sin dependencias externas de charts.

## Decisiones

- `goal` actual del onboarding actua como la base del "tipo de dieta" por ahora.
- Los workouts ajustan gasto y contexto del dia; no reemplazan el objetivo nutricional.
- Todo queda local-first hasta reintroducir auth y persistencia remota multiusuario.
- La visualizacion de progreso usara barras simples normalizadas para evitar dependencias nuevas.

## Pasos

1. Crear dominio y controlador de workouts manuales.
2. Crear calculadora de targets diarios y recomendaciones por objetivo.
3. Añadir pantalla de workout manual con carga de sets/peso y fecha.
4. Integrar resumen, recomendaciones y progreso en dashboard.
5. Añadir tests de persistencia/cálculos.
6. Ejecutar format, analyze y test.

## Riesgos

- Aun no hay sexo/edad para un BMR completo; se usara estimacion conservadora por peso.
- Las recomendaciones seran educativas y fijas por objetivo, no adaptacion IA.
- Si luego cambia el modelo de identidad, habra que migrar local -> remoto.
