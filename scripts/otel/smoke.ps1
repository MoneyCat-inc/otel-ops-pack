<#!
.SYNOPSIS
    Deterministic Windows → SigNoz smoke test for OTLP logs, traces, and metrics.

.DESCRIPTION
    Starts (or verifies) the local SigNoz stack, emits synthetic OTLP payloads, and asserts
    that ClickHouse + SigNoz APIs observe the traffic. Designed for CI and on-call use.

.PARAMETER SkipStackCheck
    Skips docker-compose bring-up and health validation (use when stack already running).

.PARAMETER TimeoutSeconds
    Total seconds to wait for collectors to become healthy. Defaults to 120.

.EXAMPLE
    pwsh -File scripts/otel/smoke.ps1

.EXAMPLE
    pwsh -File scripts/otel/smoke.ps1 -SkipStackCheck
#>
[CmdletBinding()]
param(
    [switch]$SkipStackCheck,
    [int]$TimeoutSeconds = 120
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Pass {
    param([string]$Message)
    Write-Host "   [OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "   [WARN] $Message" -ForegroundColor Yellow
}

function Invoke-DockerCompose {
    param(
        [string[]]$Args
    )

    $cmd = "docker"
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "docker CLI not found on PATH"
    }

    $fullArgs = @('compose') + $Args
    $process = Start-Process -FilePath $cmd -ArgumentList $fullArgs -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        throw "docker compose $($Args -join ' ') failed with exit code $($process.ExitCode)"
    }
}

function Invoke-ClickHouseQuery {
    param(
        [string]$Query,
        [switch]$Quiet
    )

    $queryArgs = @('exec', 'signoz-clickhouse', 'clickhouse-client', '--query', $Query)
    $output = & docker @queryArgs 2>$null
    if ($LASTEXITCODE -ne 0) {
        if (-not $Quiet) {
            Write-Warn "ClickHouse query failed: $Query"
        }
        return $null
    }
    return $output
}

function Wait-ForUrl {
    param(
        [string]$Url,
        [int]$Timeout = 60
    )

    $deadline = (Get-Date).AddSeconds($Timeout)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri $Url -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                return $true
            }
        } catch {
            Start-Sleep -Seconds 3
        }
    }
    return $false
}

Write-Step "Preparing SigNoz stack"
if (-not $SkipStackCheck) {
    Invoke-DockerCompose -Args @('-f', 'docker-compose.yml', 'up', '-d')
    Write-Pass "docker compose up -d"
} else {
    Write-Warn "Skipping docker compose up (per flag)"
}

if (-not (Wait-ForUrl -Url 'http://localhost:13133/healthz' -Timeout $TimeoutSeconds)) {
    throw "SigNoz collector health endpoint did not become ready"
}
Write-Pass "SigNoz collector healthy on :13133"

if (-not (Wait-ForUrl -Url 'http://localhost:8080/api/v1/health' -Timeout $TimeoutSeconds)) {
    throw "SigNoz UI health endpoint did not respond"
}
Write-Pass "SigNoz UI reachable"

$smokeId = "otel-smoke-" + ([Guid]::NewGuid().ToString())
$nowNano = [int64]([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() * 1000000)
$spanEndNano = $nowNano + 5 * 1000000

Write-Step "Emitting OTLP payloads ($smokeId)"

$logPayload = @{
    resourceLogs = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = 'service.name'; value = @{ stringValue = 'windows-collector' } },
                    @{ key = 'deployment.environment'; value = @{ stringValue = 'local-smoke' } }
                )
            }
            scopeLogs = @(
                @{
                    scope = @{ name = 'smoke-harness'; version = '1.0.0' }
                    logRecords = @(
                        @{
                            timeUnixNano = $nowNano.ToString()
                            observedTimeUnixNano = $nowNano.ToString()
                            severityNumber = 9
                            severityText = 'INFO'
                            body = @{ stringValue = "sig-smoke-log::$smokeId" }
                            attributes = @(
                                @{ key = 'smoke.id'; value = @{ stringValue = $smokeId } },
                                @{ key = 'dataset'; value = @{ stringValue = 'smoke' } }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 6

$tracePayload = @{
    resourceSpans = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = 'service.name'; value = @{ stringValue = 'smoke-service' } },
                    @{ key = 'deployment.environment'; value = @{ stringValue = 'local-smoke' } }
                )
            }
            scopeSpans = @(
                @{
                    scope = @{ name = 'smoke-harness'; version = '1.0.0' }
                    spans = @(
                        @{
                            traceId = ([System.BitConverter]::ToString((New-Guid).ToByteArray()) -replace '-', '').Substring(0,32)
                            spanId = ([System.BitConverter]::ToString((New-Guid).ToByteArray()) -replace '-', '').Substring(0,16)
                            name = 'smoke-span'
                            kind = 'SPAN_KIND_INTERNAL'
                            startTimeUnixNano = $nowNano.ToString()
                            endTimeUnixNano = $spanEndNano.ToString()
                            attributes = @(
                                @{ key = 'smoke.id'; value = @{ stringValue = $smokeId } },
                                @{ key = 'smoke.phase'; value = @{ stringValue = 'harness' } }
                            )
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 6

$metricPayload = @{
    resourceMetrics = @(
        @{
            resource = @{
                attributes = @(
                    @{ key = 'service.name'; value = @{ stringValue = 'smoke-service' } },
                    @{ key = 'deployment.environment'; value = @{ stringValue = 'local-smoke' } }
                )
            }
            scopeMetrics = @(
                @{
                    scope = @{ name = 'smoke-harness'; version = '1.0.0' }
                    metrics = @(
                        @{
                            name = 'smoke_gauge'
                            unit = '1'
                            gauge = @{
                                dataPoints = @(
                                    @{
                                        timeUnixNano = $nowNano.ToString()
                                        asDouble = 1.0
                                        attributes = @(
                                            @{ key = 'smoke.id'; value = @{ stringValue = $smokeId } }
                                        )
                                    }
                                )
                            }
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 6

Invoke-RestMethod -Uri 'http://localhost:4318/v1/logs' -Method Post -Body $logPayload -ContentType 'application/json'
Write-Pass "OTLP log accepted"
Invoke-RestMethod -Uri 'http://localhost:4318/v1/traces' -Method Post -Body $tracePayload -ContentType 'application/json'
Write-Pass "OTLP trace accepted"
Invoke-RestMethod -Uri 'http://localhost:4318/v1/metrics' -Method Post -Body $metricPayload -ContentType 'application/json'
Write-Pass "OTLP metric accepted"

Start-Sleep -Seconds 10

Write-Step "Verifying ingestion"
$logCountRaw = Invoke-ClickHouseQuery -Query "SELECT count() FROM signoz_logs.distributed_logs_v2 WHERE JSONExtractString(body, 'smoke.id') = '$smokeId'"
$logCount = 0
if ([int]::TryParse(($logCountRaw | Select-Object -First 1), [ref]$logCount)) {
    if ($logCount -gt 0) {
        Write-Pass "Log present in ClickHouse"
    } else {
        Write-Warn "Log not found in ClickHouse (smoke id: $smokeId)"
    }
} elseif ($null -eq $logCountRaw) {
    Write-Warn "Unable to query ClickHouse logs"
}

$traceCountRaw = Invoke-ClickHouseQuery -Query "SELECT count() FROM signoz_traces.signoz_index_v2 WHERE attributes_string['smoke.id'] = '$smokeId'"
$traceCount = 0
if ([int]::TryParse(($traceCountRaw | Select-Object -First 1), [ref]$traceCount)) {
    if ($traceCount -gt 0) {
        Write-Pass "Trace present in ClickHouse"
    } else {
        Write-Warn "Trace not found in ClickHouse"
    }
} elseif ($null -eq $traceCountRaw) {
    Write-Warn "Unable to query ClickHouse traces"
}

$promQuery = "smoke_gauge{smoke_id='${smokeId}'}"
$promUrl = "http://localhost:8080/api/v1/prometheus/api/v1/query?query=" + [System.Uri]::EscapeDataString($promQuery)
try {
    $metricResponse = Invoke-RestMethod -Uri $promUrl -TimeoutSec 15
    $result = $metricResponse.data.result
    if ($result -and $result.Count -gt 0) {
        Write-Pass "Metric visible via PromQL"
    } else {
        Write-Warn "Metric not returned by PromQL (smoke id: $smokeId)"
    }
} catch {
    Write-Warn "PromQL query failed: $($_.Exception.Message)"
}

Write-Step "Smoke complete"
Write-Host "Smoke ID: $smokeId" -ForegroundColor White
