# Prompt para NotebookLM: diagrama visual de Myfit

Usa `docs/product/status_map.md` como fuente principal.

Quiero que generes un diagrama visual muy claro y facil de entender del estado actual de `Myfit`.

Objetivo del diagrama:

- mostrar que partes del producto ya estan implementadas,
- que partes ya fueron validadas en dispositivo real,
- que partes estan pendientes de prueba real,
- que sigue en la proxima iteracion,
- y que queda como backlog futuro.

Instrucciones importantes:

1. No me des solo una lista. Quiero una salida visual estructurada.
2. Organiza el diagrama por modulos principales:
   - Core app
   - Auth
   - Food
   - Barcode
   - Workout
   - Progress
   - Backend
   - Next iteration
   - Future backlog
3. Distingue visualmente los estados:
   - Implementado
   - Validado en dispositivo
   - Pendiente de prueba real
   - Pendiente siguiente iteracion
   - Backlog futuro
4. Dentro de `Food`, muestra explicitamente la cadena de lookup de barcode:
   - cache Supabase
   - Open Food Facts
   - USDA
5. Dentro de `Backend`, muestra las Edge Functions activas:
   - meal-photo-analyze
   - food-catalog-upsert
   - food-barcode-lookup
6. Muestra dependencias importantes entre bloques. Ejemplos:
   - Barcode scan depende de Supabase config + food-barcode-lookup
   - Analyze with AI depende de meal-photo-analyze + OpenRouter
   - Persistencia remota depende de auth real
7. Si puedes, genera dos vistas:
   - una vista ejecutiva simple para entender el producto de un vistazo,
   - una vista mas detallada por modulos.
8. El diagrama debe ser legible para una persona no tecnica pero tambien util para desarrollo.
9. Prioriza claridad visual sobre detalle excesivo.
10. No inventes features no presentes en `status_map.md`.

Formato deseado:

- primero una vista visual principal,
- luego una version resumida tipo roadmap o tablero por estados,
- y finalmente una explicacion corta de como leer el diagrama.

Si necesitas elegir un tipo de visual, prioriza en este orden:

1. Product map por modulos y estados
2. Roadmap board por estado
3. Dependency diagram simplificado

Quiero que el resultado final sea suficientemente claro como para compartirlo con otra persona y que entienda rapido:

- que ya funciona,
- que ya esta probado,
- que falta probar,
- y que viene despues.
