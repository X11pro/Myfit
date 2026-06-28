# Recomendacion de LLM free para reconocimiento de comida

## Objetivo

Elegir el modelo mas indicado para probar reconocimiento de comida desde foto sin incurrir en costo por uso de API propietaria.

## Recomendacion principal

- Modelo recomendado: `Qwen2.5-VL-7B-Instruct`.

## Por que este modelo

- Tiene buen equilibrio entre calidad y costo operativo para `vision + texto`.
- Suele responder mejor que otras opciones open en extraccion estructurada a JSON.
- Sirve para reconocer comida, estimar porciones probables y devolver una `confidence` util.
- Es mas viable para correr barato o local que modelos mucho mas grandes.

## Uso recomendado en Myfit

Usarlo solo para:

- identificar la comida,
- listar items probables,
- estimar porcion,
- devolver confianza,
- producir JSON estable.

No usarlo como fuente final unica de calorias y macros. Para eso, cruzar el resultado con:

- `USDA FoodData Central`,
- `Open Food Facts`,
- o catalogo propio compartido.

## Salida sugerida del modelo

```json
{
  "meal_name": "chicken rice bowl",
  "possible_items": ["chicken breast", "white rice", "mixed vegetables"],
  "estimated_portion": "medium plate",
  "confidence": 0.78,
  "notes": "Likely home-cooked meal. Portion could vary."
}
```

## Ranking practico

1. `Qwen2.5-VL-7B-Instruct`
2. `Qwen2-VL-7B-Instruct`
3. `Llama 3.2 Vision 11B`
4. `MiniCPM-V`

## Decision tecnica sugerida

- Mantener el flujo actual de `meal-photo-analyze` con salida JSON y confirmacion del usuario.
- Si se quiere evitar gasto, evaluar migrar esa parte del backend a un modelo open como `Qwen2.5-VL-7B-Instruct` en infraestructura propia o proveedor compatible.
- La app nunca debe guardar automaticamente una comida detectada por foto sin confirmacion del usuario.

## Estado al cerrar esta sesion

- La recomendacion actual sigue siendo `Qwen2.5-VL-7B-Instruct` como mejor opcion free/open para esta prueba.
- El backend actual todavia apunta a OpenAI en `backend/supabase/functions/meal-photo-analyze/index.ts`.
- Queda pendiente decidir si se mantiene OpenAI para pruebas iniciales o se reemplaza por un backend free/open para reconocimiento de comida.
