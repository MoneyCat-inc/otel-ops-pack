<#
.SYNOPSIS
  Quick readiness check for Smol Slimes + nRF52840 dongles + SlimeVR Server.

.DESCRIPTION
  - Enumerates likely nRF52840 receiver dongles (best-effort heuristics).
  - Lists serial ports (if any).
  - Checks if SlimeVR Server UI port is listening (default 6969).
  - Prints READY/NOT READY summary and returns exit code 0/1.

.PARAMETER Root
  Root path for the otel workspace (default C:\otel).

.PARAMETER SlimeVrPort
  Port to check for SlimeVR Server (default 6969).

.PARAMETER Quiet
  Reduces chatter; still prints final READY/NOT READY line.
#>

[CmdletBinding()]
param(
  [string]$Root = 'C:\otel',
  [int]$SlimeVrPort = 6969,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

function Write-Info {
  param([string]$Message)
  if (-not $Quiet) {
    Write-Host $Message
  }
}

function Get-DongleCandidates {
  # Heuristics:
  # - Nordic official dongle often uses VID_1915
  # - Some show as "nRF52840", "nRF52", "Nordic"
  # - Some appear via Segger/J-Link ("J-Link", "JLink") depending on board/firmware
  # - Your EBYTE may include "EBYTE", "E104", "BT5040"
  $patterns = @(
    'nRF52840',
    'nRF52',
    'Nordic',
    'EBYTE',
    'E104',
    'BT5040',
    'J-Link',
    'JLink'
  )

  $vidPatterns = @(
    'VID_1915', # Nordic Semiconductor
    'VID_1366'  # SEGGER
  )

  $devices =
  Get-CimInstance Win32_PnPEntity |
  Where-Object {
    $name = $_.Name
    $hid = ($_.HardwareID -join ' ')

    ($patterns | ForEach-Object { $name -match $_ }) -contains $true -or
    ($vidPatterns | ForEach-Object { $hid -match $_ }) -contains $true
  } |
  Sort-Object Name

  return $devices
}

function Test-PortListening {
  param([int]$Port)

  $isListening = $false

  if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    $hit =
    Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1

    $isListening = ($null -ne $hit)
  }
  else {
    # Fallback for older PS environments
    $isListening =
    (netstat -an |
    Select-String -SimpleMatch ":$Port" |
    Select-String -SimpleMatch 'LISTEN') -ne $null
  }

  return $isListening
}

try {
  $dongleScript = Join-Path $Root 'scripts\slimevr-usb-dongles.ps1'

  Write-Info "== SlimeVR Sanity Check =="
  Write-Info ("Root: {0}" -f $Root)
  Write-Info ("Time: {0}" -f (Get-Date))
  Write-Info ""

  if (Test-Path $dongleScript) {
    Write-Info "== Running existing dongle enumerator =="
    Write-Info ("Script: {0}" -f $dongleScript)
    & $dongleScript
    Write-Info ""
  }
  else {
    Write-Info "== Note =="
    Write-Info "Did not find scripts\slimevr-usb-dongles.ps1 (this is optional)."
    Write-Info ""
  }

  Write-Info "== Dongle candidates (best-effort) =="
  $candidates = Get-DongleCandidates
  $candidateCount = @($candidates).Count

  if ($candidateCount -eq 0) {
    Write-Info "No obvious nRF52840/J-Link/EBYTE candidates found."
  }
  else {
    $candidates |
    Select-Object Name, PNPDeviceID |
    Format-Table -AutoSize
  }

  Write-Info ""
  Write-Info "== Serial ports (if any) =="
  $ports =
  Get-CimInstance Win32_SerialPort -ErrorAction SilentlyContinue |
  Sort-Object DeviceID

  if ($null -eq $ports -or @($ports).Count -eq 0) {
    Write-Info "No serial ports detected (this is often fine)."
  }
  else {
    $ports |
    Select-Object DeviceID, Name |
    Format-Table -AutoSize
  }

  Write-Info ""
  Write-Info ("== SlimeVR Server port check (localhost:{0}) ==" -f $SlimeVrPort)
  $listening = Test-PortListening -Port $SlimeVrPort

  if ($listening) {
    Write-Info "SlimeVR appears to be listening."
  }
  else {
    Write-Info "SlimeVR does NOT appear to be listening on that port."
  }

  Write-Info ""
  $ready = ($candidateCount -ge 1 -and $listening)

  if ($ready) {
    Write-Host ("READY ✅  (dongle candidates: {0}, SlimeVR port: {1} listening)" -f $candidateCount, $SlimeVrPort)
    exit 0
  }
  else {
    Write-Host ("NOT READY ❌  (dongle candidates: {0}, SlimeVR port: {1} listening: {2})" -f $candidateCount, $SlimeVrPort, $listening)

    Write-Info ""
    Write-Info "Next moves:"
    Write-Info "- If dongles missing: replug, try a different USB port, avoid unpowered hubs, try a short USB extension."
    Write-Info "- If SlimeVR not listening: start SlimeVR Server, then rerun this script."
    exit 1
  }
}
catch {
  Write-Host "ERROR ❌  Sanity check failed:"
  Write-Host $_
  exit 2
}
