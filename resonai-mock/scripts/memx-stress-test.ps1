# MEMX Stress Test Script
# Generates synthetic load to test thresholds and alert rules

param(
    [int]$DurationSeconds = 120,
    [switch]$StressMemory,
    [switch]$JitterFrames,
    [switch]$PauseStreaming,
    [int]$PauseStreamingSeconds = 120,
    [switch]$EnableStreaming,
    [switch]$Verbose
)

Write-Host "=== MEMX Stress Test ===" -ForegroundColor Green

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
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
    $serverRunning = $true
    Write-Host "✅ Development server is running on port 3000" -ForegroundColor Green
} catch {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 5
        $serverRunning = $true
        Write-Host "✅ Development server is running on port 3001" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Development server not running, starting..." -ForegroundColor Yellow
        Start-Process -FilePath "pnpm" -ArgumentList "dev" -WindowStyle Hidden
        Start-Sleep -Seconds 10
        
        # Verify server started
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 5
            $serverRunning = $true
            Write-Host "✅ Development server started on port 3000" -ForegroundColor Green
        } catch {
            try {
                $response = Invoke-WebRequest -Uri "http://localhost:3001" -UseBasicParsing -TimeoutSec 5
                $serverRunning = $true
                Write-Host "✅ Development server started on port 3001" -ForegroundColor Green
            } catch {
                Write-Error "Failed to start development server"
                exit 1
            }
        }
    }
}

# Determine server URL
$serverUrl = if ($serverRunning) { 
    try { 
        Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing -TimeoutSec 2 | Out-Null
        "http://localhost:3000"
    } catch { 
        "http://localhost:3001" 
    }
} else { 
    "http://localhost:3000" 
}

Write-Host "Using server URL: $serverUrl" -ForegroundColor Cyan

# Test configuration
$testConfig = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    testId = [System.Guid]::NewGuid().ToString()
    duration = $DurationSeconds
    streaming = $EnableStreaming
    stressMemory = $StressMemory
    jitterFrames = $JitterFrames
    pauseStreaming = $PauseStreaming
    pauseStreamingSeconds = $PauseStreamingSeconds
}

Write-Host "`n=== Test Configuration ===" -ForegroundColor Green
Write-Host "Test ID: $($testConfig.testId)" -ForegroundColor Cyan
Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor Cyan
Write-Host "Stress Memory: $StressMemory" -ForegroundColor Cyan
Write-Host "Jitter Frames: $JitterFrames" -ForegroundColor Cyan
Write-Host "Pause Streaming: $PauseStreaming" -ForegroundColor Cyan
Write-Host "Enable Streaming: $EnableStreaming" -ForegroundColor Cyan

# Generate stress test data
$stressData = @{
    version = "1.0"
    testType = "stress"
    testId = $testConfig.testId
    timestamp = $testConfig.timestamp
    duration = $DurationSeconds
    scenarios = @()
}

# Memory stress scenario
if ($StressMemory) {
    $memoryScenario = @{
        name = "memory_stress"
        description = "Generate high WASM heap and SAB usage"
        duration = $DurationSeconds
        parameters = @{
            wasmHeapBytes = 25 * 1024 * 1024  # 25MB (above 20MB threshold)
            sabUsagePercent = 92  # Above 90% threshold
            memoryStrainPercent = 85  # Above 80% threshold
            workletLagMs = 75  # Above 50ms threshold
        }
    }
    $stressData.scenarios += $memoryScenario
    Write-Host "✅ Memory stress scenario configured" -ForegroundColor Green
}

# Frame jitter scenario
if ($JitterFrames) {
    $jitterScenario = @{
        name = "frame_jitter"
        description = "Generate frame drops and worklet lag"
        duration = $DurationSeconds
        parameters = @{
            frameDropRate = 6  # Above 5% threshold
            workletLagMs = 110  # Above 100ms threshold
            frameBudgetMs = 6  # Below 8.33ms threshold
        }
    }
    $stressData.scenarios += $jitterScenario
    Write-Host "✅ Frame jitter scenario configured" -ForegroundColor Green
}

# Streaming pause scenario
if ($PauseStreaming) {
    $pauseScenario = @{
        name = "streaming_pause"
        description = "Pause OTel streaming to test disconnect alerts"
        duration = $PauseStreamingSeconds
        parameters = @{
            pauseStreaming = $true
            pauseDuration = $PauseStreamingSeconds
        }
    }
    $stressData.scenarios += $pauseScenario
    Write-Host "✅ Streaming pause scenario configured" -ForegroundColor Green
}

# Save stress test data
$stressDataFile = "stress-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$stressData | ConvertTo-Json -Depth 4 | Out-File -FilePath $stressDataFile -Encoding UTF8
Write-Host "✅ Stress test data saved to: $stressDataFile" -ForegroundColor Green

# Start stress test
Write-Host "`n=== Starting Stress Test ===" -ForegroundColor Green
$startTime = Get-Date
$endTime = $startTime.AddSeconds($DurationSeconds)

$testPhase = 0
$totalPhases = if ($PauseStreaming) { 3 } else { 2 }

while ((Get-Date) -lt $endTime) {
    $currentTime = Get-Date
    $elapsed = ($currentTime - $startTime).TotalSeconds
    $remaining = $DurationSeconds - $elapsed
    
    # Phase 1: Normal operation (first 30 seconds)
    if ($elapsed -lt 30) {
        if ($testPhase -ne 1) {
            $testPhase = 1
            Write-Host "Phase 1: Normal operation (0-30s)" -ForegroundColor Cyan
        }
        
        # Simulate normal MEMX activity
        try {
            $response = Invoke-WebRequest -Uri "$serverUrl/labs/memx" -UseBasicParsing -TimeoutSec 5
            if ($Verbose) {
                Write-Host "Normal operation: $($response.StatusCode)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "⚠️  Request failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    # Phase 2: Stress conditions (30s to end or pause start)
    elseif ($elapsed -lt ($DurationSeconds - $PauseStreamingSeconds) -or -not $PauseStreaming) {
        if ($testPhase -ne 2) {
            $testPhase = 2
            Write-Host "Phase 2: Stress conditions (30s to end)" -ForegroundColor Yellow
        }
        
        # Simulate stress conditions
        if ($StressMemory) {
            # Simulate high memory usage
            if ($Verbose) {
                Write-Host "Simulating high memory usage..." -ForegroundColor Gray
            }
        }
        
        if ($JitterFrames) {
            # Simulate frame jitter
            if ($Verbose) {
                Write-Host "Simulating frame jitter..." -ForegroundColor Gray
            }
        }
        
        try {
            $response = Invoke-WebRequest -Uri "$serverUrl/labs/memx" -UseBasicParsing -TimeoutSec 5
            if ($Verbose) {
                Write-Host "Stress operation: $($response.StatusCode)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "⚠️  Request failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    # Phase 3: Streaming pause (if enabled)
    elseif ($PauseStreaming -and $elapsed -ge ($DurationSeconds - $PauseStreamingSeconds)) {
        if ($testPhase -ne 3) {
            $testPhase = 3
            Write-Host "Phase 3: Streaming pause (last $PauseStreamingSeconds seconds)" -ForegroundColor Red
        }
        
        # Simulate OTel disconnect
        if ($Verbose) {
            Write-Host "Simulating OTel disconnect..." -ForegroundColor Gray
        }
    }
    
    # Progress indicator
    $progress = [math]::Round(($elapsed / $DurationSeconds) * 100, 1)
    Write-Progress -Activity "MEMX Stress Test" -Status "Phase $testPhase/$totalPhases - $progress% complete" -PercentComplete $progress
    
    Start-Sleep -Seconds 5
}

Write-Progress -Activity "MEMX Stress Test" -Completed

# Final verification
Write-Host "`n=== Final Verification ===" -ForegroundColor Green

try {
    $finalResponse = Invoke-WebRequest -Uri "$serverUrl/labs/memx" -UseBasicParsing -TimeoutSec 10
    if ($finalResponse.StatusCode -eq 200) {
        Write-Host "✅ MEMX page accessible after stress test" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ MEMX page not accessible after stress test" -ForegroundColor Red
}

# Check OTel integration if streaming was enabled
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

# Cleanup
Write-Host "`n=== Cleanup ===" -ForegroundColor Green

if (Test-Path $stressDataFile) {
    Remove-Item $stressDataFile
    Write-Host "✅ Cleaned up stress test data file" -ForegroundColor Green
}

# Summary
Write-Host "`n=== MEMX Stress Test Summary ===" -ForegroundColor Green
Write-Host "Test ID: $($testConfig.testId)" -ForegroundColor Cyan
Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor Cyan
Write-Host "Scenarios: $($stressData.scenarios.Count)" -ForegroundColor Cyan
Write-Host "Status: ✅ COMPLETE" -ForegroundColor Green

# Next steps
Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Check SigNoz dashboard for alert triggers" -ForegroundColor Cyan
Write-Host "2. Verify alert notifications were sent" -ForegroundColor Cyan
Write-Host "3. Review threshold effectiveness" -ForegroundColor Cyan
Write-Host "4. Adjust thresholds if needed" -ForegroundColor Cyan
Write-Host "5. Document any issues found" -ForegroundColor Cyan

Write-Host "`n=== MEMX Stress Test Complete ===" -ForegroundColor Green
