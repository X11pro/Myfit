# Prompt de reanudacion exacta tras reinicio

```text
Lee primero AGENTS.md, docs/product/fitness_product_plan.md, docs/handoff/current_status.md, docs/setup/cachyos_resume.md y docs/research/free_food_photo_llm_recommendation.md.

Quiero retomar Myfit exactamente donde quedo la ultima sesion, sin rehacer analisis ya resueltos.

Estado exacto al pausar:
- Se mejoro la UX de workout manual con `Repeat last` para duplicar el ultimo set y con sugerencias de ejercicios recientes.
- Se reforzo el flujo Flutter de catalogo compartido y `Analyze with AI` para validar configuracion de Supabase y tolerar respuestas incompletas del backend.
- `flutter analyze` y `flutter test` pasaron correctamente.
- La prueba end-to-end real de AI/comida quedo pendiente porque faltaban `SUPABASE_URL` y `SUPABASE_ANON_KEY` en la shell actual.
- Se documento que la opcion free/open mas recomendada para reconocimiento de comida por foto es `Qwen2.5-VL-7B-Instruct`.

Que hacer primero:
1. Revisar `git status` y `git log --oneline -10`.
2. No revertir nada por defecto.
3. Verificar si ya estan disponibles `SUPABASE_URL` y `SUPABASE_ANON_KEY` para correr la app con `--dart-define`.
4. Si estan disponibles, priorizar la prueba real de:
   - pantalla de catalogo compartido,
   - boton `Analyze with AI` en manual food entry.
5. Si no estan disponibles, preparar el comando exacto para correr la app con esas variables y avanzar en la decision tecnica de backend free/open para reconocimiento de comida.
6. Mantener el foco en guest-first + persistencia local + backend simple. No reintroducir auth todavia salvo que sea necesario para desbloquear persistencia remota.

Decision tecnica ya tomada para foto de comida si buscamos costo cero o muy bajo:
- mejor opcion actual: `Qwen2.5-VL-7B-Instruct`,
- usarlo para reconocimiento + porcion + confianza + JSON,
- resolver macros finales con USDA/Open Food Facts/catalogo, no solo con el LLM.

Hablar siempre en espanol.
``` 
