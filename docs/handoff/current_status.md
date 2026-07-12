# Estado actual

## Resumen

El repo quedo listo para continuar en CachyOS con una app Flutter guest-first pero ya muy cerca de `v1.0`: auth OTP funcional, persistencia remota base para `weight + manual meals + meal photos + manual workouts`, export/delete remoto minimo, release Android base saneada, idioma ingles por defecto, selector `EN / ESP`, dark mode, top bar global, barcode/AI/comida conectados a Supabase/OpenRouter, y timers de workout ya probados en dispositivo.

Ultimo estado exacto antes de pausar:

- `manual meals`, `meal photos`, `daily weight` y `manual workouts` ya tienen base hibrida `guest local / auth remoto`.
- La nueva Edge Function `user-data-manage` ya esta desplegada y ofrece `export` + `delete` remoto por usuario autenticado.
- La release Android ya usa `applicationId = com.x11pro.myfit`, label `Myfit` y package nativo corregido en `MainActivity`.
- El warning de Samsung sobre `16 KB compatibility` desaparecio cuando se desinstalo la app vieja `debug` (`com.example.fitness_app`) y se dejo solo la app nueva `release` (`com.x11pro.myfit`).
- `Duration (min)` del workout manual ya no se pisa mientras se edita y `Duration (min)` / `Calories burned` quedaron marcados como opcionales.
- El flujo de auth ya no rebota a splash al pedir OTP, el back funciona mejor y el welcome autenticado muestra `Open app`.
- `flutter analyze` y `flutter test` pasaron correctamente despues de todos estos cambios.
- El siguiente punto exacto NO es rediseñar UI/UX total todavia: primero hay que ejecutar QA real guiada en Android y confirmar `export/delete + rehidratacion real`.

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
- Migraciones nuevas ya aplicadas en remoto:
  - `backend/supabase/migrations/20260711_000003_manual_workout_remote_fields.sql`
  - `backend/supabase/migrations/20260711120001_meal_photos_storage.sql`
- ExecPlans relevantes:
  - `.agent/plans/20260612_supabase_auth_profiles_execplan.md`
  - `.agent/plans/20260620_manual_food_entry_execplan.md`
  - `.agent/plans/20260627_gym_diet_progress_execplan.md`
  - `.agent/plans/2026-06-28-gym-progress-metrics.md`

## Cambios implementados en esta etapa reciente

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
- `mobile/fitness_app/lib/features/auth/presentation/login_screen.dart`
  - split implicito `email -> verify code` por ruta,
  - fix de back navigation,
  - layout estable con teclado,
  - acciones nuevas `Export my data` y `Delete my data` para usuarios autenticados.
- `mobile/fitness_app/lib/features/auth/application/account_data_service.dart`
  - cliente Flutter para invocar `user-data-manage`.
- `mobile/fitness_app/lib/features/auth/application/auth_controller.dart`
  - helper para limpiar providers sincronizados localmente al borrar datos remotos.
- `mobile/fitness_app/lib/shared/app_language.dart`
  - limpieza de textos mezclados EN/ES para dashboard, auth y workout,
  - helpers de localizacion para labels de sets, reps y progreso,
  - nuevos labels para metricas de fuerza y `reps today`,
  - mensajes mas claros para errores de red/servidor,
  - textos de export/delete y labels opcionales en workout.
- `backend/supabase/functions/food-catalog-upsert/index.ts`
  - edge function para extraer datos desde OCR/AI y guardar `food_items` compartidos.
- `backend/supabase/functions/meal-photo-analyze/index.ts`
  - edge function para analizar foto de comida y estimar nombre, calorias, proteina, carbohidratos, grasas, azucar, fibra y confianza.
- `backend/supabase/functions/_shared/openrouter.ts`
  - helper compartido para llamar OpenRouter con `qwen/qwen3-vl-8b-instruct` y parsear JSON multimodal.
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
  - normalizacion de `confidence` entre `0` y `1`,
  - subida remota de `meal photos` a Storage para usuarios autenticados,
  - signed URL remota para preview de foto,
  - cleanup best-effort de fotos viejas.
- `mobile/fitness_app/lib/features/food/application/manual_food_entries_controller.dart`
  - persistencia hibrida local/remota,
  - sync remoto de `meal_entries`,
  - soporte para `photo_id`, `remotePhotoId` y `remotePhotoStoragePath`.
- `mobile/fitness_app/lib/features/food/domain/manual_food_entry.dart`
  - nuevos campos `remotePhotoId` y `remotePhotoStoragePath`.
- `mobile/fitness_app/lib/features/food/presentation/widgets/meal_photo_view.dart`
  - soporte para `NetworkImage` ademas de `FileImage` y `data:`.
- `mobile/fitness_app/test/features/workout/manual_workout_controller_test.dart`
  - test nuevo para sugerencias de ejercicios recientes sin duplicados,
  - verificacion explicita de persistencia local de `RPE` por set.
- `mobile/fitness_app/test/features/workout/manual_workout_screen_test.dart`
  - test del flujo UI para crear multiples sets iguales desde el dialogo.
- `mobile/fitness_app/lib/features/workout/domain/manual_workout_session.dart`
  - nuevos campos persistidos para `totalDurationSeconds`, `activeDurationSeconds` y `restDurationSeconds`.
- `mobile/fitness_app/lib/features/workout/application/manual_workout_controller.dart`
  - compatibilidad local-first para guardar y leer los nuevos tiempos sin romper sesiones viejas.
- `mobile/fitness_app/lib/features/workout/presentation/manual_workout_screen.dart`
  - cronometro general manual de entrenamiento,
  - timer REST con countdown negativo y overtime positivo,
  - guardado real de `tiempo total`, `tiempo activo` y `tiempo de descanso`,
  - alerta de sonido seleccionable,
  - vibracion opcional al llegar `REST` a `0`,
  - preview automatico del sonido al cambiar la opcion elegida,
  - estado visual del boton REST en rojo/verde segun countdown u overtime,
  - fix para que `Duration (min)` no se sobreescriba mientras el usuario tipea.
- `mobile/fitness_app/lib/features/dashboard/application/daily_weight_controller.dart`
  - persistencia hibrida local/remota para peso diario.
- `mobile/fitness_app/lib/features/workout/application/manual_workout_controller.dart`
  - persistencia hibrida local/remota para workouts manuales y sets.
- `mobile/fitness_app/lib/features/dashboard/application/daily_targets_calculator.dart`
  - las rutinas recomendadas por goal ya salen en ingles cuando la app esta en ingles; no quedan hardcodeadas solo en espanol.
- `mobile/fitness_app/lib/shared/app_language.dart`
  - nuevos textos para alertas REST, sonido, vibracion y labels relacionados.
- `mobile/fitness_app/pubspec.yaml`
  - nuevas dependencias `audioplayers` y `vibration` para alertas de descanso en Android.
- `mobile/fitness_app/test/features/workout/manual_workout_screen_test.dart`
  - tests nuevos para countdown REST, persistencia de settings de alerta y guardado de tiempos.
- `mobile/fitness_app/test/features/dashboard/daily_targets_calculator_test.dart`
  - ajuste para verificar que la recomendacion por defecto sale en ingles.
- `backend/supabase/functions/_shared/openrouter.ts`
  - helper comun para llamadas a OpenRouter con imagen + JSON.
- `backend/supabase/functions/food-catalog-upsert/index.ts`
  - migracion real de OpenAI a OpenRouter,
  - correcciones TS/Deno minimas para deploy limpio.
- `backend/supabase/functions/meal-photo-analyze/index.ts`
  - migracion real de OpenAI a OpenRouter con parsing JSON mas robusto.
- `backend/supabase/functions/user-data-manage/index.ts`
  - export/delete minimo real de datos por usuario autenticado.
- `docs/release/android_release_checklist.md`
  - checklist de release Android base.
- `docs/legal/privacy_policy_draft.md`
  - borrador inicial de politica de privacidad.
- `docs/legal/data_export_delete.md`
  - notas tecnicas y funcionales de export/delete.
- `docs/qa/android_real_device_checklist.md`
  - checklist de QA real Android para cerrar antes de `v1.0`.
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

En esta sesion adicionalmente se verifico:

```bash
flutter analyze
flutter test
```

Resultado:

- `flutter test`: paso.
- `flutter analyze`: paso con 4 warnings deprecados ya existentes por `value` -> `initialValue` en formularios, sin errores nuevos de la migracion OpenRouter.
- La API key de OpenRouter fue validada manualmente fuera del repo con respuesta correcta y prueba multimodal minima OK.
- `deno fmt` y `deno check` no se pudieron correr en la shell Windows de esta sesion porque `deno` no estaba instalado ahi.

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

## Verificaciones hechas en esta etapa reciente

En esta sesion se ejecuto correctamente:

```bash
npx supabase secrets set OPENROUTER_API_KEY=... OPENROUTER_MODEL=qwen/qwen3-vl-8b-instruct --project-ref cyecalxewqcyxxglxloa
npx supabase functions deploy food-catalog-upsert --project-ref cyecalxewqcyxxglxloa --workdir backend
npx supabase functions deploy meal-photo-analyze --project-ref cyecalxewqcyxxglxloa --workdir backend
npx supabase migration repair --status reverted 20260711 --linked --workdir backend
npx supabase db push --linked --workdir backend
npx supabase functions deploy user-data-manage --project-ref cyecalxewqcyxxglxloa --workdir backend
```

En la sesion mas reciente tambien se ejecuto correctamente:

```bash
flutter analyze
flutter test
flutter devices
flutter run -d linux --dart-define=SUPABASE_URL=placeholder --dart-define=SUPABASE_ANON_KEY=placeholder
```

En la sesion actual de Windows tambien se ejecuto correctamente:

```bash
npx supabase projects list
npx supabase link --project-ref cyecalxewqcyxxglxloa --workdir backend --yes
npx supabase functions list --project-ref cyecalxewqcyxxglxloa --workdir backend
flutter run -d edge --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter run -d windows --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter build apk --debug --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Resultado confirmado de esa prueba:

- `flutter analyze` sigue OK.
- `flutter test` sigue OK en toda la app.
- El APK `release` ahora compila correctamente y pasa `zipalign -P 16`.
- El warning `16 KB compatibility` desaparecio en `SM S916B` cuando se dejo solo la app nueva `release` `com.x11pro.myfit` y se desinstalo la vieja `com.example.fitness_app`.
- La release instalada ya no deberia confundirse con la debug vieja.

## Verificaciones hechas en la sesion mas reciente de Android/workout

En la sesion mas reciente en CachyOS se ejecuto correctamente:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test test/features/workout/manual_workout_screen_test.dart
flutter test test/features/workout/manual_workout_controller_test.dart
flutter test test/features/dashboard/daily_targets_calculator_test.dart
flutter build apk --debug --target-platform android-arm64
flutter install --debug -d "adb-RZCW82F6TRL-J7io0E._adb-tls-connect._tcp"
flutter run -d "adb-RZCW82F6TRL-J7io0E._adb-tls-connect._tcp"
```

Resultado confirmado:

- El primer intento de instalacion debug fallo por `INSTALL_FAILED_NO_MATCHING_ABIS` porque el APK viejo solo traia `x86_64`; se resolvio recompilando para `android-arm64`.
- La app debug quedo instalada y abierta correctamente en `SM S916B`.
- El preview automatico del sonido REST al cambiar selector quedo probado en dispositivo.
- La vibracion REST al llegar a `0` quedo confirmada por el usuario en dispositivo.
- El flujo actual de workout timer/rest timer se considera funcional en Android real.
- `flutter test` sigue OK.
- La app Flutter arranca en Linux y llega a inicializar Supabase cuando se le pasan `--dart-define`.
- En Windows ya se valido `SUPABASE_ACCESS_TOKEN`, `SUPABASE_URL` y `SUPABASE_ANON_KEY` reales durante la sesion, pero no quedaron persistidos en archivos del repo.
- `supabase link` ya quedo ejecutado localmente en esta maquina y `functions list` confirmo `food-catalog-upsert` y `meal-photo-analyze` activas en remoto.
- La app arranca tanto en `Edge` como en `Windows` con Supabase inicializado cuando recibe `--dart-define` reales.
- En Windows ya existe automatizacion local para no repetir `--dart-define` manualmente en Android/web/desktop: `scripts/flutter/save_local_dart_defines.ps1`, `scripts/flutter/build_android_debug.ps1`, `scripts/flutter/build_android_release.ps1`, `scripts/flutter/run_android_debug.ps1`, `scripts/flutter/run_windows_debug.ps1` y `scripts/flutter/run_edge_debug.ps1`.
- Se implemento barcode real en `Add meal`: campo manual, `Scan barcode` con camara en Android/iOS, lookup remoto por `Open Food Facts` y cache en `food_items` via nueva Edge Function `food-barcode-lookup`.
- El mismo flujo de barcode ya quedo conectado tambien a `shared food catalog` para precargar productos empaquetados antes de guardar el item compartido.
- La UI de barcode se pulo en `Add meal` y `shared food catalog` con una card de resultado visible que muestra nombre, marca, fuente, cache/fresh lookup, source id y confianza antes de guardar.
- El flujo web ya no se rompe al elegir foto desde galeria: `manual food entry` ahora soporta `data:` URLs y preview sin depender de `path_provider` para web.
- Se agrego una galeria local-first de comidas con foto y resumen nutricional en `/food/gallery`, basada en la persistencia local ya existente.
- El flujo de `gym tracker` ahora incluye cronometro de sesion y cronometro de descanso entre series dentro de la misma pantalla.
- El cronometro de sesion sincroniza el campo `Duration (min)` y el cronometro de descanso arranca automaticamente al agregar o repetir un set.
- Se regenero `app-debug.apk` con ese flujo nuevo para probar en Android.
- Tambien se regenero `app-debug.apk` con `SUPABASE_URL` y `SUPABASE_ANON_KEY` reales para destrabar `Analyze with AI` en Android.
- Quedo preparado tambien el flujo de `flutter run -d windows`, `flutter run -d edge` y `flutter build apk --release` usando `--dart-define-from-file` sobre `mobile/fitness_app/dart_defines.local.json`.
- En esta iteracion tambien se desplego `food-barcode-lookup` y se verifico con barcode real `737628064502`, devolviendo nombre, marca y macros desde `Open Food Facts`.
- Tambien se instalo la build debug mas reciente directamente en el telefono `SM S916B` por `flutter run --no-resident` y se confirmo en logs `Supabase init completed`; el error previo de `SUPABASE_URL/SUPABASE_ANON_KEY` venia de una instalacion vieja del APK.
- Se agregaron `docs/product/status_map.md`, `docs/product/status_map_visual.md` y `prompts/notebooklm_status_map_diagram_prompt.md` para entregar a otra IA un mapa estructurado y una vista Mermaid local del estado del producto.

Smoke tests remotos confirmados:

- `food-catalog-upsert` respondio OK en `mode=extract`.
- `meal-photo-analyze` ya no falla por `OPENAI_API_KEY` y ahora pega a OpenRouter.
- `food-barcode-lookup` respondio `200 OK` en remoto con cache `food_items` + `Open Food Facts` para barcode empaquetado.
- El fallback `USDA` ya quedo implementado y validado en remoto dentro de `food-barcode-lookup` despues de cargar `USDA_FDC_API_KEY`; caso confirmado con barcode `030034954949`, devolviendo `source=usda`.
- El error observado en `meal-photo-analyze` fue por imagen base64 invalida de prueba, lo cual confirma que la ruta nueva ya esta activa.
- `food-catalog-upsert` tambien respondio `200 OK` con payload manual autenticado usando la anon key real.
- `meal-photo-analyze` respondio autenticado y llego a OpenRouter; el riesgo pendiente real esta en probar con una foto valida y confirmar que no aparezcan limites de credito o proveedor.

## Commits relevantes

- `efc2e21` `Add AMARILLO continuity rule`
- `f80f5df` `Update workout UX and reboot handoff`
- `9986cb7` `Generate Flutter app platforms`
- `eb29587` `Add Flutter scaffold and initial schema`
- `c4466fe` `Add project structure and planning docs`

## Pendientes inmediatos

1. Ejecutar QA real guiada en `SM S916B` con `docs/qa/android_real_device_checklist.md`.
2. Confirmar en Android que `Export my data` y `Delete my data` funcionan de punta a punta con `user-data-manage`.
3. Probar en Android varios productos reales con `Scan barcode` y confirmar autocompletado correcto de nombre/macros tanto para `Open Food Facts` como para `USDA` cuando corresponda.
4. Probar en Android con foto real que `manual food entry` guarda la foto remota, la muestra en gallery y deja lanzar `Analyze with AI`.
5. Probar end-to-end la pantalla Flutter del catalogo compartido con una imagen real y la build Android/web ya configurada con Supabase.
6. Integrar los tres tiempos de workout (`total / activo / descanso`) al dashboard y al analisis general.
7. Preparar firma release real y volver a generar build release firmada para pre-publicacion.
8. Publicar version final de privacy policy y cerrar contacto/proceso de soporte para export/delete.
9. Reevaluar en ese punto si ya conviene abrir la mejora total de UI/UX; ese sigue siendo el siguiente gran paso despues de QA real + cierre release/legal.

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
- `gym tracker` ahora incluye dos ayudas nuevas locales: cronometro de sesion y cronometro de descanso; por ahora no se persisten como eventos separados ni corren en background.
- El modulo workout ya guarda `totalDurationSeconds`, `activeDurationSeconds` y `restDurationSeconds` por sesion; todavia falta explotarlos en dashboard/analitica.
- Si la build Android falla tras tocar NDK, correr `flutter clean` antes de volver a `flutter build apk --debug`.
- Las edge functions `food-catalog-upsert` y `meal-photo-analyze` quedaron migradas localmente a OpenRouter y redeployadas en Supabase.
- La nueva edge function `food-barcode-lookup` usa `Open Food Facts` como fuente primaria gratuita, cachea en `food_items` y ya incluye fallback `USDA` validado en remoto.
- Los secrets remotos vigentes para AI son `OPENROUTER_API_KEY` y `OPENROUTER_MODEL`; ya no corresponde documentar `OPENAI_API_KEY` como dependencia actual de estas funciones.
- El modelo efectivamente adoptado y validado para esta iteracion es `qwen/qwen3-vl-8b-instruct` via OpenRouter.
- La prueba end-to-end real del frontend con Supabase si sigue bloqueada en esta maquina hasta tener `SUPABASE_URL` y `SUPABASE_ANON_KEY` reales o un `SUPABASE_ACCESS_TOKEN` que permita recuperarlas por CLI.
- `food-catalog-upsert` respondio OK en smoke test remoto; `meal-photo-analyze` respondio contra OpenRouter y fallo solo con una imagen base64 invalida de prueba.
- `deno` no estuvo disponible en esta maquina, por lo que no se corrieron `deno fmt` ni `deno check` antes del deploy.
- Por seguridad, conviene rotar `OPENROUTER_API_KEY` y `SUPABASE_ACCESS_TOKEN` porque fueron expuestos durante la sesion.
- Recordatorio explicito para la proxima sesion: reimplementar autenticacion sin Auth0 antes de conectar persistencia remota multiusuario.
- `currentWeightKg` del onboarding se guarda en `body_metrics`, no en `profiles`, porque el esquema actual ya separa ese dato historico.
- El worktree del repo contiene cambios previos y/o de entorno no relacionados, especialmente en `backend/supabase/functions/meal-photo-analyze` y varios archivos Android; revisar cuidadosamente antes de hacer commits amplios.
- En esta maquina Windows ya se activo `Developer Mode`, por lo que `flutter run -d windows` vuelve a compilar; la sesion de debug puede perder conexion despues del arranque, pero la app si levanta e inicializa Supabase.
- La nueva galeria de comidas es local-first; todavia no sube fotos ni meals a Supabase Storage/Postgres.
- En web se corrigio el flujo de foto guardando `data:` URLs localmente; eso resuelve preview/AI, pero puede crecer mas que un path local y no es el target principal a largo plazo.
- No persistir API keys en `docs/`, `prompts/`, `.env.example` ni commits. Recargarlas solo como variables de entorno o secrets de Supabase.
- `mobile/fitness_app/dart_defines.local.json` queda ignorado por Git y es el lugar local recomendado para recordar `SUPABASE_URL` y `SUPABASE_ANON_KEY` en esta maquina sin volver a escribir `--dart-define` a mano.
- Desde ahora el punto de entrada recomendado en Windows es `scripts/flutter/`; no depender de memorizar flags manuales para `android`, `windows` o `edge`.
- Si se necesita un diagrama entendible del producto para terceros o para NotebookLM, usar `docs/product/status_map.md` como fuente estructurada y `docs/product/status_map_visual.md` como referencia visual local.
- La rutina recomendada por goal debe mantenerse en ingles cuando el idioma de app este en ingles; ya no asumir textos hardcodeados en espanol en esa parte del dashboard/workout.
- Para instalar debug en el `SM S916B`, si aparece `INSTALL_FAILED_NO_MATCHING_ABIS`, recompilar con `flutter build apk --debug --target-platform android-arm64` antes de reinstalar.
- El mejor momento para una mejora total de UI/UX aun no es ahora; primero cerrar auth + sync remoto y conectar los tres tiempos de workout al analisis/dashboard.
- Desde este punto exacto, el siguiente bloque de trabajo debe continuar desde `QA real Android + export/delete real + cierre release/legal`, no reiniciar sobre auth/persistencia base porque eso ya quedo avanzado.

## Regla persistente del usuario

Si el usuario escribe `AMARILLO` en mayusculas, el agente debe generar o actualizar el paquete de continuidad antes de cerrar la sesion o cambiar de sistema operativo.

Ese paquete debe dejar como minimo:

- estado actualizado del proyecto,
- pasos de setup o resume del OS destino,
- instrucciones persistentes de agente si hicieron falta,
- prompt de reanudacion actualizado,
- commit y push si Git esta disponible.
