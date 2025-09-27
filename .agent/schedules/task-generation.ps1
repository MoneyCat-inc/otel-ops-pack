# Automated Task Generation
# Generated: 2025-09-27 03:23:30

Write-Log "Starting scheduled task generation"
try {
    # Generate tasks from ECRR reports
    pwsh -File scripts/cross-system-monitor.ps1 -Action generate
    Write-Log "Scheduled task generation completed successfully"
} catch {
    Write-Log "Scheduled task generation failed: $($_.Exception.Message)" "ERROR"
}
