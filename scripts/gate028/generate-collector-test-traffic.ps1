# Gate #028 Track 28A: Traffic Generator for Collector Path Test
# Purpose: Generate HTTP requests to test app exporting to collector

param(
    [string]$Url = "http://localhost:5558/",
    [int]$Requests = 15,
    [int]$DelayMs = 500
)

Write-Host "=== Generating Traffic to Collector Test ===" -ForegroundColor Cyan
Write-Host "   Target: $Url" -ForegroundColor White
Write-Host "   Requests: $Requests" -ForegroundColor White
Write-Host ""

Start-Sleep -Seconds 3

for ($i = 1; $i -le $Requests; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
        Write-Host "Request $i/$Requests`: HTTP $($response.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "Request $i/$Requests`: Failed - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Start-Sleep -Milliseconds $DelayMs
}

Write-Host ""
Write-Host "✅ Traffic generation complete" -ForegroundColor Green
Write-Host "   Now run health probe: pwsh -File scripts\windows\verify-collector-traces.ps1" -ForegroundColor Yellow

