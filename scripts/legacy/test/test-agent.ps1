# Test Agent Script
Write-Host "Testing agent system..." -ForegroundColor Green

# Check task queue structure
$taskQueuePath = ".agent\task_queue"
if (Test-Path $taskQueuePath) {
    Write-Host "✅ Task queue directory exists" -ForegroundColor Green
    
    $pendingPath = "$taskQueuePath\pending"
    if (Test-Path $pendingPath) {
        $tasks = Get-ChildItem "$pendingPath\*.json"
        Write-Host "📋 Found $($tasks.Count) pending tasks" -ForegroundColor Yellow
        
        foreach ($task in $tasks) {
            Write-Host "  - $($task.Name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "❌ Pending directory not found" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Task queue directory not found" -ForegroundColor Red
}

Write-Host "Test complete" -ForegroundColor Green


