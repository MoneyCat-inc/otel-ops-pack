# ECRR Compliance Task Management Script
# Quick commands for managing the compliance monitoring scheduled task

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [switch]$RunNow,
    [switch]$Logs
)

$TaskName = 'ECRR Compliance Monitoring'

if ($Start) {
    Write-Host "?? Starting ECRR Compliance Monitoring Task" -ForegroundColor Green
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "? Task started" -ForegroundColor Green
}
elseif ($Stop) {
    Write-Host "?? Stopping ECRR Compliance Monitoring Task" -ForegroundColor Yellow
    Stop-ScheduledTask -TaskName $TaskName
    Write-Host "? Task stopped" -ForegroundColor Green
}
elseif ($Status) {
    Write-Host "?? ECRR Compliance Monitoring Task Status" -ForegroundColor Cyan
    $task = Get-ScheduledTask -TaskName $TaskName
    $info = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host "   State: $($task.State)" -ForegroundColor White
    Write-Host "   Last Run: $($info.LastRunTime)" -ForegroundColor White
    Write-Host "   Next Run: $($info.NextRunTime)" -ForegroundColor White
    Write-Host "   Last Result: $($info.LastTaskResult)" -ForegroundColor White
}
elseif ($RunNow) {
    Write-Host "?? Running ECRR Compliance Monitoring Now" -ForegroundColor Green
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 5
    $info = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host "   Last Run: $($info.LastRunTime)" -ForegroundColor White
    Write-Host "   Result: $($info.LastTaskResult)" -ForegroundColor White
}
elseif ($Logs) {
    Write-Host "?? Recent Compliance Log Entries" -ForegroundColor Cyan
    $logFile = 'C:/logs/ecrr/compliance-trends.log'
    if (Test-Path $logFile) {
        Get-Content $logFile -Tail 5 | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
    } else {
        Write-Host "   Log file not found: $logFile" -ForegroundColor Yellow
    }
}
else {
    Write-Host "ECRR Compliance Task Management" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  -Start    : Start the scheduled task" -ForegroundColor White
    Write-Host "  -Stop     : Stop the scheduled task" -ForegroundColor White
    Write-Host "  -Status   : Show task status" -ForegroundColor White
    Write-Host "  -RunNow   : Run the task immediately" -ForegroundColor White
    Write-Host "  -Logs     : Show recent log entries" -ForegroundColor White
}
