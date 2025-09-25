[CmdletBinding()]
param(
    [switch]$CheckSigNoz,
    [switch]$RunTest
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[Verify] $Message" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "[✓] $Message" -ForegroundColor Green }
function Write-Warning { param([string]$Message) Write-Host "[!] $Message" -ForegroundColor Yellow }
function Write-Error { param([string]$Message) Write-Host "[✗] $Message" -ForegroundColor Red }

Write-Info "Verifying disk monitoring setup..."

# Check if monitoring script exists and works
Write-Info "Testing disk monitoring script..."
try {
    $result = pwsh -File scripts/monitor-disk-usage.ps1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Disk monitoring script working correctly"
    } else {
        Write-Error "Disk monitoring script failed with exit code $LASTEXITCODE"
    }
} catch {
    Write-Error "Failed to run disk monitoring script: $($_.Exception.Message)"
}

# Check log file generation
Write-Info "Checking log file generation..."
$logFile = "C:/logs/disk-monitor/disk-usage.log"
if (Test-Path $logFile) {
    $logContent = Get-Content $logFile -Tail 1 | ConvertFrom-Json
    if ($logContent.dataset -eq "disk-monitor") {
        Write-Success "Log file generated with correct dataset tag"
        Write-Info "Latest entry: Drive $($logContent.drive) usage $($logContent.percent_used)% (status: $($logContent.status))"
    } else {
        Write-Error "Log file missing correct dataset tag"
    }
} else {
    Write-Error "Log file not found at $logFile"
}

# Check scheduled task
Write-Info "Checking scheduled task..."
$task = Get-ScheduledTask -TaskName 'DiskUsageMonitor' -ErrorAction SilentlyContinue
if ($task) {
    Write-Success "Scheduled task 'DiskUsageMonitor' exists"
    Write-Info "Task state: $($task.State)"
} else {
    Write-Warning "Scheduled task 'DiskUsageMonitor' not found - run setup-disk-monitoring.ps1"
}

# Check event log entries
Write-Info "Checking Windows Event Log integration..."
$events = Get-WinEvent -FilterHashtable @{ LogName = 'Application'; ProviderName = 'DiskUsageMonitor'; StartTime = (Get-Date).AddMinutes(-10) } -ErrorAction SilentlyContinue
if ($events) {
    Write-Success "Event log entries found: $($events.Count) recent entries"
} else {
    Write-Warning "No recent event log entries found"
}

# Check alert pack
Write-Info "Checking alert pack generation..."
$alertFile = "artifacts/signoz-disk-alerts.json"
if (Test-Path $alertFile) {
    $alertContent = Get-Content $alertFile | ConvertFrom-Json
    if ($alertContent.alerts.Count -eq 2) {
        Write-Success "Alert pack generated with 2 alerts"
        foreach ($alert in $alertContent.alerts) {
            Write-Info "- $($alert.name) [$($alert.severity)]"
        }
    } else {
        Write-Error "Alert pack missing expected 2 alerts"
    }
} else {
    Write-Error "Alert pack not found at $alertFile"
}

# Check SigNoz connectivity (optional)
if ($CheckSigNoz) {
    Write-Info "Checking SigNoz connectivity..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8080" -Method GET -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Success "SigNoz UI accessible at http://localhost:8080"
        }
    } catch {
        Write-Warning "SigNoz UI not accessible - ensure SigNoz is running"
        Write-Info "Start with: docker-compose -f docker-compose.yml up -d"
    }
}

# Run test with different thresholds if requested
if ($RunTest) {
    Write-Info "Running test with modified thresholds..."
    try {
        pwsh -File scripts/monitor-disk-usage.ps1 -WarningPercent 60 -CriticalPercent 70
        Write-Success "Test run completed - check logs for modified thresholds"
    } catch {
        Write-Error "Test run failed: $($_.Exception.Message)"
    }
}

Write-Info "Verification complete!"
Write-Info ""
Write-Info "Next steps:"
Write-Info "1. Ensure SigNoz is running: docker-compose -f docker-compose.yml up -d"
Write-Info "2. Open SigNoz UI: http://localhost:8080"
Write-Info "3. Import alerts: Alerts -> Import JSON -> upload artifacts/signoz-disk-alerts.json"
Write-Info "4. Create dashboard: Use queries from docs/QUERY_RECIPES.md"
Write-Info "5. View logs: Logs -> filter: attributes.dataset = 'disk-monitor'"
Write-Info ""
Write-Info "Setup guide: docs/SIGNOZ_DISK_MONITORING_SETUP.md"
