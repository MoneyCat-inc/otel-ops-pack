#Requires -Version 7.0

<#
.SYNOPSIS
    Schedule ECRR task generation for automated workflow integration

.DESCRIPTION
    Creates scheduled tasks and git hooks for automated ECRR report processing.
    Supports daily/weekly runs and commit-triggered generation.

.PARAMETER Action
    Action to perform: create-schedule, create-hook, test-run, remove-schedule

.PARAMETER ScheduleType
    Type of schedule: daily, weekly, manual

.PARAMETER Time
    Time for scheduled runs (HH:MM format). Default: 09:00

.PARAMETER MaxTasks
    Maximum tasks to generate per run. Default: 5

.PARAMETER AutoAssign
    Auto-assign tasks based on category

.EXAMPLE
    .\schedule-ecrr-generation.ps1 -Action create-schedule -ScheduleType daily -Time 09:00
    Create a daily scheduled task for ECRR generation

.EXAMPLE
    .\schedule-ecrr-generation.ps1 -Action create-hook
    Create a git pre-commit hook for ECRR processing

.EXAMPLE
    .\schedule-ecrr-generation.ps1 -Action test-run -MaxTasks 3
    Test the generation process without scheduling
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('create-schedule', 'create-hook', 'test-run', 'remove-schedule', 'status')]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [ValidateSet('daily', 'weekly', 'manual')]
    [string]$ScheduleType = 'daily',

    [Parameter(Mandatory = $false)]
    [string]$Time = '09:00',

    [Parameter(Mandatory = $false)]
    [int]$MaxTasks = 5,

    [Parameter(Mandatory = $false)]
    [switch]$AutoAssign
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        default   { 'Cyan' }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-ScheduledTask {
    param(
        [string]$TaskName,
        [string]$ScheduleType,
        [string]$Time,
        [int]$MaxTasks,
        [bool]$AutoAssign
    )

    if (-not (Test-Administrator)) {
        Write-Log "Administrator privileges required to create scheduled tasks" 'ERROR'
        return $false
    }

    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'ecrr-task-automation.ps1'
    $arguments = "-MaxTasks $MaxTasks"
    if ($AutoAssign) { $arguments += " -AutoAssign" }

    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-File `"$scriptPath`" $arguments"
    
    $trigger = switch ($ScheduleType) {
        'daily' { New-ScheduledTaskTrigger -Daily -At $Time }
        'weekly' { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $Time }
        'manual' { New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) }
    }

    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    try {
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
        Write-Log "Scheduled task '$TaskName' created successfully" 'SUCCESS'
        return $true
    }
    catch {
        Write-Log "Failed to create scheduled task: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Remove-ScheduledTask {
    param([string]$TaskName)

    if (-not (Test-Administrator)) {
        Write-Log "Administrator privileges required to remove scheduled tasks" 'ERROR'
        return $false
    }

    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Log "Scheduled task '$TaskName' removed successfully" 'SUCCESS'
        return $true
    }
    catch {
        Write-Log "Failed to remove scheduled task: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function New-GitHook {
    param([int]$MaxTasks, [bool]$AutoAssign)

    $gitDir = Join-Path -Path (Get-Location) -ChildPath '.git'
    if (-not (Test-Path -Path $gitDir)) {
        Write-Log "Not in a git repository" 'ERROR'
        return $false
    }

    $hooksDir = Join-Path -Path $gitDir -ChildPath 'hooks'
    if (-not (Test-Path -Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir -Force | Out-Null
    }

    $hookFile = Join-Path -Path $hooksDir -ChildPath 'pre-commit'
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'ecrr-task-automation.ps1'
    
    $arguments = "-MaxTasks $MaxTasks"
    if ($AutoAssign) { $arguments += " -AutoAssign" }

    $hookContent = @"
#!/bin/sh
# ECRR Task Generation Hook
# Generated by schedule-ecrr-generation.ps1

echo "Running ECRR task generation..."
pwsh -File "$scriptPath" $arguments

# Continue with commit even if generation fails
exit 0
"@

    try {
        Set-Content -Path $hookFile -Value $hookContent -Encoding UTF8
        # Make executable on Unix systems
        if ($IsLinux -or $IsMacOS) {
            chmod +x $hookFile
        }
        Write-Log "Git pre-commit hook created: $hookFile" 'SUCCESS'
        return $true
    }
    catch {
        Write-Log "Failed to create git hook: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Test-GenerationRun {
    param([int]$MaxTasks, [bool]$AutoAssign)

    Write-Log "Testing ECRR task generation..." 'INFO'
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'ecrr-task-automation.ps1'
    $arguments = "-MaxTasks $MaxTasks -DryRun"
    if ($AutoAssign) { $arguments += " -AutoAssign" }

    try {
        & pwsh -File $scriptPath $arguments
        Write-Log "Test run completed successfully" 'SUCCESS'
        return $true
    }
    catch {
        Write-Log "Test run failed: $($_.Exception.Message)" 'ERROR'
        return $false
    }
}

function Get-ScheduleStatus {
    $taskName = "ECRR-Task-Generation"
    
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Write-Host "`nScheduled Task Status" -ForegroundColor Cyan
            Write-Host "====================" -ForegroundColor Cyan
            Write-Host "Task Name: $($task.TaskName)" -ForegroundColor White
            Write-Host "State: $($task.State)" -ForegroundColor White
            Write-Host "Last Run: $($task.LastRunTime)" -ForegroundColor White
            Write-Host "Next Run: $($task.NextRunTime)" -ForegroundColor White
            
            $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
            if ($taskInfo) {
                Write-Host "Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor White
            }
        } else {
            Write-Host "`nNo scheduled task found for ECRR generation" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Log "Failed to get schedule status: $($_.Exception.Message)" 'ERROR'
    }
}

# Main execution
Write-Host "ECRR Task Generation Scheduler" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

switch ($Action) {
    'create-schedule' {
        $taskName = "ECRR-Task-Generation"
        Write-Log "Creating scheduled task: $taskName" 'INFO'
        Write-Log "Schedule: $ScheduleType at $Time" 'INFO'
        Write-Log "Max Tasks: $MaxTasks" 'INFO'
        Write-Log "Auto Assign: $AutoAssign" 'INFO'
        
        if (New-ScheduledTask -TaskName $taskName -ScheduleType $ScheduleType -Time $Time -MaxTasks $MaxTasks -AutoAssign $AutoAssign) {
            Write-Host "`nScheduled task created successfully!" -ForegroundColor Green
            Write-Host "Task will run $ScheduleType at $Time" -ForegroundColor White
            Write-Host "Use 'Get-ScheduledTask -TaskName ECRR-Task-Generation' to view details" -ForegroundColor Gray
        }
    }
    
    'create-hook' {
        Write-Log "Creating git pre-commit hook" 'INFO'
        Write-Log "Max Tasks: $MaxTasks" 'INFO'
        Write-Log "Auto Assign: $AutoAssign" 'INFO'
        
        if (New-GitHook -MaxTasks $MaxTasks -AutoAssign $AutoAssign) {
            Write-Host "`nGit hook created successfully!" -ForegroundColor Green
            Write-Host "ECRR task generation will run before each commit" -ForegroundColor White
            Write-Host "Hook location: .git/hooks/pre-commit" -ForegroundColor Gray
        }
    }
    
    'test-run' {
        Write-Log "Running test generation" 'INFO'
        Write-Log "Max Tasks: $MaxTasks" 'INFO'
        Write-Log "Auto Assign: $AutoAssign" 'INFO'
        
        if (Test-GenerationRun -MaxTasks $MaxTasks -AutoAssign $AutoAssign) {
            Write-Host "`nTest run completed successfully!" -ForegroundColor Green
            Write-Host "Ready for scheduled deployment" -ForegroundColor White
        }
    }
    
    'remove-schedule' {
        $taskName = "ECRR-Task-Generation"
        Write-Log "Removing scheduled task: $taskName" 'INFO'
        
        if (Remove-ScheduledTask -TaskName $taskName) {
            Write-Host "`nScheduled task removed successfully!" -ForegroundColor Green
        }
    }
    
    'status' {
        Get-ScheduleStatus
    }
}

Write-Host "`nIntegration Notes:" -ForegroundColor Cyan
Write-Host "• Scheduled tasks require administrator privileges" -ForegroundColor White
Write-Host "• Git hooks run automatically on commits" -ForegroundColor White
Write-Host "• Use 'pwsh -File scripts/manage-tasks.ps1 -Action Status' to monitor task counts" -ForegroundColor White
Write-Host "• Generated summaries are saved to artifacts/ directory" -ForegroundColor White
