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

Desde `mobile/fitness_app`:

```powershell
flutter build apk --debug --dart-define=SUPABASE_URL=$env:SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

Salida esperada:

- `build/app/outputs/flutter-apk/app-debug.apk`

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

## 7. Siguiente prueba recomendada

1. Instalar el `app-debug.apk` actual en Android.
2. Crear una comida con foto real.
3. Confirmar que aparece en `/food/gallery`.
4. Lanzar `Analyze with AI` con esa misma foto.
5. Si falla, distinguir si el error es de formato de imagen o de credito/proveedor en OpenRouter.
