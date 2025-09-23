# Steam Games Cleanup Script
# Provides commands to uninstall large Steam games

Write-Host "STEAM GAMES CLEANUP - MANUAL UNINSTALLATION REQUIRED" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "`nLarge Steam Games Identified:" -ForegroundColor Yellow
Write-Host "1. Oblivion Remastered: 106.67GB" -ForegroundColor Red
Write-Host "2. Marvel Rivals: 42.41GB total (multiple files)" -ForegroundColor Red
Write-Host "Total potential savings: ~149GB" -ForegroundColor Green

Write-Host "`n=== MANUAL UNINSTALLATION STEPS ===" -ForegroundColor White
Write-Host "1. Open Steam application" -ForegroundColor White
Write-Host "2. Go to Library tab" -ForegroundColor White
Write-Host "3. Find 'Oblivion Remastered' in your games list" -ForegroundColor White
Write-Host "4. Right-click on 'Oblivion Remastered'" -ForegroundColor White
Write-Host "5. Select 'Uninstall...'" -ForegroundColor White
Write-Host "6. Confirm uninstallation (this will free 106.67GB)" -ForegroundColor White

Write-Host "`n7. Find 'Marvel Rivals' in your games list" -ForegroundColor White
Write-Host "8. Right-click on 'Marvel Rivals'" -ForegroundColor White
Write-Host "9. Select 'Uninstall...'" -ForegroundColor White
Write-Host "10. Confirm uninstallation (this will free 42.41GB)" -ForegroundColor White

Write-Host "`n=== ALTERNATIVE: STEAM CONSOLE COMMANDS ===" -ForegroundColor Yellow
Write-Host "If you prefer command line, you can use Steam console:" -ForegroundColor White
Write-Host "1. Open Steam" -ForegroundColor White
Write-Host "2. Go to View → Settings → Interface" -ForegroundColor White
Write-Host "3. Check 'Enable Steam Console'" -ForegroundColor White
Write-Host "4. Press Ctrl+Alt+Shift+C to open console" -ForegroundColor White
Write-Host "5. Type: app_uninstall 22330 (for Oblivion Remastered)" -ForegroundColor White
Write-Host "6. Type: app_uninstall [Marvel Rivals App ID] (for Marvel Rivals)" -ForegroundColor White

Write-Host "`n=== VERIFICATION COMMANDS ===" -ForegroundColor Green
Write-Host "After uninstalling, run these commands to verify:" -ForegroundColor White
Write-Host "Get-WmiObject -Class Win32_LogicalDisk | Where-Object { `$_.DeviceID -eq 'C:' } | Select-Object DeviceID, @{Name='FreeGB';Expression={[math]::Round(`$_.FreeSpace/1GB,2)}}, @{Name='UsedPercent';Expression={[math]::Round(((`$_.Size-`$_.FreeSpace)/`$_.Size)*100,1)}}" -ForegroundColor Gray

Write-Host "`n=== EXPECTED RESULTS ===" -ForegroundColor Cyan
Write-Host "Current usage: 93.3% (868.56GB used)" -ForegroundColor White
Write-Host "After Steam cleanup: ~70-75% (650-700GB used)" -ForegroundColor Green
Write-Host "Free space after cleanup: ~230-280GB" -ForegroundColor Green

Write-Host "`n=== TRACEABILITY ===" -ForegroundColor Magenta
Write-Host "This cleanup is logged in: docs/DISK_CLEANUP_TRACEABILITY_LOG.md" -ForegroundColor White
Write-Host "Games can be re-downloaded from Steam library if needed" -ForegroundColor White
Write-Host "No data loss risk - games are tied to Steam account" -ForegroundColor White

Write-Host "`nSteam games cleanup guide complete!" -ForegroundColor Green
Write-Host "Execute the manual steps above to free up ~149GB" -ForegroundColor Yellow
