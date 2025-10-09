#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Write-Host "[stop-all] Stopping OTel Windows → SigNoz Kit" -ForegroundColor Yellow

# Stop Windows OTel Collector service
Write-Host "[stop-all] Stopping Windows OTel Collector service..." -ForegroundColor Yellow
try {
    Stop-Service -Name "otelcol-contrib" -Force -ErrorAction SilentlyContinue
    Write-Host "[stop-all] ✓ Windows OTel Collector service stopped" -ForegroundColor Green
} catch {
    Write-Host "[stop-all] ⚠ Windows OTel Collector service stop failed: $_" -ForegroundColor Yellow
}

# Stop Docker stack
Write-Host "[stop-all] Stopping SigNoz Docker stack..." -ForegroundColor Yellow
$composeFile = Join-Path $PSScriptRoot "..\docker-compose.yml"
docker compose -f $composeFile down

if ($LASTEXITCODE -ne 0) {
    Write-Host "[stop-all] ✗ Failed to stop Docker stack" -ForegroundColor Red
    exit 1
}

Write-Host "[stop-all] ✓ All services stopped successfully!" -ForegroundColor Green