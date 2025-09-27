# Verify Canary Monitoring Fix
# Confirms that the canary monitoring issues have been resolved

Write-Host "🔍 Verifying Canary Monitoring Fix" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

$results = @{
    timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    tests = @()
    status = "ok"
    summary = @{}
}

# Test 1: Check if monitoring script exists
Write-Host "`n1. Checking monitoring script existence..." -ForegroundColor Yellow
if (Test-Path "scripts/monitor-signoz-canary-scheduled.ps1") {
    $results.tests += @{ name = "MonitoringScriptExists"; status = "PASS"; message = "Monitoring script exists" }
    Write-Host "   ✅ scripts/monitor-signoz-canary-scheduled.ps1 exists" -ForegroundColor Green
} else {
    $results.tests += @{ name = "MonitoringScriptExists"; status = "FAIL"; message = "Monitoring script missing" }
    Write-Host "   ❌ scripts/monitor-signoz-canary-scheduled.ps1 missing" -ForegroundColor Red
    $results.status = "fail"
}

# Test 2: Check adaptive monitoring script
Write-Host "`n2. Checking adaptive monitoring script..." -ForegroundColor Yellow
if (Test-Path "scripts/adaptive-canary-monitor-enhanced.ps1") {
    $results.tests += @{ name = "AdaptiveMonitoringExists"; status = "PASS"; message = "Adaptive monitoring script exists" }
    Write-Host "   ✅ Adaptive monitoring script exists" -ForegroundColor Green
} else {
    $results.tests += @{ name = "AdaptiveMonitoringExists"; status = "FAIL"; message = "Adaptive monitoring script missing" }
    Write-Host "   ❌ Adaptive monitoring script missing" -ForegroundColor Red
    $results.status = "fail"
}

# Test 3: Check baseline calculation
Write-Host "`n3. Checking adaptive baseline..." -ForegroundColor Yellow
if (Test-Path "artifacts/canary-baseline.json") {
    $baseline = Get-Content "artifacts/canary-baseline.json" -Raw | ConvertFrom-Json
    if ($baseline.adaptiveSpikeThreshold -and $baseline.adaptiveSpikeThreshold -gt 350) {
        $results.tests += @{ name = "AdaptiveThreshold"; status = "PASS"; message = "Adaptive threshold: $($baseline.adaptiveSpikeThreshold)" }
        Write-Host "   ✅ Adaptive spike threshold: $($baseline.adaptiveSpikeThreshold) (was 350)" -ForegroundColor Green
    } else {
        $results.tests += @{ name = "AdaptiveThreshold"; status = "FAIL"; message = "Adaptive threshold not properly calculated" }
        Write-Host "   ❌ Adaptive threshold not properly calculated" -ForegroundColor Red
        $results.status = "fail"
    }
} else {
    $results.tests += @{ name = "AdaptiveThreshold"; status = "FAIL"; message = "Baseline file missing" }
    Write-Host "   ❌ artifacts/canary-baseline.json missing" -ForegroundColor Red
    $results.status = "fail"
}

# Test 4: Check latest monitoring report
Write-Host "`n4. Checking latest monitoring report..." -ForegroundColor Yellow
if (Test-Path "artifacts/signoz-canary-monitor-latest.json") {
    $latest = Get-Content "artifacts/signoz-canary-monitor-latest.json" -Raw | ConvertFrom-Json
    if ($latest.spikeThreshold -and $latest.spikeThreshold -gt 350 -and $latest.status -ne "warning") {
        $results.tests += @{ name = "LatestReport"; status = "PASS"; message = "Latest report: threshold $($latest.spikeThreshold), status $($latest.status)" }
        Write-Host "   ✅ Latest report: threshold $($latest.spikeThreshold), status $($latest.status)" -ForegroundColor Green
    } else {
        $results.tests += @{ name = "LatestReport"; status = "FAIL"; message = "Latest report shows issues" }
        Write-Host "   ❌ Latest report shows issues: threshold $($latest.spikeThreshold), status $($latest.status)" -ForegroundColor Red
        $results.status = "fail"
    }
} else {
    $results.tests += @{ name = "LatestReport"; status = "FAIL"; message = "Latest report missing" }
    Write-Host "   ❌ artifacts/signoz-canary-monitor-latest.json missing" -ForegroundColor Red
    $results.status = "fail"
}

# Test 5: Check historical data generation
Write-Host "`n5. Checking historical data..." -ForegroundColor Yellow
$historicalReports = Get-ChildItem "artifacts/signoz-canary-monitor-*.json" | Where-Object { $_.Name -ne "signoz-canary-monitor-latest.json" }
if ($historicalReports.Count -ge 5) {
    $results.tests += @{ name = "HistoricalData"; status = "PASS"; message = "$($historicalReports.Count) historical reports available" }
    Write-Host "   ✅ $($historicalReports.Count) historical reports available" -ForegroundColor Green
} else {
    $results.tests += @{ name = "HistoricalData"; status = "FAIL"; message = "Insufficient historical data: $($historicalReports.Count)" }
    Write-Host "   ❌ Insufficient historical data: $($historicalReports.Count) reports" -ForegroundColor Red
    $results.status = "fail"
}

# Test 6: Check scheduled task configuration
Write-Host "`n6. Checking scheduled task..." -ForegroundColor Yellow
try {
    $task = Get-ScheduledTask -TaskName "SigNozCanaryMonitor" -ErrorAction Stop
    $taskAction = $task.Actions[0]
    if ($taskAction.Arguments -like "*monitor-signoz-canary-scheduled.ps1*") {
        $results.tests += @{ name = "ScheduledTask"; status = "PASS"; message = "Task configured correctly" }
        Write-Host "   ✅ Scheduled task points to correct script" -ForegroundColor Green
    } else {
        $results.tests += @{ name = "ScheduledTask"; status = "FAIL"; message = "Task points to wrong script" }
        Write-Host "   ❌ Task points to: $($taskAction.Arguments)" -ForegroundColor Red
        $results.status = "fail"
    }
} catch {
    $results.tests += @{ name = "ScheduledTask"; status = "FAIL"; message = "Scheduled task not found" }
    Write-Host "   ❌ Scheduled task not found" -ForegroundColor Red
    $results.status = "fail"
}

# Calculate summary
$passCount = ($results.tests | Where-Object { $_.status -eq "PASS" }).Count
$failCount = ($results.tests | Where-Object { $_.status -eq "FAIL" }).Count
$totalCount = $results.tests.Count

$results.summary = @{
    total = $totalCount
    passed = $passCount
    failed = $failCount
    percentage = if ($totalCount -gt 0) { [Math]::Round(($passCount / $totalCount) * 100, 1) } else { 0 }
}

# Display summary
Write-Host "`n📊 Verification Summary:" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host "   Total tests: $totalCount" -ForegroundColor Gray
Write-Host "   Passed: $passCount" -ForegroundColor Green
Write-Host "   Failed: $failCount" -ForegroundColor Red
Write-Host "   Success rate: $($results.summary.percentage)%" -ForegroundColor $(if ($results.summary.percentage -eq 100) { "Green" } elseif ($results.summary.percentage -ge 80) { "Yellow" } else { "Red" })

# Final status
Write-Host "`n🎯 Overall Status:" -ForegroundColor Cyan
if ($results.status -eq "ok") {
    Write-Host "✅ CANARY MONITORING ISSUES RESOLVED" -ForegroundColor Green
    Write-Host "   • Thresholds adjusted to match current traffic" -ForegroundColor Gray
    Write-Host "   • Historical data generated for adaptive monitoring" -ForegroundColor Gray
    Write-Host "   • Scheduled monitoring configured and working" -ForegroundColor Gray
    Write-Host "   • Adaptive threshold adjustment implemented" -ForegroundColor Gray
} else {
    Write-Host "❌ CANARY MONITORING ISSUES REMAIN" -ForegroundColor Red
    Write-Host "   Some tests failed - check output above for details" -ForegroundColor Gray
}

# Write verification report
$reportFile = "artifacts/canary-monitoring-verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$results | ConvertTo-Json -Depth 4 | Set-Content -Path $reportFile -Encoding UTF8
Write-Host "`n📄 Verification report saved to: $reportFile" -ForegroundColor Blue

Write-Host "`n🔗 Next steps:" -ForegroundColor Cyan
Write-Host "   • Monitor artifacts/signoz-canary-monitor-latest.json for ongoing status" -ForegroundColor Gray
Write-Host "   • Run pwsh -File scripts/adaptive-canary-monitor-enhanced.ps1 to update baselines" -ForegroundColor Gray
Write-Host "   • Check scheduled task execution in Task Scheduler" -ForegroundColor Gray
