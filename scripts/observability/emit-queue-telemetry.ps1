param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot '..\..'),
    [string]$OutputPath = 'C:\logs\queue\health.log'
)

function Resolve-RepoRoot {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }
    return (Join-Path (Get-Location) $Path)
}

function Read-JsonFile {
    param(
        [string]$Path,
        [object]$Default = @{}
    )
    
    if (Test-Path $Path) {
        try {
            $content = Get-Content $Path -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
        catch {
            Write-Warning "Failed to read JSON file $Path : $($_.Exception.Message)"
            return $Default
        }
    }
    return $Default
}

function Parse-IsoDate {
    param([string]$IsoString)
    
    if ([string]::IsNullOrEmpty($IsoString)) {
        return $null
    }
    
    try {
        return [DateTimeOffset]::Parse($IsoString)
    }
    catch {
        return $null
    }
}

function Get-LaneSummaries {
    param([array]$Queue)
    
    $lanes = @{}
    $now = [DateTimeOffset]::UtcNow
    
    foreach ($job in $Queue) {
        $type = if ($job.type) { $job.type } else { 'unknown' }
        $priority = if ($job.priority) { $job.priority } else { 0 }
        
        if (-not $lanes.ContainsKey($type)) {
            $lanes[$type] = @{
                type = $type
                total = 0
                ready = 0
                pending = 0
                avgPriority = 0
                prioritySum = 0
            }
        }
        
        $lanes[$type].total++
        $lanes[$type].prioritySum += $priority
        
        # Check if job is ready (not before current time)
        $notBefore = Parse-IsoDate -IsoString $job.nextRunAt
        if ($notBefore -eq $null -or $notBefore -le $now) {
            $lanes[$type].ready++
        } else {
            $lanes[$type].pending++
        }
    }
    
    # Calculate average priorities
    foreach ($type in $lanes.Keys) {
        if ($lanes[$type].total -gt 0) {
            $lanes[$type].avgPriority = [math]::Round($lanes[$type].prioritySum / $lanes[$type].total, 2)
        }
    }
    
    return $lanes.Values | Sort-Object { $_.type }
}

# Resolve paths
$repoRoot = Resolve-RepoRoot -Path $RepoRoot
$queueFile = Join-Path $repoRoot '.agent\agent_queue.json'
$stateFile = Join-Path $repoRoot '.agent\state.json'
$configFile = Join-Path $repoRoot '.agent\config.json'

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Read queue and state files
$queue = Read-JsonFile -Path $queueFile -Default @()
$state = Read-JsonFile -Path $stateFile -Default @{}
$config = Read-JsonFile -Path $configFile -Default @{}

# Calculate queue metrics
$queueLength = ($queue | Measure-Object).Count
$now = [DateTimeOffset]::UtcNow

# Count ready vs pending jobs
$readyCount = 0
$pendingCount = 0
$pendingByLane = @{}
$readyByLane = @{}

foreach ($job in $queue) {
    $type = if ($job.type) { $job.type } else { 'unknown' }
    $notBefore = Parse-IsoDate -IsoString $job.nextRunAt
    
    if (-not $pendingByLane.ContainsKey($type)) {
        $pendingByLane[$type] = 0
        $readyByLane[$type] = 0
    }
    
    if ($notBefore -eq $null -or $notBefore -le $now) {
        $readyCount++
        $readyByLane[$type]++
    } else {
        $pendingCount++
        $pendingByLane[$type]++
    }
}

# Get lane summaries
$laneSummaries = Get-LaneSummaries -Queue $queue

# Extract state information
$lastRun = if ($state.lastRun) { $state.lastRun } else { $null }
$lastError = if ($state.lastError) { $state.lastError } else { $null }
$killSwitch = if ($state.killSwitch -eq $true) { $true } else { $false }
$jobsProcessed = if ($state.jobsProcessed) { $state.jobsProcessed } else { 0 }
$agentName = if ($state.agentName) { $state.agentName } else { 'unknown' }
$uptime = if ($state.uptime) { $state.uptime } else { 0 }

# Create telemetry payload
$payload = [ordered]@{
    timestamp = $now.ToString('o')
    dataset = 'agent_queue'
    queueLength = $queueLength
    readyCount = $readyCount
    pendingCount = $pendingCount
    pendingByLane = $pendingByLane
    readyByLane = $readyByLane
    lastRun = $lastRun
    lastError = $lastError
    killSwitch = $killSwitch
    jobsProcessed = $jobsProcessed
    agentName = $agentName
    uptime = $uptime
    lanes = $laneSummaries
    config = @{
        maxConcurrency = if ($config.maxConcurrency) { $config.maxConcurrency } else { 1 }
        defaultTtl = if ($config.defaultTtl) { $config.defaultTtl } else { 86400000 }
        retryBackoff = if ($config.retryBackoff) { $config.retryBackoff } else { 'exponential' }
    }
}

# Write to log file
$jsonLine = $payload | ConvertTo-Json -Compress -Depth 10
Add-Content -Path $OutputPath -Value $jsonLine -Encoding UTF8

# Output summary to console
Write-Host "Queue telemetry emitted: queueLength=$queueLength readyCount=$readyCount killSwitch=$killSwitch"
Write-Host "Output written to: $OutputPath"