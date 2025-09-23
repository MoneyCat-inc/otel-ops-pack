# Program Files (x86) Analysis Script
# Analyzes what's taking up space in Program Files (x86) directory

Write-Host "Program Files (x86) Analysis" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan

$programFilesPath = "C:\Program Files (x86)"
if (-not (Test-Path $programFilesPath)) {
    Write-Host "Program Files (x86) directory not found" -ForegroundColor Red
    exit 1
}

# Get total size
$totalSize = (Get-ChildItem $programFilesPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "Total Program Files (x86) size: $([math]::Round($totalSize, 2)) GB" -ForegroundColor Yellow

# Analyze top-level directories
Write-Host "`nTop-level directories by size:" -ForegroundColor White
$topDirs = Get-ChildItem $programFilesPath -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    [PSCustomObject]@{ 
        Name = $_.Name
        SizeGB = [math]::Round($size, 2)
        LastModified = $_.LastWriteTime
    }
} | Sort-Object SizeGB -Descending

foreach ($dir in $topDirs | Select-Object -First 20) {
    if ($dir.SizeGB -gt 1) {
        $age = (Get-Date) - $dir.LastModified
        Write-Host "  $($dir.Name): $($dir.SizeGB) GB (modified $($age.Days) days ago)" -ForegroundColor White
    }
}

# Find large files
Write-Host "`nLargest files in Program Files (x86):" -ForegroundColor White
$largeFiles = Get-ChildItem $programFilesPath -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.Length -gt 100MB } | 
    Sort-Object Length -Descending | 
    Select-Object -First 20

foreach ($file in $largeFiles) {
    $sizeGB = [math]::Round($file.Length / 1GB, 2)
    $age = (Get-Date) - $file.LastWriteTime
    Write-Host "  $($file.Name): $sizeGB GB (modified $($age.Days) days ago)" -ForegroundColor Gray
    Write-Host "    Path: $($file.FullName)" -ForegroundColor DarkGray
}

# Find old directories (not modified in 1+ years)
Write-Host "`nOld directories (not modified in 1+ years):" -ForegroundColor White
$oneYearAgo = (Get-Date).AddYears(-1)
$oldDirs = Get-ChildItem $programFilesPath -Directory | Where-Object { $_.LastWriteTime -lt $oneYearAgo } | Sort-Object LastWriteTime

foreach ($dir in $oldDirs | Select-Object -First 15) {
    $size = (Get-ChildItem $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    $age = (Get-Date) - $dir.LastWriteTime
    if ($size -gt 0.5) {
        Write-Host "  $($dir.Name): $([math]::Round($size, 2)) GB (last modified $($age.Days) days ago)" -ForegroundColor Yellow
    }
}

# Find common uninstallable software
Write-Host "`nCommon software that can be uninstalled:" -ForegroundColor White
$commonSoftware = @(
    "Microsoft Visual Studio",
    "Adobe",
    "Google",
    "Mozilla Firefox",
    "Microsoft Office",
    "Steam",
    "Epic Games",
    "Origin",
    "Battle.net",
    "Discord",
    "Spotify",
    "VLC",
    "WinRAR",
    "7-Zip",
    "Java",
    "Python",
    "Node.js",
    "Git",
    "Docker",
    "VirtualBox"
)

foreach ($software in $commonSoftware) {
    $found = Get-ChildItem $programFilesPath -Directory | Where-Object { $_.Name -like "*$software*" }
    if ($found) {
        foreach ($dir in $found) {
            $size = (Get-ChildItem $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            if ($size -gt 0.1) {
                Write-Host "  $($dir.Name): $([math]::Round($size, 2)) GB" -ForegroundColor Green
            }
        }
    }
}

Write-Host "`n=== ANALYSIS COMPLETE ===" -ForegroundColor Cyan
Write-Host "Total size: $([math]::Round($totalSize, 2)) GB" -ForegroundColor White
Write-Host "Large files found: $($largeFiles.Count)" -ForegroundColor White
Write-Host "Old directories: $($oldDirs.Count)" -ForegroundColor White

Write-Host "`nRecommendations:" -ForegroundColor Yellow
Write-Host "1. Review old directories for uninstallation" -ForegroundColor White
Write-Host "2. Check large files for deletion or archiving" -ForegroundColor White
Write-Host "3. Use 'Add or Remove Programs' to uninstall unused software" -ForegroundColor White
Write-Host "4. Consider moving large development tools to external storage" -ForegroundColor White
