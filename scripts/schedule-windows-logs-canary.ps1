#Requires -Version 7.0

<#
.SYNOPSIS
    Schedule Windows Logs Canary generation via Task Scheduler

.DESCRIPTION
    This script creates a Windows Task Scheduler task to automatically generate
    Windows Event Log canary entries at regular intervals for pipeline monitoring.

.PARAMETER TaskName
    Name of the scheduled task (default: WindowsLogsCanary)

.PARAMETER IntervalMinutes
    Interval between canary generations in minutes (default: 30)

.PARAMETER CanaryCount
    Number of canary entries to generate each time (default: 3)

.PARAMETER RemoveTask
    Remove the scheduled task instead of creating it

.EXAMPLE
    .\schedule-windows-logs-canary.ps1
    .\schedule-windows-logs-canary.ps1 -IntervalMinutes 15 -CanaryCount 5
    .\schedule-windows-logs-canary.ps1 -RemoveTask
#>

param(
    [string]$TaskName = "WindowsLogsCanary",
    [int]$IntervalMinutes = 30,
    [int]$CanaryCount = 3,
    [switch]$RemoveTask
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

Write-Info "🕐 Windows Logs Canary Task Scheduler Setup"
Write-Info "==========================================="

if ($RemoveTask) {
    Write-Info "Removing scheduled task: $TaskName"
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Success "Task '$TaskName' removed successfully"
        exit 0
    } catch {
        Write-Warning "Task '$TaskName' not found or already removed"
        exit 0
    }
}

# Configuration
$ScriptPath = Join-Path $PSScriptRoot "windows-logs-canary-test.ps1"
$TaskDescription = "Automatically generate Windows Event Log canary entries for observability pipeline monitoring"
$TaskAuthor = "OTel Observability Kit"

Write-Info "Task Name: $TaskName"
Write-Info "Interval: Every $IntervalMinutes minutes"
Write-Info "Canary Count: $CanaryCount entries per run"
Write-Info "Script Path: $ScriptPath"

# Verify script exists
if (-not (Test-Path $ScriptPath)) {
    Write-Error "Canary test script not found: $ScriptPath"
    Write-Info "Make sure scripts/windows-logs-canary-test.ps1 exists"
    exit 1
}

try {
    # Remove existing task if it exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Info "Removing existing task: $TaskName"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
    }

    # Create action to run the canary script
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$ScriptPath`" -Count $CanaryCount"

    # Create trigger for the interval
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)

    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    # Create task principal (run as SYSTEM for reliability)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Register the scheduled task
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $TaskDescription -Force

    Write-Success "✅ Scheduled task '$TaskName' created successfully!"
    Write-Info "📋 Task Details:"
    Write-Info "  • Name: $TaskName"
    Write-Info "  • Interval: Every $IntervalMinutes minutes"
    Write-Info "  • Canary Count: $CanaryCount per run"
    Write-Info "  • Runs as: SYSTEM (highest privileges)"
    Write-Info "  • Script: $ScriptPath"

    # Get task info for verification
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($taskInfo) {
        Write-Info "📊 Task Status:"
        Write-Info "  • State: $($taskInfo.TaskState)"
        Write-Info "  • Last Run: $($taskInfo.LastRunTime)"
        Write-Info "  • Next Run: $($taskInfo.NextRunTime)"
    }

    # Create artifacts report
    $artifactsDir = "artifacts"
    if (-not (Test-Path $artifactsDir)) {
        New-Item -Path $artifactsDir -ItemType Directory | Out-Null
    }

    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        task_name = $TaskName
        interval_minutes = $IntervalMinutes
        canary_count = $CanaryCount
        script_path = $ScriptPath
        task_description = $TaskDescription
        status = "created"
    }

    $reportFile = Join-Path $artifactsDir "windows-logs-canary-scheduler-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Info "📄 Report saved to: $reportFile"

    Write-Info "`n🔗 Next Steps:"
    Write-Info "  • Monitor task execution in Task Scheduler"
    Write-Info "  • Check SigNoz logs for generated canaries"
    Write-Info "  • Verify alert configuration is working"
    Write-Info "  • Configure notification channels"

    Write-Info "`n📚 Management Commands:"
    Write-Info "  • View task: Get-ScheduledTask -TaskName '$TaskName'"
    Write-Info "  • Run manually: Start-ScheduledTask -TaskName '$TaskName'"
    Write-Info "  • Remove task: .\schedule-windows-logs-canary.ps1 -RemoveTask"
    Write-Info "  • Check status: Get-ScheduledTaskInfo -TaskName '$TaskName'"

    exit 0

} catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
    Write-Info "Make sure you're running as Administrator"
    exit 1
}
