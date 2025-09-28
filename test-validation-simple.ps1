# Simple Validation Test
Write-Host "Testing Validation Scripts..." -ForegroundColor Green

# Test 1: Check if validation scripts exist
$validationScripts = @(
    "validation/validate-otlp-exporter.ps1",
    "validation/validate-tail-sampling.ps1", 
    "validation/validate-cardinality.ps1",
    "validation/validate-gpu-thermal.ps1"
)

Write-Host "`n🔍 Checking validation scripts..." -ForegroundColor Cyan
foreach ($script in $validationScripts) {
    if (Test-Path $script) {
        Write-Host "✅ $script exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $script not found" -ForegroundColor Red
    }
}

# Test 2: Check collector health
Write-Host "`n🔍 Checking collector health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:13134/" -Method Get -TimeoutSec 5
    if ($response.status -eq "Server available") {
        Write-Host "✅ Collector health check passed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Collector status: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Collector health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check SigNoz UI
Write-Host "`n🔍 Checking SigNoz UI..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5
    if ($response.status -eq "ok") {
        Write-Host "✅ SigNoz UI health check passed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  SigNoz UI status: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ SigNoz UI health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Check metrics endpoint
Write-Host "`n🔍 Checking metrics endpoint..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -Method Get -TimeoutSec 5
    $otelLines = $response -split "`n" | Where-Object { $_ -match "otelcol_" }
    Write-Host "✅ Metrics endpoint healthy ($($otelLines.Count) metrics)" -ForegroundColor Green
} catch {
    Write-Host "❌ Metrics endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Check OTLP endpoint
Write-Host "`n🔍 Checking OTLP endpoint..." -ForegroundColor Cyan
try {
    $testPayload = @{
        resourceLogs = @(
            @{
                resource = @{ attributes = @() }
                scopeLogs = @(
                    @{
                        logRecords = @(
                            @{
                                timeUnixNano = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000
                                severityNumber = 17
                                severityText = "INFO"
                                body = @{ stringValue = "Validation test log" }
                                attributes = @()
                            }
                        )
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 10

    $response = Invoke-RestMethod -Uri "http://localhost:14318/v1/logs" -Method Post -Body $testPayload -ContentType "application/json" -TimeoutSec 5
    Write-Host "✅ OTLP endpoint test passed" -ForegroundColor Green
} catch {
    Write-Host "❌ OTLP endpoint test failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Validation test complete" -ForegroundColor Green


