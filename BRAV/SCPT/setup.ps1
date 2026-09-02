#Requires -Version 5.1
#Requires -RunAsAdministrator

# First-time kit setup: start the SigNoz stack and register the Windows collector service.
# 2026-09-02 (ECRR_DOCS_TRUTH_SWEEP_20260902 follow-up): this script predates the tetragram reorg
# and still assumed it lived at <repo>\scripts\ — it looked for ..\config\otelcol-windows.yaml and
# ..\docker-compose.yml, neither of which exists relative to BRAV\SCPT\. It now resolves the repo
# root and uses the canonical inputs: root config.yaml (the file the service loads; see
# windows/otelcol/otelcol-contrib-config.yaml for the template) and root docker-compose.yml.
# For the hardened ProgramData layout (delayed-auto start, failure actions, file_storage dirs)
# run scripts\windows\install-or-repair-otel-collector.ps1 afterwards; it requires the service to
# exist, which is what this script creates.

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')).Path   # BRAV\SCPT -> repo root (separator-neutral)

Write-Host "[setup] Starting OTel Windows -> SigNoz Kit Setup" -ForegroundColor Green

# Preflight checks
Write-Host "[setup] Running preflight checks..." -ForegroundColor Yellow

# Check Docker
try {
    $dockerVersion = docker --version 2>$null
    if (-not $dockerVersion) {
        throw "Docker not found in PATH"
    }
    Write-Host "[setup] OK Docker found: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "[setup] ERROR Docker not found. Please install Docker Desktop and ensure it is on PATH" -ForegroundColor Red
    exit 1
}

# Check OTel Collector (phase0-setup.ps1 installs to 'OpenTelemetry Collector'; the MSI layout is 'otelcol-contrib')
$collectorCandidates = @(
    "$env:ProgramFiles\OpenTelemetry Collector\otelcol-contrib.exe",
    "$env:ProgramFiles\otelcol-contrib\otelcol-contrib.exe"
)
$collectorPath = $collectorCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $collectorPath) {
    Write-Host "[setup] ERROR OTel Collector not found at: $($collectorCandidates -join ' or ')" -ForegroundColor Red
    Write-Host "[setup] Install OpenTelemetry Collector for Windows: https://github.com/open-telemetry/opentelemetry-collector-releases" -ForegroundColor Yellow
    exit 1
}
Write-Host "[setup] OK OTel Collector found: $collectorPath" -ForegroundColor Green

# Canonical inputs live at the repo root
$configFile = Join-Path $repoRoot 'config.yaml'
$composeFile = Join-Path $repoRoot 'docker-compose.yml'
foreach ($required in @($configFile, $composeFile)) {
    if (-not (Test-Path -LiteralPath $required)) {
        Write-Host "[setup] ERROR Required file not found: $required" -ForegroundColor Red
        exit 1
    }
}

# Start Docker stack
Write-Host "[setup] Starting SigNoz Docker stack ($composeFile)..." -ForegroundColor Yellow
docker compose -f $composeFile up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "[setup] ERROR Failed to start Docker stack" -ForegroundColor Red
    exit 1
}

# Wait for services to be ready
Write-Host "[setup] Waiting for SigNoz services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Install Windows OTel Collector service against the canonical config
Write-Host "[setup] Installing Windows OTel Collector service ($configFile)..." -ForegroundColor Yellow
& $PSScriptRoot\install-service.ps1 -CollectorPath $collectorPath -Config $configFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "[setup] ERROR Failed to install Windows OTel Collector service" -ForegroundColor Red
    exit 1
}

Write-Host "[setup] OK Setup complete!" -ForegroundColor Green
Write-Host "[setup] SigNoz UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "[setup] SigNoz OTLP: localhost:4317 (gRPC) / http://localhost:4318 (HTTP)" -ForegroundColor Cyan
Write-Host "[setup] Windows collector ingest: 127.0.0.1:5320 (gRPC) / 5321 (HTTP); health 127.0.0.1:13134" -ForegroundColor Cyan
Write-Host "[setup] Next: pwsh -File scripts\verify-integration.ps1 (or BRAV\SCPT\verify-pipeline.ps1) to test the pipeline" -ForegroundColor Yellow
Write-Host "[setup] Harden: pwsh -File scripts\windows\install-or-repair-otel-collector.ps1 -ConfigSource .\config.yaml" -ForegroundColor Yellow
