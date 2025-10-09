#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Write-Host "[setup] Starting OTel Windows -> SigNoz Kit Setup (No Admin)" -ForegroundColor Green

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
    Write-Host "[setup] ERROR Docker not found. Install Docker Desktop and ensure it is on PATH" -ForegroundColor Red
    exit 1
}

# Check OTel Collector
$collectorPath = "C:\\Program Files\\OpenTelemetry Collector\\otelcol-contrib.exe"
if (-not (Test-Path $collectorPath)) {
    Write-Host "[setup] ERROR OTel Collector not found at: $collectorPath" -ForegroundColor Red
    Write-Host "[setup] Install OpenTelemetry Collector for Windows: https://github.com/open-telemetry/opentelemetry-collector-releases" -ForegroundColor Yellow
    exit 1
}
Write-Host "[setup] OK OTel Collector found: $collectorPath" -ForegroundColor Green

# Ensure config directory exists
$configDir = Join-Path $PSScriptRoot "..\config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "[setup] OK Created config directory" -ForegroundColor Green
}

# Start Docker stack
Write-Host "[setup] Starting SigNoz Docker stack..." -ForegroundColor Yellow
$composeFile = Join-Path $PSScriptRoot "..\docker-compose.yml"
docker compose -f $composeFile up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "[setup] ERROR Failed to start Docker stack" -ForegroundColor Red
    exit 1
}

# Wait for services to be ready
Write-Host "[setup] Waiting for SigNoz services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "[setup] OK Docker stack started successfully" -ForegroundColor Green
Write-Host "[setup] SigNoz UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "[setup] OTLP gRPC: localhost:4317" -ForegroundColor Cyan
Write-Host "[setup] OTLP HTTP: http://localhost:4318" -ForegroundColor Cyan
Write-Host "[setup] Note: installing the Windows OTel Collector service requires admin rights" -ForegroundColor Yellow
Write-Host "[setup] Run .\scripts\verify-integration.ps1 to test the pipeline" -ForegroundColor Yellow
