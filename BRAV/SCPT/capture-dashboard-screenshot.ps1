# Capture SigNoz Dashboard Screenshot
# Provides instructions for capturing E2 dashboard proof

param(
    [string]$SigNozUrl = "http://127.0.0.1:8080",
    [string]$ScreenshotDir = "CHAR/ECRR/ECRR_REPORTS"
)

Import-Module (Join-Path $PSScriptRoot 'lib\OtelPorts.psm1') -Force
$otelPorts = Get-OtelPorts

Write-Host "=== SigNoz Dashboard Screenshot Capture ===" -ForegroundColor Green
Write-Host "SigNoz URL: $SigNozUrl" -ForegroundColor Yellow
Write-Host "Screenshot directory: $ScreenshotDir" -ForegroundColor Yellow

# Ensure screenshot directory exists
if (-not (Test-Path $ScreenshotDir)) {
    New-Item -ItemType Directory -Path $ScreenshotDir -Force
    Write-Host "Created screenshot directory: $ScreenshotDir" -ForegroundColor Green
}

# Check SigNoz connectivity
Write-Host "`nChecking SigNoz connectivity..." -ForegroundColor Yellow
try {
    $testConnection = Test-NetConnection -ComputerName 127.0.0.1 -Port 8080 -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "✓ SigNoz UI is reachable" -ForegroundColor Green
    } else {
        Write-Host "✗ SigNoz UI is not reachable" -ForegroundColor Red
        Write-Host "Please ensure SigNoz is running and accessible" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Could not test SigNoz connectivity: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Screenshot Capture Instructions ===" -ForegroundColor Green

Write-Host "`n1. Open SigNoz UI:" -ForegroundColor Yellow
Write-Host "   URL: $SigNozUrl" -ForegroundColor White
Write-Host "   Browser: Chrome, Firefox, or Edge recommended" -ForegroundColor White

Write-Host "`n2. Navigate to Dashboards:" -ForegroundColor Yellow
Write-Host "   Click: Dashboards (left sidebar)" -ForegroundColor White
Write-Host "   Click: Import (if dashboard not already imported)" -ForegroundColor White
Write-Host "   Upload: artifacts/signoz-dashboard-config.json" -ForegroundColor White

Write-Host "`n3. Open OTel Queue Pressure Dashboard:" -ForegroundColor Yellow
Write-Host "   Click: 'OTel Queue Pressure Dashboard'" -ForegroundColor White
Write-Host "   Wait: For all panels to load (may take 30-60 seconds)" -ForegroundColor White

Write-Host "`n4. Verify E2 Panels:" -ForegroundColor Yellow
Write-Host "   ✓ E2 Ratio Sweep Results (table with 9 rows)" -ForegroundColor White
Write-Host "   ✓ Optimal E2 Config (stat showing E2-005)" -ForegroundColor White
Write-Host "   ✓ E2 P95 Latency Trend (chart with 9 lines)" -ForegroundColor White

Write-Host "`n5. Capture Screenshot:" -ForegroundColor Yellow
Write-Host "   Method 1: Browser screenshot tool" -ForegroundColor White
Write-Host "     - Chrome: F12 → Device toolbar → Screenshot" -ForegroundColor White
Write-Host "     - Firefox: Right-click → Take Screenshot" -ForegroundColor White
Write-Host "   Method 2: Windows Snipping Tool" -ForegroundColor White
Write-Host "     - Win+Shift+S → Select area → Save" -ForegroundColor White
Write-Host "   Method 3: Print Screen" -ForegroundColor White
Write-Host "     - PrtScn → Paste in Paint → Save" -ForegroundColor White

Write-Host "`n6. Save Screenshot:" -ForegroundColor Yellow
$screenshotPath = "$ScreenshotDir/2025-01-27-e2-dashboard-screenshot.png"
Write-Host "   Filename: 2025-01-27-e2-dashboard-screenshot.png" -ForegroundColor White
Write-Host "   Path: $screenshotPath" -ForegroundColor White
Write-Host "   Format: PNG (recommended)" -ForegroundColor White

Write-Host "`n7. Verify Log Data:" -ForegroundColor Yellow
Write-Host "   Go to: Logs → Builder" -ForegroundColor White
Write-Host "   Add filter: dataset = 'e2_ratio_sweep'" -ForegroundColor White
Write-Host "   Add filter: log_type = 'e2_result'" -ForegroundColor White
Write-Host "   Should see: 9 log entries (E2-001 to E2-009)" -ForegroundColor White

Write-Host "`n=== Expected Dashboard Content ===" -ForegroundColor Green

Write-Host "`nE2 Ratio Sweep Results Table:" -ForegroundColor Yellow
Write-Host "  Columns: test_id, agent_timeout, gateway_timeout, p95_latency_ms, p99_latency_ms, queue_utilization_percent, batch_efficiency_percent" -ForegroundColor White
Write-Host "  Rows: 9 (E2-001 through E2-009)" -ForegroundColor White
Write-Host "  Sort: By p95_latency_ms ascending" -ForegroundColor White

Write-Host "`nOptimal E2 Config Stat:" -ForegroundColor Yellow
Write-Host "  Value: E2-005 (200ms/5s)" -ForegroundColor White
Write-Host "  P95 Latency: 1550ms" -ForegroundColor White
Write-Host "  Color: Green (within threshold)" -ForegroundColor White

Write-Host "`nE2 P95 Latency Trend Chart:" -ForegroundColor Yellow
Write-Host "  X-axis: Time" -ForegroundColor White
Write-Host "  Y-axis: P95 Latency (ms)" -ForegroundColor White
Write-Host "  Lines: 9 (one per test combination)" -ForegroundColor White
Write-Host "  Legend: test_id labels" -ForegroundColor White

Write-Host "`n=== Troubleshooting ===" -ForegroundColor Green

Write-Host "`nIf panels are empty:" -ForegroundColor Yellow
Write-Host "1. Check if E2 results were published:" -ForegroundColor White
Write-Host "   pwsh -File scripts/publish-e2-results.ps1" -ForegroundColor White
Write-Host "2. Wait 30-60 seconds for data to appear" -ForegroundColor White
Write-Host "3. Refresh the dashboard" -ForegroundColor White

Write-Host "`nIf dashboard import fails:" -ForegroundColor Yellow
Write-Host "1. Check JSON syntax:" -ForegroundColor White
Write-Host "   Get-Content artifacts/signoz-dashboard-config.json | ConvertFrom-Json" -ForegroundColor White
Write-Host "2. Verify SigNoz is running:" -ForegroundColor White
Write-Host "   docker ps | findstr signoz" -ForegroundColor White

Write-Host "`nIf logs don't appear:" -ForegroundColor Yellow
Write-Host "1. Check OTLP endpoint:" -ForegroundColor White
Write-Host "   Test-NetConnection -ComputerName 127.0.0.1 -Port $($otelPorts.IngestHttp)" -ForegroundColor White
Write-Host "2. Verify collector is running:" -ForegroundColor White
Write-Host "   Get-Service otelcol-contrib" -ForegroundColor White

Write-Host "`nScreenshot capture instructions completed!" -ForegroundColor Green
Write-Host "Screenshot path: $screenshotPath" -ForegroundColor Cyan

