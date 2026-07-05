# Windows resume

## 1. Estado de esta maquina

- Windows ya tiene `Developer Mode` activado.
- `flutter run -d windows` ya vuelve a compilar.
- La app ya inicializo Supabase correctamente en `Edge` y `Windows` cuando se le pasaron `--dart-define` reales.
- `flutter run -d windows` puede perder la conexion de debug despues del arranque, pero el binario si se genera y abre.

## 2. Variables a recargar en PowerShell

No guardarlas en el repo.

```powershell
$env:SUPABASE_ACCESS_TOKEN="sbp_TU_TOKEN"
$env:SUPABASE_URL="https://TU-PROYECTO.supabase.co"
$env:SUPABASE_ANON_KEY="TU_ANON_KEY"
$env:OPENROUTER_API_KEY="TU_OPENROUTER_API_KEY"
$env:OPENROUTER_MODEL="qwen/qwen3-vl-8b-instruct"
```

## 3. Comandos de verificacion Supabase

Desde la raiz del repo:

```powershell
npx supabase projects list
npx supabase link --project-ref cyecalxewqcyxxglxloa --workdir backend --yes
npx supabase functions list --project-ref cyecalxewqcyxxglxloa --workdir backend
```

Estado ya confirmado en Windows:

- `food-catalog-upsert` activa.
- `meal-photo-analyze` activa.
- `food-catalog-upsert` respondio `200 OK` con payload manual autenticado.
- `meal-photo-analyze` respondio autenticado y llego a OpenRouter; queda pendiente validarlo con foto real.

## 4. Flutter en Windows

Para correr en web:

```powershell
flutter run -d edge --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

Para correr en desktop Windows:

```powershell
flutter run -d windows --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

Si el debug pierde conexion pero el binario ya arranco, tambien puedes abrir:

```text
mobile/fitness_app/build/windows/x64/runner/Debug/fitness_app.exe
```

## 5. Android debug APK

Forma recomendada desde la raiz del repo:

1. Generar una sola vez el archivo local no versionado:

```powershell
.\scripts\flutter\save_local_dart_defines.ps1
```

Ese script crea `mobile/fitness_app/dart_defines.local.json` usando:

- `SUPABASE_URL` + `SUPABASE_ANON_KEY` si ya existen en la shell, o
- `SUPABASE_ACCESS_TOKEN` para recuperar la anon key por CLI y reconstruir la URL del proyecto.

2. Compilar siempre el APK debug funcional con:

```powershell
.\scripts\flutter\build_android_debug.ps1
```

3. Si quieres correr directo en Android por USB/emulador:

```powershell
.\scripts\flutter\run_android_debug.ps1
```

Alternativa manual desde `mobile/fitness_app`:

```powershell
flutter build apk --debug --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

Salida esperada:

- `build/app/outputs/flutter-apk/app-debug.apk`
- Si usas los scripts, no hace falta volver a pegar `--dart-define` en cada build.

## 6. Estado funcional actual de food

- `manual food entry` ya soporta foto desde galeria/camara.
- En web, la foto se guarda como `data:` URL para evitar el crash previo por `path_provider`.
- Ya existe `/food/gallery` con:
  - foto,
  - fecha,
  - meal type,
  - calorias,
  - proteina,
  - carbs,
  - grasas,
  - azucar,
  - fibra,
  - confianza AI,
  - editar y eliminar.
- `Add meal` ya muestra un acceso directo visible a `Food gallery`.
- `Gym tracker` ya incluye:
  - cronometro de sesion,
  - cronometro de descanso,
  - sincronizacion del timer de sesion con `Duration (min)`,
  - arranque automatico del timer de descanso al agregar o repetir un set.

## 7. Siguiente prueba recomendada

1. Instalar el `app-debug.apk` actual en Android.
2. Probar una sesion de gym real con el cronometro total y el cronometro de descanso.
3. Crear una comida con foto real.
4. Confirmar que aparece en `/food/gallery`.
5. Lanzar `Analyze with AI` con esa misma foto.
6. Si falla, distinguir si el error es de formato de imagen o de credito/proveedor en OpenRouter.
