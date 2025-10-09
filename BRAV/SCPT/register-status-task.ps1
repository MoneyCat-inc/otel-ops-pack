# Register Windows Scheduled Task for Health Status Updates
# Runs update-status.ps1 hourly to maintain fresh health data

param(
    [switch]$Unregister,
    [string]$IntervalHours = "1"
)

$ErrorActionPreference = "Stop"

$taskName = "TetragramHealthStatus"
$scriptPath = Join-Path $PSScriptRoot "update-status.ps1"
$workingDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent  # Repo root
$logFile = Join-Path $workingDir "CHAR\EVID\health\update-status.log"

Write-Host "🐾 BossCat Scheduled Task Configuration" -ForegroundColor Cyan
Write-Host ""

# Check if task exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($Unregister) {
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "✅ Task '$taskName' unregistered successfully" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Task '$taskName' not found" -ForegroundColor Yellow
    }
    exit 0
}

if ($existingTask) {
    Write-Host "⚠️  Task '$taskName' already exists" -ForegroundColor Yellow
    $response = Read-Host "Overwrite existing task? (y/N)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "Cancelled" -ForegroundColor Gray
        exit 0
    }
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Create scheduled task
Write-Host "Creating scheduled task..." -ForegroundColor Yellow
Write-Host "  Task name: $taskName" -ForegroundColor Gray
Write-Host "  Interval: Every $IntervalHours hour(s)" -ForegroundColor Gray
Write-Host "  Script: $scriptPath" -ForegroundColor Gray
Write-Host "  Log: $logFile" -ForegroundColor Gray
Write-Host ""

# Action: Run PowerShell script with logging
$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" *>> `"$logFile`"" `
    -WorkingDirectory $workingDir

# Trigger: Hourly
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours $IntervalHours)

# Settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
    -MultipleInstances IgnoreNew

# Principal: Run as current user, no elevation
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U

# Register task
try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Tetragram health status update - generates guardrails, Docker, and Windows service status every $IntervalHours hour(s)" | Out-Null
    
    Write-Host "✅ Scheduled task registered successfully" -ForegroundColor Green
    Write-Host ""
    Write-Host "Task will run:" -ForegroundColor Cyan
    Write-Host "  • Every $IntervalHours hour(s) starting now" -ForegroundColor Gray
    Write-Host "  • As user: $env:USERNAME (no elevation)" -ForegroundColor Gray
    Write-Host "  • Output logged to: $logFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Management commands:" -ForegroundColor Cyan
    Write-Host "  View status:  Get-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    Write-Host "  Run now:      Start-ScheduledTask -TaskName '$taskName'" -ForegroundColor Gray
    Write-Host "  Unregister:   .\register-status-task.ps1 -Unregister" -ForegroundColor Gray
    Write-Host "  View logs:    Get-Content '$logFile' -Tail 50" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Error registering task: $_" -ForegroundColor Red
    exit 1
}

