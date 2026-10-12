# Retomar en Mac mini

## Estado local macOS, 2026-10-12

Este entorno detecta `iPhone 18 Pro` Simulator con ID `AB8AD4CB-BE80-4011-B664-3B062DC0EB07`. Myfit compiló, instaló e inició con Supabase correcto, pero la sesión debug perdió conexión después del arranque. Confirmar la UI y hot reload antes de tomarlo como QA iOS concluyente.

```bash
cd /Volumes/HDD/Github/Myfit/mobile/fitness_app
flutter run -d AB8AD4CB-BE80-4011-B664-3B062DC0EB07 \
  --dart-define-from-file=dart_defines.local.json
```

No versionar `dart_defines.local.json`.

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
