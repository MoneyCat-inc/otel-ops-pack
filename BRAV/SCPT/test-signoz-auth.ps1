# Test SigNoz Authentication Script
# Verifies API token access and authentication status

param(
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN,
    [string]$BaseUrl = "http://localhost:8080"
)

# ECRR: Examine → Clean → Report → Role
Write-Host "SigNoz Authentication Test - ECRR Framework" -ForegroundColor Cyan
Write-Host "Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Examine: Check current authentication status
Write-Host "`nExamine: Testing SigNoz authentication..." -ForegroundColor Green

if (-not $ApiToken) {
    Write-Host "ERROR: SIGNOZ_API_TOKEN environment variable not set" -ForegroundColor Red
    Write-Host "Please set: `$env:SIGNOZ_API_TOKEN = 'your-api-token-here'" -ForegroundColor Yellow
    exit 1
}

# Test 1: Health endpoint (no auth required)
Write-Host "`nTest 1: Health endpoint (no auth required)" -ForegroundColor Yellow
try {
    $HealthResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/health" -TimeoutSec 5
    Write-Host "  OK Health endpoint accessible: $($HealthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "  ERROR Health endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Logs API with authentication
Write-Host "`nTest 2: Logs API with authentication" -ForegroundColor Yellow
try {
    $Headers = @{
        "Authorization" = "Bearer $ApiToken"
        "Content-Type" = "application/json"
    }
    
    $LogQuery = @{
        query = "*"
        start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
        end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
        limit = 10
    }
    
    $LogsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/logs" -Method POST -Headers $Headers -Body ($LogQuery | ConvertTo-Json) -TimeoutSec 10
    
    if ($LogsResponse -and $LogsResponse.data) {
        Write-Host "  OK Logs API accessible: $($LogsResponse.data.Count) logs found" -ForegroundColor Green
    } else {
        Write-Host "  WARNING Logs API accessible but no data returned" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR Logs API failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "  HINT: Invalid or expired API token" -ForegroundColor Yellow
    } elseif ($_.Exception.Response.StatusCode -eq 403) {
        Write-Host "  HINT: Insufficient permissions for logs API" -ForegroundColor Yellow
    }
}

# Test 3: Metrics API with authentication
Write-Host "`nTest 3: Metrics API with authentication" -ForegroundColor Yellow
try {
    $MetricsQuery = @{
        query = "otelcol_receiver_accepted_log_records"
        start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
        end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
    }
    
    $MetricsResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/metrics" -Method POST -Headers $Headers -Body ($MetricsQuery | ConvertTo-Json) -TimeoutSec 10
    
    if ($MetricsResponse -and $MetricsResponse.data) {
        Write-Host "  OK Metrics API accessible: $($MetricsResponse.data.Count) metrics found" -ForegroundColor Green
    } else {
        Write-Host "  WARNING Metrics API accessible but no data returned" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR Metrics API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Traces API with authentication
Write-Host "`nTest 4: Traces API with authentication" -ForegroundColor Yellow
try {
    $TracesQuery = @{
        query = "*"
        start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
        end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds
        limit = 10
    }
    
    $TracesResponse = Invoke-RestMethod -Uri "$BaseUrl/api/v1/traces" -Method POST -Headers $Headers -Body ($TracesQuery | ConvertTo-Json) -TimeoutSec 10
    
    if ($TracesResponse -and $TracesResponse.data) {
        Write-Host "  OK Traces API accessible: $($TracesResponse.data.Count) traces found" -ForegroundColor Green
    } else {
        Write-Host "  WARNING Traces API accessible but no data returned" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR Traces API failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Report: Generate authentication status report
Write-Host "`nReport: Authentication status summary" -ForegroundColor Green

$AuthStatus = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    base_url = $BaseUrl
    api_token_set = [bool]$ApiToken
    health_accessible = $false
    logs_api_accessible = $false
    metrics_api_accessible = $false
    traces_api_accessible = $false
    recommendations = @()
}

# Update status based on test results
try {
    $HealthTest = Invoke-RestMethod -Uri "$BaseUrl/api/v1/health" -TimeoutSec 5
    $AuthStatus.health_accessible = $true
} catch {
    $AuthStatus.recommendations += "Fix SigNoz health endpoint accessibility"
}

try {
    $Headers = @{ "Authorization" = "Bearer $ApiToken"; "Content-Type" = "application/json" }
    $LogQuery = @{ query = "*"; start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds; end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds; limit = 1 }
    $LogsTest = Invoke-RestMethod -Uri "$BaseUrl/api/v1/logs" -Method POST -Headers $Headers -Body ($LogQuery | ConvertTo-Json) -TimeoutSec 5
    $AuthStatus.logs_api_accessible = $true
} catch {
    $AuthStatus.recommendations += "Fix logs API authentication or permissions"
}

try {
    $MetricsQuery = @{ query = "otelcol_receiver_accepted_log_records"; start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds; end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds }
    $MetricsTest = Invoke-RestMethod -Uri "$BaseUrl/api/v1/metrics" -Method POST -Headers $Headers -Body ($MetricsQuery | ConvertTo-Json) -TimeoutSec 5
    $AuthStatus.metrics_api_accessible = $true
} catch {
    $AuthStatus.recommendations += "Fix metrics API authentication or permissions"
}

try {
    $TracesQuery = @{ query = "*"; start = [int64]((Get-Date).AddMinutes(-5).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds; end = [int64]((Get-Date).ToUniversalTime() - (Get-Date "1970-01-01")).TotalSeconds; limit = 1 }
    $TracesTest = Invoke-RestMethod -Uri "$BaseUrl/api/v1/traces" -Method POST -Headers $Headers -Body ($TracesQuery | ConvertTo-Json) -TimeoutSec 5
    $AuthStatus.traces_api_accessible = $true
} catch {
    $AuthStatus.recommendations += "Fix traces API authentication or permissions"
}

# Save authentication status report
$AuthStatus | ConvertTo-Json -Depth 3 | Out-File "artifacts/signoz-auth-status.json" -Encoding UTF8

Write-Host "`nAuthentication Status:" -ForegroundColor Cyan
Write-Host "  Health Endpoint: $(if ($AuthStatus.health_accessible) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($AuthStatus.health_accessible) { 'Green' } else { 'Red' })
Write-Host "  Logs API: $(if ($AuthStatus.logs_api_accessible) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($AuthStatus.logs_api_accessible) { 'Green' } else { 'Red' })
Write-Host "  Metrics API: $(if ($AuthStatus.metrics_api_accessible) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($AuthStatus.metrics_api_accessible) { 'Green' } else { 'Red' })
Write-Host "  Traces API: $(if ($AuthStatus.traces_api_accessible) { 'OK' } else { 'ERROR' })" -ForegroundColor $(if ($AuthStatus.traces_api_accessible) { 'Green' } else { 'Red' })

if ($AuthStatus.recommendations.Count -gt 0) {
    Write-Host "`nRecommendations:" -ForegroundColor Yellow
    $AuthStatus.recommendations | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor Yellow
    }
}

Write-Host "`nReport saved to: artifacts/signoz-auth-status.json" -ForegroundColor Cyan

# Role: Declare actor and next steps
Write-Host "`nRole: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow
Write-Host "Next: Complete manual authentication setup in SigNoz UI" -ForegroundColor Yellow
Write-Host "Then: Import dashboard and configure webhook notifications" -ForegroundColor Yellow
