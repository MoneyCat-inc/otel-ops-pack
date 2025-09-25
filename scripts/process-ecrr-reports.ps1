# ECRR Reports Processing Script
# Processes all ECRR reports and organizes them into correct folders

param(
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Set up paths
$ecrrBase = "docs/ECRR_REPORTS"
$archiveDir = "$ecrrBase/archive"
$workingDir = "$ecrrBase/working"
$reviewedDir = "$ecrrBase/reviewed"

# Ensure directories exist
if (-not (Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null }
if (-not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir -Force | Out-Null }
if (-not (Test-Path $reviewedDir)) { New-Item -ItemType Directory -Path $reviewedDir -Force | Out-Null }

# Define organization rules based on content analysis
$organizationRules = @{
    # Completed/Resolved reports (based on content analysis)
    "archive" = @(
        "2025-01-21-ecrr-01-final-completion.md",
        "2025-01-21-ecrr-01-final-report.md", 
        "2025-01-21-ecrr-01-isolation-hardening.md",
        "2025-01-21-ecrr-01-verification-complete.md",
        "2025-01-21-ecrr-documentation-refresh.md",
        "2025-01-27-agent-role-documentation.md",
        "2025-01-27-codex-local-role-documentation.md",
        "2025-01-27-developer-hooks-hygiene-tooling.md",
        "2025-01-27-e2-dashboard-complete.md",
        "2025-01-27-e2-dashboard-implementation.md",
        "2025-01-27-e2-ratio-sweep-complete.md",
        "2025-01-27-e2-workflow-complete.md",
        "2025-01-27-eslint-configuration-optimization.md",
        "2025-01-27-stakeholder-map-validation.md",
        "2025-01-27-task-framework-deployment.md",
        "2024-12-19-ci-pipeline-hardening-parallel-validation.md",
        "2024-09-23-ai-pr-execution-plan.md",
        "2025-09-20-ecrr-canary-deployment-complete.md",
        "2025-09-20-ecrr-canary-deployment-ready.md",
        "2025-09-20-ecrr-canary-enhancement.md",
        "2025-09-20-ecrr-canary-scheduled-run.md",
        "2025-09-20-ecrr-implementation.md",
        "2025-09-20-ecrr-verification.md",
        "2025-09-20-readme-ecrr-integration.md",
        "2025-09-21-ci-validation.md",
        "2025-09-21-doe-harness-enhancement.md",
        "2025-09-21-doe-harness-implementation-complete.md",
        "2025-09-22-codex-local-docs-integration.md",
        "2025-09-22-comfort-cat-compliance.md",
        "2025-09-22-comfort-cat-folder-duplication.md",
        "2025-09-22-ecrr-01-and-comfort-cat-merge.md",
        "2025-09-22-ECRR-01-FINAL-REPORT.md",
        "2025-09-22-ecrr-01-gate-validation.md",
        "2025-09-22-ecrr-01-merge-gate.md",
        "2025-09-22-ecrr-01-merge-signoff.md",
        "2025-09-22-monitoring-automation.md",
        "2025-09-22-monitoring-enhancement.md",
        "2025-09-22-monitoring-infrastructure-setup.md",
        "2025-09-22-observability-copilot-health-check.md",
        "2025-09-22-observability-copilot-setup.md",
        "2025-09-22-optimized-pipeline-deployment.md",
        "2025-09-22-post-merge-validation.md",
        "2025-09-22-resonai-session-validation.md",
        "2025-09-22-signoz-alerts-complete-ecrr-report.md",
        "2025-09-22-signoz-alerts-execution-ready.md",
        "2025-09-22-signoz-alerts-final-verification.md",
        "2025-09-22-signoz-alerts-import-ready.md",
        "2025-09-22-signoz-alerts-verification-complete.md",
        "2025-09-22-signoz-ui-and-drilldown-assets.md",
        "2025-09-22-stakeholder-map-validation.md",
        "2025-09-22-terminal-commands-summary.md",
        "2025-09-22-terminal-session-ecrr-01.md",
        "2025-09-22-windows-collector-reset-and-canary.md"
    )
    
    # Active work reports (based on ledger.json)
    "working" = @(
        "2025-09-30-lint-toolchain-gap.md",
        "2025-09-23-202410-auto-ecrr-report.md",
        "2025-09-23-ecrr-lifecycle-system-implementation.md"
    )
    
    # Recent reports that need review (2025-09-23)
    "reviewed" = @(
        "2025-09-23-023645-signoz-logs-investigation.md",
        "2025-09-23-disk-cleanup-operation.md",
        "2025-09-23-disk-usage-critical.md",
        "2025-09-23-ecrr-lifecycle-system-implementation.md",
        "2025-09-23-ecrr-lifecycle-verification.md",
        "2025-09-23-ecrr-live-refresh.md",
        "2025-09-23-ecrr-observability-health-verification.md",
        "2025-09-23-gpu-sidecar-connectivity-analysis.md",
        "2025-09-23-health-endpoint-alignment.md",
        "2025-09-23-lint-typecheck-remediation-complete.md",
        "2025-09-23-lint-typecheck-zero-warnings.md",
        "2025-09-23-manual-cleanup-guide-review.md",
        "2025-09-23-manual-disk-cleanup-review.md",
        "2025-09-23-monolith-d-encoding-and-dma.md",
        "2025-09-23-otel-health-ci-patch-installer.md",
        "2025-09-23-otel-health-patches-wiring.md",
        "2025-09-23-phase-a-test-run.md",
        "2025-09-23-sanity-ci-billing-hold.md",
        "2025-09-23-signoz-live-refresh.md",
        "2025-09-23-signoz-log-sweep.md",
        "2025-09-23-signoz-monitoring-complete.md",
        "2025-09-23-split-path-fix.md",
        "2025-09-23-splitpath-remediation.md",
        "2025-09-23-wer-phoneexperience-monitoring-deployment.md",
        "2025-09-23-windows-collector-stability.md",
        "ECRR-20250923-001032-NIGHTLY-TRACKER-SYNC-IMPLEMENTATION.md",
        "ECRR-20250923-002045-SLEEP-KIT-IMPLEMENTATION.md"
    )
}

# Function to move files
function Move-Report {
    param(
        [string]$SourceFile,
        [string]$TargetDir,
        [string]$Category
    )
    
    $sourcePath = Join-Path $ecrrBase $SourceFile
    $targetPath = Join-Path $TargetDir $SourceFile
    
    if (Test-Path $sourcePath) {
        if ($DryRun) {
            Write-Host "DRY RUN: Would move $SourceFile to $Category/" -ForegroundColor Yellow
        } else {
            try {
                Move-Item -Path $sourcePath -Destination $targetPath -Force
                Write-Host "Moved $SourceFile to $Category/" -ForegroundColor Green
            } catch {
                Write-Host "Error moving $SourceFile`: $_" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "File not found: $SourceFile" -ForegroundColor Red
    }
}

# Process organization rules
Write-Host "Processing ECRR Reports Organization..." -ForegroundColor Cyan
Write-Host "Mode: $(if ($DryRun) { 'DRY RUN' } else { 'LIVE' })" -ForegroundColor $(if ($DryRun) { 'Yellow' } else { 'Green' })

foreach ($category in $organizationRules.Keys) {
    $targetDir = switch ($category) {
        "archive" { $archiveDir }
        "working" { $workingDir }
        "reviewed" { $reviewedDir }
    }
    
    Write-Host "`nProcessing $category reports..." -ForegroundColor Cyan
    
    foreach ($report in $organizationRules[$category]) {
        Move-Report -SourceFile $report -TargetDir $targetDir -Category $category
    }
}

# Generate summary
Write-Host "`nOrganization Summary:" -ForegroundColor Cyan
Write-Host "Archive: $($organizationRules['archive'].Count) reports" -ForegroundColor Green
Write-Host "Working: $($organizationRules['working'].Count) reports" -ForegroundColor Yellow  
Write-Host "Reviewed: $($organizationRules['reviewed'].Count) reports" -ForegroundColor Blue

if (-not $DryRun) {
    Write-Host "`nUpdating ledger and index..." -ForegroundColor Cyan
    try {
        # First, restore exclusions (guides/templates) that should not live under reports
        & pwsh -File scripts/ecrr-exclusions.ps1 -Action Restore
    } catch {
        Write-Host "Warning: Exclusions restore step failed: $_" -ForegroundColor Yellow
    }
    try {
        & pwsh -File scripts/ecrr-manage.ps1 -Action RegenerateAll
        Write-Host "Ledger and index updated successfully" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not update ledger automatically: $_" -ForegroundColor Yellow
    }
}

Write-Host "`nECRR Reports processing complete!" -ForegroundColor Green
