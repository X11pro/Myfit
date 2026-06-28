# ExecPlan: Migracion de meal photo AI a backend free/open

## Objetivo

Reemplazar la dependencia actual de `OPENAI_API_KEY` en `meal-photo-analyze` por una ruta backend simple y barata basada en `Qwen2.5-VL-7B-Instruct`, sin tocar todavia auth y sin romper el flujo guest-first local.

## Alcance de esta iteracion

1. Mantener la UI Flutter actual de `Analyze with AI`.
2. Mantener Supabase Edge Function como punto de entrada del cliente.
3. Cambiar el proveedor vision por una opcion compatible con `Qwen2.5-VL-7B-Instruct`.
4. Devolver JSON estable con `confidence` y datos parciales tolerables.
5. Resolver nutricion final con `USDA`, `Open Food Facts` y/o catalogo compartido, no solo con el modelo vision.

## Decisiones ya tomadas

- Prioridad actual: guest-first + persistencia local + backend simple.
- No reintroducir auth en esta iteracion salvo bloqueo real.
- `Qwen2.5-VL-7B-Instruct` es la opcion recomendada para costo cero o muy bajo.
- El modelo vision debe usarse para reconocimiento, porcion y confianza; las macros finales deben pasar por matching nutricional confiable.

## Delta sobre el estado actual

- Hoy `backend/supabase/functions/meal-photo-analyze/index.ts` llama a OpenAI Responses API y falla si falta `OPENAI_API_KEY`.
- La migracion debe aislar la llamada al proveedor para no cambiar el flujo Flutter salvo necesidad real.

## Implementacion prevista

1. Introducir configuracion de proveedor vision por variables de entorno del backend.
2. Adaptar `meal-photo-analyze` para consumir un endpoint compatible con Qwen.
3. Normalizar la respuesta a un contrato JSON fijo y conservador.
4. Agregar matching nutricional posterior con `USDA`/`Open Food Facts`/catalogo cuando haya identificacion suficiente.
5. Mantener tolerancia a respuestas incompletas para no romper la app.

## Verificacion prevista

1. `dart format .`
2. `flutter analyze`
3. `flutter test`
4. prueba real de `Shared Food Catalog`
5. prueba real de `Analyze with AI`

## Setup manual esperado

- Configurar `SUPABASE_URL` y `SUPABASE_ANON_KEY` al correr Flutter.
- Configurar las nuevas variables secret del proveedor vision en Supabase.
- Redesplegar `meal-photo-analyze`.

## Siguiente paso esperado

- Implementar la migracion del backend vision sin cambiar todavia el modelo de identidad ni la persistencia remota multiusuario.
