# Myfit Project Status

Actualizado: 2026-11-19.

## Punto De Reanudacion

Myfit tiene una extensión Chrome para construir rutinas semanales en escritorio. Flutter y la extensión comparten un documento remoto de rutinas por usuario autenticado; el almacenamiento local de Flutter permanece como respaldo offline. La primera pasada de UI con superficies azul grisáceas y acentos menta está instalada en los simuladores Android local e iOS de la Mac; falta QA visual y confirmar la sincronización de rutinas con la misma cuenta OTP.

## Ultimo Trabajo Hecho

- Se actualizó el tema compartido, la jerarquía de secciones y la extensión Chrome para usar la misma paleta. El dashboard ya no muestra una variación de peso fija ficticia; muestra la acción de registrar peso.
- Android se compiló en la Mac y se instaló en el emulador **local** `emulator-5554`; iOS se compiló e inició en el simulador de la Mac. Falta revisión visual, accesibilidad y texto grande.
- El tema global usa superficies verde bosque oscuras, verde menta para progreso y coral para avisos/energía.
- El dashboard se reorganizó para priorizar balance, macros, acciones rápidas, actividad y métricas secundarias.
- Onboarding, tarjetas compartidas, campos, botones y barra superior usan el mismo sistema visual; la barra superior muestra una única acción de más opciones.
- La navegación inferior mantiene cuatro destinos: inicio, entreno, nutrición y progreso.
- El flujo OTP cuenta con verificación de seis dígitos y reenvío con espera.
- El workout manual resume cada ejercicio en una tarjeta desplegable; al abrirlo, muestra sus sets y controles rápidos.
- `KG` y `REPS` se editan directamente en cada set.
- El dialogo detallado sigue disponible para ejercicio, grupo muscular, RPE y acciones secundarias.
- El onboarding recoge perfil energético: peso, altura, fecha de nacimiento, sexo opcional y actividad diaria baja/media/media-alta/alta. El dashboard usa Mifflin-St Jeor cuando el perfil está completo; conserva el cálculo previo como fallback.
- El perfil energético completo es obligatorio antes del dashboard, tanto después de OTP como en modo guest. Se puede editar después tocando la tarjeta de gasto diario estimado.
- Se agregaron los mapas `docs/product/app_roadmap_visual.md` y `docs/product/function_family_tree.md`.
- El plan de este trabajo es `.agent/plans/2026-11-16-ui-ux-refresh.md`.
- La nueva implementación está descrita en `.agent/plans/2026-11-17-chrome-routine-builder.md`.
- La extensión está en `extensions/myfit-routine-builder`; usa OTP, no usa claves privilegiadas y permite editar bloques normales, superseries y trisets de lunes a domingo.
- Las migraciones remotas pendientes se aplicaron al proyecto Supabase `cyecalxewqcyxxglxloa`, incluida `20261117_000004_workout_routines.sql`, que crea `public.workout_routines` con RLS.
- La guía de instalación y conexión está en `docs/setup/chrome_routine_builder.md`.
- La extensión está en versión `0.1.1`: renueva su sesión Supabase al abrirse y, si la renovación falla, vuelve al formulario OTP. También acepta la respuesta vacía exitosa de Supabase al guardar rutinas.
- La app expone ahora un botón visible `Edit weekly routine` desde `Manual workout`. La pantalla `Weekly routine` incluye `Reload routines`, que vuelve a descargar la biblioteca desde Supabase bajo demanda.
- Tras verificar correctamente un OTP, el login navega explícitamente a onboarding; el router redirige perfiles ya completos al dashboard. Esto evita que la pantalla de código parezca no responder mientras se actualiza la sesión asíncrona.
- El sexto dígito OTP ahora verifica automáticamente, cierra el teclado y muestra carga o error visible en la pantalla.
- Inglés usa locale `en_GB` y fechas visibles `DD/MM/YYYY`; ISO continúa reservado para claves y persistencia.

## Estado iOS

- El 2026-11-18 se compiló y firmó una build Release para `Mariano's iPhone` (iPhone 16, UDID `00008140-0002313E1141801C`) usando el equipo `33SY9X526C`; `xcrun devicectl` confirmó su instalación como `com.example.fitnessApp`.
- El lanzamiento remoto falló únicamente porque el teléfono estaba bloqueado. Desbloquearlo y abrir Myfit desde el icono: una build Release no requiere Flutter conectado.
- El 2026-10-12 Myfit compiló, instaló e inició en `iPhone 18 Pro` Simulator (`AB8AD4CB-BE80-4011-B664-3B062DC0EB07`).
- Supabase inicializó correctamente.
- La sesión de depuración se desconectó tras iniciar (`The Dart compiler exited unexpectedly`), sin error de build. Confirmar visualmente la app y el hot reload antes de considerar iOS validado.
- Falta bundle identifier definitivo, firma y QA iOS real.

## Verificaciones

Desde `mobile/fitness_app` pasó el 2026-11-18:

```bash
flutter test test/features/workout/manual_workout_controller_test.dart
```

`node --check` pasó para `popup.js` y `options.js`; `git diff --check` también pasó. En este entorno, `flutter analyze` queda bloqueado por dos errores preexistentes en `onboarding_screen.dart` (`DropdownButtonFormField.initialValue` no está disponible en la versión local de Flutter); no fueron introducidos por la sincronización de rutinas.

## Estado Android

- El AVD `Pixel_10_Pro` arrancó como `emulator-5554` (Android 17, API 37).
- La app se compiló, instaló y abrió correctamente con `flutter run -d emulator-5554 --no-resident`.
- La compilación muestra avisos no bloqueantes de compatibilidad futura de Kotlin/Flutter.

## Siguiente Paso

1. Revisar la nueva UI en el emulador Android local y el simulador iOS de la Mac; recargar la extensión en `chrome://extensions` y revisar su apariencia.
2. Autenticarse en el móvil con el mismo email OTP de Chrome y abrir `Manual workout` → `Edit weekly routine` → `Reload routines` para confirmar la sincronización.
3. Si no aparece, comprobar el usuario de Supabase y los `dart-define` de la build móvil antes de cambiar el modelo de sincronización.
4. Hacer QA visual del dashboard, onboarding, comida y workout en Android e iOS; después preparar firma Android, privacy policy pública y soporte para export/delete.

## Notas De Git

- La entrega de UI, OTP, iconos y continuidad está publicada en `eeea9bd Refresh dark UI and continuity`.
- Hay cambios previos no relacionados junto con el rediseño, iconos iOS, OTP y Android. No hacer reversiones masivas.
- `.agent/skills/impeccable/` queda intencionalmente sin seguimiento: fue generado por una inicialización externa y no forma parte de Myfit.
- No versionar `mobile/fitness_app/dart_defines.local.json` ni secretos.
- Los ajustes de Xcode ahora se incluyen para preservar la firma Release del equipo `33SY9X526C` usada en el iPhone físico.
- Los commits recientes publicados son `c6f0238 Refresh expired extension sessions`, `5a52fdd Handle empty routine save responses` y `7fb7afc Add manual routine refresh action`.
