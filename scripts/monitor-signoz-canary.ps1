#Requires -Version 7.0

<#
.SYNOPSIS
    Monitor SigNoz canary ingestion with ClickHouse queries and optional canary emission.

.DESCRIPTION
    Emits (optionally) a Windows + file log canary, queries ClickHouse for recent
    SigNoz canary entries, and writes structured reports that scheduled tasks can consume.
    Exit codes: 0=healthy, 1=warning, 2=critical (no canary), 3=script error.

.PARAMETER AlertThreshold
    Minimum expected canary entries per hour (default: 1).

.PARAMETER SpikeThreshold
    Maximum expected canary entries per hour before considering it a spike (default: 350).

.PARAMETER TimeWindowMinutes
    Observation window in minutes for the ClickHouse query (default: 60).

.PARAMETER EmitCanary
    When supplied, explicitly emit a canary before querying. If omitted, emission is enabled by default.

.EXAMPLE
    .\monitor-signoz-canary.ps1
    Runs the monitor, emits a canary, and verifies ingestion over the last hour.

.EXAMPLE
    .\monitor-signoz-canary.ps1 -EmitCanary:$false -TimeWindowMinutes 15
    Skips emission and only verifies that existing canaries are present for the last 15 minutes.
#>

param(
    [int]$AlertThreshold = 1,
    [int]$SpikeThreshold = 350,
    [int]$TimeWindowMinutes = 60,
    [switch]$EmitCanary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'spinner-toolkit.ps1')

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]    $Message" -ForegroundColor Green
}

function Write-WarnMsg {
    param([string]$Message)
    Write-Host "[WARN]  $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([string]$Message)
    Write-Host "[FAIL]  $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO]  $Message" -ForegroundColor Cyan
}

$ClickHouseContainer = 'signoz-clickhouse'
$LogTable = 'signoz_logs.distributed_logs_v2'
$CanaryFilterClause = "body LIKE '%SigNoz wiring canary%'"
$ArtifactsDir = 'artifacts'
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$LatestReportPath = Join-Path $ArtifactsDir 'signoz-canary-monitor-latest.json'

if (-not (Test-Path $ArtifactsDir)) {
    New-Item -Path $ArtifactsDir -ItemType Directory | Out-Null
}

function Invoke-ClickHouseJson {
    param(
        [Parameter(Mandatory = $true)][string]$Query,
        [Parameter(Mandatory = $true)][string]$ContainerName
    )

    $raw = docker exec $ContainerName clickhouse-client --query="$Query"
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "ClickHouse returned no data. Query:`n$Query"
    }

    try {
        return $raw | ConvertFrom-Json
    }
    catch {
        throw "Failed to parse ClickHouse JSON response: $($_.Exception.Message). Raw:`n$raw"
    }
}

$shouldEmitCanary = if ($PSBoundParameters.ContainsKey('EmitCanary')) { $EmitCanary.IsPresent } else { $true }

Write-Info "Starting SigNoz canary monitor at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "Alert threshold: $AlertThreshold/hour | Spike threshold: $SpikeThreshold/hour | Window: $TimeWindowMinutes minutes"
Write-Info "Emit canary this run: $shouldEmitCanary"

try {
    Show-ThinkingAnimation -Message "Checking ClickHouse container status..." -AnimationType "Health" -DurationMs 200
    $containerStatus = docker ps --filter "name=^/$ClickHouseContainer$" --format '{{.Status}}'
    Clear-Spinner
    if (-not $containerStatus -or $containerStatus -notmatch '^Up') {
        throw "ClickHouse container '$ClickHouseContainer' is not running (status: '$containerStatus')"
    }

    $canaryMessage = $null
    if ($shouldEmitCanary) {
        Write-Info 'Emitting canary (Application event + file log)'
        $source = 'SigNozTestSource'
        $logName = 'Application'
        if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
            New-EventLog -LogName $logName -Source $source | Out-Null
        }
        $ts = Get-Date -Format 's'
        $canaryMessage = "SigNoz wiring canary sent $ts"
        Write-EventLog -LogName $logName -Source $source -EntryType Information -EventId 1001 -Message $canaryMessage

        $logDir = 'C:/logs/signoz-canary'
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir | Out-Null
        }
        $payload = @{ level = 'INFO'; message = $canaryMessage; timestamp = (Get-Date).ToUniversalTime().ToString('o'); eventId = 1001; source = $source } | ConvertTo-Json -Compress
        Add-Content -Path (Join-Path $logDir 'canary.log') -Value $payload
        Write-Success "Canary emitted: $canaryMessage"
        Wait-WithSpinner -Seconds 3 -Message 'Waiting for canary ingestion...' -AnimationType 'Analytics'
    }

    $aggregateQuery = @"
SELECT
    count(*) AS canary_count,
    min(fromUnixTimestamp64Nano(timestamp)) AS earliest_ts,
    max(fromUnixTimestamp64Nano(timestamp)) AS latest_ts
FROM $LogTable
WHERE $CanaryFilterClause
  AND timestamp >= now() - INTERVAL $TimeWindowMinutes MINUTE
FORMAT JSON
"@

    Show-ThinkingAnimation -Message "Querying ClickHouse (aggregate window)..." -AnimationType "Analytics" -DurationMs 220
    $aggregateResponse = Invoke-ClickHouseJson -Query $aggregateQuery -ContainerName $ClickHouseContainer
    Clear-Spinner
    if (-not $aggregateResponse.data -or $aggregateResponse.data.Count -eq 0) {
        throw "ClickHouse returned an empty data array for canary aggregate query."
    }

    $aggregateRow = $aggregateResponse.data[0]
    $canaryCount = if ($aggregateRow.canary_count) { [int]$aggregateRow.canary_count } else { 0 }
    $earliestTs = if ($aggregateRow.earliest_ts) { $aggregateRow.earliest_ts } else { $null }
    $latestTs = if ($aggregateRow.latest_ts) { $aggregateRow.latest_ts } else { $null }

    Write-Info "Canary entries observed: $canaryCount over the last $TimeWindowMinutes minutes"
    if ($latestTs) {
        Write-Info "Latest canary timestamp: $latestTs"
    }

    $latestQuery = @"
SELECT
    fromUnixTimestamp64Nano(timestamp) AS event_time,
    body
FROM $LogTable
WHERE $CanaryFilterClause
ORDER BY timestamp DESC
LIMIT 1
FORMAT JSON
"@

    Show-ThinkingAnimation -Message "Fetching latest canary log..." -AnimationType "Analytics" -DurationMs 200
    $latestResponse = Invoke-ClickHouseJson -Query $latestQuery -ContainerName $ClickHouseContainer
    Clear-Spinner
    $latestRecord = $null
    if ($latestResponse.data -and $latestResponse.data.Count -gt 0) {
        $latestRecord = $latestResponse.data[0]
        Write-Info "Newest canary body: $($latestRecord.body)"
    } else {
        Write-WarnMsg 'No matching canary row was returned from ClickHouse.'
    }

    $report = [ordered]@{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        emittedMessage = $canaryMessage
        timeWindowMinutes = $TimeWindowMinutes
        canaryCount = $canaryCount
        earliestTimestamp = $earliestTs
        latestTimestamp = $latestTs
        alertThreshold = $AlertThreshold
        spikeThreshold = $SpikeThreshold
        status = 'healthy'
        alerts = @()
        latest = $latestRecord
    }

    if ($canaryCount -eq 0) {
        $alertMsg = "CRITICAL: zero SigNoz canary entries in the last $TimeWindowMinutes minutes"
        Write-Failure $alertMsg
        $report.status = 'critical'
        $report.alerts += $alertMsg

        $diagQuery = @"
SELECT
    count(*) AS total_logs,
    countIf($CanaryFilterClause) AS matching_canary_logs,
    max(fromUnixTimestamp64Nano(timestamp)) AS newest_log
FROM $LogTable
WHERE timestamp >= now() - INTERVAL $TimeWindowMinutes MINUTE
FORMAT JSON
"@
        Show-ThinkingAnimation -Message "Collecting diagnostic totals..." -AnimationType "Analytics" -DurationMs 200
        $diag = Invoke-ClickHouseJson -Query $diagQuery -ContainerName $ClickHouseContainer
        Clear-Spinner
        if ($diag.data.Count -gt 0) {
            $report['diagnostic'] = $diag.data[0]
            Write-WarnMsg "Diagnostic totals: total_logs=$($diag.data[0].total_logs); matching_canary_logs=$($diag.data[0].matching_canary_logs); newest_log=$($diag.data[0].newest_log)"
        }
    }
    elseif ($canaryCount -lt $AlertThreshold) {
        $alertMsg = "WARNING: only $canaryCount canary entries observed (threshold: $AlertThreshold)"
        Write-WarnMsg $alertMsg
        $report.status = 'warning'
        $report.alerts += $alertMsg
    }
    elseif ($canaryCount -gt $SpikeThreshold) {
        $alertMsg = "WARNING: spike detected with $canaryCount canary entries (spike threshold: $SpikeThreshold)"
        Write-WarnMsg $alertMsg
        $report.status = 'warning'
        $report.alerts += $alertMsg
    }
    else {
        Write-Success "Canary ingestion is within expected range."
    }

    $reportJson = $report | ConvertTo-Json -Depth 6
    $reportFile = Join-Path $ArtifactsDir "signoz-canary-monitor-$Timestamp.json"
    $reportJson | Out-File -FilePath $reportFile -Encoding UTF8
    $reportJson | Out-File -FilePath $LatestReportPath -Encoding UTF8
    Write-Info "Reports written to $reportFile and $LatestReportPath"

    switch ($report.status) {
        'critical' { exit 2 }
        'warning'  { exit 1 }
        default    { exit 0 }
    }
}
catch {
    $errorMsg = "SigNoz canary monitor failed: $($_.Exception.Message)"
    Write-Failure $errorMsg

    $errorReport = [ordered]@{
        timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        status = 'error'
        error = $errorMsg
        stack = $_.ScriptStackTrace
    }

    $errorFile = Join-Path $ArtifactsDir "signoz-canary-monitor-error-$Timestamp.json"
    $errorJson = $errorReport | ConvertTo-Json -Depth 4
    $errorJson | Out-File -FilePath $errorFile -Encoding UTF8
    $errorJson | Out-File -FilePath $LatestReportPath -Encoding UTF8

    exit 3
}







