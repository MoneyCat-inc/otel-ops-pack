# Author-Run - Full Authoring Cycle with ECRR
# ECRR: BossCat Gate #010 - LLM-driven preset authoring
# Authority: BossCat OEM | Executor: Cursor{Implementer}

param(
    [Parameter(Mandatory=$false)]
    [string]$StyleBrief = "Radial kaleidoscope with strong bass zoom and colorful waves",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxCycles = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$EvalDurationSeconds = 15,
    
    [Parameter(Mandatory=$false)]
    [string]$VizEngineUrl = "http://localhost:7001",
    
    [Parameter(Mandatory=$false)]
    [string]$ScorebotUrl = "http://localhost:7010"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Author-Run: LLM-Driven Authoring Loop" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Style Brief: $StyleBrief" -ForegroundColor White
Write-Host "Max Cycles:  $MaxCycles" -ForegroundColor Gray
Write-Host "Eval Time:   ${EvalDurationSeconds}s per cycle" -ForegroundColor Gray
Write-Host ""

# ECRR Phase: EXAMINE
Write-Host "[EXAMINE] Capturing pre-authoring state..." -ForegroundColor Yellow

$sessionId = Get-Date -Format "yyyyMMdd-HHmmss"
$sessionDir = "artifacts/viz-engine/session-$sessionId"
New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null

# Check if audio feeder is running
try {
    $audioStats = Invoke-RestMethod -Uri "$VizEngineUrl/audio/stats" -Method Get -TimeoutSec 2
    $audioActive = $audioStats.samples -gt 0
} catch {
    $audioActive = $false
}

if (-not $audioActive) {
    Write-Host "[WARN] No audio input detected. Starting audio feeder..." -ForegroundColor Yellow
    Start-Job -ScriptBlock {
        pwsh -File $using:PSScriptRoot\audio-feeder.ps1 -DurationSeconds ($using:MaxCycles * $using:EvalDurationSeconds + 60)
    } | Out-Null
    Start-Sleep -Seconds 3
}

# Authoring cycles
$cycles = @()
$bestScore = 0
$bestPreset = $null

for ($cycle = 1; $cycle -le $MaxCycles; $cycle++) {
    Write-Host ""
    Write-Host "=== CYCLE $cycle/$MaxCycles ===" -ForegroundColor Cyan
    Write-Host ""
    
    # ECRR Phase: CLEAN (generate/load preset)
    Write-Host "[CLEAN] Generating preset for cycle $cycle..." -ForegroundColor Yellow
    
    # For now, use starter_bass.milk as template
    # TODO: Integrate with LLM/Bedrock MCP for proposal
    $presetName = "author-cycle-$cycle"
    $presetFile = "$sessionDir/$presetName.milk"
    
    if ($cycle -eq 1) {
        # Use starter template
        Copy-Item "viz-engine-butterchurn/presets/starter_bass.milk" $presetFile
    } else {
        # TODO: LLM revise based on previous metrics
        # For now, just modify decay slightly
        $prevContent = Get-Content $cycles[$cycle - 2].file -Raw
        $newDecay = 0.96 - ($cycle * 0.01)
        $newContent = $prevContent -replace "fDecay=[0-9.]+","fDecay=$newDecay"
        $newContent | Set-Content $presetFile -Encoding UTF8
    }
    
    Write-Host "  [OK] Preset generated: $presetFile" -ForegroundColor Green
    
    # Evaluate preset
    Write-Host "[REPORT] Evaluating preset..." -ForegroundColor Yellow
    
    $evalResult = pwsh -File "$PSScriptRoot\author-eval.ps1" `
        -PresetFile $presetFile `
        -DurationSeconds $EvalDurationSeconds `
        -Blend 1.5 `
        -VizEngineUrl $VizEngineUrl `
        -ScorebotUrl $ScorebotUrl
    
    $evalExitCode = $LASTEXITCODE
    
    # Load evaluation artifact
    $latestArtifact = Get-ChildItem "artifacts/viz-engine/eval-$presetName-*.json" | 
        Sort-Object LastWriteTime -Descending | 
        Select-Object -First 1
    
    if ($latestArtifact) {
        $evalData = Get-Content $latestArtifact.FullName | ConvertFrom-Json
        
        $cycles += @{
            cycle = $cycle
            preset = $presetName
            file = $presetFile
            verdict = $evalData.verdict
            score = $evalData.score
            metrics = $evalData.metrics
            artifact = $latestArtifact.FullName
        }
        
        Write-Host "  Verdict: $($evalData.verdict) | Score: $($evalData.score.ToString('F2'))" -ForegroundColor $(if ($evalData.ok) { 'Green' } else { 'Yellow' })
        
        # Check if best so far
        if ($evalData.score -gt $bestScore) {
            $bestScore = $evalData.score
            $bestPreset = $presetName
            Write-Host "  [NEW BEST] Score improved to $($bestScore.ToString('F2'))" -ForegroundColor Green
        }
        
        # ECRR Phase: ROLE (check for PASS and early exit)
        if ($evalData.ok) {
            Write-Host ""
            Write-Host "[GATE PASS] Preset meets Gate #010 thresholds!" -ForegroundColor Green
            break
        }
    }
}

# Final summary
Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Authoring Session Complete" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cycles Run:    $($cycles.Count)" -ForegroundColor White
Write-Host "Best Score:    $($bestScore.ToString('F2'))" -ForegroundColor White
Write-Host "Best Preset:   $bestPreset" -ForegroundColor White
Write-Host "Session Dir:   $sessionDir" -ForegroundColor Gray
Write-Host ""

# ECRR artifact
$sessionArtifact = @{
    session_id = $sessionId
    style_brief = $StyleBrief
    max_cycles = $MaxCycles
    cycles_run = $cycles.Count
    best_score = $bestScore
    best_preset = $bestPreset
    cycles = $cycles
    timestamp = Get-Date -Format "o"
} | ConvertTo-Json -Depth 15

$sessionArtifact | Set-Content "$sessionDir/session-summary.json" -Encoding UTF8

# BOSSCAT_LOG entry
$logEntry = "- $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') - [AUTHORING] Session ${sessionId}: $($cycles.Count) cycles, best score $($bestScore.ToString('F2')) ($bestPreset), style='$StyleBrief'. - Cursor{Implementer}"

Write-Host "BOSSCAT_LOG entry:" -ForegroundColor Gray
Write-Host $logEntry -ForegroundColor Gray
Write-Host ""
Write-Host "[COMPLETE] Session artifacts in $sessionDir" -ForegroundColor Green

