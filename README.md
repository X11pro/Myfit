# Myfit

Proyecto inicial para una app de nutrición, entrenamiento, balance energético y coach inteligente.

## Punto de partida

El documento principal está en:

- `docs/product/fitness_product_plan.md`

## Objetivo del producto

Crear una app Android/iOS para:

- Registrar alimentos consumidos.
- Estimar calorías, proteína, azúcar y otros macros.
- Analizar fotos de comida con IA, siempre con confirmación del usuario.
- Leer entrenamientos desde Health Connect / Apple Health y, si corresponde, Strava como integración secundaria.
- Estimar gasto diario incluyendo entrenamiento, trabajo físico y vida diaria.
- Recomendar suplementación de forma educativa y segura.

## Stack recomendado inicial

- Flutter
- Supabase
- PostgreSQL
- Supabase Edge Functions
- Health Connect para Android
- HealthKit para iOS
- Open Food Facts + USDA FoodData Central
- Modelos IA separados para visión, normalización nutricional y coach

## Sincronizar con GitHub

Repositorio remoto previsto:

```bash
git remote add origin https://github.com/X11pro/Myfit.git
```

Si el remoto ya existe:

```bash
git remote set-url origin https://github.com/X11pro/Myfit.git
```
