#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Setup BossCat nightly automation with scaled parallel processing
.DESCRIPTION
    Creates Windows scheduled tasks for continuous observability operations
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

Write-Host "`n🐾 BossCat Scaled Scheduler Setup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$workspaceRoot = $PSScriptRoot | Split-Path -Parent
$pwshPath = (Get-Command pwsh).Source

# Task 1: Nightly ECRR Processing & Dashboard Export
$nightlyTask = @{
    TaskName = "BossCat-Nightly-Reports"
    Description = "Nightly ECRR processing and dashboard exports (02:00 UTC)"
    Action = New-ScheduledTaskAction `
        -Execute $pwshPath `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$workspaceRoot\scripts\parallel-agent-orchestrator.ps1`" -TaskSpec `"{`\`"name`\`":`\`"nightly-processing`\`",`\`"type`\`":`\`"ecrr-compliance-check`\`",`\`"input`\`":{},`\`"output`\`":{`\`"telemetry`\`":true}}`" -MaxConcurrentAgents 48 -EnableTelemetry" `
        -WorkingDirectory $workspaceRoot
    Trigger = New-ScheduledTaskTrigger -Daily -At "02:00AM"
    Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable
}

# Task 2: Continuous Canary Monitoring
$canaryTask = @{
    TaskName = "BossCat-Canary-Monitoring"
    Description = "Continuous canary health checks (every 30 minutes)"
    Action = New-ScheduledTaskAction `
        -Execute $pwshPath `
        -Argument "-NoProfile -File `"$workspaceRoot\scripts\send-canary-log.ps1`"" `
        -WorkingDirectory $workspaceRoot
    Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 30) -RepetitionDuration ([TimeSpan]::MaxValue)
    Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable
}

# Task 3: Watchdog Startup (on system boot)
$watchdogTask = @{
    TaskName = "BossCat-Watchdog-Startup"
    Description = "Start BossCat watchdog on system boot"
    Action = New-ScheduledTaskAction `
        -Execute $pwshPath `
        -Argument "-NoProfile -WindowStyle Hidden -File `"$workspaceRoot\scripts\agent\watchdog.ps1`" -CycleIntervalSeconds 30" `
        -WorkingDirectory $workspaceRoot
    Trigger = New-ScheduledTaskTrigger -AtStartup
    Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable
}

if ($DryRun) {
    Write-Host "✓ DRY RUN: Would create 3 scheduled tasks:" -ForegroundColor Yellow
    Write-Host "  1. $($nightlyTask.TaskName)" -ForegroundColor White
    Write-Host "  2. $($canaryTask.TaskName)" -ForegroundColor White
    Write-Host "  3. $($watchdogTask.TaskName)" -ForegroundColor White
    exit 0
}

try {
    # Register tasks
    Write-Host "Creating scheduled task: $($nightlyTask.TaskName)..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $nightlyTask.TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask @nightlyTask -User "SYSTEM" | Out-Null
    Write-Host "✓ $($nightlyTask.TaskName) created" -ForegroundColor Green
    
    Write-Host "Creating scheduled task: $($canaryTask.TaskName)..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $canaryTask.TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask @canaryTask -User "SYSTEM" | Out-Null
    Write-Host "✓ $($canaryTask.TaskName) created" -ForegroundColor Green
    
    Write-Host "Creating scheduled task: $($watchdogTask.TaskName)..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $watchdogTask.TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask @watchdogTask -User "SYSTEM" | Out-Null
    Write-Host "✓ $($watchdogTask.TaskName) created" -ForegroundColor Green
    
    Write-Host "`n✅ All scheduled tasks created successfully" -ForegroundColor Green
    Write-Host "`n📅 Schedule:" -ForegroundColor Cyan
    Write-Host "   Nightly Reports: 02:00 AM daily" -ForegroundColor White
    Write-Host "   Canary Monitoring: Every 30 minutes" -ForegroundColor White
    Write-Host "   Watchdog: On system startup" -ForegroundColor White
    
} catch {
    Write-Host "`n❌ Error creating scheduled tasks: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Ensure you're running as Administrator" -ForegroundColor Yellow
    exit 1
}

