#Requires -Version 7.0

<#
.SYNOPSIS
    Enhanced DOE scoring tool for OTel Collector experiment evaluation

.DESCRIPTION
    Evaluates experiment results against SLOs and produces weighted efficiency rankings.
    Supports both real experiment data (with extracted measurements) and sample data generation.

.PARAMETER ExperimentDir
    Directory containing experiment results (batch-plan.json and measurements)

.PARAMETER SampleData
    Generate and score sample data instead of real experiment results

.PARAMETER OutputFile
    Output CSV file for rankings. Default: doe-scores.csv

.PARAMETER SLOConfig
    Path to SLO configuration file. Default: config/slo-config.json

.EXAMPLE
    .\score-otel-doe-enhanced.ps1 -SampleData
    Generate and score sample data for testing

.EXAMPLE
    .\score-otel-doe-enhanced.ps1 -ExperimentDir artifacts/doe/stage1-20240101-120000
    Score real experiment results with extracted measurements
#>

param(
    [string]$ExperimentDir,
    [switch]$SampleData,
    [string]$OutputFile = "doe-scores.csv",
    [string]$SLOConfig = "config/slo-config.json"
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# SLO Configuration
$defaultSLOs = @{
    latency = @{
        p95_ms = 100
        p99_ms = 500
        weight = 0.3
    }
    throughput = @{
        events_per_second = 1000
        weight = 0.25
    }
    resource_usage = @{
        cpu_percent = 80
        memory_mb = 1024
        weight = 0.25
    }
    reliability = @{
        error_rate_percent = 1.0
        availability_percent = 99.5
        weight = 0.2
    }
}

Write-Host "Enhanced DOE Scoring Tool" -ForegroundColor Green
Write-Host "SLO Configuration:" -ForegroundColor Cyan
$defaultSLOs | ConvertTo-Json -Depth 3 | Write-Host

# Load SLO configuration if exists
$slos = $defaultSLOs
if (Test-Path $SLOConfig) {
    try {
        $customSLOs = Get-Content $SLOConfig | ConvertFrom-Json
        # Convert PSCustomObject to Hashtable
        $slos = @{
            latency = @{
                p95_ms = $customSLOs.latency.p95_ms
                p99_ms = $customSLOs.latency.p99_ms
                weight = $customSLOs.latency.weight
            }
            throughput = @{
                events_per_second = $customSLOs.throughput.events_per_second
                weight = $customSLOs.throughput.weight
            }
            resource_usage = @{
                cpu_percent = $customSLOs.resource_usage.cpu_percent
                memory_mb = $customSLOs.resource_usage.memory_mb
                weight = $customSLOs.resource_usage.weight
            }
            reliability = @{
                error_rate_percent = $customSLOs.reliability.error_rate_percent
                availability_percent = $customSLOs.reliability.availability_percent
                weight = $customSLOs.reliability.weight
            }
        }
        Write-Host "Loaded custom SLO configuration from: $SLOConfig" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to load custom SLO config, using defaults"
    }
}

function Generate-SampleData {
    Write-Host "Generating sample experiment data..." -ForegroundColor Yellow
    
    $sampleRuns = @()
    $baseTimestamp = (Get-Date).AddHours(-2).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    
    # Generate sample data for 3 different configurations
    $configs = @(
        @{
            runLabel = "row01"
            factors = @{
                traces_timeout_ms = 100
                metrics_timeout_ms = 500
                logs_timeout_ms = 1000
                send_batch_max_size = 5000
                queue_size = 3000
                num_consumers = 1
                memory_limit_mib = 512
                compression = "gzip"
                retry_max_elapsed_minutes = 5
            }
            performance = @{
                latency_p95_ms = 85
                latency_p99_ms = 420
                throughput_eps = 1200
                cpu_percent = 65
                memory_mb = 480
                error_rate_percent = 0.2
                availability_percent = 99.8
            }
        },
        @{
            runLabel = "row12"
            factors = @{
                traces_timeout_ms = 500
                metrics_timeout_ms = 1000
                logs_timeout_ms = 5000
                send_batch_max_size = 20000
                queue_size = 3000
                num_consumers = 4
                memory_limit_mib = 1024
                compression = "none"
                retry_max_elapsed_minutes = 15
            }
            performance = @{
                latency_p95_ms = 95
                latency_p99_ms = 480
                throughput_eps = 980
                cpu_percent = 75
                memory_mb = 920
                error_rate_percent = 0.8
                availability_percent = 99.6
            }
        },
        @{
            runLabel = "row24"
            factors = @{
                traces_timeout_ms = 500
                metrics_timeout_ms = 500
                logs_timeout_ms = 1000
                send_batch_max_size = 10000
                queue_size = 15000
                num_consumers = 2
                memory_limit_mib = 2048
                compression = "none"
                retry_max_elapsed_minutes = 15
            }
            performance = @{
                latency_p95_ms = 78
                latency_p99_ms = 380
                throughput_eps = 1350
                cpu_percent = 58
                memory_mb = 1850
                error_rate_percent = 0.1
                availability_percent = 99.9
            }
        }
    )
    
    foreach ($config in $configs) {
        for ($replicate = 1; $replicate -le 3; $replicate++) {
            $runId = "$($config.runLabel)-r$replicate-$($baseTimestamp -replace '[-:]', '')"
            
            # Add some variation to replicates
            $variation = (Get-Random -Minimum 0.9 -Maximum 1.1)
            $perf = @{
                latency_p95_ms = [math]::Round($config.performance.latency_p95_ms * $variation, 2)
                latency_p99_ms = [math]::Round($config.performance.latency_p99_ms * $variation, 2)
                throughput_eps = [math]::Round($config.performance.throughput_eps * $variation, 2)
                cpu_percent = [math]::Round($config.performance.cpu_percent * $variation, 2)
                memory_mb = [math]::Round($config.performance.memory_mb * $variation, 2)
                error_rate_percent = [math]::Round($config.performance.error_rate_percent * $variation, 2)
                availability_percent = [math]::Round($config.performance.availability_percent * $variation, 2)
            }
            
            $sampleRuns += @{
                runId = $runId
                runLabel = $config.runLabel
                replicate = $replicate
                factors = $config.factors
                metrics = $perf
                timestamp = $baseTimestamp
            }
        }
    }
    
    Write-Host "Generated $($sampleRuns.Count) sample runs" -ForegroundColor Green
    return $sampleRuns
}

function Load-ExperimentData {
    param([string]$ExperimentPath)
    
    Write-Host "Loading experiment data from: $ExperimentPath" -ForegroundColor Cyan
    
    $planFile = Join-Path $ExperimentPath "batch-plan.json"
    if (-not (Test-Path $planFile)) {
        throw "Batch plan file not found: $planFile"
    }
    
    $plan = Get-Content $planFile | ConvertFrom-Json
    $runs = @()
    
    foreach ($run in $plan.runs) {
        if ($run.status -eq "completed") {
            # First try to load extracted measurements
            $measurementsFile = Join-Path $ExperimentPath "results" "$($run.runId)-measurements.json"
            
            if (Test-Path $measurementsFile) {
                Write-Host "Loading extracted measurements for $($run.runId)" -ForegroundColor Green
                $measurements = Get-Content $measurementsFile | ConvertFrom-Json
                
                $performanceMetrics = @{
                    latency_p95_ms = $measurements.latency.p95_ms
                    latency_p99_ms = $measurements.latency.p99_ms
                    throughput_eps = $measurements.throughput.events_per_second
                    cpu_percent = $measurements.resource_usage.cpu_percent
                    memory_mb = $measurements.resource_usage.memory_mb
                    error_rate_percent = $measurements.reliability.error_rate_percent
                    availability_percent = $measurements.reliability.availability_percent
                }
                
                $runs += @{
                    runId = $run.runId
                    runLabel = $run.runLabel
                    replicate = $run.replicate
                    factors = $measurements.factors
                    metrics = $performanceMetrics
                    timestamp = $measurements.timestamp
                }
            } else {
                # Fallback to basic metrics file
                $metricsFile = $run.artifacts.metricsFile
                if (Test-Path $metricsFile) {
                    Write-Host "Loading basic metrics for $($run.runId)" -ForegroundColor Yellow
                    $metrics = Get-Content $metricsFile | ConvertFrom-Json
                    
                    $performanceMetrics = @{
                        latency_p95_ms = 100  # Default, would be extracted from SigNoz
                        latency_p99_ms = 500  # Default, would be extracted from SigNoz
                        throughput_eps = 800  # Default, would be calculated from logs
                        cpu_percent = $metrics.systemMetrics.cpu
                        memory_mb = $metrics.systemMetrics.memory
                        error_rate_percent = 0.5  # Default, would be extracted from error logs
                        availability_percent = 99.5  # Default, would be calculated from uptime
                    }
                    
                    $runs += @{
                        runId = $run.runId
                        runLabel = $run.runLabel
                        replicate = $run.replicate
                        factors = $run.factors
                        metrics = $performanceMetrics
                        timestamp = $run.startTime
                    }
                }
            }
        }
    }
    
    Write-Host "Loaded $($runs.Count) completed runs" -ForegroundColor Green
    return $runs
}

function Calculate-SLOScore {
    param(
        [hashtable]$Metrics,
        [hashtable]$SLOs
    )
    
    $score = @{
        latency = 0
        throughput = 0
        resource_usage = 0
        reliability = 0
        overall = 0
        slo_violations = @()
    }
    
    # Latency scoring (lower is better)
    $latencyWeight = $SLOs.latency.weight
    $p95Score = [math]::Max(0, 1 - ($Metrics.latency_p95_ms / $SLOs.latency.p95_ms))
    $p99Score = [math]::Max(0, 1 - ($Metrics.latency_p99_ms / $SLOs.latency.p99_ms))
    $score.latency = ($p95Score + $p99Score) / 2 * $latencyWeight
    
    if ($Metrics.latency_p95_ms -gt $SLOs.latency.p95_ms) {
        $score.slo_violations += "p95_latency"
    }
    if ($Metrics.latency_p99_ms -gt $SLOs.latency.p99_ms) {
        $score.slo_violations += "p99_latency"
    }
    
    # Throughput scoring (higher is better)
    $throughputWeight = $SLOs.throughput.weight
    $throughputScore = [math]::Min(1, $Metrics.throughput_eps / $SLOs.throughput.events_per_second)
    $score.throughput = $throughputScore * $throughputWeight
    
    if ($Metrics.throughput_eps -lt $SLOs.throughput.events_per_second) {
        $score.slo_violations += "throughput"
    }
    
    # Resource usage scoring (lower is better)
    $resourceWeight = $SLOs.resource_usage.weight
    $cpuScore = [math]::Max(0, 1 - ($Metrics.cpu_percent / $SLOs.resource_usage.cpu_percent))
    $memoryScore = [math]::Max(0, 1 - ($Metrics.memory_mb / $SLOs.resource_usage.memory_mb))
    $score.resource_usage = ($cpuScore + $memoryScore) / 2 * $resourceWeight
    
    if ($Metrics.cpu_percent -gt $SLOs.resource_usage.cpu_percent) {
        $score.slo_violations += "cpu_usage"
    }
    if ($Metrics.memory_mb -gt $SLOs.resource_usage.memory_mb) {
        $score.slo_violations += "memory_usage"
    }
    
    # Reliability scoring
    $reliabilityWeight = $SLOs.reliability.weight
    $errorScore = [math]::Max(0, 1 - ($Metrics.error_rate_percent / $SLOs.reliability.error_rate_percent))
    $availabilityScore = [math]::Max(0, ($Metrics.availability_percent - 95) / (100 - 95)) # 95% baseline
    $score.reliability = ($errorScore + $availabilityScore) / 2 * $reliabilityWeight
    
    if ($Metrics.error_rate_percent -gt $SLOs.reliability.error_rate_percent) {
        $score.slo_violations += "error_rate"
    }
    if ($Metrics.availability_percent -lt $SLOs.reliability.availability_percent) {
        $score.slo_violations += "availability"
    }
    
    # Overall score
    $score.overall = $score.latency + $score.throughput + $score.resource_usage + $score.reliability
    
    return $score
}

function Generate-Rankings {
    param([array]$Runs)
    
    Write-Host "Calculating SLO scores and rankings..." -ForegroundColor Cyan
    
    $rankedRuns = @()
    
    foreach ($run in $Runs) {
        $sloScore = Calculate-SLOScore -Metrics $run.metrics -SLOs $slos
        
        $rankedRuns += @{
            runId = $run.runId
            runLabel = $run.runLabel
            replicate = $run.replicate
            overall_score = [math]::Round($sloScore.overall, 3)
            latency_score = [math]::Round($sloScore.latency, 3)
            throughput_score = [math]::Round($sloScore.throughput, 3)
            resource_score = [math]::Round($sloScore.resource_usage, 3)
            reliability_score = [math]::Round($sloScore.reliability, 3)
            slo_violations = $sloScore.slo_violations -join ";"
            violation_count = $sloScore.slo_violations.Count
            metrics = $run.metrics
            factors = $run.factors
            timestamp = $run.timestamp
        }
    }
    
    # Sort by overall score (descending) and then by violation count (ascending)
    $rankedRuns = $rankedRuns | Sort-Object @{Expression = "overall_score"; Descending = $true}, @{Expression = "violation_count"; Descending = $false}
    
    # Add ranking
    for ($i = 0; $i -lt $rankedRuns.Count; $i++) {
        $rankedRuns[$i].rank = $i + 1
    }
    
    return $rankedRuns
}

function Export-CSVResults {
    param(
        [array]$RankedRuns,
        [string]$OutputPath
    )
    
    Write-Host "Exporting results to CSV: $OutputPath" -ForegroundColor Cyan
    
    $csvData = @()
    foreach ($run in $RankedRuns) {
        $csvData += [PSCustomObject]@{
            rank = $run.rank
            runId = $run.runId
            runLabel = $run.runLabel
            replicate = $run.replicate
            overall_score = $run.overall_score
            latency_score = $run.latency_score
            throughput_score = $run.throughput_score
            resource_score = $run.resource_score
            reliability_score = $run.reliability_score
            slo_violations = $run.slo_violations
            violation_count = $run.violation_count
            latency_p95_ms = $run.metrics.latency_p95_ms
            latency_p99_ms = $run.metrics.latency_p99_ms
            throughput_eps = $run.metrics.throughput_eps
            cpu_percent = $run.metrics.cpu_percent
            memory_mb = $run.metrics.memory_mb
            error_rate_percent = $run.metrics.error_rate_percent
            availability_percent = $run.metrics.availability_percent
            traces_timeout_ms = $run.factors.traces_timeout_ms
            metrics_timeout_ms = $run.factors.metrics_timeout_ms
            logs_timeout_ms = $run.factors.logs_timeout_ms
            send_batch_max_size = $run.factors.send_batch_max_size
            queue_size = $run.factors.queue_size
            num_consumers = $run.factors.num_consumers
            memory_limit_mib = $run.factors.memory_limit_mib
            compression = $run.factors.compression
            retry_max_elapsed_minutes = $run.factors.retry_max_elapsed_minutes
        }
    }
    
    $csvData | Export-Csv -Path $OutputPath -NoTypeInformation
    
    Write-Host "CSV export completed: $($csvData.Count) runs ranked" -ForegroundColor Green
}

function Show-TopResults {
    param([array]$RankedRuns)
    
    Write-Host "`nTop 5 DOE Results:" -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Yellow
    
    for ($i = 0; $i -lt [math]::Min(5, $RankedRuns.Count); $i++) {
        $run = $RankedRuns[$i]
        Write-Host "Rank $($run.rank): $($run.runLabel) (Score: $($run.overall_score))" -ForegroundColor Cyan
        Write-Host "  Latency: $($run.metrics.latency_p95_ms)ms p95, $($run.metrics.latency_p99_ms)ms p99" -ForegroundColor White
        Write-Host "  Throughput: $($run.metrics.throughput_eps) eps" -ForegroundColor White
        Write-Host "  Resources: $($run.metrics.cpu_percent)% CPU, $($run.metrics.memory_mb)MB RAM" -ForegroundColor White
        Write-Host "  Reliability: $($run.metrics.error_rate_percent)% errors, $($run.metrics.availability_percent)% availability" -ForegroundColor White
        if ($run.violation_count -gt 0) {
            Write-Host "  SLO Violations: $($run.slo_violations)" -ForegroundColor Red
        } else {
            Write-Host "  SLO Violations: None" -ForegroundColor Green
        }
        Write-Host ""
    }
}

# Main execution
if ($SampleData) {
    Write-Host "Generating and scoring sample data..." -ForegroundColor Yellow
    $runs = Generate-SampleData
} elseif ($ExperimentDir) {
    $runs = Load-ExperimentData -ExperimentPath $ExperimentDir
} else {
    throw "Either -SampleData or -ExperimentDir must be specified"
}

if ($runs.Count -eq 0) {
    Write-Warning "No runs to score"
    return
}

# Generate rankings
$rankedRuns = Generate-Rankings -Runs $runs

# Export results
Export-CSVResults -RankedRuns $rankedRuns -OutputPath $OutputFile

# Show top results
Show-TopResults -RankedRuns $rankedRuns

# Summary statistics
$avgScore = ($rankedRuns | Measure-Object -Property overall_score -Average).Average
$totalViolations = ($rankedRuns | Measure-Object -Property violation_count -Sum).Sum
$runsWithoutViolations = ($rankedRuns | Where-Object { $_.violation_count -eq 0 }).Count

Write-Host "`nScoring Summary:" -ForegroundColor Green
Write-Host "Average overall score: $([math]::Round($avgScore, 3))" -ForegroundColor Cyan
Write-Host "Total SLO violations: $totalViolations" -ForegroundColor Yellow
Write-Host "Runs without violations: $runsWithoutViolations/$($rankedRuns.Count)" -ForegroundColor Cyan
Write-Host "Results saved to: $OutputFile" -ForegroundColor Green
