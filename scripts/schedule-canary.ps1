# schedule-canary.ps1 - Schedule automated health checks every 15 minutes
# Usage: .\scripts\schedule-canary.ps1

Write-Host "📅 Scheduling Automated Health Checks" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "❌ This script requires administrator privileges" -ForegroundColor Red
    Write-Host "   Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

# Define the scheduled task
$taskName = "OTelPipelineHealthCheck"
$scriptPath = Join-Path $PSScriptRoot "..\health.ps1"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
$trigger.Repetition.Interval = "PT15M"  # Every 15 minutes
$trigger.Repetition.Duration = "P365D"  # For 365 days
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "🔄 Removing existing scheduled task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create the new scheduled task
Write-Host "📝 Creating scheduled task: $taskName" -ForegroundColor Yellow
Write-Host "   Script: $scriptPath" -ForegroundColor Gray
Write-Host "   Interval: Every 15 minutes" -ForegroundColor Gray
Write-Host "   Duration: 1 year" -ForegroundColor Gray

try {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automated OpenTelemetry pipeline health checks every 15 minutes"
    Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify the task was created
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "`n📊 Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor White
    Write-Host "  State: $($task.State)" -ForegroundColor White
    Write-Host "  Next Run: $((Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo).NextRunTime)" -ForegroundColor White
} else {
    Write-Host "❌ Task verification failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "  • Health checks will run automatically every 15 minutes" -ForegroundColor White
Write-Host "  • Check Task Scheduler for 'OTelPipelineHealthCheck' to manage" -ForegroundColor White
Write-Host "  • Run '.\health.ps1' manually anytime for immediate status" -ForegroundColor White
Write-Host "  • View logs in SigNoz UI: http://localhost:8080" -ForegroundColor White

Write-Host "`n🔧 Management Commands:" -ForegroundColor Cyan
Write-Host "  View task: Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "  Run now: Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false" -ForegroundColor Gray
