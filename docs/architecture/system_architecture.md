# Arquitectura del sistema

## Stack principal

- Mobile: `Flutter`.
- Estado: `Riverpod`.
- Navegacion: `go_router`.
- Backend: `Supabase` + `Edge Functions`.
- Base de datos: `PostgreSQL`.
- Storage: `Supabase Storage`.

## Modulos

- `mobile/fitness_app`: cliente Android/iOS.
- `backend/supabase/migrations`: esquema SQL versionado.
- `backend/supabase/functions`: logica serverless.
- `prompts/`: prompts versionados para IA.

## Flujos clave

1. Comida por texto: app -> edge function -> normalizador -> base nutricional -> confirmacion.
2. Comida por foto: app -> storage -> vision model -> matching nutricional -> confirmacion.
3. Entrenamiento: app -> Health Connect/HealthKit -> resumen local/backend.
4. Coach: backend -> resumen diario/semanal -> salida estructurada segura.

## Restricciones tecnicas

- No usar datos `Strava` como fuente central de IA.
- Pedir permisos por tipo de dato y de forma granular.
- Mantener soporte offline parcial para cache y entradas recientes.
