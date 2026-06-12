# Arquitectura IA

## Responsabilidades separadas

- Vision food estimator.
- Nutrition normalizer.
- Daily/weekly coach.

## Principios

- No usar un modelo unico para todo.
- Structured outputs obligatorios.
- Reglas de seguridad antes de generar recomendaciones de suplementos.
- Evitar enviar a modelos datos no permitidos por contratos externos.

## Datos de entrada

- Texto libre de alimentos.
- Fotos de comida.
- Resumen energetico diario.
- Perfil y objetivo del usuario.

## Datos de salida

- Alimentos estructurados.
- Porciones estimadas con `confidence`.
- Recomendaciones cortas, accionables y seguras.

## Riesgos controlados

- Alucinacion nutricional.
- Sobreconfianza en estimaciones visuales.
- Uso indebido de datos de salud o de terceros.
