# Estado actual

## Resumen

El repo quedo listo para continuar en CachyOS con una app Flutter usable sin login obligatorio, idioma ingles por defecto, dark mode activo, comidas manuales persistidas localmente, resumen diario por fecha, peso diario y base de analisis AI por foto conectada a backend.

## Estado de codigo

- Remoto configurado: `origin -> https://github.com/X11pro/Myfit.git`.
- App Flutter real creada en `mobile/fitness_app`.
- Plataformas generadas: `android`, `ios`, `linux`, `macos`, `web`, `windows`.
- Scaffold actual:
  - `welcome/splash` con selector `EN / ESP`
  - `onboarding`
  - `dashboard`
  - `manual food entry`
  - `daily summary + daily weight` local-first
  - `meal photo attach` y boton `Analyze with AI`
  - router con `go_router`
  - estado con `Riverpod`
  - perfil guest persistido localmente con `shared_preferences`
- Bootstrap de Supabase preparado en `lib/core/bootstrap.dart`.
- Migracion inicial SQL creada en `backend/supabase/migrations/20260612_000001_initial_schema.sql`.
- Segunda migracion creada y aplicada en remoto: `backend/supabase/migrations/20260620_000002_food_items_shared_catalog.sql`.
- ExecPlans relevantes:
  - `.agent/plans/20260612_supabase_auth_profiles_execplan.md`
  - `.agent/plans/20260620_manual_food_entry_execplan.md`

## Cambios implementados en esta sesion

- `mobile/fitness_app/lib/features/splash/presentation/splash_screen.dart`
  - bienvenida en dark mode,
  - ingles por defecto,
  - selector `EN / ESP`,
  - entrada directa sin auth.
- `mobile/fitness_app/lib/shared/app_state.dart`
  - carga de sesion actual si existe,
  - fallback a perfil guest local,
  - persistencia local de onboarding con `shared_preferences`.
- `mobile/fitness_app/lib/features/onboarding/presentation/onboarding_screen.dart`
  - textos bilingues,
  - guardado local en guest mode,
  - redireccion al dashboard.
- `mobile/fitness_app/lib/features/dashboard/presentation/dashboard_screen.dart`
  - dark mode base,
  - acciones rapidas,
  - lectura de comidas manuales locales,
  - lista de comidas del dia,
  - acceso a catalogo compartido,
  - resumen diario local,
  - peso diario local,
  - historial diario local.
- `mobile/fitness_app/lib/features/food/`
  - primer flujo local-first de `manual food entry`,
  - pantalla para aportar productos al catalogo compartido,
  - soporte para OCR/AI de etiquetas y score nutricional `0-5`,
  - fotos locales por comida,
  - edicion/borrado,
  - persistencia local durable.
- `backend/supabase/functions/food-catalog-upsert/index.ts`
  - edge function para extraer datos desde OCR/AI y guardar `food_items` compartidos.
- `backend/supabase/functions/meal-photo-analyze/index.ts`
  - edge function para analizar foto de comida y estimar nombre, calorias, proteina, macros y confianza.
- `backend/supabase/migrations/20260620_000002_food_items_shared_catalog.sql`
  - indice unico para catalogo compartido por `source + source_id`,
  - columnas `nutrition_quality_score` y `nutrition_quality_reason`.
- `mobile/fitness_app/lib/features/food/presentation/shared_food_catalog_screen.dart`
  - alta de productos compartidos,
  - foto de etiqueta,
  - OCR/manual input,
  - score nutricional `0-5`.
- `mobile/fitness_app/test/widget_test.dart`
  - test actualizado al welcome screen en ingles por defecto.

## Estado del entorno CachyOS

- Flutter operativo desde `/home/x11pro_lnx_up/flutter`.
- `flutter doctor -v`: sin errores.
- Android SDK operativo en `/home/x11pro_lnx_up/Android/Sdk`.
- `cmdline-tools` instalados en `~/Android/Sdk/cmdline-tools/latest`.
- Licencias Android aceptadas.
- Chromium instalado via Flatpak y visible para Flutter web.
- Shell local actualizado fuera del repo para exponer:
  - `PATH` de Flutter,
  - `JAVA_HOME`,
  - `ANDROID_HOME`,
  - `ANDROID_SDK_ROOT`,
  - `CHROME_EXECUTABLE`.

## Verificaciones ya hechas

En CachyOS se ejecuto correctamente:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter doctor -v
```

## Commits relevantes

- `efc2e21` `Add AMARILLO continuity rule`
- `9986cb7` `Generate Flutter app platforms`
- `eb29587` `Add Flutter scaffold and initial schema`
- `c4466fe` `Add project structure and planning docs`

## Pendientes inmediatos

1. Seguir iterando la UX real cuando llegue el Figma.
2. Reintroducir autenticacion en una proxima iteracion sin Auth0, probablemente sobre Supabase o guest identity persistente.
3. Conectar `manual food entry` a persistencia remota cuando quede definido el modelo final de identidad.
4. Agregar edicion/borrado y persistencia local de comidas manuales.
5. Configurar `OPENAI_API_KEY` en Supabase para habilitar AI real en `food-catalog-upsert` y `meal-photo-analyze`.
6. Probar end-to-end la pantalla Flutter del catalogo compartido y el boton `Analyze with AI` contra las funciones ya desplegadas.
7. Conectar los resultados AI a `meal_entries` remotos cuando se defina el modelo final de identidad.

## Riesgos o notas

- El package name Android sigue siendo el default de Flutter: `com.example.fitness_app`.
- Falta definir bundle identifier iOS real.
- No hay claves reales ni `.env` comprometidos en el repo.
- La app esta temporalmente en guest mode para destrabar UX y desarrollo de producto.
- El perfil del invitado ya persiste localmente, pero las comidas manuales aun viven solo en memoria.
- La migracion y las edge functions `food-catalog-upsert` y `meal-photo-analyze` ya quedaron desplegadas.
- La extraccion AI desde imagen aun depende de configurar `OPENAI_API_KEY` como secret en Supabase.
- Recordatorio explicito para la proxima sesion: reimplementar autenticacion sin Auth0 antes de conectar persistencia remota multiusuario.
- `currentWeightKg` del onboarding se guarda en `body_metrics`, no en `profiles`, porque el esquema actual ya separa ese dato historico.
- El worktree del repo contiene muchos cambios previos y/o de entorno no relacionados; revisar cuidadosamente antes de hacer commits amplios.

## Regla persistente del usuario

Si el usuario escribe `AMARILLO` en mayusculas, el agente debe generar o actualizar el paquete de continuidad antes de cerrar la sesion o cambiar de sistema operativo.

Ese paquete debe dejar como minimo:

- estado actualizado del proyecto,
- pasos de setup o resume del OS destino,
- instrucciones persistentes de agente si hicieron falta,
- prompt de reanudacion actualizado,
- commit y push si Git esta disponible.
