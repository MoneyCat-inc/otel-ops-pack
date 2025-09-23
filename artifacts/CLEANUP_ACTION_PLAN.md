# C: Drive Cleanup Action Plan
**Generated**: 2025-09-23 02:35:14  
**Current Status**: 61.85 GB free (6.6% of 930.5 GB total)  
**Recoverable Space**: 366.89 GB

## 🎯 Priority Cleanup Targets

### 1. **Steam Games** (333.8 GB) - HIGHEST IMPACT
**Action**: Uninstall unused games or move to external drive

| Game | Size | Priority | Action |
|------|------|----------|--------|
| Oblivion Remastered | 118.82 GB | 🔴 High | Uninstall if not playing |
| MarvelRivals | 90.41 GB | 🔴 High | Uninstall if not playing |
| dota 2 beta | 57.47 GB | 🟡 Medium | Consider uninstalling |
| Counter-Strike Global Offensive | 53.28 GB | 🟡 Medium | Keep if actively playing |
| SteamVR | 5.35 GB | 🟢 Low | Keep if using VR |

### 2. **ISO Images** (20.86 GB) - MEDIUM IMPACT
**Action**: Move to external storage, then delete

**Files to Archive**:
- Windows 11 Insider Preview ISO (5.57 GB)
- Windows 10 Insider Preview ISO (5.54 GB)  
- Windows 11 24H2 ISO (5.42 GB)
- Ubuntu 24.04.2 Desktop ISO (5.91 GB)
- Office 365 Home Premium Image (5.15 GB)

### 3. **Duplicate Files** (7.94 GB) - LOW IMPACT
**Action**: Remove OneDrive copies, keep local only

**Files to Remove**:
- Stable Diffusion models in OneDrive (3.97 GB)
- PyTorch CUDA libraries in OneDrive (1.03 GB)

## 🚀 Quick Win Commands

### Immediate Space Recovery (Run these first):
`powershell
# 1. Remove duplicate Stable Diffusion models (7.94 GB)
Remove-Item "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\models\Stable-diffusion\*.safetensors" -Force

# 2. Remove duplicate PyTorch libraries (1.03 GB)  
Remove-Item "C:\Users\fubum\OneDrive\Pictures\AI world Takeover\stable-diffusion-webui-master\stable-diffusion-webui\venv\Lib\site-packages\torch\lib\torch_cuda.dll" -Force

# 3. Check current free space
Get-PSDrive C | Select-Object Used,Free,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}}
`

## 📊 Expected Results

| Action | Space Recovered | Effort | Risk |
|--------|----------------|--------|------|
| Remove duplicates | ~9 GB | Low | None |
| Uninstall Oblivion Remastered | ~119 GB | Low | None |
| Uninstall MarvelRivals | ~90 GB | Low | None |
| Archive ISOs | ~21 GB | Medium | Low |
| **TOTAL POTENTIAL** | **~239 GB** | **Medium** | **Low** |

## ✅ Verification Steps

After each cleanup action, run:
`powershell
# Check drive space
Get-PSDrive C

# Run full analysis
pwsh -File C:\otel\scripts\disk-cleanup-analyzer.ps1 -AnalyzeOnly
`

## 🎯 Success Criteria

- **Target**: Recover at least 200 GB of space
- **Goal**: Achieve 15%+ free space (140+ GB free)
- **Stretch**: Achieve 20%+ free space (185+ GB free)
