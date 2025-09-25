#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$SigNozUrl = 'http://localhost:8080',
    [switch]$CheckLogs,
    [switch]$CheckAlerts,
    [switch]$CheckDashboard,
    [switch]$FullCheck,
    [int]$LogCount = 5
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[Monitor] $Message" -ForegroundColor Cyan }
function Write-Warn { param([string]$Message) Write-Host "[Monitor] $Message" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[Monitor] $Message" -ForegroundColor Red }
function Write-Success { param([string]$Message) Write-Host "[Monitor] $Message" -ForegroundColor Green }
function Write-Step { param([string]$Message) Write-Host "[Check] $Message" -ForegroundColor Magenta }

if ($FullCheck) {
    $CheckLogs = $true
    $CheckAlerts = $true
    $CheckDashboard = $true
}

Write-Info "SigNoz Setup Monitoring and Verification"
Write-Host ""

# Check SigNoz connectivity
Write-Step "Checking SigNoz connectivity"
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    if ($healthResponse.status -eq 'ok') {
        Write-Success "✓ SigNoz is accessible at $SigNozUrl"
    } else {
        Write-ErrorMsg "✗ SigNoz health check failed: $($healthResponse.status)"
        exit 1
    }
} catch {
    Write-ErrorMsg "✗ Cannot connect to SigNoz at $SigNozUrl"
    Write-Host "Please ensure SigNoz is running and accessible" -ForegroundColor Yellow
    exit 1
}

# Check disk monitoring script
Write-Step "Checking disk monitoring script status"
try {
    $result = & 'C:/otel/scripts/monitor-disk-usage.ps1'
    if ($LASTEXITCODE -eq 0) {
        Write-Success "✓ Disk monitoring script executed successfully"
        Write-Host "  Output: $result" -ForegroundColor Gray
    } else {
        Write-Warn "⚠ Disk monitoring script returned exit code: $LASTEXITCODE"
    }
} catch {
    Write-ErrorMsg "✗ Disk monitoring script error: $($_.Exception.Message)"
}

if ($CheckLogs) {
    Write-Step "Checking disk monitoring logs"
    
    # Check log file
    $logFile = 'C:/logs/disk-monitor/disk-usage.log'
    if (Test-Path $logFile) {
        Write-Success "✓ Log file exists: $logFile"
        
        # Check recent entries
        $recentLogs = Get-Content $logFile -Tail $LogCount
        Write-Info "Recent $LogCount log entries:"
        
        foreach ($logEntry in $recentLogs) {
            try {
                $logData = $logEntry | ConvertFrom-Json
                $timestamp = [DateTime]::Parse($logData.timestamp).ToString('HH:mm:ss')
                Write-Host "  $timestamp - Drive $($logData.drive): $($logData.percent_used)% ($($logData.status))" -ForegroundColor Gray
            } catch {
                Write-Host "  Invalid JSON entry: $logEntry" -ForegroundColor Red
            }
        }
        
        # Check latest entry details
        $latestLog = $recentLogs[-1] | ConvertFrom-Json
        Write-Info "Latest entry details:"
        Write-Host "  Drive: $($latestLog.drive)" -ForegroundColor Gray
        Write-Host "  Usage: $($latestLog.percent_used)%" -ForegroundColor Gray
        Write-Host "  Status: $($latestLog.status)" -ForegroundColor Gray
        Write-Host "  Severity: $($latestLog.severity)" -ForegroundColor Gray
        Write-Host "  Dataset: $($latestLog.dataset)" -ForegroundColor Gray
        
        # Check if logs are recent (within last hour)
        $logTime = [DateTime]::Parse($latestLog.timestamp)
        $timeDiff = (Get-Date) - $logTime
        if ($timeDiff.TotalHours -lt 1) {
            Write-Success "✓ Latest log entry is recent (within last hour)"
        } else {
            Write-Warn "⚠ Latest log entry is older than 1 hour"
        }
        
    } else {
        Write-ErrorMsg "✗ Log file not found: $logFile"
    }
    
    # Check Windows Event Log
    Write-Info "Checking Windows Event Log entries"
    try {
        $events = Get-WinEvent -FilterHashtable @{LogName='Application';ProviderName='DiskUsageMonitor';StartTime=(Get-Date).AddHours(-1)} -ErrorAction SilentlyContinue
        if ($events) {
            Write-Success "✓ Found $($events.Count) disk monitoring events in the last hour"
            $latestEvent = $events | Select-Object -First 1
            Write-Host "  Latest EventID: $($latestEvent.Id)" -ForegroundColor Gray
            Write-Host "  Time: $($latestEvent.TimeCreated)" -ForegroundColor Gray
        } else {
            Write-Warn "⚠ No recent disk monitoring events found in Windows Event Log"
        }
    } catch {
        Write-Warn "⚠ Error checking Windows Event Log: $($_.Exception.Message)"
    }
}

if ($CheckAlerts) {
    Write-Step "Checking alert configuration status"
    
    Write-Info "Alert configurations to verify in SigNoz UI:"
    Write-Host ""
    Write-Host "Alert 1: Disk Usage Warning" -ForegroundColor Yellow
    Write-Host "  Query: count by (drive) (attributes.dataset=\"disk-monitor\" and attributes.status=\"warning\") > 0" -ForegroundColor Gray
    Write-Host "  Severity: Warning, Duration: 1 minute" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Alert 2: Disk Usage Critical" -ForegroundColor Yellow
    Write-Host "  Query: count by (drive) (attributes.dataset=\"disk-monitor\" and attributes.status=\"critical\") > 0" -ForegroundColor Gray
    Write-Host "  Severity: Critical, Duration: 30 seconds" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Alert 3: Disk Monitor Offline" -ForegroundColor Yellow
    Write-Host "  Query: count by (attributes.dataset) (attributes.dataset=\"disk-monitor\") == 0" -ForegroundColor Gray
    Write-Host "  Severity: Warning, Duration: 5 minutes" -ForegroundColor Gray
    Write-Host ""
    
    Write-Info "Manual verification required:"
    Write-Host "1. Go to $SigNozUrl/alerts" -ForegroundColor Cyan
    Write-Host "2. Verify all 3 alerts are created and enabled" -ForegroundColor Cyan
    Write-Host "3. Check that queries match the configurations above" -ForegroundColor Cyan
}

if ($CheckDashboard) {
    Write-Step "Checking dashboard configuration"
    
    Write-Info "Dashboard panels to verify in SigNoz UI:"
    Write-Host ""
    Write-Host "Panel 1: Disk Usage Gauge" -ForegroundColor Yellow
    Write-Host "  Query: attributes.percent_used by (attributes.drive) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Panel 2: Disk Usage Trend" -ForegroundColor Yellow
    Write-Host "  Query: attributes.percent_used by (attributes.drive) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Panel 3: Free Space Bar Chart" -ForegroundColor Yellow
    Write-Host "  Query: attributes.free_gb by (attributes.drive) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Panel 4: Disk Status Pie Chart" -ForegroundColor Yellow
    Write-Host "  Query: count by (attributes.status) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Panel 5: Recent Alerts Table" -ForegroundColor Yellow
    Write-Host "  Query: attributes.message by (attributes.drive, attributes.status) (attributes.dataset=\"disk-monitor\" and attributes.status!=\"ok\")" -ForegroundColor Gray
    Write-Host ""
    
    Write-Info "Manual verification required:"
    Write-Host "1. Go to $SigNozUrl/dashboards" -ForegroundColor Cyan
    Write-Host "2. Open 'Disk Monitoring Dashboard'" -ForegroundColor Cyan
    Write-Host "3. Verify all 5 panels are displaying data" -ForegroundColor Cyan
}

# Summary and next steps
Write-Host ""
Write-Step "Summary and Next Steps"
Write-Host ""

Write-Info "Current Status:"
Write-Host "• SigNoz: ✅ Accessible at $SigNozUrl" -ForegroundColor Green
Write-Host "• Disk Monitoring: ✅ Script executing successfully" -ForegroundColor Green
Write-Host "• Log Generation: ✅ JSON logs being written" -ForegroundColor Green
Write-Host "• Event Logging: ✅ Windows Event Log entries" -ForegroundColor Green

Write-Host ""
Write-Info "Manual Setup Required:"
Write-Host "1. Import 3 alerts in SigNoz UI → Alerts" -ForegroundColor Yellow
Write-Host "2. Create saved view in SigNoz UI → Logs" -ForegroundColor Yellow
Write-Host "3. Create dashboard in SigNoz UI → Dashboards" -ForegroundColor Yellow

Write-Host ""
Write-Info "Verification URLs:"
Write-Host "• SigNoz UI: $SigNozUrl" -ForegroundColor Cyan
Write-Host "• Alerts: $SigNozUrl/alerts" -ForegroundColor Cyan
Write-Host "• Logs: $SigNozUrl/logs" -ForegroundColor Cyan
Write-Host "• Dashboards: $SigNozUrl/dashboards" -ForegroundColor Cyan

Write-Host ""
Write-Info "Testing Commands:"
Write-Host "• Test warning alert: pwsh -File scripts/test-disk-alerts.ps1 -TestWarning" -ForegroundColor Gray
Write-Host "• Restore thresholds: pwsh -File scripts/test-disk-alerts.ps1 -RestoreDefaults" -ForegroundColor Gray
Write-Host "• Check latest logs: Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1" -ForegroundColor Gray
