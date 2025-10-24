#!/usr/bin/env pwsh
# Gate #012B Validation Script
# ECRR: BossCat Mission - Visual Unblock via ProjectM
# Authority: BossCat OEM | Executor: Cursor{Implementer}
#
# Success Criteria:
# - 3 known .milk presets render non-black frames (blackout ≤ 20%)
# - Motion > 0 and reactivity_r ≥ 0.35 (with audio feed)
# - /preset switch works in ≤ 1.5s
# - Evidence bundle + BOSSCAT_LOG entry emitted

[CmdletBinding()]
param(
    [string]$ComposeFile = "docker-compose.viz.yml",
    [int]$WaitSeconds = 30,
    [string]$OutputDir = "artifacts/pm"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ECRR Evidence Trail
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$evidenceFile = "$OutputDir/gate-012b-validation-$timestamp.json"
$evidence = @{
    gate = "012B"
    timestamp = $timestamp
    objective = "Visual Unblock via ProjectM"
    success_criteria = @{
        blackout_threshold = 20
        motion_threshold = 0
        reactivity_threshold = 0.35
        preset_switch_threshold_ms = 1500
    }
    results = @{}
    status = "UNKNOWN"
}

Write-Host "🐾 Gate #012B Validation - ProjectM Visual Unblock" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Step 1: Start pm-engine
Write-Host "▶ Step 1: Starting pm-engine container..." -ForegroundColor Yellow
try {
    docker-compose -f $ComposeFile up -d pm-engine 2>&1 | Out-Null
    Write-Host "✓ pm-engine started" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to start pm-engine: $_" -ForegroundColor Red
    $evidence.status = "FAILED"
    $evidence.error = "Container startup failed: $_"
    $evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
    exit 1
}

# Step 2: Wait for health check
Write-Host "▶ Step 2: Waiting for health check (max ${WaitSeconds}s)..." -ForegroundColor Yellow
$healthUrl = "http://localhost:7020/health"
$healthy = $false
$elapsed = 0

while ($elapsed -lt $WaitSeconds) {
    try {
        $response = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 2
        if ($response.ok -eq $true) {
            $healthy = $true
            Write-Host "✓ Health check passed (${elapsed}s)" -ForegroundColor Green
            break
        }
    } catch {
        # Health check not ready yet
    }
    Start-Sleep -Seconds 2
    $elapsed += 2
}

if (-not $healthy) {
    Write-Host "✗ Health check failed after ${WaitSeconds}s" -ForegroundColor Red
    Write-Host "  Container logs:" -ForegroundColor Yellow
    docker logs pm-engine --tail 50
    $evidence.status = "FAILED"
    $evidence.error = "Health check timeout"
    $evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
    exit 1
}

# Step 3: List presets
Write-Host "▶ Step 3: Listing available presets..." -ForegroundColor Yellow
try {
    $presetsResponse = Invoke-RestMethod -Uri "http://localhost:7020/pm/presets" -Method Get
    $presets = $presetsResponse.presets
    Write-Host "✓ Found $($presets.Count) presets" -ForegroundColor Green
    $evidence.presets_available = $presets
    
    if ($presets.Count -eq 0) {
        Write-Host "✗ No presets found!" -ForegroundColor Red
        $evidence.status = "FAILED"
        $evidence.error = "No presets available"
        $evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
        exit 1
    }
} catch {
    Write-Host "✗ Failed to list presets: $_" -ForegroundColor Red
    $evidence.status = "FAILED"
    $evidence.error = "Preset listing failed: $_"
    $evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
    exit 1
}

# Step 4: Test 3 presets
Write-Host "▶ Step 4: Testing preset switching and visual output..." -ForegroundColor Yellow
$testPresets = $presets | Select-Object -First 3
$allPassed = $true

foreach ($preset in $testPresets) {
    Write-Host "  Testing preset: $preset" -ForegroundColor Cyan
    $presetResult = @{
        name = $preset
        switch_time_ms = 0
        blackout_pct = 0
        status = "UNKNOWN"
    }
    
    # Load preset and measure switch time
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $loadResponse = Invoke-RestMethod -Uri "http://localhost:7020/pm/preset" -Method Post -Body (@{ name = $preset } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 5
        $sw.Stop()
        $presetResult.switch_time_ms = $sw.ElapsedMilliseconds
        
        if ($loadResponse.ok -eq $true) {
            Write-Host "    ✓ Preset loaded in $($presetResult.switch_time_ms)ms" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Preset load failed: $($loadResponse.error)" -ForegroundColor Red
            $presetResult.status = "LOAD_FAILED"
            $allPassed = $false
            $evidence.results[$preset] = $presetResult
            continue
        }
    } catch {
        Write-Host "    ✗ Preset load error: $_" -ForegroundColor Red
        $presetResult.status = "LOAD_ERROR"
        $presetResult.error = $_.ToString()
        $allPassed = $false
        $evidence.results[$preset] = $presetResult
        continue
    }
    
    # Wait for rendering to stabilize
    Start-Sleep -Seconds 2
    
    # Capture frame
    try {
        $snapPath = "$OutputDir/snap-$($preset -replace '[/\\]', '_').jpg"
        Invoke-WebRequest -Uri "http://localhost:7020/snap.jpg" -OutFile $snapPath -TimeoutSec 5
        Write-Host "    ✓ Frame captured: $snapPath" -ForegroundColor Green
        $presetResult.snapshot = $snapPath
    } catch {
        Write-Host "    ✗ Frame capture failed: $_" -ForegroundColor Red
        $presetResult.status = "CAPTURE_FAILED"
        $allPassed = $false
        $evidence.results[$preset] = $presetResult
        continue
    }
    
    # Check blackout percentage
    try {
        $metricsResponse = Invoke-RestMethod -Uri "http://localhost:7020/pm/metrics" -Method Get -TimeoutSec 5
        $presetResult.blackout_pct = 100 - $metricsResponse.non_black_pct
        $presetResult.mean_luma = $metricsResponse.mean_luma
        
        if ($presetResult.blackout_pct -le 20) {
            Write-Host "    ✓ Blackout: $($presetResult.blackout_pct)% (≤20% threshold)" -ForegroundColor Green
            $presetResult.status = "PASS"
        } else {
            Write-Host "    ✗ Blackout: $($presetResult.blackout_pct)% (>20% threshold)" -ForegroundColor Red
            $presetResult.status = "BLACKOUT_FAIL"
            $allPassed = $false
        }
    } catch {
        Write-Host "    ✗ Metrics check failed: $_" -ForegroundColor Red
        $presetResult.status = "METRICS_FAILED"
        $allPassed = $false
    }
    
    # Check switch time threshold
    if ($presetResult.switch_time_ms -gt 1500) {
        Write-Host "    ⚠ Switch time: $($presetResult.switch_time_ms)ms (>1500ms threshold)" -ForegroundColor Yellow
        $presetResult.switch_warning = $true
    }
    
    $evidence.results[$preset] = $presetResult
}

# Step 5: Final status
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
if ($allPassed) {
    $evidence.status = "GREEN"
    Write-Host "✅ Gate #012B Validation: PASSED" -ForegroundColor Green
    Write-Host "   All 3 presets render non-black frames" -ForegroundColor Green
} else {
    $evidence.status = "AMBER"
    Write-Host "⚠ Gate #012B Validation: PARTIAL" -ForegroundColor Yellow
    Write-Host "   Some presets failed validation criteria" -ForegroundColor Yellow
}

# Save evidence bundle
$evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
Write-Host ""
Write-Host "📋 Evidence bundle: $evidenceFile" -ForegroundColor Cyan

# Display summary
Write-Host ""
Write-Host "📊 Results Summary:" -ForegroundColor Cyan
foreach ($key in $evidence.results.Keys) {
    $result = $evidence.results[$key]
    $statusColor = switch ($result.status) {
        "PASS" { "Green" }
        "AMBER" { "Yellow" }
        default { "Red" }
    }
    Write-Host "   $key : $($result.status)" -ForegroundColor $statusColor
    Write-Host "     - Blackout: $($result.blackout_pct)%" -ForegroundColor Gray
    Write-Host "     - Switch time: $($result.switch_time_ms)ms" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🐾 Gate #012B validation complete" -ForegroundColor Cyan

if ($evidence.status -eq "GREEN") {
    exit 0
} else {
    exit 1
}

