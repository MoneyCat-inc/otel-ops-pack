#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Write-Host "[start-all] Starting OTel Windows → SigNoz Kit" -ForegroundColor Green

# Start Docker stack
Write-Host "[start-all] Starting SigNoz Docker stack..." -ForegroundColor Yellow
$composeFile = Join-Path $PSScriptRoot "..\docker-compose.yml"
docker compose -f $composeFile up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "[start-all] ✗ Failed to start Docker stack" -ForegroundColor Red
    exit 1
}

# Wait for services to be ready
Write-Host "[start-all] Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Start Windows OTel Collector service
Write-Host "[start-all] Starting Windows OTel Collector service..." -ForegroundColor Yellow
try {
    Start-Service -Name "otelcol-contrib" -ErrorAction Stop
    Write-Host "[start-all] ✓ Windows OTel Collector service started" -ForegroundColor Green
} catch {
    Write-Host "[start-all] ✗ Failed to start Windows OTel Collector service: $_" -ForegroundColor Red
    exit 1
}

Write-Host "[start-all] ✓ All services started successfully!" -ForegroundColor Green
Write-Host "[start-all] SigNoz UI: http://localhost:8080" -ForegroundColor Cyan
Write-Host "[start-all] Run .\scripts\verify-integration.ps1 to verify the pipeline" -ForegroundColor Yellow