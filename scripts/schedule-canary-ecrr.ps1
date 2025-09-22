<#
Schedule ECRR-Enhanced Canary
-----------------------------
Creates a scheduled task for the ECRR-enhanced canary script.
Usage: pwsh -File scripts/schedule-canary-ecrr.ps1
#>

param(
    [string]$TaskName = "OTel-ECRR-Canary",
    [int]$IntervalMinutes = 10,
    [switch]$DryRun
)

# Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This script requires administrator privileges" -ForegroundColor Red
    Write-Host "   Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
    exit 1
}

$scriptPath = Join-Path $PSScriptRoot "canary-ecrr.ps1"
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: ECRR canary script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

Write-Host "Scheduling ECRR-Enhanced Canary" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Define the scheduled task
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoLogo -NonInteractive -File `"$scriptPath`"" -WorkingDirectory "C:\otel"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Removing existing scheduled task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

if ($DryRun) {
    Write-Host "DRY RUN - Would create task with:" -ForegroundColor Cyan
    Write-Host "  Task Name: $TaskName" -ForegroundColor White
    Write-Host "  Script: $scriptPath" -ForegroundColor White
    Write-Host "  Interval: Every $IntervalMinutes minutes" -ForegroundColor White
    Write-Host "  Principal: SYSTEM" -ForegroundColor White
    exit 0
}

# Create the new scheduled task
Write-Host "Creating scheduled task: $TaskName" -ForegroundColor Yellow
Write-Host "   Script: $scriptPath" -ForegroundColor Gray
Write-Host "   Interval: Every $IntervalMinutes minutes" -ForegroundColor Gray
Write-Host "   Duration: 1 year" -ForegroundColor Gray

try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "ECRR-enhanced OpenTelemetry canary testing every $IntervalMinutes minutes"
    Write-Host "SUCCESS: ECRR canary scheduled task created successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify the task was created
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host "`nTask Details:" -ForegroundColor Cyan
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor White
    Write-Host "  State: $($task.State)" -ForegroundColor White
    
    try {
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "  Next Run: $($taskInfo.NextRunTime)" -ForegroundColor White
        Write-Host "  Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "  Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor White
    } catch {
        Write-Host "  Next Run: Not available yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR: Task verification failed" -ForegroundColor Red
    exit 1
}

Write-Host "`nECRR Canary Features:" -ForegroundColor Cyan
Write-Host "  - Examine: Environment state validation" -ForegroundColor White
Write-Host "  - Clean: Drift detection and remediation" -ForegroundColor White
Write-Host "  - Report: Structured canary execution with artifacts" -ForegroundColor White
Write-Host "  - Role: Clear agent responsibilities and handoffs" -ForegroundColor White

Write-Host "`nManagement Commands:" -ForegroundColor Cyan
Write-Host "  View task: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Run now: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor Gray

Write-Host "`nVerification:" -ForegroundColor Cyan
Write-Host "  - Check artifacts: Get-Content C:\otel\artifacts\canary-ecrr-report.txt" -ForegroundColor Gray
Write-Host "  - SigNoz logs: http://localhost:8080 -> Logs -> filter: 'ECRR-Canary-Test'" -ForegroundColor Gray
Write-Host "  - Event logs: Windows Event Viewer -> Application -> 'SigNoz-Canary'" -ForegroundColor Gray
