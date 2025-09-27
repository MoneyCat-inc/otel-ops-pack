# Simple test to show duration estimates and progress bars
# This will demonstrate the enhanced progress display

# Import animation functions
. "$PSScriptRoot/waiting-animations.ps1"

Write-Host "⏱️  Duration Estimates Test" -ForegroundColor Yellow
Write-Host "=" * 40 -ForegroundColor Gray
Write-Host ""

# Test 1: Show duration estimate
Write-Host "📊 Duration Estimates:" -ForegroundColor Cyan
$operations = @("npm_lint", "service_check", "api_test", "e2e_verification", "data_processing")
foreach ($op in $operations) {
    $duration = Get-DurationEstimate -operationType $op
    Write-Host "   $op`: $duration seconds" -ForegroundColor White
}
Write-Host ""

# Test 2: Show progress bar with duration
Write-Host "🎬 Progress Bar Demo (5 seconds):" -ForegroundColor Cyan
Write-Host ""

# Simulate a 5-second operation with progress updates
$totalDuration = 5
$startTime = Get-Date
$frame = 0
$chars = @(".", "..", "...", "")

Write-Host "Starting 5-second operation..." -ForegroundColor White
Write-Host ""

while ($true) {
    $now = Get-Date
    $elapsed = [math]::Round(($now - $startTime).TotalSeconds, 1)
    
    if ($elapsed -ge $totalDuration) {
        break
    }
    
    $progress = [math]::Round(($elapsed / $totalDuration) * 100)
    $remaining = [math]::Max(0, $totalDuration - $elapsed)
    $progressBar = "█" * [math]::Floor($progress / 10) + "░" * (10 - [math]::Floor($progress / 10))
    $char = $chars[$frame % $chars.Length]
    
    Write-Host "`r$char Processing... [$progressBar] $progress% ($elapsed/$totalDuration s, ~$remaining s left)" -NoNewline -ForegroundColor Cyan
    
    $frame++
    Start-Sleep -Milliseconds 200
}

Write-Host "`r✅ Processing completed! [████████████] 100% (5.0/5 s, ~0 s left)" -ForegroundColor Green
Write-Host ""

Write-Host "🎉 Duration estimates and progress bars working!" -ForegroundColor Green
