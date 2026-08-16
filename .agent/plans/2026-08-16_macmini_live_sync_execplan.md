# ExecPlan: Mac mini live sync

Fecha: 2026-08-16

## Goal

Replicar los cambios del repositorio CachyOS a la copia de Myfit en la Mac mini cada 3 segundos para acelerar las pruebas en el simulador iOS.

## Decisions

- La conexion usa SSH y `rsync`; el usuario debe proporcionar `usuario@host` y la ruta remota.
- El watcher replica tambien eliminaciones, pero excluye secretos y salidas generadas locales.
- El watcher actualiza archivos fuente; no inicia ni recompila Flutter en la Mac mini automaticamente.

## Implementation steps

- [x] Crear watcher de sincronizacion configurable con intervalo de 3 segundos.
- [x] Guardar instrucciones persistentes para el flujo `EMU`.
- [x] Validar sintaxis y dependencias locales del script.
- [x] Integrar la clave SSH local autorizada para la Mac mini.
- [x] Iniciar y verificar el watcher contra `/Users/macmini/Projects/Myfit`.

## Non-goals

- No guardar credenciales SSH ni secretos en el repositorio.
- No iniciar builds iOS remotos automaticamente.
