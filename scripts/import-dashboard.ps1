# Import SigNoz Dashboard Script
# Imports the OTel latency monitoring dashboard configuration

param(
    [string]$DashboardFile = "artifacts/signoz-dashboard-config.json",
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$ApplyMode
)

Write-Host "=== Import SigNoz Dashboard ===" -ForegroundColor Green
Write-Host "Dashboard file: $DashboardFile" -ForegroundColor Yellow
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor Yellow

# Check if dashboard file exists
if (-not (Test-Path $DashboardFile)) {
    Write-Error "Dashboard file not found: $DashboardFile"
    exit 1
}

# Check if SigNoz is reachable
Write-Host "Checking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$SigNozUrl/api/health" -Method GET -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "SigNoz is reachable" -ForegroundColor Green
    } else {
        Write-Warning "SigNoz returned status code: $($response.StatusCode)"
    }
} catch {
    Write-Warning "Cannot reach SigNoz at $SigNozUrl. Please ensure SigNoz is running."
    Write-Host "You can manually import the dashboard by:" -ForegroundColor Cyan
    Write-Host "1. Open SigNoz UI at $SigNozUrl" -ForegroundColor Cyan
    Write-Host "2. Go to Dashboards → Import" -ForegroundColor Cyan
    Write-Host "3. Upload the file: $DashboardFile" -ForegroundColor Cyan
    exit 0
}

# Read dashboard configuration
$completeConfig = Get-Content $DashboardFile -Raw | ConvertFrom-Json

# Handle both old and new format
if ($completeConfig.dashboard) {
    $dashboardConfig = $completeConfig.dashboard
    $alertsConfig = $completeConfig.alerts
    $savedSearchesConfig = $completeConfig.savedSearches
    $metadata = $completeConfig.metadata
} else {
    $dashboardConfig = $completeConfig
    $alertsConfig = @()
    $savedSearchesConfig = @()
    $metadata = @{}
}

Write-Host "Dashboard: $($dashboardConfig.name)" -ForegroundColor Green
Write-Host "Description: $($dashboardConfig.description)" -ForegroundColor White
Write-Host "Panels: $($dashboardConfig.panels.Count)" -ForegroundColor White
Write-Host "Alerts: $($alertsConfig.Count)" -ForegroundColor White
Write-Host "Saved Searches: $($savedSearchesConfig.Count)" -ForegroundColor White

if ($metadata.exported) {
    Write-Host "Exported: $($metadata.exported)" -ForegroundColor Gray
}

# Display dashboard panels
Write-Host "`nDashboard Panels:" -ForegroundColor Yellow
foreach ($panel in $dashboardConfig.panels) {
    Write-Host "  - $($panel.title) ($($panel.type))" -ForegroundColor White
}

# Display alerts
if ($alertsConfig.Count -gt 0) {
    Write-Host "`nAlerts:" -ForegroundColor Yellow
    foreach ($alert in $alertsConfig) {
        Write-Host "  - $($alert.name) ($($alert.severity))" -ForegroundColor White
        Write-Host "    Query: $($alert.query)" -ForegroundColor Gray
    }
}

# Display saved searches
if ($savedSearchesConfig.Count -gt 0) {
    Write-Host "`nSaved Searches:" -ForegroundColor Yellow
    foreach ($search in $savedSearchesConfig) {
        Write-Host "  - $($search.name)" -ForegroundColor White
        Write-Host "    Query: $($search.query)" -ForegroundColor Gray
    }
}

if ($ApplyMode) {
    Write-Host "`n=== Apply Mode: Automated Import ===" -ForegroundColor Green
    
    # In apply mode, we provide detailed instructions for manual import
    # since SigNoz doesn't have a public API for dashboard import
    Write-Host "Since SigNoz doesn't support automated dashboard import via API," -ForegroundColor Yellow
    Write-Host "please follow these steps to complete the import:" -ForegroundColor Yellow
    
    Write-Host "`n1. Dashboard Import:" -ForegroundColor Cyan
    Write-Host "   • Open SigNoz UI: $SigNozUrl" -ForegroundColor White
    Write-Host "   • Go to Dashboards → Import" -ForegroundColor White
    Write-Host "   • Upload: $DashboardFile" -ForegroundColor White
    Write-Host "   • Configure data sources if needed" -ForegroundColor White
    Write-Host "   • Save dashboard" -ForegroundColor White
    
    if ($alertsConfig.Count -gt 0) {
        Write-Host "`n2. Configure Alerts:" -ForegroundColor Cyan
        Write-Host "   • Go to Alerts → New Alert" -ForegroundColor White
        foreach ($alert in $alertsConfig) {
            Write-Host "   • Alert: $($alert.name)" -ForegroundColor White
            Write-Host "     Query: $($alert.query)" -ForegroundColor Gray
            Write-Host "     Severity: $($alert.severity)" -ForegroundColor Gray
            Write-Host "     Evaluation: $($alert.evaluationWindow)" -ForegroundColor Gray
        }
    }
    
    if ($savedSearchesConfig.Count -gt 0) {
        Write-Host "`n3. Create Saved Searches:" -ForegroundColor Cyan
        Write-Host "   • Go to Logs → Saved Searches → New" -ForegroundColor White
        foreach ($search in $savedSearchesConfig) {
            Write-Host "   • Search: $($search.name)" -ForegroundColor White
            Write-Host "     Query: $($search.query)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n4. Test Dashboard:" -ForegroundColor Cyan
    Write-Host "   • Verify panels are displaying data" -ForegroundColor White
    Write-Host "   • Check time range: $($dashboardConfig.time.from) to $($dashboardConfig.time.to)" -ForegroundColor White
    Write-Host "   • Confirm refresh interval: $($dashboardConfig.refresh)" -ForegroundColor White
    
} else {
    Write-Host "`n=== Manual Import Instructions ===" -ForegroundColor Green
    Write-Host "To import this dashboard:" -ForegroundColor Yellow
    Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor Cyan
    Write-Host "2. Navigate to: Dashboards → Import" -ForegroundColor Cyan
    Write-Host "3. Upload file: $DashboardFile" -ForegroundColor Cyan
    Write-Host "4. Configure data sources if needed" -ForegroundColor Cyan
    Write-Host "5. Save dashboard" -ForegroundColor Cyan
}

Write-Host "`n=== Dashboard Configuration ===" -ForegroundColor Green
Write-Host "Time Range: $($dashboardConfig.time.from) to $($dashboardConfig.time.to)" -ForegroundColor White
Write-Host "Refresh Interval: $($dashboardConfig.refresh)" -ForegroundColor White
Write-Host "Tags: $($dashboardConfig.tags -join ', ')" -ForegroundColor White

if ($dashboardConfig.annotations -and $dashboardConfig.annotations.list) {
    Write-Host "`nAnnotations:" -ForegroundColor Yellow
    foreach ($annotation in $dashboardConfig.annotations.list) {
        Write-Host "  - $($annotation.name): $($annotation.titleFormat)" -ForegroundColor White
    }
}

if ($metadata.baselineFile) {
    Write-Host "`nBaseline Source: $($metadata.baselineFile)" -ForegroundColor Gray
}

Write-Host "`nDashboard import instructions completed!" -ForegroundColor Green
Write-Host "Dashboard file: $DashboardFile" -ForegroundColor Cyan

if ($ApplyMode) {
    Write-Host "`n=== Apply Mode Summary ===" -ForegroundColor Green
    Write-Host "✓ Dashboard configuration exported" -ForegroundColor White
    Write-Host "✓ Import instructions provided" -ForegroundColor White
    Write-Host "✓ Alerts configuration ready" -ForegroundColor White
    Write-Host "✓ Saved searches configuration ready" -ForegroundColor White
    Write-Host "`nNext: Follow the manual import steps above" -ForegroundColor Yellow
}
