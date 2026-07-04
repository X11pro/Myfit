# Roadmap

## Fase 0

- Base del repo.
- Documentacion.
- Estructura monorepo.
- Configuracion Git y entorno.

## Fase 1

- Flutter app base.
- Auth.
- Onboarding.
- Perfil.
- Registro manual de alimentos.
- Dashboard diario.

## Fase 2

- Barcode scanner.
- Integracion `Open Food Facts`.
- Fallback `USDA`.
- Cache local.

## Fase 3

- Captura y subida de fotos.
- Analisis IA.
- Confirmacion de porciones.
- Confidence score.

## Fase 4

- `Health Connect`.
- `HealthKit`.
- Dedupe de workouts.
- UI de permisos y fuentes.

## Fase 5

- Modo trabajo fisico.
- Ajuste de gasto diario.
- Transparencia de calculos.

## Fase 6

- Coach diario y semanal.
- Recomendaciones de recuperacion.
- Reglas de seguridad para suplementos.

## Fase 7

- Beta cerrada.
- Telemetria privacy-friendly.
- Ajustes UX.

## Fase 8

- Politica de privacidad.
- Material de tiendas.
- Declaraciones de salud.
- Publicacion gradual.

## Backlog post-MVP

- Cronometro de inicio/fin para medir tiempo total de entrenamiento.
- Cronometro de descanso entre series.
- Fotos de ejercicios o del cuerpo para analizar tecnica/postura de forma educativa.
- Exportacion de datos para analisis externo en un SaaS propio para PC o Mac.
- Integracion de musica o playlists con `Spotify` u otro servicio compatible.
- Vinculacion con smartwatch o smart ring para mejorar precision de datos de entrenamiento y recuperacion.

## Notas de prioridad

- Alta despues del flujo core actual: cronometro total de entrenamiento.
- Alta despues del flujo core actual: cronometro de descanso entre series.
- Media: exportacion de datos, porque ayuda al analisis externo sin bloquear el MVP mobile.
- Media-baja: integraciones con wearables, cuando el flujo base manual y Health Connect/HealthKit ya este estable.
- Baja por ahora: musica/playlists, porque no mejora el tracking principal.
- Baja y con cuidado tecnico/legal: analisis de postura por foto, porque implica UI, privacidad y validacion tecnica adicional.
