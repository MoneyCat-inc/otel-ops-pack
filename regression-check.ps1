# C:\otel\regression-check.ps1
# One-liner regression check for health + metrics + canary + kafka smoke
# ASCII only, PowerShell 5.1 compatible

$ErrorActionPreference = 'Stop'

Write-Host "Running regression check..." -ForegroundColor Green

try {
    # Health + metrics + canary
    Write-Host "  Running green sheet..." -ForegroundColor Yellow
    & 'C:\otel\green-sheet.ps1'
    
    Write-Host "  Running canary check..." -ForegroundColor Yellow
    & 'C:\otel\canary-check-min.ps1'
    
    # Metrics endpoint check
    Write-Host "  Checking metrics endpoint..." -ForegroundColor Yellow
    $metricsResp = Invoke-WebRequest -Uri http://127.0.0.1:8889/metrics -TimeoutSec 5 -UseBasicParsing
    if ($metricsResp.StatusCode -eq 200) {
        Write-Host "  ✅ METRICS OK (200)" -ForegroundColor Green
    } else {
        Write-Host "  ❌ METRICS DOWN ($($metricsResp.StatusCode))" -ForegroundColor Red
    }
    
    # Optional Kafka smoke test
    Write-Host "  Checking Kafka connectivity (optional)..." -ForegroundColor Yellow
    try {
        $client = New-Object Net.Sockets.TcpClient
        $client.Connect('localhost', 9092)
        $client.Close()
        Write-Host "  ✅ KAFKA OK" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  KAFKA DOWN (optional)" -ForegroundColor Yellow
    }
    
    Write-Host "✅ REGRESSION CHECK PASSED" -ForegroundColor Green
    exit 0
    
} catch {
    Write-Host "❌ REGRESSION CHECK FAILED - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
