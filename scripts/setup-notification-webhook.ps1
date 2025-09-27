# Master Notification Webhook Setup Script
# Sets up webhook notifications for OTel pipeline alerts

param(
    [ValidateSet("slack", "teams", "opsgenie", "webhook")]
    [string]$NotificationType = "slack",
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL,
    [switch]$TestOnly = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Notification Webhook Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check notification configuration
Write-Host "`nExamine: Checking notification configuration..." -ForegroundColor Green

$NotificationStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    notification_type = $NotificationType
    webhook_url = $WebhookUrl
    configured = $false
    test_successful = $false
    recommendations = @()
}

# Clean: Set up notification based on type
Write-Host "`nClean: Setting up $NotificationType notifications..." -ForegroundColor Green

switch ($NotificationType) {
    "slack" {
        Write-Host "Setting up Slack notifications..." -ForegroundColor Yellow
        if (-not $env:SLACK_WEBHOOK_URL) {
            Write-Host "`n=== SLACK WEBHOOK SETUP ===" -ForegroundColor Cyan
            Write-Host "1. Go to your Slack workspace" -ForegroundColor White
            Write-Host "2. Navigate to Apps → Incoming Webhooks" -ForegroundColor White
            Write-Host "3. Click 'Add to Slack'" -ForegroundColor White
            Write-Host "4. Choose the channel: #alerts" -ForegroundColor White
            Write-Host "5. Copy the webhook URL" -ForegroundColor White
            Write-Host "6. Set environment variable:" -ForegroundColor White
            Write-Host "   `$env:SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter when Slack webhook is configured"
        }
        
        if ($env:SLACK_WEBHOOK_URL) {
            $NotificationStatus.webhook_url = $env:SLACK_WEBHOOK_URL
            $NotificationStatus.configured = $true
            
            # Test Slack webhook
            try {
                $SlackPayload = @{
                    channel = "#alerts"
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
                                }
                            )
                            footer = "OTel Pipeline Monitor"
                            ts = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
                        }
                    )
                }
                
                $SlackResponse = Invoke-RestMethod -Uri $env:SLACK_WEBHOOK_URL -Method POST -Body ($SlackPayload | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 10
                
                if ($SlackResponse -eq "ok") {
                    Write-Host "  ✅ Slack webhook test successful" -ForegroundColor Green
                    $NotificationStatus.test_successful = $true
                }
            } catch {
                Write-Host "  ❌ Slack webhook test failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    "teams" {
        Write-Host "Setting up Microsoft Teams notifications..." -ForegroundColor Yellow
        if (-not $env:TEAMS_WEBHOOK_URL) {
            Write-Host "`n=== MICROSOFT TEAMS WEBHOOK SETUP ===" -ForegroundColor Cyan
            Write-Host "1. Open Microsoft Teams" -ForegroundColor White
            Write-Host "2. Navigate to the channel: OTel Alerts" -ForegroundColor White
            Write-Host "3. Click the three dots (...) next to the channel name" -ForegroundColor White
            Write-Host "4. Select 'Connectors'" -ForegroundColor White
            Write-Host "5. Find 'Incoming Webhook' and click 'Configure'" -ForegroundColor White
            Write-Host "6. Fill in the details and copy the webhook URL" -ForegroundColor White
            Write-Host "7. Set environment variable:" -ForegroundColor White
            Write-Host "   `$env:TEAMS_WEBHOOK_URL = 'https://your-org.webhook.office.com/webhookb2/...'" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter when Teams webhook is configured"
        }
        
        if ($env:TEAMS_WEBHOOK_URL) {
            $NotificationStatus.webhook_url = $env:TEAMS_WEBHOOK_URL
            $NotificationStatus.configured = $true
            
            # Test Teams webhook
            try {
                $TeamsPayload = @{
                    "@type" = "MessageCard"
                    "@context" = "http://schema.org/extensions"
                    themeColor = "00FF00"
                    summary = "OTel Pipeline Alert Test"
                    sections = @(
                        @{
                            activityTitle = "🔔 OTel Pipeline Alert Test"
                            activitySubtitle = "Observability Pipeline Monitor"
                            facts = @(
                                @{
                                    name = "Status"
                                    value = "Pipeline Test Alert"
                                },
                                @{
                                    name = "Timestamp"
                                    value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
                                }
                            )
                            markdown = $true
                        }
                    )
                }
                
                $TeamsResponse = Invoke-RestMethod -Uri $env:TEAMS_WEBHOOK_URL -Method POST -Body ($TeamsPayload | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 10
                
                Write-Host "  ✅ Teams webhook test successful" -ForegroundColor Green
                $NotificationStatus.test_successful = $true
            } catch {
                Write-Host "  ❌ Teams webhook test failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    "opsgenie" {
        Write-Host "Setting up OpsGenie notifications..." -ForegroundColor Yellow
        if (-not $env:OPSGENIE_API_KEY -or -not $env:OPSGENIE_WEBHOOK_URL) {
            Write-Host "`n=== OPSGENIE SETUP ===" -ForegroundColor Cyan
            Write-Host "1. Log in to OpsGenie" -ForegroundColor White
            Write-Host "2. Navigate to Settings → Integrations" -ForegroundColor White
            Write-Host "3. Click 'Add Integration' → 'Webhook'" -ForegroundColor White
            Write-Host "4. Configure the webhook and copy the URL and API key" -ForegroundColor White
            Write-Host "5. Set environment variables:" -ForegroundColor White
            Write-Host "   `$env:OPSGENIE_API_KEY = 'your-api-key'" -ForegroundColor Yellow
            Write-Host "   `$env:OPSGENIE_WEBHOOK_URL = 'https://api.opsgenie.com/v1/alerts'" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Press Enter when OpsGenie is configured"
        }
        
        if ($env:OPSGENIE_API_KEY -and $env:OPSGENIE_WEBHOOK_URL) {
            $NotificationStatus.webhook_url = $env:OPSGENIE_WEBHOOK_URL
            $NotificationStatus.configured = $true
            
            # Test OpsGenie webhook
            try {
                $OpsGeniePayload = @{
                    message = "OTel Pipeline Alert Test"
                    alias = "otel-pipeline-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                    description = "Test alert from OTel observability pipeline"
                    priority = "P3"
                    tags = @("otel", "pipeline", "test")
                }
                
                $Headers = @{
                    "Authorization" = "GenieKey $env:OPSGENIE_API_KEY"
                    "Content-Type" = "application/json"
                }
                
                $OpsGenieResponse = Invoke-RestMethod -Uri $env:OPSGENIE_WEBHOOK_URL -Method POST -Headers $Headers -Body ($OpsGeniePayload | ConvertTo-Json -Depth 10) -TimeoutSec 10
                
                Write-Host "  ✅ OpsGenie webhook test successful" -ForegroundColor Green
                $NotificationStatus.test_successful = $true
            } catch {
                Write-Host "  ❌ OpsGenie webhook test failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    "webhook" {
        Write-Host "Setting up generic webhook notifications..." -ForegroundColor Yellow
        if ($WebhookUrl) {
            $NotificationStatus.webhook_url = $WebhookUrl
            $NotificationStatus.configured = $true
            
            # Test generic webhook
            try {
                $GenericPayload = @{
                    message = "OTel Pipeline Alert Test"
                    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    source = "otel-pipeline"
                    test = $true
                }
                
                $Headers = @{
                    "Content-Type" = "application/json"
                }
                
                # Add Host header if it's the known endpoint
                if ($WebhookUrl -like "*192.168.0.76:3003*") {
                    $Headers["Host"] = "localhost:3003"
                }
                
                $GenericResponse = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Headers $Headers -Body ($GenericPayload | ConvertTo-Json -Depth 10) -TimeoutSec 10
                
                Write-Host "  ✅ Generic webhook test successful" -ForegroundColor Green
                $NotificationStatus.test_successful = $true
            } catch {
                Write-Host "  ❌ Generic webhook test failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  ❌ No webhook URL provided" -ForegroundColor Red
            $NotificationStatus.recommendations += "Set ALERT_WEBHOOK_URL environment variable"
        }
    }
}

# Report: Generate notification status report
Write-Host "`nReport: Notification status summary" -ForegroundColor Green

Write-Host "`nNotification Status:" -ForegroundColor Cyan
Write-Host "  Type: $NotificationType" -ForegroundColor Cyan
Write-Host "  Configured: $(if ($NotificationStatus.configured) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($NotificationStatus.configured) { 'Green' } else { 'Red' })
Write-Host "  Test Result: $(if ($NotificationStatus.test_successful) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($NotificationStatus.test_successful) { 'Green' } else { 'Red' })

if ($NotificationStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $NotificationStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save notification status report
$NotificationStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/notification-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/notification-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($NotificationStatus.test_successful) {
    Write-Host "Next: $NotificationType notifications configured successfully" -ForegroundColor Green
    Write-Host "Then: Configure alert rules in SigNoz to send alerts" -ForegroundColor Green
} else {
    Write-Host "Next: Complete $NotificationType setup and test delivery" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify integration" -ForegroundColor Yellow
}

# Usage examples
Write-Host "`n=== USAGE EXAMPLES ===" -ForegroundColor Cyan
Write-Host "Slack: pwsh -File scripts/setup-notification-webhook.ps1 -NotificationType slack" -ForegroundColor Yellow
Write-Host "Teams: pwsh -File scripts/setup-notification-webhook.ps1 -NotificationType teams" -ForegroundColor Yellow
Write-Host "OpsGenie: pwsh -File scripts/setup-notification-webhook.ps1 -NotificationType opsgenie" -ForegroundColor Yellow
Write-Host "Generic: pwsh -File scripts/setup-notification-webhook.ps1 -NotificationType webhook" -ForegroundColor Yellow
