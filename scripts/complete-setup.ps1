# Complete Setup Script
# Guides user through manual setup steps with verification

param(
    [switch]$SkipSigNozAuth = $false,
    [switch]$SkipWebhookConfig = $false,
    [switch]$SkipDashboardImport = $false,
    [switch]$SkipResonaiStartup = $false,
    [switch]$SkipWebhookTest = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Complete Setup Guide - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check current system status
Write-Host "`nExamine: Checking current system status..." -ForegroundColor Green

$SetupStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    signoz_ui_accessible = $false
    signoz_api_token_set = $false
    webhook_url_set = $false
    dashboard_file_exists = $false
    resonai_running = $false
    otel_collector_running = $false
    recommendations = @()
}

# Check SigNoz UI accessibility
Write-Host "Checking SigNoz UI accessibility..." -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  OK SigNoz UI accessible" -ForegroundColor Green
        $SetupStatus.signoz_ui_accessible = $true
    }
} catch {
    Write-Host "  ERROR SigNoz UI not accessible" -ForegroundColor Red
    $SetupStatus.recommendations += "Start SigNoz stack (docker-compose up)"
}

# Check API token
Write-Host "Checking SigNoz API token..." -ForegroundColor Yellow
if ($env:SIGNOZ_API_TOKEN) {
    Write-Host "  OK API token is set" -ForegroundColor Green
    $SetupStatus.signoz_api_token_set = $true
} else {
    Write-Host "  ERROR API token not set" -ForegroundColor Red
    $SetupStatus.recommendations += "Set SIGNOZ_API_TOKEN environment variable"
}

# Check webhook URL
Write-Host "Checking webhook URL..." -ForegroundColor Yellow
if ($env:ALERT_WEBHOOK_URL) {
    Write-Host "  OK Webhook URL is set" -ForegroundColor Green
    $SetupStatus.webhook_url_set = $true
} else {
    Write-Host "  ERROR Webhook URL not set" -ForegroundColor Red
    $SetupStatus.recommendations += "Set ALERT_WEBHOOK_URL environment variable"
}

# Check dashboard file
Write-Host "Checking dashboard file..." -ForegroundColor Yellow
if (Test-Path "artifacts/signoz-queue-pressure-dashboard.json") {
    Write-Host "  OK Dashboard file exists" -ForegroundColor Green
    $SetupStatus.dashboard_file_exists = $true
} else {
    Write-Host "  ERROR Dashboard file not found" -ForegroundColor Red
    $SetupStatus.recommendations += "Create dashboard configuration file"
}

# Check Resonai status
Write-Host "Checking Resonai status..." -ForegroundColor Yellow
$PortCheck = netstat -an | Select-String ":3003 "
if ($PortCheck) {
    Write-Host "  OK Resonai is running on port 3003" -ForegroundColor Green
    $SetupStatus.resonai_running = $true
} else {
    Write-Host "  ERROR Resonai not running on port 3003" -ForegroundColor Red
    $SetupStatus.recommendations += "Start Resonai application on port 3003"
}

# Check OTel collector
Write-Host "Checking OTel collector..." -ForegroundColor Yellow
try {
    $CollectorHealth = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if ($CollectorHealth.status -eq "Server available") {
        Write-Host "  OK OTel collector is running" -ForegroundColor Green
        $SetupStatus.otel_collector_running = $true
    }
} catch {
    Write-Host "  ERROR OTel collector not accessible" -ForegroundColor Red
    $SetupStatus.recommendations += "Start OTel collector service"
}

# Clean: Provide setup guidance
Write-Host "`nClean: Setup guidance and next steps..." -ForegroundColor Green

if (-not $SkipSigNozAuth -and -not $SetupStatus.signoz_api_token_set) {
    Write-Host "`n=== SIGNOZ AUTHENTICATION SETUP ===" -ForegroundColor Cyan
    Write-Host "1. Open browser: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Navigate to Settings → API Keys" -ForegroundColor White
    Write-Host "3. Generate new API key with read permissions" -ForegroundColor White
    Write-Host "4. Set environment variable:" -ForegroundColor White
    Write-Host "   `$env:SIGNOZ_API_TOKEN = 'your-api-token-here'" -ForegroundColor Yellow
    Write-Host "5. Test authentication:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/test-signoz-auth.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter when SigNoz authentication is complete"
}

if (-not $SkipWebhookConfig -and -not $SetupStatus.webhook_url_set) {
    Write-Host "`n=== WEBHOOK CONFIGURATION ===" -ForegroundColor Cyan
    Write-Host "Choose webhook service:" -ForegroundColor White
    Write-Host "1. Slack: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" -ForegroundColor Yellow
    Write-Host "2. Discord: https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK" -ForegroundColor Yellow
    Write-Host "3. Local: http://localhost:3003/api/webhooks/alerts" -ForegroundColor Yellow
    Write-Host "4. Set environment variable:" -ForegroundColor White
    Write-Host "   `$env:ALERT_WEBHOOK_URL = 'your-webhook-url'" -ForegroundColor Yellow
    Write-Host "5. Test webhook:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/test-webhook.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter when webhook configuration is complete"
}

if (-not $SkipDashboardImport -and $SetupStatus.dashboard_file_exists) {
    Write-Host "`n=== DASHBOARD IMPORT ===" -ForegroundColor Cyan
    Write-Host "1. Open SigNoz UI: http://localhost:8080" -ForegroundColor White
    Write-Host "2. Navigate to Dashboards → Import Dashboard" -ForegroundColor White
    Write-Host "3. Upload file: C:\otel\artifacts\signoz-queue-pressure-dashboard.json" -ForegroundColor White
    Write-Host "4. Verify dashboard: OTel Queue Pressure Monitor" -ForegroundColor White
    Write-Host "5. Check panels are displaying data" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter when dashboard import is complete"
}

if (-not $SkipResonaiStartup -and -not $SetupStatus.resonai_running) {
    Write-Host "`n=== RESONAI STARTUP ===" -ForegroundColor Cyan
    Write-Host "1. Navigate to Resonai project directory" -ForegroundColor White
    Write-Host "2. Install dependencies: npm install" -ForegroundColor White
    Write-Host "3. Start development server: npm run dev" -ForegroundColor White
    Write-Host "4. Verify startup on port 3003" -ForegroundColor White
    Write-Host "5. Test verification:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/verify-resonai.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter when Resonai startup is complete"
}

if (-not $SkipWebhookTest) {
    Write-Host "`n=== WEBHOOK TESTING ===" -ForegroundColor Cyan
    Write-Host "Testing webhook notifications..." -ForegroundColor White
    
    if ($env:ALERT_WEBHOOK_URL) {
        try {
            pwsh -File scripts/test-webhook.ps1 -TestMessage "Complete setup test alert"
            Write-Host "Webhook test completed" -ForegroundColor Green
        } catch {
            Write-Host "Webhook test failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Skipping webhook test - URL not configured" -ForegroundColor Yellow
    }
}

# Report: Generate setup status report
Write-Host "`nReport: Setup status summary" -ForegroundColor Green

Write-Host "`nSetup Status:" -ForegroundColor Cyan
Write-Host "  SigNoz UI: $(if ($SetupStatus.signoz_ui_accessible) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($SetupStatus.signoz_ui_accessible) { 'Green' } else { 'Red' })
Write-Host "  API Token: $(if ($SetupStatus.signoz_api_token_set) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($SetupStatus.signoz_api_token_set) { 'Green' } else { 'Red' })
Write-Host "  Webhook URL: $(if ($SetupStatus.webhook_url_set) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($SetupStatus.webhook_url_set) { 'Green' } else { 'Red' })
Write-Host "  Dashboard File: $(if ($SetupStatus.dashboard_file_exists) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($SetupStatus.dashboard_file_exists) { 'Green' } else { 'Red' })
Write-Host "  Resonai Running: $(if ($SetupStatus.resonai_running) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($SetupStatus.resonai_running) { 'Green' } else { 'Red' })
Write-Host "  OTel Collector: $(if ($SetupStatus.otel_collector_running) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($SetupStatus.otel_collector_running) { 'Green' } else { 'Red' })

if ($SetupStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $SetupStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save setup status report
$SetupStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/setup-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/setup-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

$AllComplete = $SetupStatus.signoz_ui_accessible -and $SetupStatus.signoz_api_token_set -and $SetupStatus.webhook_url_set -and $SetupStatus.dashboard_file_exists -and $SetupStatus.resonai_running -and $SetupStatus.otel_collector_running

if ($AllComplete) {
    Write-Host "Next: All setup steps completed - system ready for monitoring" -ForegroundColor Green
    Write-Host "Then: Configure alert thresholds and test end-to-end delivery" -ForegroundColor Green
} else {
    Write-Host "Next: Complete remaining setup steps manually" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify completion" -ForegroundColor Yellow
}
