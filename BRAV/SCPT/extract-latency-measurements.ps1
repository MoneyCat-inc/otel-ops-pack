#Requires -Version 7.0

<#
.SYNOPSIS
    Enhanced latency measurement extraction with fail-fast behavior

.DESCRIPTION
    Extracts real latency measurements from ClickHouse for DOE experiments.
    Fails immediately if data is missing instead of using fallback values.

.PARAMETER RunId
    Specific run ID to extract measurements for

.PARAMETER ExperimentDir
    Directory containing experiment results (batch-plan.json)

.PARAMETER ClickHouseEndpoint
    ClickHouse HTTP endpoint. Default: http://localhost:8123

.PARAMETER TimeRange
    Time range in minutes to query. Default: 10

.PARAMETER BaselineFile
    Path to baseline latency file for comparison. Default: artifacts/doe/baselines/latency.json

.PARAMETER FailOnMissingData
    Fail if no data found instead of using fallbacks. Default: true

.EXAMPLE
    .\extract-latency-measurements.ps1 -RunId test-run-001
    Extract measurements for specific run

.EXAMPLE
    .\extract-latency-measurements.ps1 -ExperimentDir artifacts/doe/stage1-20250921-190945
    Extract measurements for all runs in experiment
#>

param(
    [string]$RunId,
    [string]$ExperimentDir,
    [string]$ClickHouseEndpoint = "http://localhost:8123",
    [int]$TimeRange = 10,
    [string]$BaselineFile = "artifacts/doe/baselines/latency.json",
    [switch]$FailOnMissingData = $true
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Enhanced Latency Measurement Extraction" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Load baseline if available
$baseline = $null
if (Test-Path $BaselineFile) {
    try {
        $baseline = Get-Content $BaselineFile | ConvertFrom-Json
        Write-Host "Loaded baseline from: $BaselineFile" -ForegroundColor Cyan
    } catch {
        Write-Warning "Failed to load baseline file: $($_.Exception.Message)"
    }
}

# ClickHouse query templates
$queries = @{
    latency_logs = @"
SELECT 
    resources_string['run.id'] as run_id,
    quantile(0.50)(toFloat64(attributes_number['duration_ms'])) as p50_latency_ms,
    quantile(0.95)(toFloat64(attributes_number['duration_ms'])) as p95_latency_ms,
    quantile(0.99)(toFloat64(attributes_number['duration_ms'])) as p99_latency_ms,
    count() as sample_count
FROM signoz_logs.logs_v2 
WHERE timestamp >= now() - INTERVAL {0} MINUTE
  AND resources_string['run.id'] IS NOT NULL
  AND resources_string['run.id'] != ''
  AND attributes_number['duration_ms'] IS NOT NULL
  AND attributes_number['duration_ms'] > 0
GROUP BY run_id
ORDER BY run_id
"@
    latency_traces = @"
SELECT 
    resourceTagsMap['run.id'] as run_id,
    quantile(0.50)(durationNano / 1000000) as p50_latency_ms,
    quantile(0.95)(durationNano / 1000000) as p95_latency_ms,
    quantile(0.99)(durationNano / 1000000) as p99_latency_ms,
    count() as sample_count
FROM signoz_traces.signoz_index_v2 
WHERE timestamp >= now() - INTERVAL {0} MINUTE
  AND resourceTagsMap['run.id'] IS NOT NULL
  AND resourceTagsMap['run.id'] != ''
  AND durationNano IS NOT NULL
  AND durationNano > 0
GROUP BY run_id
ORDER BY run_id
"@
    throughput = @"
SELECT 
    resources_string['run.id'] as run_id,
    count() / {0} as events_per_second,
    count() as total_events
FROM signoz_logs.logs_v2 
WHERE timestamp >= now() - INTERVAL {0} MINUTE
  AND resources_string['run.id'] IS NOT NULL
  AND resources_string['run.id'] != ''
GROUP BY run_id
ORDER BY run_id
"@
    error_rate = @"
SELECT 
    resources_string['run.id'] as run_id,
    countIf(severity_text = 'ERROR') as error_count,
    count() as total_count,
    countIf(severity_text = 'ERROR') / count() * 100 as error_rate_percent
FROM signoz_logs.logs_v2 
WHERE timestamp >= now() - INTERVAL {0} MINUTE
  AND resources_string['run.id'] IS NOT NULL
  AND resources_string['run.id'] != ''
GROUP BY run_id
ORDER BY run_id
"@
}

# Function to execute ClickHouse query
function Invoke-ClickHouseQuery {
    param(
        [string]$Query,
        [string]$ClickHouseEndpoint
    )
    
    try {
        $encodedQuery = [Uri]::EscapeDataString($Query)
        $uri = "$ClickHouseEndpoint/?query=$encodedQuery&format=JSONEachRow"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 30
        
        if ($response) {
            return $response
        } else {
            return @()
        }
    } catch {
        Write-Warning "ClickHouse query failed: $($_.Exception.Message)"
        Write-Warning "Query: $Query"
        return @()
    }
}

# Function to extract measurements for a specific run
function Get-RunLatencyMeasurements {
    param(
        [string]$RunId,
        [int]$TimeRangeMinutes,
        [string]$ClickHouseEndpoint
    )
    
    Write-Host "Extracting latency measurements for run: $RunId" -ForegroundColor Yellow
    
    $measurements = @{
        runId = $RunId
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        latency = @{
            p50_ms = $null
            p95_ms = $null
            p99_ms = $null
            sample_count = 0
            source = "none"
        }
        throughput = @{
            events_per_second = 0
            total_events = 0
        }
        reliability = @{
            error_rate_percent = 0
            error_count = 0
            total_count = 0
        }
        baseline_comparison = @{
            p95_regression_percent = $null
            p99_regression_percent = $null
            meets_sla = $null
        }
    }
    
    # Try traces first (preferred for latency)
    $traceQuery = $queries.latency_traces -f $TimeRangeMinutes
    $traceData = Invoke-ClickHouseQuery -Query $traceQuery -ClickHouseEndpoint $ClickHouseEndpoint
    
    $runTraceData = $traceData | Where-Object { $_.run_id -eq $RunId }
    
    if ($runTraceData -and $runTraceData.sample_count -gt 0) {
        $measurements.latency.p50_ms = [math]::Round($runTraceData.p50_latency_ms, 2)
        $measurements.latency.p95_ms = [math]::Round($runTraceData.p95_latency_ms, 2)
        $measurements.latency.p99_ms = [math]::Round($runTraceData.p99_latency_ms, 2)
        $measurements.latency.sample_count = $runTraceData.sample_count
        $measurements.latency.source = "traces"
        Write-Host "  [OK] Latency from traces: p95=$($measurements.latency.p95_ms)ms, samples=$($measurements.latency.sample_count)" -ForegroundColor Green
    } else {
        # Fall back to logs with duration attributes
        $logQuery = $queries.latency_logs -f $TimeRangeMinutes
        $logData = Invoke-ClickHouseQuery -Query $logQuery -ClickHouseEndpoint $ClickHouseEndpoint
        
        $runLogData = $logData | Where-Object { $_.run_id -eq $RunId }
        
        if ($runLogData -and $runLogData.sample_count -gt 0) {
            $measurements.latency.p50_ms = [math]::Round($runLogData.p50_latency_ms, 2)
            $measurements.latency.p95_ms = [math]::Round($runLogData.p95_latency_ms, 2)
            $measurements.latency.p99_ms = [math]::Round($runLogData.p99_latency_ms, 2)
            $measurements.latency.sample_count = $runLogData.sample_count
            $measurements.latency.source = "logs"
            Write-Host "  [OK] Latency from logs: p95=$($measurements.latency.p95_ms)ms, samples=$($measurements.latency.sample_count)" -ForegroundColor Green
        } else {
            if ($FailOnMissingData) {
                throw "No latency data found for run $RunId in the last $TimeRangeMinutes minutes. Check that the run generated traces or logs with duration attributes."
            } else {
                Write-Host "  [WARN] No latency data found - using fallback values" -ForegroundColor Yellow
                $measurements.latency.p50_ms = 100
                $measurements.latency.p95_ms = 200
                $measurements.latency.p99_ms = 500
                $measurements.latency.sample_count = 0
                $measurements.latency.source = "fallback"
            }
        }
    }
    
    # Extract throughput
    $throughputQuery = $queries.throughput -f $TimeRangeMinutes
    $throughputData = Invoke-ClickHouseQuery -Query $throughputQuery -ClickHouseEndpoint $ClickHouseEndpoint
    
    $runThroughputData = $throughputData | Where-Object { $_.run_id -eq $RunId }
    if ($runThroughputData) {
        $measurements.throughput.events_per_second = [math]::Round($runThroughputData.events_per_second, 2)
        $measurements.throughput.total_events = $runThroughputData.total_events
        Write-Host "  [OK] Throughput: $($measurements.throughput.events_per_second) eps" -ForegroundColor Green
    } else {
        if ($FailOnMissingData) {
            throw "No throughput data found for run $RunId"
        }
    }
    
    # Extract error rate
    $errorQuery = $queries.error_rate -f $TimeRangeMinutes
    $errorData = Invoke-ClickHouseQuery -Query $errorQuery -ClickHouseEndpoint $ClickHouseEndpoint
    
    $runErrorData = $errorData | Where-Object { $_.run_id -eq $RunId }
    if ($runErrorData) {
        $measurements.reliability.error_rate_percent = [math]::Round($runErrorData.error_rate_percent, 2)
        $measurements.reliability.error_count = $runErrorData.error_count
        $measurements.reliability.total_count = $runErrorData.total_count
        Write-Host "  [OK] Error rate: $($measurements.reliability.error_rate_percent)%" -ForegroundColor Green
    }
    
    # Compare with baseline
    if ($baseline -and $measurements.latency.p95_ms) {
        $p95Baseline = $baseline.p95_ms
        $p99Baseline = $baseline.p99_ms
        
        if ($p95Baseline) {
            $measurements.baseline_comparison.p95_regression_percent = [math]::Round(($measurements.latency.p95_ms - $p95Baseline) / $p95Baseline * 100, 2)
        }
        
        if ($p99Baseline) {
            $measurements.baseline_comparison.p99_regression_percent = [math]::Round(($measurements.latency.p99_ms - $p99Baseline) / $p99Baseline * 100, 2)
        }
        
        # Check SLA (10% regression threshold)
        $p95Regression = $measurements.baseline_comparison.p95_regression_percent
        $measurements.baseline_comparison.meets_sla = if ($p95Regression -and $p95Regression -le 10) { $true } else { $false }
        
        if ($p95Regression) {
            $status = if ($measurements.baseline_comparison.meets_sla) { "[OK]" } else { "[FAIL]" }
            $color = if ($measurements.baseline_comparison.meets_sla) { "Green" } else { "Red" }
            Write-Host "  $status Baseline comparison: p95 regression $p95Regression% (SLA: <=10%)" -ForegroundColor $color
        }
    }
    
    return $measurements
}

# Main execution
if ($RunId) {
    # Single run extraction
    try {
        $measurements = Get-RunLatencyMeasurements -RunId $RunId -TimeRangeMinutes $TimeRange -ClickHouseEndpoint $ClickHouseEndpoint
        
        # Save measurements
        $outputFile = "artifacts/doe/latency-measurements-$RunId.json"
        $measurements | ConvertTo-Json -Depth 10 | Set-Content $outputFile
        
        Write-Host "`nLatency measurements saved to: $outputFile" -ForegroundColor Green
        Write-Host "Run: $RunId" -ForegroundColor White
        Write-Host "  Latency: $($measurements.latency.p50_ms)ms p50, $($measurements.latency.p95_ms)ms p95, $($measurements.latency.p99_ms)ms p99" -ForegroundColor White
        Write-Host "  Source: $($measurements.latency.source), Samples: $($measurements.latency.sample_count)" -ForegroundColor White
        Write-Host "  Throughput: $($measurements.throughput.events_per_second) eps" -ForegroundColor White
        Write-Host "  Error Rate: $($measurements.reliability.error_rate_percent)%" -ForegroundColor White
        
        if ($measurements.baseline_comparison.p95_regression_percent) {
            Write-Host "  Baseline: p95 regression $($measurements.baseline_comparison.p95_regression_percent)%" -ForegroundColor White
        }
        
    } catch {
        Write-Error "Failed to extract measurements for $RunId`: $($_.Exception.Message)"
        exit 1
    }
    
} elseif ($ExperimentDir) {
    # Batch extraction
    if (-not (Test-Path $ExperimentDir)) {
        throw "Experiment directory not found: $ExperimentDir"
    }
    
    $planFile = Join-Path $ExperimentDir "batch-plan.json"
    if (-not (Test-Path $planFile)) {
        throw "Batch plan file not found: $planFile"
    }
    
    $plan = Get-Content $planFile | ConvertFrom-Json
    $completedRuns = $plan.runs | Where-Object { $_.status -eq "completed" }
    
    Write-Host "Processing $($completedRuns.Count) completed runs" -ForegroundColor Cyan
    
    $resultsDir = Join-Path $ExperimentDir "results"
    if (-not (Test-Path $resultsDir)) {
        New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
    }
    
    $extractedCount = 0
    $failedCount = 0
    
    foreach ($run in $completedRuns) {
        try {
            $measurements = Get-RunLatencyMeasurements -RunId $run.runId -TimeRangeMinutes $TimeRange -ClickHouseEndpoint $ClickHouseEndpoint
            
            # Save measurements
            $measurementsFile = Join-Path $resultsDir "$($run.runId)-latency-measurements.json"
            $measurements | ConvertTo-Json -Depth 10 | Set-Content $measurementsFile
            
            $extractedCount++
            Write-Host "[OK] Extracted measurements for $($run.runId)" -ForegroundColor Green
            
        } catch {
            Write-Error "Failed to extract measurements for $($run.runId): $($_.Exception.Message)"
            $failedCount++
        }
    }
    
    Write-Host "`nBatch extraction completed!" -ForegroundColor Green
    Write-Host "Extracted: $extractedCount, Failed: $failedCount" -ForegroundColor Cyan
    
} else {
    Write-Host "Please specify either -RunId or -ExperimentDir" -ForegroundColor Red
    exit 1
}
