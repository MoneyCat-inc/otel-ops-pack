# Queue Steward Scheduled Task Verification Script
# This script checks the status of the automated canary task

param(
    [string]$TaskName = "QueueStewardCanary"
)

Write-Host "Queue Steward Scheduled Task Verification" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if task exists
try {
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
    
    Write-Host "Task Name: $($Task.TaskName)" -ForegroundColor Green
    Write-Host "Task State: $($Task.State)" -ForegroundColor $(if ($Task.State -eq 'Ready') { 'Green' } else { 'Yellow' })
    Write-Host "Last Run Time: $($Task.LastRunTime)" -ForegroundColor White
    Write-Host "Last Result: $($Task.LastTaskResult)" -ForegroundColor White
    Write-Host ""
    
    # Get task info
    $TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($TaskInfo) {
        Write-Host "Next Run Time: $($TaskInfo.NextRunTime)" -ForegroundColor White
        Write-Host "Number of Missed Runs: $($TaskInfo.NumberOfMissedRuns)" -ForegroundColor $(if ($TaskInfo.NumberOfMissedRuns -eq 0) { 'Green' } else { 'Red' })
    }
    
    Write-Host ""
    Write-Host "Task Actions:" -ForegroundColor Yellow
    $Task.Actions | ForEach-Object {
        Write-Host "  Execute: $($_.Execute)" -ForegroundColor White
        Write-Host "  Arguments: $($_.Arguments)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Task Triggers:" -ForegroundColor Yellow
    $Task.Triggers | ForEach-Object {
        Write-Host "  Type: $($_.CimClass.CimClassName)" -ForegroundColor White
        if ($_.Repetition) {
            Write-Host "  Interval: $($_.Repetition.Interval)" -ForegroundColor White
            Write-Host "  Duration: $($_.Repetition.Duration)" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "Task '$TaskName' not found or not accessible." -ForegroundColor Red
    Write-Host "Make sure you've run the setup script as Administrator." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To create the task, run:" -ForegroundColor Cyan
    Write-Host "  pwsh -File scripts/setup-queue-steward-scheduled-task.ps1" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "Dashboard Status Check:" -ForegroundColor Yellow
try {
    $DashboardContent = Get-Content "docs/ECRR_QUALITY_DASHBOARD.md" -Raw
        if ($DashboardContent -match '\*\*Last Verified\*\*: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})') {
        $LastVerified = $Matches[1]
        $LastVerifiedDate = [DateTime]::ParseExact($LastVerified, "yyyy-MM-dd HH:mm:ss", $null)
        $TimeSince = (Get-Date) - $LastVerifiedDate
        
        Write-Host "Last Verified: $LastVerified" -ForegroundColor Green
        Write-Host "Time Since: $($TimeSince.ToString('hh\:mm\:ss'))" -ForegroundColor $(if ($TimeSince.TotalMinutes -lt 20) { 'Green' } else { 'Yellow' })
        
        if ($TimeSince.TotalMinutes -lt 20) {
            Write-Host "Dashboard timestamp is recent - automation appears to be working!" -ForegroundColor Green
        } else {
            Write-Host "Dashboard timestamp is older than 20 minutes - check task execution." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Could not find 'Last Verified' timestamp in dashboard." -ForegroundColor Red
    }
} catch {
    Write-Host "Could not read dashboard file." -ForegroundColor Red
}

Write-Host ""
Write-Host "Quick Commands:" -ForegroundColor Yellow
Write-Host "  Start Task:  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "  Stop Task:   Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "  Remove Task: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor White
