# Sync local changes to GitHub.
# Requires Git credentials already configured on this machine.

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $repoRoot

if (-not (Test-Path -LiteralPath (Join-Path $repoRoot ".git"))) {
  throw "Git repository not found at $repoRoot"
}

$status = git -C $repoRoot status --porcelain
if (-not $status) {
  "No changes to sync."
  exit 0
}

git -C $repoRoot add .
git -C $repoRoot commit -m "Auto-sync project changes"
git -C $repoRoot push origin main
