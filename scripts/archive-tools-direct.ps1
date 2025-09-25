# Direct TOOLS Directory Archiving Script
# Archives old installers and SDKs to free up space

Write-Host "TOOLS Directory Archiving Script" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-Host "Current Disk Usage: $usedSpace GB / $totalSpace GB ($usagePercent%)" -ForegroundColor Yellow

# Check TOOLS directory
$toolsPath = "C:\TOOLS"
if (-not (Test-Path $toolsPath)) {
    Write-Host "TOOLS directory not found at $toolsPath" -ForegroundColor Red
    exit 1
}

# Get TOOLS directory size
$toolsSize = (Get-ChildItem $toolsPath -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
Write-Host "TOOLS directory size: $([math]::Round($toolsSize, 2)) GB" -ForegroundColor White

# Create archive directory
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$archivePath = "C:\archives\TOOLS-$timestamp"
Write-Host "Creating archive directory: $archivePath" -ForegroundColor White

if (-not (Test-Path "C:\archives")) {
    New-Item -ItemType Directory -Path "C:\archives" -Force | Out-Null
}
New-Item -ItemType Directory -Path $archivePath -Force | Out-Null

# Find old files (older than 6 months)
$cutoffDate = (Get-Date).AddMonths(-6)
Write-Host "`nFinding files older than 6 months..." -ForegroundColor Cyan

$oldFiles = Get-ChildItem $toolsPath -Recurse -File | Where-Object { 
    $_.LastWriteTime -lt $cutoffDate -and 
    ($_.Extension -match '\.(exe|msi|zip|7z|tar|gz|iso)$' -or $_.Name -match '(sdk|installer|setup|setup|download)')
} | Sort-Object LastWriteTime

Write-Host "Found $($oldFiles.Count) old files to archive" -ForegroundColor White

if ($oldFiles.Count -eq 0) {
    Write-Host "No old files found to archive" -ForegroundColor Yellow
    exit 0
}

# Show files to be archived (first 10)
Write-Host "`nFiles to be archived (first 10):" -ForegroundColor Gray
foreach ($file in $oldFiles | Select-Object -First 10) {
    $age = (Get-Date) - $file.LastWriteTime
    Write-Host "  $($file.Name) (last modified: $($age.Days) days ago)" -ForegroundColor Gray
}

# Archive files
Write-Host "`nArchiving files..." -ForegroundColor Cyan
$totalArchived = 0
$archivedCount = 0

foreach ($file in $oldFiles) {
    try {
        $relativePath = $file.FullName.Substring($toolsPath.Length + 1)
        $destinationPath = Join-Path $archivePath $relativePath
        $destinationDir = Split-Path -Path $destinationPath -Parent
        
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        
        Move-Item $file.FullName $destinationPath -Force
        $totalArchived += $file.Length / 1GB
        $archivedCount++
        
        if ($archivedCount % 10 -eq 0) {
            Write-Host "  Archived $archivedCount files..." -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Error archiving $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check final disk usage
Write-Host "`nFinal Disk Usage Check..." -ForegroundColor Cyan
$finalDisk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$finalFreeSpace = [math]::Round($finalDisk.FreeSpace / 1GB, 2)
$finalUsedSpace = $totalSpace - $finalFreeSpace
$finalUsagePercent = [math]::Round(($finalUsedSpace / $totalSpace) * 100, 1)

Write-Host "`n=== ARCHIVE RESULTS ===" -ForegroundColor Yellow
Write-Host "Files archived: $archivedCount" -ForegroundColor Green
Write-Host "Space freed: $([math]::Round($totalArchived, 2)) GB" -ForegroundColor Green
Write-Host "Archive location: $archivePath" -ForegroundColor White
Write-Host "New free space: $finalFreeSpace GB" -ForegroundColor White
Write-Host "New usage: $finalUsagePercent%" -ForegroundColor White

if ($finalUsagePercent -lt 85) {
    Write-Host "SUCCESS: Disk usage reduced below 85%" -ForegroundColor Green
} elseif ($finalUsagePercent -lt 90) {
    Write-Host "IMPROVEMENT: Disk usage reduced below 90%" -ForegroundColor Yellow
} else {
    Write-Host "WARNING: Disk usage still above 90%" -ForegroundColor Red
    Write-Host "Consider additional cleanup or disk expansion" -ForegroundColor Red
}

Write-Host "`nArchive complete!" -ForegroundColor Cyan

