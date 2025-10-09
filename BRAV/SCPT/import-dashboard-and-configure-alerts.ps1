# Dashboard Import and Alert Configuration Script
# ECRR Framework: Examine → Clean → Report → Role
# Actor: Cursor Agent - Observability Copilot

param(
    [switch]$DryRun,
    [switch]$SkipDashboard,
    [switch]$SkipAlerts
)

Write-Host "📊 Dashboard Import and Alert Configuration" -ForegroundColor Cyan
Write-Host "Actor: Cursor Agent - Observability Copilot" -ForegroundColor Gray
Write-Host ""

# Examine: Check Prerequisites
Write-Host "🔍 Examine: Checking Prerequisites..." -ForegroundColor Yellow

$Prerequisites = @{
    SigNozApiToken = $false
    DashboardJson = $false
    SigNozUiAccessible = $false
    WebhookUrl = $false
}

# Check SigNoz API Token
if ($env:SIGNOZ_API_TOKEN) {
    $Prerequisites.SigNozApiToken = $true
    Write-Host "  ✅ SigNoz API Token: Available" -ForegroundColor Green
} else {
    Write-Host "  ❌ SigNoz API Token: Not set" -ForegroundColor Red
}

# Check Dashboard JSON File
$DashboardPath = "artifacts/signoz-queue-pressure-dashboard.json"
if (Test-Path $DashboardPath) {
    $Prerequisites.DashboardJson = $true
    Write-Host "  ✅ Dashboard JSON: Available" -ForegroundColor Green
} else {
    Write-Host "  ❌ Dashboard JSON: Missing ($DashboardPath)" -ForegroundColor Red
}

# Check SigNoz UI Accessibility
try {
    $UiResponse = Invoke-WebRequest -Uri "http://localhost:8080" -Method Get -TimeoutSec 5
    if ($UiResponse.StatusCode -eq 200) {
        $Prerequisites.SigNozUiAccessible = $true
        Write-Host "  ✅ SigNoz UI: Accessible" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ SigNoz UI: HTTP $($UiResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ❌ SigNoz UI: Not accessible" -ForegroundColor Red
}

# Check Webhook URL
if ($env:ALERT_WEBHOOK_URL) {
    $Prerequisites.WebhookUrl = $true
    Write-Host "  ✅ Alert Webhook URL: Available" -ForegroundColor Green
} else {
    Write-Host "  ❌ Alert Webhook URL: Not set" -ForegroundColor Red
}

# Clean: Import Dashboard
if (-not $SkipDashboard -and $Prerequisites.DashboardJson -and $Prerequisites.SigNozUiAccessible) {
    Write-Host ""
    Write-Host "🧹 Clean: Importing Dashboard..." -ForegroundColor Yellow
    
    if (-not $DryRun) {
        Write-Host "  📊 Dashboard Import Instructions:" -ForegroundColor Cyan
        Write-Host "    1. Open browser: http://localhost:8080" -ForegroundColor White
        Write-Host "    2. Navigate to Dashboards" -ForegroundColor White
        Write-Host "    3. Click 'Import Dashboard'" -ForegroundColor White
        Write-Host "    4. Upload file: $DashboardPath" -ForegroundColor White
        Write-Host "    5. Verify dashboard name: 'OTel Queue Pressure Monitor'" -ForegroundColor White
        Write-Host "    6. Click 'Import'" -ForegroundColor White
        Write-Host ""
        Write-Host "  💡 Dashboard contains 5 panels:" -ForegroundColor Cyan
        Write-Host "    • Queue Utilization Ratio (Stat)" -ForegroundColor White
        Write-Host "    • Queue Size vs Capacity (Time Series)" -ForegroundColor White
        Write-Host "    • Send Failure Rate (Stat)" -ForegroundColor White
        Write-Host "    • Batch Timeout Triggers (Time Series)" -ForegroundColor White
        Write-Host "    • Log Processing Rate (Time Series)" -ForegroundColor White
        
        # Try to open the dashboard file for user convenience
        try {
            Start-Process "notepad.exe" -ArgumentList $DashboardPath -ErrorAction SilentlyContinue
            Write-Host "  📝 Dashboard JSON opened in Notepad for reference" -ForegroundColor Green
        } catch {
            Write-Host "  💡 Dashboard file location: $DashboardPath" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  🔍 Dry run: Dashboard import would proceed" -ForegroundColor Gray
    }
} elseif ($SkipDashboard) {
    Write-Host ""
    Write-Host "  ⏭️ Dashboard import: Skipped by user" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "  ❌ Dashboard import: Cannot proceed (missing prerequisites)" -ForegroundColor Red
}

# Clean: Configure Alerts
if (-not $SkipAlerts -and $Prerequisites.SigNozApiToken -and $Prerequisites.WebhookUrl) {
    Write-Host ""
    Write-Host "🧹 Clean: Configuring Alerts..." -ForegroundColor Yellow
    
    $AlertConfigs = @(
        @{
            Name = "Queue Utilization High"
            Description = "Queue utilization above 70% for 10 minutes"
            Query = "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity"
            Threshold = 0.7
            Duration = "10m"
            Severity = "critical"
            Message = "🚨 Queue utilization is above 70% for 10 minutes. Check collector performance and batch processing."
        },
        @{
            Name = "Send Failure Rate High"
            Description = "Send failure rate above 5%"
            Query = "rate(otelcol_exporter_send_failed_log_records_total[5m]) / rate(otelcol_exporter_sent_log_records_total[5m])"
            Threshold = 0.05
            Duration = "5m"
            Severity = "critical"
            Message = "🚨 Send failure rate is above 5%. Check exporter connectivity and SigNoz health."
        },
        @{
            Name = "Batch Timeout Triggers High"
            Description = "High frequency of batch timeout triggers"
            Query = "rate(otelcol_processor_batch_timeout_trigger_send[5m])"
            Threshold = 10
            Duration = "5m"
            Severity = "warning"
            Message = "⚠️ High frequency of batch timeout triggers. Consider optimizing batch configuration."
        },
        @{
            Name = "Log Processing Rate Low"
            Description = "Log processing rate below 1 log/second"
            Query = "rate(otelcol_receiver_accepted_log_records_total[5m])"
            Threshold = 1
            Duration = "10m"
            Severity = "warning"
            Message = "⚠️ Log processing rate is low. Check log ingestion pipeline."
        }
    )
    
    if (-not $DryRun) {
        Write-Host "  🚨 Alert Configuration Instructions:" -ForegroundColor Cyan
        Write-Host "    1. Open browser: http://localhost:8080" -ForegroundColor White
        Write-Host "    2. Navigate to Alerts → New Alert" -ForegroundColor White
        Write-Host "    3. Configure each alert with the following settings:" -ForegroundColor White
        Write-Host ""
        
        foreach ($Alert in $AlertConfigs) {
            Write-Host "    📊 Alert: $($Alert.Name)" -ForegroundColor Yellow
            Write-Host "      Query: $($Alert.Query)" -ForegroundColor White
            Write-Host "      Threshold: $($Alert.Threshold)" -ForegroundColor White
            Write-Host "      Duration: $($Alert.Duration)" -ForegroundColor White
            Write-Host "      Severity: $($Alert.Severity)" -ForegroundColor White
            Write-Host "      Message: $($Alert.Message)" -ForegroundColor White
            Write-Host ""
        }
        
        Write-Host "  💡 Webhook URL for notifications: $env:ALERT_WEBHOOK_URL" -ForegroundColor Cyan
        
        # Generate alert configuration file
        $AlertConfigPath = "artifacts/signoz-alert-configs.json"
        $AlertConfigs | ConvertTo-Json -Depth 10 | Set-Content -Path $AlertConfigPath
        Write-Host "  📝 Alert configurations saved to: $AlertConfigPath" -ForegroundColor Green
        
    } else {
        Write-Host "  🔍 Dry run: Alert configuration would proceed" -ForegroundColor Gray
        Write-Host "  📊 Would configure $($AlertConfigs.Count) alerts" -ForegroundColor Gray
    }
} elseif ($SkipAlerts) {
    Write-Host ""
    Write-Host "  ⏭️ Alert configuration: Skipped by user" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "  ❌ Alert configuration: Cannot proceed (missing prerequisites)" -ForegroundColor Red
}

# Report: Test Configuration
Write-Host ""
Write-Host "📝 Report: Testing Configuration..." -ForegroundColor Yellow

if ($Prerequisites.SigNozApiToken) {
    try {
        $Headers = @{ "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN" }
        
        # Test logs API
        $LogsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method Get -Headers $Headers -TimeoutSec 10
        Write-Host "  ✅ SigNoz API: Logs accessible" -ForegroundColor Green
        
        # Test metrics API
        try {
            $MetricsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/metrics" -Method Get -Headers $Headers -TimeoutSec 10
            Write-Host "  ✅ SigNoz API: Metrics accessible" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️ SigNoz API: Metrics test failed" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ❌ SigNoz API: Test failed - $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ⏭️ SigNoz API: Test skipped (no token)" -ForegroundColor Gray
}

if ($Prerequisites.WebhookUrl) {
    try {
        $TestPayload = @{
            text = "Test alert from dashboard configuration"
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            source = "dashboard-setup"
            severity = "info"
        } | ConvertTo-Json
        
        $WebhookResponse = Invoke-RestMethod -Uri $env:ALERT_WEBHOOK_URL -Method Post -Body $TestPayload -ContentType "application/json" -TimeoutSec 10
        Write-Host "  ✅ Webhook: Test notification sent" -ForegroundColor Green
        
    } catch {
        Write-Host "  ❌ Webhook: Test failed - $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "  ⏭️ Webhook: Test skipped (no URL)" -ForegroundColor Gray
}

# Role: Generate Configuration Summary
Write-Host ""
Write-Host "🎭 Role: Configuration Summary..." -ForegroundColor Yellow

$DashboardReady = $Prerequisites.DashboardJson -and $Prerequisites.SigNozUiAccessible
$AlertsReady = $Prerequisites.SigNozApiToken -and $Prerequisites.WebhookUrl

if ($DashboardReady) {
    Write-Host "  ✅ Dashboard: Ready for import" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Dashboard: Manual import required" -ForegroundColor Yellow
}

if ($AlertsReady) {
    Write-Host "  ✅ Alerts: Ready for configuration" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Alerts: Prerequisites not met" -ForegroundColor Yellow
}

# Generate configuration report
$ReportPath = "artifacts/dashboard-alert-config-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
$ReportContent = @"
# Dashboard and Alert Configuration Report

**Date**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Actor**: Cursor Agent - Observability Copilot  
**Mode**: $(if ($DryRun) { 'Dry Run' } else { 'Live Configuration' })

## Prerequisites Status
- **SigNoz API Token**: $(if ($Prerequisites.SigNozApiToken) { '✅ Available' } else { '❌ Missing' })
- **Dashboard JSON**: $(if ($Prerequisites.DashboardJson) { '✅ Available' } else { '❌ Missing' })
- **SigNoz UI**: $(if ($Prerequisites.SigNozUiAccessible) { '✅ Accessible' } else { '❌ Not Accessible' })
- **Webhook URL**: $(if ($Prerequisites.WebhookUrl) { '✅ Available' } else { '❌ Missing' })

## Configuration Status
- **Dashboard Import**: $(if ($DashboardReady) { '✅ Ready' } else { '⚠️ Manual Required' })
- **Alert Configuration**: $(if ($AlertsReady) { '✅ Ready' } else { '⚠️ Prerequisites Missing' })

## Dashboard Details
- **File**: $DashboardPath
- **Name**: OTel Queue Pressure Monitor
- **Panels**: 5 (Queue Utilization, Queue Size vs Capacity, Send Failure Rate, Batch Timeout Triggers, Log Processing Rate)
- **Refresh**: 30s
- **Tags**: otel, queue, pressure, monitoring

## Alert Configurations
$(if ($AlertsReady) {
    "- Queue Utilization High (70% threshold, 10m duration)
- Send Failure Rate High (5% threshold, 5m duration)
- Batch Timeout Triggers High (10/sec threshold, 5m duration)
- Log Processing Rate Low (1 log/sec threshold, 10m duration)"
} else {
    "Alert configuration skipped due to missing prerequisites"
})

## Next Steps
$(if ($DashboardReady -and $AlertsReady) {
    "1. Import dashboard in SigNoz UI
2. Configure alerts with provided settings
3. Test alert notifications via webhook
4. Monitor dashboard and alert performance
5. Run end-to-end pipeline test"
} else {
    "1. Complete missing prerequisites (API token, webhook URL)
2. Re-run this script to configure alerts
3. Manually import dashboard if needed
4. Verify all components are working"
})

## Manual Steps Required
1. **Dashboard Import**: Access http://localhost:8080 → Dashboards → Import → Upload $DashboardPath
2. **Alert Configuration**: Access http://localhost:8080 → Alerts → New Alert → Configure with provided settings
3. **Webhook Testing**: Verify notifications are received at $env:ALERT_WEBHOOK_URL

---
**Generated by**: Dashboard Import and Alert Configuration Script  
**ECRR Framework**: Examine → Clean → Report → Role
"@

New-Item -Path (Split-Path $ReportPath -Parent) -ItemType Directory -Force | Out-Null
Set-Content -Path $ReportPath -Value $ReportContent
Write-Host "  📊 Configuration report saved to: $ReportPath" -ForegroundColor Green

Write-Host ""
Write-Host "✅ Dashboard and Alert Configuration Complete!" -ForegroundColor Green

if (-not $DashboardReady -or -not $AlertsReady) {
    Write-Host ""
    Write-Host "🔧 Manual Steps Required:" -ForegroundColor Yellow
    if (-not $DashboardReady) {
        Write-Host "  • Import dashboard manually in SigNoz UI" -ForegroundColor White
    }
    if (-not $AlertsReady) {
        Write-Host "  • Set up API token and webhook URL" -ForegroundColor White
        Write-Host "  • Re-run this script to configure alerts" -ForegroundColor White
    }
}
