# Prompt inicial para Codex

Usa este prompt cuando abras el repositorio con Codex:

```text
Lee primero AGENTS.md y docs/product/fitness_product_plan.md.

Quiero que actúes como arquitecto mobile senior y me ayudes a construir Myfit paso a paso.

No empieces por IA avanzada. Primero crea la base sólida del proyecto.

Primer objetivo:
1. Revisar la estructura actual del repo.
2. Proponer un ExecPlan para el milestone 1.
3. El milestone 1 debe crear una app Flutter ejecutable con:
   - onboarding básico,
   - modelo de perfil,
   - entrada manual de comida,
   - cálculo local de calorías/proteína,
   - dashboard diario simple,
   - estructura preparada para Supabase, pero sin claves reales.
4. Antes de modificar archivos, explícame brevemente el plan.
5. Después implementa en pasos pequeños.
6. Añade tests para los cálculos.
7. Ejecuta `dart format .`, `flutter analyze` y `flutter test` si Flutter está disponible.

Responde en español.
```
