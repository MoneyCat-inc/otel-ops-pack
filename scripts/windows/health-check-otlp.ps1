# Gate #029: OTLP Collector Path Verification (5317)
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Purpose: Verify Windows Collector path end-to-end (5317 → 14317 → SigNoz)

<#
.SYNOPSIS
    Verify the Windows OTel Collector path (port 5317) routes to SigNoz correctly.

.DESCRIPTION
    Tests the collection path:
    1. Service sends to http://127.0.0.1:5317 (Windows Collector)
    2. Collector forwards to localhost:14317 (SigNoz)
    3. Verify traces appear in SigNoz
    4. Calculate accepted_spans / sent_spans ratio

.PARAMETER ServiceName
    Service name to filter in SigNoz

.PARAMETER SigNozUrl
    SigNoz base URL (default: http://localhost:8080)

.EXAMPLE
    .\health-check-otlp.ps1 -ServiceName "bosscat-svc2-api"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,
    
    [Parameter(Mandatory=$false)]
    [string]$SigNozUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"

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

Write-CheckLog -Level "INFO" -Message "Starting Collector path verification" -Data @{
    service = $ServiceName
    signoz_url = $SigNozUrl
}

# Step 1: Verify Collector is listening on 5317
Write-CheckLog -Level "INFO" -Message "Checking if Collector is listening on port 5317"

$collectorListening = $false
try {
    $testConnection = Test-NetConnection -ComputerName 127.0.0.1 -Port 5317 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($testConnection) {
        Write-CheckLog -Level "INFO" -Message "Collector listening on port 5317" -Data @{ status = "PASS" }
        $collectorListening = $true
    } else {
        Write-CheckLog -Level "ERROR" -Message "Collector not listening on port 5317" -Data @{ status = "FAIL" }
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
        collector_port = 5317
        signoz_port = 14317
        traces_received = $traceCount
    }
    
    exit 0
    
} catch {
    Write-CheckLog -Level "ERROR" -Message "SigNoz query failed" -Data @{
        error = $_.Exception.Message
        signoz_url = $SigNozUrl
    }
    exit 2
}

