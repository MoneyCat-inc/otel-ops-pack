# OtelPorts.psm1 — thin binding over DELT/CONF/otel-ports.json
# Second Pass B3. Authority: collector YAML (see check-otel-ports-drift.ps1).

Set-StrictMode -Version Latest

function Get-OtelRepoRoot {
    param([string]$StartDir = $PSScriptRoot)
    $dir = Get-Item -LiteralPath $StartDir
    while ($null -ne $dir) {
        $candidate = Join-Path $dir.FullName 'DELT\CONF\otel-ports.json'
        if (Test-Path -LiteralPath $candidate) { return $dir.FullName }
        $dir = $dir.Parent
    }
    throw "Get-OtelRepoRoot: could not locate DELT/CONF/otel-ports.json from $StartDir"
}

function Get-OtelPorts {
    <#
    .SYNOPSIS
      Load canonical OTLP / SigNoz ports from DELT/CONF/otel-ports.json.
    #>
    param(
        [string]$RepoRoot = (Get-OtelRepoRoot),
        [string]$PortsJsonPath
    )
    if (-not $PortsJsonPath) {
        $PortsJsonPath = Join-Path $RepoRoot 'DELT\CONF\otel-ports.json'
    }
    if (-not (Test-Path -LiteralPath $PortsJsonPath)) {
        throw "Get-OtelPorts: missing $PortsJsonPath"
    }
    $raw = Get-Content -LiteralPath $PortsJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    [pscustomobject]@{
        IngestGrpc     = [int]$raw.windows_collector_ingest.grpc
        IngestHttp     = [int]$raw.windows_collector_ingest.http
        SignozOtlpGrpc = [int]$raw.signoz_otlp.grpc
        SignozOtlpHttp = [int]$raw.signoz_otlp.http
        SignozUiHttp   = [int]$raw.signoz_ui.http
        Authority      = [string]$raw.authority
        RepoRoot       = $RepoRoot
        PortsJsonPath  = $PortsJsonPath
    }
}

function Get-OtelIngestHttpBase {
    param(
        [string]$HostName = '127.0.0.1',
        $Ports = (Get-OtelPorts)
    )
    "http://${HostName}:$($Ports.IngestHttp)"
}

function Get-OtelIngestGrpcEndpoint {
    param(
        [string]$HostName = '127.0.0.1',
        $Ports = (Get-OtelPorts)
    )
    "${HostName}:$($Ports.IngestGrpc)"
}

Export-ModuleMember -Function Get-OtelRepoRoot, Get-OtelPorts, Get-OtelIngestHttpBase, Get-OtelIngestGrpcEndpoint
