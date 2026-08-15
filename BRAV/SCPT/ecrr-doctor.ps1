<#
ECRR Doctor
-------------
Environment validation script for the Windows -> OTel -> SigNoz toolchain.
Usage: pwsh -File scripts/ecrr-doctor.ps1
Creates artifacts/ecrr-doctor.txt with the collected notes.
#>

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$script:OtelPorts = Get-OtelPorts

$issues = @()
$warnings = @()
$report = @()

function Add-ReportLine {
    param(
        [string]$Level,
        [string]$Message,
        [System.ConsoleColor]$Color = [System.ConsoleColor]::Gray
    )

    $line = "[$Level] $Message"
    $script:report += $line
    Write-Host $line -ForegroundColor $Color
}

function Test-Port {
    param([int]$Port)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect('localhost', $Port, $null, $null)
        $completed = $async.AsyncWaitHandle.WaitOne(500)
        if (-not $completed) {
            $client.Close()
            return $false
        }
        $client.EndConnect($async)
        $client.Close()
        return $true
    } catch {
        return $false
    }
}

Add-ReportLine -Level 'INFO' -Message 'ECRR Doctor - Environment Examination' -Color Cyan
Add-ReportLine -Level 'INFO' -Message ('Timestamp: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Color Cyan
Add-ReportLine -Level 'INFO' -Message ('Working directory: ' + (Get-Location))
Add-ReportLine -Level 'INFO' -Message ('PowerShell version: ' + $PSVersionTable.PSVersion)

# Tooling checks
Add-ReportLine -Level 'SECTION' -Message 'Tooling availability' -Color Yellow
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerVersion = (docker --version 2>$null)
    Add-ReportLine -Level 'OK' -Message ('Docker detected: ' + $dockerVersion.Trim()) -Color Green
} else {
    $issues += 'Docker CLI not found in PATH'
    Add-ReportLine -Level 'FAIL' -Message 'Docker CLI not found in PATH' -Color Red
}

if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Add-ReportLine -Level 'OK' -Message 'WSL command available' -Color Green
} else {
    $warnings += 'WSL command not found in PATH'
    Add-ReportLine -Level 'WARN' -Message 'WSL command not found in PATH' -Color Yellow
}

# SigNoz UI check
Add-ReportLine -Level 'SECTION' -Message 'SigNoz and collector endpoints' -Color Yellow
try {
    $uiResponse = Invoke-WebRequest -Uri "http://localhost:$($script:OtelPorts.SignozUiHttp)" -UseBasicParsing -TimeoutSec 3
    Add-ReportLine -Level 'OK' -Message ("SigNoz UI responded on http://localhost:{0}" -f $script:OtelPorts.SignozUiHttp) -Color Green
} catch {
    $warnings += ("SigNoz UI did not respond on http://localhost:{0}" -f $script:OtelPorts.SignozUiHttp)
    Add-ReportLine -Level 'WARN' -Message ("SigNoz UI did not respond on http://localhost:{0}" -f $script:OtelPorts.SignozUiHttp) -Color Yellow
}

$ports = @(
    $script:OtelPorts.IngestGrpc,
    $script:OtelPorts.IngestHttp,
    $script:OtelPorts.SignozOtlpGrpc,
    $script:OtelPorts.SignozOtlpHttp
)
foreach ($port in $ports) {
    if (Test-Port -Port $port) {
        Add-ReportLine -Level 'OK' -Message ("Port $port accepts TCP connections") -Color Green
    } else {
        $warnings += "Port $port not reachable"
        Add-ReportLine -Level 'WARN' -Message ("Port $port not reachable") -Color Yellow
    }
}

# Collector service
Add-ReportLine -Level 'SECTION' -Message 'Windows collector service' -Color Yellow
try {
    $service = Get-Service -Name 'otelcol-contrib' -ErrorAction Stop
    Add-ReportLine -Level 'OK' -Message ("otelcol-contrib status: " + $service.Status) -Color Green
    if ($service.Status -ne 'Running') {
        $issues += 'otelcol-contrib service is not running'
        Add-ReportLine -Level 'WARN' -Message 'Service not running: consider Restart-Service otelcol-contrib' -Color Yellow
    }
} catch {
    $issues += 'otelcol-contrib service not found'
    Add-ReportLine -Level 'FAIL' -Message 'otelcol-contrib service not found' -Color Red
}

# Agent infrastructure
Add-ReportLine -Level 'SECTION' -Message 'Agent workflow files' -Color Yellow
if (Test-Path '.agent') {
    Add-ReportLine -Level 'OK' -Message '.agent directory present' -Color Green
    if (Test-Path '.agent/LOCK') {
        $warnings += '.agent/LOCK present (agents paused)'
        Add-ReportLine -Level 'WARN' -Message '.agent/LOCK present (agents paused)' -Color Yellow
    }
    if (Test-Path '.agent/status.json') {
        Add-ReportLine -Level 'OK' -Message '.agent/status.json found' -Color Green
    }
} else {
    $warnings += '.agent directory missing'
    Add-ReportLine -Level 'WARN' -Message '.agent directory missing' -Color Yellow
}

# ECRR reports directory
Add-ReportLine -Level 'SECTION' -Message 'ECRR report storage' -Color Yellow
if (-not (Test-Path 'CHAR/ECRR/ECRR_REPORTS')) {
    New-Item -ItemType Directory -Path 'CHAR/ECRR/ECRR_REPORTS' -Force | Out-Null
    Add-ReportLine -Level 'OK' -Message 'Created CHAR/ECRR/ECRR_REPORTS directory' -Color Green
} else {
    $count = (Get-ChildItem 'CHAR/ECRR/ECRR_REPORTS' -Filter '*.md' | Measure-Object).Count
    Add-ReportLine -Level 'OK' -Message ("CHAR/ECRR/ECRR_REPORTS present with $count markdown files") -Color Green
}

# Suggested manual checks
Add-ReportLine -Level 'SECTION' -Message 'Manual follow-up checks' -Color Yellow
Add-ReportLine -Level 'NOTE' -Message 'Run pwsh -File scripts/canary-test.ps1 and confirm SigNoz logs show the canary message within 30 seconds.'
Add-ReportLine -Level 'NOTE' -Message 'Inspect config.yaml to confirm OTLP exporters target http://localhost:4317.'
Add-ReportLine -Level 'NOTE' -Message 'Review SigNoz Logs with filter: message contains "SigNoz test".'

# Summary
Add-ReportLine -Level 'SECTION' -Message 'Summary' -Color Yellow
if ($issues.Count -eq 0) {
    Add-ReportLine -Level 'OK' -Message 'No critical issues detected' -Color Green
} else {
    foreach ($issue in $issues) {
        Add-ReportLine -Level 'FAIL' -Message $issue -Color Red
    }
}
if ($warnings.Count -gt 0) {
    foreach ($warning in $warnings) {
        Add-ReportLine -Level 'WARN' -Message $warning -Color Yellow
    }
}

# Persist artifact
$artifactDir = 'artifacts'
if (-not (Test-Path $artifactDir)) {
    New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
}
$artifactPath = Join-Path $artifactDir 'ecrr-doctor.txt'
$report | Set-Content -Path $artifactPath
Add-ReportLine -Level 'INFO' -Message ('Report written to ' + (Resolve-Path $artifactPath)) -Color Cyan

if ($issues.Count -gt 0) {
    exit 1
} else {
    exit 0
}
