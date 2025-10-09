# 🔧 Windows Collector Memory Pressure Fix

**Date**: 2025-09-29  
**Status**: ✅ **CONFIGURATION TUNED**  
**Agent**: Cursor Agent — Observability Copilot

---

## 🎯 **Memory Pressure Issue Identified**

### **Problem** ⚠️
- **OTLP Export Failures**: Multiple `otelcol-contrib` errors showing `"data refused due to high memory usage"`
- **Impact**: Windows collector failing to export logs to SigNoz due to memory pressure
- **Frequency**: Continuous failures every few seconds

### **Root Cause** 🔍
- **Memory Limiter**: Too restrictive for current log volume
- **Batch Sizes**: Too large for available memory
- **Queue Sizes**: Exceeding memory limits

---

## 🛠️ **Configuration Tuning Applied**

### **Memory Optimizations** ✅
```yaml
# config.yaml changes applied:
memory_limiter:
  limit_mib: 1536        # Increased from 1024
  check_interval: 500ms
  spike_limit_mib: 512

batch/logs:
  timeout: 200ms
  send_batch_size: 512    # Reduced from 1024
  send_batch_max_size: 1024  # Reduced from 2048

sending_queue:
  enabled: true
  num_consumers: 8
  queue_size: 1024        # Reduced from 2048
```

### **Expected Impact** 📊
- **Higher Memory Headroom**: 1536 MiB limit provides more buffer
- **Smaller Batches**: 512 batch size reduces memory spikes
- **Reduced Queue Pressure**: 1024 queue size prevents overflow
- **Better Stability**: More conservative settings prevent memory exhaustion

---

## 🚀 **Next Steps Required**

### **1. Elevated Service Restart** ⚠️
**Command**: (Run in elevated PowerShell)
```powershell
Restart-Service -Name otelcol-contrib -Force
```

### **2. Verification Commands** ✅
```powershell
# Check for new memory errors (should be empty)
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='otelcol-contrib'; StartTime=(Get-Date).AddMinutes(-5)} |
  Where-Object { $_.Message -match 'data refused due to high memory usage' }

# Verify canary log emission
Get-Content C:\logs\queue\health.log -Tail 1
```

### **3. SigNoz Verification** ✅
**URL**: `http://localhost:8080 → Logs`
**Filter**: `message contains "QueueMemoryCanary"`
**Expected**: Fresh log row with QueueMemoryCanary message

---

## 📊 **Current Status**

### **Configuration** ✅
- **Memory Limit**: Increased to 1536 MiB
- **Batch Sizes**: Reduced to 512/1024
- **Queue Size**: Reduced to 1024
- **Canary Emitted**: QueueMemoryCanary log created

### **Service Status** ⚠️
- **Configuration**: Updated and ready
- **Service**: Needs elevated restart to apply changes
- **Memory Errors**: Still occurring (until restart)

### **Verification Ready** ✅
- **Canary Log**: Emitted to `C:\logs\queue\health.log`
- **Commands**: Ready for post-restart verification
- **SigNoz**: Ready for QueueMemoryCanary filter test

---

## 🎯 **Success Criteria**

### **After Elevated Restart** ✅
1. **No Memory Errors**: `Get-WinEvent` should show no new "data refused due to high memory usage" entries
2. **Canary Visible**: SigNoz Logs should show QueueMemoryCanary message
3. **Export Success**: OTLP export should work without memory pressure

### **Expected Results** 📈
- **Memory Pressure**: Resolved
- **Export Stability**: Improved
- **Queue Steward Logs**: Flowing successfully to SigNoz
- **Pipeline Health**: Fully operational

---

**STATUS**: ✅ **CONFIGURATION TUNED - AWAITING ELEVATED RESTART**

The Windows collector memory tuning is complete. The configuration has been optimized to prevent memory pressure issues. An elevated PowerShell restart is required to apply the changes and resolve the export failures.
