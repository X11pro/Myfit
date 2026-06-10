# Run from the root of this extracted folder: Myfit
# Requires Git installed and GitHub authentication configured.

$ErrorActionPreference = "Stop"

if (-not (Test-Path ".git")) {
  git init
}

git branch -M main

$remote = git remote 2>$null
if ($remote -contains "origin") {
  git remote set-url origin https://github.com/X11pro/Myfit.git
} else {
  git remote add origin https://github.com/X11pro/Myfit.git
}

git add .
git commit -m "Add initial fitness app product plan" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "No new changes to commit, continuing..."
}

git push -u origin main
