# Configure Webhook URL for Alert Notifications
# Set up environment variables for webhook notifications
# Cursor-Local: Observability Copilot

param(
    [string]$WebhookUrl,
    [string]$Channel = "otel-alerts",
    [switch]$Persistent = $false,
    [switch]$Test = $false
)

Write-Host "🔔 Configuring Webhook URL for Alert Notifications" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# ECRR: Examine → Clean → Report → Role
Write-Host "🔍 ECRR Framework: Webhook URL Configuration" -ForegroundColor Yellow

$ArtifactsDir = "artifacts"
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -ItemType Directory -Path $ArtifactsDir | Out-Null
}

# Check if webhook URL is provided
if (-not $WebhookUrl) {
    Write-Host "⚠️ No webhook URL provided. Please provide a webhook URL." -ForegroundColor Yellow
    Write-Host "`n📋 Usage Examples:" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan
    Write-Host "Slack: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" -ForegroundColor White
    Write-Host "Teams: https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK" -ForegroundColor White
    Write-Host "Discord: https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK" -ForegroundColor White
    Write-Host "`n🔧 Command Examples:" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "pwsh -File scripts/configure-webhook-url.ps1 -WebhookUrl 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'" -ForegroundColor Gray
    Write-Host "pwsh -File scripts/configure-webhook-url.ps1 -WebhookUrl 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK' -Persistent" -ForegroundColor Gray
    Write-Host "pwsh -File scripts/configure-webhook-url.ps1 -WebhookUrl 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK' -Test" -ForegroundColor Gray
    
    # Show current environment variables
    Write-Host "`n📊 Current Environment Variables:" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    $CurrentWebhook = $env:ALERT_WEBHOOK_URL
    $CurrentChannel = $env:ALERT_CHANNEL
    
    if ($CurrentWebhook) {
        Write-Host "✅ ALERT_WEBHOOK_URL: $($CurrentWebhook.Substring(0, [Math]::Min(50, $CurrentWebhook.Length)))..." -ForegroundColor Green
    } else {
        Write-Host "❌ ALERT_WEBHOOK_URL: Not set" -ForegroundColor Red
    }
    
    if ($CurrentChannel) {
        Write-Host "✅ ALERT_CHANNEL: $CurrentChannel" -ForegroundColor Green
    } else {
        Write-Host "❌ ALERT_CHANNEL: Not set" -ForegroundColor Red
    }
    
    exit 0
}

# Validate webhook URL format
Write-Host "🔍 Validating webhook URL format..." -ForegroundColor Yellow
if ($WebhookUrl -notmatch "^https?://") {
    Write-Host "❌ Invalid webhook URL format. Must start with http:// or https://" -ForegroundColor Red
    exit 1
}

# Set environment variables
Write-Host "🔧 Setting environment variables..." -ForegroundColor Yellow
$env:ALERT_WEBHOOK_URL = $WebhookUrl
$env:ALERT_CHANNEL = $Channel

Write-Host "✅ Environment variables set:" -ForegroundColor Green
Write-Host "   ALERT_WEBHOOK_URL: $($WebhookUrl.Substring(0, [Math]::Min(50, $WebhookUrl.Length)))..." -ForegroundColor Gray
Write-Host "   ALERT_CHANNEL: $Channel" -ForegroundColor Gray

# Make persistent if requested
if ($Persistent) {
    Write-Host "`n💾 Making environment variables persistent..." -ForegroundColor Yellow
    
    # Set user environment variables
    [Environment]::SetEnvironmentVariable("ALERT_WEBHOOK_URL", $WebhookUrl, "User")
    [Environment]::SetEnvironmentVariable("ALERT_CHANNEL", $Channel, "User")
    
    Write-Host "✅ Environment variables set persistently for user" -ForegroundColor Green
    Write-Host "   Note: Restart PowerShell to see changes in new sessions" -ForegroundColor Gray
}

# Save configuration
$WebhookConfig = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    webhook_url = $WebhookUrl
    channel = $Channel
    persistent = $Persistent
    environment_variables = @{
        ALERT_WEBHOOK_URL = $WebhookUrl
        ALERT_CHANNEL = $Channel
    }
}

$WebhookConfig | ConvertTo-Json -Depth 3 | Set-Content -Path "$ArtifactsDir/webhook-url-config.json"
Write-Host "📁 Configuration saved to: $ArtifactsDir/webhook-url-config.json" -ForegroundColor Yellow

# Test webhook if requested
if ($Test) {
    Write-Host "`n🧪 Testing webhook notification..." -ForegroundColor Yellow
    
    $TestPayload = @{
        text = "🧪 Test notification from OTel Observability Pipeline"
        attachments = @(
            @{
                color = "good"
                fields = @(
                    @{
                        title = "Test"
                        value = "Webhook notification test"
                        short = $true
                    },
                    @{
                        title = "Timestamp"
                        value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        short = $true
                    },
                    @{
                        title = "Channel"
                        value = $Channel
                        short = $true
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 3
    
    try {
        $Response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $TestPayload -ContentType "application/json" -TimeoutSec 10
        Write-Host "✅ Webhook test successful!" -ForegroundColor Green
        Write-Host "   Response: $Response" -ForegroundColor Gray
    } catch {
        Write-Host "❌ Webhook test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Check your webhook URL and try again" -ForegroundColor Yellow
    }
}

# Create webhook status script
Write-Host "`n📝 Creating webhook status script..." -ForegroundColor Yellow

$StatusScript = @"
# Webhook Status Check Script
# Check current webhook configuration and test connectivity

Write-Host "🔔 Webhook Status Check" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Check environment variables
`$WebhookUrl = `$env:ALERT_WEBHOOK_URL
`$Channel = `$env:ALERT_CHANNEL

if (`$WebhookUrl) {
    Write-Host "✅ ALERT_WEBHOOK_URL: `$(`$WebhookUrl.Substring(0, [Math]::Min(50, `$WebhookUrl.Length)))..." -ForegroundColor Green
} else {
    Write-Host "❌ ALERT_WEBHOOK_URL: Not set" -ForegroundColor Red
}

if (`$Channel) {
    Write-Host "✅ ALERT_CHANNEL: `$Channel" -ForegroundColor Green
} else {
    Write-Host "❌ ALERT_CHANNEL: Not set" -ForegroundColor Red
}

# Test webhook connectivity
if (`$WebhookUrl) {
    Write-Host "`n🧪 Testing webhook connectivity..." -ForegroundColor Yellow
    
    `$TestPayload = @{
        text = "🔍 Connectivity test from OTel Observability Pipeline"
        attachments = @(
            @{
                color = "good"
                fields = @(
                    @{
                        title = "Test"
                        value = "Connectivity test"
                        short = `$true
                    },
                    @{
                        title = "Timestamp"
                        value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                        short = `$true
                    }
                )
            }
        )
    } | ConvertTo-Json -Depth 3
    
    try {
        `$Response = Invoke-RestMethod -Uri `$WebhookUrl -Method Post -Body `$TestPayload -ContentType "application/json" -TimeoutSec 10
        Write-Host "✅ Webhook connectivity test successful!" -ForegroundColor Green
    } catch {
        Write-Host "❌ Webhook connectivity test failed: `$(`$_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`n⚠️ No webhook URL configured. Run configure-webhook-url.ps1 to set up." -ForegroundColor Yellow
}
"@

$StatusScript | Set-Content -Path "scripts/webhook-status.ps1"
Write-Host "📝 Status script created: scripts/webhook-status.ps1" -ForegroundColor Yellow

# ECRR Report
$ECRRReport = @"
# Webhook URL Configuration - ECRR Report
**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Actor**: Cursor-Local (Observability Copilot)

## Examine
- Webhook URL: $(if ($WebhookUrl) { "Configured" } else { "Not configured" })
- Channel: $Channel
- Persistent: $Persistent
- Test: $Test

## Clean
- Set environment variables for webhook notifications
- Created configuration file and status script
- Tested webhook connectivity (if requested)

## Report
- Configuration: $ArtifactsDir/webhook-url-config.json
- Status script: scripts/webhook-status.ps1
- Environment variables: ALERT_WEBHOOK_URL, ALERT_CHANNEL
- Test result: $(if ($Test) { "Completed" } else { "Skipped" })

## Role
Cursor-Local: Observability Copilot - Webhook URL configuration and testing
"@

$ECRRReport | Set-Content -Path "$ArtifactsDir/webhook-url-config-ecrr.md"

Write-Host "`n📁 ECRR Report saved to: $ArtifactsDir/webhook-url-config-ecrr.md" -ForegroundColor Magenta

Write-Host "`n🎉 Webhook URL Configuration Complete!" -ForegroundColor Green
Write-Host "🔔 Webhook URL: $($WebhookUrl.Substring(0, [Math]::Min(50, $WebhookUrl.Length)))..." -ForegroundColor Blue
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Check status: pwsh -File scripts/webhook-status.ps1" -ForegroundColor White
Write-Host "   2. Test webhook: pwsh -File scripts/test-webhook.ps1" -ForegroundColor White
Write-Host "   3. Deploy alerts: pwsh -File scripts/integrate-webhook-alerts.ps1" -ForegroundColor White
