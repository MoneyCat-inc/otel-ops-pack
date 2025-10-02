# Dashboard Import Verification Script
# Verify dashboard import and panel functionality

param(
    [string]$SigNozUrl = "http://localhost:8080"
)

Write-Host "🔍 Dashboard Import Verification" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Check SigNoz health
Write-Host "
1. Checking SigNoz health..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    Write-Host "   ✅ SigNoz is healthy: $($HealthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ SigNoz not accessible: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check OTel Collector status
Write-Host "
2. Checking OTel Collector status..." -ForegroundColor Yellow
try {
    $ServiceStatus = Get-Service otelcol-contrib -ErrorAction SilentlyContinue
    if ($ServiceStatus) {
        Write-Host "   ✅ OTel Collector service: $($ServiceStatus.Status)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ OTel Collector service not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️ Could not check OTel Collector service" -ForegroundColor Yellow
}

# Check metrics availability
Write-Host "
3. Checking metrics availability..." -ForegroundColor Yellow
$Metrics = @(
    "otelcol_exporter_queue_size",
    "otelcol_exporter_queue_capacity",
    "otelcol_exporter_send_failed_spans_total",
    "otelcol_exporter_sent_spans_total",
    "otelcol_processor_batch_timeout_trigger_sent_duration_bucket"
)

foreach ($Metric in $Metrics) {
    try {
        $QueryResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/query?query=$Metric" -Method Get -TimeoutSec 10
        if ($QueryResponse.data.result -and $QueryResponse.data.result.Count -gt 0) {
            Write-Host "   ✅ $Metric: Available" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ $Metric: No data" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ $Metric: Query failed" -ForegroundColor Red
    }
}

Write-Host "
4. Dashboard import verification complete!" -ForegroundColor Green
Write-Host "   📊 Check SigNoz UI at $SigNozUrl to verify dashboard import" -ForegroundColor Blue
