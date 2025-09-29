# Schedule ECRR Orchestrator for Nightly Dashboard Refresh
# Creates a Windows scheduled task to run the ECRR orchestrator daily at 02:00

param(
    [string]$TaskName = "ECRR-Orchestrator-Daily",
    [string]$Time = "02:00",
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script requires administrator privileges to create scheduled tasks."
    exit 1
}

# Get the script directory and construct the full path to the orchestrator
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$orchestratorPath = Join-Path $scriptDir "ecrr-process-and-publish.ps1"

if (-not (Test-Path $orchestratorPath)) {
    Write-Error "ECRR orchestrator script not found: $orchestratorPath"
    exit 1
}

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask -and -not $Force) {
    Write-Host "Scheduled task '$TaskName' already exists. Use -Force to overwrite." -ForegroundColor Yellow
    exit 0
}

# Remove existing task if Force is specified
if ($existingTask -and $Force) {
    Write-Host "Removing existing task '$TaskName'..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the action
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$orchestratorPath`""

# Create the trigger (daily at specified time)
$trigger = New-ScheduledTaskTrigger -Daily -At $Time

# Create task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Create the principal (run as SYSTEM with highest privileges)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Register the scheduled task
try {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Daily ECRR processing and dashboard refresh at $Time"
    
    Write-Host "✅ Scheduled task '$TaskName' created successfully!" -ForegroundColor Green
    Write-Host "   - Runs daily at $Time" -ForegroundColor Cyan
    Write-Host "   - Executes: pwsh -File scripts/ecrr-process-and-publish.ps1" -ForegroundColor Cyan
    Write-Host "   - Runs as SYSTEM with highest privileges" -ForegroundColor Cyan
    
    # Show the task details
    $task = Get-ScheduledTask -TaskName $TaskName
    Write-Host "`nTask Details:" -ForegroundColor Yellow
    Write-Host "  Name: $($task.TaskName)" -ForegroundColor White
    Write-Host "  State: $($task.State)" -ForegroundColor White
    Write-Host "  Next Run: $($task.NextRunTime)" -ForegroundColor White
    
    Write-Host "`nTo manage this task:" -ForegroundColor Yellow
    Write-Host "  View: Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  Run: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    Write-Host "  Remove: Unregister-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
    
} catch {
    Write-Error "Failed to create scheduled task: $_"
    exit 1
}
