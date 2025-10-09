# BossCat OEM - Webhook Notifier
# Sends verification results to Slack/Teams/Discord webhook for immediate visibility

param(
  [Parameter(Mandatory=$true)]
  [string]$WebhookUrl,
  
  [Parameter(Mandatory=$true)]
  [string]$Title,
  
  [Parameter(Mandatory=$true)]
  [string]$Text,
  
  [ValidateSet("info", "warning", "critical")]
  [string]$Severity = "info"
)

# Build payload (supports generic webhook format compatible with Slack/Teams/Discord)
$emoji = switch ($Severity) {
  "critical" { "🔴" }
  "warning"  { "🟡" }
  "info"     { "🟢" }
  default    { "ℹ️" }
}

$payload = @{
  text = "$emoji **$Title**`n$Text`n*Severity: $Severity*"
  username = "BossCat OEM"
}

try {
  Write-Host "🔔 [webhook] Sending notification..." -ForegroundColor Cyan
  Write-Host "   Title: $Title" -ForegroundColor Gray
  Write-Host "   Severity: $Severity" -ForegroundColor Gray
  
  $response = Invoke-RestMethod -Method Post `
    -Uri $WebhookUrl `
    -Body (ConvertTo-Json $payload) `
    -ContentType "application/json" `
    -TimeoutSec 10
  
  Write-Host "✅ Notification sent successfully" -ForegroundColor Green
  
} catch {
  Write-Warning "❌ Webhook notification failed: $($_.Exception.Message)"
  Write-Host "   Check webhook URL and network connectivity" -ForegroundColor Yellow
  exit 1
}

