# scripts/agent/watchdog-enhanced.ps1
# codex-local Local Workflow Custodian - Enhanced background watchdog with progress indicators
# This script runs the operational loop for continuous local upkeep with visual progress

[CmdletBinding()]
param(
    [switch]$Detached,
    [int]$MaxCycles = -1,
    [int]$CycleIntervalSeconds = 300
)

$ErrorActionPreference = "Stop"

function Show-CycleProgress {
    param(
        [int]$CycleNumber,
        [int]$TotalCycles,
        [string]$CurrentTask,
        [int]$TaskProgress = 0,
        [int]$MaxTasks = 2
    )
    
    $cyclePercent = if ($TotalCycles -gt 0) { ($CycleNumber / $TotalCycles) * 100 } else { 0 }
    $taskPercent = if ($MaxTasks -gt 0) { ($TaskProgress / $MaxTasks) * 100 } else { 0 }
    
    $status = "Cycle $CycleNumber/$TotalCycles - $CurrentTask ($TaskProgress/$MaxTasks tasks)"
    if ($TotalCycles -eq -1) { $status = "Cycle $CycleNumber (continuous) - $CurrentTask ($TaskProgress/$MaxTasks tasks)" }
    
    Write-Progress -Activity "codex-local Watchdog" -Status $status -PercentComplete $taskPercent -Id 1
}

function Show-SleepProgress {
    param(
        [int]$Seconds,
        [string]$Reason = "Waiting"
    )
    
    for ($i = 0; $i -le ($Seconds * 2); $i++) {
        $percent = ($i / ($Seconds * 2)) * 100
        $remaining = [Math]::Max(0, $Seconds - ($i * 0.5))
        $status = "$Reason - Next cycle in $([Math]::Round($remaining, 1))s"
        
        Write-Progress -Activity "codex-local Watchdog" -Status $status -PercentComplete $percent -Id 2
        Start-Sleep -Milliseconds 500
    }
    Write-Progress -Activity "codex-local Watchdog" -Completed -Id 2
}

Write-Host "[watchdog] codex-local Local Workflow Custodian - Enhanced Background Watchdog" -ForegroundColor Cyan
Write-Host "[watchdog] ========================================================================" -ForegroundColor Cyan

# Load configuration
$configPath = ".agent/config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "[watchdog] ✗ Configuration file not found: $configPath" -ForegroundColor Red
    Write-Host "[watchdog] Run 'pnpm setup-local' first to initialize the agent" -ForegroundColor Yellow
    exit 1
}

try {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $cycleInterval = if ($config.watchdog.cycle_interval_seconds) { $config.watchdog.cycle_interval_seconds } else { $CycleIntervalSeconds }
    $maxTasksPerCycle = if ($config.watchdog.max_tasks_per_cycle) { $config.watchdog.max_tasks_per_cycle } else { 2 }
    $lockCheckInterval = if ($config.watchdog.lock_check_interval_seconds) { $config.watchdog.lock_check_interval_seconds } else { 30 }
} catch {
    Write-Host "[watchdog] ⚠ Error reading configuration, using defaults" -ForegroundColor Yellow
    $cycleInterval = $CycleIntervalSeconds
    $maxTasksPerCycle = 2
    $lockCheckInterval = 30
}

Write-Host "[watchdog] Configuration loaded:" -ForegroundColor Yellow
Write-Host "[watchdog]   Cycle interval: $cycleInterval seconds" -ForegroundColor White
Write-Host "[watchdog]   Max tasks per cycle: $maxTasksPerCycle" -ForegroundColor White
Write-Host "[watchdog]   Lock check interval: $lockCheckInterval seconds" -ForegroundColor White

# Initialize cycle tracking
$cycleCount = 0
$startTime = Get-Date
$lastLockCheck = Get-Date

Write-Host "[watchdog] Starting enhanced watchdog loop with progress indicators..." -ForegroundColor Green
Write-Host "[watchdog] Press Ctrl+C to stop" -ForegroundColor Yellow

# Main watchdog loop
try {
    while ($MaxCycles -eq -1 -or $cycleCount -lt $MaxCycles) {
        $cycleCount++
        $cycleStartTime = Get-Date
        
        Write-Host "[watchdog] ================================================================" -ForegroundColor Cyan
        Write-Host "[watchdog] CYCLE #$cycleCount - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "[watchdog] ================================================================" -ForegroundColor Cyan
        
        # 1. Check for .agent/LOCK kill-switch
        Show-CycleProgress -CycleNumber $cycleCount -TotalCycles $MaxCycles -CurrentTask "Checking lock file" -TaskProgress 0 -MaxTasks $maxTasksPerCycle
        
        $lockPath = ".agent/LOCK"
        if (Test-Path $lockPath) {
            Write-Host "[watchdog] ✗ Agent is LOCKED. Pausing operations." -ForegroundColor Red
            Write-Host "[watchdog] Lock file found at: $lockPath" -ForegroundColor Yellow
            
            # Update status to paused
            try {
                pwsh -File scripts/agent/update-status.ps1 -section env -ok $false -detail "paused:lock"
            } catch {
                Write-Host "[watchdog] ⚠ Status update failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
            
            # Log pause
            $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Watchdog paused due to lock file"
            if (Test-Path "TASKS.md") {
                $logEntry | Add-Content "TASKS.md"
            }
            
            Write-Host "[watchdog] Waiting for lock to be removed..." -ForegroundColor Yellow
            Show-SleepProgress -Seconds $lockCheckInterval -Reason "Agent locked - waiting"
            continue
        }
        
        Write-Host "[watchdog] ✓ No lock file detected, proceeding with cycle..." -ForegroundColor Green
        
        # 2. Run environment doctor checks
        Show-CycleProgress -CycleNumber $cycleCount -TotalCycles $MaxCycles -CurrentTask "Running health diagnostics" -TaskProgress 1 -MaxTasks $maxTasksPerCycle
        
        Write-Host "[watchdog] Running environment health check..." -ForegroundColor Yellow
        try {
            $doctorStartTime = Get-Date
            $doctorJob = Start-Job -ScriptBlock { 
                Set-Location $using:PWD
                pwsh -File scripts/agent/doctor.ps1 2>&1
            }
            
            # Show progress while doctor runs
            while ($doctorJob.State -eq "Running") {
                $elapsed = (Get-Date) - $doctorStartTime
                $estimated = [TimeSpan]::FromSeconds(30)
                $percent = [Math]::Min(($elapsed.TotalSeconds / $estimated.TotalSeconds) * 100, 95)
                $remaining = [Math]::Max(0, $estimated.TotalSeconds - $elapsed.TotalSeconds)
                
                Write-Progress -Activity "Health Diagnostics" -Status "Running health check (ETA: $([Math]::Round($remaining, 1))s)" -PercentComplete $percent -Id 3
                Start-Sleep -Milliseconds 500
            }
            Write-Progress -Activity "Health Diagnostics" -Completed -Id 3
            
            $doctorResult = Receive-Job $doctorJob
            Remove-Job $doctorJob
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[watchdog] ✓ Environment health check passed" -ForegroundColor Green
            } else {
                Write-Host "[watchdog] ✗ Environment health check failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "[watchdog] ⚠ Environment health check error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 3. Process queued micro-tasks
        Show-CycleProgress -CycleNumber $cycleCount -TotalCycles $MaxCycles -CurrentTask "Processing micro-tasks" -TaskProgress 2 -MaxTasks $maxTasksPerCycle
        
        Write-Host "[watchdog] Processing queued micro-tasks..." -ForegroundColor Yellow
        $tasksProcessed = 0
        
        try {
            $queuePath = ".agent/agent_queue.json"
            if (Test-Path $queuePath) {
                $queue = Get-Content $queuePath -Raw | ConvertFrom-Json
                $availableTasks = $queue.jobs | Where-Object { $_.status -eq "queued" -and $_.attempts -lt $_.maxAttempts }
                
                Write-Host "[watchdog] Found $($availableTasks.Count) available tasks" -ForegroundColor White
                
                $taskIndex = 0
                foreach ($task in $availableTasks | Select-Object -First $maxTasksPerCycle) {
                    $taskIndex++
                    Write-Host "[watchdog] Processing task $taskIndex/$maxTasksPerCycle: $($task.id)" -ForegroundColor Yellow
                    
                    try {
                        # Execute the task command with progress
                        $taskStartTime = Get-Date
                        $taskJob = Start-Job -ScriptBlock { 
                            Set-Location $using:PWD
                            Invoke-Expression $using:task.command 2>&1
                        }
                        
                        # Show task progress
                        while ($taskJob.State -eq "Running") {
                            $elapsed = (Get-Date) - $taskStartTime
                            $estimated = [TimeSpan]::FromSeconds(15)
                            $percent = [Math]::Min(($elapsed.TotalSeconds / $estimated.TotalSeconds) * 100, 95)
                            $remaining = [Math]::Max(0, $estimated.TotalSeconds - $elapsed.TotalSeconds)
                            
                            Write-Progress -Activity "Task Processing" -Status "Running $($task.id) (ETA: $([Math]::Round($remaining, 1))s)" -PercentComplete $percent -Id 4
                            Start-Sleep -Milliseconds 500
                        }
                        Write-Progress -Activity "Task Processing" -Completed -Id 4
                        
                        $taskResult = Receive-Job $taskJob
                        Remove-Job $taskJob
                        $taskEndTime = Get-Date
                        $taskDuration = ($taskEndTime - $taskStartTime).TotalSeconds
                        
                        # Update task status
                        $task.status = "completed"
                        $task.lastResult = @{
                            success = $true
                            completedAt = $taskEndTime.ToString("o")
                            duration = $taskDuration
                            exitCode = $LASTEXITCODE
                        }
                        $task.attempts++
                        
                        Write-Host "[watchdog] ✓ Task $($task.id) completed in $([math]::Round($taskDuration, 2))s" -ForegroundColor Green
                        $tasksProcessed++
                        
                        # Log task completion
                        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Task completed: $($task.id) (${taskDuration}s)"
                        if (Test-Path "TASKS.md") {
                            $logEntry | Add-Content "TASKS.md"
                        }
                        
                    } catch {
                        Write-Host "[watchdog] ✗ Task $($task.id) failed: $($_.Exception.Message)" -ForegroundColor Red
                        
                        # Update task with failure
                        $task.attempts++
                        $task.lastResult = @{
                            success = $false
                            failedAt = (Get-Date).ToString("o")
                            error = $_.Exception.Message
                        }
                        
                        if ($task.attempts -ge $task.maxAttempts) {
                            $task.status = "failed"
                            Write-Host "[watchdog] ✗ Task $($task.id) exceeded max attempts, marking as failed" -ForegroundColor Red
                        }
                        
                        # Log task failure
                        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Task failed: $($task.id) (attempt $($task.attempts)/$($task.maxAttempts))"
                        if (Test-Path "TASKS.md") {
                            $logEntry | Add-Content "TASKS.md"
                        }
                    }
                }
                
                # Save updated queue
                ($queue | ConvertTo-Json -Depth 6) | Set-Content $queuePath
                Write-Host "[watchdog] ✓ Processed $tasksProcessed tasks, updated queue" -ForegroundColor Green
            } else {
                Write-Host "[watchdog] ⚠ No task queue found" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "[watchdog] ⚠ Error processing tasks: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 4. Update status
        Show-CycleProgress -CycleNumber $cycleCount -TotalCycles $MaxCycles -CurrentTask "Updating status" -TaskProgress $maxTasksPerCycle -MaxTasks $maxTasksPerCycle
        
        Write-Host "[watchdog] Updating agent status..." -ForegroundColor Yellow
        try {
            $cycleDuration = ((Get-Date) - $cycleStartTime).TotalSeconds
            $statusDetail = "Watchdog running: Cycle #$cycleCount, $tasksProcessed tasks processed, ${cycleDuration}s duration"
            
            pwsh -File scripts/agent/update-status.ps1 -section env -ok $true -detail $statusDetail
            Write-Host "[watchdog] ✓ Status updated" -ForegroundColor Green
        } catch {
            Write-Host "[watchdog] ⚠ Status update failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 5. Log cycle completion
        $cycleEndTime = Get-Date
        $cycleDuration = ($cycleEndTime - $cycleStartTime).TotalSeconds
        $totalDuration = ($cycleEndTime - $startTime).TotalSeconds
        
        Write-Host "[watchdog] ================================================================" -ForegroundColor Cyan
        Write-Host "[watchdog] CYCLE #$cycleCount COMPLETED" -ForegroundColor Cyan
        Write-Host "[watchdog] Cycle duration: $([math]::Round($cycleDuration, 2))s" -ForegroundColor White
        Write-Host "[watchdog] Total uptime: $([math]::Round($totalDuration, 2))s" -ForegroundColor White
        Write-Host "[watchdog] Tasks processed: $tasksProcessed" -ForegroundColor White
        Write-Host "[watchdog] ================================================================" -ForegroundColor Cyan
        
        # Log cycle completion
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Watchdog cycle #$cycleCount completed: $tasksProcessed tasks, ${cycleDuration}s"
        if (Test-Path "TASKS.md") {
            $logEntry | Add-Content "TASKS.md"
        }
        
        # Sleep until next cycle with progress
        if ($MaxCycles -eq -1 -or $cycleCount -lt $MaxCycles) {
            Write-Host "[watchdog] Waiting for next cycle..." -ForegroundColor Yellow
            Show-SleepProgress -Seconds $cycleInterval -Reason "Next cycle in"
        }
    }
    
    Write-Host "[watchdog] ========================================================================" -ForegroundColor Cyan
    Write-Host "[watchdog] Enhanced watchdog completed $cycleCount cycles" -ForegroundColor Green
    Write-Host "[watchdog] Total runtime: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White
    Write-Host "[watchdog] ========================================================================" -ForegroundColor Cyan
    
} catch {
    Write-Host "[watchdog] ✗ Watchdog error: $($_.Exception.Message)" -ForegroundColor Red
    
    # Update status to error
    try {
        pwsh -File scripts/agent/update-status.ps1 -section env -ok $false -detail "error: $($_.Exception.Message)"
    } catch {
        Write-Host "[watchdog] ⚠ Status update failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Log error
    $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') – Watchdog error: $($_.Exception.Message)"
    if (Test-Path "TASKS.md") {
        $logEntry | Add-Content "TASKS.md"
    }
    
    exit 1
} finally {
    # Clean up progress bars
    Write-Progress -Activity "codex-local Watchdog" -Completed -Id 1
    Write-Progress -Activity "codex-local Watchdog" -Completed -Id 2
    Write-Progress -Activity "Health Diagnostics" -Completed -Id 3
    Write-Progress -Activity "Task Processing" -Completed -Id 4
}

Write-Host "[watchdog] Enhanced watchdog shutdown complete" -ForegroundColor Green
