<#
.SYNOPSIS
  Watchdog for otelcol-contrib: re-enables and starts the service if not Running.
  Designed to run as a scheduled task every 5 minutes under SYSTEM.
.OUTPUTS
  Appends one JSON line per invocation to artifacts\watchdog\watchdog.log.
  Rotates the log at $MaxLogBytes: watchdog.log -> .1 -> .2 -> .3, oldest dropped.
  Total footprint is bounded by (1 + $MaxArchives) * $MaxLogBytes.
#>

param(
  [string]$ServiceName = "otelcol-contrib",
  [string]$LogDir      = "C:\otel\artifacts\watchdog",
  [long]$MaxLogBytes   = 5MB,
  [int]$MaxArchives    = 3
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
$LogFile = Join-Path $LogDir "watchdog.log"

$logItem = Get-Item $LogFile -ErrorAction SilentlyContinue
if ($logItem -and $logItem.Length -ge $MaxLogBytes) {
  try {
    for ($i = $MaxArchives - 1; $i -ge 1; $i--) {
      if (Test-Path "$LogFile.$i") { Move-Item -Force "$LogFile.$i" "$LogFile.$($i + 1)" }
    }
    Move-Item -Force $LogFile "$LogFile.1"
    $note = @{ ts = (Get-Date -Format "o"); svc = $ServiceName; action = "rotated"; ok = $true; rotated_bytes = $logItem.Length }
  } catch {
    # Rotation failure must be visible in the log, but must not stop the service check.
    $note = @{ ts = (Get-Date -Format "o"); svc = $ServiceName; action = "rotate_failed"; ok = $false; err = $_.Exception.Message }
  }
  ($note | ConvertTo-Json -Compress) | Out-File -Append -Encoding UTF8 $LogFile
}

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $svc) {
  $entry = @{ ts = (Get-Date -Format "o"); svc = $ServiceName; action = "not_found"; ok = $false }
  ($entry | ConvertTo-Json -Compress) | Out-File -Append -Encoding UTF8 $LogFile
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
($entry | ConvertTo-Json -Compress) | Out-File -Append -Encoding UTF8 $LogFile

exit $(if ($ok) { 0 } else { 1 })
