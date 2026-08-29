# Simple Validation Status Check
# Run this periodically to check progress

Write-Host "🔍 Validation Status Check - $(Get-Date)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Check background monitor
$monitor = Get-Process -Name "pwsh" -ErrorAction SilentlyContinue | Where-Object { 
    $_.CommandLine -like "*monitor-ci-background*" 
}

if ($monitor) {
    Write-Host "✅ Background Monitor: RUNNING (PID: $($monitor.Id))" -ForegroundColor Green
} else {
    Write-Host "⚠️  Background Monitor: NOT DETECTED" -ForegroundColor Yellow
}

# 2. Check recent CI runs
Write-Host "`n📊 Recent CI Runs:" -ForegroundColor Yellow
try {
    $runs = gh run list --limit 3 --json status,conclusion,displayTitle | ConvertFrom-Json
    $runs | ForEach-Object {
        $status = if ($_.status -eq "completed") { $_.conclusion.ToUpper() } else { $_.status.ToUpper() }
        $color = switch ($status) {
            "SUCCESS" { "Green" }
            "FAILURE" { "Red" }
            "CANCELLED" { "Yellow" }
            "RUNNING" { "Cyan" }
            default { "White" }
        }
        Write-Host "  $status - $($_.displayTitle)" -ForegroundColor $color
    }
} catch {
    Write-Host "❌ Error checking CI runs" -ForegroundColor Red
}

# 3. Check test PR
Write-Host "`n📋 Test PR Status:" -ForegroundColor Yellow
try {
    $pr = gh pr list --json number,state,headRefName | ConvertFrom-Json | Where-Object { $_.headRefName -eq "test-queue-behavior" }
    if ($pr) {
        Write-Host "✅ Test PR: #$($pr.number) ($($pr.state))" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Test PR: NOT FOUND" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error checking PR" -ForegroundColor Red
}

# 4. Check test files
if (Test-Path "test-reviewdog.js") {
    Write-Host "✅ Reviewdog Test: DEPLOYED" -ForegroundColor Green
} else {
    Write-Host "❌ Reviewdog Test: MISSING" -ForegroundColor Red
}

Write-Host "`n🔄 Run this script again to check progress" -ForegroundColor Gray
