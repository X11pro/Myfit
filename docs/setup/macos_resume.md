# Retomar en Mac mini

## Firma iOS por SSH

CocoaPods está en `/opt/homebrew/bin`. Para compilar desde una shell remota,
añadir esa ruta al `PATH` y usar `LANG=en_US.UTF-8`. Si Xcode encuentra el
certificado pero `codesign` devuelve `errSecInternalComponent`, ejecutar la
compilación desde Terminal en la sesión gráfica de la Mac y atender cualquier
aviso de acceso al llavero allí. No guardar ni transmitir la contraseña.

## Actualización 2026-11-19

La IP SSH confirmada es `Mariano@192.168.1.244` y la copia Git real es `/Volumes/HDD/Github/Myfit`; `/Users/macmini/Projects/Myfit` es un espejo sin `.git`. Los archivos de UI se copiaron a la copia Git real y pueden aparecer modificados: revisar `git status` antes de hacer pull, sin descartarlos. El simulador iOS ejecutó la nueva UI. La instalación Release en el iPhone físico quedó bloqueada por CocoaPods ausente o fuera del PATH de SSH.

## Hot reload desde CachyOS

La copia aislada `/Users/macmini/Projects/Myfit-live` es exclusivamente para
desarrollo: `scripts/git/watch_ios_live.sh` copia cada tres segundos solo los
archivos `.dart` de `lib/`, sin borrar archivos ni copiar secretos. La sesión
Flutter del simulador corre en `screen` bajo el nombre `myfit-ios-live`.
La copia no refleja eliminaciones, dependencias, recursos ni cambios nativos;
esos cambios requieren sincronización y compilación adicionales.

Desde CachyOS, con el watcher iniciado, enviar un hot reload:

```bash
ssh -i ~/.ssh/id_ed25519_macmini Mariano@192.168.1.244 \
  "screen -S myfit-ios-live -X stuff 'r'"
```

El watcher actual corre como unidad transitoria de usuario
`myfit-ios-live-sync.service`; comprobarlo con `systemctl --user status
myfit-ios-live-sync.service`. Para iniciarlo nuevamente tras reiniciar:
`systemd-run --user --unit=myfit-ios-live-sync --property=Restart=on-failure
/usr/bin/bash /home/x11pro_lnx_up/Documents/Github/Myfit/scripts/git/watch_ios_live.sh`.
La sesión `screen` y el watcher no se reinician automáticamente.
La copia Git principal en `/Volumes/HDD/Github/Myfit` permanece independiente.

## Estado local macOS, 2026-11-18

Este entorno detecta `iPhone 18 Pro` Simulator con ID `A048785F-667B-4FD7-97BD-CB97035601A4`. Myfit compiló, se instaló e inició mediante `xcrun simctl` el 2026-11-17. Confirmar la UI y hot reload antes de tomarlo como QA iOS concluyente.

```bash
cd /Users/macmini/Projects/Myfit/mobile/fitness_app
flutter run -d A048785F-667B-4FD7-97BD-CB97035601A4 \
  --dart-define-from-file=dart_defines.local.json
```

No versionar `dart_defines.local.json`.

La rama actual incluye el rediseño dark minimalista del dashboard, onboarding y componentes compartidos. Tras iniciar, comprobar primero el layout en teléfono, tipografía dinámica y navegación de las cuatro pestañas antes de retomar trabajo de producto.

La migración `20261117_000004_workout_routines.sql` ya está aplicada en Supabase. Tras actualizar el repositorio, la extensión Chrome relacionada está en `extensions/myfit-routine-builder`; seguir `docs/setup/chrome_routine_builder.md`, cargarla y autenticarla con la misma cuenta OTP que Myfit.

Para comprobar una rutina creada en Chrome, recompilar la app y abrir:

```text
Manual workout → Edit weekly routine → Reload routines
```

`Reload routines` descarga manualmente la biblioteca remota. La build debe incluir al menos el commit `7fb7afc Add manual routine refresh action`.

## Instalar en iPhone físico

El iPhone conectado es `Mariano's iPhone` (iPhone 16, UDID `00008140-0002313E1141801C`). Para instalar una build que se pueda abrir desde el icono sin depurador:

```bash
cd /Users/macmini/Projects/Myfit/mobile/fitness_app
flutter run --release --no-resident -d 00008140-0002313E1141801C \
  --dart-define-from-file=dart_defines.local.json
```

La firma Release usa el equipo Xcode `33SY9X526C`. Mantener el teléfono desbloqueado durante instalación y lanzamiento. Una build Debug solo se puede abrir mediante `flutter run` o Xcode en iOS 14+.

## Sincronizar desde CachyOS

El repositorio local debe estar limpio y los cambios deben estar committeados. Desde CachyOS:

```bash
./scripts/git/sync_to_macmini.sh Mariano@192.168.0.105 /Users/macmini/Projects/Myfit
```

El script sube el branch actual a `origin` y ejecuta un `git pull --ff-only` en la Mac mini por SSH. No agrega, guarda ni commitea cambios locales automaticamente.

## Sincronizacion continua desde CachyOS

Para copiar los cambios fuente a la Mac mini cada 3 segundos, sin crear commits:

```bash
./scripts/git/watch_sync_to_macmini.sh Mariano@192.168.0.105 /Users/macmini/Projects/Myfit
```

El watcher mantiene sincronizados los archivos fuente y sus eliminaciones. Excluye `.git`, secretos locales, `build`, `.dart_tool` y artefactos iOS generados. Para detenerlo, usar `Ctrl+C`.

En este equipo los scripts usan por defecto `~/.ssh/id_ed25519_macmini` para conectar a `Mariano@192.168.0.105`. Si la clave cambia, definir `MYFIT_MACMINI_SSH_KEY` antes de ejecutarlos.

Si Myfit ya esta corriendo con `flutter run` en la Mac mini, ejecutar `r` en esa terminal para aplicar hot reload tras los cambios sincronizados. Los cambios que requieren compilacion nativa requieren reiniciar la app.

## Abrir el simulador iOS

En Terminal de la Mac mini:

```bash
open -a Simulator
```

En este Mac concreto no se encontró `Simulator.app`, por lo que ese comando falla. Como alternativa headless, desde `mobile/fitness_app`:

```bash
flutter build ios --simulator
xcrun simctl install A048785F-667B-4FD7-97BD-CB97035601A4 "build/ios/iphonesimulator/Runner.app"
xcrun simctl launch A048785F-667B-4FD7-97BD-CB97035601A4 com.example.fitnessApp
```

Con el simulador iniciado, ejecutar la app desde el repositorio:

```bash
cd /Users/macmini/Projects/Myfit/mobile/fitness_app
flutter run -d ios
```

Si hay varios simuladores, obtener sus IDs con:

```bash
flutter devices
```

Y seleccionar uno explicitamente:

```bash
flutter run -d <device-id>
```
