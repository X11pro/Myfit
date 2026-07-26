# Myfit - Estado del proyecto

## Listo ahora

- app Flutter guest-first con dark mode, selector `EN / ESP`, onboarding, dashboard y top bar global;
- auth por email OTP con Supabase y sesion persistente;
- persistencia hibrida local/remota para peso diario, comidas manuales, fotos de comidas y workouts manuales de usuarios autenticados;
- comida manual con macros, edicion, borrado y galeria;
- barcode con camara, cache Supabase, `Open Food Facts` y fallback `USDA`;
- foto de comida con IA via OpenRouter, confianza, ingredientes y peso editables;
- catalogo compartido de alimentos y OCR/IA de etiquetas;
- workouts manuales, sets, RPE, progreso, cronometros de sesion/descanso, sonido y vibracion;
- export/delete remoto minimo mediante `user-data-manage`;
- Android release con package `com.x11pro.myfit`.

## Pendiente de validar en dispositivo

- sign out, barcode manual/no-match/sin internet y errores controlados de backend;
- borrado individual y edicion completa de meals/workouts;
- catalogo compartido end-to-end;

## Siguiente desarrollo

1. Resolver los fallos que surjan de QA Android.
2. Integrar tiempos total, activo y descanso de workout al dashboard y analitica.
3. Cerrar firma, smoke tests, privacy policy y soporte de release Android.
4. Consolidar migracion guest -> cuenta y datos remotos por usuario.
5. Implementar Health Connect, HealthKit, modo trabajo fisico y coach seguro.

## Aun fuera del MVP inmediato

- bundle identifier iOS real;
- wearables indirectos, Strava secundario, recovery score, Spotify y analisis de postura;
- rediseño UI/UX completo, despues del cierre de QA y release.
