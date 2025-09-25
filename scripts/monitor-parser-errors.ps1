#Requires -Version 7.0

<#
.SYNOPSIS
    Monitor JSON parser errors to detect regressions and long-term noise
.DESCRIPTION
    Checks SigNoz for JSON parser errors and logs findings for trend analysis.
    Designed to run as a scheduled task every 15 minutes.
.EXAMPLE
    pwsh -File scripts/monitor-parser-errors.ps1
#>

param(
    [int]$Minutes = 15,
    [string]$LogPath = "artifacts/parser-monitoring.log"
)

function Write-MonitoringLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    Write-Host $LogEntry
    $LogEntry | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function Test-ParserErrors {
    param([int]$Minutes)
    
    try {
        Write-MonitoringLog "Checking for parser errors in last $Minutes minutes"
        
        $Query = @"
SELECT count() as error_count, 
       countIf(severity_text = 'ERROR') as error_severity_count
FROM signoz_logs.logs_v2 
WHERE match(body, 'expected .* character .* for .* map .* value') 
AND timestamp > toUnixTimestamp(now()) * 1000000000 - ($Minutes * 60 * 1000000000)
"@
        
        $Result = docker exec signoz-clickhouse clickhouse-client --query $Query 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $Result) {
            $Counts = $Result -split '\s+'
            $ErrorCount = [int]$Counts[0]
            $SeverityCount = [int]$Counts[1]
            
            if ($ErrorCount -eq 0) {
                Write-MonitoringLog "✅ No parser errors detected in last $Minutes minutes" "SUCCESS"
                return $true
            }
            else {
                Write-MonitoringLog "⚠️  Found $ErrorCount parser errors ($SeverityCount ERROR severity) in last $Minutes minutes" "WARNING"
                
                # Get sample errors for analysis
                $SampleQuery = @"
SELECT timestamp, body, attributes_string 
FROM signoz_logs.logs_v2 
WHERE match(body, 'expected .* character .* for .* map .* value') 
AND timestamp > toUnixTimestamp(now()) * 1000000000 - ($Minutes * 60 * 1000000000)
ORDER BY timestamp DESC LIMIT 3
"@
                
                $SampleErrors = docker exec signoz-clickhouse clickhouse-client --query $SampleQuery 2>$null
                Write-MonitoringLog "Sample errors: $SampleErrors" "DETAIL"
                
                return $false
            }
        }
        else {
            Write-MonitoringLog "❌ Failed to query SigNoz: $Result" "ERROR"
            return $false
        }
    }
    catch {
        Write-MonitoringLog "❌ Exception during parser error check: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-LogThroughput {
    try {
        Write-MonitoringLog "Checking log processing throughput"
        
        $Query = @"
SELECT count() as total_logs, 
       countIf(severity_text = 'ERROR') as total_errors,
       countIf(attributes_string['dataset'] IN ('windows', 'ecrr-canary')) as dataset_logs
FROM signoz_logs.logs_v2 
WHERE timestamp > toUnixTimestamp(now()) * 1000000000 - ($Minutes * 60 * 1000000000)
"@
        
        $Result = docker exec signoz-clickhouse clickhouse-client --query $Query 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $Result) {
            $Counts = $Result -split '\s+'
            $TotalLogs = [int]$Counts[0]
            $TotalErrors = [int]$Counts[1]
            $DatasetLogs = [int]$Counts[2]
            
            $ErrorRate = if ($TotalLogs -gt 0) { ($TotalErrors / $TotalLogs) * 100 } else { 0 }
            $SuccessRate = 100 - $ErrorRate
            
            Write-MonitoringLog "📊 Throughput: $TotalLogs total logs, $DatasetLogs dataset-tagged, $SuccessRate% success rate" "INFO"
            
            return $SuccessRate -gt 99
        }
        else {
            Write-MonitoringLog "❌ Failed to query throughput: $Result" "ERROR"
            return $false
        }
    }
    catch {
        Write-MonitoringLog "❌ Exception during throughput check: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-MonitoringLog "Starting JSON parser error monitoring (last $Minutes minutes)"

$ParserHealthy = Test-ParserErrors -Minutes $Minutes
$ThroughputHealthy = Test-LogThroughput

if ($ParserHealthy -and $ThroughputHealthy) {
    Write-MonitoringLog "✅ Parser monitoring: All systems healthy" "SUCCESS"
    exit 0
}
else {
    Write-MonitoringLog "⚠️  Parser monitoring: Issues detected - manual review recommended" "WARNING"
    exit 1
}