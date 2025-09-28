# Test SigNoz Logs Query Script
# Query SigNoz for Windows canary logs

param(
    [string]$SigNozUrl = "http://localhost:8080"
)

Write-Host "=== Testing SigNoz Logs Query ===" -ForegroundColor Green

try {
    # Test query for canary logs
    $queryPayload = @{
        query = 'log.file.path = "C:/logs/windows-canary-test.log" AND body contains "windows-canary"'
        limit = 10
        start = (Get-Date).AddMinutes(-15).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        end = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }
    
    Write-Host "Query: $($queryPayload.query)" -ForegroundColor Yellow
    Write-Host "Time range: Last 15 minutes" -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri "$SigNozUrl/api/v1/logs" -Method Post -Body ($queryPayload | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10
    
    Write-Host "`n✅ SigNoz Query Successful!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 4
    
    if ($response.logs -and $response.logs.Count -gt 0) {
        Write-Host "`n📊 Found $($response.logs.Count) canary log entries" -ForegroundColor Green
        Write-Host "Sample log entry:" -ForegroundColor Yellow
        $response.logs[0] | ConvertTo-Json -Depth 3
    } else {
        Write-Host "`n⚠️ No canary logs found in SigNoz" -ForegroundColor Yellow
        Write-Host "This might be due to:" -ForegroundColor Gray
        Write-Host "- Time range too narrow" -ForegroundColor Gray
        Write-Host "- Logs still being processed" -ForegroundColor Gray
        Write-Host "- Different field names in SigNoz" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "❌ SigNoz query failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Gray
}

Write-Host "`n=== Manual Verification Steps ===" -ForegroundColor Cyan
Write-Host "1. Open SigNoz UI: $SigNozUrl" -ForegroundColor White
Write-Host "2. Go to Logs section" -ForegroundColor White
Write-Host "3. Set time range to 'Last 15 minutes'" -ForegroundColor White
Write-Host "4. Clear all filters" -ForegroundColor White
Write-Host "5. Add filter: log.file.path = 'C:/logs/windows-canary-test.log'" -ForegroundColor White
Write-Host "6. Add quick search: body contains 'windows-canary'" -ForegroundColor White
Write-Host "7. Click Apply" -ForegroundColor White

Write-Host "`n=== Alternative Query ===" -ForegroundColor Cyan
Write-Host "Try this query in SigNoz Logs:" -ForegroundColor White
Write-Host "log.file.path = 'C:/logs/windows-canary-test.log' AND body contains 'windows-canary'" -ForegroundColor Gray
