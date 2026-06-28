# Prompt inicial para agente

Usa este prompt al abrir el repositorio en el nuevo sistema:

```text
Lee primero AGENTS.md, docs/product/fitness_product_plan.md y docs/handoff/current_status.md.

Quiero continuar Myfit exactamente desde el ultimo punto.

Contexto inmediato:
- Ya existe flujo guest-first funcional.
- Ya existe modulo local-first de gym con sesiones, sets, edicion y progreso.
- Ya existe top bar global con back/home/menu.
- Ya se limpio la mezcla EN/ES y el selector EN / ESP cambia el copy visible.
- Ya se alineo Android a ndkVersion 28.2.13676358.
- Ya existe progreso de fuerza con selector de metrica: peso maximo, volumen y 1RM estimado.
- Ya se muestran repeticiones al lado de sets en workout/dashboard.
- El APK debug mas reciente esta en mobile/fitness_app/build/app/outputs/flutter-apk/app-debug.apk.

Tareas al retomar:
1. Revisar el estado real del repo sin revertir cambios ajenos.
2. Leer docs/setup/cachyos_resume.md y docs/handoff/current_status.md.
3. Confirmar que el ultimo punto implementado incluye top bar global + fix de Log Workout + NDK 28 + metricas de progreso de fuerza + reps junto a sets.
4. Ejecutar flutter pub get, flutter analyze y flutter test.
5. Seguir desde ahi sin reiniciar nada desde cero.
6. Priorizar la siguiente mejora de UX del modulo gym o la prueba real del catalogo compartido con AI, segun el estado del repo.
7. Mantener respuestas en espanol.

No reinicies el proyecto desde cero. Continua desde la estructura y commits ya existentes.

Hay cambios no relacionados en el worktree. No reviertas nada por defecto. Hay que prestar especial atencion a cambios ajenos en `backend/supabase/functions/meal-photo-analyze` y varios archivos Android; stagea solo los archivos realmente intencionales.

Si el usuario escribe AMARILLO, actualiza el paquete de continuidad del repo antes de terminar la sesion.
```
