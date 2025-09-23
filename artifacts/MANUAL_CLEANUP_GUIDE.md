# Manual Disk Cleanup Guide - Critical 93.4% Usage

## Current Status
- **Disk Usage**: 93.4% (868.56 GB used of 930.5 GB)
- **Free Space**: 61.94 GB remaining (6.7%)
- **Status**: CRITICAL - Immediate action required
- **Target**: Reduce to below 85% (need to free ~80+ GB)

## Quick Win Deletions (Step 1)

### PowerShell Commands - Copy & Paste Ready
`powershell
# Before cleanup - check current space
Get-PSDrive C | Select-Object Used,Free,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}

# Clean temp files (safe, immediate ~2-5 GB)
Get-ChildItem $env:TEMP -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-ChildItem 'C:\Windows\Temp' -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Clean browser caches (~1-3 GB)
Get-ChildItem "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

# Clean Windows Update cache (~2-5 GB)
Stop-Service wuauserv -Force
Get-ChildItem 'C:\Windows\SoftwareDistribution' -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Start-Service wuauserv

# After cleanup - verify space freed
Get-PSDrive C | Select-Object Used,Free,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}
`

**Expected Result**: 5-15 GB freed immediately

## Steam Uninstall Targets (Step 2)

### High Priority Steam Games (333.8 GB total)
| Game | Size | Action | Priority |
|------|------|--------|----------|
| Oblivion Remastered | 118.82 GB | Uninstall or move to external | HIGH |
| MarvelRivals | 90.41 GB | Uninstall or move to external | HIGH |
| dota 2 beta | 57.47 GB | Uninstall or move to external | MEDIUM |
| Counter-Strike Global Offensive | 53.28 GB | Uninstall or move to external | MEDIUM |
| SteamVR | 5.35 GB | Keep if using VR | LOW |

### Steam Cleanup Instructions
1. Open Steam → Library
2. Right-click each game → Properties → Local Files
3. Click "Move Install Folder" to external drive (if available)
4. OR click "Uninstall" to remove completely
5. **Start with Oblivion Remastered** (118.82 GB) for maximum impact

**Expected Result**: 200-300 GB freed

## ISO Archiving (Step 3)

### ISO Files Found (14.95 GB total)
- **Location**: C:\TOOLS\[images]\ + OneDrive Desktop
- **Count**: 6 files
- **Action**: Archive to external storage, then delete

### ISO Archiving Script
`powershell
# Create archive directory on external drive
$archiveDir = "D:\Archived_ISOs"
if (!(Test-Path $archiveDir)) { New-Item -ItemType Directory -Path $archiveDir -Force }

# Archive ISOs from C:\TOOLS\[images]\
$sourceDir = "C:\TOOLS\[images]"
if (Test-Path $sourceDir) {
    Get-ChildItem "$sourceDir\*.iso" | ForEach-Object {
        Copy-Item $_.FullName "$archiveDir\$($_.Name)" -Force
        Write-Host "Archived: $($_.Name)" -ForegroundColor Green
    }
}

# Archive ISOs from OneDrive
$oneDriveDir = "C:\Users\fubum\OneDrive\Desktop\TOOLS\ScGuard\ISO images"
if (Test-Path $oneDriveDir) {
    Get-ChildItem "$oneDriveDir\*.iso" | ForEach-Object {
        Copy-Item $_.FullName "$archiveDir\$($_.Name)" -Force
        Write-Host "Archived: $($_.Name)" -ForegroundColor Green
    }
}

# After archiving, delete originals (CAREFUL!)
# Uncomment the lines below ONLY after verifying files are safely archived
# Get-ChildItem "$sourceDir\*.iso" | Remove-Item -Force
# Get-ChildItem "$oneDriveDir\*.iso" | Remove-Item -Force
`

**Expected Result**: 14.95 GB freed

## Duplicate File Cleanup (Step 4)

### Stable Diffusion Models (3.97 GB)
- **Issue**: Duplicate models in local + OneDrive
- **Action**: Remove OneDrive copies, keep local only

`powershell
# Remove OneDrive copies of Stable Diffusion models
$oneDriveModels = "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion"
if (Test-Path $oneDriveModels) {
    Get-ChildItem "$oneDriveModels\*.safetensors" | Remove-Item -Force
    Write-Host "Removed OneDrive duplicate models" -ForegroundColor Green
}
`

**Expected Result**: 3.97 GB freed

## Monitoring Commands

### Real-time Space Monitoring
`powershell
# Quick space check
Get-PSDrive C | Select-Object Used,Free,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}

# Detailed analysis
pwsh -File C:\otel\scripts\disk-cleanup-analyzer.ps1 -AnalyzeOnly

# Find largest files
Get-ChildItem C:\ -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1GB } | Sort-Object Length -Descending | Select-Object -First 20
`

### Progress Tracking
After each cleanup step, run the space check command to verify progress:
`powershell
Get-PSDrive C | Select-Object Used,Free,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}
`

## Execution Order

1. **Step 1**: Run quick-win PowerShell commands (5-15 GB)
2. **Step 2**: Uninstall/move Steam games starting with Oblivion (200-300 GB)
3. **Step 3**: Archive ISOs to external storage (14.95 GB)
4. **Step 4**: Remove duplicate Stable Diffusion models (3.97 GB)

## Expected Total Recovery
- **Minimum**: 80+ GB (to get below 85%)
- **Realistic**: 200-350 GB (to get to 70-80% usage)
- **Maximum**: 357+ GB (if all targets are cleaned)

## Safety Notes
- Always verify files are safely archived before deletion
- Test external drive connectivity before archiving
- Keep essential games and software
- Document what you archive for future reference

## Emergency Actions
If disk fills completely:
1. Run Step 1 commands immediately
2. Uninstall largest Steam games first
3. Move large files to external storage
4. Consider disk expansion or secondary storage

---
*Generated by ECRR-compliant disk cleanup analyzer*
*Last updated: 2025-09-23 02:53:04*
