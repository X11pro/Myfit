# Data Export And Delete Notes

## Export minimo para v1.0

- profile
- body_metrics
- meal_entries
- meal_photos metadata
- workout_sessions
- gym_sets

## Borrado minimo para v1.0

- borrar filas remotas por usuario
- borrar objetos de Storage en `meal-photos/<user-id>/...`

## Recomendacion tecnica

- implementar Edge Function dedicada para export/delete
- no depender de borrado manual tabla por tabla desde cliente para release final
