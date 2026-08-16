#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
macmini_host="${1:-${MYFIT_MACMINI_HOST:-}}"
remote_repo="${2:-${MYFIT_MACMINI_REPO:-}}"
sync_interval_seconds="${MYFIT_MACMINI_SYNC_INTERVAL_SECONDS:-3}"
ssh_key="${MYFIT_MACMINI_SSH_KEY:-$HOME/.ssh/id_ed25519_macmini}"

if [[ -z "$macmini_host" || -z "$remote_repo" ]]; then
  printf '%s\n' 'Usage: watch_sync_to_macmini.sh <user@macmini-host> <remote-repo-path>' >&2
  printf '%s\n' 'Or set MYFIT_MACMINI_HOST and MYFIT_MACMINI_REPO.' >&2
  exit 1
fi

if ! [[ "$sync_interval_seconds" =~ ^[1-9][0-9]*$ ]]; then
  printf '%s\n' 'MYFIT_MACMINI_SYNC_INTERVAL_SECONDS must be a positive integer.' >&2
  exit 1
fi

if [[ ! -f "$ssh_key" ]]; then
  printf 'Mac mini SSH key not found: %s\n' "$ssh_key" >&2
  exit 1
fi

command -v rsync >/dev/null || {
  printf '%s\n' 'rsync is required.' >&2
  exit 1
}

command -v ssh >/dev/null || {
  printf '%s\n' 'ssh is required.' >&2
  exit 1
}

sync_once() {
  rsync --archive --compress --delete-delay \
    --exclude='.git/' \
    --exclude='.dart_tool/' \
    --exclude='build/' \
    --exclude='.env' \
    --exclude='.env.local' \
    --exclude='dart_defines.local.json' \
    --exclude='mobile/fitness_app/ios/Pods/' \
    --exclude='mobile/fitness_app/ios/.symlinks/' \
    --exclude='mobile/fitness_app/macos/Flutter/ephemeral/' \
    -e "ssh -i $ssh_key -o IdentitiesOnly=yes" \
    "$repo_root/" "$macmini_host:$remote_repo/"
  printf 'Myfit synced to Mac mini at %(%F %T)T\n' -1
}

printf 'Watching Myfit and syncing to %s every %s seconds. Press Ctrl+C to stop.\n' \
  "$macmini_host:$remote_repo" "$sync_interval_seconds"

while true; do
  sync_once
  sleep "$sync_interval_seconds"
done
