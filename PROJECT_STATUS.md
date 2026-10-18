# Myfit Project Status

Actualizado: 2026-10-12.

## Punto De Reanudacion

Myfit esta en una primera iteracion de rediseño UX/UI light, con prioridad absoluta en registrar sets de entrenamiento en menos de cinco segundos. No reiniciar auth, barcode, foto IA, timers ni export/delete: ya fueron validados en Android real salvo una regresion nueva.

## Ultimo Trabajo Hecho

- El tema global cambio a light mode.
- La paleta light usa la regla 60-30-10: fondo neutro, estructura carbón y naranja energético para acciones; rojo solo para errores y verde para éxito.
- El workout manual resume cada ejercicio en una tarjeta desplegable; al abrirlo, muestra sus sets y controles rápidos.
- `KG` y `REPS` se editan directamente en cada set.
- El dialogo detallado sigue disponible para ejercicio, grupo muscular, RPE y acciones secundarias.
- El onboarding recoge perfil energético: peso, altura, fecha de nacimiento, sexo opcional y actividad diaria baja/media/media-alta/alta. El dashboard usa Mifflin-St Jeor cuando el perfil está completo; conserva el cálculo previo como fallback.
- El perfil energético completo es obligatorio antes del dashboard, tanto después de OTP como en modo guest. Se puede editar después tocando la tarjeta de gasto diario estimado.
- Se agregaron los mapas `docs/product/app_roadmap_visual.md` y `docs/product/function_family_tree.md`.
- El plan de este trabajo es `.agent/plans/2026-10-12_light_workout_ux_execplan.md`.

## Estado iOS

- El 2026-10-12 Myfit compiló, instaló e inició en `iPhone 18 Pro` Simulator (`AB8AD4CB-BE80-4011-B664-3B062DC0EB07`).
- Supabase inicializó correctamente.
- La sesión de depuración se desconectó tras iniciar (`The Dart compiler exited unexpectedly`), sin error de build. Confirmar visualmente la app y el hot reload antes de considerar iOS validado.
- Falta bundle identifier definitivo, firma y QA iOS real.

## Verificaciones

Desde `mobile/fitness_app` pasaron:

```bash
flutter test test/features/workout/manual_workout_screen_test.dart
flutter test
```

`flutter analyze` no tuvo errores nuevos; conserva 10 avisos deprecados preexistentes sobre campos de formulario.

## Siguiente Paso

1. Revisar la pantalla light de workout en iOS Simulator.
2. Decidir entre precargar el ultimo `kg/reps` por ejercicio o añadir gestos para copiar/eliminar sets.
3. Retomar firma Android, privacy policy publica y soporte export/delete.
4. Consolidar migracion guest a cuenta antes de Health Connect/HealthKit.

## Notas De Git

- Continuidad documental publicada en `7f766d5 Add visual roadmap and continuity status`.
- Hay cambios previos no relacionados junto con el rediseño light. No hacer reversiones masivas.
- No versionar `mobile/fitness_app/dart_defines.local.json` ni secretos.
