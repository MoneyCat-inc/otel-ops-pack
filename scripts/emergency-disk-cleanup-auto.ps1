# Emergency Disk Cleanup Script - Non-Interactive Version
# Critical disk usage above 90% - immediate cleanup required

Write-Host "Emergency Disk Cleanup - CRITICAL DISK USAGE" -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red

# Check current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-Host "Current Disk Usage: $usedSpace GB / $totalSpace GB ($usagePercent%)" -ForegroundColor Yellow
Write-Host "Free Space: $freeSpace GB" -ForegroundColor Yellow

if ($usagePercent -gt 90) {
    Write-Host "CRITICAL: Disk usage above 90% - executing emergency cleanup" -ForegroundColor Red
} else {
    Write-Host "Disk usage within acceptable range" -ForegroundColor Green
    exit 0
}

$totalCleaned = 0

# Phase 1: Clean temp directories (non-interactive)
Write-Host "`nPhase 1: Cleaning temporary directories..." -ForegroundColor Cyan
$tempDirs = @(
    $env:TEMP,
    $env:TMP,
    "C:\Windows\Temp"
)

foreach ($dir in $tempDirs) {
    if (Test-Path $dir) {
        Write-Host "Cleaning $dir..." -ForegroundColor White
        try {
            $beforeSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            # Use Remove-Item with -Force and -Recurse to avoid prompts
            Get-ChildItem $dir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            $cleaned = $beforeSize - $afterSize
            $totalCleaned += $cleaned
            Write-Host "  Cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Phase 2: Clean cache directories (non-interactive)
Write-Host "`nPhase 2: Cleaning cache directories..." -ForegroundColor Cyan
$cacheDirs = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:APPDATA\Microsoft\Windows\Caches",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache"
)

foreach ($dir in $cacheDirs) {
    if (Test-Path $dir) {
        Write-Host "Cleaning $dir..." -ForegroundColor White
        try {
            $beforeSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Get-ChildItem $dir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            $cleaned = $beforeSize - $afterSize
            $totalCleaned += $cleaned
            Write-Host "  Cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Phase 3: Clean Windows Update cache (non-interactive)
Write-Host "`nPhase 3: Cleaning Windows Update cache..." -ForegroundColor Cyan
$updateCache = "C:\Windows\SoftwareDistribution\Download"
if (Test-Path $updateCache) {
    Write-Host "Cleaning Windows Update cache..." -ForegroundColor White
    try {
        $beforeSize = (Get-ChildItem $updateCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        Get-ChildItem $updateCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        $afterSize = (Get-ChildItem $updateCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        $cleaned = $beforeSize - $afterSize
        $totalCleaned += $cleaned
        Write-Host "  Cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check final disk usage
Write-Host "`nFinal Disk Usage Check..." -ForegroundColor Cyan
$finalDisk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$finalFreeSpace = [math]::Round($finalDisk.FreeSpace / 1GB, 2)
$finalUsedSpace = $totalSpace - $finalFreeSpace
$finalUsagePercent = [math]::Round(($finalUsedSpace / $totalSpace) * 100, 1)

Write-Host "`n=== CLEANUP RESULTS ===" -ForegroundColor Yellow
Write-Host "Total space cleaned: $([math]::Round($totalCleaned, 2)) GB" -ForegroundColor Green
Write-Host "New free space: $finalFreeSpace GB" -ForegroundColor White
Write-Host "New usage: $finalUsagePercent%" -ForegroundColor White

if ($finalUsagePercent -lt 85) {
    Write-Host "SUCCESS: Disk usage reduced below 85%" -ForegroundColor Green
} elseif ($finalUsagePercent -lt 90) {
    Write-Host "IMPROVEMENT: Disk usage reduced below 90%" -ForegroundColor Yellow
} else {
    Write-Host "WARNING: Disk usage still above 90% - additional cleanup needed" -ForegroundColor Red
    Write-Host "Consider archiving old tools or expanding disk space" -ForegroundColor Red
}

Write-Host "`nEmergency cleanup complete!" -ForegroundColor Cyan
