# Gate #027 Track 27A: Windows Collector Traces Pipeline Health Probe
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify collector receives and forwards traces (±1% acceptable drift)

param(
    [string]$CollectorMetricsUrl = "http://localhost:8888/metrics",
    [int]$DriftThresholdPercent = 1
)

$ErrorActionPreference = "Stop"

Write-Host "=== Gate #027 Track 27A: Collector Traces Health Probe ===" -ForegroundColor Cyan
Write-Host ""

# Fetch collector metrics
Write-Host "[1/3] Fetching collector metrics..." -ForegroundColor Cyan
try {
    $metricsRaw = Invoke-RestMethod -Uri $CollectorMetricsUrl -TimeoutSec 10
} catch {
    Write-Host "   ❌ Failed to fetch metrics: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Parse traces receiver metrics
Write-Host ""
Write-Host "[2/3] Parsing traces pipeline metrics..." -ForegroundColor Cyan

# Extract accepted spans (receiver)
$acceptedPattern = 'otelcol_receiver_accepted_spans\{.*?service_name="otlp/traces".*?\}\s+(\d+)'
if ($metricsRaw -match $acceptedPattern) {
    $acceptedSpans = [int]$matches[1]
    Write-Host "   Received (accepted): $acceptedSpans spans" -ForegroundColor White
} else {
    Write-Host "   ⚠️  No receiver.accepted_spans metric found" -ForegroundColor Yellow
    $acceptedSpans = 0
}

# Extract sent spans (exporter)
$sentPattern = 'otelcol_exporter_sent_spans\{.*?service_name="otlp/traces".*?\}\s+(\d+)'
if ($metricsRaw -match $sentPattern) {
    $sentSpans = [int]$matches[1]
    Write-Host "   Exported (sent): $sentSpans spans" -ForegroundColor White
} else {
    Write-Host "   ⚠️  No exporter.sent_spans metric found" -ForegroundColor Yellow
    $sentSpans = 0
}

# Extract failed exports
$failedPattern = 'otelcol_exporter_send_failed_spans\{.*?service_name="otlp/traces".*?\}\s+(\d+)'
if ($metricsRaw -match $failedPattern) {
    $failedSpans = [int]$matches[1]
    Write-Host "   Failed exports: $failedSpans spans" -ForegroundColor $(if ($failedSpans -gt 0) { 'Red' } else { 'Green' })
} else {
    $failedSpans = 0
    Write-Host "   Failed exports: 0 spans (no metric)" -ForegroundColor Green
}

# Calculate drift
Write-Host ""
Write-Host "[3/3] Analyzing traces pipeline health..." -ForegroundColor Cyan

$drift = if ($acceptedSpans -gt 0) {
    [Math]::Abs($acceptedSpans - $sentSpans) / $acceptedSpans * 100
} else {
    0
}

$driftRounded = [Math]::Round($drift, 2)

Write-Host "   Accepted: $acceptedSpans" -ForegroundColor White
Write-Host "   Sent: $sentSpans" -ForegroundColor White
Write-Host "   Failed: $failedSpans" -ForegroundColor White
Write-Host "   Drift: $driftRounded%" -ForegroundColor $(if ($drift -le $DriftThresholdPercent) { 'Green' } else { 'Red' })

# Verdict
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

$healthy = ($drift -le $DriftThresholdPercent) -and ($failedSpans -eq 0) -and ($acceptedSpans -gt 0)

if ($healthy) {
    Write-Host "✅ Traces Pipeline: HEALTHY" -ForegroundColor Green
    Write-Host "   Drift: $driftRounded% (threshold: ≤$DriftThresholdPercent%)" -ForegroundColor Green
    Write-Host "   Failed exports: 0" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ Traces Pipeline: UNHEALTHY" -ForegroundColor Red
    
    if ($acceptedSpans -eq 0) {
        Write-Host "   Issue: No spans received by collector" -ForegroundColor Red
    } elseif ($drift -gt $DriftThresholdPercent) {
        Write-Host "   Issue: Drift $driftRounded% exceeds threshold ($DriftThresholdPercent%)" -ForegroundColor Red
    } elseif ($failedSpans -gt 0) {
        Write-Host "   Issue: $failedSpans failed exports" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "🔍 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Check collector config: C:\otel\config.yaml (traces pipeline)" -ForegroundColor White
    Write-Host "   2. Restart collector: Restart-Service otelcol-contrib" -ForegroundColor White
    Write-Host "   3. Verify SigNoz endpoint: http://localhost:4317" -ForegroundColor White
    exit 1
}

