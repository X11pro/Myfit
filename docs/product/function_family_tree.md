# Árbol De Funciones De Myfit

Leyenda: `[LISTO]` disponible ahora, `[EN CURSO]` necesita consolidación, `[SIGUIENTE]` próximo bloque, `[FUTURO]` backlog.

```mermaid
mindmap
  root((Myfit))
    Experiencia principal
      Welcome y acceso [LISTO]
        Idioma EN / ESP
        Continuar como guest
        Abrir app con sesión
      Onboarding [LISTO]
        Perfil corporal
        Objetivo
        Actividad y trabajo
        Peso inicial
      Dashboard [LISTO]
        Balance diario
        Objetivos de macros
        Comidas del día
        Peso diario
        Acciones rápidas
      Progreso [EN CURSO]
        Peso corporal
        Calorías
        Fuerza
          Peso máximo
          Volumen
          1RM educativo
    Comida
      Registro manual [LISTO]
        Nombre y tipo de comida
        Calorías y macros
        Editar y borrar
      Barcode [LISTO]
        Cámara móvil
        Código manual
        Open Food Facts
        Fallback USDA
        Cache Supabase
      Foto e IA [LISTO]
        Cámara o galería
        Analyze with AI
        Confianza
        Ingredientes editables
        Peso editable
        Recalcular macros
      Galería [LISTO]
        Fotos
        Macros
        Editar y borrar
      Catálogo compartido [EN CURSO]
        Producto y marca
        Barcode
        Etiqueta con OCR o IA
        Puntuación nutricional
    Entrenamiento
      Workout manual [LISTO]
        Sesiones por fecha
        Ejercicios por grupo muscular
        Sets múltiples
        Peso y repeticiones
          Edición directa rápida
        RPE
        Notas
        Repetir último set
        Ejercicios recientes
      Rutinas semanales [LISTO local]
        Biblioteca de rutinas
        Rutina activa
        Lunes a domingo
        Bloques normales
        Superseries
        Triseries
      Timers [LISTO]
        Tiempo total
        Tiempo activo
        Descanso
        Sonido
        Vibración
      UX rápido [EN CURSO]
        Tema claro
        Sets visibles
        Menos de 5 segundos por set
        Precargar último peso y reps [SIGUIENTE]
        Gestos copiar o borrar [SIGUIENTE]
    Cuenta y datos
      Auth OTP [LISTO]
        Email
        Verificar código
        Sesión persistente
        Sign out
      Persistencia híbrida [LISTO]
        Guest local
        Cuenta remota
        Comidas
        Fotos
        Peso
        Workouts
      Privacidad [LISTO]
        Exportar datos
        Borrar datos
        RLS Supabase
      Migración guest a cuenta [SIGUIENTE]
        Sin pérdida de datos
        Sin duplicados
    Backend
      Supabase [LISTO]
        Auth
        PostgreSQL
        Storage
        Edge Functions
      Funciones activas [LISTO]
        meal-photo-analyze
        food-barcode-lookup
        food-catalog-upsert
        user-data-manage
      IA [LISTO]
        OpenRouter
        Qwen3 VL
        JSON estructurado
        Confirmación humana
    Próximas familias
      Release Android [SIGUIENTE]
        Firma
        Privacy policy pública
        Soporte
      Salud [SIGUIENTE]
        Health Connect
        HealthKit
        Permisos y dedupe
      Balance energético [FUTURO]
        Trabajo físico
        NEAT
        Explicación de cálculos
      Coach seguro [FUTURO]
        Resumen diario
        Resumen semanal
        Suplementación educativa
      Ecosistema [FUTURO]
        Wearables indirectos
        Export CSV y JSON
        Strava secundario
        Spotify
```

La rama principal para usar todos los días es: `Dashboard -> Workout manual -> sets con kg/reps -> guardar sesión -> Progreso`.
