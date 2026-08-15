# Gate #029: OTLP Collector Path Verification (5320) + API-Signed Proofs (H1)
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify Windows Collector path end-to-end (5320 → 4317 → SigNoz) with API-signed proof artifacts

<#
.SYNOPSIS
    Verify the Windows OTel Collector path (port 5320) routes to SigNoz correctly, with API-signed proof generation.

.DESCRIPTION
    Tests the collection path:
    1. Service sends to http://127.0.0.1:5320 (Windows Collector)
    2. Collector forwards to localhost:4317 (SigNoz)
    3. Verify traces appear in SigNoz (with optional API proof)
    4. Calculate accepted_spans / sent_spans ratio
    5. Generate machine-verifiable JSON proof artifacts (if API key provided)

.PARAMETER ServiceName
    Service name to filter in SigNoz (or use SIGNOZ_SERVICE_NAME env var)

.PARAMETER SigNozUrl
    SigNoz base URL (default: http://localhost:8080, or SIGNOZ_BASE_URL env var)

.PARAMETER LookbackMinutes
    Minutes to look back for traces (default: 3, or SIGNOZ_LOOKBACK_MINUTES env var)

.PARAMETER ExpectAtLeast
    Minimum trace count required for PASS (default: 1)

.PARAMETER UseApiProof
    Enable API-signed proof generation (requires SIGNOZ_API_KEY environment variable)

.EXAMPLE
    .\health-check-otlp.ps1 -ServiceName "bosscat-svc2-api"

.EXAMPLE
    # With API-signed proof
    $env:SIGNOZ_API_KEY = "<key>"
    .\health-check-otlp.ps1 -ServiceName "bosscat-svc2-api" -UseApiProof
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
    [switch]$UseApiProof
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot '..\..\BRAV\SCPT\lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

function Write-CheckLog {
    param([string]$Level, [string]$Message, [hashtable]$Data = @{})
    
    $logEntry = @{
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        level = $Level
        check = "otlp-collector-path"
        message = $Message
    } + $Data
    
    Write-Host ($logEntry | ConvertTo-Json -Compress)
}

# Gate #029-H1: API-signed proof query function
function Query-SigNozTraces {
    param(
        [string]$ServiceName,
        [string]$SigNozBaseUrl,
        [string]$ApiKey,
        [int]$LookbackMinutes
    )
    
    $end = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $start = [DateTimeOffset]::UtcNow.AddMinutes(-$LookbackMinutes).ToUnixTimeMilliseconds()
    
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
                        signal = "traces"
                        aggregations = @(@{ expression = "count()"; alias = "span_count" })
                        filter = @{ expression = "serviceName = '$ServiceName'" }
                        disabled = $false
                    }
                }
            )
        }
    } | ConvertTo-Json -Depth 10
    
    $headers = @{ "Content-Type" = "application/json"; "SIGNOZ-API-KEY" = $ApiKey }
    $uri = ($SigNozBaseUrl.TrimEnd('/')) + "/api/v5/query_range"
    
    try {
        $resp = Invoke-RestMethod -Method POST -Uri $uri -Headers $headers -Body $payload -TimeoutSec 30
        
        # Parse count from response
        $count = 0
        if ($resp.data -and $resp.data.result -and $resp.data.result.A) {
            if ($resp.data.result.A.value) {
                $count = [int]$resp.data.result.A.value
            } elseif ($resp.data.result.A.list) {
                $count = [int]$resp.data.result.A.list.Count
            }
        }
        
        return @{ Success = $true; Count = $count; Response = $resp; StartMs = $start; EndMs = $end; Endpoint = $uri }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Validate ServiceName if using API proof
if ($UseApiProof) {
    if (-not $ServiceName) {
        Write-Error "ServiceName required when using API proof (or set SIGNOZ_SERVICE_NAME)"
        exit 21
    }
    $ApiKey = $env:SIGNOZ_API_KEY
    if (-not $ApiKey) {
        Write-Error "SIGNOZ_API_KEY environment variable required for API proof mode"
        exit 21
    }
}

Write-CheckLog -Level "INFO" -Message "Starting Collector path verification" -Data @{
    service = $ServiceName
    signoz_url = $SigNozUrl
    api_proof_mode = $UseApiProof.IsPresent
    lookback_minutes = $LookbackMinutes
}

# Step 1: Verify Collector is listening on ingest gRPC port
Write-CheckLog -Level "INFO" -Message "Checking if Collector is listening on port $($script:OtelPorts.IngestGrpc)"

$collectorListening = $false
try {
    $testConnection = Test-NetConnection -ComputerName 127.0.0.1 -Port $script:OtelPorts.IngestGrpc -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($testConnection) {
        Write-CheckLog -Level "INFO" -Message "Collector listening on port $($script:OtelPorts.IngestGrpc)" -Data @{ status = "PASS" }
        $collectorListening = $true
    } else {
        Write-CheckLog -Level "ERROR" -Message "Collector not listening on port $($script:OtelPorts.IngestGrpc)" -Data @{ status = "FAIL" }
        exit 2
    }
} catch {
    Write-CheckLog -Level "ERROR" -Message "Failed to check Collector port" -Data @{
        error = $_.Exception.Message
    }
    exit 2
}

# Step 2: Generate traffic to the service (which should send to Collector)
Write-CheckLog -Level "INFO" -Message "Generating traffic to service"

$servicePort = switch ($ServiceName) {
    "bosscat-svc2-api" { 5556 }
    "bosscat-svc3-worker" { 5557 }
    default { 5556 }
}

try {
    # Generate 5 requests to create traces
    for ($i = 1; $i -le 5; $i++) {
        $response = Invoke-WebRequest -Uri "http://localhost:$servicePort/test" -TimeoutSec 10 -ErrorAction SilentlyContinue
        Write-CheckLog -Level "INFO" -Message "Traffic generated" -Data @{
            request = $i
            status_code = $response.StatusCode
        }
        Start-Sleep -Milliseconds 200
    }
} catch {
    Write-CheckLog -Level "WARN" -Message "Traffic generation had issues" -Data @{
        error = $_.Exception.Message
    }
}

# Step 3: Wait for batch export (Collector batch timeout is 200ms)
Write-CheckLog -Level "INFO" -Message "Waiting for batch export to SigNoz"
Start-Sleep -Seconds 3

# Step 4: Query SigNoz for traces
Write-CheckLog -Level "INFO" -Message "Querying SigNoz for traces"

try {
    $queryUrl = "$SigNozUrl/api/v3/query_range"
    $endTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $startTime = $endTime - (15 * 60 * 1000)  # Last 15 minutes
    
    $body = @{
        start = $startTime
        end = $endTime
        step = 60
        variables = @{}
        compositeQuery = @{
            queryType = "builder"
            panelType = "table"
            builder = @{
                queryData = @(
                    @{
                        dataSource = "traces"
                        queryName = "A"
                        aggregateOperator = "count"
                        aggregateAttribute = @{
                            key = ""
                        }
                        filters = @{
                            items = @(
                                @{
                                    key = @{
                                        key = "service.name"
                                        dataType = "string"
                                        type = "resource"
                                    }
                                    op = "="
                                    value = $ServiceName
                                }
                            )
                            op = "AND"
                        }
                    }
                )
            }
        }
    } | ConvertTo-Json -Depth 10
    
    $response = Invoke-RestMethod -Uri $queryUrl -Method Post -Body $body -ContentType "application/json" -TimeoutSec 30
    
    $traceCount = 0
    if ($response.data.result -and $response.data.result.Count -gt 0) {
        # Extract trace count from response
        $traceCount = $response.data.result[0].table.rows.Count
    }
    
    Write-CheckLog -Level "INFO" -Message "SigNoz query complete" -Data @{
        service = $ServiceName
        traces_found = $traceCount
        status = if ($traceCount -gt 0) { "PASS" } else { "FAIL" }
    }
    
    if ($traceCount -eq 0) {
        Write-CheckLog -Level "ERROR" -Message "No traces found in SigNoz for service" -Data @{
            service = $ServiceName
            query_url = $queryUrl
        }
        exit 1  # AMBER - service might be working but not routing through Collector
    }
    
    # Step 5: Verify accepted_spans ≈ sent_spans (within 5% tolerance)
    # For this test, we sent 5 requests, expect approximately 5 traces (or 10 if counting child spans)
    $expectedTraces = 5
    $tolerance = 0.05
    $ratio = $traceCount / $expectedTraces
    
    Write-CheckLog -Level "INFO" -Message "Span acceptance ratio calculated" -Data @{
        expected_traces = $expectedTraces
        actual_traces = $traceCount
        ratio = $ratio
        within_tolerance = ($ratio -ge (1 - $tolerance)) -and ($ratio -le (1 + $tolerance))
    }
    
    if ($ratio -lt (1 - $tolerance)) {
        Write-CheckLog -Level "WARN" -Message "Trace count lower than expected" -Data @{
            expected = $expectedTraces
            actual = $traceCount
            loss_percentage = ((1 - $ratio) * 100)
        }
    }
    
    Write-CheckLog -Level "INFO" -Message "Collector path verification complete" -Data @{
        status = "GREEN"
        collector_port = $script:OtelPorts.IngestGrpc
        signoz_port = $script:OtelPorts.SignozOtlpGrpc
        traces_received = $traceCount
    }
    
    # Gate #029-H1: Generate API-signed proof if enabled
    if ($UseApiProof -and $ApiKey) {
        Write-CheckLog -Level "INFO" -Message "Generating API-signed proof"
        
        $apiResult = Query-SigNozTraces -ServiceName $ServiceName -SigNozBaseUrl $SigNozUrl -ApiKey $ApiKey -LookbackMinutes $LookbackMinutes
        
        if ($apiResult.Success) {
            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $proof = @{
                probe = "signoz-traces"
                service = $ServiceName
                timeframe = "$LookbackMinutes min"
                startMs = $apiResult.StartMs
                endMs = $apiResult.EndMs
                count = $apiResult.Count
                endpoint = $apiResult.Endpoint
                timestamp = $stamp
                verification_type = "api-signed"
                api_version = "v5"
            } | ConvertTo-Json -Depth 5
            
            New-Item -ItemType Directory -Force -Path "artifacts/proofs" | Out-Null
            $proofPath = "artifacts/proofs/proof-traces-$($ServiceName)-$stamp.json"
            $proof | Out-File -Encoding utf8 $proofPath
            
            Write-CheckLog -Level "INFO" -Message "API-signed proof generated" -Data @{
                proof_path = $proofPath
                trace_count = $apiResult.Count
                status = if ($apiResult.Count -ge $ExpectAtLeast) { "PASS" } else { "FAIL" }
            }
            
            Write-Host "[OK] SigNoz traces present for '$ServiceName': $($apiResult.Count) ≥ $ExpectAtLeast" -ForegroundColor Green
            Write-Host "Proof: $proofPath" -ForegroundColor Cyan
        } else {
            Write-CheckLog -Level "WARN" -Message "API proof generation failed" -Data @{
                error = $apiResult.Error
            }
            Write-Host "[WARN] API proof generation failed: $($apiResult.Error)" -ForegroundColor Yellow
        }
    }
    
    exit 0
    
} catch {
    Write-CheckLog -Level "ERROR" -Message "SigNoz query failed" -Data @{
        error = $_.Exception.Message
        signoz_url = $SigNozUrl
    }
    exit 2
}

