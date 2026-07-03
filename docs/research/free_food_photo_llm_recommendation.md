# Recomendacion free/open para reconocimiento de comida por foto

## Decision vigente

- Opcion recomendada actual para costo cero o muy bajo en este repo: `qwen/qwen3-vl-8b-instruct` via OpenRouter.
- Uso previsto: reconocimiento de comida desde foto, estimacion inicial de porcion, `confidence` y salida JSON estructurada.
- Limite deliberado: no usar el LLM como fuente final unica de macros.

## Enfoque aprobado

1. El modelo vision reconoce alimentos probables y devuelve una estructura conservadora.
2. La respuesta debe incluir nombre detectado, porcion estimada, `confidence` y notas breves.
3. Las macros finales se resuelven contra `USDA`, `Open Food Facts` y/o catalogo compartido cuando haya match suficiente.
4. El usuario confirma alimento y porcion antes de guardar.

## Motivo de esta decision

- Mantiene el costo bajo frente a APIs cerradas mas caras.
- Encaja con la regla del producto: AI para reconocimiento y ayuda, no para inventar nutricion final.
- Permite mantener backend simple con Edge Functions y JSON estable para Flutter.

## Implicacion tecnica inmediata

- La migracion backend actual usa `OPENROUTER_API_KEY` y por defecto `OPENROUTER_MODEL=qwen/qwen3-vl-8b-instruct`.
- El siguiente paso tecnico correcto es desplegar las funciones migradas y probarlas end-to-end manteniendo el mismo contrato JSON hacia Flutter o cambiandolo solo si hace falta para agregar porcion y campos de matching nutricional.

## Restricciones a preservar

- Siempre devolver `confidence`.
- Siempre devolver JSON estructurado.
- No guardar automaticamente sin confirmacion del usuario.
- No depender solo del LLM para calorias y macros si hay una fuente nutricional mas confiable disponible.

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
