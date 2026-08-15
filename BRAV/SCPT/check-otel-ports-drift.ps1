<#
.SYNOPSIS
  Drift check: DELT/CONF/otel-ports.json vs collector YAML endpoint lines.

.DESCRIPTION
  Reality is defined by windows/otelcol/otelcol-contrib-config.yaml (receivers.otlp
  + exporters.otlp endpoint ports). The JSON is a derived convenience source —
  this script fails if they disagree.

.PARAMETER PortsJsonPath
  Override path to otel-ports.json (for fail-probe with a mismatched copy).

.PARAMETER CollectorYamlPath
  Override path to collector YAML.
#>
[CmdletBinding()]
param(
    [string]$PortsJsonPath,
    [string]$CollectorYamlPath,
    [string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-RepoRoot {
    param([string]$Hint)
    if ($Hint) { return (Resolve-Path -LiteralPath $Hint).Path }
    $dir = Get-Item -LiteralPath $PSScriptRoot
    while ($null -ne $dir) {
        if (Test-Path -LiteralPath (Join-Path $dir.FullName 'DELT\CONF')) {
            return $dir.FullName
        }
        $dir = $dir.Parent
    }
    throw 'Could not resolve repo root'
}

$root = Resolve-RepoRoot -Hint $RepoRoot
if (-not $PortsJsonPath) {
    $PortsJsonPath = Join-Path $root 'DELT\CONF\otel-ports.json'
}
if (-not $CollectorYamlPath) {
    $CollectorYamlPath = Join-Path $root 'windows\otelcol\otelcol-contrib-config.yaml'
}

if (-not (Test-Path -LiteralPath $PortsJsonPath)) {
    Write-Error "Missing ports JSON: $PortsJsonPath"
    exit 2
}
if (-not (Test-Path -LiteralPath $CollectorYamlPath)) {
    Write-Error "Missing collector YAML: $CollectorYamlPath"
    exit 2
}

$json = Get-Content -LiteralPath $PortsJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$yaml = Get-Content -LiteralPath $CollectorYamlPath -Raw -Encoding UTF8

# Extract host:port from endpoint: lines (ignore comments stripped roughly)
$endpointPorts = [System.Collections.Generic.List[int]]::new()
foreach ($line in ($yaml -split "`n")) {
    $trim = $line.Trim()
    if ($trim -match '^#') { continue }
    if ($trim -match 'endpoint:\s*\S+:(\d+)') {
        [void]$endpointPorts.Add([int]$Matches[1])
    }
}

$expected = @{
    IngestGrpc     = [int]$json.windows_collector_ingest.grpc
    IngestHttp     = [int]$json.windows_collector_ingest.http
    SignozOtlpGrpc = [int]$json.signoz_otlp.grpc
}

$missing = @()
foreach ($name in @('IngestGrpc', 'IngestHttp', 'SignozOtlpGrpc')) {
    $port = $expected[$name]
    if ($endpointPorts -notcontains $port) {
        $missing += "$name=$port"
    }
}

Write-Host "ports_json=$PortsJsonPath"
Write-Host "collector_yaml=$CollectorYamlPath"
Write-Host ("yaml_endpoint_ports=[{0}]" -f ($endpointPorts -join ', '))
Write-Host ("json_expected ingest_grpc={0} ingest_http={1} signoz_otlp_grpc={2}" -f `
    $expected.IngestGrpc, $expected.IngestHttp, $expected.SignozOtlpGrpc)

if ($missing.Count -gt 0) {
    Write-Host "DRIFT: JSON ports not found on collector YAML endpoint lines: $($missing -join ', ')" -ForegroundColor Red
    exit 1
}

Write-Host 'OK: otel-ports.json matches collector YAML endpoint ports' -ForegroundColor Green
exit 0
