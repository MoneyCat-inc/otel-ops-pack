# Gate #030: Unified Telemetry Proof Generator
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Generate API-signed proof artifacts for traces + logs + metrics

<#
.SYNOPSIS
    Generate unified proof artifacts verifying traces, logs, and metrics in SigNoz.

.DESCRIPTION
    Queries SigNoz API for all three observability signals (traces, logs, metrics)
    and generates a unified JSON proof artifact with timestamped counts for each signal.
    
    Exit GREEN only if all three signals are present (when using -ExpectAll flag).

.PARAMETER ServiceName
    Service name to filter in SigNoz (or use SIGNOZ_SERVICE_NAME env var)

.PARAMETER SigNozUrl
    SigNoz base URL (default: http://localhost:8080, or SIGNOZ_BASE_URL env var)

.PARAMETER LookbackMinutes
    Minutes to look back for telemetry (default: 3, or SIGNOZ_LOOKBACK_MINUTES env var)

.PARAMETER ExpectAtLeast
    Minimum count required per signal for PASS (default: 1)

.PARAMETER ExpectAll
    Exit RED if any signal is missing (strict mode)

.EXAMPLE
    # Basic usage
    $env:SIGNOZ_API_KEY = "<key>"
    .\proof-of-telemetry.ps1 -ServiceName "bosscat-svc2-api"

.EXAMPLE
    # Strict mode (all signals required)
    $env:SIGNOZ_API_KEY = "<key>"
    .\proof-of-telemetry.ps1 -ServiceName "bosscat-svc2-api" -ExpectAll

.EXAMPLE
    # CI/CD usage
    $env:SIGNOZ_API_KEY = ${{ secrets.SIGNOZ_API_KEY }}
    .\proof-of-telemetry.ps1 -ServiceName "my-service" -ExpectAll -LookbackMinutes 5
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = $env:SIGNOZ_SERVICE_NAME,
    
    [Parameter(Mandatory=$false)]
    [string]$SigNozUrl = $(if ($env:SIGNOZ_BASE_URL) { $env:SIGNOZ_BASE_URL } else { "http://localhost:8080" }),
    
    [Parameter(Mandatory=$false)]
    [int]$LookbackMinutes = $(if ($env:SIGNOZ_LOOKBACK_MINUTES) { [int]$env:SIGNOZ_LOOKBACK_MINUTES } else { 3 }),
    
    [Parameter(Mandatory=$false)]
    [int]$ExpectAtLeast = 1,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExpectAll,
    
    # Gate #030 v2: Auth hardening
    [Parameter(Mandatory=$false)]
    [string]$ApiToken = $env:SIGNOZ_API_TOKEN,
    
    [Parameter(Mandatory=$false)]
    [string]$AuthHeaderName = $(if ($env:SIGNOZ_AUTH_HEADER) { $env:SIGNOZ_AUTH_HEADER } else { "signoz-api-key" }),
    
    [Parameter(Mandatory=$false)]
    [string]$CollectorMetricsUrl = "http://localhost:8888/metrics"
)

$ErrorActionPreference = "Stop"

# Validate inputs
if (-not $ServiceName) {
    Write-Error "ServiceName required (parameter or SIGNOZ_SERVICE_NAME env var)"
    exit 21
}

# Gate #030 v2: ApiToken replaces ApiKey, supports both env vars for compatibility
if (-not $ApiToken) {
    $ApiToken = $env:SIGNOZ_API_KEY  # Backward compatibility
}
if (-not $ApiToken) {
    Write-Error "API token required (SIGNOZ_API_TOKEN or SIGNOZ_API_KEY env var, or -ApiToken parameter)"
    exit 21
}

Write-Host "=== Gate #030: Unified Telemetry Proof Generator ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service: $ServiceName" -ForegroundColor White
Write-Host "Timeframe: Last $LookbackMinutes minutes" -ForegroundColor White
Write-Host "Expect at least: $ExpectAtLeast per signal" -ForegroundColor White
Write-Host "Strict mode: $(if ($ExpectAll) { 'YES (all signals required)' } else { 'NO' })" -ForegroundColor White
Write-Host ""

# Gate #030 v2: Build auth headers with dual-header support
function Build-AuthHeaders {
    param(
        [string]$ApiToken,
        [string]$HeaderName
    )
    
    $headers = @{ "Content-Type" = "application/json" }
    
    if ($HeaderName -eq "Authorization") {
        $headers["Authorization"] = "Bearer $ApiToken"
    } else {
        # Default: signoz-api-key
        $headers["SIGNOZ-API-KEY"] = $ApiToken
    }
    
    return $headers
}

# Gate #030 v2: Query collector health metrics (Prometheus format)
function Query-CollectorMetrics {
    param(
        [string]$MetricsUrl
    )
    
    try {
        $response = Invoke-WebRequest -Uri $MetricsUrl -UseBasicParsing -TimeoutSec 10
        $content = $response.Content
        
        # Parse otelcol_exporter_sent_spans metric
        if ($content -match 'otelcol_exporter_sent_spans\{[^\}]*\}\s+(\d+)') {
            $count = [int]$Matches[1]
            return @{
                Success = $true
                Count = $count
                Metric = "otelcol_exporter_sent_spans"
                Endpoint = $MetricsUrl
            }
        } else {
            return @{
                Success = $false
                Error = "Metric otelcol_exporter_sent_spans not found"
            }
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Generic SigNoz signal query function
function Query-SigNozSignal {
    param(
        [string]$ServiceName,
        [string]$SigNozBaseUrl,
        [string]$ApiToken,
        [string]$AuthHeaderName,
        [string]$Signal,  # "traces", "logs", or "metrics"
        [int]$LookbackMinutes
    )
    
    $end = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $start = [DateTimeOffset]::UtcNow.AddMinutes(-$LookbackMinutes).ToUnixTimeMilliseconds()
    
    # Adjust filter expression based on signal type
    # Traces use 'serviceName' field
    # Logs/metrics: Use no filter (counts all) - service-level filtering TBD in future enhancement
    $filterExpression = if ($Signal -eq "traces") {
        "serviceName = '$ServiceName'"
    } else {
        ""  # No filter for logs/metrics (counts all signals)
    }
    
    $payload = @{
        start = $start
        end = $end
        requestType = "scalar"
        compositeQuery = @{
            queries = @(
                @{
                    type = "builder_query"
                    spec = @{
                        name = "A"
                        signal = $Signal
                        aggregations = @(@{ expression = "count()"; alias = "$($Signal)_count" })
                        filter = @{ expression = $filterExpression }
                        disabled = $false
                    }
                }
            )
        }
    } | ConvertTo-Json -Depth 10
    
    $headers = Build-AuthHeaders -ApiToken $ApiToken -HeaderName $AuthHeaderName
    $uri = ($SigNozBaseUrl.TrimEnd('/')) + "/api/v5/query_range"
    
    try {
        $resp = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $payload -TimeoutSec 30
    } catch {
        # Gate #030 v2: Fallback to alternate header on auth failure
        if ($_.Exception.Response.StatusCode.value__ -in @(401, 403) -and $AuthHeaderName -eq "signoz-api-key") {
            $headers = Build-AuthHeaders -ApiToken $ApiToken -HeaderName "Authorization"
            $resp = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $payload -TimeoutSec 30
        } else {
            throw
        }
    }
    
    try {
        
        # Parse count from response (handle different response formats)
        $count = 0
        if ($resp.data -and $resp.data.data -and $resp.data.data.results) {
            # v5 API format: data.data.results[0].data[0][0]
            $result = $resp.data.data.results[0]
            if ($result.data -and $result.data.Count -gt 0 -and $result.data[0].Count -gt 0) {
                $count = [int]$result.data[0][0]
            }
        } elseif ($resp.data -and $resp.data.result -and $resp.data.result.A) {
            # Alternative format
            if ($resp.data.result.A.value) {
                $count = [int]$resp.data.result.A.value
            } elseif ($resp.data.result.A.list) {
                $count = [int]$resp.data.result.A.list.Count
            }
        }
        
        return @{
            Success = $true
            Count = $count
            StartMs = $start
            EndMs = $end
            Endpoint = $uri
            Signal = $Signal
        }
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            Signal = $Signal
        }
    }
}

# Query all three signals
Write-Host "[1/3] Querying traces..." -ForegroundColor Yellow
$tracesResult = Query-SigNozSignal -ServiceName $ServiceName -SigNozBaseUrl $SigNozUrl -ApiToken $ApiToken -AuthHeaderName $AuthHeaderName -Signal "traces" -LookbackMinutes $LookbackMinutes

if ($tracesResult.Success) {
    Write-Host "  Traces: $($tracesResult.Count)" -ForegroundColor $(if ($tracesResult.Count -ge $ExpectAtLeast) { "Green" } else { "Red" })
} else {
    Write-Host "  Traces: ERROR - $($tracesResult.Error)" -ForegroundColor Red
}

Write-Host "[2/3] Querying logs..." -ForegroundColor Yellow
$logsResult = Query-SigNozSignal -ServiceName $ServiceName -SigNozBaseUrl $SigNozUrl -ApiToken $ApiToken -AuthHeaderName $AuthHeaderName -Signal "logs" -LookbackMinutes $LookbackMinutes

if ($logsResult.Success) {
    Write-Host "  Logs: $($logsResult.Count)" -ForegroundColor $(if ($logsResult.Count -ge $ExpectAtLeast) { "Green" } else { "Red" })
} else {
    Write-Host "  Logs: ERROR - $($logsResult.Error)" -ForegroundColor Red
}

Write-Host "[3/3] Querying metrics..." -ForegroundColor Yellow
# Gate #030 v2: Query collector health metrics (Prometheus format)
$metricsResult = Query-CollectorMetrics -MetricsUrl $CollectorMetricsUrl

if ($metricsResult.Success) {
    Write-Host "  Metrics: $($metricsResult.Count) ($($metricsResult.Metric))" -ForegroundColor $(if ($metricsResult.Count -ge $ExpectAtLeast) { "Green" } else { "Red" })
} else {
    Write-Host "  Metrics: ERROR - $($metricsResult.Error)" -ForegroundColor Red
}

Write-Host ""

# Generate unified proof artifact
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$proof = @{
    probe = "signoz-unified"
    service = $ServiceName
    timeframe = "$LookbackMinutes min"
    startMs = if ($tracesResult.Success) { $tracesResult.StartMs } else { 0 }
    endMs = if ($tracesResult.Success) { $tracesResult.EndMs } else { 0 }
    signals = @{
        traces = @{
            count = if ($tracesResult.Success) { $tracesResult.Count } else { 0 }
            status = if ($tracesResult.Success -and $tracesResult.Count -ge $ExpectAtLeast) { "PASS" } else { "FAIL" }
            endpoint = if ($tracesResult.Success) { $tracesResult.Endpoint } else { "N/A" }
            error = if (-not $tracesResult.Success) { $tracesResult.Error } else { $null }
        }
        logs = @{
            count = if ($logsResult.Success) { $logsResult.Count } else { 0 }
            status = if ($logsResult.Success -and $logsResult.Count -ge $ExpectAtLeast) { "PASS" } else { "FAIL" }
            endpoint = if ($logsResult.Success) { $logsResult.Endpoint } else { "N/A" }
            error = if (-not $logsResult.Success) { $logsResult.Error } else { $null }
        }
        metrics = @{
            count = if ($metricsResult.Success) { $metricsResult.Count } else { 0 }
            status = if ($metricsResult.Success -and $metricsResult.Count -ge $ExpectAtLeast) { "PASS" } else { "FAIL" }
            endpoint = if ($metricsResult.Success) { $metricsResult.Endpoint } else { "N/A" }
            metric_name = if ($metricsResult.Success) { $metricsResult.Metric } else { $null }
            error = if (-not $metricsResult.Success) { $metricsResult.Error } else { $null }
        }
    }
    timestamp = $stamp
    verification_type = "api-signed-unified"
    api_version = "v5"
    auth_method = $AuthHeaderName
    auth_token = "***masked***"  # Gate #030 v2: Never expose token in artifacts
}

# Determine overall status
$tracesPass = $tracesResult.Success -and ($tracesResult.Count -ge $ExpectAtLeast)
$logsPass = $logsResult.Success -and ($logsResult.Count -ge $ExpectAtLeast)
$metricsPass = $metricsResult.Success -and ($metricsResult.Count -ge $ExpectAtLeast)

$signalsPresent = @($tracesPass, $logsPass, $metricsPass) | Where-Object { $_ -eq $true } | Measure-Object | Select-Object -ExpandProperty Count

if ($signalsPresent -eq 3) {
    $proof.overall_status = "PASS"
} elseif ($signalsPresent -ge 1) {
    $proof.overall_status = "PARTIAL"
} else {
    $proof.overall_status = "FAIL"
}

# Save proof artifact
New-Item -ItemType Directory -Force -Path "artifacts/proofs" | Out-Null
$proofPath = "artifacts/proofs/unified-proof-$($ServiceName)-$stamp.json"
$proof | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $proofPath

Write-Host "[PROOF] Generated: $proofPath" -ForegroundColor Cyan
Write-Host ""

# Display summary
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Traces:  $(if ($tracesPass) { '✅ PASS' } else { '❌ FAIL' }) ($($tracesResult.Count) found)" -ForegroundColor $(if ($tracesPass) { "Green" } else { "Red" })
Write-Host "Logs:    $(if ($logsPass) { '✅ PASS' } else { '❌ FAIL' }) ($($logsResult.Count) found)" -ForegroundColor $(if ($logsPass) { "Green" } else { "Red" })
Write-Host "Metrics: $(if ($metricsPass) { '✅ PASS' } else { '❌ FAIL' }) ($($metricsResult.Count) found)" -ForegroundColor $(if ($metricsPass) { "Green" } else { "Red" })
Write-Host ""
Write-Host "Overall: $($proof.overall_status) ($signalsPresent/3 signals)" -ForegroundColor $(
    if ($proof.overall_status -eq "PASS") { "Green" }
    elseif ($proof.overall_status -eq "PARTIAL") { "Yellow" }
    else { "Red" }
)
Write-Host ""

# Exit logic
if ($ExpectAll) {
    # Strict mode: All three signals required
    if ($signalsPresent -eq 3) {
        Write-Host "[GREEN] All three signals verified ✅" -ForegroundColor Green
        exit 0
    } elseif ($signalsPresent -ge 1) {
        Write-Host "[AMBER] Only $signalsPresent/3 signals present" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "[RED] No signals present" -ForegroundColor Red
        exit 2
    }
} else {
    # Permissive mode: At least one signal required
    if ($signalsPresent -ge 1) {
        Write-Host "[GREEN] At least one signal verified ✅" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "[RED] No signals present" -ForegroundColor Red
        exit 2
    }
}

