# BOSSCAT-022A: Install/Repair OpenTelemetry Collector (Windows)
# Purpose: Idempotent setup of otelcol-contrib service with hardened config
# Authority: BossCat OEM | Executor: Cursor{Implementer}

param(
  [string]$ConfigSource = ".\windows\otelcol\otelcol-contrib-config.yaml",
  [string]$ProgramDataPath = "$env:ProgramData\otelcol-contrib",
  [string]$ServiceName = "otelcol-contrib",
  [string]$OtlpGrpcEndpoint = "127.0.0.1:4317"
)

$ErrorActionPreference = "Stop"

Write-Host "=== BOSSCAT-022A :: Install/Repair OpenTelemetry Collector (Windows) ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Ensure ProgramData folder exists
Write-Host "[1/5] Ensuring config directory..." -ForegroundColor White
if (!(Test-Path $ProgramDataPath)) {
  New-Item -ItemType Directory -Force -Path $ProgramDataPath | Out-Null
  Write-Host "  ✓ Created: $ProgramDataPath" -ForegroundColor Green
} else {
  Write-Host "  ✓ Already exists: $ProgramDataPath" -ForegroundColor Green
}

# Step 2: Write config (with endpoint substitution)
Write-Host ""
Write-Host "[2/5] Writing collector config..." -ForegroundColor White

if (!(Test-Path $ConfigSource)) {
  Write-Error "Config source not found: $ConfigSource"
  Write-Host "  → Expected location: .\windows\otelcol\otelcol-contrib-config.yaml" -ForegroundColor Yellow
  exit 1
}

$configText = Get-Content $ConfigSource -Raw

# Substitute OTLP endpoint if provided
if ($OtlpGrpcEndpoint) {
  $configText = $configText -replace '\$\{env:OTLP_GRPC_ENDPOINT\}', $OtlpGrpcEndpoint
}

# Set deployment environment (default to local)
$deployEnv = if ($env:DEPLOY_ENV) { $env:DEPLOY_ENV } else { "local" }
$configText = $configText -replace '\$\{env:DEPLOY_ENV\}', $deployEnv

$configTarget = Join-Path $ProgramDataPath "config.yaml"
$configText | Out-File -FilePath $configTarget -Encoding UTF8 -Force
Write-Host "  ✓ Config written: $configTarget" -ForegroundColor Green
Write-Host "  → OTLP endpoint: $OtlpGrpcEndpoint" -ForegroundColor Gray
Write-Host "  → Deploy env: $deployEnv" -ForegroundColor Gray

# Step 3: Ensure service exists
Write-Host ""
Write-Host "[3/5] Checking service installation..." -ForegroundColor White

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (!$svc) {
  Write-Warning "Service '$ServiceName' not found."
  Write-Host ""
  Write-Host "  Please install the OpenTelemetry Collector Contrib for Windows:" -ForegroundColor Yellow
  Write-Host "  1. Download: https://github.com/open-telemetry/opentelemetry-collector-releases/releases" -ForegroundColor Yellow
  Write-Host "  2. Install MSI or extract binary to: C:\Program Files\otelcol-contrib\" -ForegroundColor Yellow
  Write-Host "  3. Create Windows service with:" -ForegroundColor Yellow
  Write-Host "     sc.exe create $ServiceName binPath= \"C:\Program Files\otelcol-contrib\otelcol-contrib.exe --config $configTarget\"" -ForegroundColor Gray
  Write-Host ""
  Write-Host "  Once installed, re-run this script." -ForegroundColor Yellow
  exit 1
}

Write-Host "  ✓ Service found: $ServiceName" -ForegroundColor Green

# Step 4: Configure service for reliability
Write-Host ""
Write-Host "[4/5] Configuring service..." -ForegroundColor White

# Set Automatic (Delayed Start)
sc.exe config $ServiceName start= delayed-auto | Out-Null
Write-Host "  ✓ Start type: Automatic (Delayed Start)" -ForegroundColor Green

# Set failure actions: restart after 10s for first/second/subsequent failures
sc.exe failure $ServiceName reset= 0 actions= restart/10000/restart/10000/restart/10000 | Out-Null
sc.exe failureflag $ServiceName 1 | Out-Null
Write-Host "  ✓ Failure recovery: Restart after 10s (3 attempts)" -ForegroundColor Green

# Step 5: Start or restart service
Write-Host ""
Write-Host "[5/5] Starting service..." -ForegroundColor White

try {
  if ($svc.Status -ne "Running") {
    Start-Service -Name $ServiceName
    Write-Host "  → Service started" -ForegroundColor Gray
  } else {
    Restart-Service -Name $ServiceName -Force
    Write-Host "  → Service restarted (config refresh)" -ForegroundColor Gray
  }
} catch {
  Write-Error "Failed to start/restart service '$ServiceName': $_"
  Write-Host ""
  Write-Host "  Troubleshooting:" -ForegroundColor Yellow
  Write-Host "  - Check config syntax: $configTarget" -ForegroundColor Gray
  Write-Host "  - View service logs: Get-EventLog -LogName Application -Source $ServiceName" -ForegroundColor Gray
  exit 1
}

# Wait for service to stabilize
Start-Sleep -Seconds 3

# Verify service is running
$svcStatus = (Get-Service -Name $ServiceName).Status
if ($svcStatus -ne "Running") {
  Write-Error "Service not running after start attempt (Status: $svcStatus)"
  exit 1
}

Write-Host "  ✓ Service status: RUNNING" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ BOSSCAT-022A Install/Repair Complete" -ForegroundColor Green
Write-Host ""
Write-Host "Service: $ServiceName" -ForegroundColor White
Write-Host "Status: RUNNING" -ForegroundColor Green
Write-Host "Config: $configTarget" -ForegroundColor White
Write-Host "Start Type: Delayed Auto-Start" -ForegroundColor White
Write-Host "Failure Recovery: Enabled" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Verify: pwsh -File .\scripts\windows\verify-otel-collector.ps1" -ForegroundColor Gray
Write-Host "  2. Monitor: Get-Service $ServiceName" -ForegroundColor Gray
Write-Host "  3. Telemetry: http://localhost:8888/metrics" -ForegroundColor Gray
Write-Host ""

