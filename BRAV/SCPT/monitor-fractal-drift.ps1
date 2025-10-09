# Fractal Drift Monitoring Script
# Provides ongoing monitoring of Hurst exponent patterns

Write-Host "🔍 Fractal Drift Monitoring Dashboard" -ForegroundColor Cyan
Write-Host "🎭 Actor: Cursor-Local (Observability Copilot)" -ForegroundColor Yellow

# Check for recent pattern results
Write-Host "
📊 Recent Pattern Analysis:" -ForegroundColor Green
$RecentResults = Get-ChildItem "artifacts\canary-pattern-results.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($RecentResults) {
    $Age = (Get-Date) - $RecentResults.LastWriteTime
    Write-Host "  Latest Results: $($RecentResults.Name) ($($Age.TotalHours.ToString('F1')) hours ago)" -ForegroundColor White
    
    $Results = Get-Content $RecentResults.FullName -Raw | ConvertFrom-Json
    Write-Host "
  Pattern Analysis:" -ForegroundColor Cyan
    
    foreach ($Pattern in $Results.pattern_results) {
        $Hurst = $Pattern.hurst_estimate
        $Status = if ($Hurst -lt 0.3) { "Anti-persistent" } 
                  elseif ($Hurst -gt 0.7) { "Persistent (ALERT)" } 
                  elseif ($Hurst -gt 0.6) { "Slightly Persistent" }
                  else { "Normal" }
        
        Write-Host "    $($Pattern.pattern): H=$Hurst ($Status)" -ForegroundColor White
    }
} else {
    Write-Host "  ⚠️ No recent pattern results found" -ForegroundColor Yellow
}

# Check alert status (manual verification needed)
Write-Host "
🚨 Alert Status Check:" -ForegroundColor Yellow
Write-Host "  Manual verification required in SigNoz UI:" -ForegroundColor White
Write-Host "  1. Navigate to http://localhost:8080/alerts" -ForegroundColor White
Write-Host "  2. Check 'Hurst Exponent Drift Alert' status" -ForegroundColor White
Write-Host "  3. Verify threshold: H > 0.7" -ForegroundColor White

Write-Host "
📈 Monitoring Recommendations:" -ForegroundColor Green
Write-Host "  1. Run daily pattern drills for baseline data" -ForegroundColor White
Write-Host "  2. Monitor for H > 0.7 (persistent behavior)" -ForegroundColor White
Write-Host "  3. Investigate H < 0.3 (anti-persistent behavior)" -ForegroundColor White
Write-Host "  4. Track long-term trends in Hurst values" -ForegroundColor White

Write-Host "
🎯 Next Actions:" -ForegroundColor Cyan
Write-Host "  - Run pattern drills: pwsh -File scripts/canary-pattern-drills.ps1" -ForegroundColor White
Write-Host "  - Check alert: pwsh -File scripts/verify-hurst-drift-alert.ps1" -ForegroundColor White
Write-Host "  - View dashboard: http://localhost:8080/dashboards" -ForegroundColor White
