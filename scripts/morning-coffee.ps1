# Morning Coffee Checklist - What happened while you slept?
Write-Host "☕ Morning Coffee Checklist" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

# 1) Check recent workflow runs
Write-Host "`n🔍 Recent Workflow Runs:" -ForegroundColor Yellow
gh run list --workflow "PR Guardrails" --limit 3
gh run list --workflow "Loose-Ends Tracker Sync" --limit 3

# 2) Check for failed runs
Write-Host "`n❌ Failed Runs (need attention):" -ForegroundColor Red
$failed = gh run list --conclusion failure --limit 5 --json databaseId,workflowName,createdAt
if ($failed -and $failed.Length -gt 0) {
    $failed | ForEach-Object { Write-Host "  - $($_.workflowName) failed at $($_.createdAt)" }
} else {
    Write-Host "  ✅ No failed runs! All systems green." -ForegroundColor Green
}

# 3) Check loose-ends progress
Write-Host "`n📊 Loose-Ends Tracker Status:" -ForegroundColor Cyan
if (Test-Path "artifacts/loose-ends-tracker.md") {
    $lines = Get-Content "artifacts/loose-ends-tracker.md" | Where-Object { $_ -match '^\|' }
    $rows = $lines | Select-Object -Skip 2 | ForEach-Object { ($_ -split '\|')[1..6].ForEach({$_.Trim()}) }
    $done = ($rows | Where-Object { $_[3] -eq 'Done' }).Count
    $prog = ($rows | Where-Object { $_[3] -eq 'In Progress' }).Count
    $ns   = ($rows | Where-Object { $_[3] -eq 'Not Started' }).Count
    $total = $rows.Count
    Write-Host "  Loose Ends: $total | Done:$done | In Progress:$prog | Not Started:$ns" -ForegroundColor White
} else {
    Write-Host "  ⚠️ Tracker file not found" -ForegroundColor Yellow
}

# 4) Latest ECRR status
Write-Host "`n📋 Latest ECRR:" -ForegroundColor Magenta
try {
    $ecrr = Get-Content "docs/ECRR_REPORTS/index.json" -Raw | ConvertFrom-Json
    if ($ecrr.Count -gt 0) {
        $x = $ecrr[0]
        Write-Host "  $($x.key) — $($x.outcome) — $($x.timestamp) — $($x.scope)" -ForegroundColor White
    } else {
        Write-Host "  (none)" -ForegroundColor Yellow
    }
} catch { 
    Write-Host "  (index missing)" -ForegroundColor Red
}

# 5) Check NAP_MODE status
Write-Host "`n😴 Nap Mode Status:" -ForegroundColor Blue
$nap = (gh variable list --limit 200 | Select-String 'NAP_MODE').ToString()
$napStatus = if ($nap -match 'true') {'ON'} else {'OFF'}
Write-Host "  NAP_MODE: $napStatus" -ForegroundColor $(if ($napStatus -eq 'ON') {'Yellow'} else {'Green'})

Write-Host "`n☕ Coffee checklist complete! Have a great day!" -ForegroundColor Green
