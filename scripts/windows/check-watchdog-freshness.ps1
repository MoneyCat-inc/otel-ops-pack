<#
.SYNOPSIS
  Gate assertion: the otelcol watchdog heartbeat is alive and the host has disk headroom.
  Run by gate-nightly on the self-hosted runner; exits 1 (honest red) when the newest
  watchdog.log line is missing, unparseable, older than $MaxAgeMinutes, or reports
  C: free space below $MinCFreeGb.
.NOTES
  Both failure directions are reachable: kill the watchdog task and the age check trips;
  fill C: and the floor check trips. 15 min = 3 missed ticks; 50 GB gives weeks of
  warning at the 2026-08 VHDX incident's growth rate (that incident bottomed out at 3 GB).
#>

param(
  [string]$LogPath      = "C:\otel\artifacts\watchdog\watchdog.log",
  [int]$MaxAgeMinutes   = 15,
  [double]$MinCFreeGb   = 50
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LogPath)) {
  Write-Host "::error::watchdog log missing: $LogPath"
  exit 1
}

$last = Get-Content $LogPath -Tail 1
try {
  $entry = $last | ConvertFrom-Json
  $ts    = [datetimeoffset]::Parse($entry.ts, [cultureinfo]::InvariantCulture)
} catch {
  Write-Host "::error::newest watchdog line is not parseable JSON with a ts field: $last"
  exit 1
}

$ageMin = [math]::Round(([datetimeoffset]::Now - $ts).TotalMinutes, 1)
if ($ageMin -gt $MaxAgeMinutes) {
  Write-Host "::error::watchdog stale: newest line is $ageMin min old (limit $MaxAgeMinutes). Is task BossCat-OtelcolWatchdog alive?"
  exit 1
}

# c_free_gb is absent on burst_sample/rotated lines; only assert when present.
if ($null -ne $entry.c_free_gb -and $entry.c_free_gb -lt $MinCFreeGb) {
  Write-Host "::error::C: free space $($entry.c_free_gb) GB is below the $MinCFreeGb GB floor (VHDX-incident guard)"
  exit 1
}

Write-Host "watchdog fresh: newest line $ageMin min old (action=$($entry.action), c_free_gb=$($entry.c_free_gb), vhdx_gb=$($entry.vhdx_gb))"
exit 0
