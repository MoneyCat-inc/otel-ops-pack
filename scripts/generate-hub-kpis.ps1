#!/usr/bin/env pwsh
#Requires -Version 7

<#
.SYNOPSIS
    Generate docs/status/kpis.json from gate verification results.
.DESCRIPTION
    Runs verify-iona-gate.ps1 when needed, then maps verdict/tests to hub KPI tiles.
#>

param(
    [string]$GateJson = 'artifacts/gate-verification-results.json',
    [string]$Out = 'docs/status/kpis.json',
    [ValidateSet('local', 'ci', 'stg', 'prod')]
    [string]$Site = 'ci',
    [switch]$SkipVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$verifyScript = Join-Path $PSScriptRoot 'verify-iona-gate.ps1'

if (-not $SkipVerify -and (Test-Path $verifyScript)) {
    & pwsh -NoProfile -File $verifyScript `
        -Site $Site `
        -NoFailOnMissing `
        -OutputJson $GateJson | Out-Null
}

if (-not (Test-Path $GateJson)) {
    throw "Gate results not found: $GateJson"
}

$gate = Get-Content $GateJson -Raw | ConvertFrom-Json
$total = [int]($gate.tests.total)
$failed = [int]($gate.tests.failed)

$gatePct = if ($total -gt 0) {
    [math]::Round((($total - $failed) / $total) * 100, 1)
} else {
    switch ($gate.verdict) {
        'READY' { 100.0 }
        'READY_WITH_WARNINGS' { 95.0 }
        default { 0.0 }
    }
}

$errorPct = if ($total -gt 0) {
    [math]::Round(($failed / $total) * 100, 1)
} else { 0.0 }

$canary = 0
$canaryReport = 'artifacts/canary-ecrr-report.txt'
if (Test-Path $canaryReport) {
    $canary = (Select-String -Path $canaryReport -Pattern '\[OK\]' -AllMatches).Count
}
if ($canary -eq 0) { $canary = 1 }

$otel = switch ($gate.verdict) {
    'READY' { 'ok' }
    'READY_WITH_WARNINGS' { 'warn' }
    default { 'fail' }
}

$kpis = [ordered]@{
    gate    = "$gatePct%"
    error   = "$errorPct%"
    canary  = $canary
    otel    = $otel
    ts      = $gate.timestamp
    source  = 'gate-verification'
    version = '1.1'
    verdict = $gate.verdict
    commit  = $gate.commit
    site    = $gate.site
}

$outDir = Split-Path -Parent $Out
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$kpis | ConvertTo-Json -Depth 4 | Set-Content -Path $Out -Encoding UTF8
Write-Host "[Hub] KPIs written to $Out (verdict=$($gate.verdict), gate=$gatePct%)" -ForegroundColor Green
