# IONA Agent Runner - Background Execution Engine
# Processes queued agents and enforces budgets and safety controls

param(
    [int]$PollIntervalMs = 5000,
    [switch]$Daemon,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Configuration
$AgentDir = ".agent"
$ArtifactsDir = "artifacts/agents"
$QueueFile = "$AgentDir/iona_queue.json"
$StateFile = "$AgentDir/iona_state.json"
$ConfigFile = "$AgentDir/config.json"
$LockFile = "$AgentDir/LOCK"

function Write-RunnerLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "INFO" { "Green" }
        "DEBUG" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [RUNNER] [$Level] $Message" -ForegroundColor $color
}

function Get-Config {
    if (Test-Path $ConfigFile) {
        return Get-Content $ConfigFile | ConvertFrom-Json
    }
    return @{
        max_jobs_per_run = 3
        max_files_per_job = 15
        max_lines_per_job = 500
        job_ttl_seconds = 86400
        performance = @{
            timeout_seconds = 60
            memory_limit_mb = 512
            parallel_jobs = 2
        }
    }
}

function Get-Queue {
    if (Test-Path $QueueFile) {
        $content = Get-Content $QueueFile | ConvertFrom-Json
        return $content
    }
    return @{
        version = 1
        lastRun = $null
        jobs = @()
    }
}

function Set-Queue {
    param($Queue)
    $Queue | ConvertTo-Json -Depth 10 | Set-Content $QueueFile -Encoding UTF8
}

function Get-State {
    if (Test-Path $StateFile) {
        return Get-Content $StateFile | ConvertFrom-Json
    }
    return @{
        version = 1
        updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")
        runner = @{
            status = "stopped"
            lastHeartbeat = $null
            activeJobs = @()
        }
        statistics = @{
            totalJobs = 0
            successfulJobs = 0
            failedJobs = 0
            terminatedJobs = 0
        }
    }
}

function Set-State {
    param($State)
    if (-not $State.PSObject.Properties['updatedAt']) {
        $State | Add-Member -NotePropertyName 'updatedAt' -NotePropertyValue (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")
    } else {
        $State.updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffffffK")
    }
    
    if (-not $State.runner.PSObject.Properties['lastHeartbeat']) {
        $heartbeat = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $State.runner | Add-Member -NotePropertyName 'lastHeartbeat' -NotePropertyValue $heartbeat
    } else {
        $State.runner.lastHeartbeat = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    }
    
    $State | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8
}

function Test-Lock {
    return Test-Path $LockFile
}

function Invoke-AgentExecution {
    param($Ticket)
    
    $ticketId = $Ticket.id
    $mode = $Ticket.metadata.mode
    $goal = $Ticket.metadata.goal
    
    Write-RunnerLog "Starting agent execution: $ticketId ($mode)" "INFO"
    
    # Create agent output directory
    $agentDir = "$ArtifactsDir/$ticketId"
    if (-not (Test-Path $agentDir)) {
        New-Item -ItemType Directory -Path $agentDir -Force | Out-Null
    }
    
    # Simulate agent execution based on mode
    $outputs = @{
        ticketId = $ticketId
        mode = $mode
        goal = $goal
        executedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        results = @{}
        logs = @()
    }
    
    try {
        switch ($mode) {
            "Companion" {
                $outputs.results = @{
                    response = "Hello! I'm here to help with your $($goal) request."
                    humorEnabled = $Ticket.metadata.guardrails.humorGating
                    tokensUsed = 150
                }
                $outputs.logs += "Companion agent provided conversational assistance"
            }
            
            "Archivist" {
                $outputs.results = @{
                    documentsCreated = 3
                    metadataExtracted = 25
                    format = "markdown"
                    tokensUsed = 800
                }
                $outputs.logs += "Archivist agent generated documentation artifacts"
            }
            
            "Cipher" {
                $outputs.results = @{
                    vulnerabilitiesFound = 0
                    complianceChecks = 12
                    securityScore = 95
                    tokensUsed = 600
                }
                $outputs.logs += "Cipher agent completed security analysis"
            }
            
            "MarketAnalyst" {
                $outputs.results = @{
                    metricsAnalyzed = 8
                    trendsIdentified = 3
                    reportGenerated = $true
                    tokensUsed = 700
                }
                $outputs.logs += "MarketAnalyst agent generated business intelligence report"
            }
            
            "Care" {
                $outputs.results = @{
                    healthChecks = 5
                    issuesFound = 0
                    maintenanceTasks = 2
                    tokensUsed = 300
                }
                $outputs.logs += "Care agent completed health monitoring and maintenance"
            }
            
            default {
                throw "Unknown agent mode: $mode"
            }
        }
        
        # Simulate execution time
        $executionTime = Get-Random -Minimum 1000 -Maximum 5000
        Start-Sleep -Milliseconds $executionTime
        
        # Write outputs
        $outputs | ConvertTo-Json -Depth 10 | Set-Content "$agentDir/output.json" -Encoding UTF8
        
        # Write logs
        $outputs.logs | Set-Content "$agentDir/logs.txt" -Encoding UTF8
        
        Write-RunnerLog "Agent execution completed: $ticketId" "INFO"
        return @{
            success = $true
            outputs = $outputs
        }
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-RunnerLog "Agent execution failed: $ticketId - $errorMsg" "ERROR"
        
        # Write error outputs
        $errorOutputs = @{
            ticketId = $ticketId
            mode = $mode
            goal = $goal
            executedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            error = $errorMsg
            logs = @("Agent execution failed: $errorMsg")
        }
        
        $errorOutputs | ConvertTo-Json -Depth 10 | Set-Content "$agentDir/output.json" -Encoding UTF8
        $errorOutputs.logs | Set-Content "$agentDir/logs.txt" -Encoding UTF8
        
        return @{
            success = $false
            error = $errorMsg
        }
    }
}

function Update-TicketStatus {
    param($Ticket, [string]$Status, $Outputs = $null, $Error = $null)
    
    $queue = Get-Queue
    $ticket = $queue.jobs | Where-Object { $_.id -eq $Ticket.id }
    
    if ($ticket) {
        $ticket.status = $Status
        if (-not $ticket.PSObject.Properties['updatedAt']) {
            $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
            $ticket | Add-Member -NotePropertyName 'updatedAt' -NotePropertyValue $timestamp
        } else {
            $ticket.updatedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        }
        
        if ($Outputs) {
            if (-not $ticket.PSObject.Properties['outputs']) {
                $ticket | Add-Member -NotePropertyName 'outputs' -NotePropertyValue $Outputs
            } else {
                $ticket.outputs = $Outputs
            }
        }
        
        if ($Error) {
            if (-not $ticket.logs) {
                $ticket.logs = @()
            }
            $ticket.logs += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERROR: $Error"
        }
        
        # Update queue
        $queue.jobs = $queue.jobs | ForEach-Object {
            if ($_.id -eq $Ticket.id) { $ticket } else { $_ }
        }
        Set-Queue $queue
        
        # Update state statistics
        $state = Get-State
        switch ($Status) {
            "succeeded" { $state.statistics.successfulJobs++ }
            "failed" { $state.statistics.failedJobs++ }
            "terminated" { $state.statistics.terminatedJobs++ }
        }
        Set-State $state
    }
}

function Process-Queue {
    $queue = Get-Queue
    $config = Get-Config
    $state = Get-State
    
    # Check lock
    if (Test-Lock) {
        Write-RunnerLog "System locked - skipping queue processing" "WARN"
        return
    }
    
    # Find queued jobs
    $queuedJobs = $queue.jobs | Where-Object { $_.status -eq "queued" }
    $runningJobs = $queue.jobs | Where-Object { $_.status -eq "running" }
    
    # Enforce job limits
    $maxJobs = $config.max_jobs_per_run
    $availableSlots = $maxJobs - $runningJobs.Count
    
    if ($availableSlots -le 0) {
        Write-RunnerLog "Job limit reached: $maxJobs active jobs" "DEBUG"
        return
    }
    
    # Process available jobs
    $jobsToProcess = $queuedJobs | Select-Object -First $availableSlots
    
    foreach ($job in $jobsToProcess) {
        # Check TTL
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        if ($now -gt $job.deadline) {
            Write-RunnerLog "Job expired: $($job.id)" "WARN"
            Update-TicketStatus -Ticket $job -Status "failed" -Error "Job expired (TTL exceeded)"
            continue
        }
        
        # Check attempts
        if ($job.attempts -ge $job.metadata.budgets.maxAttempts) {
            Write-RunnerLog "Max attempts reached: $($job.id)" "WARN"
            Update-TicketStatus -Ticket $job -Status "failed" -Error "Max attempts exceeded"
            continue
        }
        
        # Start job
        $job.status = "running"
        if (-not $job.PSObject.Properties['startedAt']) {
            $job | Add-Member -NotePropertyName 'startedAt' -NotePropertyValue $now
        } else {
            $job.startedAt = $now
        }
        $job.attempts++
        
        Write-RunnerLog "Starting job: $($job.id) (attempt $($job.attempts))" "INFO"
        
        # Execute agent
        $result = Invoke-AgentExecution -Ticket $job
        
        if ($result.success) {
            Update-TicketStatus -Ticket $job -Status "succeeded" -Outputs $result.outputs
            Write-RunnerLog "Job completed successfully: $($job.id)" "INFO"
        } else {
            # Check if we should retry
            if ($job.attempts -lt $job.metadata.budgets.maxAttempts) {
                $job.status = "queued"
                $backoffMs = $job.metadata.budgets.backoffMs
                Write-RunnerLog "Job failed, retrying in $backoffMs ms: $($job.id)" "WARN"
                Start-Sleep -Milliseconds $backoffMs
            } else {
                Update-TicketStatus -Ticket $job -Status "failed" -Error $result.error
                Write-RunnerLog "Job failed permanently: $($job.id)" "ERROR"
            }
        }
    }
}

function Start-Runner {
    Write-RunnerLog "Starting IONA Agent Runner..." "INFO"
    
    $state = Get-State
    $state.runner.status = "running"
    Set-State $state
    
    $runCount = 0
    
    try {
        while ($true) {
            $runCount++
            Write-RunnerLog "Processing queue (run #$runCount)..." "DEBUG"
            
            Process-Queue
            
            if (-not $Daemon) {
                Write-RunnerLog "Single run completed" "INFO"
                break
            }
            
            Start-Sleep -Milliseconds $PollIntervalMs
        }
    } catch {
        Write-RunnerLog "Runner error: $($_.Exception.Message)" "ERROR"
    } finally {
        $state = Get-State
        $state.runner.status = "stopped"
        Set-State $state
        Write-RunnerLog "Runner stopped" "INFO"
    }
}

# Main execution
if ($Daemon) {
    Write-Host "🚀 Starting IONA Agent Runner in daemon mode..." -ForegroundColor Cyan
    Write-Host "Poll interval: $PollIntervalMs ms" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "🚀 Running IONA Agent Runner (single pass)..." -ForegroundColor Cyan
}

Start-Runner
