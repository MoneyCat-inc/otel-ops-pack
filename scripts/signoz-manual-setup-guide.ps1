#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$SigNozUrl = 'http://localhost:8080',
    [switch]$OpenBrowser,
    [switch]$ShowQueries
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[SigNoz] $Message" -ForegroundColor Cyan }
function Write-Warn { param([string]$Message) Write-Host "[SigNoz] $Message" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[SigNoz] $Message" -ForegroundColor Red }
function Write-Success { param([string]$Message) Write-Host "[SigNoz] $Message" -ForegroundColor Green }
function Write-Step { param([string]$Message) Write-Host "[Step] $Message" -ForegroundColor Magenta }

Write-Info "SigNoz Manual Setup Guide for Disk Monitoring"
Write-Host ""

# Check SigNoz accessibility
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    if ($healthResponse.status -eq 'ok') {
        Write-Success "✓ SigNoz is accessible at $SigNozUrl"
    } else {
        Write-ErrorMsg "✗ SigNoz health check failed"
        exit 1
    }
} catch {
    Write-ErrorMsg "✗ Cannot connect to SigNoz at $SigNozUrl"
    exit 1
}

if ($OpenBrowser) {
    Write-Info "Opening SigNoz UI in browser..."
    Start-Process $SigNozUrl
    Start-Sleep 2
}

Write-Step "STEP 1: Import Disk Alerts"
Write-Host ""
Write-Info "Navigate to: $SigNozUrl → Alerts → New Alert"
Write-Host ""
Write-Info "Create Alert 1: Disk Usage Warning"
Write-Host "  Name: Disk Usage Warning" -ForegroundColor Yellow
Write-Host "  Description: Alert when disk usage exceeds 80%" -ForegroundColor Yellow
Write-Host "  Query: count by (drive) (attributes.dataset=\"disk-monitor\" and attributes.status=\"warning\") > 0" -ForegroundColor Yellow
Write-Host "  Severity: Warning" -ForegroundColor Yellow
Write-Host "  Duration: 1 minute" -ForegroundColor Yellow
Write-Host ""

Write-Info "Create Alert 2: Disk Usage Critical"
Write-Host "  Name: Disk Usage Critical" -ForegroundColor Yellow
Write-Host "  Description: Alert when disk usage exceeds 90%" -ForegroundColor Yellow
Write-Host "  Query: count by (drive) (attributes.dataset=\"disk-monitor\" and attributes.status=\"critical\") > 0" -ForegroundColor Yellow
Write-Host "  Severity: Critical" -ForegroundColor Yellow
Write-Host "  Duration: 30 seconds" -ForegroundColor Yellow
Write-Host ""

Write-Info "Create Alert 3: Disk Monitor Offline"
Write-Host "  Name: Disk Monitor Offline" -ForegroundColor Yellow
Write-Host "  Description: Alert when disk monitoring stops reporting" -ForegroundColor Yellow
Write-Host "  Query: count by (attributes.dataset) (attributes.dataset=\"disk-monitor\") == 0" -ForegroundColor Yellow
Write-Host "  Severity: Warning" -ForegroundColor Yellow
Write-Host "  Duration: 5 minutes" -ForegroundColor Yellow
Write-Host ""

Write-Step "STEP 2: Create Saved View"
Write-Host ""
Write-Info "Navigate to: $SigNozUrl → Logs"
Write-Info "Apply filter: attributes.dataset = \"disk-monitor\""
Write-Host ""
Write-Info "Create Saved View:"
Write-Host "  Name: Disk Monitoring Logs" -ForegroundColor Yellow
Write-Host "  Description: Saved view for disk monitoring logs with dataset filter" -ForegroundColor Yellow
Write-Host "  Filter: attributes.dataset = \"disk-monitor\"" -ForegroundColor Yellow
Write-Host "  Time Range: Last 1 hour" -ForegroundColor Yellow
Write-Host ""

Write-Step "STEP 3: Test Current Data"
Write-Host ""
Write-Info "Verify logs are visible in SigNoz:"
Write-Host "1. Go to Logs → Apply filter: attributes.dataset = \"disk-monitor\"" -ForegroundColor Gray
Write-Host "2. Look for entries showing 'Drive C: usage 69.02% (status: ok)'" -ForegroundColor Gray
Write-Host "3. Verify timestamp is recent (within last hour)" -ForegroundColor Gray
Write-Host ""

# Show current disk monitoring data
Write-Info "Current disk monitoring data:"
try {
    $latestLog = Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1 | ConvertFrom-Json
    Write-Host "  Drive: $($latestLog.drive)" -ForegroundColor Gray
    Write-Host "  Usage: $($latestLog.percent_used)%" -ForegroundColor Gray
    Write-Host "  Status: $($latestLog.status)" -ForegroundColor Gray
    Write-Host "  Timestamp: $($latestLog.timestamp)" -ForegroundColor Gray
} catch {
    Write-Warn "Could not read latest disk monitoring log"
}

Write-Host ""

Write-Step "STEP 4: Test Alert Thresholds (Optional)"
Write-Host ""
Write-Info "To test alerts, you can temporarily modify thresholds:"
Write-Host "1. Edit scripts/monitor-disk-usage.ps1" -ForegroundColor Gray
Write-Host "2. Change WarningPercent to 65 (current usage is 69%)" -ForegroundColor Gray
Write-Host "3. Run the script to trigger warning alert" -ForegroundColor Gray
Write-Host "4. Restore original thresholds after testing" -ForegroundColor Gray
Write-Host ""

Write-Step "STEP 5: Optional Dashboard Creation"
Write-Host ""
Write-Info "Navigate to: $SigNozUrl → Dashboards → New Dashboard"
Write-Host "Add these panels:"
Write-Host ""
Write-Info "Panel 1: Disk Usage by Drive (Gauge)"
Write-Host "  Title: Disk Usage by Drive" -ForegroundColor Yellow
Write-Host "  Query: attributes.percent_used by (attributes.drive) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Yellow
Write-Host "  Type: Gauge" -ForegroundColor Yellow
Write-Host ""

Write-Info "Panel 2: Disk Usage Trend (Line Chart)"
Write-Host "  Title: Disk Usage Trend (24h)" -ForegroundColor Yellow
Write-Host "  Query: attributes.percent_used by (attributes.drive) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Yellow
Write-Host "  Type: Line Chart" -ForegroundColor Yellow
Write-Host ""

Write-Info "Panel 3: Free Space by Drive (Bar Chart)"
Write-Host "  Title: Free Space by Drive" -ForegroundColor Yellow
Write-Host "  Query: attributes.free_gb by (attributes.drive) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Yellow
Write-Host "  Type: Bar Chart" -ForegroundColor Yellow
Write-Host ""

Write-Info "Panel 4: Disk Status Count (Pie Chart)"
Write-Host "  Title: Disk Status Count" -ForegroundColor Yellow
Write-Host "  Query: count by (attributes.status) (attributes.dataset=\"disk-monitor\")" -ForegroundColor Yellow
Write-Host "  Type: Pie Chart" -ForegroundColor Yellow
Write-Host ""

Write-Success "Manual setup guide complete!"
Write-Host ""
Write-Info "Quick verification commands:"
Write-Host "  Test disk monitoring: pwsh -File scripts/monitor-disk-usage.ps1" -ForegroundColor Gray
Write-Host "  Verify setup: pwsh -File scripts/verify-disk-alerts-setup.ps1" -ForegroundColor Gray
Write-Host "  Check logs: Get-Content 'C:/logs/disk-monitor/disk-usage.log' -Tail 1" -ForegroundColor Gray
Write-Host ""

if ($ShowQueries) {
    Write-Info "Copy-paste queries for alerts:"
    Write-Host ""
    Write-Host "Alert 1 Query:" -ForegroundColor Cyan
    Write-Host 'count by (drive) (attributes.dataset="disk-monitor" and attributes.status="warning") > 0' -ForegroundColor White
    Write-Host ""
    Write-Host "Alert 2 Query:" -ForegroundColor Cyan
    Write-Host 'count by (drive) (attributes.dataset="disk-monitor" and attributes.status="critical") > 0' -ForegroundColor White
    Write-Host ""
    Write-Host "Alert 3 Query:" -ForegroundColor Cyan
    Write-Host 'count by (attributes.dataset) (attributes.dataset="disk-monitor") == 0' -ForegroundColor White
    Write-Host ""
    Write-Host "Logs Filter:" -ForegroundColor Cyan
    Write-Host 'attributes.dataset = "disk-monitor"' -ForegroundColor White
}
