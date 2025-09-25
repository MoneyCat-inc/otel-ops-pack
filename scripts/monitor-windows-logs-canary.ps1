#Requires -Version 7.0

<#
.SYNOPSIS
    Monitor Windows Event Log canary ingestion with ClickHouse queries

.DESCRIPTION
    This script monitors Windows Event Log canary entries in SigNoz by querying
    ClickHouse directly. It alerts when canary count drops below threshold,
    indicating potential Windows logs ingestion pipeline issues.

.PARAMETER AlertThreshold
    Minimum expected Windows logs canary entries per hour (default: 1)

.PARAMETER TimeWindowMinutes
    Time window for monitoring in minutes (default: 60)

.EXAMPLE
    .\monitor-windows-logs-canary.ps1
    .\monitor-windows-logs-canary.ps1 -AlertThreshold 5 -TimeWindowMinutes 30
#>

param(
    [int]$AlertThreshold = 1,      # Minimum expected canary entries per hour
    [int]$TimeWindowMinutes = 60   # 1 hour monitoring window
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }

# Configuration
$ClickHouseContainer = "signoz-clickhouse"
$LogTable = "signoz_logs.distributed_logs_v2"
$ArtifactsDir = "artifacts"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Ensure artifacts directory exists
if (-not (Test-Path $ArtifactsDir)) {
    New-Item -Path $ArtifactsDir -ItemType Directory | Out-Null
}

Write-Info "🔍 Starting Windows Logs Canary Monitoring"
Write-Info "=========================================="
Write-Info "Time window: $TimeWindowMinutes minutes"
Write-Info "Alert threshold: $AlertThreshold entries"
Write-Info "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

try {
    # Check if ClickHouse container is running
    $containerStatus = docker ps --filter "name=$ClickHouseContainer" --format "{{.Status}}"
    if (-not $containerStatus -or $containerStatus -notmatch "Up") {
        throw "ClickHouse container '$ClickHouseContainer' is not running"
    }
    Write-Success "ClickHouse container is running"

    # Query for Windows logs canary entries in the specified time window
    $query = @"
SELECT 
    count(*) as canary_count,
    min(fromUnixTimestamp64Nano(timestamp)) as earliest_ts,
    max(fromUnixTimestamp64Nano(timestamp)) as latest_ts
FROM $LogTable 
WHERE attributes_string['dataset'] = 'windows'
  AND body LIKE '%windows-logs-canary%'
  AND timestamp > now() - INTERVAL $TimeWindowMinutes MINUTE
"@

    Write-Info "Executing ClickHouse query for Windows logs canaries..."
    $result = docker exec $ClickHouseContainer clickhouse-client --query $query
    
    if (-not $result) {
        throw "ClickHouse query returned no results"
    }

    # Parse the result (format: count<TAB>earliest_ts<TAB>latest_ts)
    $parts = $result -split "`t"
    $canaryCount = [int]$parts[0]
    $earliestTs = if ($parts[1] -ne "1970-01-01 00:00:00") { $parts[1] } else { "None" }
    $latestTs = if ($parts[2] -ne "1970-01-01 00:00:00") { $parts[2] } else { "None" }

    Write-Info "Windows logs canary entries found: $canaryCount in last $TimeWindowMinutes minutes"
    if ($earliestTs -ne "None") {
        Write-Info "Time range: $earliestTs to $latestTs"
    }

    # Generate report
    $report = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        test_type = "windows-logs-canary-monitoring"
        timeWindowMinutes = $TimeWindowMinutes
        canaryCount = $canaryCount
        earliestTimestamp = $earliestTs
        latestTimestamp = $latestTs
        alertThreshold = $AlertThreshold
        status = "healthy"
        alerts = @()
    }

    # Check for alerts
    if ($canaryCount -eq 0) {
        $alertMsg = "CRITICAL: No Windows logs canary entries found in last $TimeWindowMinutes minutes"
        Write-Error $alertMsg
        $report.status = "critical"
        $report.alerts += $alertMsg
        
        # Generate detailed diagnostic query
        $diagQuery = @"
SELECT 
    count(*) as total_logs,
    countIf(attributes_string['dataset'] = 'windows') as windows_event_logs,
    countIf(body LIKE '%canary%') as all_canary_logs,
    countIf(attributes_string['dataset'] = 'windows' AND body LIKE '%canary%') as windows_canary_logs,
    min(fromUnixTimestamp64Nano(timestamp)) as oldest_log,
    max(fromUnixTimestamp64Nano(timestamp)) as newest_log
FROM $LogTable 
WHERE timestamp > now() - INTERVAL $TimeWindowMinutes MINUTE
"@
        
        Write-Warning "Running diagnostic query..."
        $diagResult = docker exec $ClickHouseContainer clickhouse-client --query $diagQuery
        Write-Warning "Diagnostic: $diagResult"
        
    } elseif ($canaryCount -lt $AlertThreshold) {
        $alertMsg = "WARNING: Only $canaryCount Windows logs canary entries found (threshold: $AlertThreshold)"
        Write-Warning $alertMsg
        $report.status = "warning"
        $report.alerts += $alertMsg
        
    } else {
        Write-Success "Windows logs canary ingestion healthy: $canaryCount entries (above threshold)"
    }

    # Save report
    $reportFile = Join-Path $ArtifactsDir "windows-logs-canary-monitor-$Timestamp.json"
    $report | ConvertTo-Json -Depth 3 | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Info "Report saved to: $reportFile"

    # Return appropriate exit code
    if ($report.status -eq "critical") {
        exit 2
    } elseif ($report.status -eq "warning") {
        exit 1
    } else {
        exit 0
    }

} catch {
    $errorMsg = "Windows logs canary monitoring failed: $($_.Exception.Message)"
    Write-Error $errorMsg
    
    # Save error report
    $errorReport = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        test_type = "windows-logs-canary-monitoring"
        error = $errorMsg
        status = "error"
    }
    $errorFile = Join-Path $ArtifactsDir "windows-logs-canary-monitor-error-$Timestamp.json"
    $errorReport | ConvertTo-Json | Out-File -FilePath $errorFile -Encoding UTF8
    
    exit 3
}
