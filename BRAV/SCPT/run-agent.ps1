# Cursor-Assistant Agent Runner
# This script bootstraps and runs the Cursor-Assistant agent

param(
    [string]$Mode = "interactive",
    [switch]$ProcessQueue,
    [switch]$HealthCheck,
    [string]$ConfigPath = ".agent/config.json"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    
    # Also log to file
    $logFile = ".agent/logs/agent-runner-$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logMessage
}

# Function to check if agent is locked
function Test-AgentLocked {
    return Test-Path ".agent/LOCK"
}

# Function to load agent configuration
function Get-AgentConfig {
    if (-not (Test-Path $ConfigPath)) {
        Write-Log "Configuration file not found: $ConfigPath" "ERROR"
        return $null
    }
    
    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Log "Failed to parse configuration: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Function to process job queue
function Process-JobQueue {
    param([object]$Config)
    
    $queueFile = ".agent/agent_queue.json"
    if (-not (Test-Path $queueFile)) {
        Write-Log "Job queue file not found: $queueFile" "WARN"
        return
    }
    
    try {
        $queue = Get-Content $queueFile | ConvertFrom-Json
        if ($queue.Count -eq 0) {
            Write-Log "Job queue is empty" "INFO"
            return
        }
        
        Write-Log "Processing $($queue.Count) jobs from queue" "INFO"
        
        # Process jobs (implementation depends on specific job types)
        foreach ($job in $queue) {
            Write-Log "Processing job: $($job.id)" "INFO"
            # Job processing logic would go here
        }
    }
    catch {
        Write-Log "Failed to process job queue: $($_.Exception.Message)" "ERROR"
    }
}

# Function to perform health check
function Test-AgentHealth {
    Write-Log "Performing agent health check" "INFO"
    
    $healthStatus = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "healthy"
        checks = @()
    }
    
    # Check if agent is locked
    if (Test-AgentLocked) {
        $healthStatus.status = "locked"
        $healthStatus.checks += @{ name = "lock_check"; status = "locked"; message = "Agent is locked" }
    } else {
        $healthStatus.checks += @{ name = "lock_check"; status = "ok"; message = "Agent is not locked" }
    }
    
    # Check configuration
    $config = Get-AgentConfig
    if ($config) {
        $healthStatus.checks += @{ name = "config_check"; status = "ok"; message = "Configuration loaded successfully" }
    } else {
        $healthStatus.status = "unhealthy"
        $healthStatus.checks += @{ name = "config_check"; status = "error"; message = "Failed to load configuration" }
    }
    
    # Check directories
    $requiredDirs = @(".agent", ".agent/logs", ".agent/reports")
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            $healthStatus.checks += @{ name = "dir_check_$dir"; status = "ok"; message = "Directory exists: $dir" }
        } else {
            $healthStatus.status = "unhealthy"
            $healthStatus.checks += @{ name = "dir_check_$dir"; status = "error"; message = "Directory missing: $dir" }
        }
    }
    
    # Save health report
    $healthFile = ".agent/reports/health-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $healthStatus | ConvertTo-Json -Depth 3 | Out-File -FilePath $healthFile -Encoding UTF8
    
    Write-Log "Health check completed. Status: $($healthStatus.status)" "INFO"
    return $healthStatus
}

# Main execution
try {
    Write-Log "Starting Cursor-Assistant Agent Runner" "INFO"
    Write-Log "Mode: $Mode" "INFO"
    
    # Check if agent is locked
    if (Test-AgentLocked) {
        Write-Log "Agent is locked. Exiting." "WARN"
        exit 1
    }
    
    # Load configuration
    $config = Get-AgentConfig
    if (-not $config) {
        Write-Log "Failed to load configuration. Exiting." "ERROR"
        exit 1
    }
    
    # Execute based on mode
    switch ($Mode.ToLower()) {
        "interactive" {
            Write-Log "Interactive mode - agent ready for commands" "INFO"
            Write-Host "Cursor-Assistant Agent is ready. Use Ctrl+C to exit."
            # Interactive mode would wait for commands here
        }
        "queue" {
            Process-JobQueue -Config $config
        }
        "health" {
            $health = Test-AgentHealth
            if ($health.status -ne "healthy") {
                exit 1
            }
        }
        default {
            Write-Log "Unknown mode: $Mode" "ERROR"
            exit 1
        }
    }
    
    Write-Log "Agent runner completed successfully" "INFO"
}
catch {
    Write-Log "Agent runner failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

