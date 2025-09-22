# Import SigNoz Dashboard Script
# Imports the OTel Queue Pressure dashboard configuration

param(
    [string]$DashboardFile = "artifacts/signoz-dashboard-config.json",
    [string]$SigNozUrl = "http://localhost:8080"
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
$dashboardConfig = Get-Content $DashboardFile -Raw | ConvertFrom-Json

Write-Host "Dashboard: $($dashboardConfig.name)" -ForegroundColor Green
Write-Host "Description: $($dashboardConfig.description)" -ForegroundColor White
Write-Host "Panels: $($dashboardConfig.panels.Count)" -ForegroundColor White

# Display dashboard panels
Write-Host "`nDashboard Panels:" -ForegroundColor Yellow
foreach ($panel in $dashboardConfig.panels) {
    Write-Host "  - $($panel.title) ($($panel.type))" -ForegroundColor White
}

Write-Host "`n=== Import Instructions ===" -ForegroundColor Green
Write-Host "To import this dashboard:" -ForegroundColor Yellow
Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor Cyan
Write-Host "2. Navigate to: Dashboards → Import" -ForegroundColor Cyan
Write-Host "3. Upload file: $DashboardFile" -ForegroundColor Cyan
Write-Host "4. Configure data sources if needed" -ForegroundColor Cyan
Write-Host "5. Save dashboard" -ForegroundColor Cyan

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

Write-Host "`nDashboard import instructions completed!" -ForegroundColor Green
Write-Host "Dashboard file: $DashboardFile" -ForegroundColor Cyan
