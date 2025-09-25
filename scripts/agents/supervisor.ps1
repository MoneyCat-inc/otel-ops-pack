# IONA Supervisor - Agent Lifecycle Management
# Provides safe spawning, monitoring, and termination of AI agents

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("spawn", "await", "terminate", "status", "start-runner", "stop-runner", "smoke-test", "verify-budgets", "verify-artifacts")]
    [string]$Action,
    
    [string]$SpecPath,
    [string]$Id,
    [int]$TimeoutMs = 30000,
    [string]$Reason
)

# Configuration
$AgentDir = ".agent"
$ArtifactsDir = "artifacts/agents"
$QueueFile = "$AgentDir/iona_queue.json"
$StateFile = "$AgentDir/iona_state.json"
$ConfigFile = "$AgentDir/config.json"
$LockFile = "$AgentDir/LOCK"

# Ensure directories exist
if (-not (Test-Path $AgentDir)) { New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null }
if (-not (Test-Path $ArtifactsDir)) { New-Item -ItemType Directory -Path $ArtifactsDir -Force | Out-Null }

# Helper Functions
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "Green" })
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
    $State | ConvertTo-Json -Depth 10 | Set-Content $StateFile -Encoding UTF8
}

function New-TicketId {
    return [System.Guid]::NewGuid().ToString()
}

function Test-Lock {
    return Test-Path $LockFile
}

function Invoke-Spawn {
    param([string]$SpecPath)
    
    if (-not $SpecPath -or -not (Test-Path $SpecPath)) {
        Write-Log "Specification file not found: $SpecPath" "ERROR"
        return $false
    }
    
    if (Test-Lock) {
        Write-Log "System locked - cannot spawn agents" "WARN"
        return $false
    }
    
    $spec = Get-Content $SpecPath | ConvertFrom-Json
    $config = Get-Config
    $queue = Get-Queue
    
    # Validate budgets
    if ($queue.jobs.Count -ge $config.max_jobs_per_run) {
        Write-Log "Maximum jobs limit reached: $($config.max_jobs_per_run)" "ERROR"
        return $false
    }
    
    # Create ticket
    $ticketId = New-TicketId
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $deadline = $now + ($spec.budgets.ttlMs)
    
    $ticket = @{
        id = $ticketId
        status = "queued"
        deadline = $deadline
        attempts = 0
        metadata = @{
            mode = $spec.mode
            goal = $spec.goal
            guardrails = $spec.guardrails
            budgets = $spec.budgets
            createdAt = $now
            updatedAt = $now
        }
    }
    
    # Add to queue
    $queue.jobs += $ticket
    Set-Queue $queue
    
    Write-Log "Spawned agent ticket: $ticketId (mode: $($spec.mode))" "INFO"
    Write-Host "Ticket ID: $ticketId" -ForegroundColor Cyan
    Write-Host "Mode: $($spec.mode)" -ForegroundColor Cyan
    Write-Host "Goal: $($spec.goal)" -ForegroundColor Cyan
    Write-Host "Deadline: $(Get-Date -UnixTimeSeconds ($deadline / 1000))" -ForegroundColor Cyan
    
    return $true
}

function Invoke-Await {
    param([string]$Id, [int]$TimeoutMs)
    
    if (-not $Id) {
        Write-Log "Ticket ID required for await operation" "ERROR"
        return $false
    }
    
    $startTime = Get-Date
    $timeout = [TimeSpan]::FromMilliseconds($TimeoutMs)
    
    Write-Log "Awaiting ticket: $Id (timeout: $TimeoutMs ms)" "INFO"
    
    # Progress animation
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $spinnerIndex = 0
    $lastUpdate = Get-Date
    
    while ((Get-Date) - $startTime -lt $timeout) {
        $queue = Get-Queue
        $ticket = $queue.jobs | Where-Object { $_.id -eq $Id }
        
        if (-not $ticket) {
            Write-Log "Ticket not found: $Id" "ERROR"
            return $false
        }
        
        # Update progress animation
        $now = Get-Date
        if (($now - $lastUpdate).TotalMilliseconds -gt 200) {
            $spinnerIndex = ($spinnerIndex + 1) % $spinner.Count
            $elapsed = [math]::Round((($now - $startTime).TotalMilliseconds / $TimeoutMs) * 100)
            Write-Host "`r$($spinner[$spinnerIndex]) Awaiting ticket $Id... $elapsed% ($($ticket.status))" -NoNewline -ForegroundColor Cyan
            $lastUpdate = $now
        }
        
        if ($ticket.status -in @("succeeded", "failed", "terminated")) {
            Write-Host "`r✅ Ticket completed: $($ticket.status)" -ForegroundColor Green
            
            # Read outputs if available
            $outputPath = "$ArtifactsDir/$Id/output.json"
            if (Test-Path $outputPath) {
                $outputs = Get-Content $outputPath | ConvertFrom-Json
                Write-Host "Outputs available at: $outputPath" -ForegroundColor Green
                return @{
                    status = $ticket.status
                    outputs = $outputs
                }
            }
            
            return @{
                status = $ticket.status
                outputs = $null
            }
        }
        
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "`r⏰ Timeout reached for ticket: $Id" -ForegroundColor Yellow
    return @{
        status = "timeout"
        outputs = $null
    }
}

function Invoke-Terminate {
    param([string]$Id, [string]$Reason)
    
    if (-not $Id) {
        Write-Log "Ticket ID required for terminate operation" "ERROR"
        return $false
    }
    
    $queue = Get-Queue
    $ticket = $queue.jobs | Where-Object { $_.id -eq $Id }
    
    if (-not $ticket) {
        Write-Log "Ticket not found: $Id" "ERROR"
        return $false
    }
    
    if ($ticket.status -in @("succeeded", "failed", "terminated")) {
        Write-Log "Ticket already completed: $($ticket.status)" "WARN"
        return $true
    }
    
    # Update ticket status
    $ticket.status = "terminated"
    $ticket.updatedAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    
    if (-not $ticket.logs) {
        $ticket.logs = @()
    }
    $ticket.logs += "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] TERMINATED: $Reason"
    
    # Update queue
    $queue.jobs = $queue.jobs | ForEach-Object {
        if ($_.id -eq $Id) { $ticket } else { $_ }
    }
    Set-Queue $queue
    
    # Update state statistics
    $state = Get-State
    $state.statistics.terminatedJobs++
    Set-State $state
    
    Write-Log "Terminated ticket: $Id (reason: $Reason)" "INFO"
    return $true
}

function Invoke-Status {
    $queue = Get-Queue
    $state = Get-State
    $config = Get-Config
    
    Write-Host "`n🔍 IONA Supervisor Status" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    # System status
    $lockStatus = if (Test-Lock) { "🔒 LOCKED" } else { "🔓 UNLOCKED" }
    Write-Host "System: $lockStatus" -ForegroundColor $(if (Test-Lock) { "Red" } else { "Green" })
    
    # Runner status
    $runnerStatus = $state.runner.status
    Write-Host "Runner: $runnerStatus" -ForegroundColor $(if ($runnerStatus -eq "running") { "Green" } else { "Yellow" })
    
    # Queue status
    $queuedJobs = ($queue.jobs | Where-Object { $_.status -eq "queued" }).Count
    $runningJobs = ($queue.jobs | Where-Object { $_.status -eq "running" }).Count
    $completedJobs = ($queue.jobs | Where-Object { $_.status -in @("succeeded", "failed", "terminated") }).Count
    
    Write-Host "Queue: $queuedJobs queued, $runningJobs running, $completedJobs completed" -ForegroundColor Cyan
    
    # Budget status
    Write-Host "Budget: $($queue.jobs.Count)/$($config.max_jobs_per_run) jobs" -ForegroundColor Cyan
    
    # Statistics
    Write-Host "`n📊 Statistics" -ForegroundColor Cyan
    Write-Host "Total Jobs: $($state.statistics.totalJobs)" -ForegroundColor White
    Write-Host "Successful: $($state.statistics.successfulJobs)" -ForegroundColor Green
    Write-Host "Failed: $($state.statistics.failedJobs)" -ForegroundColor Red
    Write-Host "Terminated: $($state.statistics.terminatedJobs)" -ForegroundColor Yellow
    
    # Recent jobs
    if ($queue.jobs.Count -gt 0) {
        Write-Host "`n📋 Recent Jobs" -ForegroundColor Cyan
        $queue.jobs | Sort-Object { $_.metadata.createdAt } -Descending | Select-Object -First 5 | ForEach-Object {
            $statusColor = switch ($_.status) {
                "succeeded" { "Green" }
                "failed" { "Red" }
                "terminated" { "Yellow" }
                "running" { "Cyan" }
                default { "White" }
            }
            Write-Host "  $($_.id.Substring(0,8))... [$($_.status)] $($_.metadata.mode): $($_.metadata.goal)" -ForegroundColor $statusColor
        }
    }
    
    return $true
}

function Invoke-SmokeTest {
    Write-Log "Running IONA Supervisor smoke tests..." "INFO"
    
    # Test 1: Configuration loading
    try {
        $config = Get-Config
        Write-Host "✅ Configuration loading: PASSED" -ForegroundColor Green
    } catch {
        Write-Host "❌ Configuration loading: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Test 2: Queue operations
    try {
        $queue = Get-Queue
        Set-Queue $queue
        Write-Host "✅ Queue operations: PASSED" -ForegroundColor Green
    } catch {
        Write-Host "❌ Queue operations: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Test 3: State management
    try {
        $state = Get-State
        Set-State $state
        Write-Host "✅ State management: PASSED" -ForegroundColor Green
    } catch {
        Write-Host "❌ State management: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Test 4: Directory structure
    try {
        if (-not (Test-Path $AgentDir)) { New-Item -ItemType Directory -Path $AgentDir -Force | Out-Null }
        if (-not (Test-Path $ArtifactsDir)) { New-Item -ItemType Directory -Path $ArtifactsDir -Force | Out-Null }
        Write-Host "✅ Directory structure: PASSED" -ForegroundColor Green
    } catch {
        Write-Host "❌ Directory structure: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Test 5: Lock mechanism
    try {
        $lockBefore = Test-Lock
        if (-not $lockBefore) {
            New-Item -ItemType File -Path $LockFile -Force | Out-Null
            $lockAfter = Test-Lock
            Remove-Item $LockFile -Force
            if ($lockAfter) {
                Write-Host "✅ Lock mechanism: PASSED" -ForegroundColor Green
            } else {
                Write-Host "❌ Lock mechanism: FAILED - Lock not detected" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "✅ Lock mechanism: PASSED (already locked)" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Lock mechanism: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "`n🎉 All smoke tests PASSED!" -ForegroundColor Green
    return $true
}

# Main execution
try {
    switch ($Action) {
        "spawn" {
            if (-not $SpecPath) {
                Write-Log "SpecPath parameter required for spawn action" "ERROR"
                exit 1
            }
            $result = Invoke-Spawn -SpecPath $SpecPath
            exit $(if ($result) { 0 } else { 1 })
        }
        
        "await" {
            if (-not $Id) {
                Write-Log "Id parameter required for await action" "ERROR"
                exit 1
            }
            $result = Invoke-Await -Id $Id -TimeoutMs $TimeoutMs
            if ($result) {
                Write-Host "Result: $($result | ConvertTo-Json -Compress)" -ForegroundColor Green
                exit 0
            } else {
                exit 1
            }
        }
        
        "terminate" {
            if (-not $Id) {
                Write-Log "Id parameter required for terminate action" "ERROR"
                exit 1
            }
            if (-not $Reason) {
                $Reason = "operator termination"
            }
            $result = Invoke-Terminate -Id $Id -Reason $Reason
            exit $(if ($result) { 0 } else { 1 })
        }
        
        "status" {
            $result = Invoke-Status
            exit $(if ($result) { 0 } else { 1 })
        }
        
        "smoke-test" {
            $result = Invoke-SmokeTest
            exit $(if ($result) { 0 } else { 1 })
        }
        
        default {
            Write-Log "Unsupported action: $Action" "ERROR"
            Write-Host "Supported actions: spawn, await, terminate, status, smoke-test" -ForegroundColor Yellow
            exit 1
        }
    }
} catch {
    Write-Log "Unexpected error: $($_.Exception.Message)" "ERROR"
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
