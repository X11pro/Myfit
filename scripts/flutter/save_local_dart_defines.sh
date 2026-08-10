#!/usr/bin/env bash

set -euo pipefail
umask 077

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
defines_path="$repo_root/mobile/fitness_app/dart_defines.local.json"

read -r -p 'Supabase URL: ' supabase_url
read -r -s -p 'Supabase anon key: ' supabase_anon_key
printf '\n'

if [[ -z "$supabase_url" || -z "$supabase_anon_key" ]]; then
  printf '%s\n' 'Both values are required.' >&2
  exit 1
fi

if [[ ! "$supabase_url" =~ ^https://[a-z0-9-]+\.supabase\.co/?$ ]]; then
  printf '%s\n' 'Supabase URL must be https://<project-ref>.supabase.co.' >&2
  exit 1
fi

printf '{\n  "SUPABASE_URL": "%s",\n  "SUPABASE_ANON_KEY": "%s"\n}\n' \
  "$supabase_url" "$supabase_anon_key" >"$defines_path"

printf 'Local Dart defines saved at %s\n' "$defines_path"
