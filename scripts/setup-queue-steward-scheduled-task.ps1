# Queue Steward Canary Scheduled Task Setup
# This script creates a Windows Scheduled Task to run the canary automation every 15 minutes

param(
    [int]$IntervalMinutes = 15,
    [string]$TaskName = "QueueStewardCanary",
    [string]$ScriptPath = "scripts/queue-steward-canary-automation.ps1"
)

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator to create scheduled tasks."
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Get the full path to the script
$FullScriptPath = Resolve-Path $ScriptPath -ErrorAction SilentlyContinue
if (-not $FullScriptPath) {
    Write-Error "Script not found: $ScriptPath"
    Write-Host "Please ensure the script exists in the scripts/ directory." -ForegroundColor Red
    exit 1
}

# Create the scheduled task action
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$($FullScriptPath.Path)`""

# Create the scheduled task trigger (every N minutes)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 365)

# Create the scheduled task settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Create the scheduled task principal (run as SYSTEM)
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Automated Queue Steward Canary Emission - Emits canary logs and updates dashboard timestamp every $IntervalMinutes minutes"
    
    Write-Host "Scheduled Task Created Successfully!" -ForegroundColor Green
    Write-Host "Task Name: $TaskName" -ForegroundColor Cyan
    Write-Host "Interval: Every $IntervalMinutes minutes" -ForegroundColor Cyan
    Write-Host "Script: $($FullScriptPath.Path)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To manage the task:" -ForegroundColor Yellow
    Write-Host "  View: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  Start: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  Stop:  Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false" -ForegroundColor White
    
} catch {
    Write-Error "Failed to create scheduled task: $($_.Exception.Message)"
    exit 1
}

# Test the task immediately
Write-Host ""
Write-Host "Testing the scheduled task..." -ForegroundColor Yellow
try {
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 5
    
    $TaskInfo = Get-ScheduledTask -TaskName $TaskName
    Write-Host "Task Status: $($TaskInfo.State)" -ForegroundColor $(if ($TaskInfo.State -eq 'Running') { 'Green' } else { 'Yellow' })
    
} catch {
    Write-Warning "Task test failed: $($_.Exception.Message)"
}
