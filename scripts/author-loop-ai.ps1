#!/usr/bin/env pwsh
# Gate #015 Job-2: AI-Assisted Authoring Loop
# ECRR: BossCat - Bedrock co-author integration
# Authority: BossCat OEM | Executor: Cursor{Implementer}

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$PresetFile,
    
    [int]$Iterations = 2,
    [string]$Brief = "Optimize for visible motion without audio, reduce blackout",
    [string]$OutputDir = "artifacts/pm/coauthor",
    [string]$PmEngineUrl = "http://localhost:7020"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$evidenceFile = "$OutputDir/coauthor-$timestamp.jsonl"

Write-Host "🤖 Gate #015 - AI Co-Author Loop" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Ensure output directory exists
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

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

$presetName = Split-Path $PresetFile -Leaf
$presetContent = Get-Content $PresetFile -Raw
$workingPreset = $presetContent  # Track modifications

Write-Host "┌─ Preset: $presetName" -ForegroundColor Cyan
Write-Host "│  Brief: $Brief" -ForegroundColor Gray
Write-Host "│  Iterations: $Iterations" -ForegroundColor Gray
Write-Host ""

$previousMetrics = $null

for ($iter = 1; $iter -le $Iterations; $iter++) {
    Write-Host "│  ├─ Iteration $iter/$Iterations" -ForegroundColor Cyan
    
    $evidence = [ordered]@{
        ts = (Get-Date -Format "o")
        iteration = $iter
        preset = $presetName
        brief = $Brief
        ai_suggestion = ""
        blackout_pct = 0
        mean_luma = 0
        decision = "UNKNOWN"
        snapshot = ""
    }
    
    # Step 1: Get AI suggestion and apply to working preset (if not first iteration)
    if ($iter -gt 1 -and $previousMetrics) {
        Write-Host "│  │  ▶ Requesting AI suggestion based on metrics..." -ForegroundColor Gray
        try {
            # Create temp metrics file for AI context
            $tempMetrics = "$env:TEMP\preset-metrics-$iter.json"
            $previousMetrics | ConvertTo-Json -Depth 5 | Set-Content $tempMetrics
            
            # Save current working preset to temp file
            $tempPreset = "$env:TEMP\working-preset-$iter.milk"
            $workingPreset | Set-Content $tempPreset
            
            $suggestion = npx tsx scripts/bedrock-coauthor.ts $tempPreset $iter $tempMetrics 2>&1 | Out-String
            $evidence.ai_suggestion = $suggestion.Trim()
            
            Write-Host "│  │  ✓ AI suggestion received" -ForegroundColor Green
            
            # Parse and apply suggestion if it's JSON format
            try {
                $suggestionJson = $suggestion | ConvertFrom-Json -ErrorAction Stop
                if ($suggestionJson.parameter -and $suggestionJson.change) {
                    Write-Host "│  │    Suggestion: $($suggestionJson.parameter) → $($suggestionJson.change)" -ForegroundColor Cyan
                    Write-Host "│  │    Reasoning: $($suggestionJson.reasoning)" -ForegroundColor Gray
                    
                    # ACTUALLY APPLY: Simple parameter replacement in working preset
                    # Extract the target value from "from X to Y" format
                    if ($suggestionJson.change -match 'to\s+([\d.]+)') {
                        $newValue = $matches[1]
                        $param = $suggestionJson.parameter
                        
                        # Apply change to working preset content
                        $workingPreset = $workingPreset -replace "(?m)^$param\s*=\s*[\d.]+", "$param=$newValue"
                        $workingPreset | Set-Content $tempPreset
                        
                        Write-Host "│  │  ✓ Applied: $param = $newValue" -ForegroundColor Green
                        $evidence.ai_applied = $true
                        $evidence.parameter_modified = $param
                        $evidence.new_value = $newValue
                    } else {
                        Write-Host "│  │  ⚠ Could not parse change value" -ForegroundColor Yellow
                        $evidence.ai_applied = $false
                    }
                } else {
                    Write-Host "│  │    Raw: $($suggestion.Substring(0, [Math]::Min(100, $suggestion.Length)))..." -ForegroundColor Cyan
                    $evidence.ai_applied = $false
                }
            } catch {
                Write-Host "│  │    Non-JSON response: $($suggestion.Substring(0, [Math]::Min(100, $suggestion.Length)))..." -ForegroundColor Yellow
                $evidence.ai_applied = $false
            }
            
            # Use modified preset for this iteration
            $PresetFile = $tempPreset
            
            Remove-Item $tempMetrics -ErrorAction SilentlyContinue
        } catch {
            Write-Host "│  │  ⚠ AI suggestion failed, using baseline: $_" -ForegroundColor Yellow
            $evidence.ai_suggestion = "FAILED: $_"
            $evidence.ai_applied = $false
        }
    } else {
        $evidence.ai_suggestion = "BASELINE (first iteration)"
        $evidence.ai_applied = $false
    }
    
    # Step 2: Load preset (original or AI-modified version)
    try {
        Write-Host "│  │  ▶ Loading preset..." -ForegroundColor Gray
        
        # For iterations with AI changes, use the temp modified file
        # For first iteration, use original
        $presetToLoad = if ($iter -gt 1 -and $evidence.ai_applied) {
            # Save modified preset to presets directory with unique name
            $modifiedName = "ai_modified_iter$($iter)_$(Split-Path $PresetFile -Leaf)"
            $modifiedPath = "presets-projectm/$modifiedName"
            $workingPreset | Set-Content $modifiedPath
            $modifiedName
        } else {
            $presetName
        }
        
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $loadResult = Invoke-RestMethod -Uri "$PmEngineUrl/pm/preset" `
            -Method Post `
            -Body (@{ name = $presetToLoad } | ConvertTo-Json) `
            -ContentType "application/json" `
            -TimeoutSec 10
        $sw.Stop()
        
        if ($loadResult.ok -ne $true) {
            throw "Preset load failed: $($loadResult.error)"
        }
        
        $evidence.preset_loaded = $presetToLoad
        Write-Host "│  │  ✓ Loaded in $($sw.ElapsedMilliseconds)ms" -ForegroundColor Green
        if ($evidence.ai_applied) {
            Write-Host "│  │    (AI-modified version)" -ForegroundColor Cyan
        }
    } catch {
        Write-Host "│  │  ✗ Load failed: $_" -ForegroundColor Red
        $evidence.decision = "ERROR"
        $evidence | ConvertTo-Json -Compress | Add-Content $evidenceFile
        continue
    }
    
    # Step 3: Wait for stabilization
    Write-Host "│  │  ⏳ Stabilizing (3s)..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
    
    # Step 4: Capture frame
    try {
        $snapFile = "$OutputDir/snap_iter$($iter)_$timestamp.jpg"
        Invoke-WebRequest -Uri "$PmEngineUrl/snap.jpg" `
            -OutFile $snapFile `
            -TimeoutSec 10
        
        Write-Host "│  │  ✓ Captured: $(Split-Path $snapFile -Leaf)" -ForegroundColor Green
        $evidence.snapshot = (Split-Path $snapFile -Leaf)
    } catch {
        Write-Host "│  │  ✗ Capture failed: $_" -ForegroundColor Red
        $evidence.decision = "ERROR"
        $evidence | ConvertTo-Json -Compress | Add-Content $evidenceFile
        continue
    }
    
    # Step 5: Collect metrics
    try {
        $metrics = Invoke-RestMethod -Uri "$PmEngineUrl/pm/metrics" -Method Get -TimeoutSec 5
        
        $evidence.blackout_pct = [Math]::Round(100 - $metrics.non_black_pct, 2)
        $evidence.mean_luma = [Math]::Round($metrics.mean_luma, 4)
        
        Write-Host "│  │  ✓ Blackout: $($evidence.blackout_pct)%, Luma: $($evidence.mean_luma)" -ForegroundColor Cyan
        
        # Decision
        if ($evidence.blackout_pct -le 40) {
            $evidence.decision = "PASS"
            Write-Host "│  │  ✓ Decision: PASS" -ForegroundColor Green
        } else {
            $evidence.decision = "WARN"
            Write-Host "│  │  ⚠ Decision: WARN" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "│  │  ✗ Metrics failed: $_" -ForegroundColor Red
        $evidence.decision = "ERROR"
    }
    
    # Store metrics for next iteration
    $previousMetrics = @{
        blackout_pct = $evidence.blackout_pct
        mean_luma = $evidence.mean_luma
        preset = $presetName
    }
    
    # Log evidence
    $evidence | ConvertTo-Json -Compress | Add-Content $evidenceFile
    Write-Host "│  └─" -ForegroundColor Gray
}

Write-Host "└─" -ForegroundColor Cyan
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ AI Co-Author Loop Complete" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Evidence: $evidenceFile" -ForegroundColor Cyan
Write-Host "📸 Snapshots: $OutputDir/snap_*.jpg" -ForegroundColor Cyan
Write-Host ""
Write-Host "🐾 Gate #015 Job-2 execution complete" -ForegroundColor Cyan

exit 0

