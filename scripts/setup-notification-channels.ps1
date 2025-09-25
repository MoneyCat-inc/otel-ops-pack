#Requires -Version 7.0

<#
.SYNOPSIS
    Setup notification channels for SigNoz alerts

.DESCRIPTION
    This script provides instructions and templates for setting up notification
    channels in SigNoz for Windows Logs Canary alerts and other observability alerts.

.PARAMETER ChannelType
    Type of notification channel to configure (email, slack, teams, webhook)

.PARAMETER TestMode
    Show configuration examples without actually creating channels
#>

param(
    [ValidateSet("email", "slack", "teams", "webhook", "all")]
    [string]$ChannelType = "all",
    [switch]$TestMode
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

Write-Info "🔔 SigNoz Notification Channels Setup"
Write-Info "====================================="

$configFile = "signoz-notification-channels.json"

if (-not (Test-Path $configFile)) {
    Write-Error "Configuration file not found: $configFile"
    exit 1
}

try {
    $config = Get-Content -Path $configFile -Raw | ConvertFrom-Json
    
    Write-Info "📋 Available Notification Channels:"
    foreach ($channel in $config.notificationChannels) {
        $status = if ($channel.enabled) { "✅ Enabled" } else { "❌ Disabled" }
        Write-Info "  • $($channel.name) ($($channel.type)) - $status"
    }
    
    Write-Info "`n📝 Manual Setup Instructions for SigNoz UI:"
    Write-Info "==========================================="
    
    if ($ChannelType -eq "all" -or $ChannelType -eq "email") {
        Write-Info "`n📧 Email Notification Channel:"
        Write-Info "1. Open SigNoz UI: http://localhost:8080"
        Write-Info "2. Navigate to: Settings → Notification Channels"
        Write-Info "3. Click 'Create Channel' → Select 'Email'"
        Write-Info "4. Configure:"
        Write-Info "   • Name: Email-Alerts"
        Write-Info "   • SMTP Host: smtp.company.com"
        Write-Info "   • Port: 587"
        Write-Info "   • Username: alerts@company.com"
        Write-Info "   • Password: [your SMTP password]"
        Write-Info "   • To: admin@company.com, ops@company.com"
        Write-Info "   • Subject: [SigNoz Alert] {{ .GroupLabels.alertname }}"
        Write-Info "   • Body: Alert: {{ .GroupLabels.alertname }}`nSeverity: {{ .GroupLabels.severity }}`nStatus: {{ .Status }}"
    }
    
    if ($ChannelType -eq "all" -or $ChannelType -eq "slack") {
        Write-Info "`n💬 Slack Notification Channel:"
        Write-Info "1. Create Slack webhook: https://api.slack.com/messaging/webhooks"
        Write-Info "2. In SigNoz UI: Settings → Notification Channels"
        Write-Info "3. Click 'Create Channel' → Select 'Slack'"
        Write-Info "4. Configure:"
        Write-Info "   • Name: Slack-Ops"
        Write-Info "   • Webhook URL: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
        Write-Info "   • Channel: #ops-alerts"
        Write-Info "   • Title: 🚨 SigNoz Alert: {{ .GroupLabels.alertname }}"
        Write-Info "   • Message: {{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
    }
    
    if ($ChannelType -eq "all" -or $ChannelType -eq "teams") {
        Write-Info "`n📱 Microsoft Teams Notification Channel:"
        Write-Info "1. Create Teams webhook: https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors"
        Write-Info "2. In SigNoz UI: Settings → Notification Channels"
        Write-Info "3. Click 'Create Channel' → Select 'Teams'"
        Write-Info "4. Configure:"
        Write-Info "   • Name: Teams-Ops"
        Write-Info "   • Webhook URL: https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK"
        Write-Info "   • Title: 🚨 Windows Logs Canary Alert"
        Write-Info "   • Message: {{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
    }
    
    if ($ChannelType -eq "all" -or $ChannelType -eq "webhook") {
        Write-Info "`n🔗 Webhook Notification Channel:"
        Write-Info "1. Set up webhook endpoint to receive alerts"
        Write-Info "2. In SigNoz UI: Settings → Notification Channels"
        Write-Info "3. Click 'Create Channel' → Select 'Webhook'"
        Write-Info "4. Configure:"
        Write-Info "   • Name: Webhook-Generic"
        Write-Info "   • URL: http://localhost:8080/api/v1/webhook/alerts"
        Write-Info "   • Method: POST"
        Write-Info "   • Headers: Content-Type: application/json"
    }
    
    Write-Info "`n🔗 Link Channels to Windows Logs Canary Alert:"
    Write-Info "1. Navigate to: Alerts → Alert Rules"
    Write-Info "2. Find 'Windows Logs Canary Missing (1 Hour)'"
    Write-Info "3. Click 'Edit' → 'Notification Channels'"
    Write-Info "4. Select channels: Email-Alerts, Slack-Ops, Teams-Ops"
    Write-Info "5. Set repeat interval: 1 hour"
    Write-Info "6. Save changes"
    
    Write-Info "`n🧪 Test Notification Channels:"
    Write-Info "1. Temporarily lower alert threshold to trigger test"
    Write-Info "2. Or create test alert with short duration"
    Write-Info "3. Verify notifications are received"
    Write-Info "4. Restore original alert configuration"
    
    Write-Info "`n📊 Alert Group Configuration:"
    Write-Info "• Group Name: Windows-Logs-Canary"
    Write-Info "• Alerts: Windows Logs Canary Missing (1 Hour)"
    Write-Info "• Channels: Email-Alerts, Slack-Ops, Teams-Ops"
    Write-Info "• Repeat Interval: 1 hour"
    Write-Info "• Group Wait: 10 seconds"
    Write-Info "• Group Interval: 10 minutes"
    
    if ($TestMode) {
        Write-Info "`n🧪 Test Mode - Sample Alert Payload:"
        $sampleAlert = @{
            alertname = "Windows Logs Canary Missing (1 Hour)"
            severity = "warning"
            component = "windows-logs"
            canary = "true"
            duration = "1h"
            status = "firing"
            description = "No Windows Event Log canary entries found in the last hour"
            runbook_url = "http://localhost:8080/logs?query=attributes_string['dataset']%20%3D%20'windows'"
        } | ConvertTo-Json -Depth 2
        
        Write-Info $sampleAlert
    }
    
    Write-Success "`n✅ Notification channel setup instructions completed!"
    Write-Info "Next steps:"
    Write-Info "  • Configure channels in SigNoz UI"
    Write-Info "  • Link channels to Windows Logs Canary alert"
    Write-Info "  • Test notification delivery"
    Write-Info "  • Set up alert escalation procedures"
    
} catch {
    Write-Error "Error processing notification configuration: $($_.Exception.Message)"
    exit 1
}
