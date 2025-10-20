# Ready-to-Run Benchmark Campaign
# Produces: docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md + artifacts
# Usage: pwsh -File scripts/run-benchmark-campaign.ps1

param(
    [int]$Trials = 5,
    [string]$BaselineLabel = "baseline",
    [string]$NewLabel = "new"
)

Write-Host "🧪 Benchmark Campaign: OTLP Ingest Uplift Measurement" -ForegroundColor Cyan
Write-Host ""

# 0) Setup vars
$DATE = (Get-Date -Format "yyyy-MM-dd")
$EV = "docs/ecrr/ECRR_REPORTS/EVIDENCE_$DATE.md"
$ART = "artifacts/metrics_$DATE"

Write-Host "📅 Date: $DATE" -ForegroundColor Yellow
Write-Host "📄 Evidence: $EV" -ForegroundColor Yellow
Write-Host "📁 Artifacts: $ART" -ForegroundColor Yellow
Write-Host "🔢 Trials: $Trials per variant" -ForegroundColor Yellow
Write-Host ""

# Create artifacts directory
New-Item -ItemType Directory -Force -Path $ART | Out-Null
Write-Host "✅ Created artifacts directory" -ForegroundColor Green

# 1) Duplicate template
Write-Host ""
Write-Host "📋 Creating evidence document from template..." -ForegroundColor Cyan
Copy-Item "docs/ecrr/ECRR_REPORTS/EVIDENCE_TEMPLATE.md" $EV
Write-Host "✅ Evidence document created: $EV" -ForegroundColor Green

# 2) Run baseline trials
Write-Host ""
Write-Host "🏃 Running BASELINE trials ($Trials)..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if (-not (Test-Path "synthetic\send_synthetic_otel_simple.py")) {
    Write-Host "⚠️  WARNING: synthetic\send_synthetic_otel_simple.py not found" -ForegroundColor Yellow
    Write-Host "   Create your synthetic sender script or update this path" -ForegroundColor Yellow
    Write-Host ""
} else {
    1..$Trials | ForEach-Object {
        Write-Host "  Trial $_/$Trials..." -ForegroundColor White
        python synthetic\send_synthetic_otel_simple.py --label $BaselineLabel --run $_ | Tee-Object "$ART\${BaselineLabel}_run$_.log"
        Start-Sleep -Seconds 5 # Cool-down between trials
    }
    Write-Host "✅ BASELINE trials complete" -ForegroundColor Green
}

# 3) Apply optimized config
Write-Host ""
Write-Host "⚙️  Apply your OPTIMIZED configuration now:" -ForegroundColor Yellow
Write-Host "   1. Update Collector config (batch size, timeout, etc.)" -ForegroundColor Yellow
Write-Host "   2. Restart Collector service" -ForegroundColor Yellow
Write-Host "   3. Verify SigNoz connectivity" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter when optimized config is ready"

# 4) Run new/optimized trials
Write-Host ""
Write-Host "🏃 Running NEW/OPTIMIZED trials ($Trials)..." -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if (Test-Path "synthetic\send_synthetic_otel_simple.py") {
    1..$Trials | ForEach-Object {
        Write-Host "  Trial $_/$Trials..." -ForegroundColor White
        python synthetic\send_synthetic_otel_simple.py --label $NewLabel --run $_ | Tee-Object "$ART\${NewLabel}_run$_.log"
        Start-Sleep -Seconds 5 # Cool-down between trials
    }
    Write-Host "✅ NEW/OPTIMIZED trials complete" -ForegroundColor Green
}

# 5) Snapshot SigNoz (optional but recommended)
Write-Host ""
Write-Host "📸 Capturing SigNoz screenshots..." -ForegroundColor Cyan
if (Test-Path "scripts/signoz-snapshot.spec.ts") {
    pnpm playwright test scripts/signoz-snapshot.spec.ts
    Write-Host "✅ Screenshots captured" -ForegroundColor Green
} else {
    Write-Host "⚠️  WARNING: scripts/signoz-snapshot.spec.ts not found" -ForegroundColor Yellow
    Write-Host "   Manually capture SigNoz UI screenshots and save to $ART" -ForegroundColor Yellow
}

# 6) Final instructions
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "🎉 Benchmark Campaign Complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Open evidence document: $EV" -ForegroundColor White
Write-Host ""
Write-Host "2. Fill in the results table:" -ForegroundColor White
Write-Host "   - Extract logs/sec from trial logs in $ART" -ForegroundColor White
Write-Host "   - Calculate medians for baseline and new" -ForegroundColor White
Write-Host "   - Compute uplift: median(NEW) / median(BASELINE)" -ForegroundColor White
Write-Host ""
Write-Host "3. Calculate 95% confidence interval:" -ForegroundColor White
Write-Host "   - Use bootstrap resampling on trial medians" -ForegroundColor White
Write-Host "   - If CI lower bound ≥6×: Publish 'up to 7×'" -ForegroundColor White
Write-Host "   - If CI lower bound <6×: Publish absolute medians only" -ForegroundColor White
Write-Host ""
Write-Host "4. Document configurations:" -ForegroundColor White
Write-Host "   - Baseline config (commit hash, parameters)" -ForegroundColor White
Write-Host "   - New config (commit hash, what changed)" -ForegroundColor White
Write-Host "   - Environment (CPU, RAM, OS, SigNoz version)" -ForegroundColor White
Write-Host ""
Write-Host "5. Attach artifacts:" -ForegroundColor White
Write-Host "   - Move SigNoz screenshots to $ART" -ForegroundColor White
Write-Host "   - Export raw data (JSON) to $ART" -ForegroundColor White
Write-Host "   - Commit everything to Git" -ForegroundColor White
Write-Host ""
Write-Host "6. Update site copy (if CI ≥6×):" -ForegroundColor White
Write-Host "   - Replace 'Performance: Thresholds met (see test evidence)'" -ForegroundColor White
Write-Host "   - With: 'Up to 7× ingest uplift (see evidence → EVIDENCE_$DATE.md)'" -ForegroundColor White
Write-Host ""
Write-Host "7. Commit and push:" -ForegroundColor White
Write-Host "   - CI guard will verify no inflated claims leak" -ForegroundColor White
Write-Host "   - CODEOWNERS will require BossCat OEM approval" -ForegroundColor White
Write-Host ""
Write-Host "📂 Artifacts location: $ART" -ForegroundColor Yellow
Write-Host "📄 Evidence document: $EV" -ForegroundColor Yellow
Write-Host ""
Write-Host "✅ Campaign data collected. Complete the evidence document and commit." -ForegroundColor Green

