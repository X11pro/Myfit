# Prompt inicial para agente

Usa este prompt al abrir el repositorio en el nuevo sistema:

```text
Lee primero AGENTS.md, docs/product/fitness_product_plan.md y docs/handoff/current_status.md.

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
- El flujo Flutter de AI/comida ahora valida configuracion Supabase y maneja respuestas incompletas del backend.
- La migracion real del backend de OpenAI a OpenRouter ya quedo implementada en `backend/supabase/functions/meal-photo-analyze/index.ts`, `backend/supabase/functions/food-catalog-upsert/index.ts` y `backend/supabase/functions/_shared/openrouter.ts`.
- Los secrets remotos de Supabase para OpenRouter ya quedaron cargados y ambas functions ya fueron redeployadas.
- El modelo efectivamente adoptado para esta iteracion es `qwen/qwen3-vl-8b-instruct` via OpenRouter.
- La prueba E2E real pendiente depende de tener `SUPABASE_URL` y `SUPABASE_ANON_KEY` reales en la maquina actual o un `SUPABASE_ACCESS_TOKEN` valido para recuperarlas por CLI, y luego usar una foto valida.
- El APK debug mas reciente esta en mobile/fitness_app/build/app/outputs/flutter-apk/app-debug.apk.

Tareas al retomar:
1. Revisar el estado real del repo sin revertir cambios ajenos.
2. Leer docs/setup/cachyos_resume.md y docs/handoff/current_status.md.
3. Confirmar que el ultimo punto implementado incluye top bar global + fix de Log Workout + NDK 28 + metricas de progreso de fuerza + reps junto a sets + `Repeat last` + sugerencias de ejercicios recientes + flujo `muscle group -> exercise` + sets multiples + `RPE` visual persistido.
4. Ejecutar flutter pub get, flutter analyze y flutter test.
5. Verificar primero si la shell actual ya tiene `SUPABASE_URL` y `SUPABASE_ANON_KEY` o `SUPABASE_ACCESS_TOKEN`; si faltan, ese es el bloqueo real inmediato.
6. Ejecutar la prueba real del catalogo compartido y `Analyze with AI` con `--dart-define` para `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
7. Validar con una foto real que OpenRouter responde bien desde Flutter y, si hay respuestas incompletas, ajustar prompt/parsing sin reabrir analisis ya cerrados.
8. Validar en movil la nueva UX de workout antes de seguir con cambios mayores en progreso o analitica.
9. Seguir desde ahi sin reiniciar nada desde cero.
10. Mantener respuestas en espanol.

No reinicies el proyecto desde cero. Continua desde la estructura y commits ya existentes.

Hay cambios no relacionados ya integrados en el ultimo commit, incluyendo `backend/supabase/functions/meal-photo-analyze`, archivos Android y archivos sueltos en la raiz. No reviertas nada por defecto sin revisar.

Si el usuario escribe AMARILLO, actualiza el paquete de continuidad del repo antes de terminar la sesion.
```
