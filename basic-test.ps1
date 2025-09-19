# Basic System Test
Write-Host "Testing System..." -ForegroundColor Green

# Check collector health
try {
    $response = Invoke-RestMethod -Uri "http://localhost:13134/" -Method Get -TimeoutSec 5
    Write-Host "Collector Status: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "Collector Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check SigNoz UI
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5
    Write-Host "SigNoz Status: $($response.status)" -ForegroundColor Green
} catch {
    Write-Host "SigNoz Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check metrics
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8888/metrics" -Method Get -TimeoutSec 5
    $otelLines = $response -split "`n" | Where-Object { $_ -match "otelcol_" }
    Write-Host "Metrics Count: $($otelLines.Count)" -ForegroundColor Green
} catch {
    Write-Host "Metrics Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check pending tasks
$pendingTasks = Get-ChildItem ".agent\task_queue\pending\*.json" -ErrorAction SilentlyContinue
Write-Host "Pending Tasks: $($pendingTasks.Count)" -ForegroundColor Green

Write-Host "Test Complete" -ForegroundColor Green


