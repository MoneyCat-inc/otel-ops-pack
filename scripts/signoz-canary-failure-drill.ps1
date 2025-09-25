#Requires -Version 7.0

param(
    [int]$RemediationWaitSeconds = 30,
    [int]$ValidationWindowMinutes = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$artifactsDir = 'C:/otel/artifacts'
if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir | Out-Null
}
$drillLog = Join-Path $artifactsDir "signoz-canary-failure-drill-$timestamp.json"

$serviceName = 'otelcol-contrib'
$eventSource = 'SigNozCanaryDrill'
$logName = 'Application'

if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    try { New-EventLog -LogName $logName -Source $eventSource } catch { }
}

$steps = New-Object System.Collections.Generic.List[object]

function Add-Step {
    param($Name, $Status, $Detail)
    $steps.Add([ordered]@{ name = $Name; status = $Status; detail = $Detail })
}

try {
    Add-Step 'pre-check' 'info' "Service status before drill: $((Get-Service -Name $serviceName).Status)"

    Stop-Service -Name $serviceName -Force -ErrorAction Stop
    Add-Step 'stop-service' 'ok' 'otelcol-contrib stopped successfully'

    if (Test-Path 'C:/otel/artifacts/signoz-canary-monitor-latest.json') {
        $report = Get-Content -Raw -Path 'C:/otel/artifacts/signoz-canary-monitor-latest.json' | ConvertFrom-Json
    } else {
        $report = [ordered]@{}
    }

    $report.status = 'critical'
    $report.alerts = @('Monthly failure drill triggered')
    $report.canaryCount = 0
    $report.timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path 'C:/otel/artifacts/signoz-canary-monitor-latest.json' -Encoding UTF8
    Add-Step 'mark-report' 'ok' 'Latest canary report flagged critical for remediation trigger'

    Write-EventLog -LogName Application -Source SigNozCanaryMonitor -EventId 5001 -EntryType Error -Message 'Monthly canary failure drill: otelcol-contrib taken offline'
    Add-Step 'emit-event' 'ok' 'Synthetic SigNozCanaryMonitor error event emitted'

    Start-Sleep -Seconds $RemediationWaitSeconds
    $serviceStatus = (Get-Service -Name $serviceName).Status
    if ($serviceStatus -ne 'Running') {
        try {
            Start-Service -Name $serviceName -ErrorAction Stop
            $serviceStatus = (Get-Service -Name $serviceName).Status
            Add-Step 'restart-service-manual' 'ok' 'Service restarted manually after remediation window'
        } catch {
            Add-Step 'restart-service-manual' 'fail' $_.Exception.Message
        }
    } else {
        Add-Step 'remediation' 'ok' 'Service already running after remediation window'
    }

    & 'C:/otel/scripts/monitor-signoz-canary-scheduled.ps1' -TimeWindowMinutes $ValidationWindowMinutes | Out-Null
    Add-Step 'post-monitor' 'ok' "Monitor executed for $ValidationWindowMinutes minute window"

    $finalStatus = (Get-Service -Name $serviceName).Status
    Add-Step 'final-status' 'info' "Service status after drill: $finalStatus"

    $result = [ordered]@{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        remediationWaitSeconds = $RemediationWaitSeconds
        validationWindowMinutes = $ValidationWindowMinutes
        serviceStatus = $finalStatus
        steps = $steps
    }

    $result | ConvertTo-Json -Depth 6 | Out-File -FilePath $drillLog -Encoding UTF8

    if ([System.Diagnostics.EventLog]::SourceExists($eventSource)) {
        Write-EventLog -LogName $logName -Source $eventSource -EventId 5200 -EntryType Information -Message "Monthly SigNoz canary drill completed. Service status: $finalStatus. Log: $drillLog"
    }

} catch {
    $errorResult = [ordered]@{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        error = $_.Exception.Message
        steps = $steps
    }
    $errorResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $drillLog -Encoding UTF8
    if ([System.Diagnostics.EventLog]::SourceExists($eventSource)) {
        Write-EventLog -LogName $logName -Source $eventSource -EventId 5201 -EntryType Error -Message "SigNoz canary drill failed: $($_.Exception.Message). Log: $drillLog"
    }
    throw
}
