# Gate 022 Post-Op: Config Lint + Endpoint Assertion
# Purpose: Drift guard for Windows Collector configuration
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Exit Codes: 0=GREEN, 20=RED (config drift), 21=RED (service mismatch)

$ErrorActionPreference = "Stop"

$ConfigPath = "C:\otel\config.yaml"
$ExpectedEndpointPattern = "(127\.0\.0\.1|localhost):14317"
$ServiceName = "otelcol-contrib"

Write-Host "=== Windows Collector Config Health Check ===" -ForegroundColor Cyan
Write-Host ""

# Check 1: Config file exists
if (-not (Test-Path $ConfigPath)) {
  Write-Host "[RED] Config file not found: $ConfigPath" -ForegroundColor Red
  exit 20
}
Write-Host "[OK] Config file exists: $ConfigPath" -ForegroundColor Green

# Check 2: Endpoint assertion
$configContent = Get-Content $ConfigPath -Raw
if ($configContent -notmatch $ExpectedEndpointPattern) {
  Write-Host "[RED] Endpoint mismatch - expected 127.0.0.1:14317 or localhost:14317" -ForegroundColor Red
  Write-Host "Current config:" -ForegroundColor Yellow
  $configContent | Select-String -Pattern "endpoint:" | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
  exit 20
}
Write-Host "[OK] Endpoint verified: localhost:14317 or 127.0.0.1:14317" -ForegroundColor Green

# Check 3: Service config matches canonical path
$serviceConfig = sc qc $ServiceName 2>&1 | Out-String
if ($serviceConfig -notmatch [regex]::Escape("--config `"$ConfigPath`"")) {
  Write-Host "[RED] Service not using canonical config path" -ForegroundColor Red
  Write-Host "Expected: --config `"$ConfigPath`"" -ForegroundColor Yellow
  Write-Host "Service config:" -ForegroundColor Yellow
  sc qc $ServiceName | findstr /i "BINARY_PATH_NAME"
  exit 21
}
Write-Host "[OK] Service using canonical config path" -ForegroundColor Green

# Check 4: Service is running
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
  Write-Host "[RED] Service not found: $ServiceName" -ForegroundColor Red
  exit 21
}
if ($service.Status -ne "Running") {
  Write-Host "[RED] Service not running: $($service.Status)" -ForegroundColor Red
  exit 21
}
Write-Host "[OK] Service running: $ServiceName" -ForegroundColor Green

# Check 5: OTLP aggregator reachability
$grpcReachable = Test-NetConnection -ComputerName 127.0.0.1 -Port 14317 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
if (-not $grpcReachable) {
  Write-Host "[WARN] OTLP aggregator not reachable on port 14317" -ForegroundColor Yellow
  # Non-fatal - aggregator might be down temporarily
}
else {
  Write-Host "[OK] OTLP aggregator reachable" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Health Check: GREEN (All assertions passed)" -ForegroundColor Green
Write-Host ""
exit 0

