# Software Usage Audit Script
# Identifies what software is actually being used vs. unused

Write-Host "Software Usage Audit - Identifying Used vs Unused Software" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# Get current disk usage
$disk = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
$totalSpace = [math]::Round($disk.Size / 1GB, 2)
$freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedSpace = $totalSpace - $freeSpace
$usagePercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)

Write-Host "Current Disk Usage: $usedSpace GB / $totalSpace GB ($usagePercent%)" -ForegroundColor Yellow

# Get installed programs
Write-Host "`nAnalyzing installed software..." -ForegroundColor White
$installedPrograms = Get-WmiObject -Class Win32_Product | Select-Object Name, Version, InstallDate, @{Name='Size';Expression={0}} | Sort-Object Name

# Get recently used programs (from Start Menu and Desktop)
Write-Host "`nChecking recently used programs..." -ForegroundColor White
$recentPrograms = @()

# Check Start Menu shortcuts
$startMenuPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs"
)

foreach ($path in $startMenuPaths) {
    if (Test-Path $path) {
        $shortcuts = Get-ChildItem $path -Recurse -Filter "*.lnk" -ErrorAction SilentlyContinue
        foreach ($shortcut in $shortcuts) {
            try {
                $shell = New-Object -ComObject WScript.Shell
                $target = $shell.CreateShortcut($shortcut.FullName).TargetPath
                if ($target) {
                    $recentPrograms += Split-Path $target -Leaf
                }
            } catch {}
        }
    }
}

# Check running processes
Write-Host "`nChecking currently running processes..." -ForegroundColor White
$runningProcesses = Get-Process | Where-Object { $_.ProcessName -ne "Idle" -and $_.ProcessName -ne "System" } | Select-Object -ExpandProperty ProcessName

# Check recently modified files in Program Files
Write-Host "`nChecking recently modified files..." -ForegroundColor White
$recentlyModified = Get-ChildItem "C:\Program Files (x86)" -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-30) } | 
    Group-Object DirectoryName | 
    Sort-Object Count -Descending

# Analyze Program Files (x86) directories
Write-Host "`nAnalyzing Program Files (x86) directories..." -ForegroundColor White
$programDirs = Get-ChildItem "C:\Program Files (x86)" -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB
    $lastModified = $_.LastWriteTime
    $age = (Get-Date) - $lastModified
    
    # Check if directory has been accessed recently
    $recentlyAccessed = $false
    try {
        $recentFiles = Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.LastAccessTime -gt (Get-Date).AddDays(-30) }
        $recentlyAccessed = $recentFiles.Count -gt 0
    } catch {}
    
    [PSCustomObject]@{
        Name = $_.Name
        SizeGB = [math]::Round($size, 2)
        LastModified = $lastModified
        AgeDays = $age.Days
        RecentlyAccessed = $recentlyAccessed
        Path = $_.FullName
    }
} | Sort-Object SizeGB -Descending

# Categorize software
Write-Host "`n=== SOFTWARE ANALYSIS RESULTS ===" -ForegroundColor Cyan

# Large software (>5GB)
Write-Host "`nLARGE SOFTWARE (>5GB):" -ForegroundColor Red
$largeSoftware = $programDirs | Where-Object { $_.SizeGB -gt 5 }
foreach ($software in $largeSoftware) {
    $status = if ($software.RecentlyAccessed) { "RECENTLY USED" } else { "POTENTIALLY UNUSED" }
    $color = if ($software.RecentlyAccessed) { "Green" } else { "Yellow" }
    Write-Host "  $($software.Name): $($software.SizeGB) GB - $status" -ForegroundColor $color
    Write-Host "    Last modified: $($software.AgeDays) days ago" -ForegroundColor Gray
}

# Medium software (1-5GB)
Write-Host "`nMEDIUM SOFTWARE (1-5GB):" -ForegroundColor Yellow
$mediumSoftware = $programDirs | Where-Object { $_.SizeGB -gt 1 -and $_.SizeGB -le 5 }
foreach ($software in $mediumSoftware) {
    $status = if ($software.RecentlyAccessed) { "RECENTLY USED" } else { "POTENTIALLY UNUSED" }
    $color = if ($software.RecentlyAccessed) { "Green" } else { "Yellow" }
    Write-Host "  $($software.Name): $($software.SizeGB) GB - $status" -ForegroundColor $color
}

# Old software (not modified in 1+ years)
Write-Host "`nOLD SOFTWARE (not modified in 1+ years):" -ForegroundColor Magenta
$oldSoftware = $programDirs | Where-Object { $_.AgeDays -gt 365 -and $_.SizeGB -gt 0.5 }
foreach ($software in $oldSoftware) {
    $status = if ($software.RecentlyAccessed) { "RECENTLY USED" } else { "LIKELY UNUSED" }
    $color = if ($software.RecentlyAccessed) { "Green" } else { "Red" }
    Write-Host "  $($software.Name): $($software.SizeGB) GB - $status" -ForegroundColor $color
    Write-Host "    Last modified: $($software.AgeDays) days ago" -ForegroundColor Gray
}

# Common development tools
Write-Host "`nDEVELOPMENT TOOLS:" -ForegroundColor Blue
$devTools = $programDirs | Where-Object { 
    $_.Name -match "(Visual Studio|IntelliJ|Eclipse|Android Studio|Xcode|Node|Python|Java|Git|Docker|VirtualBox|VMware|Postman|Fiddler|Wireshark|Unity|Unreal|Blender|Maya|Photoshop|Illustrator|Premiere|After Effects)"
}
foreach ($tool in $devTools) {
    $status = if ($tool.RecentlyAccessed) { "ACTIVE" } else { "INACTIVE" }
    $color = if ($tool.RecentlyAccessed) { "Green" } else { "Yellow" }
    Write-Host "  $($tool.Name): $($tool.SizeGB) GB - $status" -ForegroundColor $color
}

# Games
Write-Host "`nGAMES:" -ForegroundColor Magenta
$games = $programDirs | Where-Object { 
    $_.Name -match "(Steam|Epic|Origin|Battle\.net|Uplay|GOG|Riot|Valorant|League|Minecraft|Fortnite|Apex|Call of Duty|Assassin|FIFA|NBA|Madden|Overwatch|Diablo|World of Warcraft|Destiny|Halo|Gears|Forza|Xbox|PlayStation)"
}
foreach ($game in $games) {
    $status = if ($game.RecentlyAccessed) { "ACTIVE" } else { "INACTIVE" }
    $color = if ($game.RecentlyAccessed) { "Green" } else { "Yellow" }
    Write-Host "  $($game.Name): $($game.SizeGB) GB - $status" -ForegroundColor $color
}

# Calculate potential savings
$unusedLarge = $largeSoftware | Where-Object { -not $_.RecentlyAccessed }
$unusedOld = $oldSoftware | Where-Object { -not $_.RecentlyAccessed }
$totalUnusedSize = ($unusedLarge | Measure-Object -Property SizeGB -Sum).Sum + ($unusedOld | Measure-Object -Property SizeGB -Sum).Sum

Write-Host "`n=== CLEANUP RECOMMENDATIONS ===" -ForegroundColor Cyan
Write-Host "Total unused large software: $([math]::Round($totalUnusedSize, 2)) GB" -ForegroundColor Yellow
Write-Host "Total unused old software: $([math]::Round(($unusedOld | Measure-Object -Property SizeGB -Sum).Sum, 2)) GB" -ForegroundColor Yellow

Write-Host "`nSAFE TO REMOVE (not recently accessed):" -ForegroundColor Green
foreach ($software in $unusedLarge) {
    Write-Host "  $($software.Name): $($software.SizeGB) GB" -ForegroundColor White
}

Write-Host "`nCONSIDER REMOVING (old and unused):" -ForegroundColor Yellow
foreach ($software in $unusedOld) {
    Write-Host "  $($software.Name): $($software.SizeGB) GB" -ForegroundColor White
}

Write-Host "`nKEEP (recently accessed):" -ForegroundColor Green
$keepSoftware = $programDirs | Where-Object { $_.RecentlyAccessed -and $_.SizeGB -gt 1 }
foreach ($software in $keepSoftware) {
    Write-Host "  $($software.Name): $($software.SizeGB) GB" -ForegroundColor White
}

Write-Host "`n=== NEXT STEPS ===" -ForegroundColor Cyan
Write-Host "1. Review the 'SAFE TO REMOVE' list above" -ForegroundColor White
Write-Host "2. Use 'Add or Remove Programs' to uninstall unused software" -ForegroundColor White
Write-Host "3. Manually delete directories for software that doesn't uninstall cleanly" -ForegroundColor White
Write-Host "4. Consider moving large development tools to external storage" -ForegroundColor White
Write-Host "5. Archive old games and media files" -ForegroundColor White

Write-Host "`nPotential space savings: $([math]::Round($totalUnusedSize, 2)) GB" -ForegroundColor Green
