# Webhook Configuration Script
# Sets up webhook notifications for SigNoz alerts

param(
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL,
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN,
    [switch]$TestOnly = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Webhook Configuration Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check webhook configuration status
Write-Host "`nExamine: Checking webhook configuration status..." -ForegroundColor Green

$WebhookStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    webhook_url = $WebhookUrl
    signoz_url = $SigNozUrl
    api_token_set = $false
    webhook_url_set = $false
    webhook_test_successful = $false
    recommendations = @()
}

# Check if API token is set
Write-Host "Checking SigNoz API token..." -ForegroundColor Yellow
if ($ApiToken) {
    Write-Host "  ✅ API token is set" -ForegroundColor Green
    $WebhookStatus.api_token_set = $true
} else {
    Write-Host "  ❌ API token not set" -ForegroundColor Red
    $WebhookStatus.recommendations += "Set SIGNOZ_API_TOKEN environment variable"
}

# Check if webhook URL is set
Write-Host "Checking webhook URL..." -ForegroundColor Yellow
if ($WebhookUrl) {
    Write-Host "  ✅ Webhook URL is set: $WebhookUrl" -ForegroundColor Green
    $WebhookStatus.webhook_url_set = $true
} else {
    Write-Host "  ❌ Webhook URL not set" -ForegroundColor Red
    $WebhookStatus.recommendations += "Set ALERT_WEBHOOK_URL environment variable"
}

# Clean: Configure webhooks if prerequisites are met
if ($WebhookStatus.api_token_set -and $WebhookStatus.webhook_url_set) {
    Write-Host "`nClean: Configuring webhook notifications..." -ForegroundColor Green
    
    # Test webhook endpoint
    Write-Host "Testing webhook endpoint..." -ForegroundColor Yellow
    try {
        $TestPayload = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            test = $true
            message = "SigNoz webhook test from OTel pipeline"
            source = "otel-observability-pipeline"
            severity = "info"
        }
        
        $WebhookResponse = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body ($TestPayload | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
        
        Write-Host "  ✅ Webhook test successful" -ForegroundColor Green
        $WebhookStatus.webhook_test_successful = $true
    } catch {
        Write-Host "  ❌ Webhook test failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $WebhookStatus.recommendations += "Check webhook URL validity and endpoint accessibility"
    }
    
    # Configure SigNoz notification channels
    if ($WebhookStatus.webhook_test_successful) {
        Write-Host "Configuring SigNoz notification channels..." -ForegroundColor Yellow
        try {
            $Headers = @{
                "Authorization" = "Bearer $ApiToken"
                "Content-Type" = "application/json"
            }
            
            # Create notification channel
            $NotificationChannel = @{
                name = "OTel Pipeline Alerts"
                type = "webhook"
                settings = @{
                    url = $WebhookUrl
                    httpMethod = "POST"
                    title = "OTel Pipeline Alert"
                    text = "Alert: {{.Status}} - {{.AlertName}}"
                }
            }
            
            $ChannelResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/notificationChannels" -Method POST -Headers $Headers -Body ($NotificationChannel | ConvertTo-Json) -TimeoutSec 10
            
            if ($ChannelResponse) {
                Write-Host "  ✅ Notification channel created successfully" -ForegroundColor Green
                $WebhookStatus.notification_channel_id = $ChannelResponse.id
            }
        } catch {
            Write-Host "  ❌ Notification channel creation failed" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            $WebhookStatus.recommendations += "Check SigNoz API permissions for notification channels"
        }
    }
} else {
    Write-Host "`nClean: Prerequisites not met for webhook configuration" -ForegroundColor Yellow
    
    if (-not $WebhookStatus.webhook_url_set) {
        Write-Host "`n=== WEBHOOK URL SETUP ===" -ForegroundColor Cyan
        Write-Host "Choose webhook service:" -ForegroundColor White
        Write-Host "1. Slack: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" -ForegroundColor Yellow
        Write-Host "2. Discord: https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK" -ForegroundColor Yellow
        Write-Host "3. Teams: https://your-org.webhook.office.com/webhookb2/..." -ForegroundColor Yellow
        Write-Host "4. Local: http://localhost:3003/api/webhooks/alerts" -ForegroundColor Yellow
        Write-Host "5. Set environment variable:" -ForegroundColor White
        Write-Host "   `$env:ALERT_WEBHOOK_URL = 'your-webhook-url'" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter when webhook URL is configured"
    }
    
    if (-not $WebhookStatus.api_token_set) {
        Write-Host "`n=== API TOKEN SETUP ===" -ForegroundColor Cyan
        Write-Host "Run authentication setup first:" -ForegroundColor White
        Write-Host "pwsh -File scripts/setup-signoz-authentication.ps1" -ForegroundColor Yellow
    }
}

# Report: Generate webhook status report
Write-Host "`nReport: Webhook configuration status summary" -ForegroundColor Green

Write-Host "`nWebhook Status:" -ForegroundColor Cyan
Write-Host "  API Token: $(if ($WebhookStatus.api_token_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($WebhookStatus.api_token_set) { 'Green' } else { 'Red' })
Write-Host "  Webhook URL: $(if ($WebhookStatus.webhook_url_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($WebhookStatus.webhook_url_set) { 'Green' } else { 'Red' })
Write-Host "  Webhook Test: $(if ($WebhookStatus.webhook_test_successful) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($WebhookStatus.webhook_test_successful) { 'Green' } else { 'Red' })

if ($WebhookStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $WebhookStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save webhook status report
$WebhookStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/webhook-setup-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/webhook-setup-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($WebhookStatus.webhook_test_successful) {
    Write-Host "Next: Webhook configuration complete - test end-to-end pipeline" -ForegroundColor Green
    Write-Host "Then: Set up alert rules and test notification delivery" -ForegroundColor Green
} else {
    Write-Host "Next: Complete webhook URL configuration and test connectivity" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify webhook setup" -ForegroundColor Yellow
}

# Webhook testing guidance
if ($WebhookStatus.webhook_test_successful) {
    Write-Host "`n=== WEBHOOK TESTING ===" -ForegroundColor Cyan
    Write-Host "1. Test webhook notifications:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/test-webhook.ps1" -ForegroundColor Yellow
    Write-Host "2. Create test alerts in SigNoz" -ForegroundColor White
    Write-Host "3. Verify alert delivery to webhook endpoint" -ForegroundColor White
    Write-Host "4. Configure alert rules for queue pressure monitoring" -ForegroundColor White
}

# Alert configuration guidance
Write-Host "`n=== ALERT CONFIGURATION ===" -ForegroundColor Cyan
Write-Host "Recommended alerts for OTel pipeline:" -ForegroundColor White
Write-Host "1. Queue utilization > 80% for 5 minutes" -ForegroundColor Yellow
Write-Host "2. Send failure rate > 10% for 2 minutes" -ForegroundColor Yellow
Write-Host "3. Batch timeout triggers > 1/sec for 1 minute" -ForegroundColor Yellow
Write-Host "4. Log processing rate drops to 0 for 2 minutes" -ForegroundColor Yellow
Write-Host "5. OTel collector health check fails" -ForegroundColor Yellow
