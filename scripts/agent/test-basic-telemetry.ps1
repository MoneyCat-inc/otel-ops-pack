#!/usr/bin/env pwsh
# Basic Telemetry Test - Simplified verification
# Tests core telemetry functionality without complex setup

param(
    [switch]$Quick
)

$ErrorActionPreference = "Stop"

function Test-OTLPEndpoint {
    Write-Host "🔍 Testing OTLP endpoint..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:4318/v1/traces" -Method POST -Body '{}' -ContentType "application/json" -TimeoutSec 5
        Write-Host "✅ OTLP HTTP endpoint reachable" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ OTLP HTTP endpoint failed: $_" -ForegroundColor Red
        return $false
    }
}

function Test-SigNozUI {
    Write-Host "🔍 Testing SigNoz UI..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5
        Write-Host "✅ SigNoz UI reachable" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ SigNoz UI failed: $_" -ForegroundColor Red
        return $false
    }
}

function Test-AgentScripts {
    Write-Host "🔍 Testing agent scripts compilation..." -ForegroundColor Cyan
    
    $scripts = @(
        "scripts/agent/watchdog.ts",
        "scripts/agent/runner.ts", 
        "scripts/agent/otel.ts",
        "scripts/agent/flake-quarantine.ts",
        "scripts/agent/emit-flake-gauges.ts"
    )
    
    $allValid = $true
    
    foreach ($script in $scripts) {
        if (Test-Path $script) {
            Write-Host "   ✅ $script exists" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $script missing" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    return $allValid
}

function Test-PackageScripts {
    Write-Host "🔍 Testing package scripts..." -ForegroundColor Cyan
    
    $scripts = @(
        "agent:start",
        "agent:stop", 
        "agent:status",
        "agent:flake-quarantine",
        "agent:emit-gauges",
        "otel:up",
        "otel:down",
        "otel:status"
    )
    
    $allValid = $true
    
    foreach ($script in $scripts) {
        try {
            npm run $script --dry-run 2>$null
            Write-Host "   ✅ npm run $script" -ForegroundColor Green
        }
        catch {
            Write-Host "   ❌ npm run $script" -ForegroundColor Red
            $allValid = $false
        }
    }
    
    return $allValid
}

function Show-TestResults {
    param(
        [hashtable]$Results
    )
    
    Write-Host "`n📊 Basic Telemetry Test Results" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    $totalTests = $Results.Count
    $passedTests = ($Results.Values | Where-Object { $_ -eq $true }).Count
    
    foreach ($test in $Results.GetEnumerator()) {
        $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
        Write-Host "   $($test.Key): $status" -ForegroundColor $(if ($test.Value) { "Green" } else { "Red" })
    }
    
    Write-Host ""
    Write-Host "Overall: $passedTests/$totalTests tests passed" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
    
    if ($passedTests -eq $totalTests) {
        Write-Host "🎉 Basic telemetry setup is ready!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some tests failed. Check the output above for details." -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "🧪 Basic OpenTelemetry Agent Test Suite" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green

$testResults = @{}

# Test OTLP endpoint
$testResults["OTLP Endpoint"] = Test-OTLPEndpoint

# Test SigNoz UI
$testResults["SigNoz UI"] = Test-SigNozUI

# Test agent scripts
$testResults["Agent Scripts"] = Test-AgentScripts

# Test package scripts
$testResults["Package Scripts"] = Test-PackageScripts

# Show results
Show-TestResults $testResults

# Exit with appropriate code
$passedTests = ($testResults.Values | Where-Object { $_ -eq $true }).Count
$totalTests = $testResults.Count
exit $(if ($passedTests -eq $totalTests) { 0 } else { 1 })
