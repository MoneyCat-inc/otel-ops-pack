#!/usr/bin/env pwsh
# recurring-job-injector.ps1
# Injects recurring maintenance jobs into the agent queue

param(
    [switch]$DryRun,
    [switch]$Verbose
)

$AgentDir = ".agent"
$StateFile = "$AgentDir/state.json"
$RecurringFile = "$AgentDir/recurring.json"
$QueueFile = "$AgentDir/agent_queue.json"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    try {
        Write-Host $Message -ForegroundColor $Color
    } catch {
        Write-Host $Message
    }
}

function Write-VerboseOutput {
    param([string]$Message)
    if ($Verbose) {
        Write-ColorOutput "VERBOSE: $Message" "Gray"
    }
}

function Get-AgentState {
    if (-not (Test-Path $StateFile)) {
        Write-ColorOutput "❌ Agent state not found: $StateFile" "Red"
        return $null
    }
    return Get-Content $StateFile | ConvertFrom-Json
}

function Get-RecurringConfig {
    if (-not (Test-Path $RecurringFile)) {
        Write-ColorOutput "❌ Recurring config not found: $RecurringFile" "Red"
        return $null
    }
    return Get-Content $RecurringFile | ConvertFrom-Json
}

function Get-TaskQueue {
    if (-not (Test-Path $QueueFile)) {
        Write-ColorOutput "❌ Task queue not found: $QueueFile" "Red"
        return @()
    }
    return Get-Content $QueueFile | ConvertFrom-Json
}

function Update-AgentState {
    param([hashtable]$RecurringTimestamps)
    
    $state = Get-AgentState
    if ($state) {
        # Create a new state object to avoid property binding issues
        $newState = @{
            lastRun = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
            killSwitch = $state.killSwitch
            status = $state.status
            jobsProcessed = $state.jobsProcessed
            agentName = $state.agentName
            uptime = $state.uptime
            lastError = $state.lastError
            recurring = $RecurringTimestamps
        }
        
        $newState | ConvertTo-Json | Out-File -FilePath $StateFile -Encoding UTF8
        Write-VerboseOutput "Updated agent state with recurring timestamps"
    }
}

function Invoke-RecurringInjection {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $state = Get-AgentState
    $config = Get-RecurringConfig
    $queue = Get-TaskQueue
    
    if (-not $state -or -not $config) {
        return
    }
    
    Write-VerboseOutput "Starting recurring job injection at $now"
    
    # Create map of existing queue items by ID
    $existingJobs = @{}
    foreach ($job in $queue) {
        $existingJobs[$job.id] = $true
    }
    
    $injectedCount = 0
    $recurringTimestamps = @{}
    
    # Copy existing recurring timestamps
    if ($state.recurring) {
        foreach ($key in $state.recurring.PSObject.Properties.Name) {
            $recurringTimestamps[$key] = $state.recurring.$key
        }
    }
    
    foreach ($job in $config.jobs) {
        $lastRun = $recurringTimestamps[$job.id]
        $isDue = -not $lastRun -or (($now - $lastRun) -ge $job.intervalMs)
        
        Write-VerboseOutput "Job $($job.id): lastRun=$lastRun, isDue=$isDue, exists=$($existingJobs.ContainsKey($job.id))"
        
        if ($isDue -and -not $existingJobs.ContainsKey($job.id)) {
            # Create new task from recurring job
            $newTask = @{
                id = $job.id
                type = $job.type
                priority = if ($job.priority) { $job.priority } else { $config.defaults.priority }
                attempts = 0
                maxAttempts = if ($job.maxAttempts) { $job.maxAttempts } else { $config.defaults.maxAttempts }
                ttlMs = if ($job.ttlMs) { $job.ttlMs } else { $config.defaults.ttlMs }
                createdAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
                nextRunAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
                payload = $job.payload
            }
            
            $queue += $newTask
            $injectedCount++
            
            Write-ColorOutput "🔄 Injected recurring job: $($job.id)" "Cyan"
            Write-VerboseOutput "  Type: $($job.type)"
            Write-VerboseOutput "  Priority: $($newTask.priority)"
            Write-VerboseOutput "  Description: $($job.payload.description)"
            
            # Mark as injected (will be updated to completion time later)
            $recurringTimestamps[$job.id] = $now
        } elseif ($lastRun) {
            # Preserve existing timestamp
            $recurringTimestamps[$job.id] = $lastRun
        }
    }
    
    if ($injectedCount -gt 0) {
        if (-not $DryRun) {
            # Write updated queue
            $queue | ConvertTo-Json | Out-File -FilePath $QueueFile -Encoding UTF8
            
            # Update state with new timestamps
            Update-AgentState -RecurringTimestamps $recurringTimestamps
            
            Write-ColorOutput "✅ Injected $injectedCount recurring jobs into queue" "Green"
        } else {
            Write-ColorOutput "🔍 DRY RUN: Would inject $injectedCount recurring jobs" "Yellow"
        }
    } else {
        Write-ColorOutput "ℹ️  No recurring jobs due for injection" "Gray"
    }
    
    return $injectedCount
}

# Main execution
Write-VerboseOutput "Starting recurring job injection with DryRun=$DryRun"

if ($DryRun) {
    Write-ColorOutput "🔍 DRY RUN MODE - No changes will be made" "Yellow"
}

$injectedCount = Invoke-RecurringInjection

if ($injectedCount -gt 0) {
    Write-ColorOutput "📋 Use 'pnpm cursor:list-tasks' to see the updated queue" "Blue"
} else {
    Write-ColorOutput "✅ Recurring injection complete - no jobs due" "Green"
}
