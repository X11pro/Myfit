$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$appDir = Join-Path $repoRoot 'mobile\fitness_app'
$definesPath = Join-Path $appDir 'dart_defines.local.json'

if (!(Test-Path -LiteralPath $appDir)) {
  throw "No se encontro mobile/fitness_app en $appDir"
}

if (!(Test-Path -LiteralPath $definesPath)) {
  throw 'Falta mobile/fitness_app/dart_defines.local.json. Corre primero .\scripts\flutter\save_local_dart_defines.ps1'
}

Push-Location $appDir
try {
  & flutter run -d edge --dart-define-from-file=$definesPath
  if ($LASTEXITCODE -ne 0) {
    throw 'Fallo flutter run -d edge.'
  }
} finally {
  Pop-Location
}
