# Manual Alert Configuration Guide - ECRR Framework
# Actor: Cursor-Local (Observability Copilot)
# Purpose: Provide detailed alert configuration instructions

param(
    [string]$WebhookUrl = "http://localhost:3003/api/webhooks/alerts",
    [switch]$ShowQueries = $true,
    [switch]$ShowTemplates = $true
)

Write-Host "🚨 Manual Alert Configuration Guide - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host ""

Write-Host "📋 Alert Configuration Steps" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host ""

# Step 1: Access SigNoz Alerts
Write-Host "🔗 Step 1: Access SigNoz Alerts" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8080" -ForegroundColor White
Write-Host "2. Go to Alerts → Alert Rules" -ForegroundColor White
Write-Host "3. Click 'Create Alert Rule'" -ForegroundColor White
Write-Host ""

# Step 2: Alert Rules
Write-Host "📊 Step 2: Create Alert Rules" -ForegroundColor Yellow
Write-Host ""

if ($ShowQueries) {
    Write-Host "🔍 Alert 1: Queue Utilization High" -ForegroundColor Cyan
    Write-Host "   Name: Queue Utilization High" -ForegroundColor White
    Write-Host "   Query: otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100" -ForegroundColor Gray
    Write-Host "   Condition: > 80" -ForegroundColor White
    Write-Host "   Duration: 5m" -ForegroundColor White
    Write-Host "   Severity: Warning" -ForegroundColor White
    Write-Host "   Description: Queue utilization exceeds 80% for 5 minutes" -ForegroundColor White
    Write-Host ""

    Write-Host "🔍 Alert 2: Send Failure Rate High" -ForegroundColor Cyan
    Write-Host "   Name: Send Failure Rate High" -ForegroundColor White
    Write-Host "   Query: rate(otelcol_exporter_send_failed_log_records_total[5m])" -ForegroundColor Gray
    Write-Host "   Condition: > 0.05" -ForegroundColor White
    Write-Host "   Duration: 2m" -ForegroundColor White
    Write-Host "   Severity: Critical" -ForegroundColor White
    Write-Host "   Description: Send failure rate exceeds 5% for 2 minutes" -ForegroundColor White
    Write-Host ""

    Write-Host "🔍 Alert 3: Batch Timeout Triggers" -ForegroundColor Cyan
    Write-Host "   Name: Batch Timeout Triggers" -ForegroundColor White
    Write-Host "   Query: rate(otelcol_processor_batch_timeout_trigger_send_total[5m])" -ForegroundColor Gray
    Write-Host "   Condition: > 0.1" -ForegroundColor White
    Write-Host "   Duration: 3m" -ForegroundColor White
    Write-Host "   Severity: Warning" -ForegroundColor White
    Write-Host "   Description: Batch timeout triggers exceed 10/min for 3 minutes" -ForegroundColor White
    Write-Host ""

    Write-Host "🔍 Alert 4: Log Processing Rate Low" -ForegroundColor Cyan
    Write-Host "   Name: Log Processing Rate Low" -ForegroundColor White
    Write-Host "   Query: rate(otelcol_receiver_accepted_log_records_total[5m])" -ForegroundColor Gray
    Write-Host "   Condition: < 1.67" -ForegroundColor White
    Write-Host "   Duration: 5m" -ForegroundColor White
    Write-Host "   Severity: Warning" -ForegroundColor White
    Write-Host "   Description: Log processing rate below 100/min for 5 minutes" -ForegroundColor White
    Write-Host ""
}

# Step 3: Notification Channel
Write-Host "🔗 Step 3: Create Notification Channel" -ForegroundColor Yellow
Write-Host "1. Go to Alerts → Notification Channels" -ForegroundColor White
Write-Host "2. Click 'Create Notification Channel'" -ForegroundColor White
Write-Host "3. Select 'Webhook' as type" -ForegroundColor White
Write-Host ""

Write-Host "📋 Webhook Configuration:" -ForegroundColor Cyan
Write-Host "   Name: OTel Webhook Alerts" -ForegroundColor White
Write-Host "   URL: $WebhookUrl" -ForegroundColor White
Write-Host "   Method: POST" -ForegroundColor White
Write-Host "   Headers: Content-Type: application/json" -ForegroundColor White
Write-Host ""

if ($ShowTemplates) {
    Write-Host "📝 Body Template (Optional):" -ForegroundColor Cyan
    Write-Host @"
   {
     "alert_name": "{{ .AlertName }}",
     "severity": "{{ .Severity }}",
     "message": "{{ .Message }}",
     "timestamp": "{{ .Timestamp }}",
     "source": "signoz-alerts"
   }
"@ -ForegroundColor Gray
    Write-Host ""
}

# Step 4: Link Alerts
Write-Host "🔗 Step 4: Link Alerts to Notification Channel" -ForegroundColor Yellow
Write-Host "1. Go back to Alert Rules" -ForegroundColor White
Write-Host "2. For each alert rule:" -ForegroundColor White
Write-Host "   - Click 'Edit' on the alert" -ForegroundColor White
Write-Host "   - Scroll to 'Notification Channels'" -ForegroundColor White
Write-Host "   - Select 'OTel Webhook Alerts'" -ForegroundColor White
Write-Host "   - Click 'Save'" -ForegroundColor White
Write-Host ""

# Step 5: Testing
Write-Host "🧪 Step 5: Test Alert Configuration" -ForegroundColor Yellow
Write-Host "1. Generate test logs:" -ForegroundColor White
Write-Host "   pwsh -File scripts/canary-test.ps1" -ForegroundColor Gray
Write-Host "2. Check webhook logs:" -ForegroundColor White
Write-Host "   Get-Content artifacts/webhook-logs.json | Select-Object -Last 5" -ForegroundColor Gray
Write-Host "3. Verify in SigNoz:" -ForegroundColor White
Write-Host "   - Go to Alerts → Alert History" -ForegroundColor White
Write-Host "   - Check for recent triggers" -ForegroundColor White
Write-Host ""

# Step 6: Verification
Write-Host "✅ Step 6: Verification Checklist" -ForegroundColor Yellow
Write-Host "□ All 4 alert rules created" -ForegroundColor White
Write-Host "□ Notification channel configured" -ForegroundColor White
Write-Host "□ Alerts linked to notification channel" -ForegroundColor White
Write-Host "□ Test alerts delivered to webhook" -ForegroundColor White
Write-Host "□ Alert history shows recent triggers" -ForegroundColor White
Write-Host ""

# Additional Information
Write-Host "📊 Additional Information" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""

Write-Host "🔍 Query Testing:" -ForegroundColor Cyan
Write-Host "   - Use SigNoz query builder to test queries" -ForegroundColor White
Write-Host "   - Verify metrics are available" -ForegroundColor White
Write-Host "   - Check time ranges and aggregations" -ForegroundColor White
Write-Host ""

Write-Host "⚙️ Threshold Tuning:" -ForegroundColor Cyan
Write-Host "   - Monitor for 24 hours" -ForegroundColor White
Write-Host "   - Adjust thresholds based on actual usage" -ForegroundColor White
Write-Host "   - Consider seasonal patterns" -ForegroundColor White
Write-Host ""

Write-Host "🚨 Alert Severity Guidelines:" -ForegroundColor Cyan
Write-Host "   - Critical: Immediate action required" -ForegroundColor White
Write-Host "   - Warning: Attention needed within hours" -ForegroundColor White
Write-Host "   - Info: Monitoring and trending" -ForegroundColor White
Write-Host ""

Write-Host "📈 Performance Impact:" -ForegroundColor Cyan
Write-Host "   - Alerts add minimal overhead" -ForegroundColor White
Write-Host "   - Query frequency affects performance" -ForegroundColor White
Write-Host "   - Consider alert grouping and deduplication" -ForegroundColor White
Write-Host ""

# Troubleshooting
Write-Host "🔧 Troubleshooting" -ForegroundColor Red
Write-Host "==================" -ForegroundColor Red
Write-Host ""

Write-Host "❌ Common Issues:" -ForegroundColor Yellow
Write-Host "   - Query syntax errors" -ForegroundColor White
Write-Host "   - Missing metrics" -ForegroundColor White
Write-Host "   - Webhook URL incorrect" -ForegroundColor White
Write-Host "   - Notification channel not linked" -ForegroundColor White
Write-Host ""

Write-Host "✅ Solutions:" -ForegroundColor Yellow
Write-Host "   - Validate queries in query builder" -ForegroundColor White
Write-Host "   - Check metric availability" -ForegroundColor White
Write-Host "   - Test webhook URL manually" -ForegroundColor White
Write-Host "   - Verify notification channel configuration" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Alert Configuration Guide Completed!" -ForegroundColor Green
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Complete manual steps in SigNoz UI" -ForegroundColor White
Write-Host "   2. Test alert delivery" -ForegroundColor White
Write-Host "   3. Run final verification" -ForegroundColor White
Write-Host "   4. Monitor system performance" -ForegroundColor White
