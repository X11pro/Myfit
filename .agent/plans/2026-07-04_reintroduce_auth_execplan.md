# ExecPlan: Reintroducir auth sin Auth0

## Objetivo

Reactivar autenticacion real con Supabase en una primera iteracion minima sin romper el flujo guest-first actual.

## Alcance de esta iteracion

1. Exponer una ruta de cuenta/auth desde la app actual.
2. Reutilizar el login por email OTP ya implementado.
3. Mostrar un estado de cuenta usable cuando el usuario ya esta autenticado.
4. Mantener guest mode como camino principal cuando no hay sesion o faltan variables de entorno.
5. Evitar todavia la sincronizacion remota de comidas y workouts; eso queda para la siguiente iteracion.

## Decisiones

- Se mantiene Supabase email OTP porque ya existe en el repo y evita agregar dependencias nuevas.
- La pantalla de login pasa a funcionar tambien como pantalla de cuenta minima.
- La entrada a auth queda disponible desde `splash` y desde el menu global.
- Si faltan `SUPABASE_URL` o `SUPABASE_ANON_KEY`, la app sigue usable en guest mode y deja el mensaje claro.

## Verificacion prevista

1. `dart format .`
2. `flutter analyze`
3. `flutter test`

## Siguiente iteracion esperada

- Empezar a conectar persistencia remota de onboarding/comidas/workouts a una identidad real sin perder el fallback local.
