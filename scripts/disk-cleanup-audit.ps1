# Disk Cleanup Audit and Automation Script
# Analyzes disk usage and provides cleanup options

param(
    [switch]$AnalyzeOnly = $true,
    [switch]$CleanTemp = $false,
    [switch]$CleanCache = $false,
    [switch]$ArchiveOldTools = $false,
    [switch]$Force = $false
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-DirectorySize {
    param([string]$Path)
    
    try {
        $size = (Get-ChildItem $Path -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
        return [math]::Round($size, 2)
    }
    catch {
        return "Error"
    }
}

function Get-TempDirectorySize {
    $tempDirs = @(
        "$env:TEMP",
        "$env:TMP",
        "C:\Windows\Temp",
        "C:\Windows\Prefetch"
    )
    
    $totalSize = 0
    foreach ($dir in $tempDirs) {
        if (Test-Path $dir) {
            $size = Get-DirectorySize $dir
            if ($size -ne "Error") {
                $totalSize += $size
                Write-ColorOutput "  $dir`: $size GB" "Gray"
            }
        }
    }
    return $totalSize
}

function Get-CacheDirectorySize {
    $cacheDirs = @(
        "$env:APPDATA\Microsoft\Windows\Recent",
        "$env:APPDATA\Microsoft\Windows\Caches",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache",
        "C:\Windows\SoftwareDistribution\Download"
    )
    
    $totalSize = 0
    foreach ($dir in $cacheDirs) {
        if (Test-Path $dir) {
            $size = Get-DirectorySize $dir
            if ($size -ne "Error") {
                $totalSize += $size
                Write-ColorOutput "  $dir`: $size GB" "Gray"
            }
        }
    }
    return $totalSize
}

function Get-TOOLSDirectoryAnalysis {
    $toolsPath = "C:\TOOLS"
    if (-not (Test-Path $toolsPath)) {
        return @{ TotalSize = 0; OldItems = @() }
    }
    
    Write-ColorOutput "`nAnalyzing C:\TOOLS directory..." "Yellow"
    $totalSize = Get-DirectorySize $toolsPath
    
    # Find old installers and SDKs (older than 6 months)
    $cutoffDate = (Get-Date).AddMonths(-6)
    $oldItems = Get-ChildItem $toolsPath -Recurse -File | Where-Object { 
        $_.LastWriteTime -lt $cutoffDate -and 
        ($_.Extension -match '\.(exe|msi|zip|7z|tar|gz)$' -or $_.Name -match '(sdk|installer|setup)')
    } | Sort-Object LastWriteTime | Select-Object -First 20
    
    return @{
        TotalSize = $totalSize
        OldItems = $oldItems
    }
}

function Clean-TempDirectories {
    Write-ColorOutput "`nCleaning temporary directories..." "Yellow"
    
    $tempDirs = @(
        "$env:TEMP",
        "$env:TMP",
        "C:\Windows\Temp"
    )
    
    $totalCleaned = 0
    foreach ($dir in $tempDirs) {
        if (Test-Path $dir) {
            Write-ColorOutput "Cleaning $dir..." "White"
            try {
                $beforeSize = Get-DirectorySize $dir
                Get-ChildItem $dir -Recurse -Force | Remove-Item -Force -ErrorAction SilentlyContinue
                $afterSize = Get-DirectorySize $dir
                $cleaned = $beforeSize - $afterSize
                $totalCleaned += $cleaned
                Write-ColorOutput "  Cleaned: $([math]::Round($cleaned, 2)) GB" "Green"
            }
            catch {
                Write-ColorOutput "  Error cleaning $dir`: $($_.Exception.Message)" "Red"
            }
        }
    }
    
    return $totalCleaned
}

function Clean-CacheDirectories {
    Write-ColorOutput "`nCleaning cache directories..." "Yellow"
    
    $cacheDirs = @(
        "$env:APPDATA\Microsoft\Windows\Recent",
        "$env:APPDATA\Microsoft\Windows\Caches",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\WebCache"
    )
    
    $totalCleaned = 0
    foreach ($dir in $cacheDirs) {
        if (Test-Path $dir) {
            Write-ColorOutput "Cleaning $dir..." "White"
            try {
                $beforeSize = Get-DirectorySize $dir
                Get-ChildItem $dir -Recurse -Force | Remove-Item -Force -ErrorAction SilentlyContinue
                $afterSize = Get-DirectorySize $dir
                $cleaned = $beforeSize - $afterSize
                $totalCleaned += $cleaned
                Write-ColorOutput "  Cleaned: $([math]::Round($cleaned, 2)) GB" "Green"
            }
            catch {
                Write-ColorOutput "  Error cleaning $dir`: $($_.Exception.Message)" "Red"
            }
        }
    }
    
    return $totalCleaned
}

function Archive-OldTools {
    param([string]$ArchivePath = "C:\TOOLS\Archive")
    
    Write-ColorOutput "`nArchiving old tools..." "Yellow"
    
    if (-not (Test-Path $ArchivePath)) {
        New-Item -ItemType Directory -Path $ArchivePath -Force | Out-Null
    }
    
    $toolsAnalysis = Get-TOOLSDirectoryAnalysis
    $totalArchived = 0
    
    foreach ($item in $toolsAnalysis.OldItems) {
        try {
            $destination = Join-Path $ArchivePath $item.Name
            Move-Item $item.FullName $destination -Force
            $totalArchived += $item.Length / 1GB
            Write-ColorOutput "  Archived: $($item.Name)" "Green"
        }
        catch {
            Write-ColorOutput "  Error archiving $($item.Name): $($_.Exception.Message)" "Red"
        }
    }
    
    return [math]::Round($totalArchived, 2)
}

# Main execution
Write-ColorOutput "Disk Cleanup Audit and Automation" "Cyan"
Write-ColorOutput "=================================" "Cyan"

# Get current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-ColorOutput "`nCurrent Disk Usage:" "Yellow"
Write-ColorOutput "  Total: $totalSpace GB" "White"
Write-ColorOutput "  Used: $usedSpace GB ($usagePercent%)" "White"
Write-ColorOutput "  Free: $freeSpace GB" "White"

if ($usagePercent -gt 90) {
    Write-ColorOutput "  ⚠️  CRITICAL: Disk usage above 90%!" "Red"
} elseif ($usagePercent -gt 80) {
    Write-ColorOutput "  ⚠️  WARNING: Disk usage above 80%" "Yellow"
}

# Analyze top directories
Write-ColorOutput "`nTop Directories by Size:" "Yellow"
$topDirs = Get-ChildItem C:\ -Directory | ForEach-Object {
    $size = Get-DirectorySize $_.FullName
    [PSCustomObject]@{ Directory = $_.Name; SizeGB = $size }
} | Sort-Object SizeGB -Descending | Select-Object -First 10

foreach ($dir in $topDirs) {
    if ($dir.SizeGB -gt 10) {
        Write-ColorOutput "  $($dir.Directory): $($dir.SizeGB) GB" "White"
    }
}

# Analyze temporary files
Write-ColorOutput "`nTemporary Files Analysis:" "Yellow"
$tempSize = Get-TempDirectorySize
Write-ColorOutput "  Total temp files: $([math]::Round($tempSize, 2)) GB" "White"

# Analyze cache files
Write-ColorOutput "`nCache Files Analysis:" "Yellow"
$cacheSize = Get-CacheDirectorySize
Write-ColorOutput "  Total cache files: $([math]::Round($cacheSize, 2)) GB" "White"

# Analyze TOOLS directory
$toolsAnalysis = Get-TOOLSDirectoryAnalysis
Write-ColorOutput "`nTOOLS Directory Analysis:" "Yellow"
Write-ColorOutput "  Total size: $($toolsAnalysis.TotalSize) GB" "White"
Write-ColorOutput "  Old items found: $($toolsAnalysis.OldItems.Count)" "White"

if ($toolsAnalysis.OldItems.Count -gt 0) {
    Write-ColorOutput "`nOld items in TOOLS (first 10):" "Gray"
    foreach ($item in $toolsAnalysis.OldItems | Select-Object -First 10) {
        $age = (Get-Date) - $item.LastWriteTime
        Write-ColorOutput "  $($item.Name) (last modified: $($age.Days) days ago)" "Gray"
    }
}

# Calculate potential savings
$potentialSavings = $tempSize + $cacheSize
if ($toolsAnalysis.OldItems.Count -gt 0) {
    $toolsSavings = ($toolsAnalysis.OldItems | Measure-Object -Property Length -Sum).Sum / 1GB
    $potentialSavings += $toolsSavings
}

Write-ColorOutput "`nPotential Cleanup Savings:" "Yellow"
Write-ColorOutput "  Temp files: $([math]::Round($tempSize, 2)) GB" "White"
Write-ColorOutput "  Cache files: $([math]::Round($cacheSize, 2)) GB" "White"
Write-ColorOutput "  Old tools: $([math]::Round($toolsSavings, 2)) GB" "White"
Write-ColorOutput "  Total potential: $([math]::Round($potentialSavings, 2)) GB" "Green"

# Execute cleanup if requested
if (-not $AnalyzeOnly) {
    Write-ColorOutput "`nExecuting Cleanup Operations..." "Cyan"
    $totalCleaned = 0
    
    if ($CleanTemp) {
        $cleaned = Clean-TempDirectories
        $totalCleaned += $cleaned
    }
    
    if ($CleanCache) {
        $cleaned = Clean-CacheDirectories
        $totalCleaned += $cleaned
    }
    
    if ($ArchiveOldTools) {
        $cleaned = Archive-OldTools
        $totalCleaned += $cleaned
    }
    
    Write-ColorOutput "`nCleanup Complete!" "Green"
    Write-ColorOutput "  Total space freed: $([math]::Round($totalCleaned, 2)) GB" "White"
    
    # Show new disk usage
    $newDisk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $newFreeSpace = [math]::Round($newDisk.FreeSpace / 1GB, 2)
    $newUsagePercent = [math]::Round((($newDisk.Size - $newDisk.FreeSpace) / $newDisk.Size) * 100, 1)
    
    Write-ColorOutput "`nNew Disk Usage:" "Yellow"
    Write-ColorOutput "  Free space: $newFreeSpace GB" "White"
    Write-ColorOutput "  Usage: $newUsagePercent%" "White"
}

Write-ColorOutput "`n=== Cleanup Commands ===" "Cyan"
Write-ColorOutput "To clean temp files: .\disk-cleanup-audit.ps1 -CleanTemp" "White"
Write-ColorOutput "To clean cache files: .\disk-cleanup-audit.ps1 -CleanCache" "White"
Write-ColorOutput "To archive old tools: .\disk-cleanup-audit.ps1 -ArchiveOldTools" "White"
Write-ColorOutput "To run all cleanup: .\disk-cleanup-audit.ps1 -CleanTemp -CleanCache -ArchiveOldTools" "White"
