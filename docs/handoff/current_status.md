# Estado actual

## Resumen

El repo quedo listo para continuar en CachyOS con una app Flutter usable sin login obligatorio, idioma ingles por defecto, cambio consistente a espanol desde el selector `EN / ESP`, dark mode activo, top bar global con `back/home/menu`, comidas manuales persistidas localmente, resumen diario por fecha, peso diario, macros extendidas locales, registro manual de gym con sets/peso por fecha, edicion de entrenamientos, objetivos diarios segun goal, pantalla separada de progreso con filtro por ejercicio y metricas de fuerza mas utiles, y backend de catalogo compartido + analisis AI por foto ya migrado a OpenRouter.

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
  - `.agent/plans/20260627_gym_diet_progress_execplan.md`
  - `.agent/plans/2026-06-28-gym-progress-metrics.md`

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
  - persistencia local durable,
  - macros extendidas por comida: carbohidratos, grasas, azucar y fibra,
  - guardado local del `confidence` devuelto por AI para fotos de comida.
- `mobile/fitness_app/lib/features/workout/`
  - registro manual local-first de sesiones de gym,
  - carga manual de sets, reps, peso y RPE opcional,
  - guardado por fecha para seguimiento historico,
  - borrado local de sesiones,
  - edicion de sesiones existentes,
  - edicion y borrado de sets cargados,
  - `repeticiones` visibles junto a `sets` en resumenes de sesion y dashboard.
- `mobile/fitness_app/lib/features/dashboard/`
  - targets diarios derivados de `goal + peso + actividad laboral + calorias de entrenamiento`,
  - recomendaciones simples de rutina y foco nutricional segun objetivo,
  - diagrama de progreso para peso levantado, peso corporal, calorias quemadas y vista combinada,
  - pantalla separada de progreso,
  - filtro por ejercicio para la vista de fuerza,
  - selector de metrica de fuerza entre `peso maximo`, `volumen` y `1RM estimado`,
  - agrupado diario corregido para sumar calorias y volumen por fecha,
  - CTA principal del dia,
  - secciones plegables para movil,
  - grafico de progreso tipo linea/area.
- `mobile/fitness_app/lib/shared/widgets/app_top_bar.dart`
  - top bar reusable con iconos de `back`, `home` y `menu`,
  - accesos rapidos globales desde menu a dashboard, profile, meal, workout, progress y welcome.
- `mobile/fitness_app/lib/features/auth/`
  - login screen alineada con ingles por defecto y traduccion al espanol via `AppStrings`.
- `mobile/fitness_app/lib/shared/app_language.dart`
  - limpieza de textos mezclados EN/ES para dashboard, auth y workout,
  - helpers de localizacion para labels de sets, reps y progreso,
  - nuevos labels para metricas de fuerza y `reps today`.
- `backend/supabase/functions/food-catalog-upsert/index.ts`
  - edge function para extraer datos desde OCR/AI y guardar `food_items` compartidos.
- `backend/supabase/functions/meal-photo-analyze/index.ts`
  - edge function para analizar foto de comida y estimar nombre, calorias, proteina, carbohidratos, grasas, azucar, fibra y confianza.
- `backend/supabase/migrations/20260620_000002_food_items_shared_catalog.sql`
  - indice unico para catalogo compartido por `source + source_id`,
  - columnas `nutrition_quality_score` y `nutrition_quality_reason`.
- `mobile/fitness_app/lib/features/food/presentation/shared_food_catalog_screen.dart`
  - alta de productos compartidos,
  - foto de etiqueta,
  - OCR/manual input,
  - score nutricional `0-5`.
- `mobile/fitness_app/test/widget_test.dart`
  - test actualizado al welcome screen en ingles por defecto,
  - test del cambio a espanol desde el selector de idioma.
- `mobile/fitness_app/test/features/food/manual_food_entries_controller_test.dart`
  - test de persistencia local y resumen nutricional para macros extendidas y confianza.
- `mobile/fitness_app/test/features/dashboard/daily_targets_calculator_test.dart`
  - test de calculo de objetivos diarios, recomendaciones por goal y filtro de progreso por ejercicio,
  - test de `training volume`, `estimated 1RM` y suma diaria de calorias por multiples sesiones.
- `mobile/fitness_app/test/features/workout/manual_workout_controller_test.dart`
  - test de persistencia local y actualizacion de sesiones gym con sets y fecha.
- `mobile/fitness_app/lib/features/workout/presentation/manual_workout_screen.dart`
  - fix del crash al abrir `Log Workout` por lectura reactiva en `initState`.
- `mobile/fitness_app/lib/features/workout/application/manual_workout_controller.dart`
  - provider de ejercicios recientes para sugerir carga rapida dentro de la sesion.
- `mobile/fitness_app/lib/features/workout/presentation/manual_workout_screen.dart`
  - boton `Repeat last` para duplicar el ultimo set cargado,
  - chips con ejercicios recientes al agregar sets nuevos,
  - campo `Sets` para crear multiples series iguales de una vez,
  - selector visual de `RPE` con valores `6-10` y medios puntos,
  - flujo reordenado a `muscle group -> exercise`,
  - dropdown de ejercicios populares por grupo muscular,
  - opcion de `custom exercise` cuando el ejercicio no esta en la lista.
- `mobile/fitness_app/lib/features/food/presentation/shared_food_catalog_screen.dart`
  - validacion previa de configuracion Supabase,
  - manejo mas robusto de respuestas incompletas o errores de Edge Functions.
- `mobile/fitness_app/lib/features/food/presentation/manual_food_entry_screen.dart`
  - validacion previa de configuracion Supabase,
  - manejo mas robusto de respuesta AI,
  - normalizacion de `confidence` entre `0` y `1`.
- `mobile/fitness_app/test/features/workout/manual_workout_controller_test.dart`
  - test nuevo para sugerencias de ejercicios recientes sin duplicados,
  - verificacion explicita de persistencia local de `RPE` por set.
- `mobile/fitness_app/test/features/workout/manual_workout_screen_test.dart`
  - test del flujo UI para crear multiples sets iguales desde el dialogo.
- `backend/supabase/functions/_shared/openrouter.ts`
  - helper comun para llamadas a OpenRouter con imagen + JSON.
- `backend/supabase/functions/food-catalog-upsert/index.ts`
  - migracion real de OpenAI a OpenRouter,
  - correcciones TS/Deno minimas para deploy limpio.
- `backend/supabase/functions/meal-photo-analyze/index.ts`
  - migracion real de OpenAI a OpenRouter con parsing JSON mas robusto.
- `docs/research/free_food_photo_llm_recommendation.md`
  - contiene referencia vieja a `Qwen2.5-VL-7B-Instruct`; el modelo realmente adoptado en esta iteracion es `qwen/qwen3-vl-8b-instruct` via OpenRouter.

## Estado del entorno CachyOS

- Flutter operativo desde `/home/x11pro_lnx_up/flutter`.
- `flutter doctor -v`: sin errores.
- Android SDK operativo en `/home/x11pro_lnx_up/Android/Sdk`.
- `android/app/build.gradle.kts` alineado a `ndkVersion = "28.2.13676358"`.
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
flutter clean
flutter build apk --debug
```

APK debug mas reciente generado en:

- `mobile/fitness_app/build/app/outputs/flutter-apk/app-debug.apk`
- regenerado despues de la limpieza de idiomas y del pulido visual de dashboard/progreso.
- regenerado tambien despues de agregar top bar global y alinear NDK 28.

## Verificaciones hechas en la ultima sesion

En la ultima sesion se volvio a ejecutar correctamente:

```bash
flutter pub get
flutter analyze
flutter test
```

Tambien en esta sesion se volvieron a ejecutar correctamente:

```bash
dart format mobile/fitness_app/lib/features/workout/application/manual_workout_controller.dart mobile/fitness_app/lib/features/workout/presentation/manual_workout_screen.dart mobile/fitness_app/lib/features/food/presentation/shared_food_catalog_screen.dart mobile/fitness_app/lib/features/food/presentation/manual_food_entry_screen.dart mobile/fitness_app/lib/shared/app_language.dart mobile/fitness_app/test/features/workout/manual_workout_controller_test.dart
flutter analyze
flutter test
```

## Verificaciones hechas en esta sesion

En esta sesion se ejecuto correctamente:

```bash
npx supabase secrets set OPENROUTER_API_KEY=... OPENROUTER_MODEL=qwen/qwen3-vl-8b-instruct --project-ref cyecalxewqcyxxglxloa
npx supabase functions deploy food-catalog-upsert --project-ref cyecalxewqcyxxglxloa --workdir backend
npx supabase functions deploy meal-photo-analyze --project-ref cyecalxewqcyxxglxloa --workdir backend
```

Smoke tests remotos confirmados:

- `food-catalog-upsert` respondio OK en `mode=extract`.
- `meal-photo-analyze` ya no falla por `OPENAI_API_KEY` y ahora pega a OpenRouter.
- El error observado en `meal-photo-analyze` fue por imagen base64 invalida de prueba, lo cual confirma que la ruta nueva ya esta activa.

## Commits relevantes

- `efc2e21` `Add AMARILLO continuity rule`
- `f80f5df` `Update workout UX and reboot handoff`
- `9986cb7` `Generate Flutter app platforms`
- `eb29587` `Add Flutter scaffold and initial schema`
- `c4466fe` `Add project structure and planning docs`

## Pendientes inmediatos

1. Probar end-to-end la pantalla Flutter del catalogo compartido con una imagen real y `--dart-define` para Supabase.
2. Probar end-to-end el boton `Analyze with AI` en `manual food entry` con una foto valida de comida.
3. Validar en movil la UX nueva de workout: `muscle group -> exercise`, sets multiples y selector RPE.
4. Si OpenRouter devuelve respuestas incompletas en casos reales, ajustar prompt/parsing sin reabrir analisis ya cerrados.
5. Empezar a mostrar `RPE` en historial/progreso si hace falta para analisis de progresion en gym.
6. Reintroducir autenticacion en una proxima iteracion sin Auth0, probablemente sobre Supabase o guest identity persistente.
7. Conectar `manual food entry` a persistencia remota cuando quede definido el modelo final de identidad.
8. Conectar workouts manuales, resultados AI y objetivos diarios a persistencia remota cuando quede definido el modelo final de identidad.

## Riesgos o notas

- El package name Android sigue siendo el default de Flutter: `com.example.fitness_app`.
- Falta definir bundle identifier iOS real.
- No hay claves reales ni `.env` comprometidos en el repo.
- La app esta temporalmente en guest mode para destrabar UX y desarrollo de producto.
- El perfil guest y las comidas manuales ya persisten localmente con `shared_preferences`.
- El flujo manual actual ya muestra y guarda `carbs`, `fat`, `sugar`, `fiber` y `confidence` cuando vienen del analisis AI.
- La UI principal quedo revisada para evitar mezcla accidental de ingles/espanol en dashboard, auth y workout; el selector `EN / ESP` cambia el copy visible del flujo principal.
- Todas las pantallas principales ahora usan top bar uniforme con `back`, `home` y `menu`.
- Los workouts manuales y el progreso de gym aun son local-first; no se sincronizan con Supabase todavia.
- `RPE` ya se guarda dentro de cada `GymSetEntry` junto con los datos del set y la fecha de su sesion, lo que deja la base lista para futuras metricas de progresion.
- El flujo de alta de sets ahora es mas guiado: primero grupo muscular, luego ejercicio sugerido, y solo despues entrada manual si hace falta.
- La pantalla de progreso de fuerza ahora deja alternar entre `peso maximo`, `volumen` y `1RM estimado`; `1RM` es solo una estimacion educativa.
- El dashboard y el historial de workout ya muestran `repeticiones` junto a `sets`, lo que mejora la lectura rapida de carga total.
- Si la build Android falla tras tocar NDK, correr `flutter clean` antes de volver a `flutter build apk --debug`.
- Las edge functions `food-catalog-upsert` y `meal-photo-analyze` quedaron migradas localmente a OpenRouter y redeployadas en Supabase.
- Los secrets remotos vigentes para AI son `OPENROUTER_API_KEY` y `OPENROUTER_MODEL`; ya no corresponde documentar `OPENAI_API_KEY` como dependencia actual de estas funciones.
- El modelo efectivamente adoptado y validado para esta iteracion es `qwen/qwen3-vl-8b-instruct` via OpenRouter.
- La prueba end-to-end real del frontend con Supabase ya no esta bloqueada por secrets faltantes; el siguiente paso real es correr Flutter con foto valida y validar la UX final.
- `food-catalog-upsert` respondio OK en smoke test remoto; `meal-photo-analyze` respondio contra OpenRouter y fallo solo con una imagen base64 invalida de prueba.
- `deno` no estuvo disponible en esta maquina, por lo que no se corrieron `deno fmt` ni `deno check` antes del deploy.
- Por seguridad, conviene rotar `OPENROUTER_API_KEY` y `SUPABASE_ACCESS_TOKEN` porque fueron expuestos durante la sesion.
- Recordatorio explicito para la proxima sesion: reimplementar autenticacion sin Auth0 antes de conectar persistencia remota multiusuario.
- `currentWeightKg` del onboarding se guarda en `body_metrics`, no en `profiles`, porque el esquema actual ya separa ese dato historico.
- El worktree del repo contiene cambios previos y/o de entorno no relacionados, especialmente en `backend/supabase/functions/meal-photo-analyze` y varios archivos Android; revisar cuidadosamente antes de hacer commits amplios.

## Regla persistente del usuario

Si el usuario escribe `AMARILLO` en mayusculas, el agente debe generar o actualizar el paquete de continuidad antes de cerrar la sesion o cambiar de sistema operativo.

Ese paquete debe dejar como minimo:

- estado actualizado del proyecto,
- pasos de setup o resume del OS destino,
- instrucciones persistentes de agente si hicieron falta,
- prompt de reanudacion actualizado,
- commit y push si Git esta disponible.
