# QA de Workout y Routine Builder

## Auditoría visual de la app

- [Progress: registrar peso y exportar CSV](theme-audit/progress-dialogs.webp)
- [Nutrición: Daily Meals y Nutrition totals cerrado y abierto](theme-audit/nutrition-cards.webp)
- [Home, Workout, revisión de comida y Weekly Routine](theme-audit/other-screens.webp)

Se comprobó el tema de tarjetas y diálogos en 12 rutas con el router real, en inglés (390 × 844) y español (360 × 780). Se abrieron ambos diálogos de Progress y el detalle de gráficos; la suite de Stitch probó también el selector de comidas, Add Meal, el editor de rutinas y la revisión de una foto local. Validación: análisis de Flutter limpio, 42 pruebas generales y 6 recorridos de UI. Los permisos de cámara, OTP real y estados conectados a Supabase no se ejercitaron. Esta revisión aún no está en el iPhone ni en el emulador.

## Workout

[Weekly Routine Editor con la paleta Obsidian Kinetic](weekly-routine-palette.webp). El resumen usa los músculos, bloques, ejercicios y series guardados. Se muestran rondas solo cuando todos los ejercicios del bloque tienen el mismo número de series. No se simula sincronización ni se inventan métricas como tempo o duración. El recorrido verifica que un plan con un bloque simple, un superset y un triset se carga una sola vez (12 series), y que agregar una serie al entrenamiento produce exactamente 13.

[Comparación con Stitch](workout-cards-comparison.webp) · [Weekly Routine](weekly-routine.webp) · [Add Set](add-set.webp)

- **Weekly Routine:** selector de rutina y día, resumen, tarjetas editables y acción para aplicar el plan a un borrador vacío. No se muestran tiempos estimados, tempo ni objetivos que el modelo no guarda.
- **Add Set:** un editor por acción, controles de carga y repeticiones, RPE opcional y guardado con o sin inicio de descanso. No se muestran recomendaciones o tipos de serie ficticios.
- **Pruebas de guardado:** doble pulsación en Add y Finish deja una única serie en un único entrenamiento. Guardar dos veces con el mismo identificador no crea una segunda sesión local; tres series de igual carga y repeticiones conservan sus números individuales.
- **Pruebas de rutina:** se rechazan nombres duplicados y nuevas repeticiones de un movimiento en el mismo día, incluso si cambian las mayúsculas, los espacios o la carga. El movimiento se permite en otro día. Los conflictos antiguos se pueden corregir sin borrado automático.
- **Recorrido de punta a punta con almacenamiento local:** doble pulsación en Apply carga nueve series del plan. Añadir una serie con doble pulsación deja diez series numeradas en una única sesión guardada.

Verificación de la primera revisión: `flutter analyze --no-pub`, 36 pruebas en `flutter test --no-pub`, prueba adicional `flutter test --no-pub tool/stitch/workout_cards_capture_test.dart` y arranque en Linux. Se confirmó la instalación y apertura en el iPhone 16 físico y en el Android local Pixel 10 Pro, sin desinstalar ni limpiar datos. Falta revisar estas pantallas en el iPhone y confirmar el guardado autenticado y la sincronización con Supabase real.

### Revisión más reciente

- El botón **Cargar rutina de [día]** está en Workout y funciona con series manuales ya añadidas. Si hay un movimiento coincidente, se pide confirmación antes de reemplazarlo con los objetivos de la rutina. No se modifican los ejercicios adicionales.
- Guardar el entrenamiento incluye todos sus ejercicios en el historial que usa Progress. Añadir al plan los extras es opcional, no sobrescribe bloques existentes y solo afecta al día del entrenamiento.
- [Add Set, Superset y Triset con el mismo estilo](workout-editors.webp). Pasaron 39 pruebas y el recorrido adicional en un viewport de 412 × 884.
- Esta revisión se instaló y abrió en el iPhone 16 físico (Release) y el Pixel 10 Pro local (`emulator-5554`), sin desinstalar ni limpiar datos.

## Chrome

[Comparación de Routine Builder 0.2.0 con Stitch](chrome-builder-comparison.webp). Se probó edición y guardado con datos simulados en Chromium. Falta comprobar OTP y recarga en el móvil con Supabase real.
