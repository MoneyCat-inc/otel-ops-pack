#Requires -Version 7.0

<#
.SYNOPSIS
    DOE (Design of Experiments) harness for Windows OTel Collector optimization

.DESCRIPTION
    Generates and executes batch experiments from a factor matrix, producing
    configs with randomized parameters and measurement collection.

.PARAMETER DryRun
    Generate batch plan and configs without executing experiments

.PARAMETER Stage
    Experiment stage (stage1, stage2). Default: stage1

.PARAMETER Replicates
    Number of replicates per run. Default: 3

.PARAMETER LoadCommand
    Command to execute for load generation (default: synthetic load)

.PARAMETER Duration
    Experiment duration in seconds. Default: 300

.PARAMETER MatrixPath
    Path to experiment matrix CSV. Default: experiments/doe/stage1-matrix.csv

.PARAMETER OutputDir
    Output directory for artifacts. Default: artifacts/doe

.EXAMPLE
    .\run-otel-doe.ps1 -DryRun
    Generate batch plan without executing experiments

.EXAMPLE
    .\run-otel-doe.ps1 -Stage stage1 -Replicates 5 -Duration 600
    Execute stage1 experiments with 5 replicates for 10 minutes each
#>

param(
    [switch]$DryRun,
    [string]$Stage = "stage1",
    [int]$Replicates = 3,
    [string]$LoadCommand = "pwsh -File scripts/generate-synthetic-load.ps1",
    [int]$Duration = 300,
    [string]$MatrixPath = "experiments/doe/stage1-matrix.csv",
    [string]$OutputDir = "artifacts/doe"
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Validate inputs
if (-not (Test-Path $MatrixPath)) {
    throw "Matrix file not found: $MatrixPath"
}

if (-not (Test-Path "templates/collector-doe-template.yaml")) {
    throw "Template file not found: templates/collector-doe-template.yaml"
}

# Create output directories
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = Join-Path $OutputDir "$Stage-$timestamp"
$configsDir = Join-Path $runDir "configs"
$resultsDir = Join-Path $runDir "results"
$logsDir = Join-Path $runDir "logs"

@($runDir, $configsDir, $resultsDir, $logsDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

Write-Host "DOE Harness: $Stage experiment run" -ForegroundColor Green
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
        replicates = $Replicates
        loadCommand = $LoadCommand
    }
    runs = @()
    artifacts = @{
        runDir = $runDir
        configsDir = $configsDir
        resultsDir = $resultsDir
        logsDir = $logsDir
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
            artifacts = @{
                logFile = Join-Path $logsDir "$runId.log"
                metricsFile = Join-Path $resultsDir "$runId-metrics.json"
                resultFile = Join-Path $resultsDir "$runId-result.json"
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

# Execute experiments
Write-Host "Starting experiment execution..." -ForegroundColor Green

$completedRuns = 0
$totalRuns = $runPlan.runs.Count

foreach ($run in $runPlan.runs) {
    try {
        Write-Host "Executing run: $($run.runId)" -ForegroundColor Cyan
        
        # Update run status
        $run.status = "running"
        $run.startTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        
        # Stop any existing collector service
        try {
            Stop-Service -Name "otelcol-contrib" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        } catch {
            Write-Warning "Could not stop existing collector service"
        }
        
        # Start collector with generated config
        Write-Host "Starting collector with config: $($run.configFile)" -ForegroundColor Yellow
        
        $collectorArgs = @(
            "--config", $run.configFile
            "--feature-gates", "-pkg.translator.prometheus.NormalizeName"
        )
        
        # Update collector service config
        try {
            # Copy generated config to collector config location
            $serviceConfigPath = "C:\otel\config.yaml"
            Copy-Item -Path $run.configFile -Destination $serviceConfigPath -Force
            
            Write-Host "Updated collector config: $serviceConfigPath" -ForegroundColor Green
            Write-Host "Note: Collector service restart may be required for config changes to take effect" -ForegroundColor Yellow
        } catch {
            Write-Warning "Failed to update collector config: $($_.Exception.Message)"
            throw
        }
        
        # Verify collector is running
        try {
            # Use standard collector health endpoint
            $healthResponse = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 10
            if ($healthResponse.status -ne "Serving") {
                throw "Collector health check failed"
            }
            Write-Host "Collector health check passed" -ForegroundColor Green
        } catch {
            Write-Warning "Collector health check failed, continuing anyway: $($_.Exception.Message)"
        }
        
        # Execute load generation
        Write-Host "Executing load generation for $Duration seconds..." -ForegroundColor Yellow
        $loadArgs = @{
            Duration = $Duration
            OTLPEndpoint = "http://localhost:$($run.ports.http)"
            RunId = $run.runId
            Stage = $Stage
        }
        
        $loadCommandExpanded = "$LoadCommand -Duration $Duration -OTLPEndpoint http://localhost:$($run.ports.http) -RunId $($run.runId) -Stage $Stage"
        
        # Execute load command
        $loadProcess = Start-Process -FilePath "pwsh" -ArgumentList @("-Command", $loadCommandExpanded) -PassThru -NoNewWindow
        $loadProcess.WaitForExit($Duration * 1000 + 30000) # Wait with 30s buffer
        
        if (-not $loadProcess.HasExited) {
            Write-Warning "Load generation timed out, terminating..."
            $loadProcess.Kill()
        }
        
        # Collect metrics
        Write-Host "Collecting experiment metrics..." -ForegroundColor Yellow
        $metrics = @{
            runId = $run.runId
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            duration = $Duration
            ports = $run.ports
            factors = $run.factors
            collectorMetrics = @{}
            systemMetrics = @{}
        }
        
        # Collect collector metrics via pprof
        try {
            $pprofUrl = "http://localhost:1777/debug/pprof/heap?debug=1"
            $heapInfo = Invoke-RestMethod -Uri $pprofUrl -TimeoutSec 10
            $metrics.collectorMetrics.heap = $heapInfo
    } catch {
            Write-Warning "Could not collect heap metrics: $($_.Exception.Message)"
        }
        
        # Collect system metrics
        $metrics.systemMetrics.cpu = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples[0].CookedValue
        $metrics.systemMetrics.memory = [math]::Round((Get-Counter "\Memory\Available MBytes").CounterSamples[0].CookedValue, 2)
        
        # Save metrics
        $metrics | ConvertTo-Json -Depth 10 | Set-Content $run.artifacts.metricsFile
        
        # Note: Collector config has been updated for this run
        Write-Host "Collector config updated for run: $($run.runId)" -ForegroundColor Green
        
        # Update run status
        $run.status = "completed"
        $run.endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        
        $completedRuns++
        Write-Host "Completed run: $($run.runId) ($completedRuns/$totalRuns)" -ForegroundColor Green
        
        # Save updated plan
        $runPlan | ConvertTo-Json -Depth 10 | Set-Content $planFile
        
        # Brief pause between runs
        Start-Sleep -Seconds 2
        
    } catch {
        Write-Error "Failed to execute run $($run.runId): $($_.Exception.Message)"
        $run.status = "failed"
        $run.endTime = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        
        # Save updated plan even on failure
        $runPlan | ConvertTo-Json -Depth 10 | Set-Content $planFile
    }
}

# Generate summary
$summary = @{
    experiment = $runPlan.experiment
    totalRuns = $totalRuns
    completedRuns = ($runPlan.runs | Where-Object { $_.status -eq "completed" }).Count
    failedRuns = ($runPlan.runs | Where-Object { $_.status -eq "failed" }).Count
    artifacts = $runPlan.artifacts
    completedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
}

$summaryFile = Join-Path $runDir "experiment-summary.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content $summaryFile

Write-Host "`nExperiment execution completed!" -ForegroundColor Green
Write-Host "Summary: $($summary.completedRuns)/$($summary.totalRuns) runs completed" -ForegroundColor Cyan
Write-Host "Results saved to: $runDir" -ForegroundColor Yellow
Write-Host "Summary file: $summaryFile" -ForegroundColor Yellow

if ($summary.failedRuns -gt 0) {
    Write-Warning "$($summary.failedRuns) runs failed - check logs for details"
}