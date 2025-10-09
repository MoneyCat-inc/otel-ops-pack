# Minimal Health Report Generator
# Reads health-check.ps1 output and produces a lightweight JSON summary

[CmdletBinding()]
param(
    [string]$HealthCheckOutput,
    [switch]$UseLatestLog
)

Write-Host "=== Minimal Health Report Generator ===" -ForegroundColor Cyan

function Invoke-HealthCheck {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'powershell.exe'
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\..\health-check.ps1`" -Mode full"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return ($stdout + $stderr)
}

# Acquire health-check output
if (-not $HealthCheckOutput) {
    if ($UseLatestLog -and (Test-Path "$PSScriptRoot\..\logs")) {
        $latest = Get-ChildItem "$PSScriptRoot\..\logs" -Filter '*health*' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) {
            Write-Host "Using latest log: $($latest.Name)" -ForegroundColor Yellow
            $HealthCheckOutput = Get-Content $latest.FullName -Raw
        }
    }
}

if (-not $HealthCheckOutput) {
    Write-Host "Running health-check.ps1 ..." -ForegroundColor Yellow
    try {
        $HealthCheckOutput = Invoke-HealthCheck
    } catch {
        Write-Host "Failed to run health-check.ps1: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
}

if (-not $HealthCheckOutput) {
    Write-Host "No health-check output available." -ForegroundColor Red
    return
}

Write-Host "Parsing health-check output..." -ForegroundColor Yellow

$report = [ordered]@{
    timestamp    = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    source       = 'health-check.ps1'
    health_score = 0
    parsed       = [ordered]@{
        otel_collector   = 'unknown'
        metrics_endpoint = 'unknown'
        canary_endpoint  = 'unknown'
        kafka_status     = 'unknown'
        warnings         = @()
    }
    raw_lines     = @()
    metrics_lines = @()
    kafka_lines   = @()
    canary_lines  = @()
    gpu_lines     = @()
    otel_lines    = @()
    signoz_lines  = @()
}

if ($HealthCheckOutput -match 'Service: Running') {
    $report.parsed.otel_collector = 'running'
    $report.health_score += 30
} elseif ($HealthCheckOutput -match 'Service: NOT FOUND') {
    $report.parsed.otel_collector = 'missing'
}

if ($HealthCheckOutput -match 'Metrics: DOWN') {
    $report.parsed.metrics_endpoint = 'down'
} elseif ($HealthCheckOutput -match 'Metrics: OK') {
    $report.parsed.metrics_endpoint = 'ok'
    $report.health_score += 20
}

if ($HealthCheckOutput -match 'Canary: ERROR') {
    $report.parsed.canary_endpoint = 'error'
} elseif ($HealthCheckOutput -match 'Canary: OK') {
    $report.parsed.canary_endpoint = 'ok'
    $report.health_score += 20
}

if ($HealthCheckOutput -match 'Kafka: UNREACHABLE') {
    $report.parsed.kafka_status = 'unreachable'
} elseif ($HealthCheckOutput -match 'Kafka: OK') {
    $report.parsed.kafka_status = 'ok'
    $report.health_score += 10
}

$warnings = @()
$HealthCheckOutput -split "`n" | Where-Object { $_ -match '^WARNING:' } | ForEach-Object { $warnings += $_.Trim() }
$report.parsed.warnings = $warnings
if ($warnings.Count -gt 0) {
    $report.health_score -= [math]::Min(10, $warnings.Count * 2)
}

$healthLines = $HealthCheckOutput -split "`n"
# Capture raw segments for downstream analysis
$report.raw_lines     = @($healthLines)
$report.metrics_lines = @($healthLines | Where-Object { $_ -match "(?i)metrics" })
$report.kafka_lines   = @($healthLines | Where-Object { $_ -match "(?i)kafka" })
$report.canary_lines  = @($healthLines | Where-Object { $_ -match "(?i)canary" })
$report.gpu_lines     = @($healthLines | Where-Object { $_ -match "(?i)gpu" })
$report.otel_lines    = @($healthLines | Where-Object { $_ -match "(?i)otel" })
$report.signoz_lines  = @($healthLines | Where-Object { $_ -match "(?i)signoz" })

$reportPath = Join-Path "$PSScriptRoot\monitoring\reports" ("health_report_{0}.json" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$report | ConvertTo-Json -Depth 4 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Report written to $reportPath" -ForegroundColor Green
Write-Host "Health score: $($report.health_score)" -ForegroundColor Cyan
