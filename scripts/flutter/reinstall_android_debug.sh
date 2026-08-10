#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
app_dir="$repo_root/mobile/fitness_app"
defines_path="$app_dir/dart_defines.local.json"

if [[ ! -f "$defines_path" ]]; then
  printf '%s\n' 'Missing mobile/fitness_app/dart_defines.local.json.' >&2
  printf '%s\n' 'Create it locally from dart_defines.example.json with SUPABASE_URL and SUPABASE_ANON_KEY.' >&2
  exit 1
fi

pushd "$app_dir" >/dev/null
flutter build apk --debug \
  --target-platform android-arm,android-arm64,android-x64 \
  --dart-define-from-file="$defines_path"

if [[ $# -gt 0 ]]; then
  flutter install --debug -d "$1"
else
  flutter install --debug
fi
popd >/dev/null
