#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ ! -d "$repo_root/.git" ]]; then
  echo "Git repository not found at $repo_root" >&2
  exit 1
fi

if [[ -z "$(git -C "$repo_root" status --porcelain)" ]]; then
  echo "No changes to sync."
  exit 0
fi

git -C "$repo_root" add .
git -C "$repo_root" commit -m "Auto-sync project changes"
git -C "$repo_root" push origin main
