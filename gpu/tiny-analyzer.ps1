# Tiny Health Report Analyzer
# Converts minimal health reports into alert JSON for downstream automation

[CmdletBinding()]
param(
    [string]$ReportPath,
    [switch]$LatestReport,
    [int]$HealthThreshold = 75
)

Write-Host "=== Tiny Health Report Analyzer ===" -ForegroundColor Cyan
Write-Host ("Health threshold: {0}" -f $HealthThreshold) -ForegroundColor Yellow

# Resolve report path when --LatestReport flag is used
if (-not $ReportPath -and $LatestReport) {
    $reportsDir = Join-Path $PSScriptRoot 'monitoring\reports'
    if (-not (Test-Path $reportsDir)) {
        Write-Host "Reports directory not found: $reportsDir" -ForegroundColor Red
        return
    }
    $latest = Get-ChildItem $reportsDir -Filter 'health_report_*.json' |
              Sort-Object LastWriteTime -Descending |
              Select-Object -First 1
    if (-not $latest) {
        Write-Host "No reports found in $reportsDir" -ForegroundColor Yellow
        return
    }
    $ReportPath = $latest.FullName
    Write-Host "Using latest report: $($latest.Name)" -ForegroundColor Yellow
}

if (-not $ReportPath -or -not (Test-Path $ReportPath)) {
    Write-Host "Report path is invalid." -ForegroundColor Red
    return
}

try {
    $report = Get-Content $ReportPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "Failed to load report: $($_.Exception.Message)" -ForegroundColor Red
    return
}

$alertTimestamp = if ($report.timestamp) { $report.timestamp } else { (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ') }
$healthScore = $report.health_score
if ($null -eq $healthScore) {
    Write-Host "Report does not contain a health_score field." -ForegroundColor Red
    return
}

$scoreColor = if ($healthScore -ge $HealthThreshold) { 'Green' } else { 'Red' }
Write-Host ("Report health score: {0}" -f $healthScore) -ForegroundColor $scoreColor

$alerts = @()
if ($healthScore -lt $HealthThreshold) {
    $severity = if ($healthScore -lt [math]::Min(50, $HealthThreshold / 2)) { 'CRITICAL' } else { 'WARNING' }
    $alerts += [ordered]@{
        id          = [guid]::NewGuid().ToString()
        type        = 'HEALTH_SCORE_LOW'
        severity    = $severity
        message     = "Health score is $healthScore (threshold: $HealthThreshold)"
        category    = 'overall-health'
        metric      = 'health_score'
        value       = $healthScore
        threshold   = $HealthThreshold
        timestamp   = $alertTimestamp
        details     = [ordered]@{
            otel_collector   = $report.parsed.otel_collector
            metrics_endpoint = $report.parsed.metrics_endpoint
            canary_endpoint  = $report.parsed.canary_endpoint
            kafka_status     = $report.parsed.kafka_status
            warnings         = $report.parsed.warnings
        }
    }
} else {
    Write-Host "Health score within threshold; no alerts generated." -ForegroundColor Green
}

# Metrics signal slice
if ($report.metrics_lines -and $report.metrics_lines.Count -gt 0) {
    $metricsIssues = $report.metrics_lines | Where-Object { $_ -match '(?i)(unreachable|failed|error|timeout)' }
    if ($metricsIssues.Count -gt 0) {
        $alerts += [ordered]@{
            id         = [guid]::NewGuid().ToString()
            type       = 'WARNING'
            category   = 'metrics-endpoint'
            metric     = 'availability'
            value      = 'degraded'
            threshold  = 'reachable'
            message    = 'Metrics endpoint issues detected.'
            timestamp  = $alertTimestamp
            details    = @{ samples = @($metricsIssues) }
        }
    }

    $metricPortConflicts = $report.metrics_lines | Where-Object { $_ -match '(?i)(port.+in use|already in use|bind.+failed)' }
    if ($metricPortConflicts.Count -gt 0) {
        $alerts += [ordered]@{
            id         = [guid]::NewGuid().ToString()
            type       = 'WARNING'
            category   = 'metrics-endpoint'
            metric     = 'port_conflict'
            value      = 'conflict_detected'
            threshold  = 'no_conflict'
            message    = 'Metrics port conflict reported.'
            timestamp  = $alertTimestamp
            details    = @{ samples = @($metricPortConflicts) }
        }
    }
}

# Kafka signal slice
if ($report.kafka_lines -and $report.kafka_lines.Count -gt 0) {
    $kafkaUnavailable = $report.kafka_lines | Where-Object { $_ -match '(?i)(unavailable|failed|error|timeout|unreachable)' }
    if ($kafkaUnavailable.Count -gt 0) {
        $alerts += [ordered]@{
            id         = [guid]::NewGuid().ToString()
            type       = 'WARNING'
            category   = 'kafka-connectivity'
            metric     = 'availability'
            value      = 'degraded'
            threshold  = 'available'
            message    = 'Kafka availability issues detected.'
            timestamp  = $alertTimestamp
            details    = @{ samples = @($kafkaUnavailable) }
        }
    }

    $kafkaConnectionErrors = $report.kafka_lines | Where-Object { $_ -match '(?i)(connection.+failed|connect.+refused|network.+error)' }
    if ($kafkaConnectionErrors.Count -gt 0) {
        $alerts += [ordered]@{
            id         = [guid]::NewGuid().ToString()
            type       = 'WARNING'
            category   = 'kafka-connectivity'
            metric     = 'connection_error'
            value      = 'connection_failed'
            threshold  = 'connected'
            message    = 'Kafka connection errors reported.'
            timestamp  = $alertTimestamp
            details    = @{ samples = @($kafkaConnectionErrors) }
        }
    }
}

# Canary signal slice
if ($report.canary_lines -and $report.canary_lines.Count -gt 0) {
    $canaryFailures = $report.canary_lines | Where-Object { $_ -match '(?i)(failed|error|timeout|unreachable)' }
    if ($canaryFailures.Count -gt 0) {
        $alerts += [ordered]@{
            id         = [guid]::NewGuid().ToString()
            type       = 'WARNING'
            category   = 'canary-test'
            metric     = 'result'
            value      = 'failed'
            threshold  = 'success'
            message    = 'Canary test failures detected.'
            timestamp  = $alertTimestamp
            details    = @{ samples = @($canaryFailures) }
        }
    }

    $canaryConnectivity = $report.canary_lines | Where-Object { $_ -match '(?i)(connection.+failed|connect.+refused|network.+error)' }
    if ($canaryConnectivity.Count -gt 0) {
        $alerts += [ordered]@{
            id         = [guid]::NewGuid().ToString()
            type       = 'WARNING'
            category   = 'canary-test'
            metric     = 'connectivity'
            value      = 'connection_failed'
            threshold  = 'connected'
            message    = 'Canary connectivity issues detected.'
            timestamp  = $alertTimestamp
            details    = @{ samples = @($canaryConnectivity) }
        }
    }
}

# GPU signal slice
if ($report.gpu_lines -and $report.gpu_lines.Count -gt 0) {
    $gpuUtilMatches = $report.gpu_lines | ForEach-Object {
        if ($_ -match '(?i)utilization[^0-9]*(\d+)%') { [int]$matches[1] }
    }
    if ($gpuUtilMatches.Count -gt 0) {
        $maxUtil = ($gpuUtilMatches | Measure-Object -Maximum).Maximum
        if ($maxUtil -gt 80) {
            $alerts += [ordered]@{
                id         = [guid]::NewGuid().ToString()
                type       = 'WARNING'
                category   = 'gpu-performance'
                metric     = 'gpu_utilization'
                value      = $maxUtil
                threshold  = 80
                message    = "GPU utilization is $maxUtil% (threshold: 80%)"
                timestamp  = $alertTimestamp
                details    = @{ samples = @($report.gpu_lines) }
            }
        }
    }

    $gpuTempMatches = $report.gpu_lines | ForEach-Object {
        if ($_ -match '(?i)(temperature|temp)[^0-9]*(\d+)°?C') { [int]$matches[2] }
    }
    if ($gpuTempMatches.Count -gt 0) {
        $maxTemp = ($gpuTempMatches | Measure-Object -Maximum).Maximum
        if ($maxTemp -gt 75) {
            $alerts += [ordered]@{
                id         = [guid]::NewGuid().ToString()
                type       = 'WARNING'
                category   = 'gpu-performance'
                metric     = 'gpu_temperature'
                value      = $maxTemp
                threshold  = 75
                message    = "GPU temperature is ${maxTemp}°C (threshold: 75°C)"
                timestamp  = $alertTimestamp
                details    = @{ samples = @($report.gpu_lines) }
            }
        }
    }

    $gpuMemMatches = $report.gpu_lines | ForEach-Object {
        if ($_ -match '(?i)(memory|mem)[^0-9]*(\d+)%') { [int]$matches[2] }
    }
    if ($gpuMemMatches.Count -gt 0) {
        $maxMem = ($gpuMemMatches | Measure-Object -Maximum).Maximum
        if ($maxMem -gt 90) {
            $alerts += [ordered]@{
                id         = [guid]::NewGuid().ToString()
                type       = 'WARNING'
                category   = 'gpu-performance'
                metric     = 'gpu_memory'
                value      = $maxMem
                threshold  = 90
                message    = "GPU memory usage is $maxMem% (threshold: 90%)"
                timestamp  = $alertTimestamp
                details    = @{ samples = @($report.gpu_lines) }
            }
        }
    }

    $gpuDriverIssues = $report.gpu_lines | Where-Object { $_ -match '(?i)(driver|cuda|nvidia|api).+error' }
    if ($gpuDriverIssues.Count -gt 0) {
        $alerts += [ordered]@{
            id         = [guid]::NewGuid().ToString()
            type       = 'WARNING'
            category   = 'gpu-performance'
            metric     = 'driver_error'
            value      = 'error_detected'
            threshold  = 'no_error'
            message    = 'GPU driver/API errors detected.'
            timestamp  = $alertTimestamp
            details    = @{ samples = @($gpuDriverIssues) }
        }
    }
}

$alertsDir = Join-Path $PSScriptRoot 'monitoring\alerts'
[System.IO.Directory]::CreateDirectory($alertsDir) | Out-Null

if ($alerts.Count -eq 0) {
    Write-Host "No alerts to save." -ForegroundColor Green
    return
}

$payload = [ordered]@{
    timestamp        = $alertTimestamp
    report_path      = $ReportPath
    health_threshold = $HealthThreshold
    alert_count      = $alerts.Count
    alerts           = $alerts
}

$alertPath = Join-Path $alertsDir ("health_alerts_{0}.json" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
$payload | ConvertTo-Json -Depth 5 | Out-File -FilePath $alertPath -Encoding UTF8

Write-Host ("Saved {0} alert(s) to {1}" -f $alerts.Count, $alertPath) -ForegroundColor Green