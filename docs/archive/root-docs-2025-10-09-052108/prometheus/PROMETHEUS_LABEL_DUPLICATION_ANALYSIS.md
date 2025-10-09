# 🔍 **Prometheus Exporter Label Duplication Analysis**

**Date**: 2025-09-29  
**Status**: ⚠️ **IDENTIFIED - NON-CRITICAL METRICS ISSUE**  
**Agent**: Cursor Agent — Observability Copilot

---

## 🎯 **Issue Summary**

### **Problem Identified** 🔍
The SigNoz collector is generating numerous Prometheus exporter errors due to **duplicate label names** in constant and variable labels for various system metrics.

### **Error Pattern** ❌
```
failed to convert metric system_memory_usage: duplicate label names in constant and variable labels for metric "system_memory_usage"
```

### **Affected Metrics** 📊
- `system_memory_usage`
- `system_disk_weighted_io_time`
- `system_disk_io`
- `system_network_connections`
- `system_disk_operation_time`
- `system_disk_pending_operations`
- `system_disk_io_time`
- `system_network_errors`
- `system_cpu_time`
- `system_network_io`
- `system_network_packets`
- `system_network_dropped`
- `scrape_series_added`
- `up`

---

## 🔍 **Root Cause Analysis**

### **Technical Cause** 🔧
The issue occurs when the Prometheus exporter encounters metrics where:
1. **Constant labels** (set at metric creation) have the same names as
2. **Variable labels** (set per metric instance)

This creates a conflict in the Prometheus metric format, which doesn't allow duplicate label names.

### **Impact Assessment** 📈
- **Severity**: Low (non-blocking)
- **Data Loss**: Some system metrics may not be exported to Prometheus
- **Queue Steward**: **No impact** - logs pipeline unaffected
- **SigNoz Functionality**: **No impact** - core observability works

### **Why It's Non-Critical** ✅
1. **Logs Pipeline**: Unaffected (uses OTLP, not Prometheus)
2. **Queue Steward**: Working perfectly (logs flow via OTLP)
3. **Core Metrics**: Collector internal metrics still work
4. **System Health**: Memory pressure resolved, retry storms eliminated

---

## 🛠️ **Potential Solutions**

### **Option 1: Disable Prometheus Exporter (Recommended)** ✅
```yaml
# In signoz-collector-config.yaml
# Comment out or remove the prometheus exporter
exporters:
  # prometheus:  # Disable if not needed
  #   endpoint: "0.0.0.0:8889"
```

**Pros**:
- Eliminates all duplicate label errors
- Reduces collector overhead
- No impact on Queue Steward (uses OTLP)

**Cons**:
- Loses some system metrics in Prometheus format
- May affect external Prometheus scraping

### **Option 2: Fix Label Conflicts** 🔧
```yaml
# Add label transformation to avoid conflicts
processors:
  transform/prometheus_labels:
    metric_statements:
      - context: metric
        statements:
          # Rename conflicting labels
          - set(attributes["host.name"], attributes["host.name"] + "_renamed") where attributes["host.name"] != nil
```

**Pros**:
- Preserves all metrics
- Maintains Prometheus compatibility

**Cons**:
- Complex configuration
- May require metric-specific fixes

### **Option 3: Update SigNoz Version** 🚀
```bash
# Use newer SigNoz version that may have fixed this issue
docker compose -f docker-compose-signoz.yml pull
docker compose -f docker-compose-signoz.yml up -d
```

**Pros**:
- May include upstream fixes
- Maintains all functionality

**Cons**:
- Requires testing
- May introduce other changes

---

## 📊 **Current Status Assessment**

### **Queue Steward Pipeline** ✅
- **Status**: Fully operational
- **Memory Pressure**: Resolved
- **Retry Storms**: Eliminated
- **Data Flow**: Smooth end-to-end
- **Attributes**: Correct (service.name="queue-steward", log.source="win-filelog")

### **SigNoz Collector Health** ✅
- **Memory Usage**: Within limits (4096 MiB)
- **Core Functionality**: Working
- **OTLP Export**: Successful
- **Logs Pipeline**: Operational

### **Prometheus Metrics** ⚠️
- **System Metrics**: Some missing due to label conflicts
- **Collector Metrics**: Working
- **Impact**: Low (non-critical)

---

## 🎯 **Recommendation**

### **Immediate Action** ✅
**No immediate action required** - the Queue Steward pipeline is fully operational and the memory pressure issue has been resolved.

### **Optional Cleanup** 🔧
If you want to eliminate the Prometheus warnings:

1. **Check if Prometheus exporter is needed**:
   ```bash
   # Check if anything is scraping the Prometheus endpoint
   curl http://localhost:18889/metrics | head -20
   ```

2. **If not needed, disable it**:
   ```yaml
   # In signoz-collector-config.yaml
   exporters:
     # prometheus:  # Comment out if not needed
     #   endpoint: "0.0.0.0:8889"
   ```

3. **Restart collector**:
   ```bash
   docker compose -f docker-compose-signoz.yml restart signoz-otel-collector
   ```

---

## 🔍 **Monitoring Recommendations**

### **Priority 1: Queue Steward Health** 📊
- Monitor `QueueMemoryCanaryUltra` frequency
- Watch for memory pressure rejections
- Track OTLP export success rates

### **Priority 2: SigNoz Collector Health** 📈
- Monitor `otelcol_process_memory_rss`
- Watch for memory limit alerts (>3.3 GiB)
- Track collector restart frequency

### **Priority 3: Prometheus Metrics (Optional)** 📋
- Monitor for duplicate label errors
- Consider disabling if not needed
- Track system metrics availability

---

## 🎯 **Final Status**

**✅ QUEUE STEWARD PIPELINE - FULLY OPERATIONAL**

The Prometheus label duplication warnings are:
- **Non-critical** (don't affect Queue Steward)
- **Non-blocking** (logs pipeline works perfectly)
- **Optional to fix** (can be addressed later)

**Priority**: Focus on Queue Steward monitoring and memory usage alerts. The Prometheus warnings can be addressed as a cleanup task when convenient.

---

**Files Created**:
- `signoz-memory-alert.json` - Memory pressure alert configuration
- `PROMETHEUS_LABEL_DUPLICATION_ANALYSIS.md` - This analysis

**Next Steps**:
1. ✅ Memory pressure resolved
2. ✅ Queue Steward pipeline operational
3. ✅ Memory monitoring alerts configured
4. ⚠️ Prometheus warnings identified (optional fix)
5. 📊 Ongoing pipeline health monitoring
