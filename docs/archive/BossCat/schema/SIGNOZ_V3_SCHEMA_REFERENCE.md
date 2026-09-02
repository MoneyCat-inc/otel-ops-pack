# 🎯 SigNoz v3 Schema Reference — Canonical Query Guide

**Date:** 2025-10-23  
**Authority:** BossCat OEM + Field Validation  
**Status:** ✅ AUTHORITATIVE

---

## V3 Schema Mapping (Authoritative)

### **Correct Table**
```
signoz_traces.signoz_index_v3  ← USE THIS FOR TRACES
```

### **Service Name Column**
```
resource_string_service$$name  ← Materialized from resources_string['service.name']
```

### **Why v3 is Different**

| Aspect | Old/Wrong | v3 (Correct) |
|--------|-----------|--------------|
| **Table** | distributed_signoz_spans | signoz_index_v3 |
| **Service Column** | serviceName OR service_name | resource_string_service$$name |
| **Access Method** | HTTP localhost:8123 | docker exec (HTTP not exposed) |
| **Attribute Storage** | span_attributes separate table | Materialized columns + map columns |

---

## Canonical Queries (Copy-Paste Ready)

### **A. Gate Predicate — Last 5 Minutes**
```bash
docker exec signoz-clickhouse clickhouse-client -q "
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE \`resource_string_service$$name\` = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE"
```

**Gate Success:** `count() > 0` → GREEN  
**Gate Hold:** `count() = 0` → WARN

### **B. Last Seen Timestamp**
```bash
docker exec signoz-clickhouse clickhouse-client -q "
SELECT max(timestamp) AS last_seen
FROM signoz_traces.signoz_index_v3
WHERE \`resource_string_service$$name\` = 'canary-test'"
```

### **C. Timeline (Per Minute, Last Hour)**
```bash
docker exec signoz-clickhouse clickhouse-client -q "
SELECT toStartOfMinute(timestamp) AS minute, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE \`resource_string_service$$name\`='canary-test'
  AND timestamp >= now() - INTERVAL 60 MINUTE
GROUP BY minute
ORDER BY minute"
```

### **D. Attribute Cross-Check (v3 Write-Path Validation)**
```bash
docker exec signoz-clickhouse clickhouse-client -q "
SELECT count()
FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE"
```

**Note:** In v3, span_attributes may be empty or sparse. Primary data is in signoz_index_v3.

### **E. Service Mix View (Last 24 Hours)**
```bash
docker exec signoz-clickhouse clickhouse-client -q "
SELECT \`resource_string_service$$name\` AS svc, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE timestamp >= now() - INTERVAL 24 HOUR
GROUP BY svc ORDER BY spans DESC"
```

---

## Current V3 Data (Verified)

```
Service Name          | Total Spans | First Seen           | Last Seen
──────────────────────────────────────────────────────────────────────────────
resonai-backend       | 1391        | 2025-10-08 02:28:13 | 2025-10-23 14:17:04
canary-test           | 1           | 2025-10-23 14:25:30 | 2025-10-23 14:25:30
```

**Evidence:**
- ✅ Service preservation works (canary-test NOT renamed to resonai-backend)
- ✅ v3 schema stores service names correctly
- ✅ Materialized column queries working
- ❌ Fresh traces not persisting (last canary-test span 7+ hours old)

---

## V3 Schema Insights

### Materialized Columns (Fast Queries)
```
resource_string_service$$name    → resources_string['service.name']
attribute_string_http$$route     → attributes_string['http.route']
attribute_string_db$$system      → attributes_string['db.system']
attribute_string_rpc$$system     → attributes_string['rpc.system']
attribute_string_rpc$$service    → attributes_string['rpc.service']
attribute_string_rpc$$method     → attributes_string['rpc.method']
```

### Map Columns (Full Attribute Access)
```
resources_string    → Map(LowCardinality(String), String)
attributes_string   → Map(LowCardinality(String), String)
attributes_number   → Map(LowCardinality(String), Float64)
attributes_bool     → Map(LowCardinality(String), Bool)
```

---

## PowerShell Query Helpers

### Query with Backtick Escaping
```powershell
# PowerShell requires backtick escaping for $$ in column names
$query = "SELECT count() FROM signoz_traces.signoz_index_v3 WHERE ``resource_string_service`$`$name``='canary-test';"
docker exec signoz-clickhouse clickhouse-client --query $query
```

### Direct Bash-Style (Simpler)
```powershell
# Use single quotes in bash command (passed through docker exec)
docker exec signoz-clickhouse clickhouse-client -q "
SELECT count() FROM signoz_traces.signoz_index_v3
WHERE \`resource_string_service$$name\`='canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE"
```

---

## Gate Decision Matrix (v3)

| Query A Result | Exit Code | Verdict | Action |
|----------------|-----------|---------|--------|
| count() > 0 | **0 (GREEN)** | Traces persisting | Package evidence → @cat ready-for-gate |
| count() = 0 | **1 (WARN/HOLD)** | Platform gap persists | Continue monitoring |
| Query error | **2 (ERROR)** | Infrastructure issue | Check ClickHouse health |

---

## Collector Configuration (Validated)

### Service Name Preservation ✅ WORKING
```yaml
# signoz-collector-config.yaml line 66
processors:
  resource/defaults:
    attributes:
      - key: service.name
        value: resonai-backend
        action: insert  # ← Preserves canary-test (not upsert)
```

**Evidence:** 1 canary-test span exists with correct service name (not overwritten)

---

## Platform Gap (Updated Understanding)

### What Works
- ✅ v3 schema structure (signoz_index_v3)
- ✅ Service name preservation (insert not upsert)
- ✅ Historical traces (1391 resonai-backend, 1 canary-test)
- ✅ Materialized column queries (resource_string_service$$name)

### What's Broken
- ❌ Fresh trace persistence (0 recent canary-test despite HTTP 200)
- ❌ Exporter→ClickHouse write path for new spans
- ❌ Batch flushing or connector issue

### Evidence
```
Fresh canary sent:       2025-10-23 21:39 UTC (HTTP 200)
Last canary-test span:   2025-10-23 14:25 UTC (7+ hours ago)
Recent query (5 min):    0 spans
Platform gap:            Confirmed (fresh traces not persisting)
```

---

## Tools Deployed

| Tool | Purpose | Status |
|------|---------|--------|
| `analyze-trace-schema.ps1` | Discover services, analyze activity | ✅ Working |
| `gate-self-signal-check.ps1` | Single check (v3 query) | ✅ Updated |
| `gate-advance.ps1` | Evidence packaging (v3 query) | ✅ Updated |
| `gate-self-signal-monitor.ps1` | 2-min polling loop (v3 query) | 🟢 Running |

---

## Next Steps

### Immediate
1. ⏳ **Awaiting:** One-liner wrapper from BossCat (check→advance→report)
2. ✅ **Running:** Low-latency monitoring (2-min polling with v3 queries)
3. 🔄 **Platform:** SigNoz team to fix fresh trace persistence

### When Traces Appear
1. ✅ Monitoring detects count() > 0 (within 2 min)
2. ✅ Execute one-liner wrapper (when provided)
3. ✅ Package evidence + ECRR artifacts
4. ✅ Post @cat ready-for-gate
5. ✅ Flip verdict: 🟠 WARN → 🟢 GREEN

---

**🐾 V3 schema locked in. Queries corrected. Ready for one-liner wrapper to complete the automation.**
