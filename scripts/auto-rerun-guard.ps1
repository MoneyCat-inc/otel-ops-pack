#Requires -Version 7.0
Param(
  [Parameter(Mandatory=$true)][string]$RunDir,
  [string]$Policy = 'config/policy/ecrr-policy.json'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $RunDir)) { Write-Error "RunDir not found: $RunDir"; exit 2 }
if (-not (Test-Path $Policy)) { Write-Error "Policy not found: $Policy"; exit 2 }

$labelsPath = Join-Path $RunDir 'labels.json'
if (-not (Test-Path $labelsPath)) { Write-Error "labels.json not found in $RunDir"; exit 2 }

$labels = Get-Content $labelsPath | ConvertFrom-Json
$policy = Get-Content $Policy | ConvertFrom-Json

$enabled = $policy.rerun.enabled
$allowed = $policy.rerun.dominant_classes_allow
$dominant = $labels.dominant_class

if (-not $enabled) { Write-Host "[rerun] disabled"; exit 0 }

$allow = $allowed -contains $dominant
if ($allow) {
  Write-Host "[rerun] allowed for dominant_class=$dominant"
  exit 0
} else {
  Write-Host "[rerun] not allowed for dominant_class=$dominant"
  exit 0
}

