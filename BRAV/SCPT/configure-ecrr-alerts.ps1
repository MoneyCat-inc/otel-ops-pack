# Configure ECRR Alert Recipients
# This script helps configure alert recipients for ECRR compliance monitoring

param(
    [string]$EmailRecipients = "",
    [string]$SlackWebhook = "",
    [string]$SlackChannel = "#ecrr-compliance",
    [string]$OutputDir = "artifacts"
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR Alert Configuration" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Create enhanced alert configuration
$AlertConfig = @{
    thresholds = @{
        fourSectionPct = 95
        gatePct = 90
    }
    monitoring = @{
        trendWindow = "7d"
        alertCooldown = "24h"
        checkInterval = "daily"
    }
    notifications = @{
        email = $EmailRecipients
        type = if ($EmailRecipients) { "Email" } elseif ($SlackWebhook) { "Slack" } else { "None" }
        webhook = $SlackWebhook
        slack = $SlackChannel
    }
    alertTemplates = @{
        email = @{
            subject = "ECRR Compliance Alert - {status}"
            body = @"
ECRR Compliance Status: {status}

Four-section Structure: {fourSectionPct}% (threshold: {fourSectionThreshold}%)
ECRR Gates: {gatePct}% (threshold: {gateThreshold}%)

Total Reports: {total}
Trend: {trend}

Dashboard: http://localhost:8080

Generated: {timestamp}
"@
        }
        slack = @{
            text = "🚨 ECRR Compliance Alert: {status}`n📊 Four-section: {fourSectionPct}% | Gates: {gatePct}%`n📈 Trend: {trend} | Reports: {total}`n🔗 Dashboard: http://localhost:8080"
        }
    }
}

# Save configuration
$ConfigPath = Join-Path $OutputDir "ecrr-alert-config.json"
$AlertConfig | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8

Write-Host "✅ Alert configuration saved to: $ConfigPath" -ForegroundColor Green

# Test alert system
Write-Host "`nTesting alert system..." -ForegroundColor Yellow
try {
    pwsh -File scripts/monitor-ecrr-alerts.ps1 -SendAlert
    Write-Host "✅ Alert system test completed" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Alert system test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Update email recipients in $ConfigPath" -ForegroundColor White
Write-Host "2. Configure Slack webhook URL if using Slack notifications" -ForegroundColor White
Write-Host "3. Test notifications with: pwsh -File scripts/monitor-ecrr-alerts.ps1 -SendAlert" -ForegroundColor White
Write-Host "4. Schedule daily monitoring: pwsh -File scripts/schedule-ecrr-trends.ps1 -CreateTask" -ForegroundColor White
