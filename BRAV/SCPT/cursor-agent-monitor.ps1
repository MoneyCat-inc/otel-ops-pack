#!/usr/bin/env pwsh
# cursor-agent-monitor.ps1
# Continuous monitoring and automated task processing for Cursor agent

param(
    [switch]$StartMonitoring,
    [switch]$StopMonitoring,
    [switch]$Status,
    [int]$IntervalMinutes = 15,
    [switch]$Verbose
)

$AgentDir = ".agent"
$ConfigFile = "$AgentDir/config.json"
$StateFile = "$AgentDir/state.json"
$QueueFile = "$AgentDir/task_queue.json"
$LockFile = "$AgentDir/LOCK"
$MonitorPidFile = "$AgentDir/monitor.pid"
$ReportsDir = "CHAR/ECRR/ECRR_REPORTS"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-VerboseOutput {
    param([string]$Message)
    if ($Verbose) {
        Write-ColorOutput "🔍 $Message" "Gray"
    }
}

function Get-MonitorStatus {
    if (Test-Path $MonitorPidFile) {
        $monitorPid = Get-Content $MonitorPidFile -ErrorAction SilentlyContinue
        if ($monitorPid) {
            $process = Get-Process -Id $monitorPid -ErrorAction SilentlyContinue
            if ($process) {
                return @{
                    IsRunning = $true
                    Pid = $monitorPid
                    Process = $process
                }
            }
        }
    }
    return @{ IsRunning = $false }
}

function Start-Monitoring {
    $status = Get-MonitorStatus
    if ($status.IsRunning) {
        Write-ColorOutput "⚠️ Monitor is already running (PID: $($status.Pid))" "Yellow"
        return
    }

    Write-ColorOutput "🚀 Starting Cursor Agent Monitor..." "Cyan"
    Write-ColorOutput "   Interval: $IntervalMinutes minutes" "Gray"
    Write-ColorOutput "   Queue: $QueueFile" "Gray"
    Write-ColorOutput "   Reports: $ReportsDir" "Gray"

    # Create monitoring script
    $monitorScript = @"
# Auto-generated monitor script
while (`$true) {
    try {
        # Check for lock file
        if (Test-Path "$LockFile") {
            Write-VerboseOutput "Agent locked, skipping cycle"
            Start-Sleep 60
            continue
        }

        # Get task queue
        `$queue = Get-Content "$QueueFile" -ErrorAction SilentlyContinue | ConvertFrom-Json
        if (`$queue -and `$queue.Count -gt 0) {
            Write-ColorOutput "📋 Found `$(`$queue.Count) tasks in queue" "Cyan"
            
            # Process highest priority task
            `$nextTask = `$queue | Sort-Object priority -Descending | Select-Object -First 1
            
            Write-ColorOutput "🎯 Processing: `$(`$nextTask.id) (Priority: `$(`$nextTask.priority))" "Yellow"
            
            # Execute task processing
            `$result = & pwsh -File "scripts/cursor-agent-processor.ps1" -TaskId `$nextTask.id
            
            if (`$LASTEXITCODE -eq 0) {
                Write-ColorOutput "✅ Task completed successfully" "Green"
            } else {
                Write-ColorOutput "❌ Task failed" "Red"
            }
        } else {
            Write-VerboseOutput "No tasks in queue"
        }
        
        # Wait for next cycle
        Start-Sleep ($IntervalMinutes * 60)
    } catch {
        Write-ColorOutput "❌ Monitor error: `$(`$_.Exception.Message)" "Red"
        Start-Sleep 300 # Wait 5 minutes on error
    }
}
"@

    # Save monitor script
    $monitorScriptFile = "$AgentDir/monitor-worker.ps1"
    $monitorScript | Out-File -FilePath $monitorScriptFile -Encoding UTF8

    # Start monitoring in background
    $job = Start-Job -ScriptBlock {
        param($ScriptFile)
        & pwsh -File $ScriptFile
    } -ArgumentList $monitorScriptFile

    # Save PID
    $job.Id | Out-File -FilePath $MonitorPidFile -Encoding UTF8

    Write-ColorOutput "✅ Monitor started successfully (Job ID: $($job.Id))" "Green"
    Write-ColorOutput "   Use -StopMonitoring to stop" "Gray"
}

function Stop-Monitoring {
    $status = Get-MonitorStatus
    if (-not $status.IsRunning) {
        Write-ColorOutput "⚠️ Monitor is not running" "Yellow"
        return
    }

    Write-ColorOutput "🛑 Stopping Cursor Agent Monitor..." "Cyan"
    
    try {
        Stop-Job -Id $status.Pid -ErrorAction SilentlyContinue
        Remove-Job -Id $status.Pid -ErrorAction SilentlyContinue
        Remove-Item $MonitorPidFile -ErrorAction SilentlyContinue
        Remove-Item "$AgentDir/monitor-worker.ps1" -ErrorAction SilentlyContinue
        
        Write-ColorOutput "✅ Monitor stopped successfully" "Green"
    } catch {
        Write-ColorOutput "❌ Error stopping monitor: $($_.Exception.Message)" "Red"
    }
}

function Show-MonitorStatus {
    $status = Get-MonitorStatus
    
    Write-ColorOutput "📊 Cursor Agent Monitor Status" "Cyan"
    Write-ColorOutput ("=" * 40) "Gray"
    
    if ($status.IsRunning) {
        Write-ColorOutput "Status: ✅ Running" "Green"
        Write-ColorOutput "PID: $($status.Pid)" "White"
        Write-ColorOutput "Start Time: $($status.Process.StartTime)" "Gray"
        Write-ColorOutput "Memory: $([math]::Round($status.Process.WorkingSet64 / 1MB, 2)) MB" "Gray"
    } else {
        Write-ColorOutput "Status: ❌ Stopped" "Red"
    }
    
    # Show queue status
    if (Test-Path $QueueFile) {
        $queue = Get-Content $QueueFile | ConvertFrom-Json
        Write-ColorOutput "Queue: $($queue.Count) tasks" "White"
        
        if ($queue.Count -gt 0) {
            $nextTask = $queue | Sort-Object priority -Descending | Select-Object -First 1
            Write-ColorOutput "Next: $($nextTask.id) (Priority: $($nextTask.priority))" "Yellow"
        }
    } else {
        Write-ColorOutput "Queue: No queue file found" "Yellow"
    }
    
    # Show recent reports
    if (Test-Path $ReportsDir) {
        $recentReports = Get-ChildItem $ReportsDir -Filter "*.md" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        Write-ColorOutput "Recent Reports:" "White"
        foreach ($report in $recentReports) {
            Write-ColorOutput "  $($report.Name)" "Gray"
        }
    }
}

function New-MaintenanceTask {
    param(
        [string]$Type,
        [string]$Description,
        [int]$Priority = 5
    )
    
    $taskId = "task-maintenance-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(Get-Random -Maximum 1000)"
    
    $task = @{
        id = $taskId
        type = $Type
        priority = $Priority
        tlMs = 86400000
        maxAttempts = 1
        createdAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        payload = @{
            description = $Description
            files = @()
            requirements = @("Automated maintenance task")
            evidence = "Generated by continuous monitor"
        }
    }
    
    # Add to queue
    if (Test-Path $QueueFile) {
        $queue = Get-Content $QueueFile | ConvertFrom-Json
        $queue += $task
        $queue | ConvertTo-Json -Depth 10 | Set-Content $QueueFile -Encoding UTF8
        Write-ColorOutput "📝 Added maintenance task: $taskId" "Green"
    }
}

# Main execution
if ($StartMonitoring) {
    Start-Monitoring
} elseif ($StopMonitoring) {
    Stop-Monitoring
} elseif ($Status) {
    Show-MonitorStatus
} else {
    Write-ColorOutput "Cursor Agent Monitor" "Cyan"
    Write-ColorOutput "Usage:" "White"
    Write-ColorOutput "  -StartMonitoring    Start continuous monitoring" "Gray"
    Write-ColorOutput "  -StopMonitoring     Stop monitoring" "Gray"
    Write-ColorOutput "  -Status             Show monitor status" "Gray"
    Write-ColorOutput "  -IntervalMinutes    Set monitoring interval (default: 15)" "Gray"
    Write-ColorOutput "  -Verbose            Show detailed output" "Gray"
}

