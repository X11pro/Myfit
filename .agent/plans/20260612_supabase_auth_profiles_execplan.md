# ExecPlan: Supabase Auth y profiles

## Objetivo

Conectar autenticacion real en la app Flutter y persistir el onboarding inicial del usuario usando Supabase.

## Alcance de esta iteracion

1. Reemplazar el login placeholder por login real con email OTP.
2. Cargar la sesion actual desde Supabase al iniciar la app.
3. Sincronizar estado local con `profiles` y el peso inicial con `body_metrics`.
4. Guardar onboarding inicial en Supabase.
5. Mantener el router actual con los mismos destinos base.

## Decisiones

- Se usa email OTP en vez de magic link profundo para evitar depender ahora mismo de deep links nativos.
- `profiles` guarda nombre, objetivo, actividad laboral y altura.
- `body_metrics` guarda el peso actual inicial porque el esquema ya separa esa entidad de `profiles`.
- Si faltan variables `SUPABASE_URL` o `SUPABASE_ANON_KEY`, la app sigue arrancando pero deja claro que auth real no esta disponible.

## Verificacion prevista

1. `dart format .`
2. `flutter analyze`
3. `flutter test`

## Pendiente manual fuera de codigo

- Configurar el proyecto Supabase real y correr la migracion.
- Habilitar email OTP en Supabase Auth.
