# Daily Pattern Drills Verification Script
# Verifies the automated daily pattern drills are working correctly

Write-Host "🔍 Verifying Daily Pattern Drills Automation..." -ForegroundColor Cyan

# Check if task exists
$Task = Get-ScheduledTask -TaskName "Daily Canary Pattern Drills" -ErrorAction SilentlyContinue
if (-not $Task) {
    Write-Host "❌ Scheduled task not found" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Scheduled task exists" -ForegroundColor Green

# Check task configuration
Write-Host "📋 Task Configuration:" -ForegroundColor Cyan
Write-Host "  State: $($Task.State)" -ForegroundColor White
Write-Host "  Last Run: $($Task.LastRunTime)" -ForegroundColor White
Write-Host "  Next Run: $($Task.NextRunTime)" -ForegroundColor White

# Check if artifacts directory exists
if (-not (Test-Path "artifacts")) {
    Write-Host "⚠️ Artifacts directory not found" -ForegroundColor Yellow
} else {
    Write-Host "✅ Artifacts directory exists" -ForegroundColor Green
}

# Check for recent results
$RecentResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($RecentResults) {
    $Age = (Get-Date) - $RecentResults.LastWriteTime
    Write-Host "📊 Latest Results: $($RecentResults.Name) ($($Age.TotalHours.ToString('F1')) hours ago)" -ForegroundColor White
    
    if ($Age.TotalHours -lt 25) {
        Write-Host "✅ Recent results found" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Results are older than 25 hours" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️ No pattern drill results found" -ForegroundColor Yellow
}

Write-Host "🎯 Verification Complete!" -ForegroundColor Green
