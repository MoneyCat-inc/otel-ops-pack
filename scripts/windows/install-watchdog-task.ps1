<#
.SYNOPSIS
  Registers (or replaces) the otelcol-contrib watchdog as a scheduled task.
  Idempotent — safe to re-run. Requires elevation.
.EXAMPLE
  pwsh -File scripts\windows\install-watchdog-task.ps1
#>

param(
  [string]$TaskName    = "BossCat-OtelcolWatchdog",
  [string]$ScriptPath  = "C:\otel\scripts\windows\watchdog-otelcol.ps1",
  [int]$IntervalMin    = 5
)

$ErrorActionPreference = "Stop"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Error "Elevation required. Re-run from an elevated prompt."
  exit 1
}

$action  = New-ScheduledTaskAction `
  -Execute "pwsh.exe" `
  -Argument "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$ScriptPath`""

$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes $IntervalMin) -Once `
  -At (Get-Date).Date  # anchor; repetition makes it recur indefinitely

$settings = New-ScheduledTaskSettingsSet `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
  -StartWhenAvailable `
  -RunOnlyIfNetworkAvailable:$false `
  -MultipleInstances IgnoreNew

# Unregister stale copy if present
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
  Write-Host "[watchdog] Removed existing task '$TaskName'" -ForegroundColor Gray
}

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action   $action `
  -Trigger  $trigger `
  -Settings $settings `
  -RunLevel Highest `
  -User     "SYSTEM" | Out-Null

Write-Host "[watchdog] Task registered: $TaskName" -ForegroundColor Green
Write-Host "  Script : $ScriptPath" -ForegroundColor Gray
Write-Host "  Runs   : every $IntervalMin min, SYSTEM, elevated" -ForegroundColor Gray
Write-Host "  Log    : C:\otel\artifacts\watchdog\watchdog.log" -ForegroundColor Gray
Write-Host ""
Write-Host "Run now to verify:" -ForegroundColor White
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Get-Content C:\otel\artifacts\watchdog\watchdog.log -Tail 5" -ForegroundColor Gray
