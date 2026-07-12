# Android Release Checklist

## Base actual

- `applicationId`: `com.x11pro.myfit`
- `namespace`: `com.x11pro.myfit`
- label Android: `Myfit`
- `OnBackInvokedCallback` habilitado

## Antes del primer release real

- definir firma release
- confirmar icono final
- revisar `version` en `pubspec.yaml`
- probar `flutter build apk --release`
- validar permisos visibles al usuario

## Comandos

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --release
```

## Smoke tests minimos

- auth OTP
- onboarding
- meal manual con foto
- barcode scan
- AI analyze
- workout manual + timers
- cerrar y reabrir app
- sign out / sign in
