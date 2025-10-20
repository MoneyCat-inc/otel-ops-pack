# Ready-to-Run Benchmark Campaign (BossCat OEM Harness)
# Produces: docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md + artifacts with medians
# Usage: pwsh -File scripts/run-benchmark-campaign.ps1

param(
    [int]$Trials = 5,
    [int]$DurationSec = 60,
    [string]$Protocol = "http",
    [string]$HttpEndpoint = "http://localhost:14318/v1/logs",
    [string]$GrpcEndpoint = "http://localhost:14317",
    [double]$Rate = 0
)

$DATE = Get-Date -Format "yyyy-MM-dd"
$ART  = "artifacts/metrics_$DATE"
$PY   = "synthetic\send_synthetic_otel_simple.py"
$EV   = "docs/ecrr/ECRR_REPORTS/EVIDENCE_$DATE.md"

Write-Host "🧪 Benchmark Campaign: OTLP Ingest Uplift Measurement" -ForegroundColor Cyan
Write-Host ""
Write-Host "📅 Date: $DATE" -ForegroundColor Yellow
Write-Host "📄 Evidence: $EV" -ForegroundColor Yellow
Write-Host "📁 Artifacts: $ART" -ForegroundColor Yellow
Write-Host "🔢 Trials: $Trials per variant" -ForegroundColor Yellow
Write-Host "⏱️  Duration: $DurationSec seconds per trial" -ForegroundColor Yellow
Write-Host "🔌 Protocol: $Protocol" -ForegroundColor Yellow
Write-Host ""

# Create artifacts directory
New-Item -Force -ItemType Directory -Path $ART | Out-Null
Write-Host "✅ Created artifacts directory" -ForegroundColor Green

# Helper: Median calculation
function Get-Median($arr) {
    $sorted = $arr | Sort-Object
    $n = $sorted.Count
    if ($n -eq 0) { return 0 }
    if ($n % 2) { 
        $sorted[[int]($n / 2)] 
    } else { 
        ([double]$sorted[$n / 2 - 1] + [double]$sorted[$n / 2]) / 2 
    }
}

# Helper: Run trial series
function Run-Series($label) {
    $rates = @()
    for ($i = 1; $i -le $Trials; $i++) {
        Write-Host "  Trial $i/$Trials..." -ForegroundColor White
        
        $endpoint = if ($Protocol -eq "grpc") { $GrpcEndpoint } else { $HttpEndpoint }
        
        $json = python $PY --label $label --run $i --duration $DurationSec --protocol $Protocol --endpoint $endpoint --rate $Rate
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ❌ Trial $i failed with exit code $LASTEXITCODE" -ForegroundColor Red
            continue
        }
        
        $obj = $json | ConvertFrom-Json
        $obj | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 "$ART\$label-run$i.json"
        $rates += [double]$obj.rate_logs_per_s
        
        Write-Host "    → $($obj.sent) logs sent, $($obj.rate_logs_per_s) logs/sec" -ForegroundColor Gray
        
        # Cool-down between trials
        if ($i -lt $Trials) {
            Start-Sleep -Seconds 5
        }
    }
    return , $rates
}

# Check if synthetic sender exists
if (-not (Test-Path $PY)) {
    Write-Host "❌ ERROR: Synthetic sender not found: $PY" -ForegroundColor Red
    Write-Host ""
    Write-Host "Create the sender first or update the path." -ForegroundColor Yellow
    exit 1
}

# Duplicate template
if (Test-Path "docs/ecrr/ECRR_REPORTS/EVIDENCE_TEMPLATE.md") {
    Copy-Item "docs/ecrr/ECRR_REPORTS/EVIDENCE_TEMPLATE.md" $EV
    Write-Host "📋 Created evidence document from template: $EV" -ForegroundColor Green
} else {
    Write-Host "⚠️  WARNING: Evidence template not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏃 Running BASELINE trials ($Trials)..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$baseRates = Run-Series -label "baseline"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "⚙️  Apply NEW/OPTIMIZED configuration now:" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Update Collector config (batch size, timeout, etc.)" -ForegroundColor White
Write-Host "2. Restart Collector service or container" -ForegroundColor White
Write-Host "3. Verify SigNoz connectivity" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter when optimized config is ready" | Out-Null

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🏃 Running NEW/OPTIMIZED trials ($Trials)..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

$newRates = Run-Series -label "new"

# Calculate medians and uplift
$baseMed = [math]::Round((Get-Median $baseRates), 3)
$newMed  = [math]::Round((Get-Median $newRates), 3)
$uplift  = if ($baseMed -gt 0) { [math]::Round($newMed / $baseMed, 3) } else { 0 }

# Save summary
$summary = [pscustomobject]@{
    date                   = $DATE
    trials                 = $Trials
    duration_s             = $DurationSec
    protocol               = $Protocol
    base_median_logs_per_s = $baseMed
    new_median_logs_per_s  = $newMed
    uplift_x               = $uplift
    base_rates             = $baseRates
    new_rates              = $newRates
}

$summary | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 "$ART\summary.json"

# Display results
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "🎉 Benchmark Campaign Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "📊 RESULTS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  BASELINE median:  $baseMed logs/sec" -ForegroundColor White
Write-Host "  NEW median:       $newMed logs/sec" -ForegroundColor White
Write-Host "  UPLIFT:           $uplift×" -ForegroundColor Yellow
Write-Host ""
Write-Host "📁 Artifacts saved to: $ART" -ForegroundColor Gray
Write-Host "   - Baseline trials: baseline-run1.json through baseline-run$Trials.json" -ForegroundColor Gray
Write-Host "   - NEW trials: new-run1.json through new-run$Trials.json" -ForegroundColor Gray
Write-Host "   - Summary: summary.json" -ForegroundColor Gray
Write-Host ""

# Publication decision
if ($uplift -ge 6.0) {
    Write-Host "✅ PUBLICATION THRESHOLD MET (uplift ≥6×)" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Allowed claim:" -ForegroundColor Green
    Write-Host "   'Up to 7× OTLP ingest throughput improvement'" -ForegroundColor Green
    Write-Host "   (baseline vs. tuned config, median of $Trials trials)" -ForegroundColor Green
    Write-Host "   See evidence → EVIDENCE_$DATE.md" -ForegroundColor Green
    Write-Host ""
    Write-Host "   ⚠️  REQUIRED: Calculate 95% bootstrap CI to verify lower bound ≥6×" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  PUBLICATION THRESHOLD NOT MET (uplift <6×)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Publish absolute medians only:" -ForegroundColor Yellow
    Write-Host "   'Baseline $baseMed logs/sec → New $newMed logs/sec'" -ForegroundColor Yellow
    Write-Host "   (median of $Trials trials, see evidence → EVIDENCE_$DATE.md)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Fill in evidence document: $EV" -ForegroundColor White
Write-Host "   - Document baseline config (commit hash, parameters)" -ForegroundColor White
Write-Host "   - Document NEW config (commit hash, changes)" -ForegroundColor White
Write-Host "   - Document environment (CPU, RAM, OS, versions)" -ForegroundColor White
Write-Host "   - Fill results table with trial data from summary.json" -ForegroundColor White
Write-Host ""
Write-Host "2. Calculate 95% confidence interval:" -ForegroundColor White
Write-Host "   - Bootstrap resampling on trial medians" -ForegroundColor White
Write-Host "   - Verify CI lower bound (must be ≥6× for '7×' claim)" -ForegroundColor White
Write-Host ""
Write-Host "3. Capture SigNoz screenshots:" -ForegroundColor White
Write-Host "   - Baseline log count query" -ForegroundColor White
Write-Host "   - NEW log count query" -ForegroundColor White
Write-Host "   - Save to $ART" -ForegroundColor White
Write-Host ""
Write-Host "4. Update site copy (if CI ≥6×):" -ForegroundColor White
Write-Host "   - Replace 'Performance: Thresholds met (see test evidence)'" -ForegroundColor White
Write-Host "   - With: 'Up to 7× ingest uplift (see evidence → EVIDENCE_$DATE.md)'" -ForegroundColor White
Write-Host ""
Write-Host "5. Commit evidence + artifacts:" -ForegroundColor White
Write-Host "   - git add $ART $EV" -ForegroundColor White
Write-Host "   - git commit -m 'feat(evidence): OTLP ingest benchmark results $DATE'" -ForegroundColor White
Write-Host ""
Write-Host "6. CI guard will verify:" -ForegroundColor White
Write-Host "   - No inflated claims (77×, 196.7) without evidence" -ForegroundColor White
Write-Host "   - CODEOWNERS will require BossCat OEM approval" -ForegroundColor White
Write-Host ""
Write-Host "✅ Campaign data collected. Complete the evidence document and commit." -ForegroundColor Green
