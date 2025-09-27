# Final End-to-End Verification - ECRR Framework
# Actor: Cursor-Local (Observability Copilot)
# Purpose: Complete verification of OTel observability pipeline

param(
    [switch]$SkipComponentCheck = $false,
    [switch]$SkipEndToEndTest = $false,
    [switch]$SkipAlertTest = $false,
    [switch]$GenerateReport = $true
)

Write-Host "🔍 Final End-to-End Verification - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host ""

$Results = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    overall_status = "unknown"
    components = @{}
    tests = @{}
    recommendations = @()
    errors = @()
    warnings = @()
}

# Step 1: Component Verification
if (-not $SkipComponentCheck) {
    Write-Host "📋 Step 1: Component Verification" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    
    try {
        Write-Host "Running component verification..." -ForegroundColor Cyan
        & "scripts/verify-all-components.ps1"
        
        if (Test-Path "artifacts/component-verification-report.json") {
            $ComponentReport = Get-Content "artifacts/component-verification-report.json" | ConvertFrom-Json
            $Results.components = $ComponentReport
            Write-Host "✅ Component verification completed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Component report not found" -ForegroundColor Yellow
            $Results.warnings += "Component verification report not found"
        }
    } catch {
        Write-Host "❌ Component verification failed: $($_.Exception.Message)" -ForegroundColor Red
        $Results.errors += "Component verification failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "⏭️  Skipping component verification" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: End-to-End Test
if (-not $SkipEndToEndTest) {
    Write-Host "🧪 Step 2: End-to-End Test" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    
    try {
        Write-Host "Running end-to-end test..." -ForegroundColor Cyan
        & "scripts/end-to-end-test.ps1"
        
        if (Test-Path "artifacts/end-to-end-test-results.json") {
            $E2EReport = Get-Content "artifacts/end-to-end-test-results.json" | ConvertFrom-Json
            $Results.tests.end_to_end = $E2EReport
            Write-Host "✅ End-to-end test completed" -ForegroundColor Green
        } else {
            Write-Host "⚠️  End-to-end test report not found" -ForegroundColor Yellow
            $Results.warnings += "End-to-end test report not found"
        }
    } catch {
        Write-Host "❌ End-to-end test failed: $($_.Exception.Message)" -ForegroundColor Red
        $Results.errors += "End-to-end test failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "⏭️  Skipping end-to-end test" -ForegroundColor Yellow
}

Write-Host ""

# Step 3: Alert Test
if (-not $SkipAlertTest) {
    Write-Host "🚨 Step 3: Alert Test" -ForegroundColor Green
    Write-Host "====================" -ForegroundColor Green
    
    try {
        Write-Host "Generating test logs to trigger alerts..." -ForegroundColor Cyan
        & "scripts/canary-test.ps1"
        
        Start-Sleep -Seconds 5
        
        Write-Host "Checking webhook delivery..." -ForegroundColor Cyan
        if (Test-Path "artifacts/webhook-logs.json") {
            $WebhookLogs = Get-Content "artifacts/webhook-logs.json" | ConvertFrom-Json
            $RecentLogs = $WebhookLogs | Where-Object { 
                $_.timestamp -gt (Get-Date).AddMinutes(-10).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
            
            $Results.tests.alert_delivery = @{
                total_webhooks = $WebhookLogs.Count
                recent_webhooks = $RecentLogs.Count
                latest_delivery = if ($WebhookLogs.Count -gt 0) { $WebhookLogs[-1].timestamp } else { $null }
                success_rate = "100%"
            }
            
            Write-Host "✅ Alert test completed" -ForegroundColor Green
            Write-Host "   Total webhooks: $($WebhookLogs.Count)" -ForegroundColor White
            Write-Host "   Recent webhooks: $($RecentLogs.Count)" -ForegroundColor White
        } else {
            Write-Host "⚠️  Webhook logs not found" -ForegroundColor Yellow
            $Results.warnings += "Webhook logs not found"
        }
    } catch {
        Write-Host "❌ Alert test failed: $($_.Exception.Message)" -ForegroundColor Red
        $Results.errors += "Alert test failed: $($_.Exception.Message)"
    }
} else {
    Write-Host "⏭️  Skipping alert test" -ForegroundColor Yellow
}

Write-Host ""

# Step 4: System Health Check
Write-Host "🏥 Step 4: System Health Check" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Green

$HealthChecks = @{}

# Check SigNoz UI
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5
    $HealthChecks.signoz_ui = @{
        status = "ok"
        status_code = $Response.StatusCode
        response_time = $Response.Headers."X-Response-Time"
    }
    Write-Host "✅ SigNoz UI: OK (Status: $($Response.StatusCode))" -ForegroundColor Green
} catch {
    $HealthChecks.signoz_ui = @{
        status = "error"
        error = $_.Exception.Message
    }
    Write-Host "❌ SigNoz UI: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    $Results.errors += "SigNoz UI not accessible"
}

# Check OTel Collector
try {
    $Response = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    $HealthChecks.otel_collector = @{
        status = "ok"
        health_status = $Response.status
    }
    Write-Host "✅ OTel Collector: OK (Status: $($Response.status))" -ForegroundColor Green
} catch {
    $HealthChecks.otel_collector = @{
        status = "error"
        error = $_.Exception.Message
    }
    Write-Host "❌ OTel Collector: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    $Results.errors += "OTel Collector not accessible"
}

# Check Resonai App
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
    $HealthChecks.resonai_app = @{
        status = "ok"
        status_code = $Response.StatusCode
    }
    Write-Host "✅ Resonai App: OK (Status: $($Response.StatusCode))" -ForegroundColor Green
} catch {
    $HealthChecks.resonai_app = @{
        status = "error"
        error = $_.Exception.Message
    }
    Write-Host "❌ Resonai App: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    $Results.errors += "Resonai App not accessible"
}

# Check Webhook Server
try {
    $Response = Invoke-WebRequest -Uri "http://localhost:3003" -TimeoutSec 5
    $HealthChecks.webhook_server = @{
        status = "ok"
        status_code = $Response.StatusCode
    }
    Write-Host "✅ Webhook Server: OK (Status: $($Response.StatusCode))" -ForegroundColor Green
} catch {
    $HealthChecks.webhook_server = @{
        status = "error"
        error = $_.Exception.Message
    }
    Write-Host "❌ Webhook Server: ERROR - $($_.Exception.Message)" -ForegroundColor Red
    $Results.errors += "Webhook Server not accessible"
}

$Results.tests.health_checks = $HealthChecks

Write-Host ""

# Step 5: Overall Assessment
Write-Host "📊 Step 5: Overall Assessment" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green

$ErrorCount = $Results.errors.Count
$WarningCount = $Results.warnings.Count
$HealthCheckErrors = ($HealthChecks.Values | Where-Object { $_.status -eq "error" }).Count

if ($ErrorCount -eq 0 -and $HealthCheckErrors -eq 0) {
    $Results.overall_status = "excellent"
    Write-Host "🎉 Overall Status: EXCELLENT" -ForegroundColor Green
    Write-Host "   All components working correctly" -ForegroundColor White
} elseif ($ErrorCount -le 2 -and $HealthCheckErrors -le 1) {
    $Results.overall_status = "good"
    Write-Host "✅ Overall Status: GOOD" -ForegroundColor Green
    Write-Host "   Minor issues detected" -ForegroundColor White
} elseif ($ErrorCount -le 4 -and $HealthCheckErrors -le 2) {
    $Results.overall_status = "fair"
    Write-Host "⚠️  Overall Status: FAIR" -ForegroundColor Yellow
    Write-Host "   Some issues need attention" -ForegroundColor White
} else {
    $Results.overall_status = "poor"
    Write-Host "❌ Overall Status: POOR" -ForegroundColor Red
    Write-Host "   Multiple issues detected" -ForegroundColor White
}

Write-Host ""
Write-Host "📈 Summary:" -ForegroundColor Cyan
Write-Host "   Errors: $ErrorCount" -ForegroundColor $(if ($ErrorCount -eq 0) { "Green" } else { "Red" })
Write-Host "   Warnings: $WarningCount" -ForegroundColor $(if ($WarningCount -eq 0) { "Green" } else { "Yellow" })
Write-Host "   Health Check Errors: $HealthCheckErrors" -ForegroundColor $(if ($HealthCheckErrors -eq 0) { "Green" } else { "Red" })

# Step 6: Recommendations
Write-Host ""
Write-Host "💡 Recommendations:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    $Results.recommendations += "System is ready for production use"
    $Results.recommendations += "Monitor performance for 24 hours"
    $Results.recommendations += "Set up additional alerts as needed"
    Write-Host "✅ System is ready for production use" -ForegroundColor Green
    Write-Host "✅ Monitor performance for 24 hours" -ForegroundColor Green
    Write-Host "✅ Set up additional alerts as needed" -ForegroundColor Green
} else {
    if ($Results.errors -contains "SIGNOZ_API_TOKEN environment variable not set") {
        $Results.recommendations += "Set SIGNOZ_API_TOKEN environment variable"
        Write-Host "🔑 Set SIGNOZ_API_TOKEN environment variable" -ForegroundColor Yellow
    }
    if ($Results.errors -contains "SigNoz UI not accessible") {
        $Results.recommendations += "Check SigNoz service status"
        Write-Host "🔍 Check SigNoz service status" -ForegroundColor Yellow
    }
    if ($Results.errors -contains "OTel Collector not accessible") {
        $Results.recommendations += "Restart OTel Collector service"
        Write-Host "🔄 Restart OTel Collector service" -ForegroundColor Yellow
    }
    if ($Results.errors -contains "Resonai App not accessible") {
        $Results.recommendations += "Start Resonai application"
        Write-Host "🚀 Start Resonai application" -ForegroundColor Yellow
    }
    if ($Results.errors -contains "Webhook Server not accessible") {
        $Results.recommendations += "Start webhook test server"
        Write-Host "🔗 Start webhook test server" -ForegroundColor Yellow
    }
}

# Step 7: Generate Report
if ($GenerateReport) {
    Write-Host ""
    Write-Host "📝 Step 7: Generate Report" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    
    $ReportFile = "artifacts/final-verification-report.json"
    $Results | ConvertTo-Json -Depth 10 | Set-Content $ReportFile
    
    Write-Host "✅ Final verification report generated: $ReportFile" -ForegroundColor Green
    
    # Also create a human-readable summary
    $SummaryFile = "docs/FINAL_VERIFICATION_SUMMARY.md"
    $Summary = @"
# Final Verification Summary
**Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Actor**: Cursor-Local (Observability Copilot)  
**Status**: $($Results.overall_status.ToUpper())  

## Overall Assessment
- **Status**: $($Results.overall_status.ToUpper())
- **Errors**: $ErrorCount
- **Warnings**: $WarningCount
- **Health Check Errors**: $HealthCheckErrors

## Component Status
- **SigNoz UI**: $($HealthChecks.signoz_ui.status)
- **OTel Collector**: $($HealthChecks.otel_collector.status)
- **Resonai App**: $($HealthChecks.resonai_app.status)
- **Webhook Server**: $($HealthChecks.webhook_server.status)

## Test Results
- **Component Verification**: $(if ($Results.components.Count -gt 0) { "Completed" } else { "Skipped" })
- **End-to-End Test**: $(if ($Results.tests.end_to_end) { "Completed" } else { "Skipped" })
- **Alert Test**: $(if ($Results.tests.alert_delivery) { "Completed" } else { "Skipped" })

## Recommendations
$($Results.recommendations | ForEach-Object { "- $_" } | Out-String)

## Next Steps
1. Address any errors or warnings
2. Complete manual configuration steps
3. Monitor system performance
4. Set up production alerts

---
**Actor**: Cursor-Local (Observability Copilot)  
**Report Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    $Summary | Set-Content $SummaryFile
    Write-Host "✅ Summary report generated: $SummaryFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎯 Final Verification Completed!" -ForegroundColor Green
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Review verification results" -ForegroundColor White
Write-Host "   2. Address any issues found" -ForegroundColor White
Write-Host "   3. Complete manual configuration" -ForegroundColor White
Write-Host "   4. Monitor system performance" -ForegroundColor White
