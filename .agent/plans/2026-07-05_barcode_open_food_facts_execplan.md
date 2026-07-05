# ExecPlan: Barcode scanner + Open Food Facts

## Objetivo

Implementar un flujo usable de escaneo de barcode en Flutter que consulte `Open Food Facts`, cachee el resultado en `Supabase` y autocompletar macros en `Add meal`.

## Alcance de esta iteracion

1. Agregar scanner de barcode en Flutter.
2. Crear una Edge Function para lookup por barcode.
3. Buscar primero en `food_items` cacheado en Supabase.
4. Si no existe, consultar `Open Food Facts`.
5. Normalizar nombre, marca y macros por `100g`.
6. Guardar el resultado en `food_items` para futuras consultas.
7. Autocompletar `Add meal` con el producto encontrado.

## Decisiones

- `Open Food Facts` es la fuente primaria porque es gratis y encaja con barcode empaquetado.
- `Supabase` queda como cache y catalogo propio para no depender siempre de la API externa.
- Se evita por ahora el fallback completo a `USDA`; se deja preparado el modelo para una siguiente iteracion.
- El scanner se integra en `manual food entry`, que es donde el usuario espera cargar macros rapido.

## Verificacion prevista

1. `flutter pub get`
2. `dart format .`
3. `flutter analyze`
4. `flutter test`

## Pendiente manual fuera de codigo

- Deployar la nueva Edge Function en Supabase.
- Probar escaneo real en Android con productos empaquetados.
