# Gate #027 Track 27B: Traffic Generator
# Purpose: Generate HTTP requests to services for telemetry verification

param(
    [int]$Requests = 20,
    [int]$DelayMs = 300
)

$services = @(
    @{ Name = "Service #2 (bosscat-svc2-api)"; Url = "http://localhost:5556/" },
    @{ Name = "Service #3 (bosscat-svc3-worker)"; Url = "http://localhost:5557/" }
)

Write-Host "=== Generating Traffic to Services ===" -ForegroundColor Cyan
Write-Host ""

foreach ($svc in $services) {
    Write-Host "Testing $($svc.Name): $($svc.Url)" -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri $svc.Url -UseBasicParsing -TimeoutSec 5
        Write-Host "   ✅ Service responding (HTTP $($response.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Service not ready: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Generating $Requests requests per service..." -ForegroundColor Cyan

for ($i = 1; $i -le $Requests; $i++) {
    foreach ($svc in $services) {
        try {
            $null = Invoke-WebRequest -Uri $svc.Url -UseBasicParsing -TimeoutSec 5
        } catch {
            # Silent fail - services may still be starting
        }
    }
    Write-Host "   Batch $i/$Requests complete" -ForegroundColor Gray
    Start-Sleep -Milliseconds $DelayMs
}

Write-Host ""
Write-Host "✅ Traffic generation complete" -ForegroundColor Green
Write-Host "   Wait 30 seconds, then check SigNoz for new services" -ForegroundColor Yellow

