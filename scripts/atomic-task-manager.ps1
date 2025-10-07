#Requires -Version 7.0

<#
.SYNOPSIS
    Atomic Task Manager for Bosscat Parallel Agent Framework
    Manages task decomposition, dependency resolution, and execution planning

.DESCRIPTION
    This module provides atomic task decomposition capabilities, breaking down complex
    workflows into parallel-friendly units with proper dependency management and
    resource optimization.

.PARAMETER TaskDefinition
    JSON definition of the task to decompose

.PARAMETER DecompositionStrategy
    Strategy for task decomposition (parallel, sequential, hybrid)

.PARAMETER ResourceConstraints
    Resource constraints for task execution

.EXAMPLE
    .\atomic-task-manager.ps1 -TaskDefinition @'
    {
        "name": "ecrr-compliance-audit",
        "type": "audit",
        "scope": ["docs/ecrr", "docs/observability"],
        "parallelism": "high"
    }
    '@ -DecompositionStrategy "parallel"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TaskDefinition,
    
    [ValidateSet('parallel', 'sequential', 'hybrid')]
    [string]$DecompositionStrategy = 'parallel',
    
    [hashtable]$ResourceConstraints = @{
        MaxConcurrent = $env:NUMBER_OF_PROCESSORS
        MemoryLimitMB = 2048
        TimeoutMinutes = 30
    },
    
    [string]$OutputPath = 'artifacts/task-plans',
    
    [switch]$EnableDependencyAnalysis,
    
    [switch]$OptimizeForLatency
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Task Decomposition Strategies
class TaskDecomposer {
    [string]$Strategy
    [hashtable]$Constraints
    
    TaskDecomposer([string]$strategy, [hashtable]$constraints) {
        $this.Strategy = $strategy
        $this.Constraints = $constraints
    }
    
    [object[]] DecomposeTask([object]$taskDef) {
        $result = $null
        
        switch ($this.Strategy) {
            'parallel' { 
                $result = $this.DecomposeParallel($taskDef)
                break
            }
            'sequential' {
                $result = $this.DecomposeSequential($taskDef)
                break
            }
            'hybrid' {
                $result = $this.DecomposeHybrid($taskDef)
                break
            }
            default {
                throw [System.InvalidOperationException]::new("Unknown decomposition strategy: $($this.Strategy)")
            }
        }
        
        if ($null -eq $result) {
            return @()
        }
        
        return [object[]]$result
    }
    
    [object[]] DecomposeParallel([object]$taskDef) {
        $atomicTasks = @()
        
        switch ($taskDef.type) {
            'batch-processing' {
                $atomicTasks += $this.CreateBatchProcessingTasks($taskDef)
            }
            'file-processing' {
                $atomicTasks += $this.CreateFileProcessingTasks($taskDef)
            }
            'api-testing' {
                $atomicTasks += $this.CreateApiTestingTasks($taskDef)
            }
            'audit' {
                $atomicTasks += $this.CreateAuditTasks($taskDef)
            }
            'monitoring' {
                $atomicTasks += $this.CreateMonitoringTasks($taskDef)
            }
            default {
                $atomicTasks += $this.CreateGenericTasks($taskDef)
            }
        }
        
        return $atomicTasks
    }
    
    [object[]] DecomposeSequential([object]$taskDef) {
        # Sequential decomposition with dependency chains
        $atomicTasks = @()
        
        # Create dependency chain based on task type
        switch ($taskDef.type) {
            'deployment' {
                $atomicTasks += @(
                    $this.CreateTask('pre-deployment-check', 1, @()),
                    $this.CreateTask('build-artifacts', 2, @('pre-deployment-check')),
                    $this.CreateTask('deploy-staging', 3, @('build-artifacts')),
                    $this.CreateTask('run-tests', 4, @('deploy-staging')),
                    $this.CreateTask('deploy-production', 5, @('run-tests')),
                    $this.CreateTask('post-deployment-verification', 6, @('deploy-production'))
                )
            }
            'data-pipeline' {
                $atomicTasks += @(
                    $this.CreateTask('data-extraction', 1, @()),
                    $this.CreateTask('data-transformation', 2, @('data-extraction')),
                    $this.CreateTask('data-validation', 3, @('data-transformation')),
                    $this.CreateTask('data-loading', 4, @('data-validation')),
                    $this.CreateTask('pipeline-verification', 5, @('data-loading'))
                )
            }
            default {
                $atomicTasks += @(
                    $this.CreateTask('generic-sequential-task', 1, @())
                )
            }
        }
        
        return $atomicTasks
    }
    
    [object[]] DecomposeHybrid([object]$taskDef) {
        # Hybrid approach: parallel within phases, sequential between phases
        $phases = $this.IdentifyPhases($taskDef)
        $atomicTasks = @()
        $phaseDependencies = @()
        
        foreach ($phase in $phases) {
            $phaseTasks = $this.DecomposeParallel($phase)
            
            # Add dependencies from previous phase
            foreach ($task in $phaseTasks) {
                $task.Dependencies += $phaseDependencies
            }
            
            $atomicTasks += $phaseTasks
            $phaseDependencies = $phaseTasks | ForEach-Object { $_.Id }
        }
        
        return $atomicTasks
    }
    
    [object[]] CreateBatchProcessingTasks([object]$taskDef) {
        $tasks = @()
        $inputSection = $this.GetInputSection($taskDef)
        $itemCount = [int]($this.GetValue($inputSection, 'itemCount'))
        
        if ($itemCount -le 0) {
            return $tasks
        }
        
        $batchSize = $this.CalculateBatchSize($taskDef, $itemCount)
        $processingType = $this.GetValue($inputSection, 'processingType')
        
        for ($i = 0; $i -lt $itemCount; $i += $batchSize) {
            $endIndex = [Math]::Min($i + $batchSize - 1, $itemCount - 1)
            
            $tasks += $this.CreateTask(
                "batch-$i-$endIndex",
                1,
                @(),
                @{
                    StartIndex = $i
                    EndIndex = $endIndex
                    BatchSize = $batchSize
                    ProcessingType = $processingType
                }
            )
        }
        
        return $tasks
    }
    
    [object[]] CreateFileProcessingTasks([object]$taskDef) {
        $tasks = @()
        $files = Get-ChildItem $taskDef.scope -Recurse -File | Where-Object { $_.Extension -in $taskDef.fileTypes }
        
        # Group files by size for optimal parallelization
        $fileGroups = $files | Group-Object { [Math]::Floor($_.Length / 1MB) }
        
        foreach ($group in $fileGroups) {
            $tasks += $this.CreateTask(
                "file-group-$($group.Name)MB",
                1,
                @(),
                @{
                    Files = $group.Group.FullName
                    ProcessingType = $taskDef.processingType
                    GroupSize = $group.Count
                }
            )
        }
        
        return $tasks
    }
    
    [object[]] CreateApiTestingTasks([object]$taskDef) {
        $tasks = @()
        $endpoints = $taskDef.input.endpoints
        
        foreach ($endpoint in $endpoints) {
            $tasks += $this.CreateTask(
                "api-test-$($endpoint.name)",
                1,
                @(),
                @{
                    Endpoint = $endpoint.url
                    Method = $endpoint.method
                    Tests = $endpoint.tests
                    ExpectedResponse = $endpoint.expectedResponse
                }
            )
        }
        
        return $tasks
    }
    
    [object[]] CreateAuditTasks([object]$taskDef) {
        $tasks = @()
        $auditScopes = $taskDef.scope
        
        foreach ($scope in $auditScopes) {
            $tasks += $this.CreateTask(
                "audit-$($scope -replace '[^a-zA-Z0-9]', '-')",
                1,
                @(),
                @{
                    Scope = $scope
                    AuditType = $taskDef.auditType
                    Rules = $taskDef.rules
                    OutputFormat = $taskDef.outputFormat
                }
            )
        }
        
        return $tasks
    }
    
    [object[]] CreateMonitoringTasks([object]$taskDef) {
        $tasks = @()
        $monitoringTargets = $taskDef.targets
        
        foreach ($target in $monitoringTargets) {
            $tasks += $this.CreateTask(
                "monitor-$($target.name)",
                2, # Lower priority for monitoring
                @(),
                @{
                    Target = $target.url
                    Metrics = $target.metrics
                    Duration = $taskDef.duration
                    AlertThresholds = $target.thresholds
                }
            )
        }
        
        return $tasks
    }
    
    [object[]] CreateGenericTasks([object]$taskDef) {
        # Fallback for unknown task types
        return @(
            $this.CreateTask(
                "generic-task-1",
                1,
                @(),
                $taskDef.input
            )
        )
    }
    
    [object] CreateTask([string]$id, [int]$priority, [string[]]$dependencies, [hashtable]$input = @{}) {
        return [pscustomobject]@{
            Id = $id
            Type = "atomic"
            Priority = $priority
            Dependencies = $dependencies
            Input = $input
            Output = @{
                Artifacts = @()
                Metrics = @()
            }
            Timeout = $this.Constraints.TimeoutMinutes
            ResourceRequirements = @{
                MemoryMB = $this.Constraints.MemoryLimitMB
                CPU = 1
            }
            EstimatedDuration = $this.EstimateDuration($input)
            Workspace = "agent-workspace-$id"
        }
    }
    
    [int] CalculateBatchSize([object]$taskDef, [int]$itemCount) {
        if ($itemCount -le 0) {
            return 10
        }
        
        $maxConcurrent = [Math]::Max(1, [int]$this.Constraints.MaxConcurrent)
        
        # Calculate optimal batch size based on parallelism and item count
        $batchSize = [Math]::Ceiling($itemCount / $maxConcurrent)
        
        # Ensure minimum batch size for efficiency
        return [Math]::Max($batchSize, 10)
    }
    
    [object[]] IdentifyPhases([object]$taskDef) {
        # Identify logical phases for hybrid decomposition
        $phases = switch ($taskDef.type) {
            'deployment' {
                @(
                    @{ type = 'pre-deployment'; tasks = @('validation', 'build') },
                    @{ type = 'deployment'; tasks = @('staging', 'testing') },
                    @{ type = 'post-deployment'; tasks = @('production', 'verification') }
                )
            }
            'data-pipeline' {
                @(
                    @{ type = 'extraction'; tasks = @('source-validation', 'data-extraction') },
                    @{ type = 'transformation'; tasks = @('data-cleaning', 'transformation') },
                    @{ type = 'loading'; tasks = @('validation', 'loading', 'verification') }
                )
            }
            default {
                @(
                    @{ type = 'execution'; tasks = @($taskDef.type) }
                )
            }
        }
        
        if ($null -eq $phases) {
            return @()
        }
        
        return [object[]]$phases
    }
    
    [object] GetInputSection([object]$taskDef) {
        if ($null -eq $taskDef) {
            return $null
        }
        
        if ($taskDef -is [hashtable]) {
            if ($taskDef.ContainsKey('input')) {
                return $taskDef['input']
            }
        } elseif ($null -ne $taskDef.PSObject -and $taskDef.PSObject.Properties.Name -contains 'input') {
            return $taskDef.input
        }
        
        return $null
    }
    
    [object] GetValue([object]$source, [string]$key) {
        if ($null -eq $source) {
            return $null
        }
        
        if ($source -is [hashtable]) {
            if ($source.ContainsKey($key)) {
                return $source[$key]
            }
        } elseif ($null -ne $source.PSObject -and $source.PSObject.Properties.Name -contains $key) {
            return $source.$key
        }
        
        return $null
    }
    
    [int] EstimateDuration([hashtable]$input) {
        # Simple duration estimation based on input complexity
        $baseDuration = 5 # minutes
        
        if ($input.ContainsKey('BatchSize')) {
            $baseDuration += $input.BatchSize * 0.1
        }
        
        if ($input.ContainsKey('Files')) {
            $baseDuration += $input.Files.Count * 0.5
        }
        
        return [Math]::Min($baseDuration, $this.Constraints.TimeoutMinutes)
    }
}

# Dependency Resolution Engine
class DependencyResolver {
    [object[]]$Tasks
    
    DependencyResolver([object[]]$tasks) {
        $this.Tasks = $tasks
    }
    
    [object[]] ResolveDependencies() {
        $resolved = @()
        $unresolved = $this.Tasks.Clone()
        $iteration = 0
        $maxIterations = $unresolved.Count * 2
        
        while ($unresolved.Count -gt 0 -and $iteration -lt $maxIterations) {
            $iteration++
            $readyTasks = @()
            
            foreach ($task in $unresolved) {
                if ($this.AreDependenciesResolved($task, $resolved)) {
                    $readyTasks += $task
                }
            }
            
            if ($readyTasks.Count -eq 0) {
                # Circular dependency detected
                Write-Warning "Circular dependency detected. Remaining tasks: $($unresolved | ForEach-Object { $_.Id })"
                break
            }
            
            $resolved += $readyTasks
            $unresolved = $unresolved | Where-Object { $readyTasks -notcontains $_ }
        }
        
        return $resolved
    }
    
    [bool] AreDependenciesResolved([object]$task, [object[]]$resolved) {
        foreach ($dependency in $task.Dependencies) {
            if ($resolved | Where-Object { $_.Id -eq $dependency } | Measure-Object | Select-Object -ExpandProperty Count -eq 0) {
                return $false
            }
        }
        return $true
    }
    
    [object[]] OptimizeForLatency([object[]]$tasks) {
        # Optimize task order for minimum latency
        # Prioritize tasks with higher estimated duration and fewer dependencies
        
        return $tasks | Sort-Object {
            # Calculate priority score (higher is better)
            $durationScore = $_.EstimatedDuration * 10
            $dependencyPenalty = $_.Dependencies.Count * 5
            return $durationScore - $dependencyPenalty
        } -Descending
    }
}

# Resource Optimization Engine
class ResourceOptimizer {
    [hashtable]$Constraints
    [object[]]$Tasks
    
    ResourceOptimizer([hashtable]$constraints, [object[]]$tasks) {
        $this.Constraints = $constraints
        $this.Tasks = $tasks
    }
    
    [object[]] OptimizeResourceUsage() {
        # Group tasks by resource requirements
        $resourceGroups = $this.GroupByResources()
        
        # Optimize each group
        $optimizedTasks = @()
        foreach ($group in $resourceGroups) {
            $optimizedTasks += $this.OptimizeGroup($group)
        }
        
        return $optimizedTasks
    }
    
    [object[]] GroupByResources() {
        $groups = @{}
        
        foreach ($task in $this.Tasks) {
            $memoryTier = [Math]::Floor($task.ResourceRequirements.MemoryMB / 512) * 512
            $key = "memory-$memoryTier-cpu-$($task.ResourceRequirements.CPU)"
            
            if (-not $groups.ContainsKey($key)) {
                $groups[$key] = @()
            }
            $groups[$key] += $task
        }
        
        return $groups.Values
    }
    
    [object[]] OptimizeGroup([object[]]$group) {
        # Sort by priority and estimated duration
        return $group | Sort-Object Priority, EstimatedDuration
    }
    
    [object] CreateExecutionPlan([object[]]$tasks) {
        $plan = @{
            TotalTasks = $tasks.Count
            EstimatedTotalDuration = ($tasks | ForEach-Object { $_.EstimatedDuration } | Measure-Object -Sum).Sum
            ResourceUtilization = $this.CalculateResourceUtilization($tasks)
            ParallelEfficiency = $this.CalculateParallelEfficiency($tasks)
            ExecutionPhases = $this.CreateExecutionPhases($tasks)
        }
        
        return $plan
    }
    
    [hashtable] CalculateResourceUtilization([object[]]$tasks) {
        $totalMemory = ($tasks | ForEach-Object { $_.ResourceRequirements.MemoryMB } | Measure-Object -Sum).Sum
        $totalCPU = ($tasks | ForEach-Object { $_.ResourceRequirements.CPU } | Measure-Object -Sum).Sum
        
        return @{
            MemoryUtilization = [Math]::Min(100, ($totalMemory / ($this.Constraints.MaxConcurrent * $this.Constraints.MemoryLimitMB)) * 100)
            CPUUtilization = [Math]::Min(100, ($totalCPU / $this.Constraints.MaxConcurrent) * 100)
        }
    }
    
    [double] CalculateParallelEfficiency([object[]]$tasks) {
        $maxConcurrent = $this.Constraints.MaxConcurrent
        $theoreticalParallelism = [Math]::Min($tasks.Count, $maxConcurrent)
        
        return [Math]::Round(($theoreticalParallelism / $tasks.Count) * 100, 2)
    }
    
    [object[]] CreateExecutionPhases([object[]]$tasks) {
        $phases = @()
        $currentPhase = @{
            PhaseNumber = 1
            Tasks = @()
            EstimatedDuration = 0
            ResourceRequirements = @{ MemoryMB = 0; CPU = 0 }
        }
        
        $phaseResourceLimit = $this.Constraints.MemoryLimitMB * $this.Constraints.MaxConcurrent
        
        foreach ($task in $tasks) {
            $taskResources = $task.ResourceRequirements.MemoryMB * $task.ResourceRequirements.CPU
            
            if (($currentPhase.ResourceRequirements.MemoryMB + $task.ResourceRequirements.MemoryMB) -gt $phaseResourceLimit) {
                # Start new phase
                $phases += $currentPhase
                $currentPhase = @{
                    PhaseNumber = $phases.Count + 1
                    Tasks = @($task)
                    EstimatedDuration = $task.EstimatedDuration
                    ResourceRequirements = @{
                        MemoryMB = $task.ResourceRequirements.MemoryMB
                        CPU = $task.ResourceRequirements.CPU
                    }
                }
            } else {
                # Add to current phase
                $currentPhase.Tasks += $task
                $currentPhase.EstimatedDuration = [Math]::Max($currentPhase.EstimatedDuration, $task.EstimatedDuration)
                $currentPhase.ResourceRequirements.MemoryMB += $task.ResourceRequirements.MemoryMB
                $currentPhase.ResourceRequirements.CPU += $task.ResourceRequirements.CPU
            }
        }
        
        if ($currentPhase.Tasks.Count -gt 0) {
            $phases += $currentPhase
        }
        
        return $phases
    }
}

# Main execution
try {
    # Parse task definition
    $taskDef = $TaskDefinition | ConvertFrom-Json
    Write-Host "Parsed task definition: $($taskDef.name) ($($taskDef.type))" -ForegroundColor Green
    
    # Initialize decomposer
    $decomposer = [TaskDecomposer]::new($DecompositionStrategy, $ResourceConstraints)
    
    # Decompose task
    Write-Host "Decomposing task using $DecompositionStrategy strategy..." -ForegroundColor Cyan
    $atomicTasks = $decomposer.DecomposeTask($taskDef)
    Write-Host "Generated $($atomicTasks.Count) atomic tasks" -ForegroundColor Green
    
    # Resolve dependencies if enabled
    if ($EnableDependencyAnalysis) {
        Write-Host "Resolving task dependencies..." -ForegroundColor Cyan
        $resolver = [DependencyResolver]::new($atomicTasks)
        $atomicTasks = $resolver.ResolveDependencies()
        
        if ($OptimizeForLatency) {
            $atomicTasks = $resolver.OptimizeForLatency($atomicTasks)
            Write-Host "Optimized task order for latency" -ForegroundColor Green
        }
    }
    
    # Optimize resource usage
    Write-Host "Optimizing resource usage..." -ForegroundColor Cyan
    $optimizer = [ResourceOptimizer]::new($ResourceConstraints, $atomicTasks)
    $optimizedTasks = $optimizer.OptimizeResourceUsage()
    
    # Create execution plan
    $executionPlan = $optimizer.CreateExecutionPlan($optimizedTasks)
    
    # Save results
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $null = New-Item -ItemType Directory -Path $OutputPath -Force
    
    $taskPlan = @{
        Metadata = @{
            GeneratedAt = (Get-Date).ToString('o')
            TaskDefinition = $taskDef
            DecompositionStrategy = $DecompositionStrategy
            ResourceConstraints = $ResourceConstraints
        }
        ExecutionPlan = $executionPlan
        AtomicTasks = $optimizedTasks
    }
    
    $planPath = Join-Path $OutputPath "task-plan-$timestamp.json"
    $taskPlan | ConvertTo-Json -Depth 10 | Out-File -FilePath $planPath -Encoding UTF8
    
    # Generate summary report
    $summary = @"
# Atomic Task Decomposition Summary

## Task Overview
- **Name**: $($taskDef.name)
- **Type**: $($taskDef.type)
- **Strategy**: $DecompositionStrategy
- **Atomic Tasks**: $($optimizedTasks.Count)

## Execution Plan
- **Total Duration**: $($executionPlan.EstimatedTotalDuration) minutes
- **Memory Utilization**: $([Math]::Round($executionPlan.ResourceUtilization.MemoryUtilization, 2))%
- **CPU Utilization**: $([Math]::Round($executionPlan.ResourceUtilization.CPUUtilization, 2))%
- **Parallel Efficiency**: $($executionPlan.ParallelEfficiency)%
- **Execution Phases**: $($executionPlan.ExecutionPhases.Count)

## Resource Optimization
- **Max Concurrent**: $($ResourceConstraints.MaxConcurrent)
- **Memory Limit**: $($ResourceConstraints.MemoryLimitMB) MB per agent
- **Timeout**: $($ResourceConstraints.TimeoutMinutes) minutes

## Task Distribution
| Priority | Count | Avg Duration |
|----------|-------|--------------|
"@

    $priorityGroups = $optimizedTasks | Group-Object Priority | Sort-Object Name
    foreach ($group in $priorityGroups) {
        $avgDuration = ($group.Group | ForEach-Object { $_.EstimatedDuration } | Measure-Object -Average).Average
        $summary += "`n| $($group.Name) | $($group.Count) | $([Math]::Round($avgDuration, 2)) |"
    }
    
    $summary += "`n`n## Generated Files"
    $summary += "`n- Task Plan: $planPath"
    $summary += "`n- Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    
    $summaryPath = Join-Path $OutputPath "task-summary-$timestamp.md"
    Set-Content -Path $summaryPath -Value $summary -Encoding UTF8
    
    Write-Host "`n✅ Atomic task decomposition complete!" -ForegroundColor Green
    Write-Host "Task Plan: $planPath" -ForegroundColor Cyan
    Write-Host "Summary: $summaryPath" -ForegroundColor Cyan
    Write-Host "Atomic Tasks: $($optimizedTasks.Count)" -ForegroundColor Yellow
    Write-Host "Estimated Duration: $($executionPlan.EstimatedTotalDuration) minutes" -ForegroundColor Yellow
    Write-Host "Parallel Efficiency: $($executionPlan.ParallelEfficiency)%" -ForegroundColor Yellow
    
} catch {
    Write-Error "Atomic task decomposition failed: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}
