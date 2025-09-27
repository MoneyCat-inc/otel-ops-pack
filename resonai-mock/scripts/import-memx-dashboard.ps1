# Import MEMX Dashboard to SigNoz
# Imports the MEMX dashboard configuration and alert rules

param(
    [string]$SigNozUrl = "http://localhost:8080",
    [string]$DashboardFile = "signoz-memx-dashboard.json",
    [string]$AlertsFile = "signoz-memx-alerts.json",
    [switch]$DryRun,
    [switch]$Force
)

Write-Host "=== MEMX SigNoz Dashboard Import ===" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Error "Please run this script from the resonai-mock directory"
    exit 1
}

# Check if SigNoz is reachable
Write-Host "Checking SigNoz connectivity..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -UseBasicParsing -TimeoutSec 10
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "✅ SigNoz is reachable" -ForegroundColor Green
    } else {
        Write-Error "SigNoz returned status: $($healthResponse.StatusCode)"
        exit 1
    }
} catch {
    Write-Error "Cannot reach SigNoz at $SigNozUrl. Please ensure SigNoz is running."
    exit 1
}

# Check if dashboard file exists
if (-not (Test-Path $DashboardFile)) {
    Write-Error "Dashboard file not found: $DashboardFile"
    exit 1
}

# Check if alerts file exists
if (-not (Test-Path $AlertsFile)) {
    Write-Error "Alerts file not found: $AlertsFile"
    exit 1
}

# Validate JSON files
Write-Host "Validating JSON files..." -ForegroundColor Cyan
try {
    $dashboardJson = Get-Content $DashboardFile -Raw | ConvertFrom-Json
    Write-Host "✅ Dashboard JSON is valid" -ForegroundColor Green
} catch {
    Write-Error "Invalid dashboard JSON: $($_.Exception.Message)"
    exit 1
}

try {
    $alertsJson = Get-Content $AlertsFile -Raw | ConvertFrom-Json
    Write-Host "✅ Alerts JSON is valid" -ForegroundColor Green
} catch {
    Write-Error "Invalid alerts JSON: $($_.Exception.Message)"
    exit 1
}

# Check if dashboard already exists
Write-Host "Checking for existing dashboard..." -ForegroundColor Cyan
try {
    $existingDashboards = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Method GET
    $memxDashboard = $existingDashboards | Where-Object { $_.name -eq "MEMX Memory Observation Dashboard" }
    
    if ($memxDashboard -and -not $Force) {
        Write-Host "⚠️  MEMX dashboard already exists" -ForegroundColor Yellow
        $response = Read-Host "Do you want to overwrite it? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Host "Import cancelled" -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Host "⚠️  Could not check existing dashboards: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Import dashboard
Write-Host "`n=== Importing Dashboard ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "DRY RUN - Would import dashboard:" -ForegroundColor Cyan
    Write-Host "Name: $($dashboardJson.name)" -ForegroundColor Gray
    Write-Host "Panels: $($dashboardJson.panels.Count)" -ForegroundColor Gray
    Write-Host "Refresh: $($dashboardJson.refresh)" -ForegroundColor Gray
} else {
    try {
        $dashboardResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/dashboards" -Method POST -Body (Get-Content $DashboardFile -Raw) -ContentType "application/json"
        Write-Host "✅ Dashboard imported successfully" -ForegroundColor Green
        Write-Host "Dashboard ID: $($dashboardResponse.id)" -ForegroundColor Cyan
        Write-Host "URL: $SigNozUrl/dashboards/$($dashboardResponse.id)" -ForegroundColor Cyan
    } catch {
        Write-Error "Failed to import dashboard: $($_.Exception.Message)"
        exit 1
    }
}

# Import alerts
Write-Host "`n=== Importing Alerts ===" -ForegroundColor Green

if ($DryRun) {
    Write-Host "DRY RUN - Would import alerts:" -ForegroundColor Cyan
    Write-Host "Alerts: $($alertsJson.alerts.Count)" -ForegroundColor Gray
    Write-Host "Notification Channels: $($alertsJson.notification_channels.Count)" -ForegroundColor Gray
} else {
    try {
        $alertsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts" -Method POST -Body (Get-Content $AlertsFile -Raw) -ContentType "application/json"
        Write-Host "✅ Alerts imported successfully" -ForegroundColor Green
        Write-Host "Alerts imported: $($alertsJson.alerts.Count)" -ForegroundColor Cyan
    } catch {
        Write-Error "Failed to import alerts: $($_.Exception.Message)"
        exit 1
    }
}

# Verify metrics are available
Write-Host "`n=== Verifying Metrics ===" -ForegroundColor Green

$requiredMetrics = @(
    "memx_wasm_heap_bytes",
    "memx_sab_usage_percent",
    "memx_worklet_lag_ms",
    "memx_memory_strain_percent"
)

foreach ($metric in $requiredMetrics) {
    try {
        $metricResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/query?query=$metric" -Method GET
        if ($metricResponse.data.result.Count -gt 0) {
            Write-Host "✅ $metric is available" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $metric has no data (may be normal if MEMX is not active)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Could not check $metric : $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Check for MEMX logs
Write-Host "`n=== Checking MEMX Logs ===" -ForegroundColor Green
try {
    $logsResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/query?query={dataset=\"resonai_analytics\"} |= \"MEMX\"" -Method GET
    if ($logsResponse.data.result.Count -gt 0) {
        Write-Host "✅ MEMX logs are available" -ForegroundColor Green
    } else {
        Write-Host "⚠️  No MEMX logs found (may be normal if MEMX is not active)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not check MEMX logs: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Import Summary ===" -ForegroundColor Green
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor Cyan
Write-Host "Dashboard: $($dashboardJson.name)" -ForegroundColor Cyan
Write-Host "Panels: $($dashboardJson.panels.Count)" -ForegroundColor Cyan
Write-Host "Alerts: $($alertsJson.alerts.Count)" -ForegroundColor Cyan
Write-Host "Status: ✅ COMPLETE" -ForegroundColor Green

# Next steps
Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Visit the dashboard: $SigNozUrl/dashboards" -ForegroundColor Cyan
Write-Host "2. Configure notification channels in the alerts file" -ForegroundColor Cyan
Write-Host "3. Enable MEMX in production: .\scripts\setup-memx-production.ps1 -EnableStreaming" -ForegroundColor Cyan
Write-Host "4. Run canary test: .\scripts\memx-canary-test.ps1 -EnableStreaming" -ForegroundColor Cyan
Write-Host "5. Monitor the dashboard for MEMX metrics" -ForegroundColor Cyan

Write-Host "`n=== MEMX Dashboard Import Complete ===" -ForegroundColor Green
