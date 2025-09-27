# Complete Pipeline Setup Script
# Orchestrates complete OTel pipeline setup with authentication, dashboard, and webhooks

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$SkipAuthentication = $false,
    [switch]$SkipDashboard = $false,
    [switch]$SkipWebhooks = $false,
    [switch]$SkipE2ETest = $false,
    [switch]$Interactive = $true
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Complete Pipeline Setup - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check current system status
Write-Host "`nExamine: Checking current system status..." -ForegroundColor Green

$SetupStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    signoz_url = $SigNozUrl
    otel_collector_running = $false
    signoz_accessible = $false
    api_token_set = $false
    webhook_url_set = $false
    dashboard_imported = $false
    e2e_test_passed = $false
    setup_complete = $false
    step_results = @{}
    recommendations = @()
}

# Check OTel collector
Write-Host "Checking OTel collector..." -ForegroundColor Yellow
try {
    $CollectorHealth = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if ($CollectorHealth.status -eq "Server available") {
        Write-Host "  ✅ OTel collector is running" -ForegroundColor Green
        $SetupStatus.otel_collector_running = $true
    }
} catch {
    Write-Host "  ❌ OTel collector not accessible" -ForegroundColor Red
    $SetupStatus.recommendations += "Start OTel collector service"
}

# Check SigNoz accessibility
Write-Host "Checking SigNoz accessibility..." -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri $SigNozUrl -TimeoutSec 5
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  ✅ SigNoz UI accessible at $SigNozUrl" -ForegroundColor Green
        $SetupStatus.signoz_accessible = $true
    }
} catch {
    Write-Host "  ❌ SigNoz UI not accessible at $SigNozUrl" -ForegroundColor Red
    $SetupStatus.recommendations += "Start SigNoz stack (docker-compose up -d)"
}

# Check existing configuration
Write-Host "Checking existing configuration..." -ForegroundColor Yellow
if ($env:SIGNOZ_API_TOKEN) {
    Write-Host "  ✅ API token is set" -ForegroundColor Green
    $SetupStatus.api_token_set = $true
} else {
    Write-Host "  ❌ API token not set" -ForegroundColor Red
}

if ($env:ALERT_WEBHOOK_URL) {
    Write-Host "  ✅ Webhook URL is set" -ForegroundColor Green
    $SetupStatus.webhook_url_set = $true
} else {
    Write-Host "  ❌ Webhook URL not set" -ForegroundColor Red
}

# Clean: Run setup steps
Write-Host "`nClean: Running complete pipeline setup..." -ForegroundColor Green

# Step 1: Authentication Setup
if (-not $SkipAuthentication) {
    Write-Host "`n=== STEP 1: SIGNOZ AUTHENTICATION SETUP ===" -ForegroundColor Cyan
    try {
        if ($Interactive) {
            Read-Host "Press Enter to start authentication setup"
        }
        
        $AuthResult = & pwsh -File scripts/setup-signoz-authentication.ps1
        $SetupStatus.step_results.authentication = $LASTEXITCODE -eq 0
        
        if ($SetupStatus.step_results.authentication) {
            Write-Host "  ✅ Authentication setup completed" -ForegroundColor Green
            $SetupStatus.api_token_set = $true
        } else {
            Write-Host "  ❌ Authentication setup failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Authentication setup error: $($_.Exception.Message)" -ForegroundColor Red
        $SetupStatus.step_results.authentication = $false
    }
} else {
    Write-Host "`n=== STEP 1: SKIPPED - SIGNOZ AUTHENTICATION ===" -ForegroundColor Yellow
    $SetupStatus.step_results.authentication = $null
}

# Step 2: Dashboard Import
if (-not $SkipDashboard) {
    Write-Host "`n=== STEP 2: DASHBOARD IMPORT ===" -ForegroundColor Cyan
    try {
        if ($Interactive) {
            Read-Host "Press Enter to start dashboard import"
        }
        
        $DashboardResult = & pwsh -File scripts/import-dashboard.ps1
        $SetupStatus.step_results.dashboard = $LASTEXITCODE -eq 0
        
        if ($SetupStatus.step_results.dashboard) {
            Write-Host "  ✅ Dashboard import completed" -ForegroundColor Green
            $SetupStatus.dashboard_imported = $true
        } else {
            Write-Host "  ❌ Dashboard import failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Dashboard import error: $($_.Exception.Message)" -ForegroundColor Red
        $SetupStatus.step_results.dashboard = $false
    }
} else {
    Write-Host "`n=== STEP 2: SKIPPED - DASHBOARD IMPORT ===" -ForegroundColor Yellow
    $SetupStatus.step_results.dashboard = $null
}

# Step 3: Webhook Configuration
if (-not $SkipWebhooks) {
    Write-Host "`n=== STEP 3: WEBHOOK CONFIGURATION ===" -ForegroundColor Cyan
    try {
        if ($Interactive) {
            Read-Host "Press Enter to start webhook configuration"
        }
        
        $WebhookResult = & pwsh -File scripts/setup-webhooks.ps1
        $SetupStatus.step_results.webhooks = $LASTEXITCODE -eq 0
        
        if ($SetupStatus.step_results.webhooks) {
            Write-Host "  ✅ Webhook configuration completed" -ForegroundColor Green
            $SetupStatus.webhook_url_set = $true
        } else {
            Write-Host "  ❌ Webhook configuration failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Webhook configuration error: $($_.Exception.Message)" -ForegroundColor Red
        $SetupStatus.step_results.webhooks = $false
    }
} else {
    Write-Host "`n=== STEP 3: SKIPPED - WEBHOOK CONFIGURATION ===" -ForegroundColor Yellow
    $SetupStatus.step_results.webhooks = $null
}

# Step 4: End-to-End Pipeline Test
if (-not $SkipE2ETest) {
    Write-Host "`n=== STEP 4: END-TO-END PIPELINE TEST ===" -ForegroundColor Cyan
    try {
        if ($Interactive) {
            Read-Host "Press Enter to start end-to-end pipeline test"
        }
        
        $E2EResult = & pwsh -File scripts/test-e2e-pipeline.ps1
        $SetupStatus.step_results.e2e_test = $LASTEXITCODE -eq 0
        
        if ($SetupStatus.step_results.e2e_test) {
            Write-Host "  ✅ End-to-end pipeline test completed" -ForegroundColor Green
            $SetupStatus.e2e_test_passed = $true
        } else {
            Write-Host "  ❌ End-to-end pipeline test failed" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ End-to-end pipeline test error: $($_.Exception.Message)" -ForegroundColor Red
        $SetupStatus.step_results.e2e_test = $false
    }
} else {
    Write-Host "`n=== STEP 4: SKIPPED - END-TO-END PIPELINE TEST ===" -ForegroundColor Yellow
    $SetupStatus.step_results.e2e_test = $null
}

# Determine overall setup status
$CompletedSteps = ($SetupStatus.step_results.Values | Where-Object { $_ -eq $true }).Count
$TotalSteps = ($SetupStatus.step_results.Values | Where-Object { $_ -ne $null }).Count

if ($CompletedSteps -eq $TotalSteps -and $TotalSteps -gt 0) {
    $SetupStatus.setup_complete = $true
}

# Report: Generate setup status report
Write-Host "`nReport: Complete pipeline setup summary" -ForegroundColor Green

Write-Host "`nSetup Status:" -ForegroundColor Cyan
Write-Host "  OTel Collector: $(if ($SetupStatus.otel_collector_running) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SetupStatus.otel_collector_running) { 'Green' } else { 'Red' })
Write-Host "  SigNoz Access: $(if ($SetupStatus.signoz_accessible) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SetupStatus.signoz_accessible) { 'Green' } else { 'Red' })
Write-Host "  API Token: $(if ($SetupStatus.api_token_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SetupStatus.api_token_set) { 'Green' } else { 'Red' })
Write-Host "  Webhook URL: $(if ($SetupStatus.webhook_url_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SetupStatus.webhook_url_set) { 'Green' } else { 'Red' })
Write-Host "  Dashboard: $(if ($SetupStatus.dashboard_imported) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SetupStatus.dashboard_imported) { 'Green' } else { 'Red' })
Write-Host "  E2E Test: $(if ($SetupStatus.e2e_test_passed) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($SetupStatus.e2e_test_passed) { 'Green' } else { 'Red' })

Write-Host "`nStep Results:" -ForegroundColor Cyan
foreach ($step in $SetupStatus.step_results.GetEnumerator()) {
    $status = if ($step.Value -eq $true) { "✅ PASS" } elseif ($step.Value -eq $false) { "❌ FAIL" } else { "⏭️ SKIP" }
    Write-Host "  $($step.Key): $status" -ForegroundColor $(if ($step.Value -eq $true) { 'Green' } elseif ($step.Value -eq $false) { 'Red' } else { 'Yellow' })
}

if ($SetupStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $SetupStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save setup status report
$SetupStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/complete-setup-status.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/complete-setup-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($SetupStatus.setup_complete) {
    Write-Host "Next: Complete pipeline setup successful - system ready for production monitoring" -ForegroundColor Green
    Write-Host "Then: Monitor dashboard, configure alert thresholds, and set up automated monitoring" -ForegroundColor Green
} else {
    Write-Host "Next: Complete remaining setup steps and re-run failed components" -ForegroundColor Yellow
    Write-Host "Then: Verify all components working and test end-to-end pipeline" -ForegroundColor Yellow
}

# Final guidance
if ($SetupStatus.setup_complete) {
    Write-Host "`n=== PRODUCTION READY ===" -ForegroundColor Cyan
    Write-Host "Your OTel observability pipeline is now fully configured:" -ForegroundColor White
    Write-Host "1. ✅ SigNoz authentication configured" -ForegroundColor Green
    Write-Host "2. ✅ Queue pressure dashboard imported" -ForegroundColor Green
    Write-Host "3. ✅ Webhook notifications configured" -ForegroundColor Green
    Write-Host "4. ✅ End-to-end pipeline tested" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps for production:" -ForegroundColor White
    Write-Host "- Monitor queue pressure dashboard in SigNoz" -ForegroundColor Yellow
    Write-Host "- Set up alert rules for critical thresholds" -ForegroundColor Yellow
    Write-Host "- Configure automated monitoring schedules" -ForegroundColor Yellow
    Write-Host "- Document operational procedures" -ForegroundColor Yellow
} else {
    Write-Host "`n=== SETUP INCOMPLETE ===" -ForegroundColor Cyan
    Write-Host "Complete the following steps:" -ForegroundColor White
    if (-not $SetupStatus.otel_collector_running) {
        Write-Host "- Start OTel collector service" -ForegroundColor Yellow
    }
    if (-not $SetupStatus.signoz_accessible) {
        Write-Host "- Start SigNoz stack (docker-compose up -d)" -ForegroundColor Yellow
    }
    if (-not $SetupStatus.api_token_set) {
        Write-Host "- Run: pwsh -File scripts/setup-signoz-authentication.ps1" -ForegroundColor Yellow
    }
    if (-not $SetupStatus.dashboard_imported) {
        Write-Host "- Run: pwsh -File scripts/import-dashboard.ps1" -ForegroundColor Yellow
    }
    if (-not $SetupStatus.webhook_url_set) {
        Write-Host "- Run: pwsh -File scripts/setup-webhooks.ps1" -ForegroundColor Yellow
    }
    if (-not $SetupStatus.e2e_test_passed) {
        Write-Host "- Run: pwsh -File scripts/test-e2e-pipeline.ps1" -ForegroundColor Yellow
    }
}
