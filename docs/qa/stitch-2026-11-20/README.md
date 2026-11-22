# Home Dashboard — inspección visual

- Referencia principal: `myfit_home_dashboard/screen.png` (259 × 1600). El ZIP contiene diez pares HTML/PNG, una fotografía independiente y `obsidian_kinetic/DESIGN.md`; solo Home es el objetivo.
- [Pantalla completa: Stitch a la izquierda, Flutter a la derecha](full-comparison.webp). Captura Flutter de 412 × 2545 lógicos, reducida al tamaño del PNG para comparar la composición. Es una vista extendida para inspección, no un dispositivo de esa altura.
- [Primer viewport: HTML, Flutter y superposición al 50 %](home_dashboard.webp). 412 × 884 en ambos renders, DPR 1 y escala de texto 1, sin barras del sistema. La superposición usa el HTML renderizado en Chromium, no una ampliación del PNG. RMSE normalizado 0.261782: no hay identidad de píxeles.
- Se ejecutó Flutter en Linux. Las capturas se generaron con el renderer de `flutter test` y datos de ejemplo locales: Alex, 620 kcal restantes, objetivo de 2200 kcal, 78.4 kg y entrenamiento de 48 min. No son datos personales ni están en el flujo de producción.
- Se recuperó la foto de entrenamiento del HTML. Las familias Inter y Plus Jakarta Sans se incluyeron con licencia OFL; no había binarios de fuentes en el ZIP. El enlace de logo devolvió HTML, no una imagen: la cabecera usa el nombre Myfit. Los iconos son Material de Flutter.
- Tras la primera captura se corrigieron el título y el anillo de balance, las superficies de acciones secundarias y las tarjetas de entrenamiento, gasto y peso. Persisten diferencias de espaciado, iconos, textos y densidad, especialmente en el historial inferior. La aplicación conserva el historial nutricional plegable y no inventa estados de sincronización ni metadatos de pesaje. El porcentaje se redondea con los datos calculados (72 % frente al 71 % del ejemplo).
- No se verificó visualmente esta revisión en iPhone físico, Android físico ni con texto ampliado.

Para repetir desde `mobile/fitness_app`:

```sh
STITCH_HEIGHT=884 STITCH_CAPTURE_DIR=/tmp/opencode/home-884 flutter test tool/stitch/capture_test.dart
STITCH_HEIGHT=2545 STITCH_CAPTURE_DIR=/tmp/opencode/home-2545 flutter test tool/stitch/capture_test.dart
```

## Active Workout Logger

Referencia: `myfit_active_workout_logger/screen.png` y su HTML. [Pantalla completa: exportación y Flutter](active-workout-full.webp). [Primer viewport: HTML, Flutter y superposición](active-workout-viewport.webp). Capturas con datos locales de prueba, inglés, texto a 1×, sin barras del sistema: 412 × 884 y 412 × 1873 lógicos, DPR 1. La comparación extendida se presenta a la escala de la imagen original (352 × 1600).

Tras revisar la primera captura se ajustaron la tabla de series, el ancho de los campos numéricos y el reloj en marcha. RMSE normalizado del primer viewport: 0.208955, sin equivalencia píxel a píxel. El tiempo cambia durante la simulación; los controles de cronómetro, ajustes e historial siguen disponibles y ocupan espacio distinto. No se simulan datos de sincronización ni semanas de descarga. La app se ejecutó en Linux; esta revisión no se verificó en Android o iOS reales.

Para reproducir: `STITCH_HEIGHT=884 STITCH_CAPTURE_DIR=/tmp/opencode/logger-884 flutter test tool/stitch/workout_capture_test.dart` desde `mobile/fitness_app`. La prueba también marca series, cambia kg y comprueba que la acción explícita de completar inicia el descanso.

## Review Meal Analysis

[Captura completa: Stitch y Flutter](meal-review-full.webp) y [HTML, Flutter y overlay](meal-review-viewport.webp). Se usaron las referencias `myfit_ai_meal_photo_review/{screen.png,code.html}` y la fotografía referenciada por el HTML, solo como fixture; en producción se muestra la foto del usuario. Viewport 412 × 884, extendido 412 × 2371, DPR 1, texto 1×; se comparó contenido sin barras del sistema. Tras la primera captura se ajustaron la insignia de confianza, las superficies de macros y los porcentajes. RMSE normalizado en el primer viewport: 0.226766. No es una coincidencia píxel a píxel.

Se conservan los tipos de datos actuales (nutrientes enteros y confianza por comida). La referencia incluye metadatos por ingrediente, edición de hora y presets que el flujo no ofrece; la acción secundaria abre los detalles editables. Fecha, etiquetas y alturas inferiores difieren. No se verificó la captura en teléfono físico ni contra el backend de producción.

`STITCH_HEIGHT=884 STITCH_CAPTURE_DIR=/tmp/opencode/meal-884 flutter test tool/stitch/meal_review_capture_test.dart` verifica 470 → 480 → 470 g, recálculo y confirmación de la comida de prueba.

## Nutrition overview

### Progress & Analytics (pantalla adicional)

[Pantalla completa, referencia y Flutter](progress-full.webp) · [HTML, Flutter y overlay](progress-viewport.webp) · [Android local, datos reales del AVD](progress-android-local.webp). El PNG de Stitch mide 282 × 1600; se revisó el contenido Flutter a 412 × 884 y 412 × 2338, DPR 1 y texto 1×. Tras comparar se aumentó la altura de los gráficos y se añadió la definición del porcentaje de adherencia. Se comprobó la vista en el AVD de 1280 × 2856 físicos (480 dpi), con estado vacío, conservando sus registros. Diferencias: puntos muestreados, leyendas y densidad, valores calculados, Epley en lugar de Brzycki, objetivos actuales y copia CSV en vez de HealthKit. No es una coincidencia de píxeles. `tool/stitch/progress_capture_test.dart` verifica el cambio de periodo y la vista previa de exportación con registros simulados.

Referencia: captura adjunta; el ZIP suministrado no contiene HTML ni PNG de esta portada. [Primer viewport](nutrition-viewport.webp) y [vista extendida](nutrition-full.webp) de Flutter a 412 × 884 y 412 × 2200, DPR 1, texto 1×, sin barras del sistema. Tras inspeccionar la primera captura se separaron las acciones rápidas, se añadieron porcentajes de macros y se destacó el botón de registro de las comidas vacías. No hay comparación píxel a píxel. El filtro busca registros del día, la galería usa fotos disponibles y no se simulan hidratación, comidas planificadas ni éxito de sincronización. Prueba offline: `flutter test tool/stitch/nutrition_capture_test.dart`. No se verificaron en dispositivo cámara, escáner ni sincronización remota de esta revisión.
