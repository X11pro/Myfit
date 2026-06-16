# Estado actual

## Resumen

El repo ya esta listo para continuar en CachyOS sin depender del contexto de esta sesion y con el entorno Flutter validado localmente.

## Estado de codigo

- Remoto configurado: `origin -> https://github.com/X11pro/Myfit.git`.
- App Flutter real creada en `mobile/fitness_app`.
- Plataformas generadas: `android`, `ios`, `linux`, `macos`, `web`, `windows`.
- Scaffold actual:
  - `login` con email OTP via Supabase
  - `onboarding`
  - `dashboard`
  - `splash`
  - router con `go_router`
  - estado con `Riverpod` sincronizado con sesion/perfil
- Bootstrap de Supabase preparado en `lib/core/bootstrap.dart`.
- Migracion inicial SQL creada en `backend/supabase/migrations/20260612_000001_initial_schema.sql`.
- ExecPlan de esta iteracion: `.agent/plans/20260612_supabase_auth_profiles_execplan.md`.

## Cambios implementados en esta sesion

- `mobile/fitness_app/lib/features/auth/presentation/login_screen.dart`
  - login real por email OTP.
- `mobile/fitness_app/lib/features/auth/application/auth_controller.dart`
  - envio y verificacion de OTP con `supabase_flutter`.
- `mobile/fitness_app/lib/shared/app_state.dart`
  - carga de sesion actual,
  - escucha de cambios de auth,
  - lectura de `profiles` y ultimo `body_metrics`,
  - persistencia del onboarding a Supabase.
- `mobile/fitness_app/lib/features/onboarding/presentation/onboarding_screen.dart`
  - precarga de datos existentes y guardado async.
- `mobile/fitness_app/test/widget_test.dart`
  - test actualizado al nuevo entry point de auth.

## Estado del entorno CachyOS

- Flutter operativo desde `/home/x11pro_lnx_up/flutter`.
- `flutter doctor -v`: sin errores.
- Android SDK operativo en `/home/x11pro_lnx_up/Android/Sdk`.
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
```

## Commits relevantes

- `efc2e21` `Add AMARILLO continuity rule`
- `9986cb7` `Generate Flutter app platforms`
- `eb29587` `Add Flutter scaffold and initial schema`
- `c4466fe` `Add project structure and planning docs`

## Pendientes inmediatos

1. Crear o conectar el proyecto real de Supabase.
2. Configurar `SUPABASE_URL` y `SUPABASE_ANON_KEY` para probar auth real en la app.
3. Aplicar la migracion `backend/supabase/migrations/20260612_000001_initial_schema.sql` en el proyecto Supabase.
4. Validar end-to-end:
   - login OTP,
   - lectura/escritura de `profiles`,
   - insercion inicial en `body_metrics`.
5. Empezar `manual food entry` como siguiente feature del producto.

## Riesgos o notas

- El package name Android sigue siendo el default de Flutter: `com.example.fitness_app`.
- Falta definir bundle identifier iOS real.
- No hay claves reales ni `.env` comprometidos en el repo.
- Sin variables reales de Supabase no se puede probar el flujo contra backend aunque el codigo ya esta integrado.
- `currentWeightKg` del onboarding se guarda en `body_metrics`, no en `profiles`, porque el esquema actual ya separa ese dato historico.
- El worktree del repo contiene muchos cambios previos y/o de entorno no relacionados; revisar cuidadosamente antes de hacer commits amplios.

## Regla persistente del usuario

Si el usuario escribe `AMARILLO` en mayusculas, el agente debe generar o actualizar el paquete de continuidad antes de cerrar la sesion o cambiar de sistema operativo.

Ese paquete debe dejar como minimo:

- estado actualizado del proyecto,
- pasos de setup o resume del OS destino,
- instrucciones persistentes de agente si hicieron falta,
- prompt de reanudacion actualizado,
- commit y push si Git esta disponible.
