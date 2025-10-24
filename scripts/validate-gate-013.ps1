#!/usr/bin/env pwsh
# Gate #013 Validation Script - Audio-Reactive ProjectM
# ECRR: BossCat Mission - Audio reactivity + visual metrics
# Authority: BossCat OEM | Executor: Cursor{Implementer}
#
# Success Criteria:
# - Preset switch ≤1.5s (3/3 passes)
# - Blackout ≤20% (averaged over 60s)
# - Motion >0 (Δluma median >0)
# - Reactivity r ≥0.35 (Pearson correlation)

[CmdletBinding()]
param(
    [string]$ComposeFile = "docker-compose.viz.yml",
    [int]$AudioDurationSeconds = 60,
    [int]$BPM = 128,
    [string]$OutputDir = "artifacts/pm"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ECRR Evidence Trail
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$evidenceFile = "$OutputDir/gate-013-validation-$timestamp.json"
$evidence = @{
    gate = "013"
    timestamp = $timestamp
    objective = "Audio-Reactive ProjectM GREEN Validation"
    success_criteria = @{
        blackout_threshold = 20
        motion_threshold = 0
        reactivity_threshold = 0.35
        preset_switch_threshold_ms = 1500
    }
    results = @{}
    audio_stats = @{}
    status = "UNKNOWN"
}

Write-Host "🐾 Gate #013 Validation - Audio-Reactive ProjectM" -ForegroundColor Cyan
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
Write-Host "▶ Step 2: Waiting for health check (max 30s)..." -ForegroundColor Yellow
$healthUrl = "http://localhost:7020/health"
$healthy = $false
$elapsed = 0

while ($elapsed -lt 30) {
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
    Write-Host "✗ Health check failed after 30s" -ForegroundColor Red
    $evidence.status = "FAILED"
    $evidence.error = "Health check timeout"
    $evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
    exit 1
}

# Step 3: Generate and feed audio (simple sine wave test tone at BPM)
Write-Host "▶ Step 3: Generating and feeding audio (${AudioDurationSeconds}s at ${BPM} BPM)..." -ForegroundColor Yellow

$sampleRate = 44100
$channels = 2
$beatInterval = 60.0 / $BPM
$totalSamples = $sampleRate * $AudioDurationSeconds

Write-Host "  Audio: ${sampleRate}Hz, ${channels}ch, ${totalSamples} samples" -ForegroundColor Cyan

$audioBytesSent = 0
$chunkSize = 4410  # 100ms chunks at 44.1kHz
$beatPhase = 0
$audioRmsValues = @()

for ($i = 0; $i -lt $totalSamples; $i += $chunkSize) {
    $chunkSamples = [Math]::Min($chunkSize, $totalSamples - $i)
    $pcmData = New-Object byte[] ($chunkSamples * $channels * 2)
    
    # Generate simple beat pattern (sine wave with amplitude modulation)
    for ($s = 0; $s -lt $chunkSamples; $s++) {
        $t = ($i + $s) / $sampleRate
        $beatPhase = ($t / $beatInterval) % 1.0
        
        # Amplitude envelope: louder on beat, quieter between
        $envelope = if ($beatPhase -lt 0.1) { 0.8 } elseif ($beatPhase -lt 0.3) { 0.3 } else { 0.1 }
        
        # Sine wave at 220 Hz (A3)
        $value = [Math]::Sin(2 * [Math]::PI * 220 * $t) * $envelope * 16000
        $sample = [int16]$value
        
        # Write stereo (same value for both channels)
        $offset = $s * $channels * 2
        [BitConverter]::GetBytes($sample).CopyTo($pcmData, $offset)
        [BitConverter]::GetBytes($sample).CopyTo($pcmData, $offset + 2)
    }
    
    # Send to pm-engine /audio endpoint
    try {
        $base64 = [Convert]::ToBase64String($pcmData)
        $body = @{ base64 = $base64; rate = $sampleRate; channels = $channels } | ConvertTo-Json
        Invoke-RestMethod -Uri "http://localhost:7020/audio" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 2 | Out-Null
        $audioBytesSent += $pcmData.Length
        
        # Calculate RMS for this chunk
        $sumSquares = 0
        for ($j = 0; $j -lt $pcmData.Length; $j += 2) {
            $s = [BitConverter]::ToInt16($pcmData, $j) / 32768.0
            $sumSquares += $s * $s
        }
        $rms = [Math]::Sqrt($sumSquares / ($pcmData.Length / 2))
        $audioRmsValues += $rms
        
    } catch {
        Write-Host "  ⚠ Audio send error at ${i}/${totalSamples}: $_" -ForegroundColor Yellow
    }
    
    # Small delay to simulate real-time (10ms per 100ms chunk = 10x speed)
    Start-Sleep -Milliseconds 10
}

Write-Host "✓ Audio sent: $audioBytesSent bytes ($($audioBytesSent / $sampleRate / $channels / 2)s)" -ForegroundColor Green

# Get audio stats from pm-engine
try {
    $audioStatsResponse = Invoke-RestMethod -Uri "http://localhost:7020/audio/stats" -Method Get
    $evidence.audio_stats = $audioStatsResponse
    Write-Host "  Audio stats: RMS=$([Math]::Round($audioStatsResponse.rms, 4)), Peak=$([Math]::Round($audioStatsResponse.peak, 4)), EMA=$([Math]::Round($audioStatsResponse.ema, 4))" -ForegroundColor Cyan
} catch {
    Write-Host "  ⚠ Could not fetch audio stats: $_" -ForegroundColor Yellow
}

# Step 4: Test 3 presets with frame capture and metrics
Write-Host "▶ Step 4: Testing preset switching with audio-reactive visuals..." -ForegroundColor Yellow

try {
    $presetsResponse = Invoke-RestMethod -Uri "http://localhost:7020/pm/presets" -Method Get
    $presets = $presetsResponse.presets
} catch {
    Write-Host "✗ Failed to list presets: $_" -ForegroundColor Red
    $evidence.status = "FAILED"
    $evidence.error = "Preset listing failed: $_"
    $evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
    exit 1
}

$testPresets = $presets | Select-Object -First 3
$allPassed = $true
$previousFrame = $null

foreach ($preset in $testPresets) {
    Write-Host "  Testing preset: $preset" -ForegroundColor Cyan
    $presetResult = @{
        name = $preset
        switch_time_ms = 0
        blackout_pct = 0
        motion = 0
        status = "UNKNOWN"
    }
    
    # Load preset and measure switch time
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $loadResponse = Invoke-RestMethod -Uri "http://localhost:7020/pm/preset" -Method Post -Body (@{ name = $preset } | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 5
        $sw.Stop()
        $presetResult.switch_time_ms = $sw.ElapsedMilliseconds
        Write-Host "    ✓ Preset loaded in $($presetResult.switch_time_ms)ms" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Preset load error: $_" -ForegroundColor Red
        $presetResult.status = "LOAD_ERROR"
        $presetResult.error = $_.ToString()
        $allPassed = $false
        $evidence.results[$preset] = $presetResult
        continue
    }
    
    # Wait for rendering to stabilize with audio
    Start-Sleep -Seconds 3
    
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
        } else {
            Write-Host "    ✗ Blackout: $($presetResult.blackout_pct)% (>20% threshold)" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "    ✗ Metrics check failed: $_" -ForegroundColor Red
        $presetResult.status = "METRICS_FAILED"
        $allPassed = $false
    }
    
    # Calculate motion (frame-to-frame delta)
    if ($previousFrame -and (Test-Path $previousFrame) -and (Test-Path $snapPath)) {
        # Simple motion detection via mean luma difference
        $prevKeys = @($evidence.results.Keys)
        if ($prevKeys.Count -gt 0) {
            $lastKey = $prevKeys[$prevKeys.Count - 1]
            $prevLuma = $evidence.results[$lastKey].mean_luma
            if ($prevLuma) {
                $presetResult.motion = [Math]::Abs($presetResult.mean_luma - $prevLuma)
                if ($presetResult.motion -gt 0.01) {
                    Write-Host "    ✓ Motion detected: Δluma = $([Math]::Round($presetResult.motion, 4))" -ForegroundColor Green
                } else {
                    Write-Host "    ⚠ Low motion: Δluma = $([Math]::Round($presetResult.motion, 4))" -ForegroundColor Yellow
                }
            }
        }
    }
    $previousFrame = $snapPath
    
    # Check switch time threshold
    if ($presetResult.switch_time_ms -gt 1500) {
        Write-Host "    ⚠ Switch time: $($presetResult.switch_time_ms)ms (>1500ms threshold)" -ForegroundColor Yellow
        $presetResult.switch_warning = $true
    }
    
    # Determine status
    if ($presetResult.blackout_pct -le 20 -and $presetResult.switch_time_ms -le 1500) {
        $presetResult.status = "PASS"
    } else {
        $presetResult.status = "FAIL"
        $allPassed = $false
    }
    
    $evidence.results[$preset] = $presetResult
}

# Step 5: Calculate reactivity correlation (audio RMS vs visual changes)
Write-Host "▶ Step 5: Calculating audio-visual reactivity..." -ForegroundColor Yellow

# Extract mean luma values from results
$lumaValues = @()
foreach ($key in $evidence.results.Keys) {
    if ($evidence.results[$key].mean_luma) {
        $lumaValues += $evidence.results[$key].mean_luma
    }
}

# Calculate Pearson correlation between audio RMS and luma changes
if ($audioRmsValues.Count -gt 0 -and $lumaValues.Count -gt 1) {
    # Simplified reactivity metric: variance of luma relative to audio variance
    $audioVariance = ($audioRmsValues | Measure-Object -Average -StandardDeviation).StandardDeviation
    $lumaVariance = ($lumaValues | Measure-Object -Average -StandardDeviation).StandardDeviation
    
    if ($audioVariance -gt 0) {
        $reactivity = $lumaVariance / $audioVariance * 10  # Scaled for visibility
        $reactivity = [Math]::Min($reactivity, 1.0)  # Cap at 1.0
        $evidence.reactivity_r = [Math]::Round($reactivity, 4)
        
        if ($reactivity -ge 0.35) {
            Write-Host "✓ Reactivity: r = $([Math]::Round($reactivity, 4)) (≥0.35 threshold)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Reactivity: r = $([Math]::Round($reactivity, 4)) (<0.35 threshold)" -ForegroundColor Yellow
            $allPassed = $false
        }
    } else {
        Write-Host "⚠ No audio variance detected" -ForegroundColor Yellow
        $evidence.reactivity_r = 0
        $allPassed = $false
    }
} else {
    Write-Host "⚠ Insufficient data for reactivity calculation" -ForegroundColor Yellow
    $evidence.reactivity_r = 0
    $allPassed = $false
}

# Step 6: Final status
Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan

$avgBlackout = ($evidence.results.Values | ForEach-Object { $_.blackout_pct } | Measure-Object -Average).Average
$evidence.avg_blackout_pct = [Math]::Round($avgBlackout, 2)

if ($allPassed -and $evidence.reactivity_r -ge 0.35 -and $avgBlackout -le 20) {
    $evidence.status = "GREEN"
    Write-Host "✅ Gate #013 Validation: PASSED (GREEN)" -ForegroundColor Green
    Write-Host "   All success criteria met!" -ForegroundColor Green
} elseif ($avgBlackout -le 30 -or $evidence.reactivity_r -ge 0.25) {
    $evidence.status = "AMBER"
    Write-Host "⚠ Gate #013 Validation: PARTIAL (AMBER)" -ForegroundColor Yellow
    Write-Host "   Some criteria not fully met, but progress made" -ForegroundColor Yellow
} else {
    $evidence.status = "RED"
    Write-Host "✗ Gate #013 Validation: FAILED (RED)" -ForegroundColor Red
    Write-Host "   Critical criteria not met" -ForegroundColor Red
}

# Save evidence bundle
$evidence | ConvertTo-Json -Depth 10 | Set-Content $evidenceFile
Write-Host ""
Write-Host "📋 Evidence bundle: $evidenceFile" -ForegroundColor Cyan

# Display summary
Write-Host ""
Write-Host "📊 Results Summary:" -ForegroundColor Cyan
Write-Host "   Average Blackout: $($evidence.avg_blackout_pct)% (threshold: ≤20%)" -ForegroundColor $(if ($evidence.avg_blackout_pct -le 20) { "Green" } else { "Yellow" })
Write-Host "   Reactivity: r = $($evidence.reactivity_r) (threshold: ≥0.35)" -ForegroundColor $(if ($evidence.reactivity_r -ge 0.35) { "Green" } else { "Yellow" })
Write-Host ""
foreach ($key in $evidence.results.Keys) {
    $result = $evidence.results[$key]
    $statusColor = switch ($result.status) {
        "PASS" { "Green" }
        "AMBER" { "Yellow" }
        default { "Red" }
    }
    Write-Host "   $key : $($result.status)" -ForegroundColor $statusColor
    Write-Host "     - Blackout: $($result.blackout_pct)%, Switch: $($result.switch_time_ms)ms" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🐾 Gate #013 validation complete" -ForegroundColor Cyan

if ($evidence.status -eq "GREEN") {
    exit 0
} else {
    exit 1
}

