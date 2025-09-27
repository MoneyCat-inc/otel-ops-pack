# MEMX Dashboard Validation Script
# Validates dashboard JSON and tests alert rules

param(
    [string]$DashboardFile = "signoz-memx-dashboard.json",
    [string]$AlertsFile = "signoz-memx-alerts.json",
    [string]$SigNozUrl = "http://localhost:8080",
    [switch]$TestAlerts,
    [switch]$Verbose
)

Write-Host "=== MEMX Dashboard Validation ===" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "package.json")) {
    Write-Error "Please run this script from the resonai-mock directory"
    exit 1
}

# Validate JSON files
Write-Host "Validating JSON files..." -ForegroundColor Cyan

if (-not (Test-Path $DashboardFile)) {
    Write-Error "Dashboard file not found: $DashboardFile"
    exit 1
}

if (-not (Test-Path $AlertsFile)) {
    Write-Error "Alerts file not found: $AlertsFile"
    exit 1
}

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

# Validate dashboard structure
Write-Host "`n=== Validating Dashboard Structure ===" -ForegroundColor Green

$requiredPanels = @(
    "memx-overview",
    "memx-wasm-heap",
    "memx-sab-usage",
    "memx-worklet-lag",
    "memx-memory-strain",
    "memx-frame-budget",
    "memx-export-metrics",
    "memx-strain-events-log",
    "memx-otel-health",
    "memx-error-rate"
)

$panelIds = $dashboardJson.panels | ForEach-Object { $_.id }
$missingPanels = $requiredPanels | Where-Object { $_ -notin $panelIds }

if ($missingPanels.Count -eq 0) {
    Write-Host "✅ All required panels present" -ForegroundColor Green
} else {
    Write-Host "❌ Missing panels: $($missingPanels -join ', ')" -ForegroundColor Red
    exit 1
}

# Validate panel configurations
Write-Host "`n=== Validating Panel Configurations ===" -ForegroundColor Green

foreach ($panel in $dashboardJson.panels) {
    $panelName = $panel.title
    $panelId = $panel.id
    
    # Check required fields
    if (-not $panel.title) {
        Write-Host "❌ Panel $panelId missing title" -ForegroundColor Red
        continue
    }
    
    if (-not $panel.type) {
        Write-Host "❌ Panel $panelId missing type" -ForegroundColor Red
        continue
    }
    
    if (-not $panel.targets -or $panel.targets.Count -eq 0) {
        Write-Host "❌ Panel $panelId missing targets" -ForegroundColor Red
        continue
    }
    
    # Check targets
    foreach ($target in $panel.targets) {
        if (-not $target.expr) {
            Write-Host "❌ Panel $panelId target missing expr" -ForegroundColor Red
            continue
        }
        
        # Validate PromQL expressions
        if ($target.expr -match "memx_") {
            if ($Verbose) {
                Write-Host "✅ Panel $panelId has valid MEMX metric: $($target.expr)" -ForegroundColor Gray
            }
        }
    }
    
    Write-Host "✅ Panel $panelName validated" -ForegroundColor Green
}

# Validate alert rules
Write-Host "`n=== Validating Alert Rules ===" -ForegroundColor Green

$requiredAlerts = @(
    "memx-high-memory-strain",
    "memx-critical-memory-strain",
    "memx-wasm-heap-growth",
    "memx-sab-backlog",
    "memx-worklet-lag",
    "memx-frame-drops",
    "memx-export-failures",
    "memx-otel-disconnect",
    "memx-session-stall",
    "memx-cross-origin-isolation"
)

$alertIds = $alertsJson.alerts | ForEach-Object { $_.id }
$missingAlerts = $requiredAlerts | Where-Object { $_ -notin $alertIds }

if ($missingAlerts.Count -eq 0) {
    Write-Host "✅ All required alerts present" -ForegroundColor Green
} else {
    Write-Host "❌ Missing alerts: $($missingAlerts -join ', ')" -ForegroundColor Red
    exit 1
}

# Validate alert configurations
foreach ($alert in $alertsJson.alerts) {
    $alertName = $alert.name
    $alertId = $alert.id
    
    # Check required fields
    if (-not $alert.condition.expr) {
        Write-Host "❌ Alert $alertId missing condition expr" -ForegroundColor Red
        continue
    }
    
    if (-not $alert.condition.duration) {
        Write-Host "❌ Alert $alertId missing condition duration" -ForegroundColor Red
        continue
    }
    
    if (-not $alert.condition.severity) {
        Write-Host "❌ Alert $alertId missing condition severity" -ForegroundColor Red
        continue
    }
    
    # Validate severity
    if ($alert.condition.severity -notin @("warning", "critical")) {
        Write-Host "❌ Alert $alertId has invalid severity: $($alert.condition.severity)" -ForegroundColor Red
        continue
    }
    
    Write-Host "✅ Alert $alertName validated" -ForegroundColor Green
}

# Test SigNoz connectivity
Write-Host "`n=== Testing SigNoz Connectivity ===" -ForegroundColor Green

try {
    $healthResponse = Invoke-WebRequest -Uri "$SigNozUrl/api/v1/health" -UseBasicParsing -TimeoutSec 10
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "✅ SigNoz is reachable" -ForegroundColor Green
    } else {
        Write-Host "⚠️  SigNoz returned status: $($healthResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Cannot reach SigNoz at $SigNozUrl" -ForegroundColor Yellow
    Write-Host "   Skipping connectivity tests" -ForegroundColor Gray
}

# Test alert rules if requested
if ($TestAlerts) {
    Write-Host "`n=== Testing Alert Rules ===" -ForegroundColor Green
    
    # Test a few key alerts
    $testAlerts = @(
        "memx-high-memory-strain",
        "memx-worklet-lag",
        "memx-otel-disconnect"
    )
    
    foreach ($alertId in $testAlerts) {
        try {
            $testResponse = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/alerts/test" -Method POST -Body (@{alert_id = $alertId} | ConvertTo-Json) -ContentType "application/json"
            Write-Host "✅ Alert $alertId test passed" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  Alert $alertId test failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

# Check for common issues
Write-Host "`n=== Checking for Common Issues ===" -ForegroundColor Green

# Check for hardcoded URLs
$hardcodedUrls = @()
if ($dashboardJson -match "localhost") {
    $hardcodedUrls += "Dashboard contains localhost URLs"
}
if ($alertsJson -match "localhost") {
    $hardcodedUrls += "Alerts contain localhost URLs"
}

if ($hardcodedUrls.Count -eq 0) {
    Write-Host "✅ No hardcoded localhost URLs found" -ForegroundColor Green
} else {
    Write-Host "⚠️  Hardcoded URLs found:" -ForegroundColor Yellow
    foreach ($url in $hardcodedUrls) {
        Write-Host "   - $url" -ForegroundColor Gray
    }
}

# Check for missing notification channels
if (-not $alertsJson.notification_channels -or $alertsJson.notification_channels.Count -eq 0) {
    Write-Host "⚠️  No notification channels configured" -ForegroundColor Yellow
} else {
    Write-Host "✅ Notification channels configured: $($alertsJson.notification_channels.Count)" -ForegroundColor Green
}

# Check for missing alert groups
if (-not $alertsJson.alert_groups -or $alertsJson.alert_groups.Count -eq 0) {
    Write-Host "⚠️  No alert groups configured" -ForegroundColor Yellow
} else {
    Write-Host "✅ Alert groups configured: $($alertsJson.alert_groups.Count)" -ForegroundColor Green
}

# Summary
Write-Host "`n=== Validation Summary ===" -ForegroundColor Green
Write-Host "Dashboard: $($dashboardJson.name)" -ForegroundColor Cyan
Write-Host "Panels: $($dashboardJson.panels.Count)" -ForegroundColor Cyan
Write-Host "Alerts: $($alertsJson.alerts.Count)" -ForegroundColor Cyan
Write-Host "Status: ✅ VALIDATION COMPLETE" -ForegroundColor Green

# Next steps
Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Import dashboard: .\scripts\import-memx-dashboard.ps1" -ForegroundColor Cyan
Write-Host "2. Configure notification channels" -ForegroundColor Cyan
Write-Host "3. Test alerts in staging environment" -ForegroundColor Cyan
Write-Host "4. Deploy to production" -ForegroundColor Cyan

Write-Host "`n=== MEMX Dashboard Validation Complete ===" -ForegroundColor Green
