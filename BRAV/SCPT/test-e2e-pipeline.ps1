# End-to-End Pipeline Test Script
# Tests complete OTel pipeline with authentication and monitoring

param(
    [string]$SigNozUrl,
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN,
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL,
    [switch]$SkipWebhookTest = $false
)

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts
if (-not $SigNozUrl) { $SigNozUrl = "http://localhost:$($script:OtelPorts.SignozUiHttp)" }

# ECRR: Examine → Clean → Report → Role
Write-Host "End-to-End Pipeline Test - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check pipeline components
Write-Host "`nExamine: Checking end-to-end pipeline components..." -ForegroundColor Green

$PipelineStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    signoz_url = $SigNozUrl
    api_token_set = $false
    webhook_url_set = $false
    otel_collector_running = $false
    signoz_accessible = $false
    pipeline_test_successful = $false
    test_results = @{}
    recommendations = @()
}

# Check OTel collector
Write-Host "Checking OTel collector..." -ForegroundColor Yellow
try {
    $CollectorHealth = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if ($CollectorHealth.status -eq "Server available") {
        Write-Host "  ✅ OTel collector is running" -ForegroundColor Green
        $PipelineStatus.otel_collector_running = $true
    }
} catch {
    Write-Host "  ❌ OTel collector not accessible" -ForegroundColor Red
    $PipelineStatus.recommendations += "Start OTel collector service"
}

# Check SigNoz accessibility
Write-Host "Checking SigNoz accessibility..." -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri $SigNozUrl -TimeoutSec 5
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  ✅ SigNoz UI accessible at $SigNozUrl" -ForegroundColor Green
        $PipelineStatus.signoz_accessible = $true
    }
} catch {
    Write-Host "  ❌ SigNoz UI not accessible at $SigNozUrl" -ForegroundColor Red
    $PipelineStatus.recommendations += "Start SigNoz stack (docker-compose up -d)"
}

# Check API token
Write-Host "Checking API token..." -ForegroundColor Yellow
if ($ApiToken) {
    Write-Host "  ✅ API token is set" -ForegroundColor Green
    $PipelineStatus.api_token_set = $true
} else {
    Write-Host "  ❌ API token not set" -ForegroundColor Red
    $PipelineStatus.recommendations += "Set SIGNOZ_API_TOKEN environment variable"
}

# Check webhook URL
Write-Host "Checking webhook URL..." -ForegroundColor Yellow
if ($WebhookUrl) {
    Write-Host "  ✅ Webhook URL is set" -ForegroundColor Green
    $PipelineStatus.webhook_url_set = $true
} else {
    Write-Host "  ❌ Webhook URL not set" -ForegroundColor Red
    $PipelineStatus.recommendations += "Set ALERT_WEBHOOK_URL environment variable"
}

# Clean: Run end-to-end tests
if ($PipelineStatus.otel_collector_running -and $PipelineStatus.signoz_accessible -and $PipelineStatus.api_token_set) {
    Write-Host "`nClean: Running end-to-end pipeline tests..." -ForegroundColor Green
    
    # Test 1: Generate canary logs
    Write-Host "`nTest 1: Generating canary logs..." -ForegroundColor Yellow
    try {
        # Create test log entry
        $TestLog = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            level = "info"
            message = "E2E Pipeline Test - $(Get-Date)"
            source = "e2e-test"
            test_id = [System.Guid]::NewGuid().ToString()
        }
        
        # Send to OTel collector
        $OtlpPayload = @{
            resourceLogs = @(
                @{
                    resource = @{
                        attributes = @(
                            @{ key = "service.name"; value = @{ stringValue = "e2e-test" } }
                            @{ key = "service.version"; value = @{ stringValue = "1.0.0" } }
                        )
                    }
                    scopeLogs = @(
                        @{
                            scope = @{ name = "e2e-test" }
                            logRecords = @(
                                @{
                                    timeUnixNano = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalMilliseconds * 1000000
                                    severityText = "INFO"
                                    body = @{ stringValue = $TestLog.message }
                                    attributes = @(
                                        @{ key = "test.id"; value = @{ stringValue = $TestLog.test_id } }
                                        @{ key = "test.source"; value = @{ stringValue = $TestLog.source } }
                                    )
                                }
                            )
                        }
                    )
                }
            )
        }
        
        $OtlpResponse = Invoke-RestMethod -Uri "$(Get-OtelIngestHttpBase -HostName 'localhost' -Ports $script:OtelPorts)/v1/logs" -Method POST -Body ($OtlpPayload | ConvertTo-Json -Depth 10) -ContentType "application/json" -TimeoutSec 10
        
        Write-Host "  ✅ Canary logs generated successfully" -ForegroundColor Green
        $PipelineStatus.test_results.canary_logs = $true
        
        # Wait for processing
        Write-Host "  Waiting for log processing (30 seconds)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
        
    } catch {
        Write-Host "  ❌ Canary log generation failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $PipelineStatus.test_results.canary_logs = $false
    }
    
    # Test 2: Query logs in SigNoz
    Write-Host "`nTest 2: Querying logs in SigNoz..." -ForegroundColor Yellow
    try {
        $Headers = @{
            "Authorization" = "Bearer $ApiToken"
            "Content-Type" = "application/json"
        }
        
        $LogQuery = @{
            query = "e2e-test"
            start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
            end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
            limit = 10
        }
        
        $LogsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method POST -Headers $Headers -Body ($LogQuery | ConvertTo-Json) -TimeoutSec 10
        
        if ($LogsResponse -and $LogsResponse.data -and $LogsResponse.data.Count -gt 0) {
            Write-Host "  ✅ Logs found in SigNoz: $($LogsResponse.data.Count) entries" -ForegroundColor Green
            $PipelineStatus.test_results.logs_query = $true
        } else {
            Write-Host "  ⚠️ No logs found in SigNoz (may need more time to process)" -ForegroundColor Yellow
            $PipelineStatus.test_results.logs_query = $false
        }
    } catch {
        Write-Host "  ❌ Log query failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $PipelineStatus.test_results.logs_query = $false
    }
    
    # Test 3: Query metrics
    Write-Host "`nTest 3: Querying metrics..." -ForegroundColor Yellow
    try {
        $MetricsQuery = @{
            query = "otelcol_receiver_accepted_log_records"
            start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
            end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
        }
        
        $MetricsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/metrics" -Method POST -Headers $Headers -Body ($MetricsQuery | ConvertTo-Json) -TimeoutSec 10
        
        if ($MetricsResponse -and $MetricsResponse.data) {
            Write-Host "  ✅ Metrics found in SigNoz: $($MetricsResponse.data.Count) metrics" -ForegroundColor Green
            $PipelineStatus.test_results.metrics_query = $true
        } else {
            Write-Host "  ⚠️ No metrics found in SigNoz" -ForegroundColor Yellow
            $PipelineStatus.test_results.metrics_query = $false
        }
    } catch {
        Write-Host "  ❌ Metrics query failed" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $PipelineStatus.test_results.metrics_query = $false
    }
    
    # Test 4: Webhook notification (if configured)
    if ($WebhookUrl -and -not $SkipWebhookTest) {
        Write-Host "`nTest 4: Testing webhook notifications..." -ForegroundColor Yellow
        try {
            $WebhookPayload = @{
                timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                test = $true
                message = "E2E Pipeline Test - Webhook Notification"
                source = "e2e-test"
                severity = "info"
                test_id = [System.Guid]::NewGuid().ToString()
            }
            
            $WebhookResponse = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body ($WebhookPayload | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
            
            Write-Host "  ✅ Webhook notification sent successfully" -ForegroundColor Green
            $PipelineStatus.test_results.webhook_notification = $true
        } catch {
            Write-Host "  ❌ Webhook notification failed" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            $PipelineStatus.test_results.webhook_notification = $false
        }
    } else {
        Write-Host "`nTest 4: Skipping webhook test (not configured)" -ForegroundColor Yellow
        $PipelineStatus.test_results.webhook_notification = $null
    }
    
    # Overall pipeline test result
    $SuccessfulTests = ($PipelineStatus.test_results.Values | Where-Object { $_ -eq $true }).Count
    $TotalTests = ($PipelineStatus.test_results.Values | Where-Object { $_ -ne $null }).Count
    
    if ($SuccessfulTests -eq $TotalTests) {
        Write-Host "`n  ✅ All pipeline tests passed ($SuccessfulTests/$TotalTests)" -ForegroundColor Green
        $PipelineStatus.pipeline_test_successful = $true
    } else {
        Write-Host "`n  ⚠️ Some pipeline tests failed ($SuccessfulTests/$TotalTests)" -ForegroundColor Yellow
        $PipelineStatus.pipeline_test_successful = $false
    }
} else {
    Write-Host "`nClean: Prerequisites not met for pipeline testing" -ForegroundColor Yellow
    Write-Host "Complete setup first:" -ForegroundColor White
    Write-Host "1. pwsh -File scripts/setup-signoz-authentication.ps1" -ForegroundColor Yellow
    Write-Host "2. pwsh -File scripts/import-dashboard.ps1" -ForegroundColor Yellow
    Write-Host "3. pwsh -File scripts/setup-webhooks.ps1" -ForegroundColor Yellow
}

# Report: Generate pipeline test report
Write-Host "`nReport: End-to-end pipeline test summary" -ForegroundColor Green

Write-Host "`nPipeline Test Results:" -ForegroundColor Cyan
Write-Host "  OTel Collector: $(if ($PipelineStatus.otel_collector_running) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($PipelineStatus.otel_collector_running) { 'Green' } else { 'Red' })
Write-Host "  SigNoz Access: $(if ($PipelineStatus.signoz_accessible) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($PipelineStatus.signoz_accessible) { 'Green' } else { 'Red' })
Write-Host "  API Token: $(if ($PipelineStatus.api_token_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($PipelineStatus.api_token_set) { 'Green' } else { 'Red' })
Write-Host "  Webhook URL: $(if ($PipelineStatus.webhook_url_set) { '✅ OK' } else { '❌ ERROR' })" -ForegroundColor $(if ($PipelineStatus.webhook_url_set) { 'Green' } else { 'Red' })

Write-Host "`nTest Results:" -ForegroundColor Cyan
foreach ($test in $PipelineStatus.test_results.GetEnumerator()) {
    $status = if ($test.Value -eq $true) { "✅ PASS" } elseif ($test.Value -eq $false) { "❌ FAIL" } else { "⏭️ SKIP" }
    Write-Host "  $($test.Key): $status" -ForegroundColor $(if ($test.Value -eq $true) { 'Green' } elseif ($test.Value -eq $false) { 'Red' } else { 'Yellow' })
}

if ($PipelineStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $PipelineStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save pipeline test report
$PipelineStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/e2e-pipeline-test.json" -Encoding UTF8

Write-Host "`nReport saved to: artifacts/e2e-pipeline-test.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($PipelineStatus.pipeline_test_successful) {
    Write-Host "Next: End-to-end pipeline test complete - system ready for production" -ForegroundColor Green
    Write-Host "Then: Monitor dashboard and configure alert thresholds" -ForegroundColor Green
} else {
    Write-Host "Next: Fix failing pipeline components and re-run tests" -ForegroundColor Yellow
    Write-Host "Then: Complete setup and verify all components working" -ForegroundColor Yellow
}

# Pipeline monitoring guidance
if ($PipelineStatus.pipeline_test_successful) {
    Write-Host "`n=== PIPELINE MONITORING ===" -ForegroundColor Cyan
    Write-Host "1. Monitor queue pressure dashboard in SigNoz" -ForegroundColor White
    Write-Host "2. Set up alert rules for critical thresholds" -ForegroundColor White
    Write-Host "3. Test alert delivery to webhook endpoints" -ForegroundColor White
    Write-Host "4. Configure automated monitoring schedules" -ForegroundColor White
    Write-Host "5. Document operational procedures" -ForegroundColor White
}
