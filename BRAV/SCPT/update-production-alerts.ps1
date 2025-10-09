# Update ECRR Alert Configuration for Production
# This script helps configure production alert recipients

param(
    [string]$EmailRecipients = "",
    [string]$SlackWebhook = "",
    [string]$SlackChannel = "#ecrr-compliance",
    [string]$ConfigFile = "artifacts/ecrr-alert-config.json"
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR Production Alert Configuration" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check if config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Host "❌ Alert config file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "Run: pwsh -File scripts/configure-ecrr-alerts.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Load current configuration
$Config = Get-Content $ConfigFile | ConvertFrom-Json

# Update recipients if provided
if ($EmailRecipients) {
    $Config.notifications.email = $EmailRecipients
    $Config.notifications.type = "Email"
    Write-Host "✅ Updated email recipients: $EmailRecipients" -ForegroundColor Green
}

if ($SlackWebhook) {
    $Config.notifications.webhook = $SlackWebhook
    $Config.notifications.type = "Slack"
    Write-Host "✅ Updated Slack webhook: $SlackWebhook" -ForegroundColor Green
}

if ($SlackChannel) {
    $Config.notifications.slack = $SlackChannel
    Write-Host "✅ Updated Slack channel: $SlackChannel" -ForegroundColor Green
}

# Save updated configuration
$Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile -Encoding UTF8

Write-Host "`n📋 Current Alert Configuration:" -ForegroundColor Yellow
Write-Host "Email Recipients: $($Config.notifications.email)" -ForegroundColor White
Write-Host "Slack Channel: $($Config.notifications.slack)" -ForegroundColor White
Write-Host "Notification Type: $($Config.notifications.type)" -ForegroundColor White
Write-Host "Thresholds: Four-section $($Config.thresholds.fourSectionPct)%, Gates $($Config.thresholds.gatePct)%" -ForegroundColor White

Write-Host "`n🧪 Testing Alert System..." -ForegroundColor Cyan
try {
    pwsh -File scripts/monitor-ecrr-alerts.ps1 -SendAlert
    Write-Host "✅ Alert system test completed successfully" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Alert system test failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n📊 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Verify alert delivery in your email/Slack" -ForegroundColor White
Write-Host "2. Import SigNoz dashboard: artifacts/signoz-ecrr-dashboard.json" -ForegroundColor White
Write-Host "3. Set up SigNoz alert rules for compliance drops" -ForegroundColor White
Write-Host "4. Monitor dashboard at: http://localhost:8080" -ForegroundColor White
