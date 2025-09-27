# Scheduled Automation for Production Operations
# Sets up automated workflows for ongoing production task management

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "start", "stop", "status", "test")]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [int]$TaskGenerationInterval = 3600,  # 1 hour
    
    [Parameter(Mandatory=$false)]
    [int]$TaskProcessingInterval = 1800,  # 30 minutes
    
    [Parameter(Mandatory=$false)]
    [int]$HealthCheckInterval = 300,      # 5 minutes
    
    [Parameter(Mandatory=$false)]
    [string]$ScheduleName = "production-automation"
)

$SchedulesDir = ".agent/schedules"
$LogDir = "logs/scheduled-automation"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    
    # File output
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    $logMessage | Out-File "$LogDir/$ScheduleName.log" -Append -Encoding utf8
}

function Setup-ScheduledTasks {
    Write-Log "Setting up scheduled automation tasks"
    
    # Create schedules directory
    if (-not (Test-Path $SchedulesDir)) {
        New-Item -ItemType Directory -Path $SchedulesDir -Force | Out-Null
    }
    
    # Task Generation Schedule (hourly)
    $taskGenScript = @"
# Automated Task Generation
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Write-Log "Starting scheduled task generation"
try {
    # Generate tasks from ECRR reports
    pwsh -File scripts/cross-system-monitor.ps1 -Action generate
    Write-Log "Scheduled task generation completed successfully"
} catch {
    Write-Log "Scheduled task generation failed: `$(`$_.Exception.Message)" "ERROR"
}
"@
    
    $taskGenScript | Out-File "$SchedulesDir/task-generation.ps1" -Encoding utf8
    
    # Task Processing Schedule (every 30 minutes)
    $taskProcScript = @"
# Automated Task Processing
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Write-Log "Starting scheduled task processing"
try {
    # Process high-priority tasks
    pwsh -File scripts/production-task-manager.ps1 -Action process -MaxConcurrentTasks 2
    Write-Log "Scheduled task processing completed successfully"
} catch {
    Write-Log "Scheduled task processing failed: `$(`$_.Exception.Message)" "ERROR"
}
"@
    
    $taskProcScript | Out-File "$SchedulesDir/task-processing.ps1" -Encoding utf8
    
    # Health Check Schedule (every 5 minutes)
    $healthScript = @"
# Automated Health Check
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Write-Log "Starting scheduled health check"
try {
    # Check system health
    pwsh -File scripts/cross-system-alerts.ps1 -Action monitor
    pwsh -File scripts/production-task-manager.ps1 -Action health
    Write-Log "Scheduled health check completed successfully"
} catch {
    Write-Log "Scheduled health check failed: `$(`$_.Exception.Message)" "ERROR"
}
"@
    
    $healthScript | Out-File "$SchedulesDir/health-check.ps1" -Encoding utf8
    
    # Status Report Schedule (daily at midnight)
    $statusScript = @"
# Daily Status Report
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Write-Log "Starting daily status report"
try {
    # Generate comprehensive status report
    pwsh -File scripts/production-task-manager.ps1 -Action status
    pwsh -File scripts/cross-system-monitor.ps1 -Action status
    pwsh -File scripts/cross-system-alerts.ps1 -Action status
    Write-Log "Daily status report completed successfully"
} catch {
    Write-Log "Daily status report failed: `$(`$_.Exception.Message)" "ERROR"
}
"@
    
    $statusScript | Out-File "$SchedulesDir/daily-status.ps1" -Encoding utf8
    
    Write-Log "Scheduled automation tasks setup completed" "SUCCESS"
}

function Start-ScheduledAutomation {
    Write-Log "Starting scheduled automation"
    
    # Start task generation job (hourly)
    $taskGenJob = Start-Job -Name "TaskGeneration" -ScriptBlock {
        param($ScriptPath, $Interval, $LogPath)
        
        while ($true) {
            try {
                pwsh -File $ScriptPath
                Start-Sleep $Interval
            }
            catch {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                "[$timestamp] [ERROR] Task generation job error: $($_.Exception.Message)" | Out-File $LogPath -Append -Encoding utf8
                Start-Sleep 300
            }
        }
    } -ArgumentList "$SchedulesDir/task-generation.ps1", $TaskGenerationInterval, "$LogDir/$ScheduleName.log"
    
    # Start task processing job (every 30 minutes)
    $taskProcJob = Start-Job -Name "TaskProcessing" -ScriptBlock {
        param($ScriptPath, $Interval, $LogPath)
        
        while ($true) {
            try {
                pwsh -File $ScriptPath
                Start-Sleep $Interval
            }
            catch {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                "[$timestamp] [ERROR] Task processing job error: $($_.Exception.Message)" | Out-File $LogPath -Append -Encoding utf8
                Start-Sleep 300
            }
        }
    } -ArgumentList "$SchedulesDir/task-processing.ps1", $TaskProcessingInterval, "$LogDir/$ScheduleName.log"
    
    # Start health check job (every 5 minutes)
    $healthJob = Start-Job -Name "HealthCheck" -ScriptBlock {
        param($ScriptPath, $Interval, $LogPath)
        
        while ($true) {
            try {
                pwsh -File $ScriptPath
                Start-Sleep $Interval
            }
            catch {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                "[$timestamp] [ERROR] Health check job error: $($_.Exception.Message)" | Out-File $LogPath -Append -Encoding utf8
                Start-Sleep 300
            }
        }
    } -ArgumentList "$SchedulesDir/health-check.ps1", $HealthCheckInterval, "$LogDir/$ScheduleName.log"
    
    Write-Log "Scheduled automation started with 3 background jobs" "SUCCESS"
    Write-Log "Jobs: TaskGeneration, TaskProcessing, HealthCheck"
}

function Stop-ScheduledAutomation {
    Write-Log "Stopping scheduled automation"
    
    # Stop all automation jobs
    $automationJobs = @("TaskGeneration", "TaskProcessing", "HealthCheck")
    
    foreach ($jobName in $automationJobs) {
        $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
        if ($job) {
            Stop-Job -Name $jobName
            Remove-Job -Name $jobName
            Write-Log "Stopped job: $jobName"
        }
    }
    
    Write-Log "Scheduled automation stopped" "SUCCESS"
}

function Get-ScheduledStatus {
    $status = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        jobs = @{}
        schedules = @{
            task_generation = @{
                enabled = $false
                interval = $TaskGenerationInterval
                script = "$SchedulesDir/task-generation.ps1"
            }
            task_processing = @{
                enabled = $false
                interval = $TaskProcessingInterval
                script = "$SchedulesDir/task-processing.ps1"
            }
            health_check = @{
                enabled = $false
                interval = $HealthCheckInterval
                script = "$SchedulesDir/health-check.ps1"
            }
            daily_status = @{
                enabled = $false
                interval = 86400  # 24 hours
                script = "$SchedulesDir/daily-status.ps1"
            }
        }
        automation = @{
            total_jobs = 0
            running_jobs = 0
            failed_jobs = 0
        }
    }
    
    # Check job status
    $jobs = @("TaskGeneration", "TaskProcessing", "HealthCheck")
    $status.automation.total_jobs = $jobs.Count
    
    foreach ($jobName in $jobs) {
        $job = Get-Job -Name $jobName -ErrorAction SilentlyContinue
        if ($job) {
            $status.jobs[$jobName] = @{
                state = $job.State
                running = $job.State -eq "Running"
                failed = $job.State -eq "Failed"
            }
            
            if ($job.State -eq "Running") {
                $status.automation.running_jobs++
            } elseif ($job.State -eq "Failed") {
                $status.automation.failed_jobs++
            }
        } else {
            $status.jobs[$jobName] = @{
                state = "NotRunning"
                running = $false
                failed = $false
            }
        }
    }
    
    # Check schedule files
    foreach ($schedule in $status.schedules.Keys) {
        $scriptPath = $status.schedules[$schedule].script
        $status.schedules[$schedule].enabled = Test-Path $scriptPath
    }
    
    return $status
}

function Test-ScheduledAutomation {
    Write-Log "Testing scheduled automation"
    
    # Test task generation
    Write-Log "Testing task generation..."
    try {
        pwsh -File "$SchedulesDir/task-generation.ps1"
        Write-Log "Task generation test passed" "SUCCESS"
    }
    catch {
        Write-Log "Task generation test failed: $($_.Exception.Message)" "ERROR"
    }
    
    # Test task processing
    Write-Log "Testing task processing..."
    try {
        pwsh -File "$SchedulesDir/task-processing.ps1"
        Write-Log "Task processing test passed" "SUCCESS"
    }
    catch {
        Write-Log "Task processing test failed: $($_.Exception.Message)" "ERROR"
    }
    
    # Test health check
    Write-Log "Testing health check..."
    try {
        pwsh -File "$SchedulesDir/health-check.ps1"
        Write-Log "Health check test passed" "SUCCESS"
    }
    catch {
        Write-Log "Health check test failed: $($_.Exception.Message)" "ERROR"
    }
    
    Write-Log "Scheduled automation testing completed"
}

function Show-ScheduledDashboard {
    $status = Get-ScheduledStatus
    
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                Scheduled Automation Dashboard               ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Job Status
    Write-Host "║ Automation Jobs:" -ForegroundColor White
    Write-Host "║   Total: $($status.automation.total_jobs)" -ForegroundColor Gray
    Write-Host "║   Running: $($status.automation.running_jobs)" -ForegroundColor Green
    Write-Host "║   Failed: $($status.automation.failed_jobs)" -ForegroundColor Red
    
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Individual Job Status
    foreach ($jobName in $status.jobs.Keys) {
        $job = $status.jobs[$jobName]
        $color = switch ($job.state) {
            "Running" { "Green" }
            "Failed" { "Red" }
            default { "Yellow" }
        }
        Write-Host "║ $($jobName): " -NoNewline -ForegroundColor White
        Write-Host "$($job.state.ToUpper())" -ForegroundColor $color
    }
    
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Schedule Status
    Write-Host "║ Schedules:" -ForegroundColor White
    foreach ($scheduleName in $status.schedules.Keys) {
        $schedule = $status.schedules[$scheduleName]
        $color = if ($schedule.enabled) { "Green" } else { "Red" }
        $interval = [math]::Round($schedule.interval / 60, 1)
        Write-Host "║   $($scheduleName): " -NoNewline -ForegroundColor White
        Write-Host "$(if ($schedule.enabled) { 'ENABLED' } else { 'DISABLED' })" -NoNewline -ForegroundColor $color
        Write-Host " (${interval}m)" -ForegroundColor Gray
    }
    
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║ Quick Actions:" -ForegroundColor White
    Write-Host "║   Setup: pwsh -File scripts/scheduled-automation.ps1 -Action setup" -ForegroundColor Gray
    Write-Host "║   Start: pwsh -File scripts/scheduled-automation.ps1 -Action start" -ForegroundColor Gray
    Write-Host "║   Stop: pwsh -File scripts/scheduled-automation.ps1 -Action stop" -ForegroundColor Gray
    Write-Host "║   Test: pwsh -File scripts/scheduled-automation.ps1 -Action test" -ForegroundColor Gray
    
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
Write-Log "Scheduled Automation for Production Operations"
Write-Log "Action: $Action, ScheduleName: $ScheduleName"

switch ($Action) {
    "setup" {
        Setup-ScheduledTasks
    }
    "start" {
        Start-ScheduledAutomation
    }
    "stop" {
        Stop-ScheduledAutomation
    }
    "status" {
        $status = Get-ScheduledStatus
        $status | ConvertTo-Json -Depth 10 | Out-File "artifacts/scheduled-automation-status.json" -Encoding utf8
        Show-ScheduledDashboard
        Write-Log "Scheduled automation status saved to artifacts/scheduled-automation-status.json"
    }
    "test" {
        Test-ScheduledAutomation
    }
    default {
        Write-Log "Unknown action: $Action" "ERROR"
        exit 1
    }
}

Write-Log "Scheduled automation operation completed"
