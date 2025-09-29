# Windows Task Scheduler Setup for ECRR Compliance Monitoring
# Creates scheduled task to run compliance monitoring every 30 minutes

param(
    [string]$TaskName = "ECRR Compliance Monitoring",
    [string]$ScriptPath = "scripts\monitor-ecrr-compliance-trends.ps1",
    [int]$IntervalMinutes = 30,
    [string]$WorkingDirectory,
    [switch]$CreateTask,
    [switch]$RemoveTask,
    [switch]$ListTasks,
    [switch]$TestTask
)

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if (-not $WorkingDirectory) {
    $WorkingDirectory = $script:RepoRoot
}

Write-Host "? ECRR Compliance Monitoring Task Scheduler" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   Working Directory : $WorkingDirectory" -ForegroundColor Gray
Write-Host "   Script Path       : $ScriptPath" -ForegroundColor Gray
Write-Host ""

function Resolve-ComplianceScriptPath {
    param(
        [Parameter(Mandatory = $true)][string]$Script,
        [Parameter(Mandatory = $true)][string]$BaseDirectory
    )

    if ([System.IO.Path]::IsPathRooted($Script)) {
        return (Resolve-Path -Path $Script -ErrorAction Stop).Path
    }

    $candidate = Join-Path $BaseDirectory $Script
    return (Resolve-Path -Path $candidate -ErrorAction Stop).Path
}

# Function to create scheduled task
function New-ComplianceMonitoringTask {
    param(
        [string]$Name,
        [string]$Script,
        [int]$Interval,
        [string]$BaseDirectory
    )
    
    Write-Host "?? Creating scheduled task: $Name" -ForegroundColor Yellow
    
    try {
        $fullScriptPath = Resolve-ComplianceScriptPath -Script $Script -BaseDirectory $BaseDirectory

        $pwshExecutable = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source
        if (-not $pwshExecutable) {
            $pwshExecutable = 'pwsh.exe'
        }

        $actionArguments = "-NoLogo -NoProfile -File `"$fullScriptPath`" -GenerateReport"
        $action = New-ScheduledTaskAction -Execute $pwshExecutable -Argument $actionArguments -WorkingDirectory $BaseDirectory
        
        # Create task trigger (every Interval minutes)
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $Interval) -RepetitionDuration ([TimeSpan]::FromDays(365))
        
        # Create task settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable
        
        # Create task principal (run as SYSTEM)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        if (Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue) {
            Write-Host "   Existing task found. Updating definition..." -ForegroundColor Gray
        }

        Register-ScheduledTask -TaskName $Name -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "ECRR Compliance Monitoring - Runs every $Interval minutes" -Force | Out-Null
        
        $info = Get-ScheduledTaskInfo -TaskName $Name
        Write-Host "? Scheduled task configured successfully!" -ForegroundColor Green
        Write-Host "   Script      : $fullScriptPath" -ForegroundColor White
        Write-Host "   Working Dir : $BaseDirectory" -ForegroundColor White
        Write-Host "   Interval    : Every $Interval minutes" -ForegroundColor White
        Write-Host "   Next Run    : $($info.NextRunTime)" -ForegroundColor White
        
        return $true
    }
    catch {
        Write-Host "? Failed to create scheduled task: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to remove scheduled task
function Remove-ComplianceMonitoringTask {
    param([string]$Name)
    
    Write-Host "??? Removing scheduled task: $Name" -ForegroundColor Yellow
    
    try {
        Unregister-ScheduledTask -TaskName $Name -Confirm:$false
        Write-Host "? Scheduled task removed successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "? Failed to remove scheduled task: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to list ECRR-related tasks
function Get-ComplianceMonitoringTasks {
    Write-Host "?? ECRR Compliance Monitoring Tasks:" -ForegroundColor Cyan
    
    try {
        $tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like '*ECRR*' -or $_.TaskName -like '*Compliance*' }
        
        if (-not $tasks) {
            Write-Host "   No ECRR compliance monitoring tasks found" -ForegroundColor Yellow
        } else {
            foreach ($task in $tasks) {
                $info = Get-ScheduledTaskInfo -TaskName $task.TaskName
                Write-Host ""
                Write-Host "   Task       : $($task.TaskName)" -ForegroundColor White
                Write-Host "   State      : $($task.State)" -ForegroundColor White
                Write-Host "   Last Run   : $($info.LastRunTime)" -ForegroundColor White
                Write-Host "   Last Result: $($info.LastTaskResult)" -ForegroundColor White
                Write-Host "   Next Run   : $($info.NextRunTime)" -ForegroundColor White
            }
        }
        
        return $tasks
    }
    catch {
        Write-Host "? Failed to list tasks: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

# Function to test task execution
function Test-ComplianceMonitoringTask {
    param(
        [string]$Name,
        [string]$BaseDirectory
    )
    
    Write-Host "?? Testing scheduled task: $Name" -ForegroundColor Yellow
    
    try {
        $task = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
        $info = Get-ScheduledTaskInfo -TaskName $Name
        
        Write-Host "   Task State : $($task.State)" -ForegroundColor White
        Write-Host "   Last Run   : $($info.LastRunTime)" -ForegroundColor White
        Write-Host "   Last Result: $($info.LastTaskResult)" -ForegroundColor White
        
        $logFile = Join-Path 'C:/logs/ecrr' 'compliance-trends.log'
        if (Test-Path $logFile) {
            $lastWrite = (Get-Item $logFile).LastWriteTime
            $minutesAgo = [math]::Round(((Get-Date) - $lastWrite).TotalMinutes, 1)
            if ($minutesAgo -lt 60) {
                Write-Host "   ? Log file updated recently ($minutesAgo minutes ago)" -ForegroundColor Green
            } else {
                Write-Host "   ?? Log file not updated recently ($minutesAgo minutes ago)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "   ? Log file not found: $logFile" -ForegroundColor Red
        }

        Write-Host ""
        Write-Host "   Triggering manual run for verification..." -ForegroundColor Gray
        Start-ScheduledTask -TaskName $Name
        Start-Sleep -Seconds 5
        $info = Get-ScheduledTaskInfo -TaskName $Name
        Write-Host "   Last Run   : $($info.LastRunTime)" -ForegroundColor White
        Write-Host "   Last Result: $($info.LastTaskResult)" -ForegroundColor White
        
        return $true
    }
    catch {
        Write-Host "? Failed to test task: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to create task management script
function New-TaskManagementScript {
    param(
        [string]$BaseDirectory,
        [string]$Task
    )

    $managementPath = Join-Path $BaseDirectory 'scripts/manage-compliance-task.ps1'

    $scriptContent = @"
# ECRR Compliance Task Management Script
# Quick commands for managing the compliance monitoring scheduled task

param(
    [switch]$Start,
    [switch]$Stop,
    [switch]$Status,
    [switch]$RunNow,
    [switch]$Logs
)

`$TaskName = '$Task'

if (`$Start) {
    Write-Host "?? Starting ECRR Compliance Monitoring Task" -ForegroundColor Green
    Start-ScheduledTask -TaskName `$TaskName
    Write-Host "? Task started" -ForegroundColor Green
}
elseif (`$Stop) {
    Write-Host "?? Stopping ECRR Compliance Monitoring Task" -ForegroundColor Yellow
    Stop-ScheduledTask -TaskName `$TaskName
    Write-Host "? Task stopped" -ForegroundColor Green
}
elseif (`$Status) {
    Write-Host "?? ECRR Compliance Monitoring Task Status" -ForegroundColor Cyan
    `$task = Get-ScheduledTask -TaskName `$TaskName
    `$info = Get-ScheduledTaskInfo -TaskName `$TaskName
    Write-Host "   State: `$(`$task.State)" -ForegroundColor White
    Write-Host "   Last Run: `$(`$info.LastRunTime)" -ForegroundColor White
    Write-Host "   Next Run: `$(`$info.NextRunTime)" -ForegroundColor White
    Write-Host "   Last Result: `$(`$info.LastTaskResult)" -ForegroundColor White
}
elseif (`$RunNow) {
    Write-Host "?? Running ECRR Compliance Monitoring Now" -ForegroundColor Green
    Start-ScheduledTask -TaskName `$TaskName
    Start-Sleep -Seconds 5
    `$info = Get-ScheduledTaskInfo -TaskName `$TaskName
    Write-Host "   Last Run: `$(`$info.LastRunTime)" -ForegroundColor White
    Write-Host "   Result: `$(`$info.LastTaskResult)" -ForegroundColor White
}
elseif (`$Logs) {
    Write-Host "?? Recent Compliance Log Entries" -ForegroundColor Cyan
    `$logFile = 'C:/logs/ecrr/compliance-trends.log'
    if (Test-Path `$logFile) {
        Get-Content `$logFile -Tail 5 | ForEach-Object { Write-Host "   `$_" -ForegroundColor White }
    } else {
        Write-Host "   Log file not found: `$logFile" -ForegroundColor Yellow
    }
}
else {
    Write-Host "ECRR Compliance Task Management" -ForegroundColor Cyan
    Write-Host "Usage:" -ForegroundColor White
    Write-Host "  -Start    : Start the scheduled task" -ForegroundColor White
    Write-Host "  -Stop     : Stop the scheduled task" -ForegroundColor White
    Write-Host "  -Status   : Show task status" -ForegroundColor White
    Write-Host "  -RunNow   : Run the task immediately" -ForegroundColor White
    Write-Host "  -Logs     : Show recent log entries" -ForegroundColor White
}
"@

    $managementDirectory = Split-Path -Parent $managementPath
    if (-not (Test-Path $managementDirectory)) {
        New-Item -Path $managementDirectory -ItemType Directory -Force | Out-Null
    }

    $scriptContent | Set-Content -Path $managementPath -Encoding UTF8
    Write-Host "?? Task management script saved: $managementPath" -ForegroundColor Green
}

try {
    Write-Host "?? Starting ECRR compliance monitoring task setup..." -ForegroundColor Green
    
    if ($CreateTask) {
        $created = New-ComplianceMonitoringTask -Name $TaskName -Script $ScriptPath -Interval $IntervalMinutes -BaseDirectory $WorkingDirectory
        if ($created) {
            New-TaskManagementScript -BaseDirectory $script:RepoRoot -Task $TaskName
        }
    }
    elseif ($RemoveTask) {
        Remove-ComplianceMonitoringTask -Name $TaskName
    }
    elseif ($ListTasks) {
        Get-ComplianceMonitoringTasks | Out-Null
    }
    elseif ($TestTask) {
        Test-ComplianceMonitoringTask -Name $TaskName -BaseDirectory $WorkingDirectory | Out-Null
    }
    else {
        Write-Host "?? Available Operations:" -ForegroundColor Cyan
        Write-Host "   -CreateTask  : Create scheduled task (every $IntervalMinutes minutes)" -ForegroundColor White
        Write-Host "   -RemoveTask  : Remove scheduled task" -ForegroundColor White
        Write-Host "   -ListTasks   : List ECRR compliance tasks" -ForegroundColor White
        Write-Host "   -TestTask    : Test task execution and status" -ForegroundColor White
        Write-Host ""
        Write-Host ("Example: pwsh -File scripts/setup-compliance-scheduler.ps1 -CreateTask -WorkingDirectory `"{0}`"" -f $script:RepoRoot) -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "?? Task Scheduler Setup Complete!" -ForegroundColor Green
    
    exit 0
    
} catch {
    Write-Error "Task scheduler setup failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}

