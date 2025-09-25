#Requires -Version 7.0

param(
    [int]$TimeWindowMinutes = 15,
    [string]$MonitorScript = 'C:/otel/scripts/monitor-signoz-canary.ps1',
    [string]$ReportPath = 'C:/otel/artifacts/signoz-canary-monitor-latest.json'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$pwshExe = Join-Path $PSHOME 'pwsh.exe'
if (-not (Test-Path $pwshExe)) {
    $pwshExe = 'pwsh.exe'
}

if (-not (Test-Path $MonitorScript)) {
    throw "Monitor script not found at $MonitorScript"
}

$arguments = @('-NoLogo','-NonInteractive','-File', $MonitorScript, '-TimeWindowMinutes', $TimeWindowMinutes)

Write-Host "[INFO] Launching SigNoz canary monitor: $MonitorScript (-TimeWindowMinutes $TimeWindowMinutes)" -ForegroundColor Cyan
$process = Start-Process -FilePath $pwshExe -ArgumentList $arguments -Wait -PassThru
$exitCode = $process.ExitCode
Write-Host "[INFO] Monitor exit code: $exitCode" -ForegroundColor Cyan

$status = 'unknown'
$message = "SigNoz canary monitor completed with exit code $exitCode"

if (Test-Path $ReportPath) {
    try {
        $report = Get-Content -Raw -Path $ReportPath | ConvertFrom-Json
        if ($report.status) { $status = $report.status }
        $message = "SigNoz canary status: $status (exit $exitCode). Latest report: $ReportPath"
        if ($report.alerts) {
            $alertSummary = ($report.alerts | Out-String).Trim()
            if ($alertSummary) {
                $message += "`nAlerts:`n$alertSummary"
            }
        }
    } catch {
        $message += "`n(Report parse failure: $($_.Exception.Message))"
    }
} else {
    $message += "`nLatest report not found at $ReportPath"
}

$eventSource = 'SigNozCanaryMonitor'
$logName = 'Application'
if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    try {
        New-EventLog -LogName $logName -Source $eventSource
    } catch {
        Write-Warning "Unable to register event source ${eventSource}: $($_.Exception.Message)"
    }
}

if ($exitCode -eq 0) {
    Write-Host "[OK] $message" -ForegroundColor Green
    if ([System.Diagnostics.EventLog]::SourceExists($eventSource)) {
        Write-EventLog -LogName $logName -Source $eventSource -EventId 5000 -EntryType Information -Message $message
    }
} else {
    Write-Host "[FAIL] $message" -ForegroundColor Red
    if ([System.Diagnostics.EventLog]::SourceExists($eventSource)) {
        Write-EventLog -LogName $logName -Source $eventSource -EventId 5001 -EntryType Error -Message $message
    }
    try {
        msg * "SigNoz canary monitor $status (exit $exitCode). Check $ReportPath" | Out-Null
    } catch {
        Write-Warning "Failed to broadcast msg notification: $($_.Exception.Message)"
    }
}

exit $exitCode

