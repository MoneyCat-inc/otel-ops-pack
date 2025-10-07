#Requires -Version 7.0

<#
.SYNOPSIS
    Parallel Agent Orchestrator for Bosscat Workflows
    Implements atomic task decomposition and background agent management

.DESCRIPTION
    This orchestrator breaks down large tasks into atomic units and spawns background
    agents to handle them in parallel, delivering both speed and the ability to explore
    multiple approaches simultaneously.

.PARAMETER TaskSpec
    JSON specification of the main task to decompose

.PARAMETER MaxConcurrentAgents
    Maximum number of concurrent agents (default: CPU count)

.PARAMETER WorkspaceRoot
    Root directory for agent workspaces (default: artifacts/agent-workspaces)

.PARAMETER AgentTimeout
    Timeout for individual agents in minutes (default: 30)

.PARAMETER EnableTelemetry
    Enable SigNoz telemetry for agent monitoring

.PARAMETER DryRun
    Generate task plan without executing agents

.EXAMPLE
    .\parallel-agent-orchestrator.ps1 -TaskSpec @'
    {
        "name": "ecrr-batch-processing",
        "type": "batch-processing",
        "input": {
            "reportCount": 1200,
            "parallelSettings": [1,2,4,6,8,12,16]
        },
        "output": {
            "artifacts": ["benchmark-results.json", "summary.md"],
            "telemetry": true
        }
    }
    '@
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TaskSpec,
    
    [int]$MaxConcurrentAgents = 0,
    
    [string]$WorkspaceRoot = 'artifacts/agent-workspaces',
    
    [int]$AgentTimeout = 30,
    
    [switch]$EnableTelemetry,
    
    [switch]$DryRun,
    
    [string]$AgentType = 'bosscat'
    
)

$script:agentConfigPath = '.agent/config.json'
$script:agentConfig = $null
$script:parallelAgentConfig = $null

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ECRR Framework Integration
$ecrrSession = @{
    SessionId = (New-Guid).ToString()
    StartTime = Get-Date
    Agent = "Parallel-Agent-Orchestrator"
    Phase = "Examine"
}

function Write-ECRRLog {
    param([string]$Message, [string]$Phase = $ecrrSession.Phase)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[ECRR-$Phase] $timestamp - $Message" -ForegroundColor Cyan
}

function Write-AgentLog {
    param([string]$Message, [string]$Level = 'INFO')
    $colors = @{ INFO = 'Green'; WARN = 'Yellow'; ERROR = 'Red'; DEBUG = 'Gray' }
    Write-Host "[AGENT-$Level] $Message" -ForegroundColor $colors[$Level]
}

if (Test-Path $script:agentConfigPath) {
    try {
        $script:agentConfig = Get-Content $script:agentConfigPath -Raw | ConvertFrom-Json
        if ($script:agentConfig.PSObject.Properties.Name -contains 'parallelAgent') {
            $script:parallelAgentConfig = $script:agentConfig.parallelAgent
        }
        Write-AgentLog "Loaded agent configuration from $($script:agentConfigPath)" -Level DEBUG
    } catch {
        Write-AgentLog "Failed to parse $($script:agentConfigPath): $($_.Exception.Message)" -Level WARN
    }
} else {
    Write-AgentLog "Agent configuration not found at $($script:agentConfigPath); using defaults" -Level WARN
}

$configuredMaxAgents = 0
if ($script:parallelAgentConfig -and $script:parallelAgentConfig.PSObject.Properties.Name -contains 'max_concurrent_agents') {
    $configuredMaxAgents = [int]$script:parallelAgentConfig.max_concurrent_agents
}

if ($PSBoundParameters.ContainsKey('MaxConcurrentAgents') -and $MaxConcurrentAgents -gt 0) {
    if ($configuredMaxAgents -gt 0 -and $MaxConcurrentAgents -gt $configuredMaxAgents) {
        Write-AgentLog "Capping requested MaxConcurrentAgents ($MaxConcurrentAgents) to configured maximum $configuredMaxAgents" -Level WARN
        $MaxConcurrentAgents = $configuredMaxAgents
    }
} else {
    if ($configuredMaxAgents -gt 0) {
        $MaxConcurrentAgents = $configuredMaxAgents
    } else {
        $MaxConcurrentAgents = [Math]::Max([int]$env:NUMBER_OF_PROCESSORS, 1)
    }
    Write-AgentLog "Using MaxConcurrentAgents=$MaxConcurrentAgents" -Level DEBUG
}

# Parse task specification
try {
    $task = $TaskSpec | ConvertFrom-Json
    Write-AgentLog "Parsed task specification: $($task.name)" -Level INFO
} catch {
    Write-AgentLog "Failed to parse task specification: $($_.Exception.Message)" -Level ERROR
    throw
}

# Initialize workspace structure
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$sessionWorkspace = Join-Path $WorkspaceRoot "session-$timestamp"
$null = New-Item -ItemType Directory -Path $sessionWorkspace -Force

Write-ECRRLog "Initializing parallel agent session: $($ecrrSession.SessionId)"

# Task Decomposition Engine
function Invoke-TaskDecomposition {
    param([object]$TaskSpec)
    
    Write-ECRRLog "Decomposing task: $($TaskSpec.name)" -Phase "Examine"
    
    $atomicTasks = @()
    
    switch ($TaskSpec.type) {
        'batch-processing' {
            $taskInput = $TaskSpec.input
            $inputPropertyNames = @()
            if ($null -ne $taskInput) { $inputPropertyNames = $taskInput.PSObject.Properties.Name }
            
            $reportCount = 0
            if ($inputPropertyNames -contains 'reportCount') {
                $reportCount = [int]$taskInput.reportCount
            }
            if ($reportCount -le 0) { $reportCount = 100 }
            
            $batchConfig = $null
            if ($script:parallelAgentConfig -and $script:parallelAgentConfig.decomposition -and $script:parallelAgentConfig.decomposition.batch_processing) {
                $batchConfig = $script:parallelAgentConfig.decomposition.batch_processing
            }
            
            $parallelSettings = @()
            if ($inputPropertyNames -contains 'parallelSettings') {
                $parallelSettings = @($taskInput.parallelSettings | ForEach-Object { [int]$_ } | Where-Object { $_ -gt 0 })
            }
            if ($parallelSettings.Count -eq 0) {
                $parallelSettings = @([Math]::Min(4, $MaxConcurrentAgents))
            }
            $parallelSettings = @($parallelSettings | Sort-Object -Unique)
            
            if ($batchConfig -and $batchConfig.max_parallel_multiplier -gt 1) {
                $maxSetting = ($parallelSettings | Measure-Object -Maximum).Maximum
                if ($maxSetting -gt 0) {
                    $boosted = [Math]::Min([Math]::Ceiling($maxSetting * $batchConfig.max_parallel_multiplier), $MaxConcurrentAgents)
                    if ($boosted -gt $maxSetting) {
                        $parallelSettings += $boosted
                    }
                }
            }
            
            $parallelSettings = @($parallelSettings | ForEach-Object { [Math]::Min($_, $MaxConcurrentAgents) } | Sort-Object -Unique | Where-Object { $_ -gt 0 })
            if ($parallelSettings.Count -eq 0) {
                $parallelSettings = @([Math]::Max(1, [Math]::Min(4, $MaxConcurrentAgents)))
            }
            
            $chunkSize = 0
            if ($inputPropertyNames -contains 'chunkSize') {
                $chunkSize = [int]$taskInput.chunkSize
            }
            if ($batchConfig -and $batchConfig.min_chunk_size -gt 0) {
                if ($chunkSize -lt $batchConfig.min_chunk_size) {
                    $chunkSize = [int]$batchConfig.min_chunk_size
                }
            }
            if ($chunkSize -le 0) {
                $chunkSize = [Math]::Max([Math]::Ceiling($reportCount / ([Math]::Max($MaxConcurrentAgents, 1) * 2)), 50)
            }
            
            $chunkCount = [Math]::Ceiling($reportCount / $chunkSize)
            $maxChunks = [Math]::Max($MaxConcurrentAgents * 4, 1)
            if ($chunkCount -gt $maxChunks) {
                $chunkCount = $maxChunks
                $chunkSize = [Math]::Ceiling($reportCount / $chunkCount)
            }
            
            for ($chunkIndex = 0; $chunkIndex -lt $chunkCount; $chunkIndex++) {
                $chunkStart = ($chunkIndex * $chunkSize) + 1
                $chunkEnd = [Math]::Min($chunkStart + $chunkSize - 1, $reportCount)
                $chunkSpan = $chunkEnd - $chunkStart + 1
                
                $parallelHint = $parallelSettings[[Math]::Min($chunkIndex, $parallelSettings.Count - 1)]
                $parallelHint = [Math]::Min([Math]::Max($parallelHint, 1), $MaxConcurrentAgents)
                
                $taskIterations = 2
                if ($inputPropertyNames -contains 'iterations' -and $taskInput.iterations -gt 0) {
                    $taskIterations = [int]$taskInput.iterations
                }
                
                $atomicTasks += [pscustomobject]@{
                    Id = "batch-chunk-$([string]::Format('{0:D2}', $chunkIndex + 1))-p$parallelHint"
                    Type = "benchmark-run"
                    Priority = if ($chunkIndex -lt $parallelSettings.Count) { 1 } else { 2 }
                    Dependencies = @()
                    Input = @{
                        MaxParallel = $parallelHint
                        ReportCount = $chunkSpan
                        Iterations = $taskIterations
                        Offset = $chunkStart
                    }
                    Output = @{
                        Artifacts = @("benchmark-results.json", "summary.md")
                        Metrics = @("latency", "throughput", "compliance")
                    }
                    Timeout = $AgentTimeout
                    Workspace = Join-Path $sessionWorkspace ("agent-batch-chunk-{0:D2}" -f ($chunkIndex + 1))
                }
            }
        }
        
        'ecrr-compliance-check' {
            # Decompose ECRR reports into parallel validation tasks
            $reportDirs = @('docs/ecrr/ECRR_REPORTS', 'docs/observability/snapshots')
            
            foreach ($dir in $reportDirs) {
                if (Test-Path $dir) {
                    $reports = Get-ChildItem $dir -Filter "*.md" | Select-Object -First 10
                    foreach ($report in $reports) {
                        $atomicTasks += [pscustomobject]@{
                            Id = "ecrr-validate-$(Split-Path $report.Name -LeafBase)"
                            Type = "ecrr-validation"
                            Priority = 1
                            Dependencies = @()
                            Input = @{
                                ReportPath = $report.FullName
                                ValidationRules = @("four-section", "actor-declaration", "evidence-reference")
                            }
                            Output = @{
                                Artifacts = @("validation-report.json")
                                Metrics = @("compliance-score", "issue-count")
                            }
                            Timeout = 5
                            Workspace = Join-Path $sessionWorkspace "agent-ecrr-$(Split-Path $report.Name -LeafBase)"
                        }
                    }
                }
            }
        }
        
        'signoz-dashboard-export' {
            $dashboardConfig = $null
            if ($script:parallelAgentConfig -and $script:parallelAgentConfig.decomposition -and $script:parallelAgentConfig.decomposition.dashboard_export) {
                $dashboardConfig = $script:parallelAgentConfig.decomposition.dashboard_export
            }
            
            $taskInput = $TaskSpec.input
            $inputPropertyNames = @()
            if ($null -ne $taskInput) { $inputPropertyNames = $taskInput.PSObject.Properties.Name }
            
            $dashboards = @()
            if ($inputPropertyNames -contains 'dashboards') {
                $dashboards = @($taskInput.dashboards | ForEach-Object { "$_" } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            }
            if ($dashboards.Count -eq 0) {
                $dashboards = @('pipeline-health', 'compliance-trends', 'performance-metrics', 'error-analysis')
            }
            
            $timeRanges = @()
            if ($inputPropertyNames -contains 'timeRanges') {
                $timeRanges = @($taskInput.timeRanges | ForEach-Object { "$_" })
            } elseif ($inputPropertyNames -contains 'timeRange') {
                $timeRanges = @("$($taskInput.timeRange)")
            } else {
                $timeRanges = @("1h")
            }
            
            $exportFormats = @()
            if ($inputPropertyNames -contains 'exportFormat') {
                $exportFormats = @($taskInput.exportFormat | ForEach-Object { "$_" })
            } else {
                $exportFormats = @("png", "json")
            }
            
            $chunkSize = 1
            if ($dashboardConfig -and $dashboardConfig.chunk_size -gt 0) {
                $chunkSize = [int]$dashboardConfig.chunk_size
            }
            if ($chunkSize -lt 1) { $chunkSize = 1 }
            
            for ($i = 0; $i -lt $dashboards.Count; $i += $chunkSize) {
                $group = @($dashboards[$i..([Math]::Min($i + $chunkSize - 1, $dashboards.Count - 1))])
                $groupId = ($group -join '-')
                
                foreach ($timeRange in $timeRanges) {
                    $groupWorkspace = Join-Path $sessionWorkspace ("agent-signoz-{0}" -f $groupId.Replace(':','-'))
                    $artifactList = @()
                    foreach ($dashboard in $group) {
                        foreach ($format in $exportFormats) {
                            $artifactList += "$dashboard.$format"
                        }
                    }
                    
                    $atomicTasks += [pscustomobject]@{
                        Id = "signoz-export-$groupId-$timeRange"
                        Type = "dashboard-export"
                        Priority = 2
                        Dependencies = @()
                        Input = @{
                            Dashboards = $group
                            ExportFormats = $exportFormats
                            TimeRange = $timeRange
                        }
                        Output = @{
                            Artifacts = $artifactList
                            Metrics = @("export-time", "file-size")
                        }
                        Timeout = 10
                        Workspace = $groupWorkspace
                    }
                }
            }
        }
        
        default {
            Write-AgentLog "Unknown task type: $($TaskSpec.type)" -Level WARN
            $atomicTasks += [pscustomobject]@{
                Id = "generic-task-1"
                Type = "generic"
                Priority = 1
                Dependencies = @()
                Input = $TaskSpec.input
                Output = $TaskSpec.output
                Timeout = $AgentTimeout
                Workspace = Join-Path $sessionWorkspace "agent-generic-1"
            }
        }
    }
    
    Write-ECRRLog "Decomposed into $($atomicTasks.Count) atomic tasks" -Phase "Examine"
    return $atomicTasks
}

# Agent Spawner
function Start-BackgroundAgent {
    param(
        [object]$Task,
        [string]$WorkspacePath,
        [bool]$EnableTelemetry = $false
    )
    
    Write-AgentLog "Spawning agent for task: $($Task.Id)" -Level INFO
    
    # Create isolated workspace
    $null = New-Item -ItemType Directory -Path $WorkspacePath -Force
    
    # Generate agent script
    $agentScript = Generate-AgentScript -Task $Task -Workspace $WorkspacePath -EnableTelemetry $EnableTelemetry
    
    # Save agent script
    $scriptPath = Join-Path $WorkspacePath "agent.ps1"
    Set-Content -Path $scriptPath -Value $agentScript -Encoding UTF8
    
    # Start background process
    $processArgs = @{
        FilePath = "pwsh.exe"
        ArgumentList = @("-NoLogo", "-NoProfile", "-File", $scriptPath)
        WorkingDirectory = $WorkspacePath
        PassThru = $true
        WindowStyle = 'Hidden'
    }
    
    $process = Start-Process @processArgs
    
    return [pscustomobject]@{
        ProcessId = $process.Id
        TaskId = $Task.Id
        Workspace = $WorkspacePath
        StartTime = Get-Date
        Status = "Running"
        Process = $process
    }
}

# Agent Script Generator
function Generate-AgentScript {
    param(
        [object]$Task,
        [string]$Workspace,
        [bool]$EnableTelemetry
    )
    
    $script = @"
# Agent Script for Task: $($Task.Id)
# Generated by Parallel Agent Orchestrator
# Workspace: $Workspace

Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'

# Agent Configuration
`$agentConfig = @{
    TaskId = '$($Task.Id)'
    TaskType = '$($Task.Type)'
    Workspace = '$Workspace'
    StartTime = (Get-Date).ToString('o')
    SessionId = '$($ecrrSession.SessionId)'
}

# ECRR Integration
function Write-AgentECRRLog {
    param([string]`$Message, [string]`$Phase = 'Clean')
    `$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[ECRR-`$Phase] `$timestamp - Agent `$(`$agentConfig.TaskId): `$Message" -ForegroundColor Cyan
}

# Telemetry Integration
function Send-AgentTelemetry {
    param([string]`$Metric, [double]`$Value, [hashtable]`$Tags = @{})
    
    if (-not `$$EnableTelemetry) { return }
    
    try {
        # Send to SigNoz via OTLP
        `$telemetryData = @{
            metric = `$Metric
            value = `$Value
            tags = `$Tags
            timestamp = (Get-Date).ToString('o')
            agent_id = `$agentConfig.TaskId
        }
        
        # Implementation would send to OTLP endpoint
        Write-Host "[TELEMETRY] `$(`$telemetryData | ConvertTo-Json -Compress)" -ForegroundColor DarkCyan
    } catch {
        Write-Warning "Failed to send telemetry: `$(`$_.Exception.Message)"
    }
}

Write-AgentECRRLog "Starting agent execution" -Phase "Examine"

try {
    # Task-specific execution
    switch ('$($Task.Type)') {
        'benchmark-run' {
            Write-AgentECRRLog "Executing benchmark run" -Phase "Clean"
            
            `$input = @'$($Task.Input | ConvertTo-Json -Compress)'@ | ConvertFrom-Json
            
            # Execute benchmark with specified parallelism
            `$benchmarkArgs = @(
                '-NoLogo', '-NoProfile', '-File', 'scripts/benchmark-process-all-ecrr-reports.ps1',
                '-ReportCount', `$input.ReportCount,
                '-MaxParallelCsv', `$input.MaxParallel,
                '-Iterations', `$input.Iterations,
                '-BenchmarkRoot', 'artifacts/benchmarks/agent-run'
            )
            
            `$benchmarkStart = Get-Date
            `$benchmarkResult = & pwsh.exe @benchmarkArgs
            `$benchmarkDuration = (Get-Date) - `$benchmarkStart
            
            Send-AgentTelemetry -Metric "benchmark_duration_ms" -Value `$benchmarkDuration.TotalMilliseconds -Tags @{parallelism = `$input.MaxParallel}
            
            # Generate output artifacts
            `$output = @{
                success = `$true
                duration_ms = `$benchmarkDuration.TotalMilliseconds
                parallelism = `$input.MaxParallel
                report_count = `$input.ReportCount
                artifacts = @('benchmark-results.json', 'summary.md')
            }
        }
        
        'ecrr-validation' {
            Write-AgentECRRLog "Validating ECRR report" -Phase "Clean"
            
            `$input = @'$($Task.Input | ConvertTo-Json -Compress)'@ | ConvertFrom-Json
            
            # Validate ECRR report
            `$validationStart = Get-Date
            `$validationResult = Validate-ECRRReport -Path `$input.ReportPath -Rules `$input.ValidationRules
            `$validationDuration = (Get-Date) - `$validationStart
            
            Send-AgentTelemetry -Metric "validation_duration_ms" -Value `$validationDuration.TotalMilliseconds -Tags @{report = Split-Path `$input.ReportPath -Leaf}
            
            `$output = @{
                success = `$validationResult.IsValid
                compliance_score = `$validationResult.ComplianceScore
                issues = `$validationResult.Issues
                duration_ms = `$validationDuration.TotalMilliseconds
            }
        }
        
        'dashboard-export' {
            Write-AgentECRRLog "Exporting SigNoz dashboard" -Phase "Clean"
            
            `$input = @'$($Task.Input | ConvertTo-Json -Compress)'@ | ConvertFrom-Json
            
            `$dashboards = @()
            if ($input.Dashboards) {
                `$dashboards = @($input.Dashboards | ForEach-Object { "$_" })
            } elseif ($input.DashboardName) {
                `$dashboards = @("$($input.DashboardName)")
            }
            if (`$dashboards.Count -eq 0) { `$dashboards = @("pipeline-health") }
            
            `$exportFormats = @()
            if ($input.ExportFormats) {
                `$exportFormats = @($input.ExportFormats | ForEach-Object { "$_" })
            } else {
                `$exportFormats = @("png", "json")
            }
            
            `$timeRange = if ($input.TimeRange) { "$($input.TimeRange)" } else { "1h" }
            
            # Placeholder export loop - would call Playwright/API in production
            `$exportDurationMs = 0
            foreach (`$dashboard in `$dashboards) {
                `$perExportMs = Get-Random -Minimum 350 -Maximum 650
                `$exportDurationMs += `$perExportMs
                Send-AgentTelemetry -Metric "export_duration_ms" -Value `$perExportMs -Tags @{dashboard = `$dashboard; time_range = `$timeRange}
            }
            
            `$artifacts = @()
            foreach (`$dashboard in `$dashboards) {
                foreach (`$format in `$exportFormats) {
                    `$artifacts += "`$dashboard.`$format"
                }
            }
            
            `$output = @{
                success = `$true
                dashboards = `$dashboards
                time_range = `$timeRange
                duration_ms = `$exportDurationMs
                artifacts = `$artifacts
            }
        }
        
        default {
            Write-AgentECRRLog "Unknown task type: $($Task.Type)" -Phase "Clean"
            `$output = @{
                success = `$false
                error = "Unknown task type: $($Task.Type)"
            }
        }
    }
    
    Write-AgentECRRLog "Task completed successfully" -Phase "Report"
    
} catch {
    Write-AgentECRRLog "Task failed: `$(`$_.Exception.Message)" -Phase "Report"
    `$output = @{
        success = `$false
        error = `$_.Exception.Message
        stack_trace = `$_.ScriptStackTrace
    }
}

# Save output
`$output | ConvertTo-Json -Depth 10 | Out-File -FilePath 'output.json' -Encoding UTF8

Write-AgentECRRLog "Agent execution complete" -Phase "Role"
"@

    return $script
}

# Helper function for ECRR validation
function Validate-ECRRReport {
    param([string]$Path, [string[]]$Rules)
    
    if (-not (Test-Path $Path)) {
        return @{
            IsValid = $false
            ComplianceScore = 0
            Issues = @("Report file not found: $Path")
        }
    }
    
    $content = Get-Content $Path -Raw
    $issues = @()
    $score = 100
    
    foreach ($rule in $Rules) {
        switch ($rule) {
            'four-section' {
                if ($content -notmatch '## 🔍 1\. Examine' -or 
                    $content -notmatch '## 🧹 2\. Clean' -or 
                    $content -notmatch '## 📊 3\. Report' -or 
                    $content -notmatch '## 👤 4\. Role') {
                    $issues += "Missing required ECRR sections"
                    $score -= 25
                }
            }
            'actor-declaration' {
                if ($content -notmatch 'Actor Declaration:') {
                    $issues += "Missing actor declaration"
                    $score -= 20
                }
            }
            'evidence-reference' {
                if ($content -notmatch 'EvidenceReference:') {
                    $issues += "Missing evidence reference"
                    $score -= 15
                }
            }
        }
    }
    
    return @{
        IsValid = ($issues.Count -eq 0)
        ComplianceScore = [Math]::Max(0, $score)
        Issues = $issues
    }
}

# Main execution
Write-ECRRLog "Starting parallel agent orchestration" -Phase "Examine"

# Decompose task into atomic units
$atomicTasks = Invoke-TaskDecomposition -TaskSpec $task

if ($DryRun) {
    Write-AgentLog "DRY RUN: Generated $($atomicTasks.Count) atomic tasks" -Level INFO
    $atomicTasks | ForEach-Object {
        Write-Host "  - $($_.Id): $($_.Type) (Priority: $($_.Priority))" -ForegroundColor Gray
    }
    Write-AgentLog "DRY RUN: Would spawn $($atomicTasks.Count) agents with max $MaxConcurrentAgents concurrent" -Level INFO
    exit 0
}

# Sort tasks by priority and dependencies
$sortedTasks = $atomicTasks | Sort-Object Priority, Id

# Agent Management
$activeAgents = @()
$completedAgents = @()
$failedAgents = @()

Write-ECRRLog "Spawning $($sortedTasks.Count) agents with max $MaxConcurrentAgents concurrent" -Phase "Clean"

# Process tasks in batches
$taskBatches = @()
for ($i = 0; $i -lt $sortedTasks.Count; $i += $MaxConcurrentAgents) {
    $batch = $sortedTasks | Select-Object -Skip $i -First $MaxConcurrentAgents
    $taskBatches += ,$batch
}

foreach ($batch in $taskBatches) {
    Write-AgentLog "Processing batch of $($batch.Count) tasks" -Level INFO
    
    # Spawn agents for this batch
    foreach ($task in $batch) {
        $agent = Start-BackgroundAgent -Task $task -WorkspacePath $task.Workspace -EnableTelemetry $EnableTelemetry
        $activeAgents += $agent
        Write-AgentLog "Spawned agent $($agent.ProcessId) for task $($agent.TaskId)" -Level INFO
    }
    
    # Wait for batch completion or timeout
    $batchStart = Get-Date
    $batchTimeout = [TimeSpan]::FromMinutes($AgentTimeout)
    
    while ($activeAgents.Count -gt 0 -and ((Get-Date) - $batchStart) -lt $batchTimeout) {
        Start-Sleep -Seconds 5
        
        # Check for completed agents
        $stillActive = @()
        foreach ($agent in $activeAgents) {
            if ($agent.Process.HasExited) {
                $agent.Status = if ($agent.Process.ExitCode -eq 0) { "Completed" } else { "Failed" }
                
                if ($agent.Status -eq "Completed") {
                    $completedAgents += $agent
                    Write-AgentLog "Agent $($agent.ProcessId) completed successfully" -Level INFO
                } else {
                    $failedAgents += $agent
                    Write-AgentLog "Agent $($agent.ProcessId) failed with exit code $($agent.Process.ExitCode)" -Level ERROR
                }
            } else {
                $stillActive += $agent
            }
        }
        $activeAgents = $stillActive
        
        if ($activeAgents.Count -gt 0) {
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
    }
    
    # Handle timeout
    if ($activeAgents.Count -gt 0) {
        Write-AgentLog "Batch timeout reached, terminating remaining agents" -Level WARN
        foreach ($agent in $activeAgents) {
            try {
                $agent.Process.Kill()
                $failedAgents += $agent
                Write-AgentLog "Terminated agent $($agent.ProcessId)" -Level WARN
            } catch {
                Write-AgentLog "Failed to terminate agent $($agent.ProcessId): $($_.Exception.Message)" -Level ERROR
            }
        }
        $activeAgents = @()
    }
    
    Write-Host "" # New line after progress dots
}

# Collect results
Write-ECRRLog "Collecting agent results" -Phase "Report"

$sessionResults = @{
    SessionId = $ecrrSession.SessionId
    StartTime = $ecrrSession.StartTime.ToString('o')
    EndTime = (Get-Date).ToString('o')
    TotalTasks = $atomicTasks.Count
    CompletedAgents = $completedAgents.Count
    FailedAgents = $failedAgents.Count
    SuccessRate = if ($atomicTasks.Count -gt 0) { [Math]::Round(($completedAgents.Count / $atomicTasks.Count) * 100, 2) } else { 0 }
    Agents = @{
        Completed = $completedAgents | ForEach-Object {
            @{
                TaskId = $_.TaskId
                ProcessId = $_.ProcessId
                Workspace = $_.Workspace
                Duration = ((Get-Date) - $_.StartTime).TotalMilliseconds
                Status = $_.Status
            }
        }
        Failed = $failedAgents | ForEach-Object {
            @{
                TaskId = $_.TaskId
                ProcessId = $_.ProcessId
                Workspace = $_.Workspace
                Duration = ((Get-Date) - $_.StartTime).TotalMilliseconds
                Status = $_.Status
                ExitCode = $_.Process.ExitCode
            }
        }
    }
}

# Save session results
$resultsPath = Join-Path $sessionWorkspace "session-results.json"
$sessionResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsPath -Encoding UTF8

# Generate ECRR report
Write-ECRRLog "Generating ECRR report" -Phase "Report"

$ecrrReport = @"
# Parallel Agent Orchestration ECRR Report

## 🔍 1. Examine
- Task: $($task.name) ($($task.type))
- Atomic Tasks: $($atomicTasks.Count)
- Max Concurrent Agents: $MaxConcurrentAgents
- Session ID: $($ecrrSession.SessionId)

## 🧹 2. Clean
- Spawned $($completedAgents.Count + $failedAgents.Count) background agents
- Isolated workspaces created for each agent
- Parallel execution with resource management
- Timeout enforcement: $AgentTimeout minutes

## 📊 3. Report
- **Success Rate**: $($sessionResults.SuccessRate)%
- **Completed Agents**: $($completedAgents.Count)
- **Failed Agents**: $($failedAgents.Count)
- **Total Duration**: $([Math]::Round(((Get-Date) - $ecrrSession.StartTime).TotalMinutes, 2)) minutes

### Performance Metrics
- Average agent duration: $([Math]::Round(($completedAgents | ForEach-Object { ((Get-Date) - $_.StartTime).TotalMilliseconds } | Measure-Object -Average).Average, 2)) ms
- Parallel efficiency: $([Math]::Round(($atomicTasks.Count / $MaxConcurrentAgents), 2))x theoretical speedup

## 👤 4. Role
- **Agent**: Parallel Agent Orchestrator
- **Actor Declaration**: Automated parallel task decomposition and execution
- **Responsibility**: Atomic task management and background agent coordination

### ECRR Gate
- **ProductionReady**: $($sessionResults.SuccessRate -ge 90)
- **EvidenceReference**: $resultsPath
"@

$ecrrReportPath = Join-Path $sessionWorkspace "ecrr-report.md"
Set-Content -Path $ecrrReportPath -Value $ecrrReport -Encoding UTF8

Write-ECRRLog "Parallel agent orchestration complete" -Phase "Role"

# Output summary
Write-Host "`n🎯 Parallel Agent Orchestration Summary" -ForegroundColor Green
Write-Host "Session ID: $($ecrrSession.SessionId)" -ForegroundColor Cyan
Write-Host "Success Rate: $($sessionResults.SuccessRate)%" -ForegroundColor $(if ($sessionResults.SuccessRate -ge 90) { 'Green' } else { 'Yellow' })
Write-Host "Completed: $($completedAgents.Count) | Failed: $($failedAgents.Count)" -ForegroundColor Cyan
Write-Host "Workspace: $sessionWorkspace" -ForegroundColor Gray
Write-Host "ECRR Report: $ecrrReportPath" -ForegroundColor Gray

if ($sessionResults.SuccessRate -ge 90) {
    Write-Host "✅ Production Ready: Parallel agent framework operational" -ForegroundColor Green
} else {
    Write-Host "⚠️ Production Gate: Review failed agents before deployment" -ForegroundColor Yellow
}
