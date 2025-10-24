#!/usr/bin/env pwsh
# Gate #014 - Authoring + Feedback Loop
# ECRR: BossCat Mission - Preset authoring with visual feedback
# Authority: BossCat OEM | Executor: Cursor{Implementer}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Presets,  # Glob pattern or single file
    
    [int]$Iterations = 1,
    [int]$StabilizationSeconds = 3,
    [double]$BlackoutThreshold = 30.0,
    [double]$MinLuma = 0.15,
    [string]$OutputDir = "artifacts/pm/author",
    [string]$PmEngineUrl = "http://localhost:7020"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$evidenceFile = "$OutputDir/author-loop-$timestamp.jsonl"

Write-Host "🎨 Gate #014 - Preset Authoring Loop" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Resolve preset files
$presetFiles = @()
if (Test-Path $Presets -PathType Leaf) {
    # Single file provided
    $presetFiles = @($Presets)
} elseif ($Presets -match '[\*\?]') {
    # Glob pattern provided
    $basePath = Split-Path $Presets -Parent
    if (-not $basePath) { $basePath = "." }
    $pattern = Split-Path $Presets -Leaf
    $presetFiles = @(Get-ChildItem -Path $basePath -Filter $pattern -Recurse -File | Select-Object -ExpandProperty FullName)
} else {
    # Directory provided
    $presetFiles = @(Get-ChildItem -Path $Presets -Filter "*.milk" -Recurse -File | Select-Object -ExpandProperty FullName)
}

if ($presetFiles.Count -eq 0) {
    Write-Host "✗ No presets found matching: $Presets" -ForegroundColor Red
    exit 1
}

Write-Host "▶ Found $($presetFiles.Count) preset(s)" -ForegroundColor Green
Write-Host "▶ Iterations per preset: $Iterations" -ForegroundColor Green
Write-Host "▶ Output: $OutputDir" -ForegroundColor Green
Write-Host ""

# Verify pm-engine health
Write-Host "▶ Checking pm-engine health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$PmEngineUrl/health" -Method Get -TimeoutSec 5
    if ($health.ok -ne $true) {
        Write-Host "✗ pm-engine not healthy" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ pm-engine healthy" -ForegroundColor Green
} catch {
    Write-Host "✗ pm-engine not responding: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Authoring loop
$totalTests = $presetFiles.Count * $Iterations
$currentTest = 0
$previousMetrics = $null

foreach ($presetPath in $presetFiles) {
    $presetName = Split-Path $presetPath -Leaf
    $presetBaseName = [System.IO.Path]::GetFileNameWithoutExtension($presetName)
    
    Write-Host "┌─ Preset: $presetName" -ForegroundColor Cyan
    
    for ($iter = 1; $iter -le $Iterations; $iter++) {
        $currentTest++
        Write-Host "│  ├─ Iteration $iter/$Iterations" -ForegroundColor Gray
        
        $evidence = [ordered]@{
            ts = (Get-Date -Format "o")
            preset = $presetName
            iteration = $iter
            blackout_pct = 0
            mean_luma = 0
            motion = 0
            decision = "UNKNOWN"
            snapshot = ""
            error = ""
        }
        
        # Step 1: Load preset
        try {
            Write-Host "│  │  ▶ Loading preset..." -ForegroundColor Gray
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $loadResult = Invoke-RestMethod -Uri "$PmEngineUrl/pm/preset" `
                -Method Post `
                -Body (@{ name = $presetName } | ConvertTo-Json) `
                -ContentType "application/json" `
                -TimeoutSec 10
            $sw.Stop()
            
            if ($loadResult.ok -ne $true) {
                throw "Preset load failed: $($loadResult.error)"
            }
            
            Write-Host "│  │  ✓ Loaded in $($sw.ElapsedMilliseconds)ms" -ForegroundColor Green
        } catch {
            Write-Host "│  │  ✗ Load failed: $_" -ForegroundColor Red
            $evidence.decision = "ERROR"
            $evidence.error = $_.ToString()
            $evidence | ConvertTo-Json -Compress | Add-Content $evidenceFile
            continue
        }
        
        # Step 2: Wait for stabilization
        Write-Host "│  │  ⏳ Stabilizing ($StabilizationSeconds s)..." -ForegroundColor Gray
        Start-Sleep -Seconds $StabilizationSeconds
        
        # Step 3: Capture frame
        try {
            $snapFile = "$OutputDir/$presetBaseName`_iter$($iter)_$timestamp.jpg"
            Write-Host "│  │  ▶ Capturing frame..." -ForegroundColor Gray
            Invoke-WebRequest -Uri "$PmEngineUrl/snap.jpg" `
                -OutFile $snapFile `
                -TimeoutSec 10
            
            if ((Get-Item $snapFile).Length -gt 0) {
                Write-Host "│  │  ✓ Captured: $(Split-Path $snapFile -Leaf)" -ForegroundColor Green
                $evidence.snapshot = (Split-Path $snapFile -Leaf)
            } else {
                throw "Empty snapshot file"
            }
        } catch {
            Write-Host "│  │  ✗ Capture failed: $_" -ForegroundColor Red
            $evidence.decision = "ERROR"
            $evidence.error = "Capture failed: $_"
            $evidence | ConvertTo-Json -Compress | Add-Content $evidenceFile
            continue
        }
        
        # Step 4: Collect metrics
        try {
            Write-Host "│  │  ▶ Collecting metrics..." -ForegroundColor Gray
            $metrics = Invoke-RestMethod -Uri "$PmEngineUrl/pm/metrics" `
                -Method Get `
                -TimeoutSec 5
            
            $evidence.blackout_pct = [Math]::Round(100 - $metrics.non_black_pct, 2)
            $evidence.mean_luma = [Math]::Round($metrics.mean_luma, 4)
            
            Write-Host "│  │  ✓ Blackout: $($evidence.blackout_pct)%, Luma: $($evidence.mean_luma)" -ForegroundColor Cyan
        } catch {
            Write-Host "│  │  ✗ Metrics failed: $_" -ForegroundColor Red
            $evidence.decision = "ERROR"
            $evidence.error = "Metrics failed: $_"
            $evidence | ConvertTo-Json -Compress | Add-Content $evidenceFile
            continue
        }
        
        # Step 5: Calculate motion (if not first iteration for this preset)
        if ($previousMetrics -and $previousMetrics.preset -eq $presetName) {
            $evidence.motion = [Math]::Round([Math]::Abs($evidence.mean_luma - $previousMetrics.mean_luma), 4)
            Write-Host "│  │  ✓ Motion: Δluma = $($evidence.motion)" -ForegroundColor Cyan
        }
        
        # Step 6: Score decision
        if ($evidence.blackout_pct -gt $BlackoutThreshold) {
            $evidence.decision = "FAIL"
            Write-Host "│  │  ✗ Decision: FAIL (blackout >$BlackoutThreshold%)" -ForegroundColor Red
        } elseif ($evidence.mean_luma -lt $MinLuma) {
            $evidence.decision = "WARN"
            Write-Host "│  │  ⚠ Decision: WARN (luma <$MinLuma)" -ForegroundColor Yellow
        } else {
            $evidence.decision = "PASS"
            Write-Host "│  │  ✓ Decision: PASS" -ForegroundColor Green
        }
        
        # Step 7: Log evidence
        $evidence | ConvertTo-Json -Compress | Add-Content $evidenceFile
        
        # Store for motion calculation
        $previousMetrics = @{
            preset = $presetName
            mean_luma = $evidence.mean_luma
        }
        
        Write-Host "│  └─ Complete ($currentTest/$totalTests)" -ForegroundColor Gray
    }
    
    Write-Host "└─" -ForegroundColor Cyan
    Write-Host ""
}

# Summary
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ Authoring Loop Complete" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Presets tested: $($presetFiles.Count)" -ForegroundColor Gray
Write-Host "   Total iterations: $totalTests" -ForegroundColor Gray
Write-Host "   Evidence file: $evidenceFile" -ForegroundColor Gray
Write-Host "   Snapshots: $OutputDir/*.jpg" -ForegroundColor Gray

# Parse and display results
if (Test-Path $evidenceFile) {
    $results = @(Get-Content $evidenceFile | ForEach-Object { $_ | ConvertFrom-Json })
    $passCount = @($results | Where-Object { $_.decision -eq "PASS" }).Count
    $warnCount = @($results | Where-Object { $_.decision -eq "WARN" }).Count
    $failCount = @($results | Where-Object { $_.decision -eq "FAIL" }).Count
    $errorCount = @($results | Where-Object { $_.decision -eq "ERROR" }).Count
    
    Write-Host ""
    Write-Host "📈 Results:" -ForegroundColor Cyan
    Write-Host "   PASS: $passCount" -ForegroundColor Green
    if ($warnCount -gt 0) {
        Write-Host "   WARN: $warnCount" -ForegroundColor Yellow
    }
    if ($failCount -gt 0) {
        Write-Host "   FAIL: $failCount" -ForegroundColor Red
    }
    if ($errorCount -gt 0) {
        Write-Host "   ERROR: $errorCount" -ForegroundColor Red
    }
    
    # Display top results
    Write-Host ""
    Write-Host "🎯 Top Results (by luma):" -ForegroundColor Cyan
    $results | Sort-Object -Property mean_luma -Descending | Select-Object -First 3 | ForEach-Object {
        $statusColor = switch ($_.decision) {
            "PASS" { "Green" }
            "WARN" { "Yellow" }
            default { "Red" }
        }
        Write-Host "   $($_.preset) : $($_.decision) (luma=$($_.mean_luma), blackout=$($_.blackout_pct)%)" -ForegroundColor $statusColor
    }
}

Write-Host ""
Write-Host "🐾 Gate #014 authoring loop execution complete" -ForegroundColor Cyan

exit 0

