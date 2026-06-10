# Codex Context Pack para Myfit

Este paquete contiene archivos para que Codex entienda el proyecto sin tener que pegar todo manualmente en cada prompt.

## Archivos

- `AGENTS.md`: instrucciones persistentes que Codex carga al trabajar en el repo.
- `.agent/PLANS.md`: guía para planes largos de implementación.
- `prompts/codex_start_prompt.md`: prompt inicial recomendado.
- `docs/product/fitness_product_plan.md`: documento base del producto.

## Cómo usarlo

Copia estos archivos en la raíz del repositorio `Myfit`.

Estructura esperada:

```text
Myfit/
  AGENTS.md
  .agent/PLANS.md
  prompts/codex_start_prompt.md
  docs/product/fitness_product_plan.md
```

Después abre Codex desde la carpeta del repositorio y pega el prompt de `prompts/codex_start_prompt.md`.
