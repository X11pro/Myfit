# Retomar en CachyOS

## 1. Clonar el repo

```bash
git clone https://github.com/X11pro/Myfit.git
cd Myfit
```

## 2. Leer primero

Abrir estos archivos antes de seguir:

- `AGENTS.md`
- `docs/product/fitness_product_plan.md`
- `docs/handoff/current_status.md`

## 3. Dependencias base recomendadas

En CachyOS, instalar como minimo:

```bash
sudo pacman -S --needed git base-devel curl unzip xz zip cmake ninja android-tools flatpak
```

Si vas a desarrollar Android tambien necesitaras Android Studio o command line tools del SDK.

## 4. Flutter

En este equipo ya quedo funcionando desde:

```bash
$HOME/flutter
```

Si Flutter no esta instalado, ejemplo manual:

```bash
mkdir -p "$HOME"
cd "$HOME"
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter --version
```

Si usas `zsh`, cambia `~/.bashrc` por `~/.zshrc`.

Variables utiles para login shells:

```bash
export PATH="$HOME/flutter/bin:$PATH"
export JAVA_HOME="$HOME/.local/share/JetBrains/Toolbox/apps/android-studio/jbr"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
export PATH="$HOME/.local/share/flatpak/exports/bin:$PATH"
export CHROME_EXECUTABLE="$HOME/.local/share/flatpak/exports/bin/org.chromium.Chromium"
```

## 5. Android toolchain

- Android Studio ya esta instalado en este equipo via JetBrains Toolbox.
- Tambien ya quedaron instalados `cmdline-tools` en `~/Android/Sdk/cmdline-tools/latest`.
- Las licencias Android ya fueron aceptadas en este entorno.

Comandos utiles:

```bash
flutter doctor
flutter doctor --android-licenses
```

Si necesitas reinstalar `cmdline-tools` manualmente:

```bash
curl -fLo /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip
mkdir -p "$HOME/Android/Sdk/cmdline-tools/latest"
unzip -oq /tmp/commandlinetools.zip -d /tmp/android-cmdline-tools
cp -r /tmp/android-cmdline-tools/cmdline-tools/. "$HOME/Android/Sdk/cmdline-tools/latest/"
```

Para aceptar licencias si hiciera falta:

```bash
yes | sdkmanager --licenses
```

Para web, en este equipo se uso Chromium via Flatpak:

```bash
flatpak --user install -y flathub org.chromium.Chromium
```

## 6. Verificar el proyecto

```bash
cd mobile/fitness_app
flutter pub get
dart format .
flutter analyze
flutter test
```

## 7. Variables de entorno

Usar `.env.example` como referencia. No poner secretos en Git.

Variables esperadas:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `OPENROUTER_API_KEY`
- `OPENROUTER_MODEL`
- `USDA_FDC_API_KEY`

## 8. Supabase

El proyecto real de Supabase ya esta conectado y tiene aplicadas estas migraciones:

- `backend/supabase/migrations/20260612_000001_initial_schema.sql`
- `backend/supabase/migrations/20260620_000002_food_items_shared_catalog.sql`

Tambien ya esta desplegada la Edge Function:

- `food-catalog-upsert`
- `meal-photo-analyze`

Pendiente importante para OCR/AI real desde imagen:

1. Correr la app Flutter con `--dart-define` para `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
2. Probar la pantalla Flutter de catalogo compartido contra la funcion desplegada.
3. Probar el boton `Analyze with AI` de comidas manuales contra `meal-photo-analyze` con una foto valida.
4. Si `deno` esta disponible en otra maquina, correr `deno fmt` y `deno check` sobre `backend/supabase/functions`.

Estado confirmado al cerrar esta sesion:

- `food-catalog-upsert` y `meal-photo-analyze` ya fueron redeployadas.
- Los secrets remotos actuales son `OPENROUTER_API_KEY` y `OPENROUTER_MODEL`.
- El modelo en uso es `qwen/qwen3-vl-8b-instruct` via OpenRouter.
- El smoke test remoto de `food-catalog-upsert` dio OK.
- El smoke test remoto de `meal-photo-analyze` confirmo que ya pega a OpenRouter; el error observado fue solo por imagen base64 invalida.
- En workout manual ya quedo implementado el flujo `muscle group -> exercise`, sets multiples desde el dialogo y selector visual de `RPE`.
- `RPE` queda persistido por set dentro de la sesion del dia para analisis futuro de progresion.

## 9. Primer objetivo al volver

Seguir el guest flow actual y avanzar estas piezas en orden:

- validar UX del modulo gym/progreso ya implementado,
- partir del ultimo punto ya hecho: metricas de fuerza con `peso maximo`, `volumen` y `1RM estimado`,
- revisar si la siguiente mejora de gym debe ser duplicar set anterior, autocompletar ejercicios recientes o resumen por ejercicio,
- prueba real del catalogo compartido con OCR/AI ya migrado a OpenRouter,
- reintroduccion de autenticacion sin Auth0,
- conexion de comidas y catalogo a persistencia remota multiusuario.

## 10. Guest flow actual

Estado funcional actual de la app:

- dark mode fijo,
- ingles por defecto,
- selector `EN / ESP` en welcome,
- onboarding guest con perfil local persistido,
- dashboard con acciones rapidas,
- top bar global con `back`, `home` y `menu`,
- manual food entry local,
- manual workout local con edicion de sesiones y sets,
- pantalla separada de progreso con filtro por ejercicio,
- metricas de fuerza alternables: `peso maximo`, `volumen` y `1RM estimado`,
- `repeticiones` visibles junto a `sets` en resumenes de workout,
- `muscle group` como primer selector al agregar sets,
- dropdown de ejercicios populares por grupo muscular con opcion de custom exercise,
- `sets` multiples desde el dialogo,
- selector visual de `RPE` con persistencia por set,
- dashboard pulido con CTA principal, secciones plegables y grafico de linea/area,
- ingles por defecto verificado y cambio consistente a espanol desde `EN / ESP`,
- pantalla para aportar productos al catalogo compartido,
- fotos locales por comida,
- resumen diario y peso diario local,
- boton `Analyze with AI` conectado a backend,
- APK debug reciente en `build/app/outputs/flutter-apk/app-debug.apk`.

## 10.1 Ultimo punto implementado confirmado

Antes de seguir, confirmar en el repo que el ultimo bloque funcional ya presente es:

- top bar global,
- fix de `Log Workout`,
- NDK 28 alineado,
- progreso de fuerza con selector de metrica,
- `reps` al lado de `sets` en workout/dashboard,
- `Repeat last`,
- sugerencias de ejercicios recientes,
- `sets` multiples y `RPE` visual,
- flujo `muscle group -> exercise`.

## 11. Comandos utiles para Supabase

Desde la raiz del repo:

```bash
npx supabase link --project-ref cyecalxewqcyxxglxloa --workdir backend --yes
npx supabase db push --linked --workdir backend
npx supabase functions deploy food-catalog-upsert --project-ref cyecalxewqcyxxglxloa --workdir backend
npx supabase functions deploy meal-photo-analyze --project-ref cyecalxewqcyxxglxloa --workdir backend
```

Para habilitar AI real en la Edge Function:

```bash
export SUPABASE_ACCESS_TOKEN="sbp_TU_TOKEN"
npx supabase secrets set OPENROUTER_API_KEY="tu_key" OPENROUTER_MODEL="qwen/qwen3-vl-8b-instruct" --project-ref cyecalxewqcyxxglxloa
```

Deploy actual de funciones:

```bash
npx supabase functions deploy food-catalog-upsert --project-ref cyecalxewqcyxxglxloa --workdir backend
npx supabase functions deploy meal-photo-analyze --project-ref cyecalxewqcyxxglxloa --workdir backend
```

## 12. Prompt recomendado para agente

Usar `prompts/codex_start_prompt.md`.

## 13. Build debug Android

Desde `mobile/fitness_app`:

```bash
flutter clean
flutter build apk --debug
```

Salida esperada:

- `build/app/outputs/flutter-apk/app-debug.apk`

## 14. Auto-sync opcional cada 20 minutos en Linux

Desde la raiz del repo:

```bash
chmod +x scripts/git/sync_to_github.sh scripts/git/install_linux_autosync.sh
./scripts/git/install_linux_autosync.sh
systemctl --user status myfit-git-sync.timer
```

Esto crea un timer de `systemd --user` que ejecuta sync cada 20 minutos.

## 15. Regla de continuidad

La palabra clave del usuario es `AMARILLO`.

Cuando aparezca en una sesion futura, el agente debe actualizar el paquete de continuidad antes de terminar, para que el cambio de OS o entorno no corte el progreso.
