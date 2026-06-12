# Register a Windows Scheduled Task that syncs this repo every 20 minutes.
# Uses schtasks for compatibility with Windows PowerShell 5.1 environments.

$ErrorActionPreference = "Stop"

$syncScript = Join-Path $PSScriptRoot "sync_to_github.ps1"
$taskName = "Myfit Git Sync"

if (-not (Test-Path -LiteralPath $syncScript)) {
  throw "Sync script not found: $syncScript"
}

$taskCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$syncScript`""

schtasks /Create /TN $taskName /SC MINUTE /MO 20 /TR $taskCommand /F | Out-Null

"Scheduled task '$taskName' created."
