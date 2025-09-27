# Complete Manual Setup Guide - ECRR Framework
# Actor: Cursor-Local (Observability Copilot)
# Purpose: Guide through remaining manual configuration steps

param(
    [string]$ApiToken = "",
    [switch]$SkipApiToken = $false,
    [switch]$SkipDashboard = $false,
    [switch]$SkipAlerts = $false,
    [switch]$RunVerification = $true
)

Write-Host "🔍 Complete Manual Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host ""

# Step 1: API Token Setup
if (-not $SkipApiToken) {
    Write-Host "📋 Step 1: SigNoz API Token Setup" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    
    if ($ApiToken -eq "") {
        Write-Host "❌ No API token provided. Please generate one in SigNoz UI:" -ForegroundColor Red
        Write-Host "   1. Open http://localhost:8080" -ForegroundColor Yellow
        Write-Host "   2. Go to Settings → API Tokens" -ForegroundColor Yellow
        Write-Host "   3. Create new token with 'Read' permissions" -ForegroundColor Yellow
        Write-Host "   4. Copy the token and run this script with -ApiToken 'your-token'" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Or set environment variable manually:" -ForegroundColor Cyan
        Write-Host "   `$env:SIGNOZ_API_TOKEN = 'your-api-token-here'" -ForegroundColor White
        Write-Host ""
        return
    }
    
    # Set environment variable
    $env:SIGNOZ_API_TOKEN = $ApiToken
    Write-Host "✅ API token set in environment variable" -ForegroundColor Green
    
    # Test API access
    try {
        $Headers = @{ "Authorization" = "Bearer $ApiToken" }
        $Response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Headers $Headers -TimeoutSec 5
        Write-Host "✅ API token validated successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ API token validation failed: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
} else {
    Write-Host "⏭️  Skipping API token setup" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Dashboard Import
if (-not $SkipDashboard) {
    Write-Host "📊 Step 2: Dashboard Import" -ForegroundColor Green
    Write-Host "===========================" -ForegroundColor Green
    
    $DashboardFile = "artifacts/signoz-queue-pressure-dashboard.json"
    if (Test-Path $DashboardFile) {
        Write-Host "✅ Dashboard configuration file found: $DashboardFile" -ForegroundColor Green
        Write-Host "📋 Manual import steps:" -ForegroundColor Cyan
        Write-Host "   1. Open http://localhost:8080" -ForegroundColor Yellow
        Write-Host "   2. Go to Dashboards → Import" -ForegroundColor Yellow
        Write-Host "   3. Upload file: $DashboardFile" -ForegroundColor Yellow
        Write-Host "   4. Name: 'OTel Queue Pressure Monitoring'" -ForegroundColor Yellow
        Write-Host "   5. Click 'Import'" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "   Dashboard contains 5 panels:" -ForegroundColor Cyan
        Write-Host "   - Queue Utilization Ratio" -ForegroundColor White
        Write-Host "   - Queue Size vs Capacity" -ForegroundColor White
        Write-Host "   - Send Failure Rate" -ForegroundColor White
        Write-Host "   - Batch Timeout Triggers" -ForegroundColor White
        Write-Host "   - Log Processing Rate" -ForegroundColor White
    } else {
        Write-Host "❌ Dashboard configuration file not found: $DashboardFile" -ForegroundColor Red
    }
} else {
    Write-Host "⏭️  Skipping dashboard import" -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Alert Configuration
if (-not $SkipAlerts) {
    Write-Host "🚨 Step 3: Alert Configuration" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    
    Write-Host "📋 Manual alert setup steps:" -ForegroundColor Cyan
    Write-Host "   1. Open http://localhost:8080" -ForegroundColor Yellow
    Write-Host "   2. Go to Alerts → Alert Rules" -ForegroundColor Yellow
    Write-Host "   3. Create new alert rule:" -ForegroundColor Yellow
    Write-Host "      - Name: 'Queue Utilization High'" -ForegroundColor White
    Write-Host "      - Query: otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100" -ForegroundColor White
    Write-Host "      - Condition: > 80" -ForegroundColor White
    Write-Host "      - Duration: 5m" -ForegroundColor White
    Write-Host "   4. Add notification channel:" -ForegroundColor Yellow
    Write-Host "      - Type: Webhook" -ForegroundColor White
    Write-Host "      - URL: http://localhost:3003/api/webhooks/alerts" -ForegroundColor White
    Write-Host "      - Method: POST" -ForegroundColor White
    Write-Host "   5. Save alert rule" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Additional alerts to configure:" -ForegroundColor Cyan
    Write-Host "   - Send Failure Rate > 5%" -ForegroundColor White
    Write-Host "   - Batch Timeout Triggers > 10/min" -ForegroundColor White
    Write-Host "   - Log Processing Rate < 100/min" -ForegroundColor White
} else {
    Write-Host "⏭️  Skipping alert configuration" -ForegroundColor Yellow
}

Write-Host ""

# Step 4: Final Verification
if ($RunVerification) {
    Write-Host "🔍 Step 4: Final Verification" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    
    Write-Host "Running component verification..." -ForegroundColor Cyan
    try {
        & "scripts/verify-all-components.ps1"
        Write-Host "✅ Component verification completed" -ForegroundColor Green
    } catch {
        Write-Host "❌ Component verification failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Running end-to-end test..." -ForegroundColor Cyan
    try {
        & "scripts/end-to-end-test.ps1"
        Write-Host "✅ End-to-end test completed" -ForegroundColor Green
    } catch {
        Write-Host "❌ End-to-end test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⏭️  Skipping final verification" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 Manual Setup Summary" -ForegroundColor Green
Write-Host "=======================" -ForegroundColor Green
Write-Host "✅ API Token: $(-not $SkipApiToken)" -ForegroundColor $(if (-not $SkipApiToken) { "Green" } else { "Yellow" })
Write-Host "✅ Dashboard: $(-not $SkipDashboard)" -ForegroundColor $(if (-not $SkipDashboard) { "Green" } else { "Yellow" })
Write-Host "✅ Alerts: $(-not $SkipAlerts)" -ForegroundColor $(if (-not $SkipAlerts) { "Green" } else { "Yellow" })
Write-Host "✅ Verification: $RunVerification" -ForegroundColor $(if ($RunVerification) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Complete manual steps in SigNoz UI" -ForegroundColor Yellow
Write-Host "   2. Verify dashboard is imported and working" -ForegroundColor Yellow
Write-Host "   3. Test alert delivery with webhook server" -ForegroundColor Yellow
Write-Host "   4. Monitor system performance and metrics" -ForegroundColor Yellow

Write-Host ""
Write-Host "🔗 Useful URLs:" -ForegroundColor Cyan
Write-Host "   - SigNoz UI: http://localhost:8080" -ForegroundColor White
Write-Host "   - Resonai App: http://localhost:3000" -ForegroundColor White
Write-Host "   - Webhook Server: http://localhost:3003" -ForegroundColor White
Write-Host "   - OTel Collector: http://localhost:13134" -ForegroundColor White

Write-Host ""
Write-Host "📁 Configuration Files:" -ForegroundColor Cyan
Write-Host "   - Dashboard: artifacts/signoz-queue-pressure-dashboard.json" -ForegroundColor White
Write-Host "   - Webhook Logs: artifacts/webhook-logs.json" -ForegroundColor White
Write-Host "   - Component Report: artifacts/component-verification-report.json" -ForegroundColor White

Write-Host ""
Write-Host "🎉 Manual setup guide completed!" -ForegroundColor Green
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
