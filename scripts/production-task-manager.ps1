# Production Task Manager
# Orchestrates automated task processing for production operations

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "process", "monitor", "stop", "status", "health")]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrentTasks = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$ProcessingInterval = 300,
    
    [Parameter(Mandatory=$false)]
    [switch]$Background,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "logs/production-task-manager.log"
)

$TaskQueueDir = ".agent\task_queue\unified"
$CompletedDir = ".agent\task_queue\completed"
$LogDir = Split-Path $LogPath -Parent
$PidFile = ".agent/production-task-manager.pid"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output
    Write-Host $logMessage
    
    # File output
    if ($LogPath) {
        if (-not (Test-Path $LogDir)) {
            New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        }
        $logMessage | Out-File $LogPath -Append -Encoding utf8
    }
}

function Get-HighPriorityTasks {
    $tasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "pending" -and $content.priority -eq "H"
    } | Sort-Object { 
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        try {
            [DateTime]::Parse($content.created_at)
        } catch {
            [DateTime]::MinValue
        }
    }
    
    return $tasks
}

function Get-MediumPriorityTasks {
    $tasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "pending" -and $content.priority -eq "M"
    } | Sort-Object { 
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        try {
            [DateTime]::Parse($content.created_at)
        } catch {
            [DateTime]::MinValue
        }
    }
    
    return $tasks
}

function Get-LowPriorityTasks {
    $tasks = Get-ChildItem $TaskQueueDir -Filter "*.json" | Where-Object {
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        $content.status -eq "pending" -and $content.priority -eq "L"
    } | Sort-Object { 
        $content = Get-Content $_.FullName -Raw | ConvertFrom-Json
        try {
            [DateTime]::Parse($content.created_at)
        } catch {
            [DateTime]::MinValue
        }
    }
    
    return $tasks
}

function Process-TaskBatch {
    param([int]$MaxTasks, [string]$PriorityFilter = "H")
    
    $processed = 0
    $failed = 0
    
    # Get tasks by priority
    $tasks = switch ($PriorityFilter) {
        "H" { Get-HighPriorityTasks }
        "M" { Get-MediumPriorityTasks }
        "L" { Get-LowPriorityTasks }
        default { Get-HighPriorityTasks + Get-MediumPriorityTasks + Get-LowPriorityTasks }
    }
    
    $tasksToProcess = $tasks | Select-Object -First $MaxTasks
    
    Write-Log "Processing $($tasksToProcess.Count) $PriorityFilter-priority tasks"
    
    foreach ($task in $tasksToProcess) {
        try {
            $taskContent = Get-Content $task.FullName -Raw | ConvertFrom-Json
            Write-Log "Processing task: $($taskContent.id) - $($taskContent.title)"
            
            # Use automated task processor
            $result = pwsh -File scripts/automated-task-processor.ps1 -Action process -TaskId $taskContent.id -Assignee "production-manager" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                $processed++
                Write-Log "Task completed successfully: $($taskContent.id)" "SUCCESS"
            } else {
                $failed++
                Write-Log "Task failed: $($taskContent.id) - $result" "ERROR"
            }
        }
        catch {
            $failed++
            Write-Log "Exception processing task: $($_.Exception.Message)" "ERROR"
        }
        
        # Brief pause between tasks
        Start-Sleep 2
    }
    
    Write-Log "Batch processing completed: $processed successful, $failed failed"
    return @{ processed = $processed; failed = $failed }
}

function Start-ProductionManager {
    Write-Log "Starting production task manager"
    
    # Check if already running
    if (Test-Path $PidFile) {
        $existingPid = Get-Content $PidFile
        if (Get-Process -Id $existingPid -ErrorAction SilentlyContinue) {
            Write-Log "Production task manager already running (PID: $existingPid)" "WARNING"
            return
        } else {
            Remove-Item $PidFile -Force
        }
    }
    
    # Create PID file
    $PID | Out-File $PidFile -Encoding utf8
    
    # Start background monitoring
    if ($Background) {
        Write-Log "Starting background production monitoring"
        Start-Job -ScriptBlock {
            param($Interval, $MaxTasks, $LogPath)
            
            while ($true) {
                try {
                    # Process high-priority tasks
                    $highResult = pwsh -File scripts/production-task-manager.ps1 -Action process -MaxConcurrentTasks $MaxTasks -LogPath $LogPath
                    
                    # Generate status report
                    pwsh -File scripts/cross-system-monitor.ps1 -Action status -LogPath $LogPath
                    
                    # Check for alerts
                    pwsh -File scripts/cross-system-alerts.ps1 -Action monitor -LogPath $LogPath
                    
                    Start-Sleep $Interval
                }
                catch {
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    "[$timestamp] [ERROR] Background monitoring error: $($_.Exception.Message)" | Out-File $LogPath -Append -Encoding utf8
                    Start-Sleep 60
                }
            }
        } -ArgumentList $ProcessingInterval, $MaxConcurrentTasks, $LogPath
        
        Write-Log "Background production monitoring started"
    } else {
        Write-Log "Production task manager started in foreground mode"
    }
}

function Stop-ProductionManager {
    Write-Log "Stopping production task manager"
    
    if (Test-Path $PidFile) {
        $processId = Get-Content $PidFile
        try {
            Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
            Write-Log "Production task manager stopped (PID: $processId)"
        }
        catch {
            Write-Log "Failed to stop production task manager: $($_.Exception.Message)" "ERROR"
        }
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    } else {
        Write-Log "Production task manager not running"
    }
    
    # Stop background jobs
    Get-Job | Where-Object { $_.Name -like "*production*" } | Stop-Job
    Get-Job | Where-Object { $_.Name -like "*production*" } | Remove-Job
}

function Get-ProductionStatus {
    $status = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        manager = @{
            running = $false
            pid = $null
            background_jobs = 0
        }
        tasks = @{
            high_priority = 0
            medium_priority = 0
            low_priority = 0
            total_pending = 0
            total_completed = 0
        }
        processing = @{
            last_processed = $null
            success_rate = 0
            average_time = 0
        }
        health = @{
            ecrr_system = "unknown"
            agent_system = "unknown"
            bridge_system = "unknown"
        }
    }
    
    # Check manager status
    if (Test-Path $PidFile) {
        $processId = Get-Content $PidFile
        if (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
            $status.manager.running = $true
            $status.manager.pid = $processId
        }
    }
    
    # Count background jobs
    $status.manager.background_jobs = (Get-Job | Where-Object { $_.Name -like "*production*" }).Count
    
    # Count tasks by priority
    $status.tasks.high_priority = (Get-HighPriorityTasks).Count
    $status.tasks.medium_priority = (Get-MediumPriorityTasks).Count
    $status.tasks.low_priority = (Get-LowPriorityTasks).Count
    $status.tasks.total_pending = $status.tasks.high_priority + $status.tasks.medium_priority + $status.tasks.low_priority
    
    if (Test-Path $CompletedDir) {
        $status.tasks.total_completed = (Get-ChildItem $CompletedDir -Filter "*.json").Count
    }
    
    # Check system health
    try {
        $ecrrStatus = pwsh -File scripts/ecrr-command.ps1 -Action status 2>&1
        $status.health.ecrr_system = if ($LASTEXITCODE -eq 0) { "healthy" } else { "degraded" }
    }
    catch {
        $status.health.ecrr_system = "error"
    }
    
    $status.health.agent_system = if (Test-Path $TaskQueueDir) { "healthy" } else { "error" }
    $status.health.bridge_system = if ((Test-Path "scripts/ecrr-to-agent.ps1") -and (Test-Path ".agent/scripts/agent-to-ecrr.ps1")) { "healthy" } else { "error" }
    
    return $status
}

function Show-ProductionDashboard {
    $status = Get-ProductionStatus
    
    Write-Host "`n" -NoNewline
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                 Production Task Manager                      ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Manager Status
    $managerColor = if ($status.manager.running) { "Green" } else { "Red" }
    Write-Host "║ Manager Status: " -NoNewline -ForegroundColor White
    Write-Host "$(if ($status.manager.running) { 'RUNNING' } else { 'STOPPED' })" -NoNewline -ForegroundColor $managerColor
    if ($status.manager.pid) {
        Write-Host " (PID: $($status.manager.pid))" -ForegroundColor White
    } else {
        Write-Host "" -ForegroundColor White
    }
    Write-Host "║ Background Jobs: $($status.manager.background_jobs)" -ForegroundColor Gray
    
    # Task Status
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║ Task Queue Status:" -ForegroundColor White
    Write-Host "║   High Priority: $($status.tasks.high_priority)" -ForegroundColor Red
    Write-Host "║   Medium Priority: $($status.tasks.medium_priority)" -ForegroundColor Yellow
    Write-Host "║   Low Priority: $($status.tasks.low_priority)" -ForegroundColor Green
    Write-Host "║   Total Pending: $($status.tasks.total_pending)" -ForegroundColor White
    Write-Host "║   Total Completed: $($status.tasks.total_completed)" -ForegroundColor Cyan
    
    # System Health
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║ System Health:" -ForegroundColor White
    $ecrrColor = switch ($status.health.ecrr_system) { "healthy" { "Green" } "degraded" { "Yellow" } default { "Red" } }
    Write-Host "║   ECRR System: " -NoNewline -ForegroundColor White
    Write-Host "$($status.health.ecrr_system.ToUpper())" -ForegroundColor $ecrrColor
    
    $agentColor = switch ($status.health.agent_system) { "healthy" { "Green" } default { "Red" } }
    Write-Host "║   Agent System: " -NoNewline -ForegroundColor White
    Write-Host "$($status.health.agent_system.ToUpper())" -ForegroundColor $agentColor
    
    $bridgeColor = switch ($status.health.bridge_system) { "healthy" { "Green" } default { "Red" } }
    Write-Host "║   Bridge System: " -NoNewline -ForegroundColor White
    Write-Host "$($status.health.bridge_system.ToUpper())" -ForegroundColor $bridgeColor
    
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    Write-Host "║ Quick Actions:" -ForegroundColor White
    Write-Host "║   Start: pwsh -File scripts/production-task-manager.ps1 -Action start" -ForegroundColor Gray
    Write-Host "║   Process: pwsh -File scripts/production-task-manager.ps1 -Action process" -ForegroundColor Gray
    Write-Host "║   Monitor: pwsh -File scripts/production-task-manager.ps1 -Action monitor" -ForegroundColor Gray
    Write-Host "║   Stop: pwsh -File scripts/production-task-manager.ps1 -Action stop" -ForegroundColor Gray
    
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Monitor-Production {
    Write-Log "Starting production monitoring"
    
    do {
        $status = Get-ProductionStatus
        
        # Process high-priority tasks if manager is running
        if ($status.manager.running) {
            $result = Process-TaskBatch -MaxTasks $MaxConcurrentTasks -PriorityFilter "H"
            
            if ($result.processed -gt 0) {
                Write-Log "Processed $($result.processed) high-priority tasks"
            }
        }
        
        # Show status
        Show-ProductionDashboard
        
        # Check for alerts
        pwsh -File scripts/cross-system-alerts.ps1 -Action monitor
        
        Write-Host "`nWaiting $ProcessingInterval seconds for next cycle..." -ForegroundColor Gray
        Start-Sleep $ProcessingInterval
        
    } while ($true)
}

# Main execution
Write-Log "Production Task Manager"
Write-Log "Action: $Action, MaxConcurrentTasks: $MaxConcurrentTasks, ProcessingInterval: $ProcessingInterval, Background: $Background"

switch ($Action) {
    "start" {
        Start-ProductionManager
    }
    "process" {
        $result = Process-TaskBatch -MaxTasks $MaxConcurrentTasks
        Write-Log "Processing completed: $($result.processed) successful, $($result.failed) failed"
    }
    "monitor" {
        Monitor-Production
    }
    "stop" {
        Stop-ProductionManager
    }
    "status" {
        $status = Get-ProductionStatus
        $status | ConvertTo-Json -Depth 10 | Out-File "artifacts/production-status.json" -Encoding utf8
        Show-ProductionDashboard
        Write-Log "Production status saved to artifacts/production-status.json"
    }
    "health" {
        $status = Get-ProductionStatus
        $healthScore = 0
        if ($status.health.ecrr_system -eq "healthy") { $healthScore += 33 }
        if ($status.health.agent_system -eq "healthy") { $healthScore += 33 }
        if ($status.health.bridge_system -eq "healthy") { $healthScore += 34 }
        
        Write-Log "Production health score: $healthScore/100"
        if ($healthScore -lt 67) {
            Write-Log "Production health degraded - investigation required" "WARNING"
        }
    }
    default {
        Write-Log "Unknown action: $Action" "ERROR"
        exit 1
    }
}

Write-Log "Production task manager operation completed"
