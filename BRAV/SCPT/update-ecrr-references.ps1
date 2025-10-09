# Update references to archived ECRR reports to consolidated files (supports dry-run)
param(
    [switch]$DryRun = $true,
    [string]$RootDir = ".",
    [string[]]$ExcludePatterns = @("*\\docs\\ECRR_REPORTS\\archive\\*", "*\\node_modules\\*", "*\\.git\\*", "*\\third_party\\*")
)

$ErrorActionPreference = "Stop"

Write-Host "Updating ECRR references (DryRun=$DryRun)" -ForegroundColor Cyan

# Map archived filenames → consolidated targets
$map = @{}

# Rollout merge group → rollout-merge-consolidated
@(
    "2025-01-27-rollout-merge-complete.md",
    "2025-01-27-rollout-merge-ecrr-complete.md",
    "2025-01-27-rollout-merge-ecrr-final-complete.md",
    "2025-01-27-rollout-merge-final-consolidated.md",
    "2025-01-27-rollout-merge-verification-complete.md",
    "2025-09-27-rollout-merge-ecrr-complete.md",
    "2025-09-27-rollout-merge-final-consolidated.md",
    "2025-09-28-rollout-merge-and-ecrr.md",
    "2025-09-28-rollout-merge-complete.md",
    "2025-09-29_18-04-04-rollout-merge.md"
) | ForEach-Object { $map[$_] = "2025-09-29-rollout-merge-consolidated.md" }

# ECRR-01 group → ecrr-01-consolidated
@(
    "2025-01-21-ecrr-01-cross-origin-isolation-complete.md",
    "2025-09-22-ecrr-01-and-comfort-cat-merge.md",
    "2025-09-22-ECRR-01-FINAL-REPORT.md",
    "2025-09-22-ecrr-01-gate-validation.md",
    "2025-09-22-ecrr-01-merge-gate.md",
    "2025-09-22-ecrr-01-merge-signoff.md",
    "2025-09-22-terminal-session-ecrr-01.md",
    "2025-01-21-ecrr-01-final-completion.md",
    "2025-01-21-ecrr-01-final-report.md",
    "2025-01-21-ecrr-01-isolation-hardening.md",
    "2025-01-21-ecrr-01-verification-complete.md"
) | ForEach-Object { $map[$_] = "2025-09-29-ecrr-01-consolidated.md" }

# Compliance automation group → compliance-automation-consolidated
@(
    "2025-01-27-compliance-automation-rollout-merge-ecrr.md",
    "2025-09-28-compliance-automation-rollout-merge-ecrr.md",
    "2025-09-28-fast-wins-rollout-merge-ecrr.md",
    "2025-09-28-windows-canary-pipeline-rollout-merge-ecrr.md"
) | ForEach-Object { $map[$_] = "2025-09-29-compliance-automation-consolidated.md" }

# Only process markdown files outside excluded paths
$mdFiles = Get-ChildItem -Path $RootDir -Filter "*.md" -Recurse |
    Where-Object { $p = $_.FullName; -not ($ExcludePatterns | Where-Object { $p -like $_ }) }

$totalChanges = 0
$filesChanged = 0

foreach ($file in $mdFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $original = $content
    $changesForFile = 0

    foreach ($key in $map.Keys) {
        if ($content -match [regex]::Escape($key)) {
            $content = $content -replace [regex]::Escape($key), $map[$key]
            $changesForFile++
        }
    }

    if ($changesForFile -gt 0) {
        $filesChanged++
        $totalChanges += $changesForFile
        if ($DryRun) {
            Write-Host "DRY-RUN: Would update $changesForFile reference(s) in $($file.FullName)" -ForegroundColor DarkCyan
        } else {
            $content | Set-Content -Path $file.FullName -Encoding UTF8
            Write-Host "Updated $changesForFile reference(s) in $($file.FullName)" -ForegroundColor Green
        }
    }
}

Write-Host "\nCompleted. Files changed: $filesChanged, Total reference updates: $totalChanges" -ForegroundColor Cyan
