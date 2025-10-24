#!/usr/bin/env pwsh
# Gate #016 - Score Curated Presets
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# ECRR: Collect metrics for curated preset library

param(
    [string]$PresetDir = "presets-projectm/curated",
    [string]$PmEngineUrl = "http://localhost:7015",
    [string]$OutputDir = "artifacts/pm/curated",
    [int]$WaitSeconds = 5
)

$ErrorActionPreference = "Stop"

# Create output directory
New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$jsonlPath = "$OutputDir/score-$timestamp.jsonl"
$results = @()

Write-Host "🎯 Gate #016: Scoring Curated Presets" -ForegroundColor Cyan
Write-Host "Directory: $PresetDir" -ForegroundColor Gray
Write-Host "Output: $jsonlPath" -ForegroundColor Gray
Write-Host ""

# Get all preset files
$presets = Get-ChildItem "$PresetDir" -Filter *.milk | Sort-Object Name

if ($presets.Count -eq 0) {
    Write-Host "❌ No presets found in $PresetDir" -ForegroundColor Red
    exit 1
}

Write-Host "📊 Found $($presets.Count) presets to score" -ForegroundColor Green
Write-Host ""

foreach ($preset in $presets) {
    $presetName = $preset.BaseName
    Write-Host "🎨 Testing: $presetName" -ForegroundColor Cyan
    
    try {
        # Load preset
        $loadStart = Get-Date
        $loadResponse = Invoke-RestMethod -Uri "$PmEngineUrl/pm/preset" -Method Post `
            -ContentType "application/json" `
            -Body (@{ name = $preset.Name } | ConvertTo-Json) `
            -TimeoutSec 5
        $loadEnd = Get-Date
        $loadTimeMs = [int](($loadEnd - $loadStart).TotalMilliseconds)
        
        Write-Host "  ⏱️  Load time: $loadTimeMs ms" -ForegroundColor Gray
        
        # Wait for preset to render
        Start-Sleep -Seconds $WaitSeconds
        
        # Capture frame
        $snapPath = "$OutputDir/$presetName-snap.jpg"
        Invoke-WebRequest -Uri "$PmEngineUrl/snap.jpg" -OutFile $snapPath -TimeoutSec 5
        
        # Get metrics
        $metrics = Invoke-RestMethod -Uri "$PmEngineUrl/pm/metrics" -TimeoutSec 5
        
        # pm-engine returns: mean_luma (0-1), non_black_pct (0-100)
        # Convert non_black_pct to blackout_pct
        $meanLuma = if ($metrics.mean_luma) { [math]::Round($metrics.mean_luma, 4) } else { 0 }
        $nonBlackPct = if ($metrics.non_black_pct) { $metrics.non_black_pct } else { 0 }
        $blackoutPct = [math]::Round((100 - $nonBlackPct), 2)
        $hasMotion = ($meanLuma -gt 0.15)  # Proxy: if visible content exists, assume motion (time-based presets)
        
        # Create record
        $record = [ordered]@{
            timestamp = (Get-Date -Format "o")
            preset_name = $presetName
            preset_file = $preset.Name
            load_time_ms = $loadTimeMs
            blackout_pct = $blackoutPct
            mean_luma = $meanLuma
            non_black_pct = $nonBlackPct
            has_visible_content = $hasMotion
            snapshot = $snapPath
            status = "OK"
        }
        
        # Determine pass/warn/fail (Gate #016 criteria: blackout ≤50%, visible content)
        if ($blackoutPct -le 50 -and $hasMotion) {
            $record.verdict = "PASS"
            Write-Host "  ✅ PASS: Blackout=$blackoutPct%, Luma=$meanLuma, Visible=Yes" -ForegroundColor Green
        }
        elseif ($blackoutPct -le 70 -and $meanLuma -gt 0.10) {
            $record.verdict = "WARN"
            Write-Host "  ⚠️  WARN: Blackout=$blackoutPct%, Luma=$meanLuma" -ForegroundColor Yellow
        }
        else {
            $record.verdict = "FAIL"
            Write-Host "  ❌ FAIL: Blackout=$blackoutPct%, Luma=$meanLuma" -ForegroundColor Red
        }
        
        # Append to JSONL
        $record | ConvertTo-Json -Compress | Out-File -FilePath $jsonlPath -Append -Encoding UTF8
        $results += $record
        
    }
    catch {
        Write-Host "  ❌ Error: $_" -ForegroundColor Red
        $errorRecord = [ordered]@{
            timestamp = (Get-Date -Format "o")
            preset_name = $presetName
            preset_file = $preset.Name
            status = "ERROR"
            error = $_.Exception.Message
            verdict = "FAIL"
        }
        $errorRecord | ConvertTo-Json -Compress | Out-File -FilePath $jsonlPath -Append -Encoding UTF8
        $results += $errorRecord
    }
    
    Write-Host ""
}

# Summary
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📈 SUMMARY" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$passCount = ($results | Where-Object { $_.verdict -eq "PASS" }).Count
$warnCount = ($results | Where-Object { $_.verdict -eq "WARN" }).Count
$failCount = ($results | Where-Object { $_.verdict -eq "FAIL" }).Count

Write-Host "Total presets: $($results.Count)" -ForegroundColor White
Write-Host "PASS: $passCount" -ForegroundColor Green
Write-Host "WARN: $warnCount" -ForegroundColor Yellow
Write-Host "FAIL: $failCount" -ForegroundColor Red
Write-Host ""
Write-Host "Evidence: $jsonlPath" -ForegroundColor Cyan

# Exit with appropriate code
if ($failCount -eq 0 -and $passCount -gt 0) {
    Write-Host "✅ Gate #016: GREEN" -ForegroundColor Green
    exit 0
}
elseif ($passCount -ge ($results.Count / 2)) {
    Write-Host "⚠️  Gate #016: AMBER" -ForegroundColor Yellow
    exit 10
}
else {
    Write-Host "❌ Gate #016: RED" -ForegroundColor Red
    exit 20
}

