# SigNoz Health Check Script
# Quick health verification for SigNoz containers and Windows Collector

Write-Host "== SigNoz containers ==" -ForegroundColor Cyan
try {
    docker ps --format 'table {{.Names}}\t{{.Ports}}' | Select-String 'signoz|otel'
} catch {
    Write-Host "Docker not available or no SigNoz containers running" -ForegroundColor Yellow
}

Write-Host "`n== Collector service ==" -ForegroundColor Cyan
try {
    sc query otelcol-contrib
} catch {
    Write-Host "Windows Collector service not found" -ForegroundColor Yellow
}

Write-Host "`n== Collector config (top) ==" -ForegroundColor Cyan
try {
    Get-Content -Path 'C:\otel\config.yaml' -TotalCount 60
} catch {
    Write-Host "Config file not found at C:\otel\config.yaml" -ForegroundColor Yellow
}

Write-Host "`n== SigNoz UI Health ==" -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 3
    Write-Host "SigNoz UI: Healthy" -ForegroundColor Green
} catch {
    Write-Host "SigNoz UI: Unreachable - $($_.Exception.Message)" -ForegroundColor Red
}
