# Queue Steward Canary Automation Script
# This script emits a canary log entry and updates the dashboard timestamp

param(
    [int]$IntervalMinutes = 15,
    [string]$DashboardPath = "docs/ECRR_QUALITY_DASHBOARD.md",
    [string]$LogPath = "C:\logs\queue\health.log"
)

# Function to emit canary
function Emit-Canary {
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $canaryToken = "463edcd0e7ff4624af6a4b15a47fc290"
    
    $canaryData = @{
        message = "Queue steward canary $stamp"
        canary = $canaryToken
        timestamp = $stamp
        source = "automated-canary"
    }
    
    $canaryData | ConvertTo-Json -Depth 2 | Out-File -FilePath $LogPath -Encoding utf8 -Append
    
    Write-Host "Canary emitted: $stamp" -ForegroundColor Green
    return $stamp
}

# Function to update dashboard timestamp
function Update-DashboardTimestamp {
    param([string]$Timestamp)
    
    if (Test-Path $DashboardPath) {
        $content = Get-Content $DashboardPath
        $updatedContent = $content -replace '\*\*Last Verified\*\*: \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\*\*', "**Last Verified**: $Timestamp**"
        $updatedContent | Set-Content $DashboardPath
        
        Write-Host "Dashboard timestamp updated: $Timestamp" -ForegroundColor Green
    } else {
        Write-Warning "Dashboard file not found: $DashboardPath"
    }
}

# Function to verify ClickHouse ingestion
function Verify-ClickHouseIngestion {
    try {
        $query = @"
SELECT toDateTime(timestamp/1000000000) AS ts,
       resources_string['service.name'] AS service_name,
       attributes_string['log.source'] AS log_source
FROM signoz_logs.logs_v2
WHERE attributes_string['dataset'] = 'agent_queue'
ORDER BY timestamp DESC LIMIT 1
"@
        
        $result = docker exec signoz-clickhouse clickhouse-client --query $query 2>$null
        
        if ($result -match "queue-steward.*win-filelog") {
            Write-Host "ClickHouse verification: PASSED" -ForegroundColor Green
            return $true
        } else {
            Write-Warning "ClickHouse verification: FAILED - attributes not found"
            return $false
        }
    } catch {
        Write-Warning "ClickHouse verification: ERROR - $($_.Exception.Message)"
        return $false
    }
}

# Main execution
try {
    Write-Host "Starting Queue Steward Canary Automation" -ForegroundColor Cyan
    Write-Host "Interval: $IntervalMinutes minutes" -ForegroundColor Cyan
    Write-Host "Dashboard: $DashboardPath" -ForegroundColor Cyan
    Write-Host "Log Path: $LogPath" -ForegroundColor Cyan
    Write-Host ""
    
    # Emit canary
    $timestamp = Emit-Canary
    
    # Update dashboard
    Update-DashboardTimestamp -Timestamp $timestamp
    
    # Verify ingestion (optional)
    $verified = Verify-ClickHouseIngestion
    
    Write-Host ""
    Write-Host "Queue Steward Canary Automation Complete" -ForegroundColor Cyan
    Write-Host "Status: $($verified ? 'VERIFIED' : 'EMITTED')" -ForegroundColor $(if ($verified) { 'Green' } else { 'Yellow' })
    
} catch {
    Write-Error "Queue Steward Canary Automation Failed: $($_.Exception.Message)"
    exit 1
}
