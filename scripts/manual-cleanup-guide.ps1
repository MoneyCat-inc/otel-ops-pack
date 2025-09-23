# Manual Cleanup Guide Script
# Provides specific commands to free up space

Write-Host "MANUAL DISK CLEANUP GUIDE" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan

# Check current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-Host "Current Disk Usage: $usedSpace GB / $totalSpace GB ($usagePercent%)" -ForegroundColor Yellow
Write-Host "Target: Free up 80+ GB to get below 85%" -ForegroundColor Green

Write-Host "`n=== IMMEDIATE ACTIONS ===" -ForegroundColor Red
Write-Host "1. Open File Explorer and navigate to these locations:" -ForegroundColor White
Write-Host "   - C:\Program Files (x86) (383GB - biggest opportunity)" -ForegroundColor Yellow
Write-Host "   - C:\Users\[YourName] (106GB - second biggest)" -ForegroundColor Yellow
Write-Host "   - C:\TOOLS (64GB - already partially cleaned)" -ForegroundColor Yellow

Write-Host "`n2. Look for these common space hogs:" -ForegroundColor White
Write-Host "   - Visual Studio (20-50GB)" -ForegroundColor Gray
Write-Host "   - Adobe Creative Suite (10-30GB)" -ForegroundColor Gray
Write-Host "   - Games (Steam, Epic, Origin)" -ForegroundColor Gray
Write-Host "   - Development tools (Android Studio, IntelliJ)" -ForegroundColor Gray
Write-Host "   - Old software versions" -ForegroundColor Gray

Write-Host "`n3. Use these PowerShell commands to find large files:" -ForegroundColor White
Write-Host "   Get-ChildItem 'C:\Program Files (x86)' -Recurse -File | Where-Object { `$_.Length -gt 1GB } | Sort-Object Length -Descending | Select-Object -First 10" -ForegroundColor Gray

Write-Host "`n4. Uninstall unused software:" -ForegroundColor White
Write-Host "   - Open Settings → Apps → Apps & features" -ForegroundColor Gray
Write-Host "   - Sort by Size (largest first)" -ForegroundColor Gray
Write-Host "   - Uninstall large, unused programs" -ForegroundColor Gray

Write-Host "`n5. Clean user directories:" -ForegroundColor White
Write-Host "   - Downloads folder (clear old files)" -ForegroundColor Gray
Write-Host "   - Documents (archive old projects)" -ForegroundColor Gray
Write-Host "   - Pictures/Videos (move to external storage)" -ForegroundColor Gray

Write-Host "`n=== AUTOMATED CLEANUP COMMANDS ===" -ForegroundColor Green
Write-Host "Run these commands one by one:" -ForegroundColor White

Write-Host "`n# Clean temp files" -ForegroundColor Yellow
Write-Host "Get-ChildItem `$env:TEMP -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue" -ForegroundColor Gray

Write-Host "`n# Clean Windows temp" -ForegroundColor Yellow
Write-Host "Get-ChildItem 'C:\Windows\Temp' -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue" -ForegroundColor Gray

Write-Host "`n# Clean browser caches" -ForegroundColor Yellow
Write-Host "Get-ChildItem `"`$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache`" -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue" -ForegroundColor Gray

Write-Host "`n# Clean Windows Update cache" -ForegroundColor Yellow
Write-Host "Stop-Service wuauserv -Force; Get-ChildItem 'C:\Windows\SoftwareDistribution' -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Start-Service wuauserv" -ForegroundColor Gray

Write-Host "`n# Find largest files" -ForegroundColor Yellow
Write-Host "Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue | Where-Object { `$_.Length -gt 1GB } | Sort-Object Length -Descending | Select-Object -First 20" -ForegroundColor Gray

Write-Host "`n=== EXPECTED RESULTS ===" -ForegroundColor Cyan
Write-Host "Target: Reduce usage from 93.4% to below 85%" -ForegroundColor White
Write-Host "Need to free: ~80GB minimum" -ForegroundColor White
Write-Host "Realistic target: 70-80% usage (650-740GB used)" -ForegroundColor White

Write-Host "`n=== EMERGENCY ACTIONS ===" -ForegroundColor Red
Write-Host "If disk fills completely:" -ForegroundColor White
Write-Host "1. Delete temp files immediately" -ForegroundColor Gray
Write-Host "2. Move large files to external storage" -ForegroundColor Gray
Write-Host "3. Uninstall largest unused software" -ForegroundColor Gray
Write-Host "4. Consider disk expansion" -ForegroundColor Gray

Write-Host "`nManual cleanup guide complete!" -ForegroundColor Green
Write-Host "Start with Program Files (x86) - it's your biggest opportunity!" -ForegroundColor Yellow
