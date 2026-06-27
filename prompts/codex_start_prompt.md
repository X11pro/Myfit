# Prompt inicial para agente

Usa este prompt al abrir el repositorio en el nuevo sistema:

```text
Lee primero AGENTS.md, docs/product/fitness_product_plan.md y docs/handoff/current_status.md.

Quiero continuar el proyecto Myfit desde el estado actual del repo.

Objetivo inmediato:
1. Revisar el estado real de mobile/fitness_app, backend/supabase/migrations y docs/setup/cachyos_resume.md.
2. Confirmar que el flujo actual es guest-first, con ingles por defecto, cambio consistente a espanol desde `EN / ESP`, dark mode, onboarding local persistido, comidas manuales persistidas, resumen diario/peso local y fotos por comida.
3. Confirmar que Supabase remoto ya tiene las Edge Functions `food-catalog-upsert` y `meal-photo-analyze`.
4. Confirmar que ya existe modulo local-first de gym con sesiones, sets, edicion, progreso, filtro por ejercicio, top bar global y pulido visual del dashboard.
5. Revisar si el APK debug mas reciente en `mobile/fitness_app/build/app/outputs/flutter-apk/app-debug.apk` sigue representando el estado actual y si hace falta repetir `flutter clean` antes de rebuild.
6. Seguir desarrollando valor de producto sin Auth0 y reintroducir autenticacion solo cuando haga falta para persistencia multiusuario.
7. Mantener respuestas en espanol.
8. Ejecutar cuando esten disponibles: flutter pub get, dart format ., flutter analyze y flutter test.

No reinicies el proyecto desde cero. Continua desde la estructura y commits ya existentes.

Hay muchos cambios no relacionados en el worktree. No reviertas nada por defecto y stagea solo los archivos realmente intencionales.

Si el usuario escribe AMARILLO, actualiza el paquete de continuidad del repo antes de terminar la sesion.
```
