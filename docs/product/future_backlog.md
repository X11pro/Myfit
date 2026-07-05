# Future Backlog

## Objetivo

Ordenar features futuras que no bloquean el MVP ni el flujo core actual, pero que pueden aumentar retencion, precision de datos o valor percibido del producto.

## Criterios de priorizacion

- Valor para el tracking principal: comida, entrenamiento, balance y recuperacion.
- Dependencias tecnicas reales: auth, persistencia remota, permisos de salud, integraciones externas.
- Riesgo legal o de plataforma.
- Complejidad de UX para no romper el flujo rapido diario.

## Grupo 1: Wearables y recovery

### 1. Smartwatch y smart ring via plataformas de salud

- Estado: backlog activo.
- Prioridad: media-baja.
- Valor: alto para precision de actividad, recuperacion y datos pasivos.
- Complejidad: media-alta.
- Dependencias:
  - `Health Connect` estable en Android.
  - `HealthKit` estable en iOS.
  - auth y persistencia remota definidas.
  - explicacion clara de permisos y fuentes.
- Enfoque recomendado:
  - no integrar dispositivos directo en la primera etapa;
  - leer datos desde `Health Connect` y `HealthKit`;
  - soportar indirectamente `Apple Watch`, `Galaxy Watch`, `Oura`, `Amazfit`, `Zepp` y otros si sincronizan con la plataforma del sistema.
- Casos de uso:
  - importar calorias activas, frecuencia cardiaca, pasos, sueno y peso corporal si existe;
  - mejorar estimacion de recuperacion y carga del dia;
  - comparar fuente manual vs fuente automatica.
- Riesgos:
  - diferencias entre fuentes y duplicados;
  - permisos sensibles de salud;
  - disponibilidad desigual por sistema operativo y marca.

### 2. Integracion indirecta con Zepp/Amazfit

- Estado: backlog condicionado.
- Prioridad: baja-media.
- Valor: medio.
- Complejidad: media.
- Dependencias:
  - que el usuario ya sincronice con `Health Connect`, `HealthKit` o `Strava`.
- Enfoque recomendado:
  - no depender de API privada de `Zepp`;
  - documentar setup recomendado para que el usuario enlace su wearable con la plataforma del sistema.
- Riesgos:
  - soporte inconsistente;
  - cambios de politica del proveedor.

### 3. Recovery score simple

- Estado: futuro util despues de wearables base.
- Prioridad: media.
- Valor: medio-alto.
- Complejidad: media.
- Dependencias:
  - datos de sueno, frecuencia cardiaca en reposo o carga previa;
  - reglas transparentes y no medicas.
- Enfoque recomendado:
  - score explicable;
  - mensajes tipo `hoy conviene bajar intensidad`;
  - evitar lenguaje de diagnostico.

## Grupo 2: Musica y foco de entrenamiento

### 4. Integracion de playlists con Spotify u otro servicio

- Estado: idea documentada, no prioritaria.
- Prioridad: baja.
- Valor: medio para experiencia, bajo para tracking core.
- Complejidad: media.
- Dependencias:
  - definir si la app solo abre playlists o si controla reproduccion;
  - revisar SDK, auth y politicas del proveedor.
- Alcance minimo recomendado:
  - permitir abrir una playlist favorita desde la pantalla de workout.
- Alcance posterior posible:
  - sugerencias por tipo de entrenamiento;
  - playlists guardadas por rutina o intensidad.
- Riesgos:
  - complejidad de OAuth;
  - poco impacto sobre la metrica principal del producto.

### 5. Audio cues para workout

- Estado: candidato mejor que playlists completas.
- Prioridad: media-baja.
- Valor: medio.
- Complejidad: baja-media.
- Dependencias:
  - timers de descanso y sesion ya estables.
- Enfoque recomendado:
  - sonidos o vibracion para fin de descanso;
  - opcion de voz simple para proximos sets.
- Motivo:
  - aporta mas al flujo principal que una integracion musical grande.

## Grupo 3: Integraciones externas y ecosistema

### 6. Exportacion de datos a SaaS propio de escritorio

- Estado: backlog util.
- Prioridad: media.
- Valor: medio-alto.
- Complejidad: media.
- Dependencias:
  - modelo remoto de identidad;
  - formato de exportacion estable.
- Enfoque recomendado:
  - `CSV` y `JSON` primero;
  - luego sync hacia dashboard web o desktop.
- Casos de uso:
  - analisis historico;
  - reporting avanzado;
  - backup portable del usuario.

### 7. Strava como integracion secundaria

- Estado: permitido con restricciones.
- Prioridad: baja-media.
- Valor: medio.
- Complejidad: media-alta.
- Dependencias:
  - validar politica vigente;
  - aislar datos de `Strava` del flujo IA.
- Enfoque recomendado:
  - conectar para mostrar actividad o importar resumenes cuando este permitido;
  - no usar como base principal del sistema.
- Riesgos:
  - cambios de policy;
  - limitaciones de uso para IA/ML.

## Grupo 4: Features adjuntas de alto cuidado

### 8. Fotos de tecnica, postura o progreso fisico

- Estado: backlog con cuidado especial.
- Prioridad: baja.
- Valor: medio.
- Complejidad: alta.
- Dependencias:
  - storage remoto;
  - consentimiento claro;
  - lineamientos fuertes de privacidad.
- Enfoque recomendado:
  - historial privado;
  - analisis educativo, no medico;
  - confirmaciones y disclaimers claros.
- Riesgos:
  - privacidad;
  - expectativas irreales de precision;
  - costo de storage e inferencia.

## Orden sugerido de implementacion futura

1. Consolidar `Health Connect` y `HealthKit`.
2. Definir auth y persistencia remota multiusuario.
3. Exportacion de datos `CSV/JSON`.
4. Wearables indirectos via plataformas de salud.
5. Recovery score simple y explicable.
6. Audio cues de workout.
7. Strava secundario con policy revisada.
8. Playlists/musica.
9. Fotos de tecnica/postura con privacidad reforzada.

## Decisiones explicitas por ahora

- No hacer integracion directa temprana con APIs privadas de relojes o anillos.
- No priorizar musica por encima de tracking, persistencia y salud.
- No construir features de recovery opacas o que parezcan diagnostico medico.
- No mezclar datos restringidos de terceros con pipelines de IA si la policy no lo permite.
