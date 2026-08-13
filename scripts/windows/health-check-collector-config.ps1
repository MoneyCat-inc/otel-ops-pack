# Gate 022 Post-Op: Config Lint + Endpoint Assertion
# Purpose: Drift guard for Windows Collector configuration
# Authority: BossCat OEM | Executor: Cursor{Implementer}
# Exit Codes: 0=GREEN, 20=RED (config drift), 21=RED (service mismatch)

$ErrorActionPreference = "Stop"

# Two paths, two roles — see docs/runbooks/windows-collector.md:
#   $ConfigPath         source of record, edited in the repo and reviewed via PR
#   $DeployedConfigPath copy the service actually reads, written by install-or-repair
# Check 3 previously asserted the service ran --config $ConfigPath. It never does, so the guard
# returned exit 21 against healthy collectors. Assert the deployed path instead.
$ConfigPath = "C:\otel\config.yaml"
$DeployedConfigPath = "C:\ProgramData\otelcol-contrib\config.yaml"
$ExpectedEndpointPattern = "(127\.0\.0\.1|localhost):4317"
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
  Write-Host "[RED] Endpoint mismatch - expected 127.0.0.1:4317 or localhost:4317" -ForegroundColor Red
  Write-Host "Current config:" -ForegroundColor Yellow
  $configContent | Select-String -Pattern "endpoint:" | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
  exit 20
}
Write-Host "[OK] Endpoint verified: localhost:4317 or 127.0.0.1:4317" -ForegroundColor Green

# Check 3: Service runs against the deployed config written by install-or-repair
$serviceConfig = sc qc $ServiceName 2>&1 | Out-String
if ($serviceConfig -notmatch [regex]::Escape("--config `"$DeployedConfigPath`"")) {
  Write-Host "[RED] Service not using the deployed config path" -ForegroundColor Red
  Write-Host "Expected: --config `"$DeployedConfigPath`"" -ForegroundColor Yellow
  Write-Host "Fix: pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1" -ForegroundColor Yellow
  Write-Host "Service config:" -ForegroundColor Yellow
  sc qc $ServiceName | findstr /i "BINARY_PATH_NAME"
  exit 21
}
Write-Host "[OK] Service using deployed config path" -ForegroundColor Green

# Check 3b: The deployed copy exists (a service can hold a path that was later removed)
if (-not (Test-Path $DeployedConfigPath)) {
  Write-Host "[RED] Deployed config missing: $DeployedConfigPath" -ForegroundColor Red
  Write-Host "Fix: pwsh -File .\scripts\windows\install-or-repair-otel-collector.ps1" -ForegroundColor Yellow
  exit 21
}
Write-Host "[OK] Deployed config present: $DeployedConfigPath" -ForegroundColor Green

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
$grpcReachable = Test-NetConnection -ComputerName 127.0.0.1 -Port 4317 -WarningAction SilentlyContinue -InformationLevel Quiet -ErrorAction SilentlyContinue
if (-not $grpcReachable) {
  Write-Host "[WARN] OTLP aggregator not reachable on port 4317" -ForegroundColor Yellow
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

