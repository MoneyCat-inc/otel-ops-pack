# Test Webhook Notifications Script
# Verifies webhook URL configuration and delivery

param(
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL,
    [string]$TestMessage = "OTel monitoring test alert",
    [switch]$DryRun = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Webhook Notification Test - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check webhook configuration
Write-Host "`nExamine: Testing webhook configuration..." -ForegroundColor Green

if (-not $WebhookUrl) {
    Write-Host "ERROR: ALERT_WEBHOOK_URL environment variable not set" -ForegroundColor Red
    Write-Host "Please set: `$env:ALERT_WEBHOOK_URL = 'your-webhook-url'" -ForegroundColor Yellow
    Write-Host "`nExample webhook URLs:" -ForegroundColor Cyan
    Write-Host "  Slack: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" -ForegroundColor White
    Write-Host "  Discord: https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK" -ForegroundColor White
    Write-Host "  Local: http://localhost:3003/api/webhooks/alerts" -ForegroundColor White
    exit 1
}

Write-Host "Webhook URL: $WebhookUrl" -ForegroundColor Cyan
Write-Host "Test Message: $TestMessage" -ForegroundColor Cyan
Write-Host "Dry Run: $DryRun" -ForegroundColor Cyan

# Clean: Prepare test payload
Write-Host "`nClean: Preparing test payload..." -ForegroundColor Green

$TestPayload = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    alert_type = "test"
    severity = "info"
    title = "OTel Monitoring Test Alert"
    message = $TestMessage
    source = "otel-monitoring"
    environment = "local"
    test_run = $true
    metadata = @{
        script = "test-webhook.ps1"
        actor = "Cursor-Local (Observability Copilot)"
        version = "1.0"
    }
}

$JsonPayload = $TestPayload | ConvertTo-Json -Depth 3
Write-Host "Payload prepared: $($JsonPayload.Length) characters" -ForegroundColor Green

# Report: Test webhook delivery
Write-Host "`nReport: Testing webhook delivery..." -ForegroundColor Green

if ($DryRun) {
    Write-Host "DRY RUN: Would send webhook to: $WebhookUrl" -ForegroundColor Yellow
    Write-Host "Payload:" -ForegroundColor Yellow
    Write-Host $JsonPayload -ForegroundColor White
    return
}

try {
    Write-Host "Sending webhook to: $WebhookUrl" -ForegroundColor Yellow
    
    $Response = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body $JsonPayload -ContentType "application/json" -TimeoutSec 30
    
    Write-Host "OK Webhook delivered successfully" -ForegroundColor Green
    Write-Host "Response: $($Response | ConvertTo-Json -Compress)" -ForegroundColor Green
    
    $DeliveryStatus = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        webhook_url = $WebhookUrl
        status = "success"
        response = $Response
        test_message = $TestMessage
    }
    
} catch {
    Write-Host "ERROR Webhook delivery failed: $($_.Exception.Message)" -ForegroundColor Red
    
    $DeliveryStatus = @{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        webhook_url = $WebhookUrl
        status = "failed"
        error = $_.Exception.Message
        test_message = $TestMessage
    }
    
    # Provide troubleshooting hints
    if ($_.Exception.Message -like "*404*") {
        Write-Host "HINT: Webhook URL not found (404) - check URL path" -ForegroundColor Yellow
    } elseif ($_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*403*") {
        Write-Host "HINT: Authentication failed - check webhook token/credentials" -ForegroundColor Yellow
    } elseif ($_.Exception.Message -like "*timeout*") {
        Write-Host "HINT: Request timeout - check network connectivity and webhook service" -ForegroundColor Yellow
    } elseif ($_.Exception.Message -like "*connection*") {
        Write-Host "HINT: Connection failed - check webhook URL and service availability" -ForegroundColor Yellow
    }
}

# Save delivery status report
$DeliveryStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/webhook-test-status.json" -Encoding UTF8

Write-Host "`nDelivery Status:" -ForegroundColor Cyan
Write-Host "  Status: $($DeliveryStatus.status)" -ForegroundColor $(if ($DeliveryStatus.status -eq "success") { 'Green' } else { 'Red' })
Write-Host "  URL: $($DeliveryStatus.webhook_url)" -ForegroundColor White
Write-Host "  Time: $($DeliveryStatus.timestamp)" -ForegroundColor White

if ($DeliveryStatus.status -eq "failed") {
    Write-Host "  Error: $($DeliveryStatus.error)" -ForegroundColor Red
}

Write-Host "`nReport saved to: artifacts/webhook-test-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host "Next: Configure webhook URL and test with real alerts" -ForegroundColor Yellow
Write-Host "Then: Set up alert thresholds and notification channels" -ForegroundColor Yellow