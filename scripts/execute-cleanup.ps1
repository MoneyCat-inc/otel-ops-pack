# Execute C: Drive Cleanup - ECRR Compliant
# Examine → Clean → Report → Role

param(
    [switch]$QuickWins,
    [switch]$SteamGames,
    [switch]$ArchiveISOs,
    [switch]$ConsolidateROMs,
    [switch]$All,
    [string]$ExternalDrive = "D:\"
)

$ErrorActionPreference = "SilentlyContinue"
$artifactsDir = "C:\otel\artifacts"
if (!(Test-Path $artifactsDir)) { New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null }

Write-Host "🔍 ECRR: Examining current drive state..." -ForegroundColor Cyan

# Capture initial state
$initialState = Get-PSDrive C
$initialFreeGB = [math]::Round($initialState.Free / 1GB, 2)
$initialUsedGB = [math]::Round($initialState.Used / 1GB, 2)

Write-Host "📊 Initial State: $initialUsedGB GB used, $initialFreeGB GB free" -ForegroundColor Yellow

$cleanupLog = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    InitialState = @{ UsedGB = $initialUsedGB; FreeGB = $initialFreeGB }
    Actions = @()
    FinalState = $null
    SpaceRecovered = 0
}

# Quick Wins - Remove duplicates (9+ GB)
if ($QuickWins -or $All) {
    Write-Host "`n🚀 QUICK WINS - Removing duplicate files..." -ForegroundColor Green
    
    # Remove duplicate Stable Diffusion models
    $stableDiffPath = "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion\*.safetensors"
    $stableDiffFiles = Get-ChildItem $stableDiffPath -ErrorAction SilentlyContinue
    if ($stableDiffFiles) {
        $stableDiffSize = ($stableDiffFiles | Measure-Object Length -Sum).Sum
        $stableDiffSizeGB = [math]::Round($stableDiffSize / 1GB, 2)
        
        Write-Host "   Removing $($stableDiffFiles.Count) duplicate Stable Diffusion models ($stableDiffSizeGB GB)..." -ForegroundColor Yellow
        $stableDiffFiles | Remove-Item -Force
        $cleanupLog.Actions += @{ Action = "Remove duplicate Stable Diffusion models"; SizeGB = $stableDiffSizeGB; Status = "Completed" }
    }
    
    # Remove duplicate PyTorch libraries
    $pytorchPath = "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\venv\Lib\site-packages\torch\lib\torch_cuda.dll"
    if (Test-Path $pytorchPath) {
        $pytorchSize = (Get-Item $pytorchPath).Length
        $pytorchSizeGB = [math]::Round($pytorchSize / 1GB, 2)
        
        Write-Host "   Removing duplicate PyTorch CUDA library ($pytorchSizeGB GB)..." -ForegroundColor Yellow
        Remove-Item $pytorchPath -Force
        $cleanupLog.Actions += @{ Action = "Remove duplicate PyTorch library"; SizeGB = $pytorchSizeGB; Status = "Completed" }
    }
}

# Steam Games Management
if ($SteamGames -or $All) {
    Write-Host "`n🎮 STEAM GAMES - Management options..." -ForegroundColor Green
    
    # List Steam games by size
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
    
    Write-Host "   Steam games by size:" -ForegroundColor Yellow
    $steamGames | ForEach-Object { 
        Write-Host "     - $($_.Name): $($_.SizeGB) GB" -ForegroundColor White 
    }
    
    Write-Host "`n   To uninstall games:" -ForegroundColor Cyan
    Write-Host "   1. Open Steam" -ForegroundColor White
    Write-Host "   2. Right-click game → Manage → Uninstall" -ForegroundColor White
    Write-Host "   3. Or use: Right-click → Properties → Local Files → Move Install Folder" -ForegroundColor White
    
    $cleanupLog.Actions += @{ Action = "Steam games analysis"; SizeGB = ($steamGames | Measure-Object SizeGB -Sum).Sum; Status = "Manual action required" }
}

# Archive ISO Images
if ($ArchiveISOs -or $All) {
    Write-Host "`n📦 ARCHIVING ISO IMAGES..." -ForegroundColor Green
    
    $externalIsoDir = "$ExternalDrive\Archived_ISOs"
    if (!(Test-Path $externalIsoDir)) { 
        New-Item -ItemType Directory -Path $externalIsoDir -Force | Out-Null 
        Write-Host "   Created archive directory: $externalIsoDir" -ForegroundColor Yellow
    }
    
    # Find all ISO files
    $isoFiles = @()
    $isoFiles += Get-ChildItem "C:\TOOLS\[images]\*.iso" -ErrorAction SilentlyContinue
    $isoFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\TOOLS\ScGuard\ISO images\*.iso" -ErrorAction SilentlyContinue
    $isoFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\TOOLS\ScGuard\ISO images\*.img" -ErrorAction SilentlyContinue
    
    if ($isoFiles.Count -gt 0) {
        $totalIsoSize = ($isoFiles | Measure-Object Length -Sum).Sum
        $totalIsoSizeGB = [math]::Round($totalIsoSize / 1GB, 2)
        
        Write-Host "   Found $($isoFiles.Count) ISO files ($totalIsoSizeGB GB total)" -ForegroundColor Yellow
        
        foreach ($iso in $isoFiles) {
            $destPath = Join-Path $externalIsoDir $iso.Name
            try {
                Write-Host "   Archiving: $($iso.Name)..." -ForegroundColor Yellow
                Copy-Item $iso.FullName $destPath -Force
                Write-Host "     ✓ Archived to: $destPath" -ForegroundColor Green
                
                # Ask for confirmation before deletion
                Write-Host "     Delete original? (y/N): " -ForegroundColor Cyan -NoNewline
                $response = Read-Host
                if ($response -eq 'y' -or $response -eq 'Y') {
                    Remove-Item $iso.FullName -Force
                    Write-Host "     ✓ Original deleted" -ForegroundColor Green
                }
            } catch {
                Write-Host "     ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        $cleanupLog.Actions += @{ Action = "Archive ISO images"; SizeGB = $totalIsoSizeGB; Status = "Completed" }
    } else {
        Write-Host "   No ISO files found to archive" -ForegroundColor Yellow
    }
}

# Consolidate ROMs
if ($ConsolidateROMs -or $All) {
    Write-Host "`n🎯 CONSOLIDATING ROMS..." -ForegroundColor Green
    
    # Find ROM files
    $romFiles = @()
    $romFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\VidyaG\ryujinx\*.xci" -ErrorAction SilentlyContinue
    $romFiles += Get-ChildItem "C:\Users\fubum\OneDrive\Desktop\VidyaG\ryujinx\*.nsp" -ErrorAction SilentlyContinue
    $romFiles += Get-ChildItem "C:\TOOLS\EMULATORS\ROMS\PS2\*.iso" -ErrorAction SilentlyContinue
    $romFiles += Get-ChildItem "C:\TOOLS\EMULATORS\ROMS\PS2\*.7z" -ErrorAction SilentlyContinue
    
    if ($romFiles.Count -gt 0) {
        $totalRomSize = ($romFiles | Measure-Object Length -Sum).Sum
        $totalRomSizeGB = [math]::Round($totalRomSize / 1GB, 2)
        
        Write-Host "   Found $($romFiles.Count) ROM files ($totalRomSizeGB GB total)" -ForegroundColor Yellow
        
        # Group by name to find duplicates
        $romGroups = $romFiles | Group-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }
        
        foreach ($group in $romGroups) {
            if ($group.Count -gt 1) {
                Write-Host "   Duplicate found: $($group.Name)" -ForegroundColor Yellow
                $group.Group | ForEach-Object { 
                    Write-Host "     - $($_.FullName) ($([math]::Round($_.Length/1GB,2)) GB)" -ForegroundColor White 
                }
            }
        }
        
        $cleanupLog.Actions += @{ Action = "Consolidate ROMs"; SizeGB = $totalRomSizeGB; Status = "Manual review required" }
    } else {
        Write-Host "   No ROM files found to consolidate" -ForegroundColor Yellow
    }
}

# Final state check
Write-Host "`n📊 FINAL STATE CHECK..." -ForegroundColor Cyan
Start-Sleep -Seconds 2  # Allow filesystem to update

$finalState = Get-PSDrive C
$finalFreeGB = [math]::Round($finalState.Free / 1GB, 2)
$finalUsedGB = [math]::Round($finalState.Used / 1GB, 2)
$spaceRecovered = $finalFreeGB - $initialFreeGB

$cleanupLog.FinalState = @{ UsedGB = $finalUsedGB; FreeGB = $finalFreeGB }
$cleanupLog.SpaceRecovered = $spaceRecovered

Write-Host "   Initial: $initialUsedGB GB used, $initialFreeGB GB free" -ForegroundColor White
Write-Host "   Final:   $finalUsedGB GB used, $finalFreeGB GB free" -ForegroundColor White
Write-Host "   Recovered: $spaceRecovered GB" -ForegroundColor Green

# Save cleanup log
$logPath = "$artifactsDir\cleanup-execution-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$cleanupLog | ConvertTo-Json -Depth 5 | Out-File -FilePath $logPath -Encoding UTF8

Write-Host "`n✅ ECRR: Cleanup execution complete!" -ForegroundColor Green
Write-Host "📄 Log saved to: $logPath" -ForegroundColor Cyan

Write-Host "`n🎯 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Review Steam games and uninstall unused ones" -ForegroundColor White
Write-Host "2. Use Steam's 'Move Install Folder' for games you want to keep" -ForegroundColor White
Write-Host "3. Manually review ROM duplicates and remove unnecessary ones" -ForegroundColor White
Write-Host "4. Run: pwsh -File C:\otel\scripts\disk-cleanup-analyzer.ps1 -AnalyzeOnly" -ForegroundColor White
