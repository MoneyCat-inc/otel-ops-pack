#Requires -Version 7.0

<#
.SYNOPSIS
    Pre-flight latency readiness check for DOE experiments

.DESCRIPTION
    Validates ClickHouse connectivity, collector health, and data flow before
    running expensive DOE experiments. Includes smoke mode for quick validation.

.PARAMETER SmokeMode
    Run a 60-second smoke test to validate latency metrics flow

.PARAMETER ClickHouseEndpoint
    ClickHouse HTTP endpoint. Default: http://localhost:8123

.PARAMETER SigNozEndpoint
    SigNoz API endpoint. Default: http://localhost:8080

.PARAMETER CollectorHealthEndpoint
    Collector health check endpoint. Default: http://localhost:13134

.PARAMETER RunId
    Test run ID for smoke mode. Default: latency-readiness-test

.EXAMPLE
    .\check-latency-readiness.ps1
    Basic readiness check

.EXAMPLE
    .\check-latency-readiness.ps1 -SmokeMode
    Run 60-second smoke test with latency validation
#>

param(
    [switch]$SmokeMode,
    [string]$ClickHouseEndpoint = "http://localhost:8123",
    [string]$SigNozEndpoint = "http://localhost:8080",
    [string]$CollectorHealthEndpoint = "http://localhost:13134",
    [string]$RunId = "latency-readiness-test"
)

# Initialize script
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host "Latency Readiness Check" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green

$checks = @{
    clickhouse = $false
    collector = $false
    data_flow = $false
    latency_metrics = $false
}

# Check 1: ClickHouse connectivity
Write-Host "`n1. Checking ClickHouse connectivity..." -ForegroundColor Cyan
try {
    $testQuery = "SELECT 1 as test"
    $encodedQuery = [Uri]::EscapeDataString($testQuery)
    $uri = "$ClickHouseEndpoint/?query=$encodedQuery&default_format=JSONEachRow"
    
    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 10
    if ($response -and $response.test -eq 1) {
        Write-Host "[OK] ClickHouse is reachable" -ForegroundColor Green
        $checks.clickhouse = $true
    } else {
        throw "ClickHouse response invalid"
    }
} catch {
    Write-Host "[FAIL] ClickHouse connectivity failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Make sure SigNoz is running and ClickHouse is accessible" -ForegroundColor Yellow
}

# Check 2: Collector health
Write-Host "`n2. Checking collector health..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "$CollectorHealthEndpoint/healthz" -TimeoutSec 10
    if ($healthResponse.status -in @("Serving", "Server available")) {
        Write-Host "[OK] Collector is healthy" -ForegroundColor Green
        $checks.collector = $true
    } else {
        throw "Collector not serving"
    }
} catch {
    Write-Host "[FAIL] Collector health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Make sure otelcol-contrib service is running" -ForegroundColor Yellow
}

# Check 3: Data flow validation
Write-Host "`n3. Checking data flow..." -ForegroundColor Cyan
try {
    # Check for recent logs in ClickHouse
    $logQuery = @"
SELECT 
    count() as log_count,
    max(timestamp) as latest_log
FROM signoz_logs.logs_v2 
WHERE timestamp >= now() - INTERVAL 5 MINUTE
"@
    
    $encodedQuery = [Uri]::EscapeDataString($logQuery)
    $uri = "$ClickHouseEndpoint/?query=$encodedQuery&default_format=JSONEachRow"
    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 10
    
    if ($response -and $response.log_count -gt 0) {
        Write-Host "[OK] Data flow detected: $($response.log_count) logs in last 5 minutes" -ForegroundColor Green
        $checks.data_flow = $true
    } else {
        Write-Host "[WARN] No recent data flow detected" -ForegroundColor Yellow
        Write-Host "  This may be normal if no applications are sending data" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[FAIL] Data flow check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Check 4: Latency metrics availability
Write-Host "`n4. Checking latency metrics availability..." -ForegroundColor Cyan
try {
    # Check if traces table exists and has data
    $traceQuery = @"
SELECT 
    count() as trace_count,
    max(timestamp) as latest_trace
FROM signoz_traces.signoz_index_v2 
WHERE timestamp >= now() - INTERVAL 10 MINUTE
"@
    
    $encodedQuery = [Uri]::EscapeDataString($traceQuery)
    $uri = "$ClickHouseEndpoint/?query=$encodedQuery&default_format=JSONEachRow"
    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 10
    
    if ($response -and $response.trace_count -gt 0) {
        Write-Host "[OK] Latency metrics available: $($response.trace_count) traces in last 10 minutes" -ForegroundColor Green
        $checks.latency_metrics = $true
    } else {
        Write-Host "[WARN] No recent traces found - latency metrics will use fallback values" -ForegroundColor Yellow
        Write-Host "  This is expected for log-only experiments" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[FAIL] Latency metrics check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Smoke mode: 60-second test run
if ($SmokeMode) {
    Write-Host "`n5. Running smoke test (60 seconds)..." -ForegroundColor Cyan
    
    if (-not $checks.clickhouse -or -not $checks.collector) {
        Write-Host "[FAIL] Skipping smoke test - prerequisites not met" -ForegroundColor Red
        return
    }
    
    try {
        # Generate test load
        Write-Host "  Generating test load..." -ForegroundColor Yellow
        $smokeCommand = "pwsh -File scripts/generate-synthetic-load.ps1 -Duration 60 -RunId $RunId -Stage smoke-test"
        $smokeProcess = Start-Process -FilePath "pwsh" -ArgumentList @("-Command", $smokeCommand) -PassThru -NoNewWindow
        $smokeProcess.WaitForExit(90000) # 90 second timeout
        
        if (-not $smokeProcess.HasExited) {
            Write-Host "  [WARN] Smoke test timed out, terminating..." -ForegroundColor Yellow
            $smokeProcess.Kill()
        }
        
        # Wait for data to propagate
        Write-Host "  Waiting for data propagation..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        # Check for test data
        $smokeQuery = @"
SELECT 
    count() as log_count,
    countIf(resources_string['run.id'] = '$RunId') as test_logs
FROM signoz_logs.logs_v2 
WHERE timestamp >= now() - INTERVAL 2 MINUTE
"@
        
        $encodedQuery = [Uri]::EscapeDataString($smokeQuery)
        $uri = "$ClickHouseEndpoint/?query=$encodedQuery&default_format=JSONEachRow"
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 10
        
        if ($response -and $response.test_logs -gt 0) {
            Write-Host "[OK] Smoke test passed: $($response.test_logs) test logs generated" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Smoke test failed: No test logs found" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "[FAIL] Smoke test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
Write-Host "`nReadiness Check Summary" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green

$passedChecks = ($checks.Values | Where-Object { $_ -eq $true }).Count
$totalChecks = $checks.Count

Write-Host "ClickHouse: $(if ($checks.clickhouse) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($checks.clickhouse) { 'Green' } else { 'Red' })
Write-Host "Collector:  $(if ($checks.collector) { '[OK]' } else { '[FAIL]' })" -ForegroundColor $(if ($checks.collector) { 'Green' } else { 'Red' })
Write-Host "Data Flow:  $(if ($checks.data_flow) { '[OK]' } else { '[WARN]' })" -ForegroundColor $(if ($checks.data_flow) { 'Green' } else { 'Yellow' })
Write-Host "Latency:    $(if ($checks.latency_metrics) { '[OK]' } else { '[WARN]' })" -ForegroundColor $(if ($checks.latency_metrics) { 'Green' } else { 'Yellow' })

if ($checks.clickhouse -and $checks.collector) {
    Write-Host "`n[OK] System is ready for DOE experiments" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n[FAIL] System not ready - fix issues before running DOE experiments" -ForegroundColor Red
    exit 1
}
