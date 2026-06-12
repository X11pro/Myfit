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
sudo pacman -S --needed git base-devel curl unzip xz zip cmake ninja jdk17-openjdk android-tools
```

Si vas a desarrollar Android tambien necesitaras Android Studio o command line tools del SDK.

## 4. Flutter

Si Flutter no esta instalado globalmente, ejemplo manual:

```bash
mkdir -p "$HOME/tools"
cd "$HOME/tools"
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$HOME/tools/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
flutter --version
```

Si usas `zsh`, cambia `~/.bashrc` por `~/.zshrc`.

## 5. Android toolchain

- Instalar Android Studio, o
- instalar Android command line tools y aceptar licencias.

Comandos utiles:

```bash
flutter doctor
flutter doctor --android-licenses
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
- `OPENAI_API_KEY`
- `USDA_FDC_API_KEY`

## 8. Supabase

Pendiente conectar proyecto real. Cuando lo hagas:

1. Crear proyecto.
2. Aplicar migracion `backend/supabase/migrations/20260612_000001_initial_schema.sql`.
3. Configurar `SUPABASE_URL` y `SUPABASE_ANON_KEY` para la app.

## 9. Primer objetivo al volver

Implementar autenticacion real y guardar el onboarding en `profiles`.

## 10. Prompt recomendado para agente

Usar `prompts/codex_start_prompt.md`.

## 11. Auto-sync opcional cada 20 minutos en Linux

Desde la raiz del repo:

```bash
chmod +x scripts/git/sync_to_github.sh scripts/git/install_linux_autosync.sh
./scripts/git/install_linux_autosync.sh
systemctl --user status myfit-git-sync.timer
```

Esto crea un timer de `systemd --user` que ejecuta sync cada 20 minutos.
