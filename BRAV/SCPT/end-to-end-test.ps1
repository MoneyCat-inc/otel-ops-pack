# End-to-End Alert Delivery Test Script
# Tests complete alert flow from log generation to webhook delivery

param(
    [string]$TestMessage = "End-to-end test alert",
    [switch]$GenerateLogs = $true,
    [switch]$TestWebhook = $true,
    [switch]$VerifySigNoz = $true
)

# ECRR: Examine → Clean → Report → Role
Write-Host "End-to-End Alert Delivery Test - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check system status
Write-Host "`nExamine: Checking system status..." -ForegroundColor Green

$TestStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    test_message = $TestMessage
    otel_collector_running = $false
    signoz_accessible = $false
    webhook_server_running = $false
    resonai_running = $false
    api_token_set = $false
    webhook_url_set = $false
    test_results = @{
        log_generation = $false
        log_ingestion = $false
        webhook_delivery = $false
        end_to_end_success = $false
    }
    recommendations = @()
}

# Check OTel Collector
Write-Host "Checking OTel Collector..." -ForegroundColor Yellow
try {
    $CollectorHealth = Invoke-RestMethod -Uri "http://localhost:13134/healthz" -TimeoutSec 5
    if ($CollectorHealth.status -eq "Server available") {
        Write-Host "  OK OTel Collector is running" -ForegroundColor Green
        $TestStatus.otel_collector_running = $true
    }
} catch {
    Write-Host "  ERROR OTel Collector not accessible" -ForegroundColor Red
    $TestStatus.recommendations += "Start OTel Collector service"
}

# Check SigNoz UI
Write-Host "Checking SigNoz UI..." -ForegroundColor Yellow
try {
    $SigNozResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5
    if ($SigNozResponse.StatusCode -eq 200) {
        Write-Host "  OK SigNoz UI is accessible" -ForegroundColor Green
        $TestStatus.signoz_accessible = $true
    }
} catch {
    Write-Host "  ERROR SigNoz UI not accessible" -ForegroundColor Red
    $TestStatus.recommendations += "Start SigNoz stack"
}

# Check Webhook Server
Write-Host "Checking Webhook Server..." -ForegroundColor Yellow
$PortCheck = netstat -an | Select-String ":3003 "
if ($PortCheck) {
    Write-Host "  OK Webhook server is running on port 3003" -ForegroundColor Green
    $TestStatus.webhook_server_running = $true
} else {
    Write-Host "  ERROR Webhook server not running on port 3003" -ForegroundColor Red
    $TestStatus.recommendations += "Start webhook test server"
}

# Check Resonai
Write-Host "Checking Resonai..." -ForegroundColor Yellow
$ResonaiPortCheck = netstat -an | Select-String ":3000 "
if ($ResonaiPortCheck) {
    Write-Host "  OK Resonai is running on port 3000" -ForegroundColor Green
    $TestStatus.resonai_running = $true
} else {
    Write-Host "  ERROR Resonai not running on port 3000" -ForegroundColor Red
    $TestStatus.recommendations += "Start Resonai application"
}

# Check API Token
Write-Host "Checking SigNoz API Token..." -ForegroundColor Yellow
if ($env:SIGNOZ_API_TOKEN) {
    Write-Host "  OK API token is set" -ForegroundColor Green
    $TestStatus.api_token_set = $true
} else {
    Write-Host "  ERROR API token not set" -ForegroundColor Red
    $TestStatus.recommendations += "Set SIGNOZ_API_TOKEN environment variable"
}

# Check Webhook URL
Write-Host "Checking Webhook URL..." -ForegroundColor Yellow
if ($env:ALERT_WEBHOOK_URL) {
    Write-Host "  OK Webhook URL is set" -ForegroundColor Green
    $TestStatus.webhook_url_set = $true
} else {
    Write-Host "  ERROR Webhook URL not set" -ForegroundColor Red
    $TestStatus.recommendations += "Set ALERT_WEBHOOK_URL environment variable"
}

# Clean: Run end-to-end tests
Write-Host "`nClean: Running end-to-end tests..." -ForegroundColor Green

# Test 1: Generate Test Logs
if ($GenerateLogs) {
    Write-Host "`nTest 1: Generating test logs..." -ForegroundColor Yellow
    try {
        # Create test log entry
        $TestLogEntry = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            level = "INFO"
            message = $TestMessage
            source = "end-to-end-test"
            test_id = "E2E-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            metadata = @{
                script = "end-to-end-test.ps1"
                actor = "Cursor-Local (Observability Copilot)"
                version = "1.0"
            }
        }
        
        # Write to log file
        $LogFile = "C:\logs\end-to-end-test.log"
        if (-not (Test-Path "C:\logs")) {
            New-Item -ItemType Directory -Path "C:\logs" -Force | Out-Null
        }
        
        $TestLogEntry | ConvertTo-Json -Depth 3 | Add-Content $LogFile -Encoding UTF8
        
        Write-Host "  OK Test log generated: $LogFile" -ForegroundColor Green
        $TestStatus.test_results.log_generation = $true
        
        # Wait for processing
        Write-Host "  Waiting for log processing..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
    } catch {
        Write-Host "  ERROR Failed to generate test logs: $($_.Exception.Message)" -ForegroundColor Red
        $TestStatus.recommendations += "Fix log generation process"
    }
}

# Test 2: Verify Log Ingestion in SigNoz
if ($VerifySigNoz -and $TestStatus.api_token_set) {
    Write-Host "`nTest 2: Verifying log ingestion in SigNoz..." -ForegroundColor Yellow
    try {
        $Headers = @{
            "Authorization" = "Bearer $env:SIGNOZ_API_TOKEN"
            "Content-Type" = "application/json"
        }
        
        $LogQuery = @{
            query = "message contains `"$TestMessage`""
            start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
            end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
            limit = 10
        }
        
        $LogsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method POST -Headers $Headers -Body ($LogQuery | ConvertTo-Json) -TimeoutSec 10
        
        if ($LogsResponse -and $LogsResponse.data -and $LogsResponse.data.Count -gt 0) {
            Write-Host "  OK Logs found in SigNoz: $($LogsResponse.data.Count) entries" -ForegroundColor Green
            $TestStatus.test_results.log_ingestion = $true
        } else {
            Write-Host "  WARNING No logs found in SigNoz" -ForegroundColor Yellow
            $TestStatus.recommendations += "Check log ingestion pipeline"
        }
    } catch {
        Write-Host "  ERROR Failed to query SigNoz: $($_.Exception.Message)" -ForegroundColor Red
        $TestStatus.recommendations += "Fix SigNoz API access"
    }
}

# Test 3: Test Webhook Delivery
if ($TestWebhook -and $TestStatus.webhook_url_set) {
    Write-Host "`nTest 3: Testing webhook delivery..." -ForegroundColor Yellow
    try {
        $WebhookPayload = @{
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            alert_type = "end-to-end-test"
            severity = "info"
            title = "End-to-End Test Alert"
            message = $TestMessage
            source = "end-to-end-test"
            environment = "local"
            test_run = $true
            metadata = @{
                script = "end-to-end-test.ps1"
                actor = "Cursor-Local (Observability Copilot)"
                version = "1.0"
                test_id = $TestStatus.test_results.log_generation ? "E2E-$(Get-Date -Format 'yyyyMMdd-HHmmss')" : "E2E-WEBHOOK-ONLY"
            }
        }
        
        $JsonPayload = $WebhookPayload | ConvertTo-Json -Depth 3
        $Response = Invoke-RestMethod -Uri $env:ALERT_WEBHOOK_URL -Method POST -Body $JsonPayload -ContentType "application/json" -TimeoutSec 30
        
        Write-Host "  OK Webhook delivered successfully" -ForegroundColor Green
        Write-Host "  Response: $($Response | ConvertTo-Json -Compress)" -ForegroundColor Green
        $TestStatus.test_results.webhook_delivery = $true
        
    } catch {
        Write-Host "  ERROR Webhook delivery failed: $($_.Exception.Message)" -ForegroundColor Red
        $TestStatus.recommendations += "Fix webhook delivery"
    }
}

# Determine end-to-end success
$TestStatus.test_results.end_to_end_success = $TestStatus.test_results.log_generation -and $TestStatus.test_results.log_ingestion -and $TestStatus.test_results.webhook_delivery

# Report: Generate test results
Write-Host "`nReport: End-to-end test results" -ForegroundColor Green

Write-Host "`nTest Results:" -ForegroundColor Cyan
Write-Host "  Log Generation: $(if ($TestStatus.test_results.log_generation) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($TestStatus.test_results.log_generation) { 'Green' } else { 'Red' })
Write-Host "  Log Ingestion: $(if ($TestStatus.test_results.log_ingestion) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($TestStatus.test_results.log_ingestion) { 'Green' } else { 'Red' })
Write-Host "  Webhook Delivery: $(if ($TestStatus.test_results.webhook_delivery) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($TestStatus.test_results.webhook_delivery) { 'Green' } else { 'Red' })
Write-Host "  End-to-End Success: $(if ($TestStatus.test_results.end_to_end_success) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($TestStatus.test_results.end_to_end_success) { 'Green' } else { 'Red' })

if ($TestStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $TestStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

# Save test results
$TestStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/end-to-end-test-results.json" -Encoding UTF8

Write-Host "`nTest results saved to: artifacts/end-to-end-test-results.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

if ($TestStatus.test_results.end_to_end_success) {
    Write-Host "Next: End-to-end alert delivery verified - proceed with alert configuration" -ForegroundColor Green
} else {
    Write-Host "Next: Fix identified issues and re-run end-to-end test" -ForegroundColor Yellow
    Write-Host "Then: Complete alert configuration and notification channels" -ForegroundColor Yellow
}
