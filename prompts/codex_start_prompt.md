# Prompt inicial para agente

Usa este prompt al abrir el repositorio en el nuevo sistema:

```text
Lee primero AGENTS.md, docs/product/fitness_product_plan.md y docs/handoff/current_status.md.

Quiero continuar el proyecto Myfit desde el estado actual del repo.

Objetivo inmediato:
1. Revisar el estado real de mobile/fitness_app, backend/supabase/migrations y docs/setup/cachyos_resume.md.
2. Confirmar que el flujo actual ya implementa auth OTP y persistencia de onboarding en `profiles` + `body_metrics`.
3. Conectar el proyecto real de Supabase o pedir las variables faltantes si no estan disponibles.
4. Validar end-to-end login OTP, carga de perfil y guardado de onboarding.
5. Mantener respuestas en espanol.
6. Ejecutar cuando esten disponibles: flutter pub get, dart format ., flutter analyze, flutter test y flutter doctor -v.

No reinicies el proyecto desde cero. Continua desde la estructura y commits ya existentes.

Hay muchos cambios no relacionados en el worktree. No reviertas nada por defecto y stagea solo los archivos realmente intencionales.

Si el usuario escribe AMARILLO, actualiza el paquete de continuidad del repo antes de terminar la sesion.
```
