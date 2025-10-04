# 🐾 BossCat Windows Quickrun Kit
**GPU Pattern-Sifter EPIC - Lane T3**  
**Target:** <2 minute smoke tests with consistent artifacts

## 🚀 **Quick Commands**

### **T1 Rolling Stats Test**
```powershell
# Set UTF-8 encoding (Windows compatibility)
$env:PYTHONIOENCODING = "utf-8"

# Run rolling stats harness
python rolling_run.py

# Expected output:
# 🐾 BossCat Rolling Statistics Harness
# ⚡ Performance Results:
#    GPU: 55.9ms
#    CPU: 1.7ms
#    Parity: 0.00e+00
#    Provider: cuda
# ✅ Parity threshold satisfied
```

### **T2 Evidence Validation**
```powershell
# Test schema load
npx tsx scripts/validate_evidence.ts --schema-only

# Validate T1 evidence
npx tsx scripts/validate_evidence.ts docs/ecrr/ECRR_REPORTS/rolling_stats_evidence.json

# Expected output:
# ✅ Evidence validation passed
```

### **Full Integration Test**
```powershell
# Run comprehensive T1+T2 test
pwsh -File test-t1-t2-integration.ps1

# Expected: All 4 steps pass ✅
```

## 📊 **Expected Evidence Output**

### **Rolling Stats Evidence:**
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
    "wsl_detected": false
  },
  "run": {
    "providerFinal": "cuda",
    "fellBackToCpu": false
  }
}
```

## 🔧 **Troubleshooting**

### **Encoding Issues**
```powershell
# If emoji don't display properly
$env:PYTHONIOENCODING = "utf-8"
chcp 65001  # Set console to UTF-8
```

### **CUDA Detection**
```powershell
# Check CUDA availability
nvidia-smi

# If no CUDA, harness will fall back to CPU automatically
# Evidence will show: "fellBackToCpu": true
```

### **Node.js/TypeScript Issues**
```powershell
# Ensure tsx is available
npm install -g tsx

# Or use npx
npx tsx scripts/validate_evidence.ts --schema-only
```

## 🎯 **Success Criteria**

- ✅ **Total Time:** <2 minutes from start to evidence file
- ✅ **Evidence Location:** `docs/ecrr/ECRR_REPORTS/rolling_stats_evidence.json`
- ✅ **Validation:** Schema compliance verified
- ✅ **Parity:** <1e-5 threshold satisfied
- ✅ **WSL Detection:** `wsl_detected: false` (Windows) or `true` (WSL)

## 🐾 **BossCat Compliance**

This quickrun kit follows BossCat governance:
- ✅ Local-first execution
- ✅ Evidence-based validation
- ✅ Windows compatibility
- ✅ ECRR methodology

**Authority:** BossCat OEM  
**Lane:** T3 - Windows & WSL Kits  
**Epic:** [GPU Pattern-Sifter EPIC](docs/ecrr/ECRR_REPORTS/GPU_PATTERN_SIFTER_EPIC.md)
