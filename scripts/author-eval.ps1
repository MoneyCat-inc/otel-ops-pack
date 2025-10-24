# Author-Eval - Preset Evaluation Orchestration
# ECRR: BossCat Gate #010 - Authoring loop
# Authority: BossCat OEM | Executor: Cursor{Implementer}

param(
    [Parameter(Mandatory=$true)]
    [string]$PresetFile,
    
    [Parameter(Mandatory=$false)]
    [int]$DurationSeconds = 15,
    
    [Parameter(Mandatory=$false)]
    [double]$Blend = 2.0,
    
    [Parameter(Mandatory=$false)]
    [string]$VizEngineUrl = "http://localhost:7001",
    
    [Parameter(Mandatory=$false)]
    [string]$ScorebotUrl = "http://localhost:7010"
)

$ErrorActionPreference = "Stop"

Write-Host "[author-eval] Evaluating preset: $PresetFile" -ForegroundColor Cyan
Write-Host "Duration: ${DurationSeconds}s | Blend: ${Blend}s" -ForegroundColor Gray
Write-Host ""

# 1. Load preset
$presetName = [System.IO.Path]::GetFileNameWithoutExtension($PresetFile)
$presetBody = Get-Content $PresetFile -Raw

$loadPayload = @{
    name = $presetName
    body = $presetBody
    blend = $Blend
} | ConvertTo-Json -Depth 5

Write-Host "[1/4] Loading preset..." -ForegroundColor Yellow

try {
    $loadResponse = Invoke-RestMethod `
        -Uri "$VizEngineUrl/preset" `
        -Method Post `
        -ContentType "application/json" `
        -Body $loadPayload `
        -TimeoutSec 10
    
    if ($loadResponse.ok) {
        Write-Host "  [OK] Preset loaded: $($loadResponse.preset)" -ForegroundColor Green
    } else {
        Write-Error "Failed to load preset"
        exit 1
    }
} catch {
    Write-Error "Error loading preset: $_"
    exit 1
}

# 2. Wait for blend + evaluation period
Write-Host "[2/4] Waiting for blend ($Blend s) + evaluation ($DurationSeconds s)..." -ForegroundColor Yellow
Start-Sleep -Seconds ($Blend + $DurationSeconds)

# 3. Capture final frame
Write-Host "[3/4] Capturing frame..." -ForegroundColor Yellow

$snapPath = "artifacts/viz-engine/eval-$presetName-$(Get-Date -Format 'yyyyMMdd-HHmmss').jpg"
curl -s "$VizEngineUrl/snap.jpg" -o $snapPath
Write-Host "  [OK] Frame saved: $snapPath" -ForegroundColor Green

# 4. Get final metrics
Write-Host "[4/4] Collecting metrics..." -ForegroundColor Yellow

try {
    $metrics = Invoke-RestMethod `
        -Uri "$ScorebotUrl/metrics" `
        -Method Get `
        -TimeoutSec 5
    
    $validation = Invoke-RestMethod `
        -Uri "$ScorebotUrl/validate" `
        -Method Post `
        -TimeoutSec 5 `
        -ErrorAction SilentlyContinue
    
    if (-not $validation) {
        # Validation failed, get error details
        $validation = @{
            verdict = "FAIL"
            ok = $false
            failures = @("Validation failed")
        }
    }
} catch {
    Write-Error "Error collecting metrics: $_"
    exit 1
}

# 5. Generate evaluation report
Write-Host ""
Write-Host "=== EVALUATION RESULTS ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Preset:        $presetName" -ForegroundColor White
Write-Host "Verdict:       $($validation.verdict)" -ForegroundColor $(if ($validation.ok) { 'Green' } else { 'Red' })
Write-Host "Score:         $($metrics.score.ToString('F2'))" -ForegroundColor White
Write-Host ""
Write-Host "Metrics:" -ForegroundColor Cyan
Write-Host "  Aspect OK:   $($metrics.aspect_ok)" -ForegroundColor Gray
Write-Host "  Blackout:    $($metrics.blackout) ($($metrics.black_ratio.ToString('P2')))" -ForegroundColor Gray
Write-Host "  Motion:      $($metrics.motion_magnitude.ToString('F4'))" -ForegroundColor Gray
Write-Host "  Reactivity:  $($metrics.reactivity_r.ToString('F3'))" -ForegroundColor Gray
Write-Host "  Color Var:   $($metrics.color_var.ToString('F3'))" -ForegroundColor Gray
Write-Host ""

if (-not $validation.ok) {
    Write-Host "Failures:" -ForegroundColor Red
    foreach ($failure in $validation.failures) {
        Write-Host "  - $failure" -ForegroundColor Red
    }
    Write-Host ""
}

# 6. Save evaluation artifact
$artifact = @{
    preset = $presetName
    file = $PresetFile
    timestamp = Get-Date -Format "o"
    duration_seconds = $DurationSeconds
    blend_seconds = $Blend
    verdict = $validation.verdict
    ok = $validation.ok
    score = $metrics.score
    metrics = $metrics
    failures = $validation.failures
    snap_path = $snapPath
} | ConvertTo-Json -Depth 10

$artifactPath = "artifacts/viz-engine/eval-$presetName-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$artifact | Set-Content $artifactPath -Encoding UTF8

Write-Host "Artifact: $artifactPath" -ForegroundColor Gray
Write-Host ""

# Return exit code based on validation
if ($validation.ok) {
    Write-Host "[RESULT] PASS - Preset meets Gate #010 thresholds" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[RESULT] FAIL - Preset does not meet thresholds" -ForegroundColor Red
    exit 1
}

