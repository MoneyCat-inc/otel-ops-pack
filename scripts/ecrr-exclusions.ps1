# ECRR exclusions guard — prevents guides/templates from living under docs/ECRR_REPORTS
# Usage examples:
#   pwsh -NoLogo -NoProfile -File scripts/ecrr-exclusions.ps1 -Action Validate
#   pwsh -NoLogo -NoProfile -File scripts/ecrr-exclusions.ps1 -Action Restore

param(
    [ValidateSet('Validate','Restore')]
    [string]$Action = 'Validate'
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$reportsRoot = Join-Path $repoRoot 'docs/ECRR_REPORTS'

# Files that should NOT be inside docs/ECRR_REPORTS
$exclusions = @(
    @{ name = 'ECRR_REVIEW_REQUEST_SUMMARY.md'; src = (Join-Path $reportsRoot 'reviewed/ECRR_REVIEW_REQUEST_SUMMARY.md'); dest = (Join-Path $repoRoot 'docs/ECRR_REVIEW_REQUEST_SUMMARY.md') },
    @{ name = 'ECRR_REPORT_TEMPLATE.md';       src = (Join-Path $reportsRoot 'reviewed/ECRR_REPORT_TEMPLATE.md');       dest = (Join-Path $repoRoot 'docs/ECRR_REPORT_TEMPLATE.md') },
    @{ name = 'ECRR.md';                       src = (Join-Path $reportsRoot 'reviewed/ECRR.md');                       dest = (Join-Path $repoRoot 'docs/ECRR.md') },
    @{ name = '.agent/ECRR_FILING_NOTE.md';    src = (Join-Path $reportsRoot 'reviewed/ECRR_FILING_NOTE.md');           dest = (Join-Path $repoRoot '.agent/ECRR_FILING_NOTE.md') }
)

function Ensure-Directory {
    param([string]$Path)
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}

switch ($Action) {
    'Validate' {
        $found = $false
        foreach ($item in $exclusions) {
            if (Test-Path $item.src) {
                Write-Host ("Found excluded file inside reports: {0}" -f $item.name) -ForegroundColor Yellow
                $found = $true
            }
        }
        if (-not $found) { Write-Host 'No excluded files found under docs/ECRR_REPORTS' -ForegroundColor Green }
    }
    'Restore' {
        foreach ($item in $exclusions) {
            if (Test-Path $item.src) {
                Ensure-Directory -Path $item.dest
                Move-Item -Force -Path $item.src -Destination $item.dest
                Write-Host ("Restored {0} -> {1}" -f $item.name, ($item.dest.Replace($repoRoot+'\\',''))) -ForegroundColor Green
            }
        }
        Write-Host 'Exclusion restore complete.' -ForegroundColor Cyan
    }
}


