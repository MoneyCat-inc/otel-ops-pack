#Requires -Version 7.0
Param(
  [Parameter(Mandatory=$true)][string]$RunDir,
  # Default resolves from the repo root regardless of the caller's cwd. The file moved from
  # config/policy/ to DELT/CONF/policy/ in the tetragram reorg; the old default pointed at a
  # path that no longer exists (ECRR_DOCS_TRUTH_SWEEP_20260902 follow-up #3).
  [string]$Policy = (Join-Path (Split-Path $PSScriptRoot -Parent) 'DELT/CONF/policy/ecrr-policy.json')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $RunDir)) { Write-Error "RunDir not found: $RunDir"; exit 2 }
if (-not (Test-Path $Policy)) { Write-Error "Policy not found: $Policy"; exit 2 }

$labelsPath = Join-Path $RunDir 'labels.json'
if (-not (Test-Path $labelsPath)) { Write-Error "labels.json not found in $RunDir"; exit 2 }

# Parse into distinctly named variables: PowerShell variable names are case-insensitive, so the
# original `$policy = ... | ConvertFrom-Json` assigned back into the [string]-typed $Policy
# parameter, coerced the object to a string, and every run reported "[rerun] disabled".
$labelsDoc = Get-Content -Raw $labelsPath | ConvertFrom-Json
$policyDoc = Get-Content -Raw $Policy | ConvertFrom-Json

$enabled = [bool]$policyDoc.rerun.enabled
$allowed = @($policyDoc.rerun.dominant_classes_allow)
$dominant = $labelsDoc.dominant_class

if (-not $enabled) { Write-Host "[rerun] disabled"; exit 0 }

$allow = $allowed -contains $dominant
if ($allow) {
  Write-Host "[rerun] allowed for dominant_class=$dominant"
  exit 0
} else {
  Write-Host "[rerun] not allowed for dominant_class=$dominant"
  exit 0
}

