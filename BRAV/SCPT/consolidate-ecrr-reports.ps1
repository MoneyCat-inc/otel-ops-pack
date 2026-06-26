# Consolidate ECRR Reports - Merge duplicates into consolidated files (with dry-run)
param(
    [switch]$DryRun = $true,
    [string]$EcrrDir = "CHAR/ECRR/ECRR_REPORTS",
    [string]$ArchiveDir = "CHAR/ECRR/ECRR_REPORTS/archive",
    [string]$OutputDir = "CHAR/ECRR/ECRR_REPORTS"
)

$ErrorActionPreference = "Stop"

Write-Host "Consolidating ECRR reports (DryRun=$DryRun)" -ForegroundColor Cyan

if (-not (Test-Path $ArchiveDir)) { New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null }

# Consolidation groups (from artifacts/ecrr-consolidation-plan.json)
$groups = @(
    @{ name = "rollout-merge-consolidated"; files = @(
        "2025-01-27-rollout-merge-ecrr-complete.md",
        "2025-01-27-rollout-merge-ecrr-final-complete.md",
        "2025-01-27-rollout-merge-final-consolidated.md",
        "2025-01-27-rollout-merge-verification-complete.md",
        "2025-09-27-rollout-merge-ecrr-complete.md",
        "2025-09-27-rollout-merge-final-consolidated.md",
        "2025-09-28-rollout-merge-and-ecrr.md",
        "2025-09-28-rollout-merge-complete.md",
        "2025-09-29_18-04-04-rollout-merge.md"
    )},
    @{ name = "ecrr-01-consolidated"; files = @(
        "2025-01-21-ecrr-01-cross-origin-isolation-complete.md",
        "2025-09-22-ecrr-01-and-comfort-cat-merge.md",
        "2025-09-22-ECRR-01-FINAL-REPORT.md",
        "2025-09-22-ecrr-01-gate-validation.md",
        "2025-09-22-ecrr-01-merge-gate.md",
        "2025-09-22-ecrr-01-merge-signoff.md",
        "2025-09-22-terminal-session-ecrr-01.md"
    )},
    @{ name = "compliance-automation-consolidated"; files = @(
        "2025-01-27-compliance-automation-rollout-merge-ecrr.md",
        "2025-09-28-compliance-automation-rollout-merge-ecrr.md",
        "2025-09-28-fast-wins-rollout-merge-ecrr.md",
        "2025-09-28-windows-canary-pipeline-rollout-merge-ecrr.md"
    )},
    @{ name = "rollout-merge-oct-2025-consolidated"; files = @(
        "2025-09-27-rollout-merge-api-token-dashboard-ecrr.md",
        "2025-09-29-ecrr-orchestrator-rollout-merge.md",
        "2025-09-29-queue-steward-rollout-merge.md",
        "2025-10-02-ecrr-automated-monitoring-rollout-merge.md",
        "2025-10-02-ecrr-rollout-merge-final.md",
        "2025-10-02-ecrr-rollout-merge-plan.md",
        "2025-10-02-windows-collector-rollout-merge-ecrr.md"
    )}
)

foreach ($group in $groups) {
    $existing = @()
    foreach ($f in $group.files) {
        $p = Join-Path $EcrrDir $f
        if (Test-Path $p) { $existing += $p }
    }
    if ($existing.Count -eq 0) { continue }

    $outFile = Join-Path $OutputDir ("2025-09-29-" + $group.name + ".md")

    Write-Host "Preparing consolidated: $outFile" -ForegroundColor Yellow

    $header = @()
    $header += "# Consolidated ECRR Report — $($group.name)"
    $header += ""
    $header += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
    $header += "Actor: Cursor Agent - Observability Copilot (Consolidation)"
    $header += "Status: ✅ CONSOLIDATED"
    $header += "---"
    $header += ""
    $header += "## Source Reports (archived)"
    foreach ($p in $existing) { $header += "- $(Split-Path $p -Leaf)" }
    $header += ""
    $header += "## Combined Content"

    $combined = @()
    $combined += $header

    foreach ($p in $existing) {
        $combined += ""
        $combined += "---"
        $combined += '```start:end:' + (Split-Path $p -Leaf)
        $combined += '// truncated content reference'
        $combined += '```'
        $combined += ""
        $combined += (Get-Content $p -Raw -Encoding UTF8)
    }

    if ($DryRun) {
        Write-Host "DRY-RUN: Would write consolidated file: $outFile" -ForegroundColor DarkCyan
        foreach ($p in $existing) {
            $archName = Join-Path $ArchiveDir (Split-Path $p -Leaf)
            Write-Host "DRY-RUN: Would move $p -> $archName" -ForegroundColor DarkGray
        }
    } else {
        $combined | Set-Content -Path $outFile -Encoding UTF8
        foreach ($p in $existing) {
            $dest = Join-Path $ArchiveDir (Split-Path $p -Leaf)
            Move-Item -Path $p -Destination $dest -Force
        }
        Write-Host "Wrote consolidated file: $outFile" -ForegroundColor Green
    }
}

Write-Host "Consolidation pass complete." -ForegroundColor Green

