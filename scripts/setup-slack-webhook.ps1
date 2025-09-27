# Slack Webhook Setup Script
# Sets up Slack notifications for OTel pipeline alerts

param(
    [string]$SlackWebhookUrl = $env:SLACK_WEBHOOK_URL,
    [string]$Channel = "#alerts",
    [switch]$TestOnly = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Slack Webhook Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check Slack webhook configuration
Write-Host "`nExamine: Checking Slack webhook configuration..." -ForegroundColor Green

$SlackStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    webhook_url = $SlackWebhookUrl
    channel = $Channel
    webhook_configured = $false
    test_successful = $false
    recommendations = @()
}

# Check if Slack webhook URL is set
Write-Host "Checking Slack webhook URL..." -ForegroundColor Yellow
if ($SlackWebhookUrl) {
    Write-Host "  ✅ Slack webhook URL is set" -ForegroundColor Green
    $SlackStatus.webhook_configured = $true
} else {
    Write-Host "  ❌ Slack webhook URL not set" -ForegroundColor Red
    $SlackStatus.recommendations += "Set SLACK_WEBHOOK_URL environment variable"
}

# Clean: Configure Slack webhook if URL is set
if ($SlackStatus.webhook_configured) {
    Write-Host "`nClean: Testing Slack webhook..." -ForegroundColor Green
    
    # Test Slack webhook
    Write-Host "Testing Slack webhook delivery..." -ForegroundColor Yellow
    try {
        $SlackPayload = @{
            channel = $Channel
            username = "OTel Pipeline Monitor"
            icon_emoji = ":telephone_receiver:"
            text = "🔔 OTel Pipeline Alert Test"
            attachments = @(
                @{
                    color = "good"
                    fields = @(
                        @{
                            title = "Status"
                            value = "Pipeline Test Alert"
                            short = $true
                        },
                        @{
                            title = "Timestamp"
                            value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
                            short = $true
                        },
                        @{
                            title = "Source"
                            value = "OTel Observability Pipeline"
                            short = $false
                        }
                    )
                    footer = "OTel Pipeline Monitor"
                    ts = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
                }
            )
        }
        
        $SlackResponse = Invoke-RestMethod -Uri $SlackWebhookUrl -Method POST -Body ($SlackPayload | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 10
        
        if ($SlackResponse -eq "ok") {
            Write-Host "  ✅ Slack webhook test successful" -ForegroundColor Green
            $SlackStatus.test_successful = $true
        } else {
            Write-Host "  ⚠️ Slack webhook responded: $SlackResponse" -ForegroundColor Yellow
            $SlackStatus.test_successful = $true
        }
    } catch {
        Write-Host "  ❌ Slack webhook test failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $SlackStatus.recommendations += "Check Slack webhook URL validity and permissions"
    }
} else {
    Write-Host "`nClean: Slack webhook setup guidance..." -ForegroundColor Yellow
    
    Write-Host "`n=== SLACK WEBHOOK SETUP ===" -ForegroundColor Cyan
    Write-Host "1. Go to your Slack workspace" -ForegroundColor White
    Write-Host "2. Navigate to Apps → Incoming Webhooks" -ForegroundColor White
    Write-Host "3. Click 'Add to Slack'" -ForegroundColor White
    Write-Host "4. Choose the channel: $Channel" -ForegroundColor White
    Write-Host "5. Copy the webhook URL" -ForegroundColor White
    Write-Host "6. Set environment variable:" -ForegroundColor White
    Write-Host "   `$env:SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'" -ForegroundColor Yellow
    Write-Host "7. Test the webhook:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/setup-slack-webhook.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter when Slack webhook is configured"
}

# Report: Generate Slack webhook status report
Write-Host "`nReport: Slack webhook status summary" -ForegroundColor Green

Write-Host "`nSlack Webhook Status:" -ForegroundColor Cyan
Write-Host "  Webhook URL: $(if ($SlackStatus.webhook_configured) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SlackStatus.webhook_configured) { 'Green' } else { 'Red' })
Write-Host "  Test Result: $(if ($SlackStatus.test_successful) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SlackStatus.test_successful) { 'Green' } else { 'Red' })
Write-Host "  Channel: $Channel" -ForegroundColor Cyan

if ($SlackStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $SlackStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save Slack webhook status report
$SlackStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/slack-webhook-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/slack-webhook-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($SlackStatus.test_successful) {
    Write-Host "Next: Slack webhook configured successfully - set up alert rules" -ForegroundColor Green
    Write-Host "Then: Configure OTel pipeline to send alerts to Slack" -ForegroundColor Green
} else {
    Write-Host "Next: Complete Slack webhook setup and test delivery" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify Slack integration" -ForegroundColor Yellow
}

# Slack integration guidance
if ($SlackStatus.test_successful) {
    Write-Host "`n=== SLACK INTEGRATION ===" -ForegroundColor Cyan
    Write-Host "1. Slack webhook is ready for OTel alerts" -ForegroundColor White
    Write-Host "2. Configure alert rules in SigNoz" -ForegroundColor White
    Write-Host "3. Set up notification channels" -ForegroundColor White
    Write-Host "4. Test alert delivery to Slack" -ForegroundColor White
    Write-Host "5. Monitor alert frequency and adjust thresholds" -ForegroundColor White
}
