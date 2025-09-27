# scripts/agent/watchdog.ps1
# codex-local Local Workflow Custodian - Background watchdog for maintenance micro-tasks
# This script runs the operational loop for continuous local upkeep

[CmdletBinding()]
param(
    [switch]$Detached,
    [int]$MaxCycles = -1,
    [int]$CycleIntervalSeconds = 300
)

$ErrorActionPreference = "Stop"

Write-Host "[watchdog] codex-local Local Workflow Custodian - Background Watchdog" -ForegroundColor Cyan
Write-Host "[watchdog] ==================================================================" -ForegroundColor Cyan

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

Write-Host "[watchdog] Starting watchdog loop..." -ForegroundColor Green
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
            Start-Sleep -Seconds $lockCheckInterval
            continue
        }
        
        Write-Host "[watchdog] ✓ No lock file detected, proceeding with cycle..." -ForegroundColor Green
        
        # 2. Run environment doctor checks (ensure recent and no new issues)
        Write-Host "[watchdog] Running environment health check..." -ForegroundColor Yellow
        try {
            $doctorResult = pwsh -File scripts/agent/doctor.ps1 -ErrorAction Stop
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[watchdog] ✓ Environment health check passed" -ForegroundColor Green
            } else {
                Write-Host "[watchdog] ✗ Environment health check failed" -ForegroundColor Red
                # Continue with cycle but note the issue
            }
        } catch {
            Write-Host "[watchdog] ⚠ Environment health check error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 3. Process queued micro-tasks
        Write-Host "[watchdog] Processing queued micro-tasks..." -ForegroundColor Yellow
        $tasksProcessed = 0
        
        try {
            $queuePath = ".agent/agent_queue.json"
            if (Test-Path $queuePath) {
                $queue = Get-Content $queuePath -Raw | ConvertFrom-Json
                $availableTasks = $queue.jobs | Where-Object { $_.status -eq "queued" -and $_.attempts -lt $_.maxAttempts }
                
                Write-Host "[watchdog] Found $($availableTasks.Count) available tasks" -ForegroundColor White
                
                foreach ($task in $availableTasks | Select-Object -First $maxTasksPerCycle) {
                    Write-Host "[watchdog] Processing task: $($task.id)" -ForegroundColor Yellow
                    
                    try {
                        # Execute the task command
                        $taskStartTime = Get-Date
                        Invoke-Expression $task.command
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
        
        # 4. Enforce guardrails (run security/a11y checks on recent changes)
        Write-Host "[watchdog] Enforcing guardrails..." -ForegroundColor Yellow
        try {
            # Run a quick guardrail check
            $guardrailViolations = 0
            
            # Check for recent file changes that might have introduced violations
            $recentFiles = Get-ChildItem -Recurse -Include "*.html", "*.jsx", "*.tsx", "*.js", "*.ts" | Where-Object { 
                $_.LastWriteTime -gt (Get-Date).AddHours(-1) -and 
                $_.FullName -notmatch "node_modules|\.git|third_party" 
            }
            
            foreach ($file in $recentFiles) {
                $content = Get-Content $file.FullName -Raw
                
                # Check for inline styles
                if ($content -match 'style\s*=\s*["'']') {
                    Write-Host "[watchdog] ⚠ Guardrail violation: Inline style in $($file.Name)" -ForegroundColor Yellow
                    $guardrailViolations++
                }
                
                # Check for dangerouslySetInnerHTML
                if ($content -match 'dangerouslySetInnerHTML') {
                    Write-Host "[watchdog] ⚠ Guardrail violation: dangerouslySetInnerHTML in $($file.Name)" -ForegroundColor Yellow
                    $guardrailViolations++
                }
            }
            
            if ($guardrailViolations -eq 0) {
                Write-Host "[watchdog] ✓ No guardrail violations detected in recent changes" -ForegroundColor Green
            } else {
                Write-Host "[watchdog] ⚠ Found $guardrailViolations guardrail violations in recent changes" -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host "[watchdog] ⚠ Guardrail enforcement error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 5. Update status
        Write-Host "[watchdog] Updating agent status..." -ForegroundColor Yellow
        try {
            $cycleDuration = ((Get-Date) - $cycleStartTime).TotalSeconds
            $statusDetail = "Watchdog running: Cycle #$cycleCount, $tasksProcessed tasks processed, ${cycleDuration}s duration"
            
            pwsh -File scripts/agent/update-status.ps1 -section env -ok $true -detail $statusDetail
            Write-Host "[watchdog] ✓ Status updated" -ForegroundColor Green
        } catch {
            Write-Host "[watchdog] ⚠ Status update failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # 6. Log cycle completion
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
        
        # Sleep until next cycle
        if ($MaxCycles -eq -1 -or $cycleCount -lt $MaxCycles) {
            Write-Host "[watchdog] Sleeping for $cycleInterval seconds until next cycle..." -ForegroundColor Yellow
            Start-Sleep -Seconds $cycleInterval
        }
    }
    
    Write-Host "[watchdog] ==================================================================" -ForegroundColor Cyan
    Write-Host "[watchdog] Watchdog completed $cycleCount cycles" -ForegroundColor Green
    Write-Host "[watchdog] Total runtime: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White
    Write-Host "[watchdog] ==================================================================" -ForegroundColor Cyan
    
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
}

Write-Host "[watchdog] Watchdog shutdown complete" -ForegroundColor Green
