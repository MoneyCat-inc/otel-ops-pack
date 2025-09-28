# ECRR Scheduled Monitoring Script
# Sets up and manages daily automated compliance checking

param(
    [string]$Action = "setup",
    [string]$ScheduleTime = "06:00",
    [string]$ConfigPath = "config/ecrr-monitoring.json",
    [switch]$Enable,
    [switch]$Disable,
    [switch]$Status,
    [switch]$Test
)

# Scheduled Task Configuration
$SCHEDULED_TASK_CONFIG = @{
    "TaskName" = "ECRR-Compliance-Monitoring"
    "Description" = "Daily ECRR compliance monitoring and reporting"
    "ScriptPath" = "$PSScriptRoot/ecrr-compliance-monitoring.ps1"
    "Arguments" = "-Dashboard -Alert -OutputPath `"artifacts/ecrr-compliance-monitoring`" -ConfigPath `"$ConfigPath`""
    "WorkingDirectory" = $PSScriptRoot.Replace("scripts", "")
    "User" = "SYSTEM"
    "RunLevel" = "Highest"
}

function Test-ScheduledTask {
    param([string]$TaskName)
    
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        return $task
    }
    catch {
        return $null
    }
}

function New-ECRRScheduledTask {
    param(
        [string]$TaskName,
        [string]$ScheduleTime,
        [hashtable]$Config
    )
    
    Write-Host "🔧 Creating ECRR scheduled task..." -ForegroundColor Cyan
    
    # Parse schedule time
    $timeParts = $ScheduleTime -split ":"
    $hour = [int]$timeParts[0]
    $minute = [int]$timeParts[1]
    
    # Create trigger for daily execution
    $trigger = New-ScheduledTaskTrigger -Daily -At "${hour}:${minute}"
    
    # Create action to run PowerShell script
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$($Config.ScriptPath)`" $($Config.Arguments)" -WorkingDirectory $Config.WorkingDirectory
    
    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
    
    # Create principal for SYSTEM user
    $principal = New-ScheduledTaskPrincipal -UserId $Config.User -LogonType ServiceAccount -RunLevel $Config.RunLevel
    
    # Register the scheduled task
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $Config.Description -Force
    
    Write-Host "✅ Scheduled task created: $TaskName" -ForegroundColor Green
    Write-Host "   Schedule: Daily at $ScheduleTime" -ForegroundColor Cyan
    Write-Host "   Script: $($Config.ScriptPath)" -ForegroundColor Cyan
    Write-Host "   Working Directory: $($Config.WorkingDirectory)" -ForegroundColor Cyan
}

function Enable-ECRRScheduledTask {
    param([string]$TaskName)
    
    Write-Host "🚀 Enabling ECRR scheduled task..." -ForegroundColor Cyan
    
    try {
        Enable-ScheduledTask -TaskName $TaskName
        Write-Host "✅ Scheduled task enabled: $TaskName" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to enable scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Disable-ECRRScheduledTask {
    param([string]$TaskName)
    
    Write-Host "⏸️ Disabling ECRR scheduled task..." -ForegroundColor Cyan
    
    try {
        Disable-ScheduledTask -TaskName $TaskName
        Write-Host "✅ Scheduled task disabled: $TaskName" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to disable scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-ECRRScheduledTaskStatus {
    param([string]$TaskName)
    
    Write-Host "📊 ECRR Scheduled Task Status" -ForegroundColor Cyan
    Write-Host ""
    
    $task = Test-ScheduledTask -TaskName $TaskName
    
    if ($task -eq $null) {
        Write-Host "❌ Scheduled task not found: $TaskName" -ForegroundColor Red
        return
    }
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    
    Write-Host "📋 Task Information:" -ForegroundColor Green
    Write-Host "   Name: $($task.TaskName)" -ForegroundColor Cyan
    Write-Host "   Description: $($task.Description)" -ForegroundColor Cyan
    Write-Host "   State: $($task.State)" -ForegroundColor $(if ($task.State -eq "Running") { "Green" } elseif ($task.State -eq "Ready") { "Yellow" } else { "Red" })
    Write-Host "   Enabled: $($task.Enabled)" -ForegroundColor $(if ($task.Enabled) { "Green" } else { "Red" })
    Write-Host ""
    
    Write-Host "📅 Schedule Information:" -ForegroundColor Green
    foreach ($trigger in $task.Triggers) {
        Write-Host "   Type: $($trigger.CimClass.CimClassName)" -ForegroundColor Cyan
        if ($trigger.CimClass.CimClassName -eq "MSFT_TaskDailyTrigger") {
            Write-Host "   Time: $($trigger.StartBoundary)" -ForegroundColor Cyan
        }
    }
    Write-Host ""
    
    Write-Host "📊 Execution Information:" -ForegroundColor Green
    Write-Host "   Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor Cyan
    Write-Host "   Last Task Result: $($taskInfo.LastTaskResult)" -ForegroundColor $(if ($taskInfo.LastTaskResult -eq 0) { "Green" } else { "Red" })
    Write-Host "   Next Run Time: $($taskInfo.NextRunTime)" -ForegroundColor Cyan
    Write-Host "   Number of Missed Runs: $($taskInfo.NumberOfMissedRuns)" -ForegroundColor $(if ($taskInfo.NumberOfMissedRuns -eq 0) { "Green" } else { "Yellow" })
    Write-Host ""
}

function Test-ECRRScheduledTask {
    param([string]$TaskName)
    
    Write-Host "🧪 Testing ECRR scheduled task..." -ForegroundColor Cyan
    
    $task = Test-ScheduledTask -TaskName $TaskName
    if ($task -eq $null) {
        Write-Host "❌ Scheduled task not found: $TaskName" -ForegroundColor Red
        return
    }
    
    try {
        Write-Host "🚀 Running scheduled task manually..." -ForegroundColor Cyan
        Start-ScheduledTask -TaskName $TaskName
        
        # Wait a moment for the task to start
        Start-Sleep -Seconds 2
        
        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "✅ Task execution started" -ForegroundColor Green
        Write-Host "   Last Run Time: $($taskInfo.LastRunTime)" -ForegroundColor Cyan
        
        # Check for output files
        $outputPath = "artifacts/ecrr-compliance-monitoring"
        if (Test-Path $outputPath) {
            Write-Host "✅ Output directory created: $outputPath" -ForegroundColor Green
            
            $files = Get-ChildItem -Path $outputPath -Recurse
            Write-Host "📁 Generated files:" -ForegroundColor Cyan
            foreach ($file in $files) {
                Write-Host "   - $($file.Name)" -ForegroundColor Cyan
            }
        }
        
    }
    catch {
        Write-Host "❌ Failed to run scheduled task: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-SetupInstructions {
    Write-Host "📋 ECRR Scheduled Monitoring Setup Instructions" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "🔵 Prerequisites:" -ForegroundColor Blue
    Write-Host "1. PowerShell 7.4+ installed"
    Write-Host "2. ECRR compliance monitoring scripts in place"
    Write-Host "3. Configuration file: config/ecrr-monitoring.json"
    Write-Host "4. Administrator privileges for scheduled task creation"
    Write-Host ""
    
    Write-Host "🔵 Setup Steps:" -ForegroundColor Blue
    Write-Host "1. Run: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Action setup -ScheduleTime '06:00'"
    Write-Host "2. Enable: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Enable"
    Write-Host "3. Test: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Test"
    Write-Host "4. Check status: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Status"
    Write-Host ""
    
    Write-Host "🔵 Management Commands:" -ForegroundColor Blue
    Write-Host "- Enable: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Enable"
    Write-Host "- Disable: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Disable"
    Write-Host "- Status: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Status"
    Write-Host "- Test: pwsh -File scripts/ecrr-schedule-monitoring.ps1 -Test"
    Write-Host ""
    
    Write-Host "🔵 Schedule Times:" -ForegroundColor Blue
    Write-Host "- Daily at 6 AM: -ScheduleTime '06:00'"
    Write-Host "- Daily at 9 AM: -ScheduleTime '09:00'"
    Write-Host "- Daily at 6 PM: -ScheduleTime '18:00'"
    Write-Host "- Custom time: -ScheduleTime 'HH:MM'"
    Write-Host ""
}

# Main execution
Write-Host "⏰ ECRR Scheduled Monitoring Setup" -ForegroundColor Cyan
Write-Host ""

$taskName = $SCHEDULED_TASK_CONFIG.TaskName

switch ($Action.ToLower()) {
    "setup" {
        $existingTask = Test-ScheduledTask -TaskName $taskName
        if ($existingTask -ne $null) {
            Write-Host "⚠️ Scheduled task already exists: $taskName" -ForegroundColor Yellow
            Write-Host "   Current state: $($existingTask.State)" -ForegroundColor Cyan
            Write-Host "   Use -Enable or -Disable to manage the task" -ForegroundColor Cyan
        } else {
            New-ECRRScheduledTask -TaskName $taskName -ScheduleTime $ScheduleTime -Config $SCHEDULED_TASK_CONFIG
        }
    }
    
    "enable" {
        Enable-ECRRScheduledTask -TaskName $taskName
    }
    
    "disable" {
        Disable-ECRRScheduledTask -TaskName $taskName
    }
    
    "status" {
        Get-ECRRScheduledTaskStatus -TaskName $taskName
    }
    
    "test" {
        Test-ECRRScheduledTask -TaskName $taskName
    }
    
    "help" {
        Show-SetupInstructions
    }
    
    default {
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        Write-Host "Available actions: setup, enable, disable, status, test, help" -ForegroundColor Yellow
        Show-SetupInstructions
        exit 1
    }
}

if ($Status) {
    Get-ECRRScheduledTaskStatus -TaskName $taskName
}

if ($Test) {
    Test-ECRRScheduledTask -TaskName $taskName
}

Write-Host ""
Write-Host "✅ ECRR Scheduled Monitoring Setup Complete" -ForegroundColor Green
