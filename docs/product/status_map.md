# Status Map

## Objetivo del archivo

Este archivo resume el estado real de `Myfit` de forma estructurada para que otra IA o herramienta visual pueda convertirlo facilmente en:

- diagrama de producto,
- mapa de modulos,
- roadmap visual,
- tablero por estados,
- arquitectura funcional entendible.

El contenido prioriza claridad sobre detalle tecnico fino.

## Leyenda de estados

- `Implementado`: ya existe en codigo y fue validado al menos localmente.
- `Validado en dispositivo`: ya se probo en telefono o entorno real.
- `Pendiente de prueba real`: existe, pero falta prueba real suficiente.
- `Pendiente siguiente iteracion`: siguiente capa logica del producto.
- `Backlog futuro`: registrado, pero no prioritario ahora.

## Resumen ejecutivo

- El producto actual ya es usable en guest mode.
- La app ya cubre comida manual, foto con AI, catalogo compartido, barcode scan, gym manual y progreso basico.
- El backend activo usa `Supabase` + Edge Functions.
- Para barcode nutricional ya existe lookup real con esta cadena:
  - `cache en Supabase food_items`
  - `Open Food Facts`
  - `USDA FoodData Central`
- La principal deuda actual ya no es de features core, sino de:
  - pruebas reales en movil,
  - persistencia remota multiusuario,
  - salud/wearables,
  - consolidacion de auth.

## Vista por modulos

### 1. Core app shell

- Modulo: `App shell`
- Estado: `Implementado`
- Incluye:
  - splash / welcome,
  - onboarding,
  - dashboard,
  - router con `go_router`,
  - dark mode,
  - selector `EN / ESP`,
  - top bar global con `back/home/menu`.
- Dependencias:
  - Flutter,
  - Riverpod,
  - go_router.
- Nota:
  - Es la base estable del flujo principal actual.

### 2. Auth e identidad

- Modulo: `Auth`
- Estado: `Implementado parcial`
- Incluye:
  - guest-first usable,
  - auth minima por email OTP con Supabase,
  - pantalla de cuenta/auth minima,
  - estado local y sincronizacion basica con sesion Supabase.
- Falta:
  - modelo final de identidad multiusuario,
  - reintroduccion completa de auth como base de persistencia remota.
- Dependencias:
  - Supabase Auth,
  - app state.
- Siguiente paso:
  - usar auth real como soporte de persistencia remota de meals/workouts.

### 3. Food manual

- Modulo: `Manual food entry`
- Estado: `Implementado`
- Incluye:
  - carga manual de nombre,
  - calorias,
  - proteina,
  - carbs,
  - grasas,
  - azucar,
  - fibra,
  - meal type,
  - editar y borrar,
  - persistencia local-first.
- Dependencias:
  - shared_preferences,
  - estado local Riverpod.

### 4. Food photo + AI

- Modulo: `Meal photo + AI`
- Estado: `Implementado, pendiente de prueba real mas profunda`
- Incluye:
  - tomar foto o elegir de galeria,
  - preview,
  - `Analyze with AI`,
  - autocompletado de comida/macros,
  - guardado de `confidence`,
  - soporte web con `data:` URL.
- Backend asociado:
  - `meal-photo-analyze`
- Modelo AI actual:
  - `OpenRouter`
  - `qwen/qwen3-vl-8b-instruct`
- Dependencias:
  - Supabase Functions,
  - OpenRouter,
  - config de Supabase embebida en build.
- Pendiente real:
  - validar varias fotos reales en Android.

### 5. Food gallery

- Modulo: `Food gallery`
- Estado: `Implementado`
- Incluye:
  - lista de comidas con foto,
  - fecha,
  - meal type,
  - macros,
  - confianza AI,
  - editar,
  - eliminar.
- Estado de datos:
  - local-first.
- Falta:
  - persistencia remota de meals/fotos.

### 6. Shared food catalog

- Modulo: `Shared food catalog`
- Estado: `Implementado, pendiente de prueba real amplia`
- Incluye:
  - alta de producto compartido,
  - barcode manual,
  - barcode scan Android/iOS,
  - lookup de barcode,
  - OCR/AI de etiqueta,
  - score nutricional,
  - guardado en Supabase.
- Backend asociado:
  - `food-catalog-upsert`
  - `food-barcode-lookup`
- Fuente de datos:
  - cache `food_items`,
  - `Open Food Facts`,
  - `USDA` fallback.
- UI adicional:
  - card visual de resultado de barcode con fuente, cache/fresh lookup y confianza.

### 7. Barcode nutrition lookup

- Modulo: `Barcode lookup`
- Estado: `Implementado y validado en dispositivo`
- Plataformas:
  - Android/iOS: scan con camara,
  - desktop/web: lookup manual por codigo.
- Flujo:
  1. usuario escanea o ingresa barcode,
  2. app llama `food-barcode-lookup`,
  3. backend busca en cache Supabase,
  4. si no existe, consulta `Open Food Facts`,
  5. si no existe y hay secret, consulta `USDA`,
  6. cachea en `food_items`,
  7. devuelve nombre, marca, macros y confianza.
- Casos validados:
  - `737628064502` via `Open Food Facts`
  - `030034954949` via `USDA`
- Resultado visible actual:
  - card con nombre,
  - marca,
  - fuente,
  - cache/fresh lookup,
  - source id,
  - confianza.

### 8. Workout manual

- Modulo: `Manual workout`
- Estado: `Implementado`
- Incluye:
  - sesiones manuales,
  - sets,
  - reps,
  - peso,
  - RPE,
  - notas,
  - fecha,
  - editar y borrar,
  - multiples sets,
  - `Repeat last`,
  - sugerencias recientes,
  - flujo `muscle group -> exercise`.
- Estado de datos:
  - local-first.
- Falta:
  - sync remoto por usuario.

### 9. Workout timers

- Modulo: `Workout timer + rest timer`
- Estado: `Implementado, pendiente de prueba real suficiente`
- Incluye:
  - cronometro total de sesion,
  - cronometro de descanso,
  - sincronizacion con `Duration (min)`,
  - arranque automatico del descanso al agregar o repetir set.

### 10. Dashboard y progreso

- Modulo: `Dashboard / Progress`
- Estado: `Implementado`
- Incluye:
  - resumen diario,
  - targets por goal,
  - recomendaciones simples,
  - peso diario,
  - charts,
  - progreso de fuerza,
  - selector de metrica,
  - `1RM` estimado,
  - agrupado diario corregido.
- Falta:
  - mezclar datos remotos reales por usuario.

### 11. Backend activo

- Modulo: `Supabase backend`
- Estado: `Implementado`
- Edge Functions activas:
  - `meal-photo-analyze`
  - `food-catalog-upsert`
  - `food-barcode-lookup`
- Base de datos usada:
  - `profiles`
  - `body_metrics`
  - `food_items`
  - `meal_entries`
  - `meal_photos`
  - `workout_sessions`
  - `gym_sets`
- IA actual:
  - OpenRouter via backend, no desde cliente Flutter.

## Dependencias importantes entre modulos

### Flujo comida AI

- `Manual food entry`
  -> depende de `Supabase config` para AI
  -> depende de `meal-photo-analyze`
  -> depende de `OpenRouter`

### Flujo barcode

- `Barcode scan`
  -> depende de `mobile_scanner`
  -> depende de `food-barcode-lookup`
  -> depende de `Supabase URL + anon key` en build
  -> depende de `food_items`
  -> depende de `Open Food Facts`
  -> opcionalmente depende de `USDA_FDC_API_KEY`

### Flujo catalogo compartido

- `Shared food catalog`
  -> depende de `food-catalog-upsert`
  -> puede usar `food-barcode-lookup`
  -> puede usar OCR/AI

### Persistencia futura

- `Meals remotos`
  -> dependen de `auth real`
  -> dependen de modelo final de identidad
- `Workouts remotos`
  -> dependen de `auth real`
- `Resultados AI remotos`
  -> dependen de identidad + storage + modelo de meals final

## Validaciones reales ya hechas

- `Supabase init completed` confirmado en telefono Android `SM S916B`.
- `Analyze with AI` desbloqueado en build correcta con `dart-define-from-file`.
- `Barcode scan` funcionando en telefono Android.
- `Open Food Facts` validado en remoto.
- `USDA` validado en remoto.

## Pendiente de prueba real

### Prioridad alta

- foto real de comida con `Analyze with AI` en Android,
- mas productos reales por barcode,
- timers de workout en una sesion real.

### Prioridad media

- shared catalog end-to-end en movil con casos reales,
- evaluar calidad visual de la card de resultado de barcode con varios productos.

## Pendiente siguiente iteracion

### Persistencia remota

- meals remotos por usuario,
- workouts remotos por usuario,
- resultados AI remotos,
- objetivos diarios remotos.

### Auth / identidad

- auth multiusuario completa,
- guest -> cuenta real sin perder datos.

### Salud y fuentes del sistema

- `Health Connect`,
- `HealthKit`,
- permisos y dedupe de workouts.

## Backlog futuro registrado

### Food / data

- busqueda manual por nombre de producto,
- exportacion `CSV/JSON`.

### Wearables / recovery

- wearables via plataformas de salud,
- recovery score explicable.

### Workout UX extra

- audio cues,
- mas automatizacion de sesiones.

### Lifestyle / ecosystem

- Spotify / playlists,
- Strava secundario,
- fotos de tecnica/postura con privacidad reforzada.

## Mapa simplificado para otra IA

Si otra IA necesita una vista compacta, este es el arbol funcional minimo:

- `Myfit`
  - `Core shell`
    - welcome
    - onboarding
    - dashboard
    - progress
    - auth minima
  - `Food`
    - manual food
    - meal photo + AI
    - food gallery
    - shared catalog
    - barcode lookup
      - cache Supabase
      - Open Food Facts
      - USDA
  - `Workout`
    - manual workout
    - timers
    - RPE
    - progreso de fuerza
  - `Backend`
    - meal-photo-analyze
    - food-catalog-upsert
    - food-barcode-lookup
  - `Siguiente`
    - persistencia remota
    - auth completa
    - Health Connect
    - HealthKit
  - `Backlog futuro`
    - busqueda por nombre
    - wearables
    - exportacion
    - recovery score
    - Spotify
    - Strava secundario
