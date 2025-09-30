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
