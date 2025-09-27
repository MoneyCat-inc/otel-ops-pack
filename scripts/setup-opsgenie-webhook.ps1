# OpsGenie Webhook Setup Script
# Sets up OpsGenie notifications for OTel pipeline alerts

param(
    [string]$OpsGenieApiKey = $env:OPSGENIE_API_KEY,
    [string]$OpsGenieWebhookUrl = $env:OPSGENIE_WEBHOOK_URL,
    [string]$Team = "OTel-Pipeline",
    [switch]$TestOnly = $false
)

# ECRR: Examine → Clean → Report → Role
Write-Host "OpsGenie Webhook Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check OpsGenie configuration
Write-Host "`nExamine: Checking OpsGenie configuration..." -ForegroundColor Green

$OpsGenieStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    api_key = $OpsGenieApiKey
    webhook_url = $OpsGenieWebhookUrl
    team = $Team
    api_key_set = $false
    webhook_configured = $false
    test_successful = $false
    recommendations = @()
}

# Check if OpsGenie API key is set
Write-Host "Checking OpsGenie API key..." -ForegroundColor Yellow
if ($OpsGenieApiKey) {
    Write-Host "  ✅ OpsGenie API key is set" -ForegroundColor Green
    $OpsGenieStatus.api_key_set = $true
} else {
    Write-Host "  ❌ OpsGenie API key not set" -ForegroundColor Red
    $OpsGenieStatus.recommendations += "Set OPSGENIE_API_KEY environment variable"
}

# Check if OpsGenie webhook URL is set
Write-Host "Checking OpsGenie webhook URL..." -ForegroundColor Yellow
if ($OpsGenieWebhookUrl) {
    Write-Host "  ✅ OpsGenie webhook URL is set" -ForegroundColor Green
    $OpsGenieStatus.webhook_configured = $true
} else {
    Write-Host "  ❌ OpsGenie webhook URL not set" -ForegroundColor Red
    $OpsGenieStatus.recommendations += "Set OPSGENIE_WEBHOOK_URL environment variable"
}

# Clean: Configure OpsGenie if credentials are set
if ($OpsGenieStatus.api_key_set -and $OpsGenieStatus.webhook_configured) {
    Write-Host "`nClean: Testing OpsGenie webhook..." -ForegroundColor Green
    
    # Test OpsGenie webhook
    Write-Host "Testing OpsGenie webhook delivery..." -ForegroundColor Yellow
    try {
        $OpsGeniePayload = @{
            message = "OTel Pipeline Alert Test"
            alias = "otel-pipeline-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            description = "Test alert from OTel observability pipeline"
            entity = "OTel Pipeline"
            source = "OTel Observability Pipeline"
            priority = "P3"
            tags = @("otel", "pipeline", "test")
            details = @{
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss UTC")
                source = "OTel Observability Pipeline"
                test = $true
            }
        }
        
        $Headers = @{
            "Authorization" = "GenieKey $OpsGenieApiKey"
            "Content-Type" = "application/json"
        }
        
        $OpsGenieResponse = Invoke-RestMethod -Uri $OpsGenieWebhookUrl -Method POST -Headers $Headers -Body ($OpsGeniePayload | ConvertTo-Json -Depth 10) -TimeoutSec 10
        
        Write-Host "  ✅ OpsGenie webhook test successful" -ForegroundColor Green
        $OpsGenieStatus.test_successful = $true
    } catch {
        Write-Host "  ❌ OpsGenie webhook test failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $OpsGenieStatus.recommendations += "Check OpsGenie API key and webhook URL validity"
    }
} else {
    Write-Host "`nClean: OpsGenie setup guidance..." -ForegroundColor Yellow
    
    Write-Host "`n=== OPSGENIE SETUP ===" -ForegroundColor Cyan
    Write-Host "1. Log in to OpsGenie" -ForegroundColor White
    Write-Host "2. Navigate to Settings → Integrations" -ForegroundColor White
    Write-Host "3. Click 'Add Integration' → 'Webhook'" -ForegroundColor White
    Write-Host "4. Configure the webhook:" -ForegroundColor White
    Write-Host "   - Name: OTel Pipeline Alerts" -ForegroundColor Yellow
    Write-Host "   - Team: $Team" -ForegroundColor Yellow
    Write-Host "   - Description: OpenTelemetry observability pipeline alerts" -ForegroundColor Yellow
    Write-Host "5. Copy the webhook URL and API key" -ForegroundColor White
    Write-Host "6. Set environment variables:" -ForegroundColor White
    Write-Host "   `$env:OPSGENIE_API_KEY = 'your-api-key'" -ForegroundColor Yellow
    Write-Host "   `$env:OPSGENIE_WEBHOOK_URL = 'https://api.opsgenie.com/v1/alerts'" -ForegroundColor Yellow
    Write-Host "7. Test the webhook:" -ForegroundColor White
    Write-Host "   pwsh -File scripts/setup-opsgenie-webhook.ps1" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter when OpsGenie is configured"
}

# Report: Generate OpsGenie status report
Write-Host "`nReport: OpsGenie status summary" -ForegroundColor Green

Write-Host "`nOpsGenie Status:" -ForegroundColor Cyan
Write-Host "  API Key: $(if ($OpsGenieStatus.api_key_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($OpsGenieStatus.api_key_set) { 'Green' } else { 'Red' })
Write-Host "  Webhook URL: $(if ($OpsGenieStatus.webhook_configured) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($OpsGenieStatus.webhook_configured) { 'Green' } else { 'Red' })
Write-Host "  Test Result: $(if ($OpsGenieStatus.test_successful) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($OpsGenieStatus.test_successful) { 'Green' } else { 'Red' })
Write-Host "  Team: $Team" -ForegroundColor Cyan

if ($OpsGenieStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $OpsGenieStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save OpsGenie status report
$OpsGenieStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/opsgenie-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/opsgenie-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($OpsGenieStatus.test_successful) {
    Write-Host "Next: OpsGenie configured successfully - set up alert rules" -ForegroundColor Green
    Write-Host "Then: Configure OTel pipeline to send alerts to OpsGenie" -ForegroundColor Green
} else {
    Write-Host "Next: Complete OpsGenie setup and test delivery" -ForegroundColor Yellow
    Write-Host "Then: Re-run this script to verify OpsGenie integration" -ForegroundColor Yellow
}

# OpsGenie integration guidance
if ($OpsGenieStatus.test_successful) {
    Write-Host "`n=== OPSGENIE INTEGRATION ===" -ForegroundColor Cyan
    Write-Host "1. OpsGenie is ready for OTel alerts" -ForegroundColor White
    Write-Host "2. Configure alert rules in SigNoz" -ForegroundColor White
    Write-Host "3. Set up notification channels" -ForegroundColor White
    Write-Host "4. Test alert delivery to OpsGenie" -ForegroundColor White
    Write-Host "5. Monitor alert frequency and adjust thresholds" -ForegroundColor White
}
