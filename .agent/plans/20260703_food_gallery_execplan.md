# ExecPlan: food gallery local-first

## Objetivo

Agregar una galeria de comidas dentro del feature `food` para que las fotos ya guardadas en cada `ManualFoodEntry` se puedan ver junto con su resumen nutricional, sin introducir todavia persistencia remota nueva.

## Decision

- Reusar la persistencia local actual en `shared_preferences`.
- No agregar base de datos remota en esta iteracion.
- Exponer una pantalla nueva de galeria y enlazarla desde la navegacion actual.

## Pasos

1. Crear pantalla `food gallery` que lea `manualFoodEntriesProvider`.
2. Mostrar cards con foto, nombre, fecha, meal type y macros principales.
3. Permitir editar o borrar la comida desde la galeria.
4. Enlazar la nueva pantalla en router y accesos principales.
5. Validar con `flutter analyze`.

## Riesgos

- En Android/iOS la foto se guarda como path local; si el archivo se elimina fuera de la app, la preview puede fallar.
- En web los `data:` URLs pueden crecer; para ahora alcanza porque el objetivo principal es Android.

## Cierre esperado

- La galeria funciona offline con el estado local ya existente.
- La decision sobre Supabase para fotos queda postergada hasta la fase de sync multi-dispositivo.
