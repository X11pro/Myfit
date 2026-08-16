#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf '%s\n' 'Usage: sync_to_macmini.sh <user@macmini-host> [remote-repo-path]' >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
macmini_host="$1"
remote_repo="${2:-$HOME/Documents/Github/Myfit}"
branch="$(git -C "$repo_root" branch --show-current)"
ssh_key="${MYFIT_MACMINI_SSH_KEY:-$HOME/.ssh/id_ed25519_macmini}"

if [[ -z "$branch" ]]; then
  printf '%s\n' 'A checked-out Git branch is required.' >&2
  exit 1
fi

if [[ ! -f "$ssh_key" ]]; then
  printf 'Mac mini SSH key not found: %s\n' "$ssh_key" >&2
  exit 1
fi

if [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
  printf '%s\n' 'Local changes detected. Commit or stash them before syncing to the Mac mini.' >&2
  exit 1
fi

git -C "$repo_root" push origin "$branch"
ssh -i "$ssh_key" -o IdentitiesOnly=yes "$macmini_host" \
  "git -C \"$remote_repo\" pull --ff-only origin \"$branch\""
