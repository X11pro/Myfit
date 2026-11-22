#!/usr/bin/env bash
# Sync Dart sources only to the dedicated, disposable iOS development copy.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
host="${MYFIT_MACMINI_HOST:-Mariano@192.168.1.244}"
remote="${MYFIT_IOS_LIVE_REPO:-/Users/macmini/Projects/Myfit-live}"
key="${MYFIT_MACMINI_SSH_KEY:-$HOME/.ssh/id_ed25519_macmini}"

while true; do
  rsync -az --include='*/' --include='*.dart' --exclude='*' \
    -e "ssh -i $key -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10" \
    "$repo_root/mobile/fitness_app/lib/" \
    "$host:$remote/mobile/fitness_app/lib/" || true
  sleep 3
done
