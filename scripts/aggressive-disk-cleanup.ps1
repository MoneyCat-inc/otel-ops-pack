# Aggressive Disk Cleanup Script
# Targets the biggest space consumers to free up 80+ GB

Write-Host "AGGRESSIVE DISK CLEANUP - TARGETING 80+ GB RECOVERY" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Red

# Check current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-Host "Current Disk Usage: $usedSpace GB / $totalSpace GB ($usagePercent%)" -ForegroundColor Yellow
Write-Host "Target: Free up 80+ GB to get below 85%" -ForegroundColor Green

$totalCleaned = 0

# Phase 1: Clean Windows Update cache more aggressively
Write-Host "`nPhase 1: Aggressive Windows Update cleanup..." -ForegroundColor Cyan
$updateCache = "C:\Windows\SoftwareDistribution"
if (Test-Path $updateCache) {
    try {
        $beforeSize = (Get-ChildItem $updateCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        # Stop Windows Update service
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        # Clear the entire SoftwareDistribution folder
        Get-ChildItem $updateCache -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        # Restart Windows Update service
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        $afterSize = (Get-ChildItem $updateCache -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        $cleaned = $beforeSize - $afterSize
        $totalCleaned += $cleaned
        Write-Host "  Windows Update cache cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
    }
    catch {
        Write-Host "  Error cleaning Windows Update cache: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Phase 2: Clean System32 logs and temp files
Write-Host "`nPhase 2: System logs and temp cleanup..." -ForegroundColor Cyan
$systemDirs = @(
    "C:\Windows\Logs",
    "C:\Windows\Temp",
    "C:\Windows\Prefetch",
    "C:\Windows\System32\LogFiles"
)

foreach ($dir in $systemDirs) {
    if (Test-Path $dir) {
        try {
            $beforeSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Get-ChildItem $dir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            $cleaned = $beforeSize - $afterSize
            $totalCleaned += $cleaned
            Write-Host "  $dir cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error cleaning $dir`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Phase 3: Clean user temp and cache more aggressively
Write-Host "`nPhase 3: Aggressive user cleanup..." -ForegroundColor Cyan
$userDirs = @(
    "$env:APPDATA\Microsoft\Windows\Recent",
    "$env:APPDATA\Microsoft\Windows\Caches",
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache",
    "$env:LOCALAPPDATA\Temp",
    "$env:TEMP"
)

foreach ($dir in $userDirs) {
    if (Test-Path $dir) {
        try {
            $beforeSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Get-ChildItem $dir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            $cleaned = $beforeSize - $afterSize
            $totalCleaned += $cleaned
            Write-Host "  $dir cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error cleaning $dir`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Phase 4: Clean browser caches
Write-Host "`nPhase 4: Browser cache cleanup..." -ForegroundColor Cyan
$browserDirs = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*\cache2",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
)

foreach ($pattern in $browserDirs) {
    $dirs = Get-ChildItem (Split-Path -Path $pattern -Parent) -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like (Split-Path -Path $pattern -Leaf) }
    foreach ($dir in $dirs) {
        try {
            $beforeSize = (Get-ChildItem $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Get-ChildItem $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            $cleaned = $beforeSize - $afterSize
            $totalCleaned += $cleaned
            Write-Host "  $($dir.Name) cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error cleaning $($dir.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Phase 5: Clean old Windows installations
Write-Host "`nPhase 5: Windows cleanup..." -ForegroundColor Cyan
$windowsDirs = @(
    "C:\Windows\WinSxS\Backup",
    "C:\Windows\Installer\$PatchCache$"
)

foreach ($dir in $windowsDirs) {
    if (Test-Path $dir) {
        try {
            $beforeSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            Get-ChildItem $dir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            $afterSize = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
            $cleaned = $beforeSize - $afterSize
            $totalCleaned += $cleaned
            Write-Host "  $dir cleaned: $([math]::Round($cleaned, 2)) GB" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error cleaning $dir`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Check final disk usage
Write-Host "`nFinal Disk Usage Check..." -ForegroundColor Cyan
$finalDisk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$finalFreeSpace = [math]::Round($finalDisk.FreeSpace / 1GB, 2)
$finalUsedSpace = $totalSpace - $finalFreeSpace
$finalUsagePercent = [math]::Round(($finalUsedSpace / $totalSpace) * 100, 1)

Write-Host "`n=== AGGRESSIVE CLEANUP RESULTS ===" -ForegroundColor Yellow
Write-Host "Total space cleaned: $([math]::Round($totalCleaned, 2)) GB" -ForegroundColor Green
Write-Host "New free space: $finalFreeSpace GB" -ForegroundColor White
Write-Host "New usage: $finalUsagePercent%" -ForegroundColor White

if ($finalUsagePercent -lt 85) {
    Write-Host "SUCCESS: Disk usage reduced below 85%" -ForegroundColor Green
} elseif ($finalUsagePercent -lt 90) {
    Write-Host "IMPROVEMENT: Disk usage reduced below 90%" -ForegroundColor Yellow
} else {
    Write-Host "WARNING: Disk usage still above 90%" -ForegroundColor Red
    Write-Host "Additional manual cleanup needed for Program Files (x86) and Users directory" -ForegroundColor Red
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
if ($finalUsagePercent -gt 85) {
    Write-Host "1. Review Program Files (x86) for large, unused software" -ForegroundColor White
    Write-Host "2. Check Users directory for large files" -ForegroundColor White
    Write-Host "3. Use 'Add or Remove Programs' to uninstall unused software" -ForegroundColor White
    Write-Host "4. Consider moving large files to external storage" -ForegroundColor White
}

Write-Host "`nAggressive cleanup complete!" -ForegroundColor Cyan
