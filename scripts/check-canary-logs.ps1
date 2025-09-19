#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

Write-Host "[canary-check] Checking for recent canary logs in SigNoz" -ForegroundColor Green

# Check if SigNoz UI is accessible
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -ne 200) {
        Write-Host "[canary-check] ERROR SigNoz UI not accessible (Status: $($response.StatusCode))" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[canary-check] ERROR Cannot reach SigNoz UI: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "[canary-check] OK SigNoz UI is accessible" -ForegroundColor Green

# Instructions for manual check
Write-Host "`n[canary-check] Manual verification steps:" -ForegroundColor Yellow
Write-Host "1. Open browser to: http://localhost:8080" -ForegroundColor Cyan
Write-Host "2. Navigate to: Logs" -ForegroundColor Cyan
Write-Host "3. Add filter: log.body contains `"windows-canary`"" -ForegroundColor Cyan
Write-Host "4. Look for recent entries (last 15 minutes)" -ForegroundColor Cyan
Write-Host "5. Check timestamp matches recent verification runs" -ForegroundColor Cyan

# Check if we can query logs via API (if available)
Write-Host "`n[canary-check] Attempting API query..." -ForegroundColor Yellow
try {
    # This is a basic check - actual SigNoz API may require authentication
    $logQuery = @{
        query = 'log.body contains "windows-canary"'
        start = (Get-Date).AddMinutes(-30).ToString("o")
        end = (Get-Date).ToString("o")
    } | ConvertTo-Json
    
    $apiResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method Post -Body $logQuery -ContentType "application/json" -TimeoutSec 10
    Write-Host "[canary-check] OK API query successful" -ForegroundColor Green
    Write-Host "[canary-check] Found $($apiResponse.data.length) canary logs" -ForegroundColor Green
} catch {
    Write-Host "[canary-check] INFO API query not available, use manual UI check" -ForegroundColor Yellow
}

Write-Host "`n[canary-check] Check complete" -ForegroundColor Green
