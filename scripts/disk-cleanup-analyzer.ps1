# Disk Cleanup Analyzer - C: Drive Space Recovery
# ECRR Compliant: Examine → Clean → Report → Role

param(
    [switch]$AnalyzeOnly,
    [switch]$CleanupISOs,
    [switch]$CleanupSteam,
    [switch]$CleanupROMs,
    [switch]$CleanupDuplicates,
    [string]$ExternalDrive = "D:\"
)

$ErrorActionPreference = "SilentlyContinue"
$artifactsDir = "C:\otel\artifacts"
if (!(Test-Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null }

Write-Host "🔍 ECRR: Examining C: drive usage..." -ForegroundColor Cyan

# 1. Current drive status
$driveInfo = Get-PSDrive C
$driveUsage = @{
    UsedGB = [math]::Round($driveInfo.Used / 1GB, 2)
    FreeGB = [math]::Round($driveInfo.Free / 1GB, 2)
    TotalGB = [math]::Round(($driveInfo.Used + $driveInfo.Free) / 1GB, 2)
    FreePercent = [math]::Round(($driveInfo.Free / ($driveInfo.Used + $driveInfo.Free)) * 100, 1)
}

Write-Host "📊 Drive Status: $($driveUsage.UsedGB) GB used, $($driveUsage.FreeGB) GB free ($($driveUsage.FreePercent)%)" -ForegroundColor Yellow

# 2. Identify cleanup targets
$cleanupTargets = @()

# ISO Images Analysis
Write-Host "`n🔍 Analyzing ISO images..." -ForegroundColor Cyan
$isoFiles = @()
$isoFiles += Get-ChildItem "C:\TOOLS\[images]\*.iso" -ErrorAction SilentlyContinue
$isoFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\TOOLS\ScGuard\ISO images\*.iso" -ErrorAction SilentlyContinue
$isoFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\TOOLS\ScGuard\ISO images\*.img" -ErrorAction SilentlyContinue

$isoTotalSize = ($isoFiles | Measure-Object Length -Sum).Sum
if ($isoTotalSize -gt 0) {
    $cleanupTargets += @{
        Category = "ISO Images"
        Path = "C:\TOOLS\[images]\ + OneDrive"
        SizeGB = [math]::Round($isoTotalSize / 1GB, 2)
        Count = $isoFiles.Count
        Action = "Move to external storage, then delete"
    }
}

# Steam Games Analysis
Write-Host "🔍 Analyzing Steam games..." -ForegroundColor Cyan
$steamGames = Get-ChildItem "C:\Program Files (x86)\Steam\steamapps\common" -Directory -ErrorAction SilentlyContinue | 
    ForEach-Object {
        try {
            $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            [pscustomobject]@{ 
                Name = $_.Name
                SizeGB = [math]::Round($size/1GB, 2)
                Path = $_.FullName
            }
        } catch {}
    } | Sort-Object SizeGB -Descending

$steamTotalSize = ($steamGames | Measure-Object SizeGB -Sum).Sum
if ($steamTotalSize -gt 0) {
    $cleanupTargets += @{
        Category = "Steam Games"
        Path = "C:\Program Files (x86)\Steam\steamapps\common"
        SizeGB = [math]::Round($steamTotalSize, 2)
        Count = $steamGames.Count
        Action = "Uninstall unused games or move to external drive"
        Details = $steamGames | Select-Object -First 5
    }
}

# Switch ROMs Analysis
Write-Host "🔍 Analyzing Switch ROMs..." -ForegroundColor Cyan
$romFiles = @()
$romFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\VidyaG\ryujinx\*.xci" -ErrorAction SilentlyContinue
$romFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\VidyaG\ryujinx\*.nsp" -ErrorAction SilentlyContinue
$romFiles += Get-ChildItem "C:\TOOLS\EMULATORS\ROMS\PS2\*.iso" -ErrorAction SilentlyContinue
$romFiles += Get-ChildItem "C:\TOOLS\EMULATORS\ROMS\PS2\*.7z" -ErrorAction SilentlyContinue

$romTotalSize = ($romFiles | Measure-Object Length -Sum).Sum
if ($romTotalSize -gt 0) {
    $cleanupTargets += @{
        Category = "Emulator ROMs"
        Path = "OneDrive VidyaG + C:\TOOLS\EMULATORS"
        SizeGB = [math]::Round($romTotalSize / 1GB, 2)
        Count = $romFiles.Count
        Action = "Consolidate and remove duplicates"
    }
}

# Duplicate Files Analysis
Write-Host "🔍 Analyzing duplicate files..." -ForegroundColor Cyan
$duplicateFiles = @()
$duplicateFiles += Get-ChildItem "C:\Users\fubum\Desktop\Stable Diffusion\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion\*.safetensors" -ErrorAction SilentlyContinue
$duplicateFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion\*.safetensors" -ErrorAction SilentlyContinue

$duplicateTotalSize = ($duplicateFiles | Measure-Object Length -Sum).Sum
if ($duplicateTotalSize -gt 0) {
    $cleanupTargets += @{
        Category = "Duplicate Files"
        Path = "Stable Diffusion models (local + OneDrive)"
        SizeGB = [math]::Round($duplicateTotalSize / 1GB, 2)
        Count = $duplicateFiles.Count
        Action = "Remove OneDrive copies, keep local only"
    }
}

# 3. Generate cleanup report
$report = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    DriveStatus = $driveUsage
    CleanupTargets = $cleanupTargets
    TotalRecoverableGB = ($cleanupTargets | Measure-Object SizeGB -Sum).Sum
    Recommendations = @()
}

# Generate recommendations
if ($report.TotalRecoverableGB -gt 100) {
    $report.Recommendations += "High impact: Focus on Steam games first (largest space recovery)"
}
if ($isoFiles.Count -gt 0) {
    $report.Recommendations += "Medium impact: Archive ISOs to external storage before deletion"
}
if ($romFiles.Count -gt 5) {
    $report.Recommendations += "Low impact: Consolidate ROMs and remove duplicates"
}

# 4. Display results
Write-Host "`n📋 CLEANUP TARGETS ANALYSIS" -ForegroundColor Green
Write-Host "=" * 50

foreach ($target in $cleanupTargets) {
    Write-Host "`n🎯 $($target.Category)" -ForegroundColor Yellow
    Write-Host "   Size: $($target.SizeGB) GB ($($target.Count) files)" -ForegroundColor White
    Write-Host "   Path: $($target.Path)" -ForegroundColor Gray
    Write-Host "   Action: $($target.Action)" -ForegroundColor Cyan
    
    if ($target.Details) {
        Write-Host "   Top items:" -ForegroundColor Gray
        $target.Details | ForEach-Object { 
            Write-Host "     - $($_.Name): $($_.SizeGB) GB" -ForegroundColor DarkGray 
        }
    }
}

Write-Host "`n💾 TOTAL RECOVERABLE SPACE: $($report.TotalRecoverableGB) GB" -ForegroundColor Green

# 5. Save report
$reportPath = "$artifactsDir\disk-cleanup-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`n📄 Report saved to: $reportPath" -ForegroundColor Green

# 6. Execute cleanup if requested
if (!$AnalyzeOnly) {
    Write-Host "`n🧹 CLEANUP ACTIONS" -ForegroundColor Green
    Write-Host "=" * 30
    
    if ($CleanupISOs -and $isoFiles.Count -gt 0) {
        Write-Host "`n📦 Moving ISO files to external storage..." -ForegroundColor Yellow
        $externalIsoDir = "$ExternalDrive\Archived_ISOs"
        if (!(Test-Path $externalIsoDir)) { 
            New-Item -ItemType Directory -Path $externalIsoDir -Force | Out-Null 
        }
        
        foreach ($iso in $isoFiles) {
            $destPath = Join-Path $externalIsoDir $iso.Name
            try {
                Copy-Item $iso.FullName $destPath -Force
                Write-Host "   ✓ Copied: $($iso.Name)" -ForegroundColor Green
            } catch {
                Write-Host "   ✗ Failed: $($iso.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    if ($CleanupDuplicates -and $duplicateFiles.Count -gt 0) {
        Write-Host "`n🗑️ Removing duplicate Stable Diffusion models..." -ForegroundColor Yellow
        $oneDriveModels = $duplicateFiles | Where-Object { $_.FullName -like "*OneDrive*" }
        foreach ($file in $oneDriveModels) {
            try {
                Remove-Item $file.FullName -Force
                Write-Host "   ✓ Removed: $($file.Name)" -ForegroundColor Green
            } catch {
                Write-Host "   ✗ Failed: $($file.Name) - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`n✅ ECRR: Analysis complete. Check artifacts for detailed report." -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Review the generated report in $artifactsDir" -ForegroundColor White
Write-Host "2. Run with -CleanupISOs to archive ISO files" -ForegroundColor White
Write-Host "3. Use Steam's 'Move Install Folder' for large games" -ForegroundColor White
Write-Host "4. Manually consolidate ROM duplicates" -ForegroundColor White
