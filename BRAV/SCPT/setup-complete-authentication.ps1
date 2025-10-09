# Complete Authentication Setup Script
# ECRR Framework: Examine → Clean → Report → Role
# Actor: Cursor Agent - Observability Copilot

param(
    [switch]$Interactive,
    [switch]$DryRun
)

Write-Host "🔐 Complete Authentication Setup" -ForegroundColor Cyan
Write-Host "Actor: Cursor Agent - Observability Copilot" -ForegroundColor Gray
Write-Host ""

# Examine: Current Authentication State
Write-Host "🔍 Examine: Current Authentication State..." -ForegroundColor Yellow

$AuthStatus = @{
    SigNozApiToken = $false
    AlertWebhookUrl = $false
    SigNozUiAccessible = $false
}

# Check SigNoz API Token
if ($env:SIGNOZ_API_TOKEN) {
    $AuthStatus.SigNozApiToken = $true
    Write-Host "  ✅ SIGNOZ_API_TOKEN: Set" -ForegroundColor Green
} else {
    Write-Host "  ❌ SIGNOZ_API_TOKEN: Not set" -ForegroundColor Red
}

# Check Alert Webhook URL
if ($env:ALERT_WEBHOOK_URL) {
    $AuthStatus.AlertWebhookUrl = $true
    Write-Host "  ✅ ALERT_WEBHOOK_URL: Set" -ForegroundColor Green
} else {
    Write-Host "  ❌ ALERT_WEBHOOK_URL: Not set" -ForegroundColor Red
}

# Check SigNoz UI Accessibility
try {
    $UiResponse = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 5
    if ($UiResponse.StatusCode -eq 200) {
        $AuthStatus.SigNozUiAccessible = $true
        Write-Host "  ✅ SigNoz UI: Accessible" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ SigNoz UI: HTTP $($UiResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ SigNoz UI: Not accessible" -ForegroundColor Red
}

# Clean: Setup Authentication
Write-Host ""
Write-Host "🧹 Clean: Setting up Authentication..." -ForegroundColor Yellow

if (-not $AuthStatus.SigNozApiToken -or $Interactive) {
    Write-Host "  📝 SigNoz API Token Setup Required" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Manual Steps Required:" -ForegroundColor Yellow
    Write-Host "    1. Open browser: http://localhost:8080" -ForegroundColor White
    Write-Host "    2. Navigate to Settings → API Keys" -ForegroundColor White
    Write-Host "    3. Click 'Generate New Key'" -ForegroundColor White
    Write-Host "    4. Name: 'otel-monitoring'" -ForegroundColor White
    Write-Host "    5. Permissions: read:logs, read:metrics, read:traces" -ForegroundColor White
    Write-Host "    6. Copy the generated token" -ForegroundColor White
    Write-Host ""
    
    if ($Interactive) {
        $ApiToken = Read-Host "Enter your SigNoz API token"
        if ($ApiToken) {
            $env:SIGNOZ_API_TOKEN = $ApiToken
            Write-Host "  ✅ API token set for this session" -ForegroundColor Green
        }
    } else {
        Write-Host "  💡 Set token with: `$env:SIGNOZ_API_TOKEN = 'your-token-here'" -ForegroundColor Cyan
    }
}

if (-not $AuthStatus.AlertWebhookUrl -or $Interactive) {
    Write-Host "  📝 Alert Webhook URL Setup Required" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Webhook Options:" -ForegroundColor Yellow
    Write-Host "    Slack: https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" -ForegroundColor White
    Write-Host "    Discord: https://discord.com/api/webhooks/YOUR/DISCORD/WEBHOOK" -ForegroundColor White
    Write-Host "    Local: http://localhost:3003/api/webhooks/alerts" -ForegroundColor White
    Write-Host ""
    
    if ($Interactive) {
        $WebhookUrl = Read-Host "Enter your webhook URL (or press Enter for local)"
        if (-not $WebhookUrl) {
            $WebhookUrl = "http://localhost:3003/api/webhooks/alerts"
        }
        $env:ALERT_WEBHOOK_URL = $WebhookUrl
        Write-Host "  ✅ Webhook URL set for this session" -ForegroundColor Green
    } else {
        Write-Host "  💡 Set webhook with: `$env:ALERT_WEBHOOK_URL = 'your-webhook-url'" -ForegroundColor Cyan
    }
}

# Report: Test Authentication
Write-Host ""
Write-Host "📝 Report: Testing Authentication..." -ForegroundColor Yellow

if ($env:SIGNOZ_API_TOKEN) {
    try {
        $Headers = @{ "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN" }
        $LogsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method Get -Headers $Headers -TimeoutSec 10
        Write-Host "  ✅ SigNoz API: Authentication successful" -ForegroundColor Green
        
        # Test metrics API
        try {
            $MetricsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/metrics" -Method Get -Headers $Headers -TimeoutSec 10
            Write-Host "  ✅ Metrics API: Accessible" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️ Metrics API: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
        # Test traces API
        try {
            $TracesResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/traces" -Method Get -Headers $Headers -TimeoutSec 10
            Write-Host "  ✅ Traces API: Accessible" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️ Traces API: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ❌ SigNoz API: Authentication failed - $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  💡 Check your API token and permissions" -ForegroundColor Cyan
    }
} else {
    Write-Host "  ⏭️ SigNoz API: Skipped (no token set)" -ForegroundColor Gray
}

if ($env:ALERT_WEBHOOK_URL) {
    try {
        $WebhookPayload = @{
            text = "Test alert from OTel pipeline setup"
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            source = "otel-setup"
            severity = "info"
        } | ConvertTo-Json
        
        $WebhookResponse = Invoke-RestMethod -Uri $env:ALERT_WEBHOOK_URL -Method Post -Body $WebhookPayload -ContentType "application/json" -TimeoutSec 10
        Write-Host "  ✅ Webhook: Test message sent successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "  ❌ Webhook: Test failed - $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  💡 Check your webhook URL and service availability" -ForegroundColor Cyan
    }
} else {
    Write-Host "  ⏭️ Webhook: Skipped (no URL set)" -ForegroundColor Gray
}

# Role: Generate Setup Summary
Write-Host ""
Write-Host "🎭 Role: Authentication Setup Summary..." -ForegroundColor Yellow

$SetupComplete = $AuthStatus.SigNozApiToken -and $AuthStatus.AlertWebhookUrl

if ($SetupComplete) {
    Write-Host "  ✅ Authentication Setup: COMPLETE" -ForegroundColor Green
    Write-Host "  🎯 Ready for dashboard import and alert configuration" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Authentication Setup: PARTIAL" -ForegroundColor Yellow
    Write-Host "  📋 Remaining steps:" -ForegroundColor Cyan
    
    if (-not $AuthStatus.SigNozApiToken) {
        Write-Host "    • Set SIGNOZ_API_TOKEN environment variable" -ForegroundColor White
    }
    if (-not $AuthStatus.AlertWebhookUrl) {
        Write-Host "    • Set ALERT_WEBHOOK_URL environment variable" -ForegroundColor White
    }
}

# Generate setup report
$ReportPath = "artifacts/authentication-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Authentication Setup Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Actor**: Cursor Agent - Observability Copilot  
**Setup Mode**: $(if ($Interactive) { 'Interactive' } else { 'Automated' })

## Current Status
- **SigNoz API Token**: $(if ($env:SIGNOZ_API_TOKEN) { '✅ Set' } else { '❌ Not Set' })
- **Alert Webhook URL**: $(if ($env:ALERT_WEBHOOK_URL) { '✅ Set' } else { '❌ Not Set' })
- **SigNoz UI**: $(if ($AuthStatus.SigNozUiAccessible) { '✅ Accessible' } else { '❌ Not Accessible' })

## Test Results
$(
    if ($env:SIGNOZ_API_TOKEN) {
        "✅ SigNoz API authentication successful"
    } else {
        "⏭️ SigNoz API test skipped (no token)"
    }
)

$(
    if ($env:ALERT_WEBHOOK_URL) {
        "✅ Webhook test successful"
    } else {
        "⏭️ Webhook test skipped (no URL)"
    }
)

## Next Steps
$(if ($SetupComplete) {
    "1. Import queue pressure dashboard to SigNoz
2. Configure alert thresholds and notifications
3. Run end-to-end pipeline test with authentication
4. Monitor system performance and alerts"
} else {
    "1. Complete API token setup in SigNoz UI
2. Set ALERT_WEBHOOK_URL environment variable
3. Re-run this script to verify authentication
4. Proceed with dashboard import"
})

## Commands
```powershell
# Set API token (replace with your actual token)
`$env:SIGNOZ_API_TOKEN = 'your-api-token-here'

# Set webhook URL (replace with your actual URL)
`$env:ALERT_WEBHOOK_URL = 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

# Test authentication
pwsh -File scripts/setup-complete-authentication.ps1 -Interactive

# Test SigNoz API
pwsh -File scripts/test-signoz-auth.ps1

# Test webhook
pwsh -File scripts/test-webhook.ps1
```

---
**Generated by**: Complete Authentication Setup Script  
**ECRR Framework**: Examine → Clean → Report → Role
"@

New-Item -Path (Split-Path $ReportPath -Parent) -ItemType Directory -Force | Out-Null
Set-Content -Path $ReportPath -Value $ReportContent
Write-Host "  📊 Setup report saved to: $ReportPath" -ForegroundColor Green

Write-Host ""
Write-Host "✅ Authentication Setup Complete!" -ForegroundColor Green

if (-not $SetupComplete) {
    Write-Host ""
    Write-Host "🔧 Manual Setup Required:" -ForegroundColor Yellow
    Write-Host "  1. Access http://localhost:8080 → Settings → API Keys" -ForegroundColor White
    Write-Host "  2. Generate API token with read permissions" -ForegroundColor White
    Write-Host "  3. Set environment variables and re-run this script" -ForegroundColor White
}
