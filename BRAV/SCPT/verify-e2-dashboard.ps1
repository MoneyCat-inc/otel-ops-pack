# Verify E2 Dashboard Setup
# Tests the complete E2 ratio sweep dashboard implementation

Write-Host "=== E2 Dashboard Verification ===" -ForegroundColor Green

# Check if results file exists
$resultsFile = "artifacts/e2-ratio-sweep-results.json"
if (Test-Path $resultsFile) {
    Write-Host "✓ E2 results file exists: $resultsFile" -ForegroundColor Green
    $results = Get-Content $resultsFile | ConvertFrom-Json
    Write-Host "  - Contains $($results.combinations.Count) test combinations" -ForegroundColor White
} else {
    Write-Host "✗ E2 results file not found: $resultsFile" -ForegroundColor Red
}

# Check if dashboard config exists
$dashboardFile = "artifacts/signoz-dashboard-config.json"
if (Test-Path $dashboardFile) {
    Write-Host "✓ Dashboard config exists: $dashboardFile" -ForegroundColor Green
    $dashboard = Get-Content $dashboardFile | ConvertFrom-Json
    Write-Host "  - Contains $($dashboard.panels.Count) panels" -ForegroundColor White
    
    # Check for E2-specific panels
    $e2Panels = $dashboard.panels | Where-Object { $_.id -like "e2-*" }
    Write-Host "  - E2 panels: $($e2Panels.Count)" -ForegroundColor White
    foreach ($panel in $e2Panels) {
        Write-Host "    * $($panel.title)" -ForegroundColor Cyan
    }
} else {
    Write-Host "✗ Dashboard config not found: $dashboardFile" -ForegroundColor Red
}

# Check if publisher script exists
$publisherFile = "scripts/publish-e2-results.ps1"
if (Test-Path $publisherFile) {
    Write-Host "✓ Publisher script exists: $publisherFile" -ForegroundColor Green
} else {
    Write-Host "✗ Publisher script not found: $publisherFile" -ForegroundColor Red
}

# Check if import script exists
$importFile = "scripts/import-dashboard.ps1"
if (Test-Path $importFile) {
    Write-Host "✓ Import script exists: $importFile" -ForegroundColor Green
} else {
    Write-Host "✗ Import script not found: $importFile" -ForegroundColor Red
}

# Test OTLP endpoint connectivity
Write-Host "`nTesting OTLP endpoint connectivity..." -ForegroundColor Yellow
try {
    $testConnection = Test-NetConnection -ComputerName 127.0.0.1 -Port 5321 -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "✓ OTLP endpoint (127.0.0.1:5321) is reachable" -ForegroundColor Green
    } else {
        Write-Host "✗ OTLP endpoint (127.0.0.1:5321) is not reachable" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Could not test OTLP endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

# Test SigNoz UI connectivity
Write-Host "`nTesting SigNoz UI connectivity..." -ForegroundColor Yellow
try {
    $testConnection = Test-NetConnection -ComputerName 127.0.0.1 -Port 8080 -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "✓ SigNoz UI (127.0.0.1:8080) is reachable" -ForegroundColor Green
    } else {
        Write-Host "✗ SigNoz UI (127.0.0.1:8080) is not reachable" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Could not test SigNoz UI: $($_.Exception.Message)" -ForegroundColor Red
}

# Display verification summary
Write-Host "`n=== Verification Summary ===" -ForegroundColor Green
Write-Host "Dashboard panels added:" -ForegroundColor Yellow
Write-Host "  1. E2 Ratio Sweep Results (table)" -ForegroundColor White
Write-Host "  2. Optimal E2 Config (stat)" -ForegroundColor White
Write-Host "  3. E2 P95 Latency Trend (timeseries)" -ForegroundColor White

Write-Host "`nSigNoz UI verification steps:" -ForegroundColor Yellow
Write-Host "1. Open SigNoz UI: http://127.0.0.1:8080" -ForegroundColor White
Write-Host "2. Go to Dashboards → Import" -ForegroundColor White
Write-Host "3. Upload: artifacts/signoz-dashboard-config.json" -ForegroundColor White
Write-Host "4. Open 'OTel Queue Pressure Dashboard'" -ForegroundColor White
Write-Host "5. Verify E2 panels are visible" -ForegroundColor White

Write-Host "`nLog verification steps:" -ForegroundColor Yellow
Write-Host "1. Go to Logs → Builder" -ForegroundColor White
Write-Host "2. Add filter: dataset = 'e2_ratio_sweep'" -ForegroundColor White
Write-Host "3. Add filter: log_type = 'e2_result'" -ForegroundColor White
Write-Host "4. Should see 9 log entries (E2-001 to E2-009)" -ForegroundColor White

Write-Host "`nCommands to run:" -ForegroundColor Yellow
Write-Host "pwsh -File scripts/publish-e2-results.ps1" -ForegroundColor White
Write-Host "pwsh -File scripts/import-dashboard.ps1" -ForegroundColor White

Write-Host "`nE2 Dashboard verification completed!" -ForegroundColor Green
