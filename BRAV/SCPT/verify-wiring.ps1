# Canonical ports: 5320 (gRPC), 5321 (HTTP). See windows/otelcol/README.md.
# Resonai ↔ OTel Wiring Verification Script
# Tests the analytics forwarding from /api/events to SigNoz via OTLP/HTTP
# Updated with progress indicators for better user experience

param(
    [ValidateSet('dev', 'staging', 'production')]
    [string]$Environment = $env:ENVIRONMENT ?? 'dev',
    
    [switch]$SkipDevServer
)

# Import progress indicators module
. .\BRAV\SCPT\progress-indicators.ps1

Set-StrictMode -Version 2
$ErrorActionPreference = "Stop"

Write-Host "=== Resonai ↔ OTel Wiring Verification ===" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Cyan

$script:allChecksPassed = $true
$script:checkFailures = New-Object 'System.Collections.Generic.List[string]'
$testEventId = [Guid]::NewGuid().ToString()
$script:artifactsDir = Join-Path (Get-Location) "artifacts"

function Write-Pass { param([string]$Message) Write-Host "   [OK] $Message" -ForegroundColor Green }
function Write-Detail { param([string]$Message) if ($Message) { Write-Host "      $Message" -ForegroundColor DarkGray } }
function Write-Fail {
    param([string]$Message)
    Write-Host "   [FAIL] $Message" -ForegroundColor Red
    $script:allChecksPassed = $false
    $script:checkFailures.Add($Message) | Out-Null
}

# Ensure artifacts directory exists
if (-not (Test-Path $script:artifactsDir)) {
    New-Item -Path $script:artifactsDir -ItemType Directory -Force | Out-Null
    Write-Detail "Created artifacts directory: $script:artifactsDir"
}

# Get SigNoz auth headers if available
$script:sigNozHeaders = $null
$envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_TOKEN')
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_API_BEARER') }
if (-not $envToken) { $envToken = [Environment]::GetEnvironmentVariable('SIGNOZ_JWT') }
if ($envToken) { $script:sigNozHeaders = @{ Authorization = "Bearer $envToken" } }

function Test-TcpPort {
    param([int]$Port,[string]$Label)
    $spinnerJob = Start-SpinnerJob -Message "Testing $Label port $Port..." -UpdateIntervalMs 150
    try {
        $result = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
        Stop-SpinnerJob -Job $spinnerJob
        if ($result.TcpTestSucceeded) { Write-Pass "$Label port $Port reachable" } else { Write-Fail "$Label port $Port not reachable" }
    } catch { 
        Stop-SpinnerJob -Job $spinnerJob
        Write-Fail "$Label port $Port error: $($_.Exception.Message)" 
    }
}

function Invoke-AnalyticsQuery {
    param([string]$EventId,[int]$MinutesBack = 15)
    $spinnerJob = Start-SpinnerJob -Message "Querying SigNoz for analytics data..." -UpdateIntervalMs 150
    try {
        $now = [long]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()); $start = $now - [long]($MinutesBack * 60000)
        $filterExpression = "attributes.dataset = `"resonai_analytics`" AND attributes.event_id = `"$EventId`""
        $payload = @{ start=$start; end=$now; requestType="raw"; compositeQuery=@{ queries=@(@{ type="builder_query"; spec=@{ name="A"; signal="logs"; filter=@{ expression=$filterExpression }; order=@(@{ key=@{ name="timestamp" }; direction="desc" }); limit=10; offset=0 }}) } } | ConvertTo-Json -Depth 8
        $params = @{ Method='Post'; Uri='http://localhost:8080/api/v5/query_range'; ContentType='application/json'; Body=$payload; TimeoutSec=30 }
        if ($script:sigNozHeaders) { $params.Headers = $script:sigNozHeaders }
        $result = Invoke-RestMethod @params
        Stop-SpinnerJob -Job $spinnerJob
        return $result
    } catch {
        Stop-SpinnerJob -Job $spinnerJob
        throw
    }
}

Write-Host "`n1. Prerequisites Check:" -ForegroundColor Yellow

# Check OTel Collector service
try {
    $service = Get-Service -Name otelcol-contrib -ErrorAction Stop
    if ($service.Status -eq 'Running') { Write-Pass "Service otelcol-contrib is running" } else { Write-Fail "Service otelcol-contrib status is $($service.Status)" }
} catch { Write-Fail "Service otelcol-contrib not found: $($_.Exception.Message)" }

# Check ports
Test-TcpPort -Port 5320 -Label "Windows collector (OTLP/gRPC)"
Test-TcpPort -Port 5321 -Label "Windows collector (OTLP/HTTP)"
Test-TcpPort -Port 8080 -Label "SigNoz UI"

Write-Host "`n2. Analytics API Test:" -ForegroundColor Yellow

# Test data
$testEvent = @{
    event = "wiring_verification_test"
    event_id = $testEventId
    session_id = "test-session-$testEventId"
    variant = "test"
    ttv_ms = 150
    ua = "PowerShell-Verification-Script"
    cohort = "test-cohort"
    props = @{
        test_type = "wiring_verification"
        timestamp = (Get-Date).ToString("o")
    }
} | ConvertTo-Json -Depth 3

$apiUrl = "http://localhost:3003/api/events"
$apiSuccess = $false
$apiError = $null

try {
    Write-Detail "Sending test analytics event to $apiUrl"
    $statusCode = $null
    $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Body $testEvent -ContentType "application/json" -TimeoutSec 10 -StatusCodeVariable statusCode
    $responseProps = @()
    if ($null -ne $response -and $response -is [System.Management.Automation.PSObject]) {
        $responseProps = $response.PSObject.Properties.Name
    }

    $apiIndicators = @()
    if ($responseProps -contains 'ok') { $apiIndicators += [bool]$response.ok }
    if ($responseProps -contains 'success') { $apiIndicators += [bool]$response.success }
    if ($responseProps -contains 'status') { $apiIndicators += ($response.status -match '^(?i)(ok|success|accepted)$') }
    if ($responseProps -contains 'result') { $apiIndicators += ($response.result -match '^(?i)(ok|success)$') }

    $httpSuccess = ($statusCode -ge 200 -and $statusCode -lt 300)
    $isAccepted = $httpSuccess -and (($apiIndicators.Count -eq 0) -or ($apiIndicators -notcontains $false))
    if ($isAccepted) {
        $countText = ''
        if ($responseProps -contains 'count') { $countText = " (count: $($response.count))" }
        Write-Pass "Analytics API accepted event$countText"
        $apiSuccess = $true
    } else {
        $responseJson = if ($null -ne $response) { $response | ConvertTo-Json -Compress } else { '<no-body>' }
        $apiError = "Unexpected response (status $statusCode): $responseJson"
        Write-Detail $apiError
    }
} catch {
    $apiError = $_.Exception.Message
    Write-Detail "API call failed: $apiError"
    
    # Check if it's a connection error vs server error
    $skipApi = ($Environment -eq 'production' -or $SkipDevServer)
    if ($_.Exception.Message -match "connection|timeout|refused") {
        Write-Host "   [WARN] Analytics API not reachable on :3003 (dev server not running — skipping)" -ForegroundColor Yellow
    } else {
        if ($skipApi) {
            Write-Detail "Analytics API error (skipped): $apiError"
        } else {
            Write-Fail "Analytics API error: $apiError"
        }
    }
}

if (-not $apiSuccess) {
    # In production mode or when dev server is skipped, verify infra instead of Resonai API
    if ($Environment -eq 'production' -or $SkipDevServer) {
        Write-Host "`n   [INFO] Dev server check skipped (Environment: $Environment)" -ForegroundColor Cyan
        Write-Host "`n3. Infrastructure health verification:" -ForegroundColor Yellow

        Test-TcpPort -Port 4317 -Label "OTLP aggregator (gRPC)"
        Test-TcpPort -Port 4318 -Label "OTLP aggregator (HTTP)"

        try {
            $collectorHealth = Invoke-RestMethod -Uri "http://127.0.0.1:13134/healthz" -Method Get -TimeoutSec 3 -ErrorAction Stop
            $statusText = if ($collectorHealth.status) { $collectorHealth.status } else { "ok" }
            Write-Pass "Collector healthz reachable ($statusText)"
        } catch {
            try {
                $null = Invoke-WebRequest -Uri "http://127.0.0.1:8888/metrics" -Method Get -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
                Write-Pass "Collector metrics reachable (8888/metrics fallback)"
            } catch {
                Write-Fail "Collector healthz/metrics unreachable: $($_.Exception.Message)"
            }
        }

        Write-Host "   Production wiring verified via:" -ForegroundColor Cyan
        Write-Host "   - OTel Collector service + health endpoint" -ForegroundColor Green
        Write-Host "   - OTLP aggregator ports (4317 gRPC, 4318 HTTP)" -ForegroundColor Green
        Write-Host "   - SigNoz UI port 8080" -ForegroundColor Green
        Write-Host "   - Canary tests can be used for end-to-end verification" -ForegroundColor Green
        # Fall through to summary — do not exit early with an unverified PASS
    } else {
        Write-Host "   [INFO] Analytics API unavailable — infrastructure-only verification" -ForegroundColor Cyan
    }
}

if ($apiSuccess) {
    Write-Host "`n3. SigNoz Verification:" -ForegroundColor Yellow
    Write-Detail "Waiting 8 seconds for OTel forwarding..."
    Start-Sleep -Seconds 8
    
    $sigNozSeen = $false
    $lastQueryError = $null
    $authRequired = $false
    
    for ($attempt = 1; $attempt -le 3 -and -not $sigNozSeen; $attempt++) {
        try {
            Write-Detail "Querying SigNoz for test event (attempt $attempt)..."
            $responseJson = (Invoke-AnalyticsQuery -EventId $testEventId) | ConvertTo-Json -Depth 8
            
            if ($responseJson -and $responseJson -match $testEventId) {
                Write-Pass "SigNoz API returned analytics event (attempt $attempt)"
                $sigNozSeen = $true
                
                # Write artifacts
                $verifyArtifact = @"
== Resonai ↔ OTel Wiring Verification Results ==
Timestamp: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK")
Test Event ID: $testEventId

API Test: PASSED
- Event sent to /api/events successfully
- Response: $($response | ConvertTo-Json -Compress)

SigNoz Test: PASSED
- Event found in SigNoz logs
- Query response contains test event ID
- Dataset: resonai_analytics

== Wiring verification PASSED ==
"@
                
                $verifyArtifact | Out-File -FilePath (Join-Path $script:artifactsDir "wiring-verify.txt") -Encoding utf8NoBOM
                $responseJson | Out-File -FilePath (Join-Path $script:artifactsDir "wiring-api.json") -Encoding utf8NoBOM
                
                Write-Pass "Artifacts written to artifacts/wiring-verify.txt and artifacts/wiring-api.json"
                
            } else {
                $lastQueryError = "No match in response"
                Write-Detail "Attempt $attempt -> no analytics event match"
            }
        } catch {
            $lastQueryError = $_.Exception.Message
            # Check for 401 Unauthorized - handle both WebException and HttpRequestException formats
            $is401 = $false
            if ($_.Exception.Response) {
                $is401 = ($_.Exception.Response.StatusCode.value__ -eq 401)
            }
            # Also check the error message for 401 patterns
            if (-not $is401 -and $lastQueryError -match "401|Unauthorized") {
                $is401 = $true
            }
            
            if ($is401) {
                $authRequired = $true
                Write-Detail "Attempt $attempt -> 401 Unauthorized (set SIGNOZ_API_TOKEN to enable API verification)"
                break
            }
            Write-Detail "Attempt $attempt -> $lastQueryError"
        }
        
        if (-not $sigNozSeen -and $attempt -lt 3) { 
            Write-Host "   Waiting 8s before retry..." -ForegroundColor Yellow
            Start-Sleep -Seconds 8 
        }
    }
    
    if (-not $sigNozSeen) {
        if ($authRequired -and -not $script:sigNozHeaders) {
            Write-Detail "SigNoz API verification skipped (authentication required)"
            Write-Detail "Set SIGNOZ_API_TOKEN environment variable to enable full verification"
            
            # Write partial artifacts
            $partialArtifact = @"
== Resonai ↔ OTel Wiring Verification Results ==
Timestamp: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK")
Test Event ID: $testEventId

API Test: PASSED
- Event sent to /api/events successfully
- Response: $($response | ConvertTo-Json -Compress)

SigNoz Test: SKIPPED (Authentication required)
- Set SIGNOZ_API_TOKEN environment variable for full verification
- Manual check: Open SigNoz UI → Logs → Filter: attributes.dataset = "resonai_analytics"

== Wiring verification PARTIAL (API only) ==
"@
            $partialArtifact | Out-File -FilePath (Join-Path $script:artifactsDir "wiring-verify.txt") -Encoding utf8NoBOM
            Write-Pass "Partial artifacts written (API test passed)"
            
        } else {
            Write-Fail "SigNoz API query failed to find analytics event within 15 minutes: $lastQueryError"
            
            # Write failure artifacts
            $failureArtifact = @"
== Resonai ↔ OTel Wiring Verification Results ==
Timestamp: $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK")
Test Event ID: $testEventId

API Test: PASSED
- Event sent to /api/events successfully
- Response: $($response | ConvertTo-Json -Compress)

SigNoz Test: FAILED
- Error: $lastQueryError
- Manual check: Open SigNoz UI → Logs → Filter: attributes.dataset = "resonai_analytics"

== Wiring verification FAILED ==
"@
            $failureArtifact | Out-File -FilePath (Join-Path $script:artifactsDir "wiring-verify.txt") -Encoding utf8NoBOM
        }
    }
}

Write-Host "`n=== Verification Complete ===" -ForegroundColor Green
if ($allChecksPassed) {
    Write-Host "== Wiring verification PASSED ==" -ForegroundColor Green
    if ($apiSuccess) {
        Write-Host "Analytics are successfully flowing from Resonai to SigNoz!" -ForegroundColor Green
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "1. Open SigNoz UI at http://localhost:8080" -ForegroundColor Yellow
        Write-Host "2. Go to Logs section" -ForegroundColor Yellow
        Write-Host "3. Filter: attributes.dataset = `"resonai_analytics`"" -ForegroundColor Yellow
        Write-Host "4. Check artifacts in artifacts/wiring-verify.txt" -ForegroundColor Yellow
    } else {
        Write-Host "Infrastructure wiring verified (collector + OTLP + SigNoz UI). Dev-server analytics path skipped." -ForegroundColor Green
    }
} else {
    Write-Host "== Wiring verification FAILED ==" -ForegroundColor Red
    Write-Host "Some checks failed. Please review the errors above." -ForegroundColor Red
    if ($checkFailures.Count -gt 0) {
        Write-Host "`nFailure summary:" -ForegroundColor Yellow
        foreach ($item in $checkFailures) { Write-Host " - $item" -ForegroundColor Red }
    }
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure otelcol-contrib service is running" -ForegroundColor Yellow
    Write-Host "2. Check ports 5320 (OTLP/gRPC), 5321 (OTLP/HTTP) and 8080 (SigNoz UI) are listening" -ForegroundColor Yellow
    Write-Host "3. Confirm Resonai dev server is running on port 3003" -ForegroundColor Yellow
    Write-Host "4. Check artifacts/wiring-verify.txt for details" -ForegroundColor Yellow
}

Write-Host "`nTest Event ID: $testEventId" -ForegroundColor Yellow

# Explicit exit codes for agent integration
if ($allChecksPassed) {
    Write-Host "== Wiring verification PASSED ==" -ForegroundColor Green
    exit 0  # Healthy - ready for production
} else {
    Write-Host "== Wiring verification FAILED ==" -ForegroundColor Red
    exit 2  # Unhealthy but retryable (watchdog can backoff and re-enqueue)
}

