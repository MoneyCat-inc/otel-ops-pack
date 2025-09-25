# See C:\otel\docs\comfort cat
# Scheduled Monitoring Setup - Administrator Version
# Run this script as Administrator to create Windows scheduled tasks

param(
    [switch]$RemoveTasks = $false,
    [switch]$ListTasks = $false
)

Write-Host "⏰ Scheduled Monitoring Setup (Administrator)" -ForegroundColor Cyan
Write-Host "Configure continuous monitoring with Windows scheduled tasks" -ForegroundColor Gray
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "   Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Alternative: Use the non-admin version for reference only:" -ForegroundColor Blue
    Write-Host "   pwsh -File scripts\setup-scheduled-monitoring.ps1 -ListTasks" -ForegroundColor Gray
    exit 1
}

Write-Host "✅ Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# List existing tasks
if ($ListTasks) {
    Write-Host "📋 Existing OTel Monitoring Tasks:" -ForegroundColor Cyan
    $existingTasks = Get-ScheduledTask -TaskName "*OTel*" -ErrorAction SilentlyContinue
    if ($existingTasks) {
        foreach ($task in $existingTasks) {
            Write-Host "   - $($task.TaskName): $($task.State)" -ForegroundColor White
        }
    } else {
        Write-Host "   No existing OTel tasks found" -ForegroundColor Gray
    }
    Write-Host ""
}

# Remove existing tasks
if ($RemoveTasks) {
    Write-Host "🗑️  Removing existing OTel monitoring tasks..." -ForegroundColor Yellow
    $existingTasks = Get-ScheduledTask -TaskName "*OTel*" -ErrorAction SilentlyContinue
    foreach ($task in $existingTasks) {
        try {
            Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
            Write-Host "   ✅ Removed: $($task.TaskName)" -ForegroundColor Green
        } catch {
            Write-Host "   ❌ Failed to remove: $($task.TaskName) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

if ($RemoveTasks) {
    Write-Host "✅ Task removal complete" -ForegroundColor Green
    exit 0
}

# Create scheduled tasks
Write-Host "🔧 Creating scheduled monitoring tasks..." -ForegroundColor Cyan

# Get current script directory
$scriptDir = Split-Path -Path -Parent $MyInvocation.MyCommand.Path
$workingDir = Split-Path -Path -Parent $scriptDir

# Task 1: Quick Health Check (every 5 minutes)
Write-Host "📊 Creating Quick Health Check task (every 5 minutes)..." -ForegroundColor Yellow
$quickMonitorAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptDir\quick-monitor.ps1`"" -WorkingDirectory $workingDir
$quickMonitorTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 365)
$quickMonitorSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 2)

try {
    Register-ScheduledTask -TaskName "OTel-QuickHealthCheck" -Action $quickMonitorAction -Trigger $quickMonitorTrigger -Settings $quickMonitorSettings -User "SYSTEM" -Description "Quick OTel pipeline health check every 5 minutes" -Force
    Write-Host "   ✅ Created: OTel-QuickHealthCheck" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to create OTel-QuickHealthCheck: $($_.Exception.Message)" -ForegroundColor Red
}

# Task 2: Canary Test (every 15 minutes)
Write-Host "🧪 Creating Canary Test task (every 15 minutes)..." -ForegroundColor Yellow
$canaryAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptDir\canary-ecrr.ps1`"" -WorkingDirectory $workingDir
$canaryTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration (New-TimeSpan -Days 365)
$canarySettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

try {
    Register-ScheduledTask -TaskName "OTel-CanaryTest" -Action $canaryAction -Trigger $canaryTrigger -Settings $canarySettings -User "SYSTEM" -Description "ECRR canary test every 15 minutes" -Force
    Write-Host "   ✅ Created: OTel-CanaryTest" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to create OTel-CanaryTest: $($_.Exception.Message)" -ForegroundColor Red
}

# Task 3: Detailed Monitor (every hour for 10 minutes)
Write-Host "📈 Creating Detailed Monitor task (every hour for 10 minutes)..." -ForegroundColor Yellow
$detailedMonitorAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptDir\monitor-optimized-pipeline.ps1`" -DurationMinutes 10 -ExportReport" -WorkingDirectory $workingDir
$detailedMonitorTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 365)
$detailedMonitorSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 15)

try {
    Register-ScheduledTask -TaskName "OTel-DetailedMonitor" -Action $detailedMonitorAction -Trigger $detailedMonitorTrigger -Settings $detailedMonitorSettings -User "SYSTEM" -Description "Detailed OTel pipeline monitoring every hour for 10 minutes with report export" -Force
    Write-Host "   ✅ Created: OTel-DetailedMonitor" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to create OTel-DetailedMonitor: $($_.Exception.Message)" -ForegroundColor Red
}

# Task 4: Weekly Report (every Sunday at 9 AM)
Write-Host "📊 Creating Weekly Report task (every Sunday at 9 AM)..." -ForegroundColor Yellow
$weeklyReportAction = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$scriptDir\generate-weekly-report.ps1`"" -WorkingDirectory $workingDir
$weeklyReportTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 9:00AM
$weeklyReportSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

try {
    Register-ScheduledTask -TaskName "OTel-WeeklyReport" -Action $weeklyReportAction -Trigger $weeklyReportTrigger -Settings $weeklyReportSettings -User "SYSTEM" -Description "Weekly OTel pipeline report generation" -Force
    Write-Host "   ✅ Created: OTel-WeeklyReport" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Failed to create OTel-WeeklyReport: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Task Summary:" -ForegroundColor Cyan
Write-Host "   OTel-QuickHealthCheck: Every 5 minutes" -ForegroundColor White
Write-Host "   OTel-CanaryTest: Every 15 minutes" -ForegroundColor White
Write-Host "   OTel-DetailedMonitor: Every hour for 10 minutes" -ForegroundColor White
Write-Host "   OTel-WeeklyReport: Every Sunday at 9 AM" -ForegroundColor White

Write-Host ""
Write-Host "🔍 Management Commands:" -ForegroundColor Blue
Write-Host "   List tasks: Get-ScheduledTask -TaskName '*OTel*'" -ForegroundColor Gray
Write-Host "   Remove tasks: pwsh -File scripts\setup-scheduled-monitoring-admin.ps1 -RemoveTasks" -ForegroundColor Gray
Write-Host "   Test task: Start-ScheduledTask -TaskName 'OTel-QuickHealthCheck'" -ForegroundColor Gray
Write-Host "   View history: Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=200,201}" -ForegroundColor Gray

Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Blue
Write-Host "   1. Verify tasks: Get-ScheduledTask -TaskName '*OTel*'" -ForegroundColor Gray
Write-Host "   2. Test manually: Start-ScheduledTask -TaskName 'OTel-QuickHealthCheck'" -ForegroundColor Gray
Write-Host "   3. Check artifacts: Get-ChildItem artifacts\*.json | Sort-Object LastWriteTime -Descending" -ForegroundColor Gray
Write-Host "   4. Monitor logs: Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TaskScheduler/Operational'; ID=200,201} | Where-Object {`$_.Message -like '*OTel*'}" -ForegroundColor Gray

