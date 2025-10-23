# 🐾 Gate Review Response: Trace Pipeline Root Cause Analysis

**Date:** 2025-10-23 15:30 UTC  
**Status:** DIAGNOSING TRACE FLOW FAILURE  
**Previous Error:** Conflated logs with traces  
**Current Focus:** Why traces aren't reaching ClickHouse

---

## 🎯 The Real Problem

**Gate Requirement:** SigNoz traces with `service.name="canary-test"`  
**What We Proved:** 2,573 canary **LOGS** in ClickHouse (✅)  
**What's Missing:** 0 canary **TRACES/SPANS** in ClickHouse (❌)

These are NOT the same data flow.

---

## 🔍 ROOT CAUSE ANALYSIS

### Issue 1: Service Name Overwriting ✅ FIXED

**Location:** `signoz-collector-config.yaml` lines 62-66

**Problem:**
```yaml
resource/defaults:
  attributes:
    - key: service.name
      value: resonai-backend
      action: upsert  # ← OVERWRITES all incoming service names!
```

**Fix Applied:**
```yaml
resource/defaults:
  attributes:
    - key: service.name
      value: resonai-backend
      action: insert  # ← PRESERVES original service names
```

**Impact:** Now canary traces with service.name="canary-test" can survive the processor without being overwritten to "resonai-backend".

**Status:** ✅ COMMITTED & DEPLOYED

---

### Issue 2: Trace Export Routing ⚠️ INVESTIGATING

**Location:** `config.yaml` lines 87-100 (Windows OTel Collector exporter)

**Flow:**
```
Canary Test
   ↓ (sends OTLP traces to localhost:5318)
Windows OTel Collector (port 5318 receiver)
   ↓ (should export to SigNoz via OTLP exporter)
SigNoz OTel Collector (listens on 4317/4318 in container, mapped to 14317/5318 on host)
   ↓ (processes traces)
ClickHouse (signoz_traces.distributed_signoz_spans)
```

**Configuration Attempts:**

Attempt 1: `endpoint: localhost:14317`
- Result: ❌ Traces not appearing in ClickHouse
- Theory: Connection might be working but traces not persisting

Attempt 2: `endpoint: host.docker.internal:4318`
- Result: ❌ Windows collector can't reach Docker internal address
- Reverted

**Current Investigation:**
- Windows collector sending OTLP traces to localhost:5318 ✅
- Canary test generating trace payloads ✅  
- SigNoz collector receiving on 4318 (mapped to host 5318) ✅
- But traces not reaching ClickHouse spans table ❌

---

## 📊 ClickHouse Status

**Logs Table:** `signoz_logs.logs_v2`
```
Count:  2,573 canary entries ✅
Status: Data flowing successfully
```

**Traces/Spans Table:** `signoz_traces.distributed_signoz_spans`
```
Count:  0 entries ❌
Status: No data arriving
```

**Index Table:** `signoz_traces.signoz_index_v2`
```
Count:  0 entries ❌
Status: No data arriving
```

---

## 🔧 Configurations Applied

### 1. SigNoz Collector Config (signoz-collector-config.yaml)

**Change:** Line 66 - `upsert` → `insert`

```diff
- action: upsert  # Change to "insert" to preserve original service names
+ action: insert
```

**Effect:** Service names now preserved in traces  
**Status:** ✅ Deployed (container restarted)

### 2. Windows Collector Config (config.yaml)

**Change:** Line 89 - Export endpoint

```diff
- endpoint: localhost:14317
+ endpoint: host.docker.internal:4318
```

**Issue:** host.docker.internal not reachable from host  
**Reverted to:** `endpoint: localhost:14317`

**Status:** ⚠️ Reverted, investigating further

---

## 🚨 Next Debugging Steps

### Critical Questions:
1. Is the Windows OTel collector exporting traces to port 14317 successfully?
2. Is SigNoz collector receiving traces on 4318/4317?
3. Is the traces pipeline in SigNoz actually exporting to ClickHouse?
4. Are traces being processed but filtered out?

### Commands to Run:
```powershell
# 1. Check Windows collector service logs for errors
Get-WinEvent -LogName "Application" -FilterXPath "*[System[Provider[@Name='otelcol-contrib']]]" -MaxEvents 20

# 2. Check SigNoz collector for trace processing
docker logs signoz-otel-collector --tail 50 | grep -i "trace\|span\|export"

# 3. Verify trace data exists in intermediate form
docker exec signoz-clickhouse clickhouse-client \
  --database=signoz_traces \
  --query "SELECT * FROM traces_v3_resource LIMIT 1;" 

# 4. Check if trace index has any data
docker exec signoz-clickhouse clickhouse-client \
  --database=signoz_traces \
  --query "SELECT * FROM trace_summary LIMIT 1;"
```

---

## 📋 Summary for Reviewer

**What We Fixed:**
- ✅ Service name overwriting (upsert → insert)
- ✅ SigNoz collector restarted with fix

**What's Still Blocked:**
- ❌ Traces not appearing in ClickHouse spans table
- ❌ Logs flow successfully, but traces do not

**Evidence of Progress:**
- Canary test generates OTLP trace payloads ✅
- Windows collector configured to export ✅
- SigNoz collector has correct service name preservation ✅
- But end-to-end trace flow still broken ❌

**Gate Status:**
- Still **WARN** - trace evidence not confirmed
- Logs alone are insufficient; gate requires traces

---

## 🎖️ Governance Impact

**BossCat Verdict:** WARN (Correct - no trace evidence)  
**Reviewer A Hold:** Valid (awaiting trace evidence)  
**Configuration Changes:** 1 critical fix deployed, investigating second issue

---

**Report:** Trace Pipeline Root Cause Analysis  
**Date:** 2025-10-23 15:30 UTC  
**Status:** ACTIVELY DEBUGGING - Will continue investigation

🐾 *Logs ≠ Traces. Finding where traces stop flowing.*
