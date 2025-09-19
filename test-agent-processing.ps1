# Test Agent Processing
Write-Host "Testing Agent Processing..." -ForegroundColor Green

# Check pending tasks
$pendingPath = ".agent\task_queue\pending"
$pendingTasks = Get-ChildItem "$pendingPath\*.json"

Write-Host "📋 Found $($pendingTasks.Count) pending tasks:" -ForegroundColor Yellow
foreach ($task in $pendingTasks) {
    Write-Host "  - $($task.Name)" -ForegroundColor Gray
}

# Test task reading
Write-Host "`n🔍 Testing task reading..." -ForegroundColor Cyan
foreach ($task in $pendingTasks) {
    try {
        $taskContent = Get-Content $task.FullName -Raw | ConvertFrom-Json
        Write-Host "✅ $($task.Name): $($taskContent.title)" -ForegroundColor Green
        Write-Host "   Recipe: $($taskContent.recipe), Priority: $($taskContent.priority)" -ForegroundColor Gray
    } catch {
        Write-Host "❌ $($task.Name): Error reading task" -ForegroundColor Red
    }
}

# Test validation scripts
Write-Host "`n🔧 Testing validation scripts..." -ForegroundColor Cyan

$validationScripts = @(
    "validation/validate-otlp-exporter.ps1",
    "validation/validate-tail-sampling.ps1", 
    "validation/validate-cardinality.ps1",
    "validation/validate-gpu-thermal.ps1"
)

foreach ($script in $validationScripts) {
    if (Test-Path $script) {
        Write-Host "✅ $script exists" -ForegroundColor Green
    } else {
        Write-Host "❌ $script not found" -ForegroundColor Red
    }
}

# Test collector dry-run
Write-Host "`n🔍 Testing collector dry-run..." -ForegroundColor Cyan
try {
    $dryRunOutput = & otelcol-contrib --config=config.yaml --dry-run 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Collector dry-run passed" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Collector dry-run issues: $dryRunOutput" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Collector dry-run failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎯 Agent processing test complete" -ForegroundColor Green


