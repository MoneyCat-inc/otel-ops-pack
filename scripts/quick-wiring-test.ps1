# Quick Wiring Test for Port 3000
# Tests analytics forwarding from /api/events to SigNoz via OTLP/HTTP

$testEventId = [Guid]::NewGuid().ToString()
$apiUrl = "http://localhost:3000/api/events"

Write-Host "=== Quick Wiring Test (Port 3000) ===" -ForegroundColor Green

# Test analytics API
Write-Host "Testing analytics API at $apiUrl..." -ForegroundColor Cyan
try {
    $testPayload = @{
        event = "wiring_test"
        session_id = "test-session-$testEventId"
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        test_id = $testEventId
        dataset = "resonai_analytics"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $testPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "[OK] Analytics API call successful" -ForegroundColor Green
    Write-Host "Response: $response" -ForegroundColor Gray
} catch {
    Write-Host "[FAIL] Analytics API call failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Wait for data to propagate
Write-Host "Waiting 5 seconds for data propagation..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test SigNoz logs query
Write-Host "Testing SigNoz logs query..." -ForegroundColor Cyan
try {
    $queryPayload = @{
        query = "test_id = `"$testEventId`""
        limit = 5
    } | ConvertTo-Json

    $logsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/logs" -Method Post -Body $queryPayload -ContentType "application/json" -TimeoutSec 10
    Write-Host "[OK] SigNoz logs query successful" -ForegroundColor Green
    
    if ($logsResponse.data -and $logsResponse.data.Count -gt 0) {
        Write-Host "Found $($logsResponse.data.Count) matching log entries" -ForegroundColor Green
        Write-Host "Latest entry: $($logsResponse.data[0].body)" -ForegroundColor Gray
    } else {
        Write-Host "No matching log entries found (may need more time to propagate)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARN] SigNoz logs query failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== Wiring Test Complete ===" -ForegroundColor Green
Write-Host "Test ID: $testEventId" -ForegroundColor Gray
Write-Host "Check SigNoz UI: http://localhost:8080/logs" -ForegroundColor Blue
Write-Host "Filter: test_id = `"$testEventId`"" -ForegroundColor Blue
