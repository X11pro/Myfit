# Prompt inicial para agente

Usa este prompt al abrir el repositorio en el nuevo sistema:

```text
Lee primero AGENTS.md, docs/product/fitness_product_plan.md, docs/handoff/current_status.md y el resume del OS actual en docs/setup/.
Lee tambien docs/research/free_food_photo_llm_recommendation.md.

Quiero continuar Myfit exactamente desde el ultimo punto.

Contexto inmediato:
- Ya existe flujo guest-first funcional.
- Ya existe modulo de gym con sesiones, sets, edicion y progreso, con persistencia hibrida local/remota para usuarios autenticados.
- Ya existe top bar global con back/home/menu.
- Ya se limpio la mezcla EN/ES y el selector EN / ESP cambia el copy visible.
- Ya se alineo Android a ndkVersion 28.2.13676358.
- Ya existe progreso de fuerza con selector de metrica: peso maximo, volumen y 1RM estimado.
- Ya se muestran repeticiones al lado de sets en workout/dashboard.
- Ya existe carga rapida minima en workout: `Repeat last` + sugerencias de ejercicios recientes.
- El dialogo de workout ya fue mejorado para usar `muscle group -> exercise`, crear multiples sets iguales y capturar `RPE` visual con persistencia por set.
- `gym tracker` ya incluye cronometro de sesion y cronometro de descanso; el de sesion sincroniza `Duration (min)` y REST solo inicia o se detiene manualmente desde su boton, nunca al agregar, editar o repetir sets.
- El workout manual ahora guarda `totalDurationSeconds`, `activeDurationSeconds` y `restDurationSeconds` por sesion.
- El timer REST se detiene automaticamente al llegar al objetivo, conserva ese objetivo para el siguiente descanso y no continua en positivo.
- La alerta REST actual usa `AudioPlayer` con tonos WAV en memoria por `BytesSource`, `mimeType: 'audio/wav'`, dos repeticiones y `mixWithOthers`; fue validada en `SM S916B`: preview y dos tonos audibles sin pausar audio externo.
- Una sesion nueva usa su fecha `YYYY-MM-DD` como titulo por defecto; cambiar la fecha actualiza ese titulo solo si no fue personalizado.
- Los ejercicios del workout manual estan agrupados en paneles plegables cerrados por defecto con bordes redondeados; cada cabecera muestra nombre y cantidad de sets, y al abrirla aparecen editar/eliminar por set.
- Existe una biblioteca local-first de rutinas en `/workout/routine`: permite crear, seleccionar, renombrar y borrar rutinas nombradas, y editar bloques de ejercicio, superserie o triserie para lunes a domingo. Cada ejercicio arranca en 3 sets x 10 reps x 0 kg; el workout nuevo vacio carga manualmente la rutina activa de su fecha incluyendo el peso configurado. No asumir que estas plantillas ya se sincronizan con Supabase.
- El catalogo de Chest, Back, Shoulders, Biceps y Triceps ya fue reemplazado por la lista elegida por el usuario; no cambiar Legs sin una lista nueva del usuario.
- El flujo Flutter de AI/comida ahora valida configuracion Supabase y maneja respuestas incompletas del backend.
- `manual food entry` ya corrige el caso web para fotos elegidas desde galeria usando `data:` URLs cuando hace falta.
- Ya existe una galeria de comidas en `/food/gallery` con foto, fecha, resumen nutricional, confianza AI, editar y eliminar; la lectura es local-first y los usuarios autenticados sincronizan meals/fotos remotamente.
- `Add meal` ya muestra un acceso directo visible a esa galeria.
- La migracion real del backend de OpenAI a OpenRouter ya quedo implementada en `backend/supabase/functions/meal-photo-analyze/index.ts`, `backend/supabase/functions/food-catalog-upsert/index.ts` y `backend/supabase/functions/_shared/openrouter.ts`.
- Los secrets remotos de Supabase para OpenRouter ya quedaron cargados y ambas functions ya fueron redeployadas.
- El modelo efectivamente adoptado para esta iteracion es `qwen/qwen3-vl-8b-instruct` via OpenRouter.
- En Windows ya se valido `SUPABASE_ACCESS_TOKEN`, `SUPABASE_URL` y `SUPABASE_ANON_KEY` durante una sesion real, pero deben recargarse manualmente al retomar porque no quedaron persistidos.
- `food-catalog-upsert` ya respondio `200 OK` autenticado y `meal-photo-analyze` ya llego a OpenRouter; lo pendiente es validar foto real en Flutter/Android y vigilar posibles limites de credito/proveedor.
- El APK debug mas reciente esta en mobile/fitness_app/build/app/outputs/flutter-apk/app-debug.apk.
- `Add meal` y `shared food catalog` ya tienen scanner de barcode + lookup `Open Food Facts -> USDA` + cache en Supabase + card visual de resultado.
- En Windows ya existe `dart_defines.local.json` ignorado por Git y scripts en `scripts/flutter/` para build/run sin repetir flags.
- El telefono Android `SM S916B` ya quedo probado con instalacion directa por `flutter run --no-resident`; si reaparece un error de `SUPABASE_URL/SUPABASE_ANON_KEY`, sospechar primero una instalacion vieja antes que un bug del codigo.
- Si reaparece `INSTALL_FAILED_NO_MATCHING_ABIS` al instalar debug en `SM S916B`, recompilar con `flutter build apk --debug --target-platform android-arm64`.
- `SUPABASE_URL` y `SUPABASE_ANON_KEY` son `dart-define` de compilacion: una APK construida sin esas flags siempre mostrara configuracion faltante. En CachyOS usar `scripts/flutter/save_local_dart_defines.sh` y luego `scripts/flutter/reinstall_android_debug.sh <device-id>`; el instalador exige el archivo local ignorado `mobile/fitness_app/dart_defines.local.json` y evita instalar una build sin credenciales.
- La app vieja `debug` `com.example.fitness_app` ya no debe convivir con la nueva `release` `com.x11pro.myfit`; si reaparece un warning raro en Samsung, comprobar primero paquetes instalados duplicados.
- `user-data-manage` ya esta desplegada para `export/delete` minimo real y fue aprobada de punta a punta en Android; no volver a reimplementar el backend.
- `app-release.apk` ya compila localmente y pasa `zipalign -P 16`; el warning de `16 KB` desaparecio cuando se desinstalo la app vieja debug.
- `Duration (min)` del workout manual ya no debe pisarse mientras el usuario tipea y `Duration/Calories` son opcionales en UI.
- `meal photo` ahora soporta `Meal weight (g)` e `Ingredients` editables con persistencia local/remota.
- Cambiar `Meal weight (g)` debe recalcular macros localmente y volver a tocar `Analyze with AI` debe respetar peso/ingredientes corregidos por el usuario.
- `ingredients_text` se aplicó en remoto con `supabase db query` por un problema del historial `20260711`; revisar `supabase migration list` antes de tocar migraciones nuevas.
- `mobile_scanner` ya fue actualizado a `7.3.0` y la camara de barcode fue aprobada en Android real.
- Punto de diseño mas reciente: revisar la ultima tanda de pantallas Stitch/Figma compartida por el usuario y decidir `usar / descartar / repetir` para cerrar la base final del rediseño.
- La base visual reusable ya existe en `mobile/fitness_app/lib/shared/ui/`; seguir construyendo sobre esa carpeta y no volver a hardcodear estilos pantalla por pantalla.
- La rutina recomendada por goal debe verse en ingles cuando la app esta en ingles; no reintroducir textos hardcodeados en espanol en esa parte.
- La QA real Android, incluida la secundaria, esta aprobada. Todavia NO es el mejor momento para una mejora total de UI/UX; primero cerrar release/legal y migracion guest a cuenta.
- `Pixel_10_Pro` fue iniciado y la build debug actual se instalo en `emulator-5554` con `scripts/flutter/reinstall_android_debug.sh emulator-5554`.
- El flujo de Mac mini esta configurado: SSH `Mariano@192.168.0.105`, clave `~/.ssh/id_ed25519_macmini`, repo remoto `/Users/macmini/Projects/Myfit`.
- `myfit-macmini-sync.service` esta activo en CachyOS y usa `scripts/git/watch_sync_to_macmini.sh` para copiar cambios fuente a la Mac mini cada 3 segundos. Confirmar que siga activo con `systemctl --user status myfit-macmini-sync.service` antes de depender de iOS.
- Para iOS en Mac mini: `open -a Simulator`; despues `cd /Users/macmini/Projects/Myfit/mobile/fitness_app && flutter run -d ios`. Usar `r` para hot reload de cambios Dart ya sincronizados.
- El ultimo bloque de UX/UI inicio el modo light y el registro directo de sets: peso y reps se editan en linea dentro de `/workout/manual`. Revisar `PROJECT_STATUS.md`, `docs/product/app_roadmap_visual.md` y `docs/product/function_family_tree.md` antes de continuar.

Tareas al retomar:
1. Revisar el estado real del repo sin revertir cambios ajenos.
2. Leer docs/setup/cachyos_resume.md y docs/handoff/current_status.md.
3. Confirmar que el ultimo punto implementado incluye top bar global + fix de Log Workout + NDK 28 + metricas de progreso de fuerza + reps junto a sets + `Repeat last` + sugerencias de ejercicios recientes + flujo `muscle group -> exercise` + sets multiples + `RPE` visual persistido.
4. Ejecutar flutter pub get, flutter analyze y flutter test.
5. Verificar primero si la shell actual ya tiene `SUPABASE_URL`, `SUPABASE_ANON_KEY` y opcionalmente `SUPABASE_ACCESS_TOKEN`; si faltan, recargarlas manualmente sin escribirlas en archivos del repo.
6. No repetir QA Android ya aprobada salvo una regresion: REST, sign out, barcode manual/no-match/sin red, error backend y editar/borrar workout estan validados.
7. Si se trabaja con iOS, confirmar el watcher Mac mini y arrancar el Simulator antes de ejecutar Flutter en la Mac mini.
8. Revisar visualmente el workout light en iOS Simulator y decidir la siguiente mejora de velocidad: precarga de ultimo peso/reps o gestos de set.
9. Preparar la firma release Android, publicar la privacy policy final y cerrar el canal/proceso de soporte para export/delete.
10. Consolidar la migracion guest -> cuenta sin perdida de datos ni duplicados.
11. Reevaluar el rediseño total de UI/UX solo despues de esos cierres.
12. Seguir desde ahi sin reiniciar nada desde cero.
13. Mantener respuestas en espanol.

No reinicies el proyecto desde cero. Continua desde la estructura y commits ya existentes.

Hay cambios no relacionados ya integrados en el ultimo commit, incluyendo `backend/supabase/functions/meal-photo-analyze`, archivos Android y archivos sueltos en la raiz. No reviertas nada por defecto sin revisar.

Si el usuario escribe AMARILLO, actualiza el paquete de continuidad del repo antes de terminar la sesion.
```
