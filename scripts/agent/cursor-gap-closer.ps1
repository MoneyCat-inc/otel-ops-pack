#!/usr/bin/env pwsh
# cursor-gap-closer agent launcher
# This script starts the cursor-gap-closer agent to process UI/UX and audio tasks

param(
    [switch]$Status,
    [switch]$Stop,
    [switch]$Resume
)

$AgentDir = ".agent"
$ConfigFile = "$AgentDir/config.json"
$StateFile = "$AgentDir/state.json"
$QueueFile = "$AgentDir/agent_queue.json"
$LockFile = "$AgentDir/LOCK"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-AgentStatus {
    if (Test-Path $StateFile) {
        $state = Get-Content $StateFile | ConvertFrom-Json
        Write-ColorOutput "Agent: $($state.agentName)" "Cyan"
        Write-ColorOutput "Status: $($state.status)" "Yellow"
        Write-ColorOutput "Jobs Processed: $($state.jobsProcessed)" "Green"
        Write-ColorOutput "Last Run: $($state.lastRun)" "Gray"
        
        if (Test-Path $LockFile) {
            Write-ColorOutput "⚠️  Agent is LOCKED" "Red"
        } else {
            Write-ColorOutput "✅ Agent is UNLOCKED" "Green"
        }
    } else {
        Write-ColorOutput "❌ Agent state not found" "Red"
    }
}

function Stop-Agent {
    if (-not (Test-Path $AgentDir)) {
        New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null
    }
    
    "Agent stopped at $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')" | Out-File -FilePath $LockFile -Encoding UTF8
    Write-ColorOutput "🛑 Agent stopped (LOCK file created)" "Red"
}

function Resume-Agent {
    if (Test-Path $LockFile) {
        Remove-Item $LockFile -Force
        Write-ColorOutput "▶️  Agent resumed (LOCK file removed)" "Green"
    } else {
        Write-ColorOutput "ℹ️  Agent was not locked" "Yellow"
    }
}

function Start-Agent {
    # Check if agent is locked
    if (Test-Path $LockFile) {
        Write-ColorOutput "❌ Agent is locked. Use -Resume to unlock." "Red"
        return
    }
    
    # Verify configuration files exist
    if (-not (Test-Path $ConfigFile)) {
        Write-ColorOutput "❌ Agent config not found: $ConfigFile" "Red"
        return
    }
    
    if (-not (Test-Path $QueueFile)) {
        Write-ColorOutput "❌ Agent queue not found: $QueueFile" "Red"
        return
    }
    
    # Load configuration
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    $queue = Get-Content $QueueFile | ConvertFrom-Json
    
    Write-ColorOutput "🚀 Starting cursor-gap-closer agent..." "Cyan"
    Write-ColorOutput "Agent: $($config.agentName)" "White"
    Write-ColorOutput "Max Jobs: $($config.maxJobs)" "White"
    Write-ColorOutput "Queue Size: $($queue.Count)" "White"
    
    # Update state
    $state = @{
        lastRun = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        killSwitch = $false
        jobsProcessed = 0
        agentName = $config.agentName
        status = "running"
        lastError = $null
        uptime = 0
    }
    
    $state | ConvertTo-Json | Out-File -FilePath $StateFile -Encoding UTF8
    
    Write-ColorOutput "✅ Agent started successfully!" "Green"
    Write-ColorOutput "📋 Processing tasks from queue..." "Yellow"
    
    # Process high-priority tasks
    $highPriorityTasks = $queue | Where-Object { $_.priority -ge 8 } | Sort-Object priority -Descending
    
    foreach ($task in $highPriorityTasks) {
        Write-ColorOutput "🎯 Processing: $($task.payload.description)" "Cyan"
        Write-ColorOutput "   Type: $($task.type)" "Gray"
        Write-ColorOutput "   Priority: $($task.priority)" "Gray"
        Write-ColorOutput "   Files: $($task.payload.files -join ', ')" "Gray"
        
        # Simulate task processing
        Start-Sleep -Milliseconds 500
        
        $state.jobsProcessed++
        $state | ConvertTo-Json | Out-File -FilePath $StateFile -Encoding UTF8
        
        Write-ColorOutput "   ✅ Task completed" "Green"
    }
    
    Write-ColorOutput "🎉 Agent processing complete!" "Green"
    Write-ColorOutput "📊 Jobs processed: $($state.jobsProcessed)" "White"
}

# Main execution
if ($Status) {
    Get-AgentStatus
} elseif ($Stop) {
    Stop-Agent
} elseif ($Resume) {
    Resume-Agent
} else {
    Start-Agent
}
