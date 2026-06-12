# Myfit

Base inicial del producto `Myfit`: app mobile de nutricion, entrenamiento y balance energetico con soporte de IA.

## Estado actual

Este repositorio ya incluye:

- Vision de producto y MVP.
- Arquitectura inicial mobile/backend/IA.
- Modelo de datos y contratos API de referencia.
- Estructura de carpetas para monorepo.
- Script de sincronizacion con GitHub.
- App Flutter real generada en `mobile/fitness_app`.
- Scaffold inicial de `login`, `onboarding` y `dashboard`.
- Primera migracion SQL de Supabase con tablas y RLS base.
- `flutter analyze` y `flutter test` en verde en el ultimo entorno Windows.

## Documentacion principal

- `docs/product/fitness_product_plan.md`: plan maestro completo.
- `docs/product/vision.md`: resumen ejecutivo y diferenciacion.
- `docs/product/mvp.md`: alcance del MVP.
- `docs/product/roadmap.md`: fases y entregables.
- `docs/product/user_stories.md`: historias de usuario iniciales.
- `docs/architecture/system_architecture.md`: arquitectura funcional.
- `docs/architecture/data_model.md`: modelo de datos inicial.
- `docs/architecture/api_contracts.md`: endpoints base.
- `docs/architecture/ai_architecture.md`: flujo y limites de IA.
- `docs/architecture/privacy_security.md`: privacidad, seguridad y cumplimiento.

## Estructura del repo

```text
Myfit/
  docs/
  mobile/
    fitness_app/
  backend/
    supabase/
      migrations/
      functions/
  prompts/
  scripts/
```

## Siguientes pasos tecnicos

1. Conectar `Supabase Auth` real en `mobile/fitness_app`.
2. Persistir onboarding en `profiles`.
3. Crear el flujo de registro manual de comida.
4. Calcular `daily_energy_summary` local/base.
5. Preparar primera `Edge Function` para `food/parse-text`.

## Retomar en otro sistema

- `docs/setup/cachyos_resume.md`: pasos exactos para retomar en CachyOS.
- `docs/handoff/current_status.md`: estado actual y pendientes.
- `AGENTS.md`: instrucciones persistentes para el agente en la raiz del repo.
- `.agent/PLANS.md`: plantilla para planes de ejecucion largos.
- `prompts/codex_start_prompt.md`: prompt inicial recomendado para abrir el repo con un agente.

## GitHub

Remoto actual:

```bash
git remote set-url origin https://github.com/X11pro/Myfit.git
```

Script principal de sync:

```powershell
.\scripts\git\sync_to_github.ps1
```
