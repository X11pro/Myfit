# ExecPlan: Manual food entry local-first

## Objetivo

Agregar la primera version funcional de registro manual de comida en la app Flutter, sin depender de auth mientras el flujo de acceso esta temporalmente deshabilitado.

## Alcance de esta iteracion

1. Crear estructura `food/` en `features/`.
2. Permitir agregar comidas manuales desde la UI.
3. Guardar comidas en estado local con Riverpod.
4. Mostrar lista y totales basicos en dashboard.
5. Mantener el flujo guest actual y el idioma ingles por defecto.

## Decisiones

- La persistencia en esta iteracion es local en memoria porque el flujo de auth esta temporalmente fuera del camino principal.
- Cada comida manual guarda solo los campos minimos para desbloquear uso real: nombre, tipo de comida, calorias y proteina.
- El dashboard se actualiza con datos reales de las comidas locales, sin esperar integraciones de backend adicionales.

## Verificacion prevista

1. `dart format .`
2. `flutter analyze`
3. `flutter test`

## Siguiente paso esperado

- Cuando vuelva auth, conectar este flujo a `meal_entries` en Supabase y mantener el mismo UI base.
