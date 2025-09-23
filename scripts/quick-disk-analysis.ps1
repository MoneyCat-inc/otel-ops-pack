# Quick Disk Analysis - Simple and Direct
# Shows what's taking up space in Program Files (x86)

Write-Host "Quick Disk Analysis - Program Files (x86)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# Current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-Host "Disk Usage: $usedSpace GB / $totalSpace GB ($usagePercent%)" -ForegroundColor Yellow

# Analyze Program Files (x86)
Write-Host "`nProgram Files (x86) Analysis:" -ForegroundColor White
$programDirs = Get-ChildItem "C:\Program Files (x86)" -Directory | ForEach-Object {
    try {
        $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        $age = (Get-Date) - $_.LastWriteTime
        [PSCustomObject]@{
            Name = $_.Name
            SizeGB = [math]::Round($size, 2)
            AgeDays = $age.Days
            LastModified = $_.LastWriteTime.ToString("yyyy-MM-dd")
        }
    } catch {
        [PSCustomObject]@{
            Name = $_.Name
            SizeGB = "Error"
            AgeDays = "Error"
            LastModified = "Error"
        }
    }
} | Sort-Object SizeGB -Descending

# Show top 20 directories
Write-Host "`nTop 20 directories by size:" -ForegroundColor White
$programDirs | Select-Object -First 20 | Format-Table -AutoSize

# Categorize by size
$largeDirs = $programDirs | Where-Object { $_.SizeGB -gt 5 -and $_.SizeGB -ne "Error" }
$mediumDirs = $programDirs | Where-Object { $_.SizeGB -gt 1 -and $_.SizeGB -le 5 -and $_.SizeGB -ne "Error" }
$oldDirs = $programDirs | Where-Object { $_.AgeDays -gt 365 -and $_.SizeGB -gt 0.5 -and $_.SizeGB -ne "Error" }

Write-Host "`nLARGE DIRECTORIES (>5GB):" -ForegroundColor Red
$largeDirs | ForEach-Object { Write-Host "  $($_.Name): $($_.SizeGB) GB (modified $($_.AgeDays) days ago)" -ForegroundColor White }

Write-Host "`nMEDIUM DIRECTORIES (1-5GB):" -ForegroundColor Yellow
$mediumDirs | ForEach-Object { Write-Host "  $($_.Name): $($_.SizeGB) GB (modified $($_.AgeDays) days ago)" -ForegroundColor White }

Write-Host "`nOLD DIRECTORIES (1+ years, >0.5GB):" -ForegroundColor Magenta
$oldDirs | ForEach-Object { Write-Host "  $($_.Name): $($_.SizeGB) GB (modified $($_.AgeDays) days ago)" -ForegroundColor White }

# Calculate potential savings
$totalLargeSize = ($largeDirs | Measure-Object -Property SizeGB -Sum).Sum
$totalMediumSize = ($mediumDirs | Measure-Object -Property SizeGB -Sum).Sum
$totalOldSize = ($oldDirs | Measure-Object -Property SizeGB -Sum).Sum

Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Large directories: $($largeDirs.Count) items, $([math]::Round($totalLargeSize, 2)) GB" -ForegroundColor White
Write-Host "Medium directories: $($mediumDirs.Count) items, $([math]::Round($totalMediumSize, 2)) GB" -ForegroundColor White
Write-Host "Old directories: $($oldDirs.Count) items, $([math]::Round($totalOldSize, 2)) GB" -ForegroundColor White

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Green
Write-Host "1. Review large directories for uninstallation" -ForegroundColor White
Write-Host "2. Check old directories for removal" -ForegroundColor White
Write-Host "3. Use 'Add or Remove Programs' to uninstall unused software" -ForegroundColor White
Write-Host "4. Consider moving development tools to external storage" -ForegroundColor White

Write-Host "`nPotential space savings: $([math]::Round($totalLargeSize + $totalOldSize, 2)) GB" -ForegroundColor Green
