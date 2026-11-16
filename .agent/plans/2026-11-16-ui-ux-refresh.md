# Rediseño UI/UX de Myfit

## Objetivo

Hacer que Myfit sea más clara, atractiva y rápida de recorrer sin alterar los flujos existentes de perfil, comida, entrenamiento, progreso y autenticación.

## Dirección visual

- Tema oscuro cálido con superficies claramente separadas.
- Verde menta para progreso y estados positivos; coral para acciones prioritarias y alertas de energía.
- Jerarquía centrada en la siguiente acción útil, antes que en mostrar todos los datos a la vez.
- Ritmo de 8 px, tarjetas de 20 px de radio e iconografía Material outline coherente.
- Navegación inferior con cuatro destinos: inicio, entreno, nutrición y progreso.

## Ejecución

1. Consolidar tokens de tema, tipografía, formularios, tarjetas, botones y navegación.
2. Reordenar el dashboard para mostrar primero el resumen diario, los macros, una acción rápida y la actividad.
3. Aplicar componentes visuales compartidos a los formularios de comida, entrenamiento y perfil.
4. Validar que no haya regresiones de navegación, accesibilidad ni pruebas Flutter.

## Verificación

- `dart format .`
- `flutter analyze`
- `flutter test`
