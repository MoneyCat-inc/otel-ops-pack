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
  Write-Host "  [OK] Created: $ProgramDataPath" -ForegroundColor Green
} else {
  Write-Host "  [OK] Already exists: $ProgramDataPath" -ForegroundColor Green
}

# Step 2: Write config (with endpoint substitution)
Write-Host ""
Write-Host "[2/5] Writing collector config..." -ForegroundColor White

if (!(Test-Path $ConfigSource)) {
  Write-Error "Config source not found: $ConfigSource"
  Write-Host "  -> Expected location: .\windows\otelcol\otelcol-contrib-config.yaml" -ForegroundColor Yellow
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
Write-Host "  [OK] Config written: $configTarget" -ForegroundColor Green
Write-Host "  -> OTLP endpoint: $OtlpGrpcEndpoint" -ForegroundColor Gray
Write-Host "  -> Deploy env: $deployEnv" -ForegroundColor Gray

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

Write-Host "  [OK] Service found: $ServiceName" -ForegroundColor Green

# Step 4: Fix ImagePath via registry (sc.exe binPath= fails with spaces), then configure reliability
Write-Host ""
Write-Host "[4/5] Configuring service..." -ForegroundColor White

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
$currentImagePath = (Get-ItemProperty -LiteralPath $regPath -Name ImagePath -ErrorAction Stop).ImagePath

# Strip any existing --config argument to isolate the executable token
$exeToken = if ($currentImagePath -match '^("[^"]+\.exe")') {
  $Matches[1]
} elseif ($currentImagePath -match '^([^\s]+\.exe)') {
  $Matches[1]
} else {
  $null
}

if (-not $exeToken) {
  Write-Error "  Could not parse executable from ImagePath: $currentImagePath"
  exit 1
}

$newImagePath = "$exeToken --config `"$configTarget`""
Set-ItemProperty -LiteralPath $regPath -Name ImagePath -Value $newImagePath

# Read back and fail closed
$verified = (Get-ItemProperty -LiteralPath $regPath -Name ImagePath).ImagePath
if ($verified -ne $newImagePath) {
  Write-Error "  ImagePath verification failed. Got: $verified"
  exit 1
}
Write-Host "  [OK] ImagePath set: $newImagePath" -ForegroundColor Green

# Set Automatic (Delayed Start)
sc.exe config $ServiceName start= delayed-auto | Out-Null
Write-Host "  [OK] Start type: Automatic (Delayed Start)" -ForegroundColor Green

# Set failure actions: restart after 10s for first/second/subsequent failures
sc.exe failure $ServiceName reset= 0 actions= restart/10000/restart/10000/restart/10000 | Out-Null
sc.exe failureflag $ServiceName 1 | Out-Null
Write-Host "  [OK] Failure recovery: Restart after 10s (3 attempts)" -ForegroundColor Green

# Step 5: Stop (with timeout + kill fallback) then start service
Write-Host ""
Write-Host "[5/5] Starting service..." -ForegroundColor White

$svc = Get-Service -Name $ServiceName
if ($svc.Status -ne "Stopped") {
  sc.exe stop $ServiceName | Out-Null
  $stopDeadline = (Get-Date).AddSeconds(30)
  do {
    Start-Sleep -Seconds 2
    $svc = Get-Service -Name $ServiceName
  } while ($svc.Status -ne "Stopped" -and (Get-Date) -lt $stopDeadline)

  if ($svc.Status -ne "Stopped") {
    Write-Warning "  Service did not stop within 30s (Status: $($svc.Status)) - attempting kill"
    $proc = (Get-CimInstance Win32_Service -Filter "Name='$ServiceName'").ProcessId
    if ($proc -and $proc -gt 0) { Stop-Process -Id $proc -Force -ErrorAction SilentlyContinue }
    # Poll again after kill
    $killDeadline = (Get-Date).AddSeconds(15)
    do {
      Start-Sleep -Seconds 2
      $svc = Get-Service -Name $ServiceName
    } while ($svc.Status -ne "Stopped" -and (Get-Date) -lt $killDeadline)
    if ($svc.Status -ne "Stopped") {
      Write-Error "  Service still not stopped after kill (Status: $($svc.Status))"
      exit 1
    }
  }
  Write-Host "  -> Service stopped" -ForegroundColor Gray
}

try {
  Start-Service -Name $ServiceName
  Write-Host "  -> Service started" -ForegroundColor Gray
} catch {
  Write-Error "Failed to start service '$ServiceName': $_"
  Write-Host "  - Check config syntax: $configTarget" -ForegroundColor Yellow
  Write-Host "  - View logs: Get-EventLog -LogName Application -Source $ServiceName" -ForegroundColor Gray
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

Write-Host "  [OK] Service status: RUNNING" -ForegroundColor Green

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[OK] BOSSCAT-022A Install/Repair Complete" -ForegroundColor Green
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

