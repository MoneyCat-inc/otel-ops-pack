# Simple Webhook Test Script
# Tests webhook with different payload formats

param(
    [string]$WebhookUrl = $env:ALERT_WEBHOOK_URL,
    [string]$TestMessage = "OTel pipeline test alert"
)

Write-Host "Simple Webhook Test - Testing Different Formats" -ForegroundColor Cyan

if (-not $WebhookUrl) {
    Write-Host "ERROR: ALERT_WEBHOOK_URL not set" -ForegroundColor Red
    exit 1
}

Write-Host "Testing webhook: $WebhookUrl" -ForegroundColor Yellow

# Test 1: Simple JSON payload
Write-Host "`nTest 1: Simple JSON payload" -ForegroundColor Yellow
try {
    $Payload1 = @{
        message = $TestMessage
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        source = "otel-pipeline"
    } | ConvertTo-Json
    
    $Response1 = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body $Payload1 -ContentType "application/json" -TimeoutSec 10
    Write-Host "  ✅ Success: $($Response1)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Plain text payload
Write-Host "`nTest 2: Plain text payload" -ForegroundColor Yellow
try {
    $Response2 = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body $TestMessage -ContentType "text/plain" -TimeoutSec 10
    Write-Host "  ✅ Success: $($Response2)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Form data payload
Write-Host "`nTest 3: Form data payload" -ForegroundColor Yellow
try {
    $FormData = @{
        message = $TestMessage
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        source = "otel-pipeline"
    }
    
    $Response3 = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Body $FormData -TimeoutSec 10
    Write-Host "  ✅ Success: $($Response3)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: With Host header
Write-Host "`nTest 4: With Host header" -ForegroundColor Yellow
try {
    $Headers = @{
        "Host" = "192.168.0.76:3003"
        "Content-Type" = "application/json"
    }
    
    $Payload4 = @{
        message = $TestMessage
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    } | ConvertTo-Json
    
    $Response4 = Invoke-RestMethod -Uri $WebhookUrl -Method POST -Headers $Headers -Body $Payload4 -TimeoutSec 10
    Write-Host "  ✅ Success: $($Response4)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: GET request to check endpoint
Write-Host "`nTest 5: GET request to check endpoint" -ForegroundColor Yellow
try {
    $Response5 = Invoke-RestMethod -Uri $WebhookUrl -Method GET -TimeoutSec 10
    Write-Host "  ✅ GET Success: $($Response5)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ GET Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nWebhook testing complete!" -ForegroundColor Cyan
