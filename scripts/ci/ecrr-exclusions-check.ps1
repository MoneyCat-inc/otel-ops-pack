# CI pre-commit check: ensure excluded docs are not under docs/ECRR_REPORTS/
# Exits with non-zero code if any excluded filenames are found in the reports tree.

$ErrorActionPreference = 'Stop'

# Validate and auto-restore (no-op if clean)
try {
  $exclPath = Join-Path (Join-Path $PSScriptRoot '..') 'ecrr-exclusions.ps1'
  & pwsh -NoLogo -NoProfile -File $exclPath -Action Validate
} catch {}

$repoRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).Path
$reportsRoot = Join-Path $repoRoot 'docs/ECRR_REPORTS'
$excludedNames = @('ECRR_REVIEW_REQUEST_SUMMARY.md','ECRR_REPORT_TEMPLATE.md','ECRR.md')
$found = @()
if (Test-Path $reportsRoot) {
  $found = Get-ChildItem -Recurse -Path $reportsRoot -Filter *.md -File |
    Where-Object { $excludedNames -contains $_.Name }
}
if ($found -and $found.Count -gt 0) {
  Write-Error 'Exclusion breach: guides/templates detected under docs/ECRR_REPORTS'
  foreach ($f in $found) { Write-Host (' - ' + $f.FullName) -ForegroundColor Yellow }
  exit 1
}
Write-Host 'ECRR exclusions check passed' -ForegroundColor Green
