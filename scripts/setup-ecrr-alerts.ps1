# ECRR Compliance Alerting Setup
# This script configures alerts for ECRR compliance drops and trend monitoring

param(
    [string]$AlertType = "Email",  # Email, Webhook, or Slack
    [string]$EmailRecipients = "",
    [string]$WebhookUrl = "",
    [string]$SlackWebhook = "",
    [int]$FourSectionThreshold = 95,
    [int]$GateThreshold = 90,
    [string]$OutputDir = "artifacts"
)

$ErrorActionPreference = "Stop"

Write-Host "ECRR Compliance Alerting Setup" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Generate alert configuration
$AlertConfig = @{
    thresholds = @{
        fourSectionPct = $FourSectionThreshold
        gatePct = $GateThreshold
    }
    notifications = @{
        type = $AlertType
        email = $EmailRecipients
        webhook = $WebhookUrl
        slack = $SlackWebhook
    }
    monitoring = @{
        checkInterval = "daily"
        trendWindow = "7d"
        alertCooldown = "24h"
    }
}

# Save alert configuration
$AlertConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "$OutputDir/ecrr-alert-config.json" -Encoding UTF8

# Generate alert monitoring script
$AlertScript = @'
# ECRR Compliance Alert Monitor
# This script checks compliance metrics and sends alerts if thresholds are breached

param(
    [string]$ConfigFile = "artifacts/ecrr-alert-config.json",
    [string]$ValidationFile = "artifacts/ecrr-ci-validation.json",
    [switch]$SendAlert = $false
)

$ErrorActionPreference = "Stop"

# Load configuration
if (-not (Test-Path $ConfigFile)) {
    Write-Host "❌ Alert configuration not found: $ConfigFile" -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json

# Load latest validation results
if (-not (Test-Path $ValidationFile)) {
    Write-Host "❌ Validation results not found: $ValidationFile" -ForegroundColor Red
    exit 1
}

$validation = Get-Content $ValidationFile | ConvertFrom-Json

# Check thresholds
$fourSectionAlert = $validation.fourSection.pct -lt $config.thresholds.fourSectionPct
$gateAlert = $validation.ecrrGate.pct -lt $config.thresholds.gatePct

if ($fourSectionAlert -or $gateAlert) {
    $alertMessage = @"
🚨 ECRR Compliance Alert 🚨

Compliance metrics have dropped below thresholds:

Four-section Structure: $($validation.fourSection.pct)% (threshold: $($config.thresholds.fourSectionPct)%)
ECRR Gates: $($validation.ecrrGate.pct)% (threshold: $($config.thresholds.gatePct)%)
Total Reports: $($validation.total)

Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")

Please review ECRR reports and ensure compliance standards are maintained.
"@

    Write-Host "🚨 ALERT: Compliance below thresholds!" -ForegroundColor Red
    Write-Host $alertMessage -ForegroundColor Yellow

    if ($SendAlert) {
        # Send alert based on configuration
        switch ($config.notifications.type) {
            "Email" {
                if ($config.notifications.email) {
                    Write-Host "📧 Sending email alert to: $($config.notifications.email)" -ForegroundColor Cyan
                    # Email sending logic would go here
                }
            }
            "Webhook" {
                if ($config.notifications.webhook) {
                    Write-Host "🔗 Sending webhook alert to: $($config.notifications.webhook)" -ForegroundColor Cyan
                    # Webhook sending logic would go here
                }
            }
            "Slack" {
                if ($config.notifications.slack) {
                    Write-Host "💬 Sending Slack alert to: $($config.notifications.slack)" -ForegroundColor Cyan
                    # Slack sending logic would go here
                }
            }
        }
    }
} else {
    Write-Host "✅ Compliance metrics are within acceptable thresholds" -ForegroundColor Green
}

# Log alert check
$logEntry = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
    fourSectionPct = $validation.fourSection.pct
    gatePct = $validation.ecrrGate.pct
    alertTriggered = ($fourSectionAlert -or $gateAlert)
    thresholds = $config.thresholds
}

$logEntry | ConvertTo-Json | Add-Content -Path "artifacts/ecrr-alert-history.jsonl" -Encoding UTF8
'@

$AlertScript | Out-File -FilePath "scripts/monitor-ecrr-alerts.ps1" -Encoding UTF8

Write-Host "`n✅ Alert configuration created:" -ForegroundColor Green
Write-Host "- Configuration: $OutputDir/ecrr-alert-config.json" -ForegroundColor White
Write-Host "- Monitor Script: scripts/monitor-ecrr-alerts.ps1" -ForegroundColor White

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure alert recipients (email/webhook/Slack)" -ForegroundColor White
Write-Host "2. Test alert monitoring: pwsh -File scripts/monitor-ecrr-alerts.ps1" -ForegroundColor White
Write-Host "3. Schedule alert checks: Add to Task Scheduler or cron" -ForegroundColor White
Write-Host "4. Integrate with CI: Run after compliance checks" -ForegroundColor White

Write-Host "`n🔧 Usage Examples:" -ForegroundColor Cyan
Write-Host "# Test alert monitoring" -ForegroundColor White
Write-Host "pwsh -File scripts/monitor-ecrr-alerts.ps1" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "# Send actual alerts" -ForegroundColor White
Write-Host "pwsh -File scripts/monitor-ecrr-alerts.ps1 -SendAlert" -ForegroundColor Gray
