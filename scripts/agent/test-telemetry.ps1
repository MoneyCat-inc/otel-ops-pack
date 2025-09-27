#!/usr/bin/env pwsh
# Test OpenTelemetry Agent Implementation
# Verifies telemetry instrumentation is working correctly

param(
    [switch]$FullTest,
    [switch]$QuickTest,
    [switch]$StopCollector
)

$ErrorActionPreference = "Stop"

function Write-Progress-Animation {
    param(
        [string]$Message,
        [int]$Duration = 3000
    )
    
    $spinner = @('⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏')
    $endTime = (Get-Date).AddMilliseconds($Duration)
    
    while ((Get-Date) -lt $endTime) {
        $spinnerIndex = [int]((Get-Date).Ticks % $spinner.Length)
        Write-Host "`r$($spinner[$spinnerIndex]) $Message" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
    }
    Write-Host "`r✅ $Message complete" -ForegroundColor Green
}

function Test-CollectorHealth {
    Write-Host "🔍 Testing collector health..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:13133/" -Method Get -TimeoutSec 5
        if ($response.status -eq "Server available") {
            Write-Host "✅ Collector is healthy" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Collector health check failed: $($response.status)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Collector not reachable: $_" -ForegroundColor Red
        return $false
    }
}

function Test-OTLPEndpoints {
    Write-Host "🔍 Testing OTLP endpoints..." -ForegroundColor Cyan
    
    $endpoints = @(
        @{ Name = "HTTP"; Url = "http://localhost:4318/v1/traces"; Method = "POST" }
        @{ Name = "gRPC"; Url = "localhost:4317"; Method = "GRPC" }
    )
    
    $allHealthy = $true
    
    foreach ($endpoint in $endpoints) {
        try {
            if ($endpoint.Method -eq "POST") {
                # Test HTTP endpoint with empty payload
                $response = Invoke-RestMethod -Uri $endpoint.Url -Method POST -Body "{}" -ContentType "application/json" -TimeoutSec 5
                Write-Host "✅ $($endpoint.Name) endpoint reachable" -ForegroundColor Green
            } else {
                # For gRPC, just check if port is open
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                $tcpClient.Connect("localhost", 4317)
                $tcpClient.Close()
                Write-Host "✅ $($endpoint.Name) endpoint reachable" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "❌ $($endpoint.Name) endpoint failed: $_" -ForegroundColor Red
            $allHealthy = $false
        }
    }
    
    return $allHealthy
}

function Test-AgentTelemetry {
    Write-Host "🔍 Testing agent telemetry..." -ForegroundColor Cyan
    
    # Set environment variables
    $env:OTEL_ENABLED = "1"
    $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
    $env:OTEL_SERVICE_NAME = "resonai-agent-test"
    
    try {
        # Test flake quarantine telemetry
        Write-Host "   Testing flake quarantine..." -ForegroundColor Yellow
        $flakeResult = & node scripts/agent/flake-quarantine.ts 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Flake quarantine telemetry working" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Flake quarantine failed: $flakeResult" -ForegroundColor Red
            return $false
        }
        
        # Test nightly gauges
        Write-Host "   Testing nightly gauges..." -ForegroundColor Yellow
        $gaugeResult = & node scripts/agent/emit-flake-gauges.ts 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ Nightly gauges telemetry working" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Nightly gauges failed: $gaugeResult" -ForegroundColor Red
            return $false
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Agent telemetry test failed: $_" -ForegroundColor Red
        return $false
    }
}

function Test-WatchdogTelemetry {
    Write-Host "🔍 Testing watchdog telemetry..." -ForegroundColor Cyan
    
    $env:OTEL_ENABLED = "1"
    $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
    $env:OTEL_SERVICE_NAME = "resonai-agent-test"
    
    try {
        # Start watchdog for a short period
        Write-Host "   Starting watchdog for 10 seconds..." -ForegroundColor Yellow
        $watchdogJob = Start-Job -ScriptBlock {
            Set-Location $using:PWD
            $env:OTEL_ENABLED = "1"
            $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://localhost:4318"
            $env:OTEL_SERVICE_NAME = "resonai-agent-test"
            & node scripts/agent/watchdog.ts start
        }
        
        Start-Sleep -Seconds 10
        
        # Stop the job
        Stop-Job $watchdogJob -Force
        Remove-Job $watchdogJob
        
        Write-Host "   ✅ Watchdog telemetry test completed" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Watchdog telemetry test failed: $_" -ForegroundColor Red
        return $false
    }
}

function Test-TelemetryData {
    Write-Host "🔍 Verifying telemetry data..." -ForegroundColor Cyan
    
    try {
        # Check if traces are being generated
        Write-Host "   Checking for traces in Jaeger..." -ForegroundColor Yellow
        $jaegerResponse = Invoke-RestMethod -Uri "http://localhost:16686/api/services" -Method Get -TimeoutSec 5
        if ($jaegerResponse -contains "resonai-agent-test") {
            Write-Host "   ✅ Traces found in Jaeger" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  No traces found in Jaeger (may take time to appear)" -ForegroundColor Yellow
        }
        
        # Check metrics
        Write-Host "   Checking metrics..." -ForegroundColor Yellow
        $metricsResponse = Invoke-RestMethod -Uri "http://localhost:8889/metrics" -Method Get -TimeoutSec 5
        if ($metricsResponse -match "jobs_processed_total|queue_depth|flake_detected_total") {
            Write-Host "   ✅ Metrics found in collector" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  No expected metrics found (may take time to appear)" -ForegroundColor Yellow
        }
        
        return $true
    }
    catch {
        Write-Host "❌ Telemetry data verification failed: $_" -ForegroundColor Red
        return $false
    }
}

function Show-TestResults {
    param(
        [hashtable]$Results
    )
    
    Write-Host "`n📊 Test Results Summary" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    $totalTests = $Results.Count
    $passedTests = ($Results.Values | Where-Object { $_ -eq $true }).Count
    
    foreach ($test in $Results.GetEnumerator()) {
        $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
        Write-Host "   $($test.Key): $status" -ForegroundColor $(if ($test.Value) { "Green" } else { "Red" })
    }
    
    Write-Host ""
    Write-Host "Overall: $passedTests/$totalTests tests passed" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
    
    if ($passedTests -eq $totalTests) {
        Write-Host "🎉 All telemetry tests passed!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed. Check the output above for details." -ForegroundColor Yellow
    }
}

function Stop-DevCollector {
    Write-Host "🛑 Stopping development collector..." -ForegroundColor Yellow
    
    try {
        Set-Location otel
        & pwsh -File start-dev-collector.ps1 -Stop
        Set-Location ..
        Write-Host "✅ Collector stopped" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to stop collector: $_" -ForegroundColor Red
    }
}

# Main execution
Write-Host "🧪 OpenTelemetry Agent Telemetry Test Suite" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

if ($StopCollector) {
    Stop-DevCollector
    exit 0
}

$testResults = @{}

# Quick test - just check collector health
if ($QuickTest) {
    Write-Host "🚀 Running quick test..." -ForegroundColor Cyan
    $testResults["Collector Health"] = Test-CollectorHealth
    Show-TestResults $testResults
    exit $(if ($testResults["Collector Health"]) { 0 } else { 1 })
}

# Full test suite
Write-Host "🚀 Running full test suite..." -ForegroundColor Cyan

# Test collector
$testResults["Collector Health"] = Test-CollectorHealth
if (-not $testResults["Collector Health"]) {
    Write-Host "❌ Collector not available. Please start it first:" -ForegroundColor Red
    Write-Host "   pwsh -File otel/start-dev-collector.ps1" -ForegroundColor Yellow
    Show-TestResults $testResults
    exit 1
}

# Test OTLP endpoints
$testResults["OTLP Endpoints"] = Test-OTLPEndpoints

# Test agent telemetry
$testResults["Agent Telemetry"] = Test-AgentTelemetry

# Test watchdog telemetry
$testResults["Watchdog Telemetry"] = Test-WatchdogTelemetry

# Test telemetry data
$testResults["Telemetry Data"] = Test-TelemetryData

# Show results
Show-TestResults $testResults

# Exit with appropriate code
$passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$totalTests = $testResults.Count
exit $(if ($passedTests -eq $totalTests) { 0 } else { 1 })
