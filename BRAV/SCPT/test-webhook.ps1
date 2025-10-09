# Webhook Test Script
# Test webhook notifications for OTel alerts

param(
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL,
    [string]$Channel = $env:ALERT_CHANNEL
)

if (-not $WebhookUrl) {
    Write-Host "❌ No webhook URL provided. Set ALERT_WEBHOOK_URL environment variable." -ForegroundColor Red
    exit 1
}

Write-Host "🧪 Testing webhook notification..." -ForegroundColor Yellow

# Test payload
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
}
