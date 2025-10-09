# Microsoft Teams Webhook Setup Script
# Sets up Microsoft Teams notifications for OTel pipeline alerts

param(
    [string]$TeamsWebhookUrl = $env:TEAMS_WEBHOOK_URL,
    [string]$Channel = "OTel Alerts",
    [switch]$TestOnly = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Microsoft Teams Webhook Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check Teams webhook configuration
Write-Host "`nExamine: Checking Microsoft Teams webhook configuration..." -ForegroundColor Green

$TeamsStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    webhook_url = $TeamsWebhookUrl
    channel = $Channel
    webhook_configured = $false
    test_successful = $false
    recommendations = @()
}

# Check if Teams webhook URL is set
Write-Host "Checking Teams webhook URL..." -ForegroundColor Yellow
if ($TeamsWebhookUrl) {
    Write-Host "  ✅ Teams webhook URL is set" -ForegroundColor Green
    $TeamsStatus.webhook_configured = $true
} else {
    Write-Host "  ❌ Teams webhook URL not set" -ForegroundColor Red
    $TeamsStatus.recommendations += "Set TEAMS_WEBHOOK_URL environment variable"
}

# Clean: Configure Teams webhook if URL is set
if ($TeamsStatus.webhook_configured) {
    Write-Host "`nClean: Testing Microsoft Teams webhook..." -ForegroundColor Green
    
    # Test Teams webhook
    Write-Host "Testing Teams webhook delivery..." -ForegroundColor Yellow
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
                    activityImage = "https://img.icons8.com/color/48/000000/telephone.png"
                    facts = @(
                        @{
                            name = "Status"
                            value = "Pipeline Test Alert"
                        },
                        @{
                            name = "Timestamp"
                            value = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
                        },
                        @{
                            name = "Source"
                            value = "OTel Observability Pipeline"
                        }
                    )
                    markdown = $true
                }
            )
        }
        
        $TeamsResponse = Invoke-RestMethod -Uri $TeamsWebhookUrl -Method POST -Body ($TeamsPayload | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 10
        
        Write-Host "  ✅ Teams webhook test successful" -ForegroundColor Green
        $TeamsStatus.test_successful = $true
    } catch {
        Write-Host "  ❌ Teams webhook test failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $TeamsStatus.recommendations += "Check Teams webhook URL validity and permissions"
    }
} else {
    Write-Host "`nClean: Microsoft Teams webhook setup guidance..." -ForegroundColor Yellow
    
    Write-Host "`n=== MICROSOFT TEAMS WEBHOOK SETUP ===" -ForegroundColor Cyan
    Write-Host "1. Open Microsoft Teams" -ForegroundColor White
    Write-Host "2. Navigate to the channel: $Channel" -ForegroundColor White
    Write-Host "3. Click the three dots (...) next to the channel name" -ForegroundColor White
    Write-Host "4. Select 'Connectors'" -ForegroundColor White
    Write-Host "5. Find 'Incoming Webhook' and click 'Configure'" -ForegroundColor White
    Write-Host "6. Fill in the details:" -ForegroundColor White
    Write-Host "   - Name: OTel Pipeline Monitor" -ForegroundColor Yellow
    Write-Host "   - Description: OpenTelemetry observability pipeline alerts" -ForegroundColor Yellow
    Write-Host "7. Click 'Create' and copy the webhook URL" -ForegroundColor White
    Write-Host "8. Set environment variable:" -ForegroundColor White
    Write-Host "   `$env:TEAMS_WEBHOOK_URL = 'https://your-org.webhook.office.com/webhookb2/...'" -ForegroundColor Yellow
    Write-Host "9. Test the webhook:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/setup-teams-webhook.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter when Teams webhook is configured"
}

# Report: Generate Teams webhook status report
Write-Host "`nReport: Microsoft Teams webhook status summary" -ForegroundColor Green

Write-Host "`nTeams Webhook Status:" -ForegroundColor Cyan
Write-Host "  Webhook URL: $(if ($TeamsStatus.webhook_configured) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($TeamsStatus.webhook_configured) { 'Green' } else { 'Red' })
Write-Host "  Test Result: $(if ($TeamsStatus.test_successful) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($TeamsStatus.test_successful) { 'Green' } else { 'Red' })
Write-Host "  Channel: $Channel" -ForegroundColor Cyan

if ($TeamsStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $TeamsStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save Teams webhook status report
$TeamsStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/teams-webhook-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/teams-webhook-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($TeamsStatus.test_successful) {
    Write-Host "Next: Microsoft Teams webhook configured successfully - set up alert rules" -ForegroundColor Green
    Write-Host "Then: Configure OTel pipeline to send alerts to Teams" -ForegroundColor Green
} else {
    Write-Host "Next: Complete Microsoft Teams webhook setup and test delivery" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify Teams integration" -ForegroundColor Yellow
}

# Teams integration guidance
if ($TeamsStatus.test_successful) {
    Write-Host "`n=== TEAMS INTEGRATION ===" -ForegroundColor Cyan
    Write-Host "1. Teams webhook is ready for OTel alerts" -ForegroundColor White
    Write-Host "2. Configure alert rules in SigNoz" -ForegroundColor White
    Write-Host "3. Set up notification channels" -ForegroundColor White
    Write-Host "4. Test alert delivery to Teams" -ForegroundColor White
    Write-Host "5. Monitor alert frequency and adjust thresholds" -ForegroundColor White
}
