# Test GPUS Command Components
Write-Host "=== Testing GPUS Command Components ===" -ForegroundColor Cyan

Write-Host "`n1. Testing GPU Sidecar Health Check..." -ForegroundColor Yellow
try {
    $result = python scripts\check-gpu-sidecars.py 2>&1
    Write-Host "Result: $result" -ForegroundColor White
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "`n2. Testing GPU Metrics Emitter..." -ForegroundColor Yellow
try {
    $result = python scripts\gpu-metrics-emitter.py 2>&1
    Write-Host "Result: $result" -ForegroundColor White
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "`n3. Testing Docker GPU Containers..." -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}" | findstr gpu

Write-Host "`n4. Testing OTel Pipeline..." -ForegroundColor Yellow
try {
    $result = python scripts\otel_synthetic_ping.py 2>&1
    Write-Host "Result: $result" -ForegroundColor White
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

Write-Host "`n=== GPUS Command Test Complete ===" -ForegroundColor Green
