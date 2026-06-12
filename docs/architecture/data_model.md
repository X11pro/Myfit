# Modelo de datos inicial

## Tablas principales

- `profiles`
- `body_metrics`
- `food_items`
- `meal_entries`
- `meal_photos`
- `workout_sessions`
- `gym_sets`
- `daily_energy_summary`
- `supplement_recommendations`

## Reglas base

- Todas las entidades sensibles deben quedar asociadas a `user_id`.
- `Row Level Security` obligatorio en tablas de usuario.
- `workout_sessions.ai_allowed` controla si una fuente puede entrar a flujos IA.
- `meal_entries` debe guardar macros calculados al momento de confirmacion para evitar recalculos ambiguos.

## Prioridades de implementacion

1. `profiles`
2. `food_items`
3. `meal_entries`
4. `workout_sessions`
5. `daily_energy_summary`
