<#
.SYNOPSIS
  Watchdog for otelcol-contrib: re-enables and starts the service if not Running.
  Designed to run as a scheduled task every 5 minutes under SYSTEM.
.OUTPUTS
  Appends one JSON line per invocation to artifacts\watchdog\watchdog.log
#>

param(
  [string]$ServiceName = "otelcol-contrib",
  [string]$LogDir      = "C:\otel\artifacts\watchdog"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $svc) {
  $entry = @{ ts = (Get-Date -Format "o"); svc = $ServiceName; action = "not_found"; ok = $false }
  ($entry | ConvertTo-Json -Compress) | Out-File -Append -Encoding UTF8 (Join-Path $LogDir "watchdog.log")
  exit 1
}

$before = $svc.Status.ToString()
$action = "ok"
$ok     = $true

if ($svc.Status -ne "Running") {
  try {
    # Re-enable if disabled (the MSI-install / post-Update pattern)
    $startType = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName" -Name Start).Start
    if ($startType -eq 4) {  # 4 = Disabled
      sc.exe config $ServiceName start= delayed-auto | Out-Null
      $action = "reenabled_and_started"
    } else {
      $action = "started"
    }
    Start-Service -Name $ServiceName
    Start-Sleep -Seconds 3
    $svc = Get-Service -Name $ServiceName
    if ($svc.Status -ne "Running") { throw "Status after start: $($svc.Status)" }
  } catch {
    $action = "start_failed"
    $ok     = $false
  }
}

$entry = @{
  ts     = (Get-Date -Format "o")
  svc    = $ServiceName
  before = $before
  after  = $svc.Status.ToString()
  action = $action
  ok     = $ok
}
($entry | ConvertTo-Json -Compress) | Out-File -Append -Encoding UTF8 (Join-Path $LogDir "watchdog.log")

exit $(if ($ok) { 0 } else { 1 })
