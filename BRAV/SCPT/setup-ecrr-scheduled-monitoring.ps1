[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$ListTasks,
    [string]$TaskUser = "SYSTEM"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workingDir = Split-Path -Parent $scriptDir

# Check if running as administrator
$principalContext = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principalContext.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚠️  This script requires administrator privileges to create scheduled tasks." -ForegroundColor Yellow
    Write-Host "   Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

if ($ListTasks) {
    Write-Host "📋 ECRR Scheduled Tasks:" -ForegroundColor Cyan
    Write-Host "=======================" -ForegroundColor Cyan
    
    $ecrrTasks = Get-ScheduledTask | Where-Object {$_.TaskName -like '*ECRR*' -or $_.TaskName -like '*Compliance*'}
    if ($ecrrTasks) {
        foreach ($task in $ecrrTasks) {
            $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName -ErrorAction SilentlyContinue
            Write-Host "📌 $($task.TaskName)" -ForegroundColor White
            Write-Host "   State: $($task.State)" -ForegroundColor Gray
            Write-Host "   Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
            Write-Host "   Last Run: $($taskInfo.LastRunTime)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "No ECRR scheduled tasks found." -ForegroundColor Yellow
    }
    return
}

Write-Host "🚀 Setting up ECRR Scheduled Monitoring" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Working Directory: $workingDir" -ForegroundColor Gray
Write-Host "Task User: $TaskUser" -ForegroundColor Gray
Write-Host ""

# Task 1: ECRR Compliance Monitor (every 6 hours)
Write-Host "📊 Creating ECRR Compliance Monitor task (every 6 hours)..." -ForegroundColor Yellow
$complianceAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptDir\continuous-ecrr-compliance-monitor.ps1`"" -WorkingDirectory $workingDir 
$complianceTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 6) -RepetitionDuration (New-TimeSpan -Days 365)
$complianceSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

try {
    Register-ScheduledTask -TaskName "ECRR Compliance Monitor" -Action $complianceAction -Trigger $complianceTrigger -Settings $complianceSettings -User $TaskUser -Description "ECRR compliance monitoring every 6 hours with report generation" -Force
    Write-Host "   ✅ Created: ECRR Compliance Monitor" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to create ECRR Compliance Monitor: $($_.Exception.Message)" -ForegroundColor Red
}

# Task 2: ECRR CI Integration (every 12 hours)
Write-Host "🔄 Creating ECRR CI Integration task (every 12 hours)..." -ForegroundColor Yellow
$ciAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptDir\ecrr-ci-integration.ps1`" -Threshold 95 -FailOnRegression" -WorkingDirectory $workingDir
$ciTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 12) -RepetitionDuration (New-TimeSpan -Days 365)
$ciSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

try {
    Register-ScheduledTask -TaskName "ECRR CI Integration" -Action $ciAction -Trigger $ciTrigger -Settings $ciSettings -User $TaskUser -Description "ECRR CI/CD integration check every 12 hours with regression detection" -Force
    Write-Host "   ✅ Created: ECRR CI Integration" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to create ECRR CI Integration: $($_.Exception.Message)" -ForegroundColor Red
}

# Task 3: ECRR Archive Management (daily at 2 AM)
Write-Host "📁 Creating ECRR Archive Management task (daily at 2 AM)..." -ForegroundColor Yellow
$archiveAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptDir\ecrr-archive-manager.ps1`"" -WorkingDirectory $workingDir
$archiveTrigger = New-ScheduledTaskTrigger -Daily -At 2:00AM
$archiveSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

try {
    Register-ScheduledTask -TaskName "ECRR Archive Management" -Action $archiveAction -Trigger $archiveTrigger -Settings $archiveSettings -User $TaskUser -Description "Daily ECRR archive management and cleanup" -Force
    Write-Host "   ✅ Created: ECRR Archive Management" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to create ECRR Archive Management: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 ECRR Task Summary:" -ForegroundColor Cyan
Write-Host "   ECRR Compliance Monitor: Every 6 hours" -ForegroundColor White
Write-Host "   ECRR CI Integration: Every 12 hours" -ForegroundColor White
Write-Host "   ECRR Archive Management: Daily at 2 AM" -ForegroundColor White

Write-Host ""
Write-Host "🔍 Management Commands:" -ForegroundColor Blue
Write-Host "   List tasks: pwsh -File scripts\setup-ecrr-scheduled-monitoring.ps1 -ListTasks" -ForegroundColor Gray
Write-Host "   Start task: Start-ScheduledTask -TaskName 'ECRR Compliance Monitor'" -ForegroundColor Gray
Write-Host "   Stop task:  Stop-ScheduledTask -TaskName 'ECRR Compliance Monitor'" -ForegroundColor Gray
Write-Host "   View logs:  Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=200,201}" -ForegroundColor Gray

Write-Host ""
Write-Host "✅ ECRR scheduled monitoring setup complete!" -ForegroundColor Green
