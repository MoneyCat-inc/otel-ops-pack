#Requires -Version 7.0

<#
.SYNOPSIS
    Create a simple scheduled task for Windows Logs Canary generation
#>

param(
    [string]$TaskName = "WindowsLogsCanary",
    [int]$IntervalMinutes = 15,
    [int]$CanaryCount = 2
)

Write-Host "🕐 Creating Windows Logs Canary Scheduled Task" -ForegroundColor Cyan
Write-Host "Task Name: $TaskName" -ForegroundColor White
Write-Host "Interval: Every $IntervalMinutes minutes" -ForegroundColor White
Write-Host "Canary Count: $CanaryCount" -ForegroundColor White

$ScriptPath = Join-Path $PSScriptRoot "windows-logs-canary-test.ps1"
$FullScriptPath = Resolve-Path $ScriptPath -ErrorAction SilentlyContinue

if (-not $FullScriptPath) {
    Write-Host "❌ Script not found: $ScriptPath" -ForegroundColor Red
    exit 1
}

$ScriptPath = $FullScriptPath.Path
Write-Host "Script Path: $ScriptPath" -ForegroundColor White

try {
    # Remove existing task if it exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create the action
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$ScriptPath`" -Count $CanaryCount"

    # Create a daily trigger that repeats every X minutes
    $trigger = New-ScheduledTaskTrigger -Daily -At (Get-Date)
    $trigger.Repetition.Interval = "PT${IntervalMinutes}M"
    $trigger.Repetition.Duration = "P1D"

    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    # Create principal to run as SYSTEM
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Register the task
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Windows Logs Canary Generation" -Force

    Write-Host "✅ Task created successfully!" -ForegroundColor Green

    # Show task info
    $task = Get-ScheduledTask -TaskName $TaskName
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    
    Write-Host "📋 Task Details:" -ForegroundColor Cyan
    Write-Host "  State: $($task.State)" -ForegroundColor White
    Write-Host "  Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor White

    Write-Host "`n🔗 Management Commands:" -ForegroundColor Cyan
    Write-Host "  Start task: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  View task: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  Remove task: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor White

} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure you're running as Administrator" -ForegroundColor Yellow
    exit 1
}
