# Gate #016 Job V1 - Visual Guard Test Script
# Test all curated presets for blackout behavior and guard effectiveness

param(
    [int]$DurationSeconds = 60,
    [int]$PollIntervalMs = 100,
    [string]$BaseUrl = "http://localhost:7020",
    [string]$OutputPath = "artifacts/pm/gate-016-v1-test.jsonl"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #016 Job V1 - Visual Guard Validation ===" -ForegroundColor Cyan
Write-Host "Duration: $DurationSeconds seconds per preset"
Write-Host "Poll interval: $PollIntervalMs ms"
Write-Host "Base URL: $BaseUrl"
Write-Host ""

# Ensure output directory exists
$outputDir = Split-Path -Parent $OutputPath
if ($outputDir -and !(Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

# Load curated preset index
$indexPath = "presets-projectm/curated/index.json"
if (!(Test-Path $indexPath)) {
    Write-Host "ERROR: Preset index not found: $indexPath" -ForegroundColor Red
    exit 1
}

$presetIndex = Get-Content $indexPath -Raw | ConvertFrom-Json
Write-Host "Loaded $($presetIndex.Count) curated presets from $indexPath" -ForegroundColor Green
Write-Host ""

# Results array
$allResults = @()

foreach ($presetMeta in $presetIndex) {
    $presetName = $presetMeta.file
    $presetShortName = $presetMeta.name
    
    Write-Host "--- Testing: $presetShortName ($presetName) ---" -ForegroundColor Yellow
    
    # Reset guard statistics
    try {
        $resetResp = Invoke-RestMethod -Uri "$BaseUrl/guard/reset" -Method POST -TimeoutSec 5
        Write-Host "  Guard reset: $($resetResp.message)"
    } catch {
        Write-Host "  WARNING: Failed to reset guard: $_" -ForegroundColor Yellow
    }
    
    # Load preset
    try {
        $loadResp = Invoke-RestMethod -Uri "$BaseUrl/pm/preset" -Method POST -Body (@{name=$presetName} | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        Write-Host "  Preset loaded: $($loadResp.preset)"
    } catch {
        Write-Host "  ERROR: Failed to load preset: $_" -ForegroundColor Red
        $allResults += @{
            preset = $presetShortName
            status = "LOAD_FAILED"
            error = $_.ToString()
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        continue
    }
    
    # Wait for preset to stabilize
    Start-Sleep -Seconds 2
    
    # Run test: poll metrics for specified duration
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($DurationSeconds)
    $pollCount = 0
    
    Write-Host "  Running $DurationSeconds second test (polling every ${PollIntervalMs}ms)..."
    
    while ((Get-Date) -lt $endTime) {
        try {
            $metricsResp = Invoke-RestMethod -Uri "$BaseUrl/pm/metrics" -Method GET -TimeoutSec 5
            $pollCount++
            
            # Log if guard triggered
            if ($metricsResp.guard.triggered) {
                Write-Host "    [GUARD TRIGGERED at poll #$pollCount] luma=$($metricsResp.mean_luma.ToString("0.####"))" -ForegroundColor Magenta
            }
        } catch {
            Write-Host "    WARNING: Metrics poll failed: $_" -ForegroundColor Yellow
        }
        
        Start-Sleep -Milliseconds $PollIntervalMs
    }
    
    Write-Host "  Completed $pollCount polls"
    
    # Get final guard statistics
    try {
        $statsResp = Invoke-RestMethod -Uri "$BaseUrl/guard/stats" -Method GET -TimeoutSec 5
        
        $blackoutRatio = $statsResp.blackoutRatio
        $maxBlackoutGapMs = $statsResp.maxBlackoutGapMs
        $triggerCount = $statsResp.triggerCount
        
        # Acceptance criteria
        $passBlackout = $blackoutRatio -le 5.0
        $passGap = $maxBlackoutGapMs -le 150
        $overallPass = $passBlackout -and $passGap
        
        $statusColor = if ($overallPass) { "Green" } else { "Red" }
        $statusText = if ($overallPass) { "PASS" } else { "FAIL" }
        
        Write-Host "  Results:" -ForegroundColor $statusColor
        Write-Host "    Blackout ratio: $($blackoutRatio.ToString("0.##"))% (target ≤5%, $(if ($passBlackout) {'PASS'} else {'FAIL'}))" -ForegroundColor $statusColor
        Write-Host "    Max blackout gap: ${maxBlackoutGapMs}ms (target ≤150ms, $(if ($passGap) {'PASS'} else {'FAIL'}))" -ForegroundColor $statusColor
        Write-Host "    Guard triggers: $triggerCount"
        Write-Host "    Status: $statusText" -ForegroundColor $statusColor
        
        # Record result
        $result = @{
            preset = $presetShortName
            presetFile = $presetName
            tags = $presetMeta.tags
            durationSeconds = $DurationSeconds
            pollCount = $pollCount
            pollIntervalMs = $PollIntervalMs
            blackoutRatio = $blackoutRatio
            maxBlackoutGapMs = $maxBlackoutGapMs
            triggerCount = $triggerCount
            frameCount = $statsResp.frameCount
            lowLumaFrames = $statsResp.lowLumaFrames
            lastLuma = $statsResp.lastLuma
            lMin = $statsResp.lMin
            guardWindowMs = $statsResp.guardWindowMs
            guardMode = $statsResp.guardMode
            passBlackout = $passBlackout
            passGap = $passGap
            status = $statusText
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
        
        $allResults += $result
        
        # Append to JSONL
        $result | ConvertTo-Json -Compress | Out-File -Append -Encoding UTF8 $OutputPath
        
    } catch {
        Write-Host "  ERROR: Failed to get guard stats: $_" -ForegroundColor Red
        $allResults += @{
            preset = $presetShortName
            status = "STATS_FAILED"
            error = $_.ToString()
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        }
    }
    
    Write-Host ""
}

# Summary report
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
$passCount = ($allResults | Where-Object { $_.status -eq "PASS" }).Count
$failCount = ($allResults | Where-Object { $_.status -eq "FAIL" }).Count
$errorCount = ($allResults | Where-Object { $_.status -like "*FAILED" }).Count

Write-Host "Total presets tested: $($allResults.Count)"
Write-Host "PASS: $passCount" -ForegroundColor Green
Write-Host "FAIL: $failCount" -ForegroundColor Red
Write-Host "ERROR: $errorCount" -ForegroundColor Yellow
Write-Host ""

if ($passCount -eq $allResults.Count) {
    Write-Host "✅ ALL PRESETS PASSED - Job V1 GREEN" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ SOME PRESETS FAILED - Job V1 needs revision" -ForegroundColor Red
    Write-Host ""
    Write-Host "Failed presets:"
    foreach ($result in ($allResults | Where-Object { $_.status -eq "FAIL" })) {
        Write-Host "  - $($result.preset): blackout=$($result.blackoutRatio)%, gap=$($result.maxBlackoutGapMs)ms" -ForegroundColor Red
    }
    exit 1
}

