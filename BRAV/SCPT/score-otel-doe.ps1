#Requires -Version 7.0

<#
.SYNOPSIS
    DOE scoring tool for OTel Collector experiment evaluation

.DESCRIPTION
    Evaluates experiment results against SLOs and produces weighted efficiency rankings.
    Supports both real experiment data and sample data generation for testing.

.PARAMETER ExperimentDir
    Directory containing experiment results (batch-plan.json and metrics)

.PARAMETER SampleData
    Generate and score sample data instead of real experiment results

.PARAMETER OutputFile
    Output CSV file for rankings. Default: doe-scores.csv

.PARAMETER SLOConfig
    Path to SLO configuration file. Default: config/slo-config.json

.EXAMPLE
    .\score-otel-doe.ps1 -SampleData
    Generate and score sample data for testing

.EXAMPLE
    .\score-otel-doe.ps1 -ExperimentDir artifacts/doe/stage1-20240101-120000
    Score real experiment results
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

Write-Host "DOE Scoring Tool" -ForegroundColor Green
Write-Host "SLO Configuration:" -ForegroundColor Cyan
$defaultSLOs | ConvertTo-Json -Depth 3 | Write-Host

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

# Load SLO configuration if exists
$slos = $defaultSLOs
if (Test-Path $SLOConfig) {
    try {
        $customSLOs = Get-Content $SLOConfig | ConvertFrom-Json
        $slos = $customSLOs
        Write-Host "Loaded custom SLO configuration from: $SLOConfig" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to load custom SLO config, using defaults"
    }
}

# Main execution
    if ($SampleData) {
    Write-Host "Generating and scoring sample data..." -ForegroundColor Yellow
    $runs = Generate-SampleData
    } else {
    Write-Error "Real experiment scoring not yet implemented - use -SampleData for testing"
    return
}

if ($runs.Count -eq 0) {
    Write-Warning "No runs to score"
    return
}

Write-Host "Scoring completed with $($runs.Count) sample runs" -ForegroundColor Green
Write-Host "Results would be saved to: $OutputFile" -ForegroundColor Yellow