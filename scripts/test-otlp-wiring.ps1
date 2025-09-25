<#
.SYNOPSIS
    Smoke test for host -> SigNoz OTLP/HTTP wiring.

.DESCRIPTION
    - Discovers the host-mapped OTLP ports exposed by the Docker collector
    - Verifies listener reachability with animated progress updates
    - Sets OTEL_* environment variables for the current session
    - Emits a Python OTLP/HTTP span so operators can confirm ingestion in SigNoz

.PARAMETER ServiceName
    Resource service.name sent with the smoke span (default: smoke).

.PARAMETER Endpoint
    Override for OTLP endpoint (default: http://127.0.0.1:<discovered-port>/v1/logs).

.PARAMETER ProbeTimeoutSeconds
    Timeout used for network probes (default: 5 seconds).
#>
[CmdletBinding()]
param(
    [string]$ServiceName = 'smoke',
    [string]$Endpoint,
    [int]$ProbeTimeoutSeconds = 5
)

$ErrorActionPreference = 'Stop'
$collectorName = 'signoz-otel-collector'
$spinnerFrames = @([char]0x280B,[char]0x2819,[char]0x2839,[char]0x2838,[char]0x283C,[char]0x2834,[char]0x2826,[char]0x2827,[char]0x2825,[char]0x280F)

function Write-SpinnerTick {
    param(
        [string]$Message,
        [int]$Iteration,
        [int]$TotalIterations
    )

    $frame = $spinnerFrames[$Iteration % $spinnerFrames.Count]
    $percent = if ($TotalIterations -gt 0) {
        [math]::Min(100, [math]::Round(($Iteration / $TotalIterations) * 100))
    } else { 0 }

    Write-Host ("`r{0} {1} ({2}%)" -f $frame, $Message, $percent) -NoNewline -ForegroundColor Cyan
}

function Clear-SpinnerLine {
    Write-Host "`r" + (' ' * 80) + "`r" -NoNewline
}

function Get-CollectorStatus {
    param([string]$Name)
    $ps = docker ps --filter "name=$Name" --format '{{.Status}}' 2>$null
    return -not [string]::IsNullOrWhiteSpace($ps)
}

function Get-CollectorPorts {
    param([string]$Name)

    $ports = [ordered]@{ Http = $null; Grpc = $null }

    try {
        $http = docker inspect -f "{{(index (index .NetworkSettings.Ports \"4318/tcp\") 0).HostPort}}" $Name 2>$null
        $grpc = docker inspect -f "{{(index (index .NetworkSettings.Ports \"4317/tcp\") 0).HostPort}}" $Name 2>$null
    } catch {
        return $ports
    }

    if (-not [string]::IsNullOrWhiteSpace($http) -and $http -ne '<no value>') {
        $ports.Http = [int]$http
    }
    if (-not [string]::IsNullOrWhiteSpace($grpc) -and $grpc -ne '<no value>') {
        $ports.Grpc = [int]$grpc
    }

    return $ports
}

function Test-OtlpEndpoint {
    param(
        [string]$TargetHost,
        [int]$Port,
        [string]$Label,
        [int]$TimeoutSeconds
    )

    $iteration = 0
    $maxIterations = [math]::Max(1, [int]([math]::Ceiling($TimeoutSeconds * 5)))
    $isReachable = $false

    while ($iteration -lt $maxIterations) {
        $iteration++
        $probe = Test-NetConnection -ComputerName $TargetHost -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
        if ($probe) {
            Clear-SpinnerLine
            Write-Host "[OK] $Label (port $Port) reachable" -ForegroundColor Green
            $isReachable = $true
            break
        }

        Write-SpinnerTick -Message "Probing $Label (port $Port)" -Iteration $iteration -TotalIterations $maxIterations
        Start-Sleep -Milliseconds 200
    }

    if (-not $isReachable) {
        Clear-SpinnerLine
        Write-Host "[WARN] $Label (port $Port) unreachable after ${TimeoutSeconds}s" -ForegroundColor Yellow
    }

    return $isReachable
}

function Send-SmokeSpan {
    param(
        [string]$TargetEndpoint,
        [string]$TargetServiceName
    )

    $python = @"
import os
import time
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://127.0.0.1:4318")
service_name = os.environ.get("OTEL_SERVICE_NAME", "smoke")

provider = TracerProvider(resource=Resource.create({"service.name": service_name}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=endpoint)))
trace.set_tracer_provider(provider)

tracer = trace.get_tracer("otlp-wiring-smoke")
with tracer.start_as_current_span("otel-smoke-span") as span:
    span.set_attribute("smoke.test", True)
    span.set_attribute("endpoint", endpoint)
    span.set_attribute("service.name", service_name)
    time.sleep(0.05)

print(f"sent span to {endpoint} as {service_name}")
"@

    $output = py -c $python 2>&1
    return @{ ExitCode = $LASTEXITCODE; Output = $output }
}

Write-Host '== OTLP host wiring smoke test ==' -ForegroundColor Cyan
Write-Host ("Service name : {0}" -f $ServiceName) -ForegroundColor Gray
if ($PSBoundParameters.ContainsKey('Endpoint')) {
    Write-Host ("Endpoint    : {0}" -f $Endpoint) -ForegroundColor Gray
}
Write-Host

Write-Host '[1/5] Checking collector container...' -ForegroundColor Yellow
$collectorRunning = Get-CollectorStatus -Name $collectorName
if ($collectorRunning) {
    Write-Host "[OK] $collectorName is running" -ForegroundColor Green
} else {
    Write-Host "[WARN] $collectorName is not running. Start the SigNoz stack (docker compose up -d) before rerunning." -ForegroundColor Yellow
}

Write-Host '[2/5] Discovering host-mapped OTLP ports...' -ForegroundColor Yellow
$ports = Get-CollectorPorts -Name $collectorName

if (-not $ports.Http) {
    $ports.Http = 4318
    Write-Host '[INFO] Falling back to HTTP port 4318' -ForegroundColor Gray
}
if (-not $ports.Grpc) {
    $ports.Grpc = 4317
    Write-Host '[INFO] Falling back to gRPC port 4317' -ForegroundColor Gray
}

Write-Host -ForegroundColor Gray ("HTTP port  : {0}" -f $ports.Http)
Write-Host -ForegroundColor Gray ("gRPC port  : {0}" -f $ports.Grpc)

if (-not $PSBoundParameters.ContainsKey('Endpoint')) {
    $Endpoint = "http://127.0.0.1:{0}" -f $ports.Http
    Write-Host ("[INFO] Using endpoint {0}" -f $Endpoint) -ForegroundColor Gray
}

Write-Host '[3/5] Probing OTLP listeners...' -ForegroundColor Yellow
$httpReachable = Test-OtlpEndpoint -TargetHost '127.0.0.1' -Port $ports.Http -Label 'OTLP HTTP' -TimeoutSeconds $ProbeTimeoutSeconds
$grpcReachable = Test-OtlpEndpoint -TargetHost '127.0.0.1' -Port $ports.Grpc -Label 'OTLP gRPC' -TimeoutSeconds $ProbeTimeoutSeconds

if (-not $httpReachable -and -not $grpcReachable) {
    Write-Host '[ERROR] No OTLP listener reachable on the host. Aborting smoke span.' -ForegroundColor Red
    exit 1
}

Write-Host '[4/5] Exporting OTLP environment variables...' -ForegroundColor Yellow
$env:OTEL_EXPORTER_OTLP_PROTOCOL = 'http/protobuf'
$env:OTEL_EXPORTER_OTLP_ENDPOINT = $Endpoint
$env:OTEL_SERVICE_NAME = $ServiceName
$env:OTEL_RESOURCE_ATTRIBUTES = 'env=dev,host=windows'

Write-Host -ForegroundColor Green ("OTEL_EXPORTER_OTLP_ENDPOINT = {0}" -f $env:OTEL_EXPORTER_OTLP_ENDPOINT)
Write-Host -ForegroundColor Green ("OTEL_SERVICE_NAME           = {0}" -f $env:OTEL_SERVICE_NAME)

Write-Host '[5/5] Sending smoke span (Python)...' -ForegroundColor Yellow
$spanResult = Send-SmokeSpan -TargetEndpoint $env:OTEL_EXPORTER_OTLP_ENDPOINT -TargetServiceName $env:OTEL_SERVICE_NAME

if ($spanResult.ExitCode -eq 0) {
    Write-Host "[OK] $($spanResult.Output.Trim())" -ForegroundColor Green
} else {
    Write-Host '[ERROR] Failed to send span:' -ForegroundColor Red
    Write-Host $spanResult.Output -ForegroundColor Red
    Write-Host 'Install dependencies: pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp' -ForegroundColor Yellow
    exit 1
}

Write-Host
Write-Host 'Verification:' -ForegroundColor Cyan
Write-Host "  - SigNoz UI -> Traces -> Search -> Filter resource.service.name = '$ServiceName'" -ForegroundColor Gray
Write-Host "  - Expect span name 'otel-smoke-span' within the last minute" -ForegroundColor Gray
Write-Host "  - docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\"" -ForegroundColor Gray

Write-Host
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '  1. Persist OTEL_* env vars in your shell profile' -ForegroundColor Gray
Write-Host '  2. Integrate this script into scripts/verify-wiring.ps1' -ForegroundColor Gray





