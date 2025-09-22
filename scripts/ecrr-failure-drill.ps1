# ECRR Canary Failure Drill - 60 Second Test
# Proves alert fires when canary stops, then resolves when restored

Write-Host "🧨 ECRR Canary Failure Drill - 60 Second Test" -ForegroundColor Yellow
Write-Host "This will pause the canary for 15 minutes to trigger the alert, then restore it." -ForegroundColor Cyan
Write-Host ""

# Check current status
Write-Host "📊 Current Status:" -ForegroundColor Green
$task = Get-ScheduledTask -TaskName 'OTel-ECRR-Canary' -ErrorAction SilentlyContinue
if ($task) {
    $info = Get-ScheduledTaskInfo -TaskName 'OTel-ECRR-Canary'
    Write-Host "  Last Run: $($info.LastRunTime)"
    Write-Host "  Next Run: $($info.NextRunTime)"
    Write-Host "  Missed Runs: $($info.NumberOfMissedRuns)"
} else {
    Write-Host "  ❌ Task 'OTel-ECRR-Canary' not found!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "⚠️  WARNING: This will trigger the 'ECRR Canary Missing' alert in SigNoz!" -ForegroundColor Red
$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Drill cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🛑 Step 1: Disabling canary task..." -ForegroundColor Yellow
Disable-ScheduledTask -TaskName "OTel-ECRR-Canary"
Write-Host "  ✅ Task disabled"

Write-Host ""
Write-Host "⏱️  Step 2: Waiting 15 minutes for alert to fire..." -ForegroundColor Yellow
Write-Host "  Monitor SigNoz at: http://localhost:8080/alerts" -ForegroundColor Cyan
Write-Host "  Query: service.name = 'ecrr-canary' AND attributes.canary.type = 'ecrr-enhanced'" -ForegroundColor Cyan
Write-Host "  Expected: Gap in logs, alert should fire after 15 minutes" -ForegroundColor Cyan

# Wait with countdown
$waitTime = 900 # 15 minutes
$startTime = Get-Date
while ($waitTime -gt 0) {
    $remaining = [TimeSpan]::FromSeconds($waitTime)
    Write-Host "  ⏳ Remaining: $($remaining.ToString('mm\:ss'))" -ForegroundColor Gray
    Start-Sleep -Seconds 60
    $waitTime -= 60
}

Write-Host ""
Write-Host "🔄 Step 3: Re-enabling canary task..." -ForegroundColor Yellow
Enable-ScheduledTask -TaskName "OTel-ECRR-Canary"
Start-ScheduledTask -TaskName "OTel-ECRR-Canary"
Write-Host "  ✅ Task enabled and triggered"

Write-Host ""
Write-Host "✅ Step 4: Verification" -ForegroundColor Green
Write-Host "  Check SigNoz Logs for new entries:" -ForegroundColor Cyan
Write-Host "  Query: message contains 'ECRR-Canary-Test'" -ForegroundColor Cyan
Write-Host "  Alert should resolve within 5 minutes" -ForegroundColor Cyan

Write-Host ""
Write-Host "🎯 Drill Complete!" -ForegroundColor Green
Write-Host "  - Alert should have fired during the 15-minute gap" -ForegroundColor White
Write-Host "  - Alert should resolve now that canary is restored" -ForegroundColor White
Write-Host "  - Check SigNoz UI to confirm end-to-end behavior" -ForegroundColor White

# Final status check
Start-Sleep -Seconds 30
Write-Host ""
Write-Host "📊 Final Status:" -ForegroundColor Green
$finalInfo = Get-ScheduledTaskInfo -TaskName 'OTel-ECRR-Canary'
Write-Host "  Last Run: $($finalInfo.LastRunTime)"
Write-Host "  Next Run: $($finalInfo.NextRunTime)"
Write-Host "  Missed Runs: $($finalInfo.NumberOfMissedRuns)"
