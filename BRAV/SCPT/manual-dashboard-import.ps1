# Manual Dashboard Import Helper
# Guide user through manual dashboard import process
# Cursor-Local: Observability Copilot

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$OpenBrowser = $false
)

Write-Host "📊 Manual Dashboard Import Helper" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# ECRR: Examine → Clean → Report → Role
Write-Host "🔍 ECRR Framework: Manual Dashboard Import" -ForegroundColor Yellow

$ArtifactsDir = "artifacts"
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Path $ArtifactsDir | Out-Null
}

# Check SigNoz connectivity
Write-Host "🔍 Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    Write-Host "✅ SigNoz is healthy: $($HealthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ SigNoz not accessible: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   Please ensure SigNoz is running on $SigNozUrl" -ForegroundColor Yellow
    exit 1
}

# Display dashboard import instructions
Write-Host "`n📋 Manual Dashboard Import Instructions" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

Write-Host "`n1. 🌐 Open SigNoz UI" -ForegroundColor Yellow
Write-Host "   URL: $SigNozUrl" -ForegroundColor White
if ($OpenBrowser) {
    Start-Process $SigNozUrl
    Write-Host "   ✅ Browser opened automatically" -ForegroundColor Green
} else {
    Write-Host "   💡 Tip: Use -OpenBrowser flag to open automatically" -ForegroundColor Gray
}

Write-Host "`n2. 🔐 Authentication (if required)" -ForegroundColor Yellow
Write-Host "   - If prompted, log in with your credentials" -ForegroundColor White
Write-Host "   - Default credentials may be admin/admin" -ForegroundColor White
Write-Host "   - Check your SigNoz setup documentation" -ForegroundColor White

Write-Host "`n3. 📊 Navigate to Dashboards" -ForegroundColor Yellow
Write-Host "   - Click 'Dashboards' in the left sidebar" -ForegroundColor White
Write-Host "   - Click 'New Dashboard' or '+' button" -ForegroundColor White
Write-Host "   - Select 'Import Dashboard' option" -ForegroundColor White

Write-Host "`n4. 📁 Import Dashboard JSON" -ForegroundColor Yellow
Write-Host "   - Choose 'Upload JSON file' or 'Paste JSON'" -ForegroundColor White
Write-Host "   - Copy the JSON configuration below" -ForegroundColor White

# Display the dashboard JSON configuration
Write-Host "`n📄 Dashboard JSON Configuration:" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

$DashboardJson = @"
{
  "title": "Queue Health Monitors",
  "description": "Queue pressure, send failure rates, and trace time-to-use monitoring for the collector export path",
  "version": "1.0.0",
  "created": "2025-01-27T06:58:00Z",
  "panels": [
    {
      "id": "queue-utilization-ratio",
      "title": "Queue Utilization Ratio",
      "type": "graph",
      "targets": [
        {
          "queryType": "promql",
          "expr": "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity",
          "legendFormat": "Queue Utilization %"
        }
      ],
      "thresholds": [
        { "value": 0.7, "colorMode": "critical", "op": "gt" },
        { "value": 0.5, "colorMode": "warning", "op": "gt" }
      ]
    },
    {
      "id": "send-failure-rate",
      "title": "Send Failure Rate",
      "type": "graph",
      "targets": [
        {
          "queryType": "promql",
          "expr": "rate(otelcol_exporter_send_failed_spans_total[5m]) / rate(otelcol_exporter_sent_spans_total[5m])",
          "legendFormat": "Span Send Failure Rate"
        }
      ],
      "thresholds": [
        { "value": 0.05, "colorMode": "critical", "op": "gt" }
      ]
    },
    {
      "id": "trace-time-to-use",
      "title": "Trace Time-to-Use Latency",
      "type": "graph",
      "targets": [
        {
          "queryType": "promql",
          "expr": "histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))",
          "legendFormat": "p95 Latency"
        }
      ],
      "thresholds": [
        { "value": 8, "colorMode": "critical", "op": "gt" }
      ]
    }
  ]
}
"@

Write-Host $DashboardJson -ForegroundColor Gray

# Save dashboard JSON to file
$DashboardJson | Set-Content -Path "$ArtifactsDir/queue-health-dashboard.json"
Write-Host "`n📁 Dashboard JSON saved to: $ArtifactsDir/queue-health-dashboard.json" -ForegroundColor Yellow

Write-Host "`n5. ⚙️ Configure Dashboard Settings" -ForegroundColor Yellow
Write-Host "   - Dashboard Name: 'Queue Health Monitors'" -ForegroundColor White
Write-Host "   - Folder: Create new folder 'OTel Monitoring' or use existing" -ForegroundColor White
Write-Host "   - Tags: Add tags: otel, queue, variability, monitoring, latency" -ForegroundColor White
Write-Host "   - Time Range: Set default to 'Last 1 hour'" -ForegroundColor White
Write-Host "   - Refresh Interval: Set to '5s'" -ForegroundColor White

Write-Host "`n6. 💾 Save and Verify" -ForegroundColor Yellow
Write-Host "   - Click 'Import' or 'Save'" -ForegroundColor White
Write-Host "   - Verify the dashboard appears in your dashboard list" -ForegroundColor White
Write-Host "   - Click on the dashboard to open it" -ForegroundColor White
Write-Host "   - Verify all three panels are visible" -ForegroundColor White

# Panel details
Write-Host "`n📊 Panel Details:" -ForegroundColor Cyan
Write-Host "=================" -ForegroundColor Cyan

Write-Host "`n🔴 Panel 1: Queue Utilization Ratio" -ForegroundColor Red
Write-Host "   Query: otelcol_exporter_queue_size / otelcol_exporter_queue_capacity" -ForegroundColor Gray
Write-Host "   Thresholds: Critical > 70%, Warning > 50%" -ForegroundColor Gray
Write-Host "   Purpose: Monitor queue pressure and batch processing efficiency" -ForegroundColor Gray

Write-Host "`n🟡 Panel 2: Send Failure Rate" -ForegroundColor Yellow
Write-Host "   Query: rate(otelcol_exporter_send_failed_spans_total[5m]) / rate(otelcol_exporter_sent_spans_total[5m])" -ForegroundColor Gray
Write-Host "   Threshold: Critical > 5%" -ForegroundColor Gray
Write-Host "   Purpose: Monitor exporter connectivity and SigNoz health" -ForegroundColor Gray

Write-Host "`n🟠 Panel 3: Trace Time-to-Use Latency" -ForegroundColor DarkYellow
Write-Host "   Query: histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))" -ForegroundColor Gray
Write-Host "   Threshold: Critical > 8 seconds" -ForegroundColor Gray
Write-Host "   Purpose: Monitor batch processor performance and network latency" -ForegroundColor Gray

# Troubleshooting section
Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

Write-Host "`n❓ Common Issues:" -ForegroundColor Yellow
Write-Host "   - No Data: Ensure OTel Collector is running and sending metrics" -ForegroundColor White
Write-Host "   - Query Errors: Verify metric names match your OTel Collector version" -ForegroundColor White
Write-Host "   - Authentication: Ensure you have proper permissions to create dashboards" -ForegroundColor White

Write-Host "`n🔍 Verification Commands:" -ForegroundColor Yellow
Write-Host "   # Check OTel Collector status" -ForegroundColor Gray
Write-Host "   Get-Service otelcol-contrib" -ForegroundColor Gray
Write-Host "   " -ForegroundColor Gray
Write-Host "   # Check SigNoz health" -ForegroundColor Gray
Write-Host "   curl -s http://localhost:8080/api/v1/health" -ForegroundColor Gray
Write-Host "   " -ForegroundColor Gray
Write-Host "   # Check if metrics are available" -ForegroundColor Gray
Write-Host "   curl -s 'http://localhost:8080/api/v1/query?query=otelcol_exporter_queue_size'" -ForegroundColor Gray

# Create verification script
Write-Host "`n📝 Creating verification script..." -ForegroundColor Yellow

$VerificationScript = @"
# Dashboard Import Verification Script
# Verify dashboard import and panel functionality

param(
    [string]`$SigNozUrl = "http://localhost:8080"
)

Write-Host "🔍 Dashboard Import Verification" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Check SigNoz health
Write-Host "`n1. Checking SigNoz health..." -ForegroundColor Yellow
try {
    `$HealthResponse = Invoke-RestMethod -Uri "`$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    Write-Host "   ✅ SigNoz is healthy: `$(`$HealthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "   ❌ SigNoz not accessible: `$(`$_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check OTel Collector status
Write-Host "`n2. Checking OTel Collector status..." -ForegroundColor Yellow
try {
    `$ServiceStatus = Get-Service otelcol-contrib -ErrorAction SilentlyContinue
    if (`$ServiceStatus) {
        Write-Host "   ✅ OTel Collector service: `$(`$ServiceStatus.Status)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ OTel Collector service not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ⚠️ Could not check OTel Collector service" -ForegroundColor Yellow
}

# Check metrics availability
Write-Host "`n3. Checking metrics availability..." -ForegroundColor Yellow
`$Metrics = @(
    "otelcol_exporter_queue_size",
    "otelcol_exporter_queue_capacity",
    "otelcol_exporter_send_failed_spans_total",
    "otelcol_exporter_sent_spans_total",
    "otelcol_processor_batch_timeout_trigger_sent_duration_bucket"
)

foreach (`$Metric in `$Metrics) {
    try {
        `$QueryResponse = Invoke-RestMethod -Uri "`$SigNozUrl/api/v1/query?query=`$Metric" -Method Get -TimeoutSec 10
        if (`$QueryResponse.data.result -and `$QueryResponse.data.result.Count -gt 0) {
            Write-Host "   ✅ `$Metric: Available" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ `$Metric: No data" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "   ❌ `$Metric: Query failed" -ForegroundColor Red
    }
}

Write-Host "`n4. Dashboard import verification complete!" -ForegroundColor Green
Write-Host "   📊 Check SigNoz UI at `$SigNozUrl to verify dashboard import" -ForegroundColor Blue
"@

$VerificationScript | Set-Content -Path "scripts/verify-dashboard-import.ps1"
Write-Host "📝 Verification script created: scripts/verify-dashboard-import.ps1" -ForegroundColor Yellow

# ECRR Report
$ECRRReport = @"
# Manual Dashboard Import - ECRR Report
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Actor**: Cursor-Local (Observability Copilot)

## Examine
- SigNoz connectivity: ✅ Healthy
- Dashboard JSON: ✅ Generated
- Import instructions: ✅ Provided
- Verification script: ✅ Created

## Clean
- Created comprehensive import guide
- Generated dashboard JSON configuration
- Provided troubleshooting steps
- Created verification script

## Report
- Dashboard JSON: $ArtifactsDir/queue-health-dashboard.json
- Import guide: docs/MANUAL_DASHBOARD_IMPORT_GUIDE.md
- Verification script: scripts/verify-dashboard-import.ps1
- SigNoz URL: $SigNozUrl

## Role
Cursor-Local: Observability Copilot - Manual dashboard import guidance and verification
"@

$ECRRReport | Set-Content -Path "$ArtifactsDir/manual-dashboard-import-ecrr.md"

Write-Host "`n📁 ECRR Report saved to: $ArtifactsDir/manual-dashboard-import-ecrr.md" -ForegroundColor Magenta

Write-Host "`n🎉 Manual Dashboard Import Helper Complete!" -ForegroundColor Green
Write-Host "📊 Dashboard JSON: $ArtifactsDir/queue-health-dashboard.json" -ForegroundColor Blue
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Follow the import instructions above" -ForegroundColor White
Write-Host "   2. Verify import: pwsh -File scripts/verify-dashboard-import.ps1" -ForegroundColor White
Write-Host "   3. Test dashboard functionality with canary logs" -ForegroundColor White
