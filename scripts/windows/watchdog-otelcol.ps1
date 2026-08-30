<#
.SYNOPSIS
  Watchdog for otelcol-contrib: re-enables and starts the service if not Running.
  Designed to run as a scheduled task every 5 minutes under SYSTEM.
.OUTPUTS
  Appends one JSON line per invocation to artifacts\watchdog\watchdog.log.
  Rotates the log at $MaxLogBytes: watchdog.log -> .1 -> .2 -> .3, oldest dropped.
  Total footprint is bounded by (1 + $MaxArchives) * $MaxLogBytes.

  When the service is not Running, the run escalates to burst resolution: after
  the start attempt it samples service state every $BurstSampleSec seconds for up
  to $BurstSeconds (one JSON line per sample), and writes an incident bundle
  (start error, start type, recent Service Control Manager events) to
  artifacts\watchdog\incidents\, capped at $MaxIncidentFiles files. Worst-case
  runtime (~100s) stays inside the task's 2-minute execution limit; the healthy
  path is unchanged - one line, immediate exit.
#>

param(
  [string]$ServiceName   = "otelcol-contrib",
  [string]$LogDir        = "C:\otel\artifacts\watchdog",
  [long]$MaxLogBytes     = 5MB,
  [int]$MaxArchives      = 3,
  [int]$BurstSeconds     = 90,
  [int]$BurstSampleSec   = 10,
  [int]$MaxIncidentFiles = 20
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
$LogFile = Join-Path $LogDir "watchdog.log"

function Write-WdLine([hashtable]$Fields) {
  $Fields.ts  = (Get-Date -Format "o")
  $Fields.svc = $ServiceName
  ($Fields | ConvertTo-Json -Compress) | Out-File -Append -Encoding UTF8 $LogFile
}

$logItem = Get-Item $LogFile -ErrorAction SilentlyContinue
if ($logItem -and $logItem.Length -ge $MaxLogBytes) {
  try {
    for ($i = $MaxArchives - 1; $i -ge 1; $i--) {
      if (Test-Path "$LogFile.$i") { Move-Item -Force "$LogFile.$i" "$LogFile.$($i + 1)" }
    }
    Move-Item -Force $LogFile "$LogFile.1"
    Write-WdLine @{ action = "rotated"; ok = $true; rotated_bytes = $logItem.Length }
  } catch {
    # Rotation failure must be visible in the log, but must not stop the service check.
    Write-WdLine @{ action = "rotate_failed"; ok = $false; err = $_.Exception.Message }
  }
}

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $svc) {
  Write-WdLine @{ action = "not_found"; ok = $false }
  exit 1
}

$before = $svc.Status.ToString()

if ($svc.Status -eq "Running") {
  Write-WdLine @{ before = $before; after = "Running"; action = "ok"; ok = $true }
  exit 0
}

# --- Not Running: remediate, then observe at burst resolution ---
$runStart  = Get-Date
$action    = "started"
$startErr  = $null
$startType = $null
try {
  # Re-enable if disabled (the MSI-install / post-Update pattern)
  $startType = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName" -Name Start).Start
  if ($startType -eq 4) {  # 4 = Disabled
    sc.exe config $ServiceName start= delayed-auto | Out-Null
    $action = "reenabled_and_started"
  }
  Start-Service -Name $ServiceName
} catch {
  $startErr = $_.Exception.Message
}

$deadline = $runStart.AddSeconds($BurstSeconds)
$samples  = 0
do {
  Start-Sleep -Seconds $BurstSampleSec
  $svc.Refresh()
  $samples++
  Write-WdLine @{ action = "burst_sample"; state = $svc.Status.ToString(); elapsed_s = [int]((Get-Date) - $runStart).TotalSeconds; ok = $true }
} while ($svc.Status -ne "Running" -and (Get-Date) -lt $deadline)

$ok = ($svc.Status -eq "Running")
if (-not $ok) { $action = "start_failed" }

# Incident bundle: the "why" that single log lines cannot carry.
try {
  $incDir = Join-Path $LogDir "incidents"
  if (-not (Test-Path $incDir)) { New-Item -ItemType Directory -Force -Path $incDir | Out-Null }
  $scm = Get-WinEvent -FilterHashtable @{ LogName = 'System'; ProviderName = 'Service Control Manager'; StartTime = (Get-Date).AddMinutes(-30) } -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -match [regex]::Escape($ServiceName) } |
    Select-Object -First 40 TimeCreated, Id, LevelDisplayName, Message
  $bundle = @{
    ts         = (Get-Date -Format "o")
    svc        = $ServiceName
    before     = $before
    after      = $svc.Status.ToString()
    action     = $action
    start_err  = $startErr
    start_type = $startType
    scm_events = @($scm)
  }
  $incFile = Join-Path $incDir ("incident-{0}.json" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
  $bundle | ConvertTo-Json -Depth 4 | Out-File -Encoding UTF8 $incFile
  Get-ChildItem $incDir -Filter "incident-*.json" | Sort-Object Name -Descending | Select-Object -Skip $MaxIncidentFiles | Remove-Item -Force
  Write-WdLine @{ action = "incident_bundle"; file = $incFile; ok = $true }
} catch {
  Write-WdLine @{ action = "bundle_failed"; ok = $false; err = $_.Exception.Message }
}

$final = @{ before = $before; after = $svc.Status.ToString(); action = $action; ok = $ok; burst_samples = $samples; elapsed_s = [int]((Get-Date) - $runStart).TotalSeconds }
if ($startErr) { $final.err = $startErr }
Write-WdLine $final

exit $(if ($ok) { 0 } else { 1 })
