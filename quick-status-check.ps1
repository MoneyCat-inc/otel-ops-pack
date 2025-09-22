# Quick Status Check for Parallel Validation
# Lightweight script to check key validation metrics

Write-Host "🔍 Quick Validation Status Check" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check if background monitor is running
$monitorProcess = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*monitor-ci-background.ps1*"
}

if ($monitorProcess) {
    Write-Host "✅ Background Monitor: RUNNING (PID: $($monitorProcess.Id))" -ForegroundColor Green
} else {
    Write-Host "⚠️  Background Monitor: NOT DETECTED" -ForegroundColor Yellow
}

# Quick CI run check
try {
    $latestRun = gh run list --limit 1 --json status,conclusion,displayTitle | ConvertFrom-Json
    if ($latestRun) {
        $status = if ($latestRun.status -eq "completed") { $latestRun.conclusion.ToUpper() } else { $latestRun.status.ToUpper() }
        $color = switch ($status) {
            "SUCCESS" { "Green" }
            "FAILURE" { "Red" }
            "CANCELLED" { "Yellow" }
            "RUNNING" { "Cyan" }
            default { "White" }
        }
        Write-Host "✅ Latest CI Run: $status - $($latestRun.displayTitle)" -ForegroundColor $color
    }
} catch {
    Write-Host "❌ CI Status: ERROR" -ForegroundColor Red
}

# Quick PR check
try {
    $testPR = gh pr list --json number,state,headRefName | ConvertFrom-Json | Where-Object { $_.headRefName -eq "test-queue-behavior" }
    if ($testPR) {
        Write-Host "✅ Test PR: #$($testPR.number) ($($testPR.state))" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Test PR: NOT FOUND" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ PR Status: ERROR" -ForegroundColor Red
}

# Quick file check
if (Test-Path "test-reviewdog.js") {
    Write-Host "✅ Reviewdog Test: DEPLOYED" -ForegroundColor Green
} else {
    Write-Host "❌ Reviewdog Test: MISSING" -ForegroundColor Red
}

Write-Host "`n🔄 Run 'pwsh -File monitor-parallel-validation.ps1' for detailed status" -ForegroundColor Yellow