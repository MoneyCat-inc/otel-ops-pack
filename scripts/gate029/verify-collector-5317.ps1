# Gate #029: Windows Collector 5317 Trace Path Verification
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify collector receives and forwards traces (accepted ≈ sent)

param(
    [string]$CollectorMetricsUrl = "http://localhost:8888/metrics",
    [int]$DriftThresholdPercent = 5,  # Allow 5% drift (more lenient than Gate #027)
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #029: Collector 5317 Trace Path Verification ===" -ForegroundColor Cyan
Write-Host ""

# Fetch collector metrics
Write-Host "[1/4] Fetching collector metrics..." -ForegroundColor Cyan
try {
    $metricsRaw = Invoke-RestMethod -Uri $CollectorMetricsUrl -TimeoutSec 10
} catch {
    Write-Host "   ❌ Failed to fetch metrics: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($Verbose) {
    Write-Host "   Raw metrics length: $($metricsRaw.Length) chars" -ForegroundColor Gray
}

# Parse traces receiver metrics (OTLP on 5317)
Write-Host ""
Write-Host "[2/4] Parsing traces pipeline metrics..." -ForegroundColor Cyan

# Extract accepted spans (receiver)
$acceptedPattern = 'otelcol_receiver_accepted_spans\{.*?receiver="otlp".*?\}\s+(\d+)'
if ($metricsRaw -match $acceptedPattern) {
    $acceptedSpans = [int]$matches[1]
    Write-Host "   Received (accepted): $acceptedSpans spans" -ForegroundColor White
} else {
    Write-Host "   ⚠️  No receiver.accepted_spans metric found for OTLP receiver" -ForegroundColor Yellow
    $acceptedSpans = 0
}

# Extract sent spans (exporter to SigNoz)
$sentPattern = 'otelcol_exporter_sent_spans\{.*?exporter="otlp".*?\}\s+(\d+)'
if ($metricsRaw -match $sentPattern) {
    $sentSpans = [int]$matches[1]
    Write-Host "   Exported (sent): $sentSpans spans" -ForegroundColor White
} else {
    Write-Host "   ⚠️  No exporter.sent_spans metric found for OTLP exporter" -ForegroundColor Yellow
    $sentSpans = 0
}

# Extract failed exports
$failedPattern = 'otelcol_exporter_send_failed_spans\{.*?exporter="otlp".*?\}\s+(\d+)'
if ($metricsRaw -match $failedPattern) {
    $failedSpans = [int]$matches[1]
    Write-Host "   Failed exports: $failedSpans spans" -ForegroundColor $(if ($failedSpans -gt 0) { 'Red' } else { 'Green' })
} else {
    $failedSpans = 0
    Write-Host "   Failed exports: 0 spans (no metric)" -ForegroundColor Green
}

# Calculate drift
Write-Host ""
Write-Host "[3/4] Analyzing traces pipeline health..." -ForegroundColor Cyan

$drift = if ($acceptedSpans -gt 0) {
    [Math]::Abs($acceptedSpans - $sentSpans) / $acceptedSpans * 100
} else {
    0
}

$driftRounded = [Math]::Round($drift, 2)

Write-Host "   Accepted: $acceptedSpans" -ForegroundColor White
Write-Host "   Sent: $sentSpans" -ForegroundColor White
Write-Host "   Failed: $failedSpans" -ForegroundColor White
Write-Host "   Drift: $driftRounded%" -ForegroundColor $(if ($drift -le $DriftThresholdPercent) { 'Green' } else { 'Yellow' })

# SigNoz spot-check reminder
Write-Host ""
Write-Host "[4/4] SigNoz verification checklist:" -ForegroundColor Cyan
Write-Host "   □ Open SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "   □ Navigate to Services page" -ForegroundColor White
Write-Host "   □ Verify service 'bosscat-svc2-api' is listed" -ForegroundColor White
Write-Host "   □ Navigate to Traces Explorer" -ForegroundColor White
Write-Host "   □ Filter: serviceName = bosscat-svc2-api" -ForegroundColor White
Write-Host "   □ Verify recent traces (timestamps match test window)" -ForegroundColor White
Write-Host "   □ Click trace detail → verify spans + attributes" -ForegroundColor White
Write-Host ""
Write-Host "   **Screenshot required:** Services list + Trace detail" -ForegroundColor Yellow

# Verdict
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

$healthy = ($drift -le $DriftThresholdPercent) -and ($failedSpans -eq 0) -and ($acceptedSpans -gt 0)

if ($healthy) {
    Write-Host "✅ Collector 5317 Trace Path: HEALTHY" -ForegroundColor Green
    Write-Host "   Accepted: $acceptedSpans" -ForegroundColor Green
    Write-Host "   Sent: $sentSpans" -ForegroundColor Green
    Write-Host "   Drift: $driftRounded% (threshold: ≤$DriftThresholdPercent%)" -ForegroundColor Green
    Write-Host "   Failed: 0" -ForegroundColor Green
    Write-Host ""
    Write-Host "   ✅ Gate #029 Acceptance Criterion #2: PASS" -ForegroundColor Green
    exit 0  # GREEN
} else {
    Write-Host "⚠️  Collector 5317 Trace Path: NEEDS REVIEW" -ForegroundColor Yellow
    
    if ($acceptedSpans -eq 0) {
        Write-Host "   Issue: No spans received by collector (check app endpoint config)" -ForegroundColor Yellow
    } elseif ($drift -gt $DriftThresholdPercent) {
        Write-Host "   Issue: Drift $driftRounded% exceeds threshold ($DriftThresholdPercent%)" -ForegroundColor Yellow
    } elseif ($failedSpans -gt 0) {
        Write-Host "   Issue: $failedSpans failed exports" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Verify service using collector endpoint: OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:5317" -ForegroundColor White
    Write-Host "   2. Check collector config: C:\otel\config.yaml (traces pipeline)" -ForegroundColor White
    Write-Host "   3. Restart collector: Restart-Service otelcol-contrib" -ForegroundColor White
    Write-Host "   4. Verify SigNoz endpoint: http://localhost:4317" -ForegroundColor White
    
    exit 10  # AMBER
}

