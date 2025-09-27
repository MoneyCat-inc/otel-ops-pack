# Automated Health Check
# Generated: 2025-09-27 03:23:30

Write-Log "Starting scheduled health check"
try {
    # Check system health
    pwsh -File scripts/cross-system-alerts.ps1 -Action monitor
    pwsh -File scripts/production-task-manager.ps1 -Action health
    Write-Log "Scheduled health check completed successfully"
} catch {
    Write-Log "Scheduled health check failed: $($_.Exception.Message)" "ERROR"
}
