# Prompt inicial para agente

Usa este prompt al abrir el repositorio en el nuevo sistema:

```text
Lee primero AGENTS.md, docs/product/fitness_product_plan.md, docs/handoff/current_status.md y el resume del OS actual en docs/setup/.
Lee tambien docs/research/free_food_photo_llm_recommendation.md.

Quiero continuar Myfit exactamente desde el ultimo punto.

Contexto inmediato:
- Ya existe flujo guest-first funcional.
- Ya existe modulo local-first de gym con sesiones, sets, edicion y progreso.
- Ya existe top bar global con back/home/menu.
- Ya se limpio la mezcla EN/ES y el selector EN / ESP cambia el copy visible.
- Ya se alineo Android a ndkVersion 28.2.13676358.
- Ya existe progreso de fuerza con selector de metrica: peso maximo, volumen y 1RM estimado.
- Ya se muestran repeticiones al lado de sets en workout/dashboard.
- Ya existe carga rapida minima en workout: `Repeat last` + sugerencias de ejercicios recientes.
- El dialogo de workout ya fue mejorado para usar `muscle group -> exercise`, crear multiples sets iguales y capturar `RPE` visual con persistencia por set.
- `gym tracker` ya incluye cronometro de sesion y cronometro de descanso; el de sesion sincroniza `Duration (min)` y el de descanso arranca automaticamente cuando se agrega o repite un set.
- El workout manual ahora guarda `totalDurationSeconds`, `activeDurationSeconds` y `restDurationSeconds` por sesion.
- El timer REST ya fue probado en `SM S916B` con sonido seleccionable, preview automatico al cambiar la opcion y vibracion opcional al llegar a `0`.
- El flujo Flutter de AI/comida ahora valida configuracion Supabase y maneja respuestas incompletas del backend.
- `manual food entry` ya corrige el caso web para fotos elegidas desde galeria usando `data:` URLs cuando hace falta.
- Ya existe una galeria local-first de comidas en `/food/gallery` con foto, fecha, resumen nutricional, confianza AI, editar y eliminar.
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
- La app vieja `debug` `com.example.fitness_app` ya no debe convivir con la nueva `release` `com.x11pro.myfit`; si reaparece un warning raro en Samsung, comprobar primero paquetes instalados duplicados.
- `user-data-manage` ya esta desplegada para `export/delete` minimo real; el siguiente chequeo es probarla en Android, no volver a reimplementar el backend.
- `app-release.apk` ya compila localmente y pasa `zipalign -P 16`; el warning de `16 KB` desaparecio cuando se desinstalo la app vieja debug.
- `Duration (min)` del workout manual ya no debe pisarse mientras el usuario tipea y `Duration/Calories` son opcionales en UI.
- La rutina recomendada por goal debe verse en ingles cuando la app esta en ingles; no reintroducir textos hardcodeados en espanol en esa parte.
- Todavia NO es el mejor momento para una mejora total de UI/UX; primero ejecutar QA real Android, confirmar export/delete y cerrar release/legal.

Tareas al retomar:
1. Revisar el estado real del repo sin revertir cambios ajenos.
2. Leer docs/setup/cachyos_resume.md y docs/handoff/current_status.md.
3. Confirmar que el ultimo punto implementado incluye top bar global + fix de Log Workout + NDK 28 + metricas de progreso de fuerza + reps junto a sets + `Repeat last` + sugerencias de ejercicios recientes + flujo `muscle group -> exercise` + sets multiples + `RPE` visual persistido.
4. Ejecutar flutter pub get, flutter analyze y flutter test.
5. Verificar primero si la shell actual ya tiene `SUPABASE_URL`, `SUPABASE_ANON_KEY` y opcionalmente `SUPABASE_ACCESS_TOKEN`; si faltan, recargarlas manualmente sin escribirlas en archivos del repo.
6. Ejecutar la prueba real del catalogo compartido y `Analyze with AI` con la build Android/web ya configurada con Supabase.
7. Priorizar en Android el flujo: guardar foto real -> verla en `/food/gallery` -> lanzar `Analyze with AI`.
8. Probar varios productos reales por barcode y distinguir si entran por cache, `Open Food Facts` o `USDA`.
9. Validar con una foto real que OpenRouter responde bien desde Flutter y, si hay respuestas incompletas, ajustar prompt/parsing sin reabrir analisis ya cerrados.
10. Ejecutar QA real guiada en `SM S916B` con `docs/qa/android_real_device_checklist.md`.
11. Confirmar export/delete remoto real desde auth screen.
12. Validar en Android barcode real, foto AI real y rehidratacion remota completa.
13. Integrar los tiempos `total / activo / descanso` al dashboard/analisis antes del rediseño total.
14. Seguir desde ahi sin reiniciar nada desde cero.
15. Mantener respuestas en espanol.

No reinicies el proyecto desde cero. Continua desde la estructura y commits ya existentes.

Hay cambios no relacionados ya integrados en el ultimo commit, incluyendo `backend/supabase/functions/meal-photo-analyze`, archivos Android y archivos sueltos en la raiz. No reviertas nada por defecto sin revisar.

Si el usuario escribe AMARILLO, actualiza el paquete de continuidad del repo antes de terminar la sesion.
```
