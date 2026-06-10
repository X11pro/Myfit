#!/usr/bin/env bash
set -euo pipefail

# Run from the root of this extracted folder: Myfit
# Requires Git installed and GitHub authentication configured.

if [ ! -d ".git" ]; then
  git init
fi

git branch -M main

if git remote | grep -q '^origin$'; then
  git remote set-url origin https://github.com/X11pro/Myfit.git
else
  git remote add origin https://github.com/X11pro/Myfit.git
fi

git add .
if ! git commit -m "Add initial fitness app product plan"; then
  echo "No new changes to commit, continuing..."
fi

git push -u origin main
