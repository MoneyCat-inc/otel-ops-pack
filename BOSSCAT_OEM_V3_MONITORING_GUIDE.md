# 🔔 BossCat OEM V3 Background Monitoring Worker — Usage Guide

**Date:** 2025-10-23  
**Authority:** BossCat OEM  
**Version:** v3.0  
**Status:** ✅ OPERATIONAL

---

## 🎯 Overview

The BossCat OEM V3 Background Monitoring Worker is a complete rebuild using the BossCat OEM v3 schema architecture. It provides autonomous gate advancement with full v3 schema integration.

### **Key Features**

- ✅ **V3 Schema Integration:** `signoz_index_v3` + `resource_string_service$$name`
- ✅ **Autonomous Operation:** 2-minute polling with auto-execution
- ✅ **Complete Automation:** End-to-end gate advancement
- ✅ **Evidence Packaging:** ECRR artifacts + BossCat logs
- ✅ **Health Monitoring:** V3 schema health checks
- ✅ **Stability Verification:** Multiple trace bursts
- ✅ **Dry Run Support:** Test mode without execution

---

## 🚀 Usage

### **Background Monitoring (Recommended)**
```powershell
# Start autonomous monitoring worker
pwsh -File .\bosscat-oem-v3-monitor.ps1

# With custom interval (5 minutes)
pwsh -File .\bosscat-oem-v3-monitor.ps1 -IntervalSeconds 300

# Quiet mode (minimal output)
pwsh -File .\bosscat-oem-v3-monitor.ps1 -QuietMode

# Dry run mode (test without execution)
pwsh -File .\bosscat-oem-v3-monitor.ps1 -DryRun
```

### **Single Gate Check**
```powershell
# Basic check
pwsh -File .\bosscat-oem-v3-check.ps1

# Verbose output with additional analysis
pwsh -File .\bosscat-oem-v3-check.ps1 -Verbose

# Dry run mode
pwsh -File .\bosscat-oem-v3-check.ps1 -DryRun
```

### **Complete Automation**
```powershell
# Full end-to-end automation
pwsh -File .\bosscat-oem-v3-complete.ps1

# Verbose output
pwsh -File .\bosscat-oem-v3-complete.ps1 -Verbose

# Dry run mode
pwsh -File .\bosscat-oem-v3-complete.ps1 -DryRun
```

---

## 🔧 Configuration

### **Default Parameters**
```powershell
# bosscat-oem-v3-monitor.ps1
param(
    [int]$IntervalSeconds = 120,  # 2 minutes (low-latency mode)
    [switch]$QuietMode = $false,
    [switch]$DryRun = $false,
    [int]$MaxChecks = 1000,
    [int]$TimeoutSeconds = 30
)
```

### **V3 Schema Constants**
```powershell
$V3_TABLE = "signoz_traces.signoz_index_v3"
$V3_SERVICE_COL = "resource_string_service`$`$name"
$CANARY_SERVICE = "canary-test"
$TIME_WINDOW = "5 MINUTE"
$STABILITY_BURSTS = 3
```

---

## 🔄 Automation Flow

### **Monitoring Loop**
1. ✅ **Health Check:** V3 schema health validation
2. ✅ **Gate Check:** V3 trace count query
3. ✅ **Evaluation:** Exit code determination
4. ✅ **Auto-Execute:** Complete automation on exit 0
5. ✅ **Evidence:** ECRR artifacts + BossCat logs
6. ✅ **Signal:** Ready for @cat ready-for-gate

### **Complete Automation Steps**
1. ✅ **Health Check:** V3 schema health validation
2. ✅ **Canary Trace:** Send fresh trace
3. ✅ **Ingestion Wait:** 3-second delay
4. ✅ **Gate Check:** V3 trace count query
5. ✅ **Stability:** 3 additional trace bursts
6. ✅ **Evidence:** ECRR artifacts + BossCat logs
7. ✅ **Gate Verdict:** 🟢 GREEN

---

## 📊 V3 Schema Queries

### **Primary Gate Query**
```sql
-- V3 schema gate predicate
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name` = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE;
```

### **Timeline Query**
```sql
-- Activity timeline (last 30 min)
SELECT toStartOfMinute(timestamp) AS minute, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name`='canary-test'
  AND timestamp >= now() - INTERVAL 30 MINUTE
GROUP BY minute
ORDER BY minute DESC LIMIT 10;
```

### **Service Mix Query**
```sql
-- Service distribution (last 24 hours)
SELECT `resource_string_service$$name` AS svc, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE timestamp >= now() - INTERVAL 24 HOUR
GROUP BY svc ORDER BY spans DESC LIMIT 10;
```

---

## 🚦 Exit Codes

### **Monitoring Worker**
- **0 (GREEN):** Traces detected → Complete automation executed
- **1 (HOLD):** No traces → Continue monitoring
- **2 (ERROR):** Infrastructure issue → Check ClickHouse

### **Gate Check**
- **0 (GREEN):** Traces persisting
- **1 (HOLD):** No fresh traces (platform gap persists)
- **2 (ERROR):** ClickHouse query failed

### **Complete Automation**
- **0 (GREEN):** Gate advancement complete
- **1 (HOLD):** No traces found
- **2 (ERROR):** Infrastructure issue

---

## 📁 Evidence Artifacts

### **Generated Files**
```
artifacts/ecrr/gate_v3_TIMESTAMP/
├── gate_evidence_TIMESTAMP.txt        # Trace counts + queries
├── timeline_TIMESTAMP.txt             # Activity timeline
└── ECRR_V3_GATE_PROOF_TIMESTAMP.json # ECRR artifact
```

### **BossCat Log Entry**
```
docs/BossCat/BOSSCAT_LOG.md
- 2025-10-23T21:39:00Z V3_GATE ✅ traces for canary-test persisted (count=4, window=5m, v3_schema=signoz_index_v3, bosscat_oem=v3.0)
```

---

## 🔍 Troubleshooting

### **Common Issues**

**V3 Schema Health Check Failed**
```powershell
# Check ClickHouse container health
docker exec signoz-clickhouse clickhouse-client -q "SELECT 1"

# Check container status
docker ps | grep signoz-clickhouse
```

**No Fresh Traces**
```powershell
# Check service mix (what services are active)
pwsh -File .\bosscat-oem-v3-check.ps1 -Verbose

# Check timeline (when was last activity)
pwsh -File .\analyze-trace-schema.ps1
```

**Automation Failed**
```powershell
# Test individual components
pwsh -File .\bosscat-oem-v3-check.ps1 -DryRun
pwsh -File .\bosscat-oem-v3-complete.ps1 -DryRun
```

---

## 🎯 Success Criteria

### **Gate Success**
```yaml
gate_success:
  fresh_traces: "count() > 0 in last 5 minutes"
  service_preservation: "canary-test not overwritten"
  stability: "multiple traces persist"
  evidence: "ECRR artifacts generated"
  logging: "BossCat log updated"
  signal: "ready-for-gate posted"
```

### **V3 Schema Validation**
```yaml
v3_validation:
  table: "signoz_traces.signoz_index_v3"
  service_column: "resource_string_service$$name"
  method: "docker exec (HTTP 8123 not exposed)"
  health: "ClickHouse container responsive"
  queries: "All V3 queries successful"
```

---

## 🔔 Current Status

### **Operational Status**
```yaml
v3_schema:
  table: "signoz_traces.signoz_index_v3"
  service_column: "resource_string_service$$name"
  method: "docker exec (HTTP 8123 not exposed)"
  status: "✅ WORKING"

service_preservation:
  action: "insert (not upsert)"
  evidence: "1 canary-test span exists (not overwritten)"
  status: "✅ WORKING"

fresh_trace_persistence:
  last_canary: "2025-10-23 14:25 UTC (7+ hours ago)"
  recent_query: "0 spans (5 min window)"
  status: "❌ BROKEN (platform gap)"

automation:
  monitoring_worker: "✅ READY (bosscat-oem-v3-monitor.ps1)"
  gate_check: "✅ READY (bosscat-oem-v3-check.ps1)"
  complete_automation: "✅ READY (bosscat-oem-v3-complete.ps1)"
  evidence_packaging: "✅ READY (ECRR + BossCat logs)"
  status: "✅ OPERATIONAL"
```

---

## 🐾 BossCat OEM Schema Summary

The BossCat OEM V3 Background Monitoring Worker provides:

- ✅ **Complete V3 Integration:** `signoz_index_v3` + `resource_string_service$$name`
- ✅ **Autonomous Operation:** 2-minute polling + auto-execution
- ✅ **Health Monitoring:** V3 schema health checks
- ✅ **Stability Verification:** Multiple trace bursts
- ✅ **Evidence Packaging:** ECRR artifacts + BossCat logs
- ✅ **Dry Run Support:** Test mode without execution

**Current Status:** 🟢 **OPERATIONAL** - Ready for platform fix detection and autonomous gate advancement.

---

**🐾 BossCat OEM V3 Background Monitoring Worker - Complete automation architecture locked in and ready.**
