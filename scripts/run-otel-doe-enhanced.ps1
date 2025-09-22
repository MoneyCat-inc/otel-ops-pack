#Requires -Version 7.0

<#
.SYNOPSIS
    Enhanced DOE harness with parallel execution, latency focus, and stage budgets

.DESCRIPTION
    Redesigned DOE harness that runs experiments in parallel, focuses on latency
    measurements, and includes stage budgets for faster completion.

.PARAMETER DryRun
    Generate batch plan and configs without executing experiments

.PARAMETER Stage
    Experiment stage (stage1, stage2). Default: stage1

.PARAMETER Replicates
    Number of replicates per run. Default: 3

.PARAMETER LoadCommand
    Command to execute for load generation (default: synthetic load)

.PARAMETER Duration
    Maximum experiment duration in seconds. Default: 300

.PARAMETER StageBudget
    Maximum duration per stage in seconds. Default: 120

.PARAMETER Parallelism
    Number of parallel workers. Default: 2

.PARAMETER MatrixPath
    Path to experiment matrix CSV. Default: experiments/doe/stage1-matrix.csv

.PARAMETER OutputDir
    Output directory for artifacts. Default: artifacts/doe

.PARAMETER SmokeMode
    Run a single 60-second smoke test

.PARAMETER LatencySLA
    Latency SLA threshold in milliseconds. Default: 200

.PARAMETER SkipPreflight
    Skip pre-flight readiness checks

.EXAMPLE
    .\run-otel-doe-enhanced.ps1 -DryRun
    Generate batch plan without executing experiments

.EXAMPLE
    .\run-otel-doe-enhanced.ps1 -SmokeMode
    Run 60-second smoke test

.EXAMPLE
    .\run-otel-doe-enhanced.ps1 -Parallelism 3 -StageBudget 90
    Run with 3 parallel workers and 90-second stage budgets
#>

param(
    [switch]$DryRun,
    [string]$Stage = "stage1",
    [int]$Replicates = 3,
    [string]$LoadCommand = "pwsh -File scripts/generate-synthetic-load.ps1",
    [int]$Duration = 300,
    [int]$StageBudget = 120,
    [int]$Parallelism = 2,
    [string]$MatrixPath = "experiments/doe/stage1-matrix.csv",
    [string]$OutputDir = "artifacts/doe",
    [switch]$SmokeMode,
    [int]$LatencySLA = 200,
    [switch]$SkipPreflight
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Enhanced DOE Harness" -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green

# Validate inputs
if (-not (Test-Path $MatrixPath)) {
    throw "Matrix file not found: $MatrixPath"
}

if (-not (Test-Path "templates/collector-doe-template.yaml")) {
    throw "Template file not found: templates/collector-doe-template.yaml"
}

# Pre-flight checks
if (-not $SkipPreflight) {
    Write-Host "`nRunning pre-flight checks..." -ForegroundColor Cyan
    try {
        $preflightArgs = @()
        
if ($SmokeMode) {
            $preflightArgs += "-SmokeMode"
        }
        
        $preflightResult = & "pwsh" -File "scripts/check-latency-readiness.ps1" @preflightArgs
        if ($LASTEXITCODE -ne 0) {
            throw "Pre-flight checks failed"
        }
        Write-Host "[OK] Pre-flight checks passed" -ForegroundColor Green
    } catch {
        Write-Error "Pre-flight checks failed: $($_.Exception.Message)"
        exit 1
    }
}

# Create output directories
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = Join-Path $OutputDir "$Stage-$timestamp"
$configsDir = Join-Path $runDir "configs"
$resultsDir = Join-Path $runDir "results"
$logsDir = Join-Path $runDir "logs"
$baselinesDir = Join-Path $runDir "baselines"

@($runDir, $configsDir, $resultsDir, $logsDir, $baselinesDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

Write-Host "Output directory: $runDir" -ForegroundColor Yellow

# Load experiment matrix
Write-Host "Loading experiment matrix from: $MatrixPath" -ForegroundColor Cyan
$matrix = Import-Csv $MatrixPath
Write-Host "Loaded $($matrix.Count) experiment configurations" -ForegroundColor Green

# Generate run plan
$runPlan = @{
    experiment = @{
        stage = $Stage
        timestamp = $timestamp
        duration = $Duration
        stageBudget = $StageBudget
        replicates = $Replicates
        loadCommand = $LoadCommand
        parallelism = $Parallelism
        latencySLA = $LatencySLA
        smokeMode = $SmokeMode
    }
    runs = @()
    artifacts = @{
        runDir = $runDir
        configsDir = $configsDir
        resultsDir = $resultsDir
        logsDir = $logsDir
        baselinesDir = $baselinesDir
    }
}

# Generate configurations and run plans
$runCounter = 1
foreach ($row in $matrix) {
    for ($replicate = 1; $replicate -le $Replicates; $replicate++) {
        $runId = "$($row.run_label)-r$replicate-$timestamp"
        $configFile = Join-Path $configsDir "$runId.yaml"
        
        # Generate randomized port assignments to avoid conflicts
        $basePort = 5000 + ($runCounter % 100) * 10
        $grpcPort = $basePort + 1
        $httpPort = $basePort + 2
        $healthPort = $basePort + 3
        $pprofPort = $basePort + 4
        $metricsPort = $basePort + 5
        
        # Load template and substitute variables
        $template = Get-Content "templates/collector-doe-template.yaml" -Raw
        
        # Replace template variables
        $template = $template -replace '\{\{INGEST_GRPC_PORT\}\}', $grpcPort
        $template = $template -replace '\{\{INGEST_HTTP_PORT\}\}', $httpPort
        $template = $template -replace '\{\{HEALTH_PORT\}\}', $healthPort
        $template = $template -replace '\{\{PPROF_PORT\}\}', $pprofPort
        $template = $template -replace '\{\{METRICS_PORT\}\}', $metricsPort
        $template = $template -replace '\{\{MEMORY_LIMIT_MIB\}\}', $row.memory_limit_mib
        $template = $template -replace '\{\{TRACES_TIMEOUT_MS\}\}', $row.traces_timeout_ms
        $template = $template -replace '\{\{METRICS_TIMEOUT_MS\}\}', $row.metrics_timeout_ms
        $template = $template -replace '\{\{LOGS_TIMEOUT_MS\}\}', $row.logs_timeout_ms
        $template = $template -replace '\{\{SEND_BATCH_MAX_SIZE\}\}', $row.send_batch_max_size
        $template = $template -replace '\{\{QUEUE_SIZE\}\}', $row.queue_size
        $template = $template -replace '\{\{NUM_CONSUMERS\}\}', $row.num_consumers
        $template = $template -replace '\{\{COMPRESSION\}\}', $row.compression
        $template = $template -replace '\{\{RETRY_MAX_ELAPSED_MINUTES\}\}', $row.retry_max_elapsed_minutes
        $template = $template -replace '\{\{RUN_ID\}\}', $runId
        $template = $template -replace '\{\{RUN_STAGE\}\}', $Stage
        $template = $template -replace '\{\{RUN_LABEL\}\}', $row.run_label
        $template = $template -replace '\{\{EXPERIMENT_TIMESTAMP\}\}', $timestamp
        
        # Write generated config
        Set-Content -Path $configFile -Value $template -NoNewline
        
        # Add to run plan
        $runPlan.runs += @{
            runId = $runId
            runLabel = $row.run_label
            replicate = $replicate
            configFile = $configFile
            ports = @{
                grpc = $grpcPort
                http = $httpPort
                health = $healthPort
                pprof = $pprofPort
                metrics = $metricsPort
            }
            factors = $row
            startTime = $null
            endTime = $null
            status = "pending"
            latencyResults = $null
            meetsSLA = $null
            artifacts = @{
                logFile = Join-Path $logsDir "$runId.log"
                metricsFile = Join-Path $resultsDir "$runId-metrics.json"
                resultFile = Join-Path $resultsDir "$runId-result.json"
                latencyFile = Join-Path $resultsDir "$runId-latency.json"
            }
        }
        
        $runCounter++
    }
}

# Save batch plan
$planFile = Join-Path $runDir "batch-plan.json"
$runPlan | ConvertTo-Json -Depth 10 | Set-Content $planFile
Write-Host "Generated batch plan: $planFile" -ForegroundColor Green
Write-Host "Total runs planned: $($runPlan.runs.Count)" -ForegroundColor Green

if ($DryRun) {
    Write-Host "DRY RUN COMPLETE" -ForegroundColor Yellow
    Write-Host "Configurations generated in: $configsDir" -ForegroundColor Cyan
    Write-Host "To execute experiments, run without -DryRun flag" -ForegroundColor Yellow
    return
}

# Smoke mode: single 60-second test
# Script block to execute a single experiment run
$experimentRunner = {
    param(
        [object]$Run,
        [int]$Duration,
        [int]$StageBudget,
        [int]$LatencySLA,
        [string]$LoadCommand,
        [string]$Stage
    )

    # Stop any existing collector service
    try {
        Stop-Service -Name "otelcol-contrib" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    } catch {
        Write-Warning "Could not stop existing collector service"
    }

    try {
        $serviceConfigPath = "C:\otel\config.yaml"
        Copy-Item -Path $Run.configFile -Destination $serviceConfigPath -Force

        Start-Service -Name "otelcol-contrib" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5

        $healthResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 10
        if ($healthResponse.status -ne "Serving") {
            throw "Collector health check failed"
        }
    } catch {
        throw "Failed to start collector: $($_.Exception.Message)"
    }

    $actualDuration = [math]::Min($Duration, $StageBudget)
    Write-Host "  Executing load generation for $actualDuration seconds..." -ForegroundColor Yellow

    $loadCommandExpanded = "$LoadCommand -Duration $actualDuration -OTLPEndpoint http://localhost:5318 -RunId $($Run.runId) -Stage $Stage"
    $loadProcess = Start-Process -FilePath "pwsh" -ArgumentList @("-Command", $loadCommandExpanded) -PassThru -NoNewWindow
    $loadProcess.WaitForExit($actualDuration * 1000 + 30000)

    if (-not $loadProcess.HasExited) {
        Write-Warning "Load generation timed out, terminating..."
        $loadProcess.Kill()
    }

    Start-Sleep -Seconds 10

    try {
        $latencyMeasurements = & "pwsh" -File "scripts/extract-latency-measurements.ps1" -RunId $Run.runId -TimeRange 5 -FailOnMissingData
        $latencyMeasurements | ConvertTo-Json -Depth 10 | Set-Content $Run.artifacts.latencyFile
        $meetsSLA = $latencyMeasurements.latency.p95_ms -le $LatencySLA
        return @{
            latencyResults = $latencyMeasurements.latency
            meetsSLA = $meetsSLA
        }
    } catch {
        throw "Latency extraction failed: $($_.Exception.Message)"
    }
}

if ($SmokeMode) {
    Write-Host "`nRunning smoke test (60 seconds)..." -ForegroundColor Cyan
    
    $smokeRun = $runPlan.runs[0]
    $smokeRun.status = "running"
    $smokeRun.startTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    
    try {
        # Execute smoke test
        $smokeResult = & $experimentRunner $smokeRun 60 60 $LatencySLA $LoadCommand $Stage
        $smokeRun.status = "completed"
        $smokeRun.endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $smokeRun.latencyResults = $smokeResult.latencyResults
        $smokeRun.meetsSLA = $smokeResult.meetsSLA
        
        Write-Host "[OK] Smoke test completed" -ForegroundColor Green
        Write-Host "  Latency: p95=$($smokeResult.latencyResults.p95_ms)ms" -ForegroundColor White
        Write-Host "  Meets SLA: $($smokeResult.meetsSLA)" -ForegroundColor White
        
    } catch {
        Write-Error "Smoke test failed: $($_.Exception.Message)"
        $smokeRun.status = "failed"
        $smokeRun.endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    # Save results
    $runPlan | ConvertTo-Json -Depth 10 | Set-Content $planFile
    return
}

# Execute experiments in parallel
Write-Host "`nStarting parallel experiment execution..." -ForegroundColor Green
Write-Host "Parallelism: $Parallelism workers" -ForegroundColor Cyan
Write-Host "Stage budget: $StageBudget seconds" -ForegroundColor Cyan

$completedRuns = 0
$totalRuns = $runPlan.runs.Count
$runsToProcess = $runPlan.runs | Where-Object { $_.status -eq "pending" }


# Process runs in parallel batches
$batches = @()
for ($i = 0; $i -lt $runsToProcess.Count; $i += $Parallelism) {
    $batch = $runsToProcess | Select-Object -Skip $i -First $Parallelism
    $batches += ,$batch
}

foreach ($batch in $batches) {
    Write-Host "`nProcessing batch of $($batch.Count) runs..." -ForegroundColor Cyan
    
    $batch | ForEach-Object -Parallel {
        $run = $_
        $runDir = $using:runDir
        $planFile = $using:planFile
        $LatencySLA = $using:LatencySLA
        $StageBudget = $using:StageBudget
        $Duration = $using:Duration
        $LoadCommand = $using:LoadCommand
        $Stage = $using:Stage
        
        try {
            Write-Host "Starting run: $($run.runId)" -ForegroundColor Yellow
            
            # Update run status
            $run.status = "running"
            $run.startTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            
            # Execute experiment
            $result = & $using:experimentRunner $run $Duration $StageBudget $LatencySLA $LoadCommand $Stage
            
            $run.status = "completed"
            $run.endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            $run.latencyResults = $result.latencyResults
            $run.meetsSLA = $result.meetsSLA
            
            Write-Host "[OK] Completed run: $($run.runId) - p95=$($result.latencyResults.p95_ms)ms, SLA=$($result.meetsSLA)" -ForegroundColor Green
            
        } catch {
            Write-Error "Failed run $($run.runId): $($_.Exception.Message)"
            $run.status = "failed"
            $run.endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    } -ThrottleLimit $Parallelism
    
    # Update progress
    $completedRuns += $batch.Count
    Write-Host "Batch completed: $completedRuns/$totalRuns runs" -ForegroundColor Cyan
    
    # Save updated plan
    $runPlan | ConvertTo-Json -Depth 10 | Set-Content $planFile
}

# Generate summary
$summary = @{
    experiment = $runPlan.experiment
    totalRuns = $totalRuns
    completedRuns = ($runPlan.runs | Where-Object { $_.status -eq "completed" }).Count
    failedRuns = ($runPlan.runs | Where-Object { $_.status -eq "failed" }).Count
    slaCompliantRuns = ($runPlan.runs | Where-Object { $_.meetsSLA -eq $true }).Count
    artifacts = $runPlan.artifacts
    completedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    latencySummary = @{
        avgP95 = [math]::Round(($runPlan.runs | Where-Object { $_.latencyResults.p95_ms } | Measure-Object -Property { $_.latencyResults.p95_ms } -Average).Average, 2)
        minP95 = [math]::Round(($runPlan.runs | Where-Object { $_.latencyResults.p95_ms } | Measure-Object -Property { $_.latencyResults.p95_ms } -Minimum).Minimum, 2)
        maxP95 = [math]::Round(($runPlan.runs | Where-Object { $_.latencyResults.p95_ms } | Measure-Object -Property { $_.latencyResults.p95_ms } -Maximum).Maximum, 2)
    }
}

$summaryFile = Join-Path $runDir "experiment-summary.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content $summaryFile

Write-Host "`nExperiment execution completed!" -ForegroundColor Green
Write-Host "Summary: $($summary.completedRuns)/$($summary.totalRuns) runs completed" -ForegroundColor Cyan
Write-Host "SLA Compliant: $($summary.slaCompliantRuns)/$($summary.completedRuns) runs" -ForegroundColor Cyan
Write-Host "Latency: avg p95=$($summary.latencySummary.avgP95)ms, min=$($summary.latencySummary.minP95)ms, max=$($summary.latencySummary.maxP95)ms" -ForegroundColor Cyan
Write-Host "Results saved to: $runDir" -ForegroundColor Yellow

if ($summary.failedRuns -gt 0) {
    Write-Warning "$($summary.failedRuns) runs failed - check logs for details"
}




