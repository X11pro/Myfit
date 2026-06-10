# Fitness App — Documento base de producto y desarrollo

**Fecha:** 2026-06-10  
**Proyecto:** App de nutrición + entrenamiento + balance energético + recomendaciones inteligentes  
**Autor del plan:** ChatGPT actuando como arquitecto/desarrollador mobile senior  
**Objetivo:** Crear la base estratégica, técnica y operativa para desarrollar una app Android/iOS que permita registrar alimentos, estimar calorías/macros mediante texto, barcode y fotos, leer entrenamientos y gasto energético desde wearables/apps, y ofrecer recomendaciones seguras de nutrición/suplementación según objetivo.

---

## 1. Resumen ejecutivo

La idea es viable, pero no debe arrancar intentando competir de frente con MyFitnessPal, Cronometer, Zepp o Strava. El primer enfoque debe ser:

> **Una app personal inteligente para balance energético realista: comida + entrenamiento + vida diaria + trabajo físico + objetivo corporal.**

La ventaja no está en “contar calorías” solamente. Eso ya existe. La ventaja debe ser:

1. **Estimación rápida con cámara/foto**, aceptando margen de error.
2. **Tracking de proteína, calorías, azúcar y adherencia**, no 200 métricas desde el día uno.
3. **Integración con Health Connect en Android y HealthKit en iOS.**
4. **Modo trabajo físico**, porque mucha gente gasta calorías fuera del gym y las apps tradicionales no lo calculan bien.
5. **Recomendación de suplementación basada en evidencia**, con límites legales y sin actuar como médico.
6. **Asistente IA que explique decisiones en lenguaje simple.**
7. **Privacidad fuerte**, porque se manejarán datos de salud, comida, cuerpo, peso y entrenamiento.

---

## 2. Decisión técnica principal

### Recomendación senior

Para la primera versión:

- **Frontend mobile:** Flutter.
- **Backend:** Supabase + Edge Functions.
- **Base de datos:** PostgreSQL en Supabase.
- **Storage:** Supabase Storage para fotos de comida.
- **IA:** combinación de modelos, no un único modelo para todo.
- **Integraciones fitness:**
  - Android: Health Connect.
  - iOS: Apple HealthKit.
  - Strava: integración secundaria, con mucho cuidado legal.
  - Zepp/Amazfit: leer indirectamente a través de Health Connect / Apple Health / Strava, no intentar depender de una API privada de Zepp.

### Por qué Flutter

Flutter permite crear Android e iOS desde una sola base de código, con buen rendimiento y una experiencia visual consistente. Para tu caso, donde quieres aprender, construir rápido y publicar en ambas plataformas, Flutter es la opción más efectiva.

### Por qué no Kotlin Multiplatform de entrada

Kotlin Multiplatform/Compose Multiplatform es muy fuerte en 2026, pero exige más conocimiento nativo, tooling más complejo en iOS y más disciplina arquitectónica. Para un primer producto comercial propio, Flutter reduce fricción.

---

## 3. Riesgo importante: Strava + IA

En 2026 Strava actualizó su API Agreement y API Policy. El punto crítico es que Strava restringe fuertemente el uso de datos obtenidos por su API para aplicaciones de IA/ML, incluyendo entrenamiento, evaluación, embeddings, RAG, grounding o uso en contexto de modelos.

### Decisión de arquitectura

No diseñar el core de IA sobre datos de Strava.

En su lugar:

1. Usar **Health Connect** en Android.
2. Usar **HealthKit** en iOS.
3. Permitir conexión con Strava solo para:
   - Mostrar actividad al usuario.
   - Importar resúmenes si está permitido.
   - Evitar enviar esos datos a modelos de IA si vienen directamente de Strava.
4. Si se usa Strava, mantenerlo aislado en un módulo `strava_connector` con reglas de retención y consentimiento.

---

## 4. Zepp / Amazfit: estrategia realista

Zepp/Amazfit no debe ser la fuente directa principal de datos. La estrategia correcta es:

1. El usuario sincroniza Zepp con:
   - Health Connect / Google Health en Android.
   - Apple Health en iOS.
   - Strava si quiere.
2. Nuestra app lee de Health Connect o HealthKit.
3. Si algunos datos no aparecen, ofrecer entrada manual o importación de archivo.

### Motivo

Zepp OS tiene documentación para Mini Programs y watch faces, pero no es una API pública universal para leer todo el historial de salud del usuario desde una app móvil externa. La integración más estable para producto es pasar por las plataformas de salud del sistema.

---

## 5. MVP recomendado

### Nombre interno del MVP

**Fitness Balance MVP**

### Objetivo del MVP

Responder diariamente una pregunta:

> “¿Estoy comiendo lo adecuado para mi objetivo teniendo en cuenta mi entrenamiento, mi trabajo y mi vida diaria?”

### Funciones del MVP

#### 5.1 Registro de usuario

Campos iniciales:

- Nombre.
- Edad.
- Sexo biológico opcional, solo si el usuario acepta.
- Altura.
- Peso actual.
- Peso objetivo.
- Objetivo principal:
  - Perder grasa.
  - Ganar músculo.
  - Mantener peso.
  - Recomposición corporal.
  - Mejorar rendimiento.
- Nivel:
  - Principiante.
  - Intermedio.
  - Avanzado.
- Tipo de trabajo:
  - Sedentario.
  - De pie.
  - Trabajo físico ligero.
  - Trabajo físico moderado.
  - Trabajo físico intenso.
- Días de entrenamiento por semana.
- Duración típica de entrenamiento.
- Preferencias alimentarias.
- Restricciones o alergias, siempre como dato declarado por el usuario.

#### 5.2 Registro de alimentos

Tres modos:

1. **Manual rápido**
   - “200g chicken breast”
   - “2 eggs”
   - “1 bowl rice”
2. **Barcode scan**
   - Open Food Facts para productos empaquetados.
   - Fallback a búsqueda USDA/FoodData Central.
3. **Foto de comida**
   - Usuario toma foto o sube imagen.
   - Modelo vision identifica alimentos probables.
   - App pregunta por porción estimada si no hay confianza suficiente.
   - Se calcula aproximación de:
     - Calorías.
     - Proteína.
     - Carbohidratos.
     - Grasas.
     - Azúcar.
     - Fibra si está disponible.
   - Mostrar siempre un margen:
     - Bajo / medio / alto nivel de confianza.
     - “Estimación aproximada, no dato médico.”

#### 5.3 Dashboard diario

Pantalla principal:

- Calorías consumidas.
- Proteína consumida.
- Azúcar consumida.
- Calorías activas del entrenamiento.
- Calorías estimadas por vida diaria.
- Calorías estimadas por trabajo.
- Balance neto estimado.
- Estado del día:
  - Déficit.
  - Mantenimiento.
  - Superávit.
- Recomendación simple:
  - “Te faltan 42g de proteína.”
  - “Vas 350 kcal por encima del objetivo.”
  - “Hoy conviene cena alta en proteína y baja en azúcar.”

#### 5.4 Entrenamiento

Leer desde Health Connect/HealthKit:

- Sesiones de ejercicio.
- Duración.
- Tipo.
- Calorías activas.
- Pasos.
- Distancia.
- Frecuencia cardíaca si el usuario concede permiso.
- Peso corporal si disponible.

Entrada manual para gym:

- Ejercicio.
- Series.
- Repeticiones.
- Peso.
- RPE opcional.
- Tiempo total.
- Descanso.
- Grupo muscular.

#### 5.5 Suplementación

No “prescribir”. Recomendar de forma educativa y segura.

Primera versión:

- Proteína whey / alimentos ricos en proteína si falta proteína diaria.
- Creatina monohidrato como opción educativa para fuerza/hipertrofia, con advertencia.
- Cafeína como opción educativa pre-entreno, con advertencias.
- Electrolitos si entrenamiento largo, sudoración alta o calor.
- Omega-3, multivitamínico, vitamina D: solo como información general, no recomendación automática fuerte sin contexto.

Reglas:

- Nunca recomendar dosis médicas personalizadas.
- Nunca recomendar SARMs, esteroides, prohormonas, quemadores agresivos, estimulantes peligrosos o sustancias de alto riesgo.
- Preguntar antes por:
  - Enfermedades renales.
  - Presión arterial.
  - Medicación.
  - Problemas cardíacos.
  - Sensibilidad a cafeína.
- Mostrar disclaimer:
  - “Consulta con un profesional de salud antes de tomar suplementos si tienes condiciones médicas o tomas medicación.”

---

## 6. Features adicionales recomendadas

### 6.1 Features fuertes para diferenciarse

1. **Modo trabajo físico**
   - El usuario indica si trabajó 4, 6, 8 o 10 horas.
   - Tipo de intensidad.
   - App estima gasto adicional.
   - Muy útil para trabajadores manuales, construcción, joinery, warehouse, cleaning, delivery.

2. **Plan de proteína inteligente**
   - En vez de contar solo calorías, la app prioriza proteína.
   - Ejemplo:
     - “Hoy llevas 96g de 150g.”
     - “Cena sugerida: 250g Greek yogurt + banana + whey.”

3. **Foto + confirmación**
   - La cámara no debe decidir sola.
   - Flujo correcto:
     - Modelo detecta: arroz, pollo, verduras.
     - Pregunta: “¿Aproximadamente era media taza, una taza o dos tazas?”
     - Usuario confirma.
     - Se calcula.

4. **Comparador de días**
   - “Los días que haces piernas comes menos proteína.”
   - “Los días de trabajo intenso tienes más déficit del esperado.”

5. **Semáforo de adherencia**
   - Verde: dentro de objetivo.
   - Amarillo: margen aceptable.
   - Rojo: lejos del objetivo.

6. **Modo recomposición**
   - Para gente que no quiere solo bajar peso.
   - Evalúa:
     - Proteína.
     - Fuerza progresiva.
     - Sueño.
     - Consistencia.
     - Balance calórico semanal.

7. **Escáner de etiquetas**
   - OCR de etiqueta nutricional.
   - Convierte por 100g o por porción.
   - El usuario ajusta gramos consumidos.

8. **Recetas automáticas con sobras**
   - Basado en lo que falta:
     - “Te faltan 40g proteína y solo tienes 600 kcal disponibles.”
   - Sugerir comidas simples.

9. **Coach semanal**
   - Resumen:
     - Promedio kcal.
     - Promedio proteína.
     - Entrenamientos completados.
     - Peso.
     - Recomendación próxima semana.

10. **Modo privacidad local**
   - Guardar datos sensibles en el dispositivo.
   - Sin subir fotos salvo que el usuario active IA cloud.

---

## 7. Stack tecnológico recomendado

## 7.1 Mobile

### Principal

- Flutter
- Dart
- Riverpod para estado
- go_router para navegación
- freezed + json_serializable para modelos inmutables
- dio para HTTP
- drift o Isar para cache local/offline
- camera / image_picker para cámara y upload
- mobile_scanner para barcodes
- flutter_secure_storage para tokens
- permission_handler para permisos

### Integraciones nativas

Android:

- Health Connect SDK.
- Platform channels si el paquete Flutter no cubre todo.
- Foreground service solo si la app trackea workout en vivo.

iOS:

- HealthKit mediante plugin o código nativo Swift.
- Permisos explícitos por tipo de dato.
- No prometer precisión médica.

---

## 7.2 Backend

### Recomendado para MVP

- Supabase
  - Auth.
  - PostgreSQL.
  - Row Level Security.
  - Storage.
  - Edge Functions.
  - Realtime opcional.
- TypeScript para Edge Functions.

### Alternativa si quieres máximo control

- FastAPI
- PostgreSQL
- Redis
- S3 compatible storage
- Docker
- Hetzner/Fly.io/Render/Railway

### Recomendación final

Arrancar con Supabase. Migrar a FastAPI solo si:
- La lógica de IA crece mucho.
- Se necesita más control.
- Los costes escalan.
- Se requiere procesamiento batch serio.

---

## 7.3 IA / LLM / visión

No usar un solo modelo para todo. Usar un sistema multi-modelo.

### Modelo 1: Vision food estimator

Uso:

- Analizar fotos de comida.
- Detectar alimentos.
- Estimar porciones.
- Devolver JSON estructurado.

Recomendado:

- OpenAI GPT-5.4 mini o GPT-5.4 nano para coste/latencia.
- GPT-5.5 solo para análisis complejo o fallback.
- Alternativa: Gemini vision si el coste conviene.
- Local: Qwen2.5-VL / Qwen-VL si quieres experimentar, pero para producción inicial usar cloud.

### Modelo 2: Nutrition normalizer

Uso:

- Convertir texto libre a alimentos estructurados.
- Ejemplo:
  - Input: “two eggs and toast”
  - Output JSON:
    - eggs, 2 units.
    - toast, 1 slice.
    - confidence.
    - requires_confirmation: false.

Modelo:

- GPT-5.4 mini o nano.
- Debe usar structured outputs.
- No debe inventar valores nutricionales si puede consultar base de datos.

### Modelo 3: Coach / recommendations

Uso:

- Explicar al usuario su día.
- Recomendar ajustes.
- Generar resumen semanal.
- Recomendaciones educativas de suplementación.

Modelo:

- GPT-5.5 para razonamiento y seguridad.
- GPT-5.4 mini para respuestas cortas.

### Modelo 4: Local dev assistant

Uso:

- Ayudarte a desarrollar código.
- Generar tests.
- Revisar PRs.
- Refactorizar.

Modelo:

- GPT-5.5 / Codex como principal.
- Qwen local como secundario para borradores, documentación y tareas offline.
- No usar modelos locales para recomendaciones de salud en producción sin evaluación.

---

## 8. Arquitectura de agentes

No conviene “un agente gigante”. Conviene dividir responsabilidades.

### Agente 1 — Product Architect

Responsable de:

- Definir MVP.
- Priorizar features.
- Mantener roadmap.
- Decidir tradeoffs.

### Agente 2 — Mobile Developer

Responsable de:

- Flutter.
- UI.
- State management.
- Integraciones nativas.
- Testing mobile.

### Agente 3 — Backend Developer

Responsable de:

- Supabase.
- Edge Functions.
- PostgreSQL.
- Seguridad.
- APIs externas.

### Agente 4 — AI/Nutrition Engineer

Responsable de:

- Prompts.
- JSON schemas.
- Food photo estimation.
- Matching contra USDA/Open Food Facts.
- Confidence scoring.

### Agente 5 — Health Integration Engineer

Responsable de:

- Health Connect.
- HealthKit.
- Strava.
- Zepp indirecto.
- Permisos.
- Data mapping.

### Agente 6 — QA/Test Engineer

Responsable de:

- Unit tests.
- Widget tests.
- Integration tests.
- Test cases de comida/fotos.
- Casos borde.

### Agente 7 — Privacy/Compliance Reviewer

Responsable de:

- Data Safety Google Play.
- App Privacy Apple.
- Health data policy.
- Consentimiento.
- Borrado de datos.
- Exportación de datos.

---

## 9. Flujo de datos

### 9.1 Comida por texto

1. Usuario escribe alimento.
2. App manda texto al backend.
3. Backend usa Nutrition Normalizer.
4. Normalizer devuelve JSON.
5. Backend busca en USDA/Open Food Facts.
6. Backend calcula macros.
7. App muestra preview.
8. Usuario confirma.
9. Se guarda meal entry.

### 9.2 Comida por foto

1. Usuario toma foto.
2. App comprime imagen.
3. Sube a Supabase Storage.
4. Edge Function llama modelo vision.
5. Modelo devuelve alimentos probables.
6. Backend hace matching contra base nutricional.
7. App pide confirmación de porción.
8. Usuario confirma.
9. Se guarda estimación con confidence score.

### 9.3 Entrenamiento

1. Usuario concede permisos.
2. App lee Health Connect/HealthKit.
3. Guarda resumen local y/o backend.
4. Calcula gasto energético.
5. Si hay datos de Strava, se aíslan según política.
6. IA coach usa solo datos permitidos.

### 9.4 Balance calórico

Componentes:

- BMR estimado.
- Actividad diaria.
- Trabajo.
- Entrenamiento.
- Calorías consumidas.
- Ajuste por objetivo.

Fórmula simplificada:

```text
calorias_totales_gastadas =
  BMR
  + NEAT / vida diaria
  + gasto trabajo
  + calorias entrenamiento
  + TEF estimado
```

```text
balance =
  calorias_consumidas - calorias_totales_gastadas
```

---

## 10. Cálculos iniciales

### 10.1 BMR

Usar Mifflin-St Jeor como estimación inicial.

Hombres:

```text
BMR = 10 × peso_kg + 6.25 × altura_cm - 5 × edad + 5
```

Mujeres:

```text
BMR = 10 × peso_kg + 6.25 × altura_cm - 5 × edad - 161
```

### 10.2 Proteína objetivo

Rangos configurables:

- Mantenimiento general: 1.2–1.6 g/kg/día.
- Pérdida de grasa con entrenamiento: 1.6–2.2 g/kg/día.
- Ganancia muscular: 1.6–2.2 g/kg/día.
- Persona con condición médica: no recomendar sin profesional.

La app debe permitir configurar el objetivo y mostrar explicación.

### 10.3 Azúcar

No convertirlo en alarma extrema. Mostrar:

- Azúcar total.
- Azúcar estimada.
- Fuentes principales.
- Tendencia semanal.

---

## 11. Diseño de base de datos

### Tabla `profiles`

```sql
id uuid primary key
user_id uuid references auth.users(id)
display_name text
date_of_birth date null
height_cm numeric
sex text null
activity_level text
job_activity_level text
goal text
target_weight_kg numeric null
created_at timestamptz
updated_at timestamptz
```

### Tabla `body_metrics`

```sql
id uuid primary key
user_id uuid
date date
weight_kg numeric
body_fat_percent numeric null
source text
created_at timestamptz
```

### Tabla `food_items`

```sql
id uuid primary key
source text -- usda, open_food_facts, manual, ai_estimated
source_id text null
name text
brand text null
calories_per_100g numeric null
protein_per_100g numeric null
carbs_per_100g numeric null
fat_per_100g numeric null
sugar_per_100g numeric null
fiber_per_100g numeric null
confidence numeric
created_at timestamptz
```

### Tabla `meal_entries`

```sql
id uuid primary key
user_id uuid
meal_date date
meal_type text
food_item_id uuid null
name text
quantity numeric
unit text
estimated_grams numeric null
calories numeric
protein_g numeric
carbs_g numeric
fat_g numeric
sugar_g numeric
fiber_g numeric null
source text
confidence numeric
photo_id uuid null
created_at timestamptz
```

### Tabla `meal_photos`

```sql
id uuid primary key
user_id uuid
storage_path text
analysis_json jsonb
confidence numeric
created_at timestamptz
```

### Tabla `workout_sessions`

```sql
id uuid primary key
user_id uuid
source text -- health_connect, healthkit, manual, strava
external_id text null
started_at timestamptz
ended_at timestamptz
activity_type text
duration_minutes numeric
active_calories numeric null
total_calories numeric null
distance_m numeric null
avg_heart_rate numeric null
notes text null
ai_allowed boolean default true
created_at timestamptz
```

### Tabla `gym_sets`

```sql
id uuid primary key
workout_session_id uuid
exercise_name text
muscle_group text
set_number int
reps int
weight_kg numeric null
rpe numeric null
created_at timestamptz
```

### Tabla `daily_energy_summary`

```sql
id uuid primary key
user_id uuid
date date
bmr numeric
life_activity_calories numeric
job_calories numeric
exercise_calories numeric
calories_in numeric
protein_g numeric
sugar_g numeric
estimated_balance numeric
created_at timestamptz
```

### Tabla `supplement_recommendations`

```sql
id uuid primary key
user_id uuid
date date
recommendation_type text
reason text
safety_warning text
evidence_level text
accepted_by_user boolean null
created_at timestamptz
```

---

## 12. API interna propuesta

### Auth

```text
POST /auth/signup
POST /auth/login
POST /auth/logout
```

### Profile

```text
GET /profile
PUT /profile
```

### Food

```text
POST /food/parse-text
POST /food/analyze-photo
GET /food/search
POST /meals
GET /meals?date=
DELETE /meals/{id}
```

### Workout

```text
POST /workouts/manual
GET /workouts?date=
POST /health/import
POST /strava/connect
POST /strava/sync
```

### Summary

```text
GET /daily-summary?date=
GET /weekly-summary
```

### Coach

```text
POST /coach/daily
POST /coach/weekly
POST /coach/supplements
```

---

## 13. Diseño de pantallas

### 13.1 Onboarding

Pantallas:

1. Bienvenida.
2. Objetivo.
3. Datos corporales.
4. Nivel de actividad.
5. Tipo de trabajo.
6. Conectar Health Connect / Apple Health.
7. Preferencias y restricciones.
8. Disclaimer salud.
9. Dashboard inicial.

### 13.2 Home / Dashboard

Componentes:

- Balance calórico circular.
- Proteína progress bar.
- Azúcar progress bar.
- Entrenamiento del día.
- Trabajo/actividad diaria.
- Sugerencia del día.
- Botones rápidos:
  - Añadir comida.
  - Foto comida.
  - Añadir entrenamiento.
  - Ver coach.

### 13.3 Add Food

Tabs:

- Buscar.
- Escanear barcode.
- Foto.
- Manual.

### 13.4 Food Photo Review

Mostrar:

- Foto.
- Alimentos detectados.
- Porción estimada.
- Macros estimados.
- Nivel de confianza.
- Botón “corregir”.
- Botón “guardar”.

### 13.5 Workout

- Entrenamientos importados.
- Entrenamiento manual de gym.
- Histórico.
- Series/reps/peso.
- Gasto estimado.

### 13.6 Coach

- Resumen diario.
- Recomendación comida.
- Recomendación recuperación.
- Recomendación suplementación segura.
- Preguntas frecuentes.

### 13.7 Settings

- Permisos.
- Fuentes de datos.
- Exportar datos.
- Borrar cuenta.
- Privacidad.
- Modo local/cloud.
- Unidades kg/lb.

---

## 14. Seguridad y privacidad

### Principios

1. Pedir solo permisos necesarios.
2. Explicar para qué se usa cada dato.
3. Permitir desconectar Health Connect/HealthKit.
4. Permitir borrar cuenta y datos.
5. Permitir exportar datos.
6. No vender datos.
7. No usar datos de salud para publicidad.
8. No enviar datos a IA sin consentimiento claro.
9. Cifrar tokens.
10. Row Level Security en Supabase.

### Datos sensibles

- Peso.
- Altura.
- Salud.
- Entrenamiento.
- Fotos de comida.
- Ubicación si hay rutas.
- Frecuencia cardíaca.

### Recomendación

Para MVP, evitar almacenar GPS/rutas. No lo necesitas para calcular proteína y calorías. Menos permisos = más fácil aprobar Google Play/App Store.

---

## 15. Cumplimiento App Store / Google Play

### Google Play

Si usas Health Connect:

- Completar Data Safety.
- Completar Health Apps declaration.
- Justificar cada permiso.
- Pedir permisos granulares.
- Evitar acceso excesivo.

### Apple App Store

Si usas HealthKit:

- Pedir permiso explícito.
- Explicar metodología de estimación.
- No afirmar precisión médica.
- Incluir recomendación de consultar profesional antes de decisiones médicas.
- Privacy labels correctas.

---

## 16. Recomendaciones de suplementación: diseño seguro

### Lo que sí puede hacer la app

- Educación general.
- Explicar evidencia.
- Sugerir hablar con profesional.
- Detectar si al usuario le falta proteína.
- Recomendar alimentos antes que suplementos.
- Avisar de riesgos.

### Lo que no debe hacer

- Diagnosticar.
- Tratar enfermedades.
- Recomendar dosis médicas personalizadas.
- Recomendar suplementos peligrosos.
- Recomendar combinaciones agresivas.
- Prometer resultados.

### Ejemplo correcto

> “Hoy te faltan aproximadamente 45g de proteína para tu objetivo. Puedes cubrirlo con comida normal o, si ya usas suplementos y no tienes contraindicaciones, una proteína whey podría ser una opción práctica. Consulta con un profesional si tienes enfermedad renal, tomas medicación o dudas.”

### Ejemplo incorrecto

> “Toma X gramos exactos de suplemento Y todos los días para ganar músculo.”

---

## 17. Roadmap de desarrollo

## Fase 0 — Preparación

Duración estimada: 1 semana.

Tareas:

- Crear repositorio Git.
- Crear monorepo.
- Crear proyecto Flutter.
- Crear Supabase project.
- Definir naming.
- Crear diseño base en Figma/Penpot.
- Crear `.env.example`.
- Configurar CI básico.
- Definir esquema DB inicial.

Entregable:

- Proyecto vacío pero ejecutable en Android/iOS.
- Login funcionando.
- Navegación base.

---

## Fase 1 — MVP nutrición manual

Duración estimada: 2–3 semanas.

Tareas:

- Onboarding.
- Perfil.
- Registro manual de alimentos.
- Búsqueda básica en USDA/Open Food Facts.
- Guardado de comidas.
- Dashboard diario.
- Cálculo básico de calorías/proteína/azúcar.

Entregable:

- Usuario puede registrar comida y ver balance diario.

---

## Fase 2 — Barcode + base nutricional

Duración estimada: 1–2 semanas.

Tareas:

- Scanner barcode.
- Integración Open Food Facts.
- Fallback USDA.
- Normalización de unidades.
- Confirmación antes de guardar.
- Cache local.

Entregable:

- Usuario escanea productos y guarda macros.

---

## Fase 3 — Foto de comida + IA

Duración estimada: 3–5 semanas.

Tareas:

- Cámara.
- Upload foto.
- Análisis vision.
- JSON schema.
- Matching nutricional.
- Pantalla de confirmación.
- Confidence score.
- Correcciones manuales.
- Evaluación de precisión con 50–100 fotos propias.

Entregable:

- Usuario saca foto y obtiene estimación aproximada.

---

## Fase 4 — Health Connect / HealthKit

Duración estimada: 3–6 semanas.

Tareas:

- Android Health Connect.
- iOS HealthKit.
- Permisos.
- Leer workout sessions.
- Leer calories, steps, heart rate opcional.
- Evitar duplicados.
- Sync manual.
- UI de fuentes.

Entregable:

- App importa entrenamiento y calorías activas.

---

## Fase 5 — Trabajo + vida diaria

Duración estimada: 1–2 semanas.

Tareas:

- Selector de tipo de trabajo.
- Registro de horas trabajadas.
- Estimación de gasto por intensidad.
- Ajuste manual.
- Explicación transparente.

Entregable:

- Balance diario incluye trabajo físico.

---

## Fase 6 — Coach IA

Duración estimada: 2–4 semanas.

Tareas:

- Daily summary.
- Weekly summary.
- Recomendación de comida.
- Recomendación de recuperación.
- Recomendación de suplementación educativa.
- Safety rules.
- Audit logs de prompts/respuestas.

Entregable:

- Coach diario funcional y seguro.

---

## Fase 7 — Beta cerrada

Duración estimada: 2–4 semanas.

Tareas:

- TestFlight.
- Google Play Internal Testing.
- 10–20 testers.
- Feedback.
- Crashlytics/Sentry.
- Analytics privacy-friendly.
- Ajustar UX.

Entregable:

- Beta usable.

---

## Fase 8 — Publicación

Duración estimada: 1–2 semanas.

Tareas:

- Privacy policy.
- Terms.
- App Store screenshots.
- Google Play listing.
- Data Safety.
- Health declarations.
- Review final de permisos.
- Publicación gradual.

Entregable:

- App publicada.

---

## 18. Estructura de carpetas recomendada

```text
fitness/
  README.md
  docs/
    product/
      vision.md
      mvp.md
      roadmap.md
      user_stories.md
    architecture/
      system_architecture.md
      data_model.md
      api_contracts.md
      ai_architecture.md
      privacy_security.md
    research/
      health_connect.md
      healthkit.md
      strava_policy.md
      zepp_integration.md
      nutrition_apis.md
      supplement_safety.md
  mobile/
    fitness_app/
      lib/
        app/
        core/
        features/
          auth/
          onboarding/
          dashboard/
          food/
          workout/
          coach/
          settings/
        shared/
      test/
  backend/
    supabase/
      migrations/
      functions/
        food-parse-text/
        food-analyze-photo/
        daily-summary/
        coach/
  scripts/
    seed_foods.py
    test_photo_estimation.py
  prompts/
    food_photo_estimator.md
    nutrition_normalizer.md
    daily_coach.md
    supplement_safety.md
```

---

## 19. Primeras tareas concretas para empezar

### Día 1

1. Crear repositorio GitHub privado.
2. Crear carpeta `fitness`.
3. Crear Flutter project.
4. Crear Supabase project.
5. Crear documento `README.md`.
6. Definir nombre temporal: `Fitness Balance`.

### Día 2

1. Crear diseño simple del onboarding.
2. Crear entidades Dart:
   - UserProfile.
   - MealEntry.
   - FoodItem.
   - WorkoutSession.
   - DailySummary.
3. Crear navegación con go_router.

### Día 3

1. Implementar Supabase Auth.
2. Crear login.
3. Crear onboarding.
4. Guardar perfil.

### Día 4–7

1. Crear registro manual de comida.
2. Crear dashboard diario.
3. Crear cálculo de calorías/proteína.
4. Crear test unitarios.

---

## 20. Paquetes Flutter iniciales

```yaml
dependencies:
  flutter:
    sdk: flutter

  flutter_riverpod: ^3.0.0
  go_router: ^15.0.0
  freezed_annotation: ^3.0.0
  json_annotation: ^4.9.0
  dio: ^5.8.0
  supabase_flutter: ^2.8.0
  flutter_secure_storage: ^9.2.0
  image_picker: ^1.1.0
  camera: ^0.11.0
  mobile_scanner: ^7.0.0
  permission_handler: ^12.0.0
  intl: ^0.20.0
  drift: ^2.26.0
  path_provider: ^2.1.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^3.0.0
  json_serializable: ^6.9.0
  flutter_test:
    sdk: flutter
```

Nota: antes de instalar, revisar versiones reales en `pub.dev`.

---

## 21. JSON schemas para IA

### Food photo estimator

```json
{
  "type": "object",
  "properties": {
    "detected_foods": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "food_name": { "type": "string" },
          "estimated_quantity": { "type": "number" },
          "unit": { "type": "string" },
          "estimated_grams": { "type": "number" },
          "confidence": { "type": "number" },
          "requires_user_confirmation": { "type": "boolean" }
        },
        "required": [
          "food_name",
          "estimated_quantity",
          "unit",
          "estimated_grams",
          "confidence",
          "requires_user_confirmation"
        ]
      }
    },
    "overall_confidence": { "type": "number" },
    "warnings": {
      "type": "array",
      "items": { "type": "string" }
    }
  },
  "required": ["detected_foods", "overall_confidence", "warnings"]
}
```

### Daily coach

```json
{
  "type": "object",
  "properties": {
    "summary": { "type": "string" },
    "calorie_status": {
      "type": "string",
      "enum": ["deficit", "maintenance", "surplus", "unknown"]
    },
    "protein_status": {
      "type": "string",
      "enum": ["low", "on_target", "high", "unknown"]
    },
    "recommendations": {
      "type": "array",
      "items": { "type": "string" }
    },
    "safety_notes": {
      "type": "array",
      "items": { "type": "string" }
    }
  },
  "required": [
    "summary",
    "calorie_status",
    "protein_status",
    "recommendations",
    "safety_notes"
  ]
}
```

---

## 22. Testing

### Unit tests

- Cálculo BMR.
- Cálculo proteína objetivo.
- Conversión gramos/unidades.
- Cálculo daily summary.
- Dedupe de workouts.
- Validación JSON IA.

### Widget tests

- Onboarding.
- Add meal.
- Food photo review.
- Dashboard.
- Settings permissions.

### Integration tests

- Login.
- Add meal manual.
- Scan barcode.
- Upload photo.
- Import workout.
- Generate daily coach.

### IA evals

Crear dataset propio:

```text
evals/
  food_photos/
    image_001.jpg
    expected_001.json
```

Medir:

- Identificación correcta de comida.
- Error promedio en gramos.
- Error promedio calorías.
- Error proteína.
- Confidence calibration.

---

## 23. Monetización

No monetizar antes de tener valor real.

### Modelo recomendado

Freemium:

Gratis:

- Registro manual.
- Dashboard diario.
- 3 análisis de foto por día.
- Integración Health Connect/HealthKit básica.

Premium:

- Fotos ilimitadas.
- Coach semanal.
- Plan de proteína.
- Recomendaciones avanzadas.
- Histórico largo.
- Export CSV.
- Modo trabajo avanzado.
- Comparativas y tendencias.

Precio inicial:

- £3.99–£6.99/mes.
- £29.99–£49.99/año.

---

## 24. Riesgos

### Riesgo 1 — Precisión de fotos

Mitigación:

- Siempre pedir confirmación.
- Mostrar margen de error.
- Permitir corrección.
- Guardar confidence.

### Riesgo 2 — Salud/legal

Mitigación:

- No diagnosticar.
- Disclaimers.
- Recomendaciones educativas.
- Revisión de políticas.

### Riesgo 3 — Integraciones fitness

Mitigación:

- Health Connect/HealthKit primero.
- Strava aislado.
- Entrada manual fallback.

### Riesgo 4 — Costes IA

Mitigación:

- Usar mini/nano para tareas frecuentes.
- Cachear análisis.
- Comprimir imágenes.
- Limitar fotos en free tier.
- Procesamiento batch para resúmenes.

### Riesgo 5 — Competencia

Mitigación:

- Nicho: personas que hacen gym + trabajo físico.
- Simplicidad.
- Inglés/español.
- Coach pragmático.
- No intentar ser app médica.

---

## 25. Criterio de éxito para primera etapa

La primera etapa está lista cuando:

1. Usuario crea perfil.
2. Usuario registra comida manual.
3. Usuario escanea barcode.
4. Usuario sube foto de comida.
5. App estima calorías/proteína/azúcar.
6. Usuario corrige porciones.
7. App importa entrenamiento desde plataforma de salud.
8. App calcula balance diario.
9. Coach genera resumen.
10. App permite borrar/exportar datos.
11. Hay disclaimer y privacidad básica.
12. Está lista para beta cerrada.

---

## 26. Decisión final

Construir esta app sí tiene sentido si se enfoca como:

> **Fitness/nutrition balance app para personas reales con entrenamiento + trabajo + vida diaria, usando IA para reducir fricción, no para prometer precisión médica.**

Orden correcto:

1. Flutter app.
2. Supabase backend.
3. Nutrición manual.
4. Barcode.
5. Foto IA.
6. Health Connect/HealthKit.
7. Trabajo físico.
8. Coach.
9. Suplementación educativa.
10. Beta.
11. Publicación.

---

## 27. Fuentes consultadas

Revisadas el 2026-06-10.

- Flutter mobile: https://flutter.dev/development/mobile
- Supabase Flutter: https://supabase.com/docs/reference/dart/introduction
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- Health Connect workouts: https://developer.android.com/health-and-fitness/health-connect/experiences/workouts
- Health Connect data types: https://developer.android.com/health-and-fitness/health-connect/data-types
- Google Play health app publishing: https://developer.android.com/health-and-fitness/health-connect/publish
- Google Fit migration: https://developer.android.com/health-and-fitness/health-connect/migration/fit
- Apple HealthKit: https://developer.apple.com/documentation/healthkit
- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Strava API docs: https://developers.strava.com/docs/reference/
- Strava API Agreement 2026: https://www.strava.com/legal/api
- Strava API Policy 2026: https://www.strava.com/legal/api_policy
- Amazfit/Zepp sync support: https://support.amazfit.com/en/amazfit_gts_2_mini/docs/N6cUdJxDRo6rbfxiLs1cJDBrnRd
- Zepp OS docs: https://docs.zepp.com/docs/intro/
- Google Health third-party apps/devices: https://support.google.com/googlehealth/answer/14236613
- Open Food Facts API: https://openfoodfacts.github.io/openfoodfacts-server/api/
- USDA FoodData Central API: https://fdc.nal.usda.gov/api-guide
- OpenAI models: https://developers.openai.com/api/docs/models
- OpenAI vision: https://developers.openai.com/api/docs/guides/images-vision
- OpenAI structured outputs: https://developers.openai.com/api/docs/guides/structured-outputs
- NIH ODS exercise supplements: https://ods.od.nih.gov/factsheets/ExerciseAndAthleticPerformance-HealthProfessional/
- Australian Institute of Sport supplements framework: https://www.ais.gov.au/nutrition/supplements
