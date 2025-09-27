# Automated Task Processing
# Generated: 2025-09-27 03:23:30

Write-Log "Starting scheduled task processing"
try {
    # Process high-priority tasks
    pwsh -File scripts/production-task-manager.ps1 -Action process -MaxConcurrentTasks 2
    Write-Log "Scheduled task processing completed successfully"
} catch {
    Write-Log "Scheduled task processing failed: $($_.Exception.Message)" "ERROR"
}
