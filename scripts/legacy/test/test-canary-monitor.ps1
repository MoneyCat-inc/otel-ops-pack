# Test Canary Monitor Functionality
Write-Host "Testing Canary Monitor..." -ForegroundColor Green

# Test 1: Check if canary monitor script exists
if (Test-Path "canary-monitor.ps1") {
    Write-Host "✅ Canary monitor script exists" -ForegroundColor Green
} else {
    Write-Host "❌ Canary monitor script not found" -ForegroundColor Red
    exit 1
}

# Test 2: Check task queue structure
$taskQueuePath = ".agent\task_queue"
if (Test-Path $taskQueuePath) {
    Write-Host "✅ Task queue directory exists" -ForegroundColor Green
    
    $pendingPath = "$taskQueuePath\pending"
    if (Test-Path $pendingPath) {
        Write-Host "✅ Pending directory exists" -ForegroundColor Green
    } else {
        Write-Host "❌ Pending directory not found" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Task queue directory not found" -ForegroundColor Red
}

# Test 3: Check existing tasks
$pendingTasks = Get-ChildItem "$taskQueuePath\pending\*.json" -ErrorAction SilentlyContinue
Write-Host "📋 Found $($pendingTasks.Count) pending tasks" -ForegroundColor Yellow

foreach ($task in $pendingTasks) {
    Write-Host "  - $($task.Name)" -ForegroundColor Gray
}

# Test 4: Check system health (simplified)
Write-Host "`n🔍 Checking system health..." -ForegroundColor Cyan

# Check SigNoz UI
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health" -Method Get -TimeoutSec 5
    if ($response.status -eq "ok") {
        Write-Host "✅ SigNoz UI healthy" -ForegroundColor Green
    } else {
        Write-Host "⚠️  SigNoz UI: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ SigNoz UI unreachable: $($_.Exception.Message)" -ForegroundColor Red
}

# Check OTEL Collector
try {
    $response = Invoke-RestMethod -Uri "http://localhost:13134/" -Method Get -TimeoutSec 5
    if ($response.status -eq "Server available") {
        Write-Host "✅ OTEL Collector healthy" -ForegroundColor Green
    } else {
        Write-Host "⚠️  OTEL Collector: $($response.status)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ OTEL Collector unreachable: $($_.Exception.Message)" -ForegroundColor Red
}

# Check log files
$logFile = "C:\logs\canary-test.log"
if (Test-Path $logFile) {
    $lastWrite = (Get-Item $logFile).LastWriteTime
    $ageMinutes = ((Get-Date) - $lastWrite).TotalMinutes
    Write-Host "✅ Log file exists (age: $([math]::Round($ageMinutes, 1)) minutes)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Log file not found" -ForegroundColor Yellow
}

Write-Host "`n🎯 Canary monitor test complete" -ForegroundColor Green


