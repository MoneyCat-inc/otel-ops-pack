# Verify All Components Script
# Comprehensive verification of all system components

param(
    [switch]$Detailed = $false,
    [switch]$TestEndToEnd = $true,
    [switch]$GenerateReport = $true
)

# ECRR: Examine → Clean → Report → Role
Write-Host "Verify All Components - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check all system components
Write-Host "`nExamine: Checking all system components..." -ForegroundColor Green

$VerificationStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    components = @{
        signoz_ui = @{ status = "unknown"; details = @{} }
        otel_collector = @{ status = "unknown"; details = @{} }
        resonai_app = @{ status = "unknown"; details = @{} }
        webhook_server = @{ status = "unknown"; details = @{} }
        api_token = @{ status = "unknown"; details = @{} }
        webhook_url = @{ status = "unknown"; details = @{} }
        dashboard_config = @{ status = "unknown"; details = @{} }
        log_processing = @{ status = "unknown"; details = @{} }
        webhook_delivery = @{ status = "unknown"; details = @{} }
    }
    overall_status = "unknown"
    recommendations = @()
    test_results = @{}
}

# Component 1: SigNoz UI
Write-Host "`nComponent 1: SigNoz UI" -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  OK SigNoz UI is accessible" -ForegroundColor Green
        $VerificationStatus.components.signoz_ui.status = "ok"
        $VerificationStatus.components.signoz_ui.details.status_code = $SigNozResponse.StatusCode
        $VerificationStatus.components.signoz_ui.details.response_time = $SigNozResponse.Headers.'X-Response-Time'
    }
} catch {
    Write-Host "  ERROR SigNoz UI not accessible: $($_.Exception.Message)" -ForegroundColor Red
    $VerificationStatus.components.signoz_ui.status = "error"
    $VerificationStatus.components.signoz_ui.details.error = $_.Exception.Message
    $VerificationStatus.recommendations += "Start SigNoz stack (docker-compose up)"
}

# Component 2: OTel Collector
Write-Host "`nComponent 2: OTel Collector" -ForegroundColor Yellow
try {
    $CollectorHealth = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if ($CollectorHealth.status -eq "Server available") {
        Write-Host "  OK OTel Collector is running" -ForegroundColor Green
        $VerificationStatus.components.otel_collector.status = "ok"
        $VerificationStatus.components.otel_collector.details.status = $CollectorHealth.status
        
        # Get collector metrics
        try {
            $CollectorMetrics = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -TimeoutSec 5
            $LogRecords = ($CollectorMetrics | Select-String "otelcol_receiver_accepted_log_records").Line
            if ($LogRecords) {
                $LogCount = ($LogRecords | ForEach-Object { ($_ -split ' ')[-1] } | Measure-Object -Sum).Sum
                $VerificationStatus.components.otel_collector.details.logs_processed = $LogCount
                Write-Host "  OK Logs processed: $LogCount" -ForegroundColor Green
            }
        } catch {
            Write-Host "  WARNING Could not retrieve collector metrics" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  ERROR OTel Collector not accessible: $($_.Exception.Message)" -ForegroundColor Red
    $VerificationStatus.components.otel_collector.status = "error"
    $VerificationStatus.components.otel_collector.details.error = $_.Exception.Message
    $VerificationStatus.recommendations += "Start OTel Collector service"
}

# Component 3: Resonai Application
Write-Host "`nComponent 3: Resonai Application" -ForegroundColor Yellow
$ResonaiPortCheck = netstat -an | Select-String ":3000 "
if ($ResonaiPortCheck) {
    try {
        $ResonaiResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
        if ($ResonaiResponse.StatusCode -eq 200) {
            Write-Host "  OK Resonai application is running" -ForegroundColor Green
            $VerificationStatus.components.resonai_app.status = "ok"
            $VerificationStatus.components.resonai_app.details.status_code = $ResonaiResponse.StatusCode
            $VerificationStatus.components.resonai_app.details.port = 3000
        }
    } catch {
        Write-Host "  ERROR Resonai application not accessible: $($_.Exception.Message)" -ForegroundColor Red
        $VerificationStatus.components.resonai_app.status = "error"
        $VerificationStatus.components.resonai_app.details.error = $_.Exception.Message
    }
} else {
    Write-Host "  ERROR Resonai application not running on port 3000" -ForegroundColor Red
    $VerificationStatus.components.resonai_app.status = "error"
    $VerificationStatus.components.resonai_app.details.error = "Port 3000 not listening"
    $VerificationStatus.recommendations += "Start Resonai application (npm run dev)"
}

# Component 4: Webhook Server
Write-Host "`nComponent 4: Webhook Server" -ForegroundColor Yellow
$WebhookPortCheck = netstat -an | Select-String ":3003 "
if ($WebhookPortCheck) {
    try {
        $WebhookTest = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            test = $true
            message = "Component verification test"
        }
        
        $WebhookResponse = Invoke-RestMethod -Uri "http://localhost:3003/api/webhooks/alerts" -Method POST -Body ($WebhookTest | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 5
        
        Write-Host "  OK Webhook server is running and responsive" -ForegroundColor Green
        $VerificationStatus.components.webhook_server.status = "ok"
        $VerificationStatus.components.webhook_server.details.port = 3003
        $VerificationStatus.components.webhook_server.details.test_response = $WebhookResponse
    } catch {
        Write-Host "  ERROR Webhook server not responsive: $($_.Exception.Message)" -ForegroundColor Red
        $VerificationStatus.components.webhook_server.status = "error"
        $VerificationStatus.components.webhook_server.details.error = $_.Exception.Message
    }
} else {
    Write-Host "  ERROR Webhook server not running on port 3003" -ForegroundColor Red
    $VerificationStatus.components.webhook_server.status = "error"
    $VerificationStatus.components.webhook_server.details.error = "Port 3003 not listening"
    $VerificationStatus.recommendations += "Start webhook test server"
}

# Component 5: API Token Configuration
Write-Host "`nComponent 5: API Token Configuration" -ForegroundColor Yellow
if ($env:SIGNOZ_API_TOKEN) {
    Write-Host "  OK API token is set" -ForegroundColor Green
    $VerificationStatus.components.api_token.status = "ok"
    $VerificationStatus.components.api_token.details.token_length = $env:SIGNOZ_API_TOKEN.Length
    
    # Test API access
    try {
        $Headers = @{
            "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN"
            "Content-Type" = "application/json"
        }
        
        $ApiTest = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method POST -Headers $Headers -Body '{"query":"*","start":0,"end":0,"limit":1}' -TimeoutSec 5
        Write-Host "  OK API token is valid and working" -ForegroundColor Green
        $VerificationStatus.components.api_token.details.api_access = "ok"
    } catch {
        Write-Host "  WARNING API token set but API access failed: $($_.Exception.Message)" -ForegroundColor Yellow
        $VerificationStatus.components.api_token.details.api_access = "error"
        $VerificationStatus.components.api_token.details.api_error = $_.Exception.Message
    }
} else {
    Write-Host "  ERROR API token not set" -ForegroundColor Red
    $VerificationStatus.components.api_token.status = "error"
    $VerificationStatus.components.api_token.details.error = "SIGNOZ_API_TOKEN environment variable not set"
    $VerificationStatus.recommendations += "Set SIGNOZ_API_TOKEN environment variable"
}

# Component 6: Webhook URL Configuration
Write-Host "`nComponent 6: Webhook URL Configuration" -ForegroundColor Yellow
if ($env:ALERT_WEBHOOK_URL) {
    Write-Host "  OK Webhook URL is set: $env:ALERT_WEBHOOK_URL" -ForegroundColor Green
    $VerificationStatus.components.webhook_url.status = "ok"
    $VerificationStatus.components.webhook_url.details.url = $env:ALERT_WEBHOOK_URL
} else {
    Write-Host "  ERROR Webhook URL not set" -ForegroundColor Red
    $VerificationStatus.components.webhook_url.status = "error"
    $VerificationStatus.components.webhook_url.details.error = "ALERT_WEBHOOK_URL environment variable not set"
    $VerificationStatus.recommendations += "Set ALERT_WEBHOOK_URL environment variable"
}

# Component 7: Dashboard Configuration
Write-Host "`nComponent 7: Dashboard Configuration" -ForegroundColor Yellow
if (Test-Path "artifacts/signoz-queue-pressure-dashboard.json") {
    try {
        $DashboardConfig = Get-Content "artifacts/signoz-queue-pressure-dashboard.json" -Raw | ConvertFrom-Json
        Write-Host "  OK Dashboard configuration file exists and is valid" -ForegroundColor Green
        $VerificationStatus.components.dashboard_config.status = "ok"
        $VerificationStatus.components.dashboard_config.details.file_exists = $true
        $VerificationStatus.components.dashboard_config.details.panels_count = $DashboardConfig.dashboard.panels.Count
    } catch {
        Write-Host "  ERROR Dashboard configuration file is invalid: $($_.Exception.Message)" -ForegroundColor Red
        $VerificationStatus.components.dashboard_config.status = "error"
        $VerificationStatus.components.dashboard_config.details.error = $_.Exception.Message
    }
} else {
    Write-Host "  ERROR Dashboard configuration file not found" -ForegroundColor Red
    $VerificationStatus.components.dashboard_config.status = "error"
    $VerificationStatus.components.dashboard_config.details.error = "File not found"
    $VerificationStatus.recommendations += "Create dashboard configuration file"
}

# Component 8: Log Processing
Write-Host "`nComponent 8: Log Processing" -ForegroundColor Yellow
try {
    # Check if logs directory exists and has recent files
    if (Test-Path "C:\logs") {
        $RecentLogs = Get-ChildItem "C:\logs" -Filter "*.log" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-10) }
        if ($RecentLogs) {
            Write-Host "  OK Recent log files found: $($RecentLogs.Count) files" -ForegroundColor Green
            $VerificationStatus.components.log_processing.status = "ok"
            $VerificationStatus.components.log_processing.details.recent_files = $RecentLogs.Count
            $VerificationStatus.components.log_processing.details.latest_file = $RecentLogs[0].Name
        } else {
            Write-Host "  WARNING No recent log files found" -ForegroundColor Yellow
            $VerificationStatus.components.log_processing.status = "warning"
            $VerificationStatus.components.log_processing.details.warning = "No recent log files"
        }
    } else {
        Write-Host "  WARNING Logs directory not found" -ForegroundColor Yellow
        $VerificationStatus.components.log_processing.status = "warning"
        $VerificationStatus.components.log_processing.details.warning = "Logs directory not found"
    }
} catch {
    Write-Host "  ERROR Error checking log processing: $($_.Exception.Message)" -ForegroundColor Red
    $VerificationStatus.components.log_processing.status = "error"
    $VerificationStatus.components.log_processing.details.error = $_.Exception.Message
}

# Component 9: Webhook Delivery
Write-Host "`nComponent 9: Webhook Delivery" -ForegroundColor Yellow
if (Test-Path "artifacts/webhook-logs.json") {
    try {
        $WebhookLogs = Get-Content "artifacts/webhook-logs.json" -Raw | ConvertFrom-Json
        if ($WebhookLogs -and $WebhookLogs.Count -gt 0) {
            $RecentWebhooks = $WebhookLogs | Where-Object { [DateTime]::Parse($_.timestamp) -gt (Get-Date).AddMinutes(-10) }
            Write-Host "  OK Webhook delivery logs found: $($WebhookLogs.Count) total, $($RecentWebhooks.Count) recent" -ForegroundColor Green
            $VerificationStatus.components.webhook_delivery.status = "ok"
            $VerificationStatus.components.webhook_delivery.details.total_webhooks = $WebhookLogs.Count
            $VerificationStatus.components.webhook_delivery.details.recent_webhooks = $RecentWebhooks.Count
            $VerificationStatus.components.webhook_delivery.details.latest_webhook = $WebhookLogs[-1].timestamp
        } else {
            Write-Host "  WARNING No webhook delivery logs found" -ForegroundColor Yellow
            $VerificationStatus.components.webhook_delivery.status = "warning"
            $VerificationStatus.components.webhook_delivery.details.warning = "No webhook logs"
        }
    } catch {
        Write-Host "  ERROR Error reading webhook logs: $($_.Exception.Message)" -ForegroundColor Red
        $VerificationStatus.components.webhook_delivery.status = "error"
        $VerificationStatus.components.webhook_delivery.details.error = $_.Exception.Message
    }
} else {
    Write-Host "  WARNING Webhook logs file not found" -ForegroundColor Yellow
    $VerificationStatus.components.webhook_delivery.status = "warning"
    $VerificationStatus.components.webhook_delivery.details.warning = "Webhook logs file not found"
}

# Clean: Run end-to-end test if requested
if ($TestEndToEnd) {
    Write-Host "`nClean: Running end-to-end test..." -ForegroundColor Green
    
    try {
        $EndToEndTest = pwsh -File scripts/end-to-end-test.ps1 -TestMessage "Component verification test"
        $VerificationStatus.test_results.end_to_end_test = "completed"
    } catch {
        Write-Host "  ERROR End-to-end test failed: $($_.Exception.Message)" -ForegroundColor Red
        $VerificationStatus.test_results.end_to_end_test = "failed"
        $VerificationStatus.test_results.end_to_end_error = $_.Exception.Message
    }
}

# Calculate overall status
$ErrorCount = ($VerificationStatus.components.Values | Where-Object { $_.status -eq "error" }).Count
$WarningCount = ($VerificationStatus.components.Values | Where-Object { $_.status -eq "warning" }).Count
$OkCount = ($VerificationStatus.components.Values | Where-Object { $_.status -eq "ok" }).Count

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    $VerificationStatus.overall_status = "excellent"
} elseif ($ErrorCount -eq 0) {
    $VerificationStatus.overall_status = "good"
} elseif ($ErrorCount -le 2) {
    $VerificationStatus.overall_status = "fair"
} else {
    $VerificationStatus.overall_status = "poor"
}

# Report: Generate verification report
Write-Host "`nReport: Component verification summary" -ForegroundColor Green

Write-Host "`nOverall Status: $($VerificationStatus.overall_status.ToUpper())" -ForegroundColor $(switch ($VerificationStatus.overall_status) {
    "excellent" { "Green" }
    "good" { "Green" }
    "fair" { "Yellow" }
    "poor" { "Red" }
})

Write-Host "`nComponent Status:" -ForegroundColor Cyan
Write-Host "  SigNoz UI: $($VerificationStatus.components.signoz_ui.status)" -ForegroundColor $(if ($VerificationStatus.components.signoz_ui.status -eq "ok") { "Green" } else { "Red" })
Write-Host "  OTel Collector: $($VerificationStatus.components.otel_collector.status)" -ForegroundColor $(if ($VerificationStatus.components.otel_collector.status -eq "ok") { "Green" } else { "Red" })
Write-Host "  Resonai App: $($VerificationStatus.components.resonai_app.status)" -ForegroundColor $(if ($VerificationStatus.components.resonai_app.status -eq "ok") { "Green" } else { "Red" })
Write-Host "  Webhook Server: $($VerificationStatus.components.webhook_server.status)" -ForegroundColor $(if ($VerificationStatus.components.webhook_server.status -eq "ok") { "Green" } else { "Red" })
Write-Host "  API Token: $($VerificationStatus.components.api_token.status)" -ForegroundColor $(if ($VerificationStatus.components.api_token.status -eq "ok") { "Green" } else { "Red" })
Write-Host "  Webhook URL: $($VerificationStatus.components.webhook_url.status)" -ForegroundColor $(if ($VerificationStatus.components.webhook_url.status -eq "ok") { "Green" } else { "Red" })
Write-Host "  Dashboard Config: $($VerificationStatus.components.dashboard_config.status)" -ForegroundColor $(if ($VerificationStatus.components.dashboard_config.status -eq "ok") { "Green" } else { "Red" })
Write-Host "  Log Processing: $($VerificationStatus.components.log_processing.status)" -ForegroundColor $(if ($VerificationStatus.components.log_processing.status -eq "ok") { "Green" } elseif ($VerificationStatus.components.log_processing.status -eq "warning") { "Yellow" } else { "Red" })
Write-Host "  Webhook Delivery: $($VerificationStatus.components.webhook_delivery.status)" -ForegroundColor $(if ($VerificationStatus.components.webhook_delivery.status -eq "ok") { "Green" } elseif ($VerificationStatus.components.webhook_delivery.status -eq "warning") { "Yellow" } else { "Red" })

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  OK: $OkCount components" -ForegroundColor Green
Write-Host "  Warnings: $WarningCount components" -ForegroundColor Yellow
Write-Host "  Errors: $ErrorCount components" -ForegroundColor Red

if ($VerificationStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $VerificationStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save verification report
if ($GenerateReport) {
    $VerificationStatus | ConvertTo-Json -Depth 4 | Out-File "artifacts/component-verification-report.json" -Encoding UTF8
    Write-Host "`nVerification report saved to: artifacts/component-verification-report.json" -ForegroundColor Cyan
}

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($VerificationStatus.overall_status -eq "excellent") {
    Write-Host "Next: All components working perfectly - system ready for production use" -ForegroundColor Green
} elseif ($VerificationStatus.overall_status -eq "good") {
    Write-Host "Next: System working well with minor warnings - monitor and optimize" -ForegroundColor Green
} elseif ($VerificationStatus.overall_status -eq "fair") {
    Write-Host "Next: System functional but needs attention - address critical issues" -ForegroundColor Yellow
} else {
    Write-Host "Next: System has significant issues - fix errors before proceeding" -ForegroundColor Red
}
