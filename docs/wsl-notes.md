# 🐾 BossCat WSL Quickrun Notes
**GPU Pattern-Sifter EPIC - Lane T3**  
**WSL Environment Detection & Compatibility**

## 🔍 **WSL Detection**

The rolling stats harness automatically detects WSL environment and includes `wsl_detected: true` in evidence:

```json
{
  "env": {
    "providers": ["cuda", "cpu"],
    "cudaVersion": "12.1",
    "wsl_detected": true
  }
}
```

## 🚀 **WSL Quick Commands**

### **Same Commands, Different Environment**
```bash
# WSL environment (bash/zsh)
export PYTHONIOENCODING=utf-8
python rolling_run.py

# Evidence will show wsl_detected: true
```

### **WSL-Specific Considerations**
```bash
# Check WSL version
wsl --version

# Check CUDA in WSL
nvidia-smi  # Should work in WSL2 with proper drivers

# Check Python environment
python --version
pip list | grep numpy
```

## 📊 **WSL Evidence Output**

### **Expected WSL Evidence:**
```json
{
  "ok": true,
  "ts": "2024-12-19T10:40:00Z",
  "algo": "rolling",
  "params": {"window": 256, "stride": 64},
  "timings": {
    "gpuMs": 55.9,
    "cpuMs": 1.7
  },
  "parity": {"maxAbsDiff": 0.0},
  "env": {
    "providers": ["cuda", "cpu"],
    "cudaVersion": "12.1",
    "wsl_detected": true
  },
  "run": {
    "providerFinal": "cuda",
    "fellBackToCpu": false
  }
}
```

## 🔧 **WSL Troubleshooting**

### **CUDA in WSL**
```bash
# WSL2 with CUDA requires:
# 1. Windows 11 or Windows 10 version 21H2+
# 2. NVIDIA driver 470.76+
# 3. WSL2 with CUDA support

# Test CUDA availability
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"
```

### **Python Environment**
```bash
# Ensure proper Python setup
python3 --version
pip3 install numpy

# If using virtual environment
source venv/bin/activate
```

### **File Path Issues**
```bash
# WSL vs Windows path handling
# Evidence files should be accessible from both environments
ls -la docs/ecrr/ECRR_REPORTS/
```

## 🎯 **WSL Success Criteria**

- ✅ **Detection:** `wsl_detected: true` in evidence
- ✅ **Performance:** Same GPU speedup as Windows
- ✅ **Parity:** <1e-5 threshold maintained
- ✅ **Evidence Location:** Accessible from both WSL and Windows
- ✅ **Total Time:** <2 minutes for complete test

## 🔄 **Cross-Environment Testing**

### **Windows → WSL**
```powershell
# From Windows PowerShell
wsl python rolling_run.py

# Evidence should show wsl_detected: true
```

### **WSL → Windows**
```bash
# From WSL bash
powershell.exe -Command "python rolling_run.py"

# Evidence should show wsl_detected: false
```

## 🐾 **BossCat WSL Compliance**

This WSL quickrun kit ensures:
- ✅ Cross-platform compatibility
- ✅ Environment detection working
- ✅ Consistent evidence format
- ✅ Same performance characteristics
- ✅ ECRR methodology maintained

**Authority:** BossCat OEM  
**Lane:** T3 - Windows & WSL Kits  
**Epic:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
