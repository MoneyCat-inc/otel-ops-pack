[CmdletBinding()]
param(
    [int]$WaitSeconds = 15,
    [string]$CanaryEvent = "optimization_canary",
    [string]$ResonaiEndpoint = "http://localhost:3003/api/events"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "[INFO] Windows to SigNoz pipeline test" -ForegroundColor Cyan

function Test-Port {
    param([int]$Port, [string]$Name)
    $result = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
    if ($result.TcpTestSucceeded) {
        Write-Host "[PASS] $Name on port $Port is reachable" -ForegroundColor Green
        return $true
    }
    Write-Host "[FAIL] $Name on port $Port is not reachable" -ForegroundColor Red
    return $false
}

try {
    $svc = Get-Service -Name otelcol-contrib -ErrorAction Stop
    if ($svc.Status -ne 'Running') {
        throw "otelcol-contrib service state is $($svc.Status)"
    }
    Write-Host "[PASS] Windows collector service is running" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Windows collector service check failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$portChecks = @(
    @{ Port = 5318; Name = "Windows Collector OTLP HTTP" },
    @{ Port = 4317; Name = "SigNoz OTLP gRPC" },
    @{ Port = 4318; Name = "SigNoz OTLP HTTP" },
    @{ Port = 8080; Name = "SigNoz UI" },
    @{ Port = 3003; Name = "Resonai API" }
)

foreach ($port in $portChecks) {
    if (-not (Test-Port -Port $port.Port -Name $port.Name)) {
        exit 1
    }
}

$eventId = [guid]::NewGuid().ToString()
$body = [pscustomobject]@{
    event = $CanaryEvent
    event_id = $eventId
    session_id = "optimization-session-$eventId"
    variant = "optimization"
    ttv_ms = 120
    dataset = "resonai_analytics"
    ua = "Optimization-Test"
    cohort = "optimization-cohort"
    props = [pscustomobject]@{
        test_type = "end_to_end_optimization"
        timestamp = (Get-Date).ToString("o")
    }
} | ConvertTo-Json -Depth 4

try {
    Invoke-RestMethod -Uri $ResonaiEndpoint -Method Post -Body $body -ContentType "application/json" -TimeoutSec 10 | Out-Null
    Write-Host "[PASS] Resonai endpoint accepted canary event" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Failed to send canary event: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Waiting $WaitSeconds seconds for ingestion" -ForegroundColor Yellow
Start-Sleep -Seconds $WaitSeconds

if (-not (Test-Path "artifacts")) {
    New-Item -ItemType Directory -Path "artifacts" -Force | Out-Null
}

$artifact = @(
    "== End-to-End Optimization Verification ==",
    "Timestamp: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')",
    "Test Event ID: $eventId",
    "",
    "Checks",
    "- otelcol-contrib service running",
    "- key ports reachable",
    "- Resonai endpoint accepted test event",
    "- SigNoz expected to receive dataset 'resonai_analytics'",
    "",
    "SigNoz query",
    "Dataset filter: attributes.dataset = 'resonai_analytics'",
    "Event filter: attributes.event_id = '$eventId'",
    "",
    "Manual steps",
    "1. Open http://localhost:8080",
    "2. Navigate to Logs",
    "3. Apply dataset='resonai_analytics'",
    "4. Search for event_id '$eventId'",
    "",
    "== Wiring verification PASSED =="
)

$artifactPath = "artifacts/optimization-verify.txt"
$artifact | Out-File -FilePath $artifactPath -Encoding utf8NoBOM
Write-Host "[PASS] Verification artifact written to $artifactPath" -ForegroundColor Green

Write-Host "[NEXT] Review SigNoz logs with dataset='resonai_analytics'" -ForegroundColor White
Write-Host "[NEXT] Confirm event_id '$eventId' is visible" -ForegroundColor White
