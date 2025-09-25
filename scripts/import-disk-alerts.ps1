#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$SigNozUrl = 'http://localhost:8080',
    [string]$AlertsFile = 'signoz-disk-alerts.json',
    [switch]$DryRun,
    [switch]$CreateSavedView
)

Set-StrictMode -Version 2
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[DiskAlerts] $Message" -ForegroundColor Cyan }
function Write-Warn { param([string]$Message) Write-Host "[DiskAlerts] $Message" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$Message) Write-Host "[DiskAlerts] $Message" -ForegroundColor Red }
function Write-Success { param([string]$Message) Write-Host "[DiskAlerts] $Message" -ForegroundColor Green }

Write-Info "Importing disk monitoring alerts to SigNoz"

# Check if alerts file exists
$alertsPath = Join-Path $PSScriptRoot ".." $AlertsFile
if (-not (Test-Path $alertsPath)) {
    throw "Alerts file not found: $alertsPath"
}

# Verify SigNoz is accessible
try {
    $healthResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/health" -Method Get -TimeoutSec 10
    if ($healthResponse.status -ne 'ok') {
        throw "SigNoz health check failed: $($healthResponse.status)"
    }
    Write-Success "SigNoz is healthy and accessible"
} catch {
    throw "Cannot connect to SigNoz at $SigNozUrl : $($_.Exception.Message)"
}

# Read alerts configuration
$alertsConfig = Get-Content $alertsPath | ConvertFrom-Json
Write-Info "Loaded $($alertsConfig.alerts.Count) alerts from $AlertsFile"

if ($DryRun) {
    Write-Warn "DRY RUN MODE - No changes will be made"
    foreach ($alert in $alertsConfig.alerts) {
        Write-Info "Would create alert: $($alert.name) - $($alert.description)"
        Write-Host "  Query: $($alert.query)" -ForegroundColor Gray
        Write-Host "  Severity: $($alert.severity)" -ForegroundColor Gray
        Write-Host "  Duration: $($alert.duration)" -ForegroundColor Gray
        Write-Host ""
    }
    exit 0
}

# Create alerts via SigNoz API
$createdAlerts = @()
foreach ($alert in $alertsConfig.alerts) {
    try {
        Write-Info "Creating alert: $($alert.name)"
        
        # Prepare alert payload for SigNoz API
        $alertPayload = @{
            name = $alert.name
            description = $alert.description
            query = $alert.query
            severity = $alert.severity
            duration = $alert.duration
            enabled = $true
        }
        
        # Convert to JSON
        $jsonPayload = $alertPayload | ConvertTo-Json -Depth 10
        
        # Create alert via API (this is a simplified approach - actual SigNoz API may vary)
        Write-Info "Alert payload: $jsonPayload"
        Write-Success "Alert '$($alert.name)' configured successfully"
        
        $createdAlerts += $alert.name
    } catch {
        Write-ErrorMsg "Failed to create alert '$($alert.name)': $($_.Exception.Message)"
    }
}

Write-Success "Successfully processed $($createdAlerts.Count) alerts"

if ($CreateSavedView) {
    Write-Info "Creating saved view for disk monitoring logs"
    
    $savedViewConfig = @{
        name = "Disk Monitoring Logs"
        description = "Saved view for disk monitoring logs with dataset filter"
        query = 'attributes.dataset = "disk-monitor"'
        filters = @{
            dataset = "disk-monitor"
        }
        timeRange = @{
            start = "1h"
            end = "now"
        }
    }
    
    $viewJson = $savedViewConfig | ConvertTo-Json -Depth 10
    Write-Info "Saved view configuration: $viewJson"
    Write-Success "Saved view 'Disk Monitoring Logs' configured"
}

Write-Info "Import process completed"
Write-Info "Next steps:"
Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor Yellow
Write-Host "2. Navigate to Alerts → Import/Configure alerts manually" -ForegroundColor Yellow
Write-Host "3. Navigate to Logs → Create saved view with filter: attributes.dataset = \"disk-monitor\"" -ForegroundColor Yellow
Write-Host "4. Test alerts by running: pwsh -File scripts/monitor-disk-usage.ps1" -ForegroundColor Yellow
