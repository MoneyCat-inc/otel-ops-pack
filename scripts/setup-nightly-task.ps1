# Setup Nightly Queue Steward Diagnostics Task
# Purpose: Configure Windows Task Scheduler to run nightly diagnostics automatically
# Usage: Run as Administrator to create the scheduled task

param(
    [string]$TaskName = "QueueSteward-NightlyDiagnostics",
    [string]$WorkingDirectory = "C:\otel",
    [string]$StartTime = "02:00",
    [switch]$Force = $false
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator to create scheduled tasks." -ForegroundColor Red
    Write-Host "Please restart PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Setting up Nightly Queue Steward Diagnostics Task" -ForegroundColor Cyan
Write-Host "Task Name: $TaskName" -ForegroundColor Gray
Write-Host "Working Directory: $WorkingDirectory" -ForegroundColor Gray
Write-Host "Start Time: $StartTime" -ForegroundColor Gray
Write-Host ""

# Check if working directory exists
if (-not (Test-Path $WorkingDirectory)) {
    Write-Host "Error: Working directory '$WorkingDirectory' does not exist." -ForegroundColor Red
    Write-Host "Please update the WorkingDirectory parameter to point to your otel repository." -ForegroundColor Yellow
    exit 1
}

# Check if the nightly diagnostics script exists
$nightlyScript = Join-Path $WorkingDirectory "scripts\nightly-queue-diagnostics.ps1"
if (-not (Test-Path $nightlyScript)) {
    Write-Host "Error: Nightly diagnostics script not found at '$nightlyScript'." -ForegroundColor Red
    exit 1
}

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask -and -not $Force) {
    Write-Host "Task '$TaskName' already exists. Use -Force to overwrite." -ForegroundColor Yellow
    exit 1
}

try {
    # Remove existing task if Force is specified
    if ($existingTask -and $Force) {
        Write-Host "Removing existing task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create the action (what to run)
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$nightlyScript`" -OutputDir `"$WorkingDirectory\artifacts`" -RetentionDays 7" -WorkingDirectory $WorkingDirectory

    # Create the trigger (when to run - daily at specified time)
    $trigger = New-ScheduledTaskTrigger -Daily -At $StartTime

    # Create the settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    # Create the principal (run as SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Create the task
    Write-Host "Creating scheduled task..." -ForegroundColor Yellow
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Nightly Queue Steward Diagnostics - Runs comprehensive diagnostics with canary test and artifact cleanup"

    # Register the task
    Register-ScheduledTask -TaskName $TaskName -InputObject $task

    Write-Host ""
    Write-Host "✅ Scheduled task created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task Details:" -ForegroundColor Cyan
    Write-Host "  Name: $TaskName" -ForegroundColor White
    Write-Host "  Schedule: Daily at $StartTime" -ForegroundColor White
    Write-Host "  Command: pwsh -File `"$nightlyScript`"" -ForegroundColor White
    Write-Host "  Working Directory: $WorkingDirectory" -ForegroundColor White
    Write-Host "  Run As: SYSTEM (highest privileges)" -ForegroundColor White
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Cyan
    Write-Host "  View task: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Run now: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Disable: Disable-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
    Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Task Scheduler UI: taskschd.msc" -ForegroundColor Gray

    # Test run the task immediately (optional)
    $testRun = Read-Host "Would you like to test run the task now? (y/N)"
    if ($testRun -eq 'y' -or $testRun -eq 'Y') {
        Write-Host ""
        Write-Host "Running test execution..." -ForegroundColor Yellow
        Start-ScheduledTask -TaskName $TaskName
        
        # Wait a moment and check the result
        Start-Sleep -Seconds 5
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor Gray
        Write-Host "Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor $(if ($taskInfo.LastTaskResult -eq 0) { 'Green' } else { 'Red' })
    }

}
catch {
    Write-Host "Error creating scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
