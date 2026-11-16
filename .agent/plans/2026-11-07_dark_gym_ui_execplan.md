# Dark Gym UI ExecPlan

## Objetivo

Reorientar la UI de Myfit hacia el estilo de referencia: una interfaz deportiva oscura, de alto contraste, con verde lima como accion principal, naranja para energia y superficies negras estratificadas.

## Alcance

- Cambiar el tema global de claro a oscuro y definir tokens visuales reutilizables.
- Reestilizar controles, navegacion, formularios, tarjetas y dialogs mediante el tema compartido.
- Ajustar los contenedores compartidos y welcome para una jerarquia mas directa: marca, objetivo y accion principal.
- Conservar rutas, estado, persistencia, textos y flujos existentes.
- No modificar los cambios locales pendientes de dashboard y OTP.

## Criterios de aceptacion

- La app inicia en modo oscuro con fondo near-black y superficies distinguibles.
- Las acciones principales usan verde lima; energia y alertas usan naranja sin competir con la accion primaria.
- Formularios y controles son legibles en movil, con areas tactiles claras y consistentes.
- Las pantallas que usan `PremiumScreen` y `PremiumCard` heredan el sistema nuevo.
- `flutter analyze` y `flutter test` continúan pasando.

## Verificacion

1. `dart format lib test`.
2. `flutter analyze`.
3. `flutter test`.
