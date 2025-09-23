# Disk Cleanup Guide - Critical 93.4% Usage

## Current Status
- **Disk Usage**: 93.4% (868.65GB used of 930.5GB)
- **Free Space**: 61.85GB remaining
- **Status**: CRITICAL - Immediate action required

## Top Space Consumers
- **Program Files (x86)**: 383.4GB (52% of used space)
- **Users**: 106.4GB (14% of used space)
- **TOOLS**: 63.9GB (9% of used space)
- **Program Files**: 40.4GB (5% of used space)
- **Windows**: 36.0GB (5% of used space)

## Manual Analysis Steps

### 1. Program Files (x86) Analysis (383GB)
**Manual Steps:**
1. Open File Explorer → Navigate to `C:\Program Files (x86)`
2. Right-click → Sort by Size (if available) or Date Modified
3. Look for these common space hogs:

**Common Large Software:**
- **Visual Studio** (20-50GB) - Keep if actively developing
- **Adobe Creative Suite** (10-30GB) - Keep if using Photoshop/Premiere
- **Games** (Steam, Epic Games, Origin) - Archive old games
- **Development Tools** (Android Studio, IntelliJ, Eclipse) - Move to external storage
- **Microsoft Office** (5-15GB) - Keep if using
- **Virtual Machines** (VMware, VirtualBox) - Archive old VMs
- **Media Software** (VLC, Media Player) - Usually small, keep
- **Browsers** (Chrome, Firefox) - Keep, usually small

**Safe to Remove:**
- Old versions of software
- Unused development tools
- Games you don't play
- Trial software
- Unused Adobe products

### 2. Users Directory Analysis (106GB)
**Check these locations:**
- `C:\Users\[YourName]\Downloads` - Clear old downloads
- `C:\Users\[YourName]\Documents` - Archive old projects
- `C:\Users\[YourName]\Pictures` - Move to external storage
- `C:\Users\[YourName]\Videos` - Move to external storage
- `C:\Users\[YourName]\AppData\Local\Temp` - Clear temp files
- `C:\Users\[YourName]\AppData\Roaming` - Check for large caches

### 3. TOOLS Directory Analysis (64GB)
**Already archived 2.36GB, but more can be done:**
- Look for old installers (.exe, .msi files)
- Archive old SDKs and development tools
- Remove duplicate tools
- Move large tools to external storage

## Quick Cleanup Commands

### Emergency Cleanup (Already Done)
```powershell
# Temp files cleanup
pwsh -ExecutionPolicy Bypass -NoProfile -File scripts\emergency-disk-cleanup-auto.ps1
```

### TOOLS Archiving (Already Done)
```powershell
# Archive old tools
pwsh -ExecutionPolicy Bypass -NoProfile -File scripts\archive-tools-direct.ps1
```

### Additional Cleanup Options
```powershell
# Find largest files
pwsh -ExecutionPolicy Bypass -NoProfile -File scripts\find-largest-files.ps1

# Analyze Program Files
pwsh -ExecutionPolicy Bypass -NoProfile -File scripts\quick-disk-analysis.ps1
```

## Manual Cleanup Steps

### Step 1: Uninstall Unused Software
1. Open **Settings** → **Apps** → **Apps & features**
2. Sort by **Size** (largest first)
3. Look for software you don't use
4. Uninstall large, unused programs

### Step 2: Clear User Data
1. **Downloads**: Delete old downloads
2. **Documents**: Archive old projects
3. **Pictures/Videos**: Move to external storage
4. **Temp files**: Run Disk Cleanup utility

### Step 3: Archive Large Files
1. **Games**: Move old games to external storage
2. **Development Tools**: Archive unused IDEs/SDKs
3. **Media Files**: Move large videos/pictures to external storage
4. **Virtual Machines**: Archive old VMs

### Step 4: Use Disk Cleanup
1. Run **Disk Cleanup** as Administrator
2. Check all boxes
3. Click **OK** to clean

## Expected Results
- **Target**: Reduce usage below 85% (790GB used)
- **Need to free**: ~80GB minimum
- **Realistic target**: 70-80% usage (650-740GB used)

## Next Steps After Cleanup
1. **Monitor**: Use SigNoz dashboard to track disk usage
2. **Automate**: Set up regular cleanup schedules
3. **Expand**: Consider disk expansion if needed
4. **Archive**: Move large files to external storage

## Emergency Actions
If disk fills completely:
1. **Immediate**: Delete temp files and caches
2. **Short-term**: Move large files to external storage
3. **Long-term**: Expand disk or add secondary storage

---
*This guide should help you identify and remove unused software to free up the needed 80+ GB of space.*
