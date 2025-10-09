# Queue Steward Automation Monitor
# This script helps monitor the automated canary system

param(
    [int]$MonitorMinutes = 20,
    [string]$TaskName = "QueueStewardCanary"
)

Write-Host "Queue Steward Automation Monitor" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan
Write-Host "Monitoring for $MonitorMinutes minutes..." -ForegroundColor Yellow
Write-Host ""

$StartTime = Get-Date
$EndTime = $StartTime.AddMinutes($MonitorMinutes)

while ((Get-Date) -lt $EndTime) {
    $CurrentTime = Get-Date -Format "HH:mm:ss"
    
    # Check task status
    try {
        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        $TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
        
        Write-Host "[$CurrentTime] Task Status: $($Task.State)" -ForegroundColor $(if ($Task.State -eq 'Ready') { 'Green' } else { 'Yellow' })
        
        if ($TaskInfo) {
            Write-Host "[$CurrentTime] Last Run: $($TaskInfo.LastRunTime)" -ForegroundColor White
            Write-Host "[$CurrentTime] Next Run: $($TaskInfo.NextRunTime)" -ForegroundColor White
            Write-Host "[$CurrentTime] Missed Runs: $($TaskInfo.NumberOfMissedRuns)" -ForegroundColor $(if ($TaskInfo.NumberOfMissedRuns -eq 0) { 'Green' } else { 'Red' })
        }
        
        # Check dashboard timestamp
        try {
            $DashboardContent = Get-Content "docs/ECRR_QUALITY_DASHBOARD.md" -Raw
            if ($DashboardContent -match '\*\*Last Verified\*\*: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
                $LastVerified = $Matches[1]
                $LastVerifiedDate = [DateTime]::ParseExact($LastVerified, "yyyy-MM-dd HH:mm:ss", $null)
                $TimeSince = (Get-Date) - $LastVerifiedDate
                
                Write-Host "[$CurrentTime] Dashboard: $LastVerified (${TimeSince:mm} min ago)" -ForegroundColor $(if ($TimeSince.TotalMinutes -lt 20) { 'Green' } else { 'Yellow' })
            }
        } catch {
            Write-Host "[$CurrentTime] Dashboard: Could not read timestamp" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "[$CurrentTime] Task: Not found or not accessible" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Wait 2 minutes before next check
    Start-Sleep -Seconds 120
}

Write-Host "Monitoring complete!" -ForegroundColor Green
Write-Host "Run 'pwsh -File scripts/verify-queue-steward-task.ps1' for detailed status." -ForegroundColor Cyan
