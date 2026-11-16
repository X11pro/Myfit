# OTP check style ExecPlan

## Objetivo

Rediseñar la pantalla de verificacion OTP como una vista focalizada y clara de seis digitos, sin cambiar el flujo de autenticacion de Supabase.

## Alcance

- Mostrar una pantalla OTP dedicada de fondo blanco cuando la ruta abre `LoginScreen` en modo codigo.
- Usar seis celdas visuales, teclado numerico, CTA de confirmacion y reenvio con espera de 60 segundos.
- Mantener la opcion de volver a cambiar email y textos localizados EN/ESP.
- Añadir prueba de widget de la estructura OTP.

## Verificacion

1. `dart format` sobre los archivos modificados.
2. `flutter analyze`.
3. `flutter test`.
