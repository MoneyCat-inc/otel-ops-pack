# Repository Cleanup Script
# This script removes files outside the working set

Write-Host "Starting repository cleanup..." -ForegroundColor Green

# Files to delete (outside working set)
$filesToDelete = @(
    # Backup and archive files
    "config.bak.20250917_214615.yaml",
    "config.bak.20250917_215300.yaml", 
    "config.bak.20250917_215440.yaml",
    "config.bak.20250917202046.yaml",
    "ops-pack.sha256",
    "ops-pack.zip",
    "ops-package-manifest.txt",
    
    # Redundant scripts
    "acl-harden.ps1",
    "backup-config.ps1",
    "burn-in-test.ps1",
    "canary-check.ps1",
    "canary-with-slack.ps1",
    "ci-cd-smoke-test.ps1",
    "cleanup-lockin.ps1",
    "cleanup-operational-monitoring.ps1",
    "drift-guard.ps1",
    "final-verification.ps1",
    "fix-and-verify-service.ps1",
    "log-forwarder.ps1",
    "otel-lockin.ps1",
    "otel-lockin-fixed.ps1",
    "package-ops.ps1",
    "queue-watch.ps1",
    "quick-test.ps1",
    "restart-collectors.ps1",
    "run-lockin.ps1",
    "sanity-check.ps1",
    "service-assert.ps1",
    "simple-log-forwarder.ps1",
    "simple-test.ps1",
    "task-harden.ps1",
    "test-auto-heal.ps1",
    "test-canary.ps1",
    "test-pipeline.ps1",
    "verify-lockin.ps1",
    
    # Redundant configs
    "config",
    "config-debug-minimal.yaml",
    "config-hardened.yaml",
    "config-hardened-plus-debug.yaml",
    "simple-config.yaml",
    
    # Canary configs (keeping canary.yml for now)
    "canary-auto-heal.yml",
    "canary-enhanced.yml",
    "canary-multi-channel.yml",
    
    # Documentation overload
    "AGENT_PROMPT.md",
    "AGENT-SYSTEM-STATUS.md",
    "AUTO_HEAL_SETUP_COMPLETE.md",
    "CI_CD_INTEGRATION_GUIDE.md",
    "CONTINUOUS_CANARY_SETUP.md",
    "COPY_PASTE_READY.md",
    "DEPLOYMENT_GUIDE.md",
    "DONE_DONE_CHECKLIST.md",
    "FINAL_CI_CD_PACKAGE.md",
    "FINAL_CONSOLIDATED_PACKAGE.md",
    "FINAL_DELIVERABLES.md",
    "FINAL_DELIVERABLES_COMPLETE.md",
    "FINAL_OPS_CARD_SUMMARY.md",
    "FINAL_SETUP_SUMMARY.md",
    "FINAL_SUMMARY.md",
    "FINAL_WRAP_AND_PRO_TIPS.md",
    "MINI_PROD_CHECKLIST.md",
    "NEW_SERVICE_ONBOARDING_PLAYBOOK.md",
    "NEXT_STEPS.md",
    "OPERATIONAL_CHEAT_SHEET.md",
    "OPS_WALLET_CARD.md",
    "PRODUCTION_CHECKLIST.md",
    "PRODUCTION_READY_PACKAGE.md",
    "README-AGENT-SYSTEM.md",
    "SIGNOZ_WINDOWS_SETUP_REPORT.md",
    "SLACK_SETUP_GUIDE.md",
    "ULTIMATE_HANDOFF_COMPLETE.md",
    
    # Signoz files
    "signoz-alert-queries.md",
    "signoz-alerts.json",
    "signoz-alerts-final.json",
    "signoz-alerts-fixed-thresholds.json",
    "signoz-alerts-ready-to-import.json",
    "signoz-dashboard.json",
    
    # Other files
    "clickhouse-expose-guide.md",
    "github-actions-example.yml",
    "service-template.json",
    "qc",
    "query",
    "start",
    "stop"
)

# Setup scripts to delete
$setupScripts = @(
    "setup-operational-hardening.ps1",
    "setup-operational-hardening-fixed.ps1", 
    "setup-operational-monitoring.ps1",
    "setup-powershell-profile.ps1",
    "setup-profile-inline.ps1",
    "setup-signoz-jwt.ps1"
)

$allFilesToDelete = $filesToDelete + $setupScripts

Write-Host "Files to be deleted: $($allFilesToDelete.Count)" -ForegroundColor Yellow

# Dry run first
Write-Host "`nDRY RUN - Files that would be deleted:" -ForegroundColor Cyan
foreach ($file in $allFilesToDelete) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (not found)" -ForegroundColor Red
    }
}

# Ask for confirmation
$confirm = Read-Host "`nProceed with deletion? (y/N)"
if ($confirm -eq 'y' -or $confirm -eq 'Y') {
    Write-Host "`nDeleting files..." -ForegroundColor Green
    $deletedCount = 0
    foreach ($file in $allFilesToDelete) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force
                Write-Host "  Deleted: $file" -ForegroundColor Green
                $deletedCount++
            } catch {
                Write-Host "  Error deleting $file`: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    Write-Host "`nCleanup complete. Deleted $deletedCount files." -ForegroundColor Green
} else {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
}