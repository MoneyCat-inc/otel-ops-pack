Param(
  [string]$SnapshotsDir = 'docs/observability/snapshots',
  [string]$Output = 'artifacts/queue-steward-verification.txt',
  [switch]$Strict
)

$ErrorActionPreference = 'Stop'

function Ensure-Dir([string]$Path){
  $dir = Split-Path -Parent $Path
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
}

if (-not (Test-Path -LiteralPath $SnapshotsDir)) {
  throw "Snapshots directory not found: $SnapshotsDir"
}

$candidates = Get-ChildItem -LiteralPath $SnapshotsDir -File -Filter 'gate-*.json' -ErrorAction SilentlyContinue
if (-not $candidates) {
  # Also check nested subfolders e.g., site-observations
  $candidates = Get-ChildItem -Recurse -LiteralPath $SnapshotsDir -File -Filter 'gate-*.json' -ErrorAction SilentlyContinue
}

if (-not $candidates) {
  if ($Strict) { throw "No gate-* JSON snapshots found in $SnapshotsDir" } else { Write-Warning "No gate-* JSON snapshots found"; $candidates = @() }
}

$latest = $null
if ($candidates -and $candidates.Count -gt 0) {
  $latest = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

$ok = $false
$summaryLines = @()
$ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'

if ($latest) {
  $json = Get-Content -Raw -LiteralPath $latest.FullName | ConvertFrom-Json
  $checks = @()
  if ($json.PSObject.Properties.Name -contains 'checks' -and $json.checks) { $checks = $json.checks }
  $allOk = $true
  if ($checks.Count -gt 0) {
    foreach ($c in $checks) {
      $name = $c.name
      $isOk = $false
      if ($c.PSObject.Properties.Name -contains 'ok') { $isOk = [bool]$c.ok }
      if (-not $isOk) { $allOk = $false }
      $detail = ''
      if ($c.details) {
        if ($c.details.PSObject.Properties.Name -contains 'status') { $detail = "status: $($c.details.status)" }
        elseif ($c.details.PSObject.Properties.Name -contains 'exitCode') { $detail = "exitCode: $($c.details.exitCode)" }
      }
      $summaryLines += ("- {0}: {1} {2}" -f $name, ($(if($isOk){'OK'} else {'FAIL'})), $detail).Trim()
    }
    $ok = $allOk
  } elseif ($json.PSObject.Properties.Name -contains 'health') {
    $isOk = $false
    if ($json.health.PSObject.Properties.Name -contains 'ok') { $isOk = [bool]$json.health.ok }
    $statusStr = ''
    if ($json.health.PSObject.Properties.Name -contains 'status') { $statusStr = "status: $($json.health.status)" }
    $summaryLines += ("- health: {0} {1}" -f ($(if($isOk){'OK'} else {'FAIL'})), $statusStr).Trim()
    $ok = $isOk
  }
}

Ensure-Dir -Path $Output
$src = '(none)'
if ($latest) { $src = $latest.FullName }
$lines = @(
  'Queue Steward Verification',
  "Timestamp: $ts",
  "Source: $src",
  '',
  'Checks:'
)
$lines += $summaryLines

$content = $lines -join "`r`n"
$content | Set-Content -Path $Output -Encoding utf8

if ($Strict) { if (-not $ok) { exit 2 } }
exit 0
