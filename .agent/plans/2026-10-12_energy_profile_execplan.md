# Energy Profile ExecPlan

## Objetivo

Recoger un perfil energético breve durante el onboarding para estimar el gasto diario y mostrar al usuario si su ingesta está en déficit, mantenimiento o superávit.

## Alcance

- Añadir fecha de nacimiento, sexo opcional y actividad diaria fuera del entrenamiento.
- Mantener peso, altura y objetivo actuales.
- Persistir el perfil en local y en `profiles` para usuarios autenticados.
- Usar Mifflin-St Jeor cuando el perfil está completo.
- Mantener el cálculo anterior como fallback para perfiles existentes incompletos.
- Mostrar en dashboard que el balance es una estimación y su gasto diario calculado.

## Límites

- Es una estimación educativa, no una medición médica.
- No solicitar datos clínicos, patologías ni información innecesaria.
- El sexo es opcional; sin ese dato se usa una constante intermedia y se comunica menor precisión.

## Verificación

1. Tests de BMR, actividad y fallback de cálculo.
2. Tests de persistencia de perfil local.
3. `dart format`, `flutter analyze` y `flutter test`.
