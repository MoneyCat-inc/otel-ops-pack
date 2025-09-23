# Find Largest Files Script
# Finds the largest files across the system to identify space hogs

Write-Host "Finding Largest Files Across System" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan

# Check current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-Host "Current Disk Usage: $usedSpace GB / $totalSpace GB ($usagePercent%)" -ForegroundColor Yellow

# Find largest files (over 1GB)
Write-Host "`nLargest files (over 1GB):" -ForegroundColor White
$largeFiles = Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Length -gt 1GB } | 
    Sort-Object Length -Descending | 
    Select-Object -First 20

foreach ($file in $largeFiles) {
    $sizeGB = [math]::Round($file.Length / 1GB, 2)
    $age = (Get-Date) - $file.LastWriteTime
    Write-Host "  $($file.Name): $sizeGB GB (modified $($age.Days) days ago)" -ForegroundColor White
    Write-Host "    Path: $($file.FullName)" -ForegroundColor DarkGray
}

# Find large files in specific directories
$targetDirs = @(
    "C:\Users",
    "C:\Program Files (x86)",
    "C:\TOOLS",
    "C:\Program Files"
)

foreach ($dir in $targetDirs) {
    if (Test-Path $dir) {
        Write-Host "`nLargest files in $dir (over 500MB):" -ForegroundColor White
        $dirLargeFiles = Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.Length -gt 500MB } | 
            Sort-Object Length -Descending | 
            Select-Object -First 10

        foreach ($file in $dirLargeFiles) {
            $sizeGB = [math]::Round($file.Length / 1GB, 2)
            $age = (Get-Date) - $file.LastWriteTime
            Write-Host "  $($file.Name): $sizeGB GB (modified $($age.Days) days ago)" -ForegroundColor Gray
        }
    }
}

# Find files by extension
Write-Host "`nLargest files by extension:" -ForegroundColor White
$extensions = @("*.iso", "*.zip", "*.7z", "*.rar", "*.exe", "*.msi", "*.dmg", "*.img", "*.vhd", "*.vdi")
foreach ($ext in $extensions) {
    $files = Get-ChildItem C:\ -Recurse -File -Include $ext -ErrorAction SilentlyContinue | 
        Sort-Object Length -Descending | 
        Select-Object -First 5
    
    if ($files.Count -gt 0) {
        Write-Host "`n$ext files:" -ForegroundColor Yellow
        foreach ($file in $files) {
            $sizeGB = [math]::Round($file.Length / 1GB, 2)
            Write-Host "  $($file.Name): $sizeGB GB" -ForegroundColor Gray
        }
    }
}

# Find duplicate files (same name and size)
Write-Host "`nPotential duplicate files (same name and size):" -ForegroundColor White
$duplicates = Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue | 
    Group-Object Name, Length | 
    Where-Object { $_.Count -gt 1 } | 
    Sort-Object Count -Descending | 
    Select-Object -First 10

foreach ($dup in $duplicates) {
    $sizeGB = [math]::Round($dup.Group[0].Length / 1GB, 2)
    Write-Host "  $($dup.Name): $sizeGB GB (found $($dup.Count) times)" -ForegroundColor Yellow
    foreach ($file in $dup.Group | Select-Object -First 3) {
        Write-Host "    $($file.FullName)" -ForegroundColor DarkGray
    }
}

Write-Host "`n=== ANALYSIS COMPLETE ===" -ForegroundColor Cyan
Write-Host "Large files found: $($largeFiles.Count)" -ForegroundColor White
Write-Host "Potential duplicates: $($duplicates.Count)" -ForegroundColor White

Write-Host "`nRecommendations:" -ForegroundColor Yellow
Write-Host "1. Review large files for deletion or archiving" -ForegroundColor White
Write-Host "2. Remove duplicate files to save space" -ForegroundColor White
Write-Host "3. Consider moving large media files to external storage" -ForegroundColor White
Write-Host "4. Clean up old installation files and downloads" -ForegroundColor White
