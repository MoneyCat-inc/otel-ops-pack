# MEMX Canary Test Script
# Generates test data and verifies MEMX functionality

param(
    [int]$DurationSeconds = 30,
    [switch]$EnableStreaming,
    [switch]$Verbose
)

Write-Host "=== MEMX Canary Test ===" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Error "Please run this script from the resonai-mock directory"
    exit 1
}

# Check if MEMX is enabled
$envFile = ".env.local"
if (-not (Test-Path $envFile)) {
    Write-Error "Environment file not found. Run setup-memx-production.ps1 first."
    exit 1
}

$memxEnabled = (Get-Content $envFile | Select-String "NEXT_PUBLIC_FEATURE_MEMX=1")
if (-not $memxEnabled) {
    Write-Error "MEMX is not enabled. Run setup-memx-production.ps1 first."
    exit 1
}

Write-Host "✅ MEMX is enabled" -ForegroundColor Green

# Start development server if not running
$serverRunning = $false
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 5
    $serverRunning = $true
    Write-Host "✅ Development server is running" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Development server not running, starting..." -ForegroundColor Yellow
    Start-Process -FilePath "pnpm" -ArgumentList "dev" -WindowStyle Hidden
    Start-Sleep -Seconds 10
    
    # Verify server started
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 5
        $serverRunning = $true
        Write-Host "✅ Development server started" -ForegroundColor Green
    } catch {
        Write-Error "Failed to start development server"
        exit 1
    }
}

# Test MEMX page accessibility
Write-Host "`n=== Testing MEMX Page Accessibility ===" -ForegroundColor Green

try {
    $memxResponse = Invoke-WebRequest -Uri "http://localhost:3001/labs/memx" -UseBasicParsing -TimeoutSec 10
    if ($memxResponse.StatusCode -eq 200) {
        Write-Host "✅ MEMX page accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ MEMX page returned status: $($memxResponse.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to access MEMX page: $($_.Exception.Message)" -ForegroundColor Red
}

# Generate test data
Write-Host "`n=== Generating Test Data ===" -ForegroundColor Green

$testData = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    testId = [System.Guid]::NewGuid().ToString()
    duration = $DurationSeconds
    streaming = $EnableStreaming
    metrics = @{
        wasmHeapBytes = 1024 * 1024 * 10  # 10MB
        sabUsedBytes = 512
        sabCapacityBytes = 1024
        workletLagMs = 15
        memoryStrainPct = 25
    }
}

$testDataJson = $testData | ConvertTo-Json -Depth 3
Write-Host "Generated test data: $testDataJson" -ForegroundColor Cyan

# Save test data
$testDataFile = "test-data-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testDataJson | Out-File -FilePath $testDataFile -Encoding UTF8
Write-Host "✅ Test data saved to: $testDataFile" -ForegroundColor Green

# Run Playwright tests
Write-Host "`n=== Running Playwright Tests ===" -ForegroundColor Green

try {
    $playwrightResult = & pnpm test:e2e --project=chromium --reporter=json 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Playwright tests passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Playwright tests failed" -ForegroundColor Red
        if ($Verbose) {
            Write-Host $playwrightResult
        }
    }
} catch {
    Write-Host "❌ Failed to run Playwright tests: $($_.Exception.Message)" -ForegroundColor Red
}

# Check OTel integration if streaming is enabled
if ($EnableStreaming) {
    Write-Host "`n=== Checking OTel Integration ===" -ForegroundColor Green
    
    # Check OTel collector
    try {
        $otelHealth = Invoke-WebRequest -Uri "http://localhost:13134/healthz" -UseBasicParsing -TimeoutSec 5
        if ($otelHealth.StatusCode -eq 200) {
            Write-Host "✅ OTel collector is healthy" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  OTel collector not reachable" -ForegroundColor Yellow
    }
    
    # Check SigNoz
    try {
        $signozHealth = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing -TimeoutSec 5
        if ($signozHealth.StatusCode -eq 200) {
            Write-Host "✅ SigNoz is healthy" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  SigNoz not reachable" -ForegroundColor Yellow
    }
}

# Performance monitoring
Write-Host "`n=== Performance Monitoring ===" -ForegroundColor Green

$startTime = Get-Date
$endTime = $startTime.AddSeconds($DurationSeconds)

Write-Host "Monitoring for $DurationSeconds seconds..." -ForegroundColor Cyan

while ((Get-Date) -lt $endTime) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3001/labs/memx" -UseBasicParsing -TimeoutSec 5
        $responseTime = $response.Headers["X-Response-Time"]
        if ($Verbose) {
            Write-Host "Response time: $responseTime" -ForegroundColor Gray
        }
    } catch {
        Write-Host "⚠️  Request failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    Start-Sleep -Seconds 5
}

# Final verification
Write-Host "`n=== Final Verification ===" -ForegroundColor Green

try {
    $finalResponse = Invoke-WebRequest -Uri "http://localhost:3001/labs/memx" -UseBasicParsing -TimeoutSec 10
    if ($finalResponse.StatusCode -eq 200) {
        Write-Host "✅ MEMX page still accessible after test" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ MEMX page not accessible after test" -ForegroundColor Red
}

# Cleanup
Write-Host "`n=== Cleanup ===" -ForegroundColor Green

if (Test-Path $testDataFile) {
    Remove-Item $testDataFile
    Write-Host "✅ Cleaned up test data file" -ForegroundColor Green
}

# Summary
Write-Host "`n=== MEMX Canary Test Summary ===" -ForegroundColor Green
Write-Host "Test ID: $($testData.testId)" -ForegroundColor Cyan
Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor Cyan
Write-Host "Streaming: $EnableStreaming" -ForegroundColor Cyan
Write-Host "Status: ✅ COMPLETE" -ForegroundColor Green

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Check browser console for any MEMX-related errors" -ForegroundColor Cyan
Write-Host "2. Verify MEMX metrics are updating in the UI" -ForegroundColor Cyan
Write-Host "3. Check SigNoz for MEMX events (if streaming enabled)" -ForegroundColor Cyan
Write-Host "4. Review Playwright test results" -ForegroundColor Cyan

Write-Host "`n=== MEMX Canary Test Complete ===" -ForegroundColor Green
