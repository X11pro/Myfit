# Estado actual

## Resumen

El repo ya esta listo para continuar en otro sistema operativo sin depender del contexto de esta sesion.

## Estado de codigo

- Repo Git limpio al cierre de esta sesion.
- Remoto configurado: `origin -> https://github.com/X11pro/Myfit.git`.
- Sync automatico cada 20 minutos creado en Windows, pero eso no se traslada a CachyOS.
- App Flutter real creada en `mobile/fitness_app`.
- Plataformas generadas: `android`, `ios`, `linux`, `macos`, `web`, `windows`.
- Scaffold actual:
  - `login` placeholder
  - `onboarding`
  - `dashboard`
  - `splash`
  - router con `go_router`
  - estado local con `Riverpod`
- Bootstrap de Supabase preparado en `lib/core/bootstrap.dart`.
- Migracion inicial SQL creada en `backend/supabase/migrations/20260612_000001_initial_schema.sql`.

## Verificaciones ya hechas

En el ultimo entorno Windows se ejecuto correctamente:

```bash
flutter pub get
flutter analyze
flutter test
```

## Commits relevantes

- `9986cb7` `Generate Flutter app platforms`
- `eb29587` `Add Flutter scaffold and initial schema`
- `c4466fe` `Add project structure and planning docs`

## Pendientes inmediatos

1. Configurar entorno Linux para Flutter y herramientas auxiliares.
2. Crear proyecto Supabase real o conectar el existente.
3. Implementar `Supabase Auth` real.
4. Persistir onboarding en tabla `profiles`.
5. Crear feature inicial de `manual food entry`.

## Riesgos o notas

- El package name Android sigue siendo el default de Flutter: `com.example.fitness_app`.
- Falta definir bundle identifier iOS real.
- El login actual es placeholder y no usa backend.
- No hay claves reales ni `.env` comprometidos en el repo.

## Regla persistente del usuario

Si el usuario escribe `AMARILLO` en mayusculas, el agente debe generar o actualizar el paquete de continuidad antes de cerrar la sesion o cambiar de sistema operativo.

Ese paquete debe dejar como minimo:

- estado actualizado del proyecto,
- pasos de setup o resume del OS destino,
- instrucciones persistentes de agente si hicieron falta,
- prompt de reanudacion actualizado,
- commit y push si Git esta disponible.
