param(
  [string]$ProjectRef = 'cyecalxewqcyxxglxloa'
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$appDir = Join-Path $repoRoot 'mobile\fitness_app'
$outputPath = Join-Path $appDir 'dart_defines.local.json'

if (!(Test-Path -LiteralPath $appDir)) {
  throw "No se encontro mobile/fitness_app en $appDir"
}

$supabaseUrl = $env:SUPABASE_URL
$supabaseAnonKey = $env:SUPABASE_ANON_KEY

if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
  $supabaseUrl = "https://$ProjectRef.supabase.co"
}

if ([string]::IsNullOrWhiteSpace($supabaseAnonKey)) {
  if ([string]::IsNullOrWhiteSpace($env:SUPABASE_ACCESS_TOKEN)) {
    throw 'Faltan SUPABASE_ANON_KEY y SUPABASE_ACCESS_TOKEN. Exporta uno de los dos antes de correr este script.'
  }

  $tempHome = Join-Path $env:TEMP 'myfit_supabase_cli'
  if (!(Test-Path -LiteralPath $tempHome)) {
    New-Item -ItemType Directory -Path $tempHome | Out-Null
  }

  $env:HOME = $tempHome
  $env:USERPROFILE = $tempHome

  $apiKeysOutput = & npx supabase projects api-keys --project-ref $ProjectRef 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    throw "No se pudieron leer las API keys del proyecto Supabase. Salida: $apiKeysOutput"
  }

  $anonMatch = [regex]::Match($apiKeysOutput, '(?m)^\s*anon\s*\|\s*(\S+)\s*$')
  if (!$anonMatch.Success) {
    throw 'No se pudo extraer la anon key desde la salida de supabase CLI.'
  }

  $supabaseAnonKey = $anonMatch.Groups[1].Value
}

$json = @{
  SUPABASE_URL = $supabaseUrl
  SUPABASE_ANON_KEY = $supabaseAnonKey
} | ConvertTo-Json

[System.IO.File]::WriteAllText($outputPath, $json + [Environment]::NewLine)

"Archivo local generado en: $outputPath"
"Usa .\scripts\flutter\build_android_debug.ps1 para compilar el APK debug funcional."
