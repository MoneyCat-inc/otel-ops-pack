# 🎯 SigNoz v3 Schema Discovery

**Date:** 2025-10-23 21:40 UTC  
**Discovery:** Correct table and column structure for traces in SigNoz v3  
**Status:** ✅ SCHEMA IDENTIFIED

---

## Breakthrough Finding

**We were querying the WRONG table for 51 checks.**

### What We Were Using (WRONG)

```sql
-- ❌ This table is EMPTY in v3
SELECT count() FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
```

### What Actually Works (CORRECT - v3 Schema)

```sql
-- ✅ v3 uses signoz_index_v3 with materialized columns
SELECT count() FROM signoz_traces.signoz_index_v3
WHERE resource_string_service$$name='canary-test'
```

---

## v3 Schema Structure

### Key Tables

| Table | Rows | Purpose |
|-------|------|---------|
| **signoz_index_v3** | 1392 | Main trace index (v3) ✅ USE THIS |
| span_attributes | 0 | Empty in v3 (deprecated?) |
| tag_attributes_v2 | 2380 | Tag storage |
| top_level_operations | 1142 | Operation index |
| traces_v3_resource | 26 | Resource fingerprints |
| signoz_spans | 1 | Raw span data |

### v3 Index Columns (signoz_index_v3)

**Critical Materialized Columns:**

- `resource_string_service$$name` — Service name (from resources_string['service.name'])
- `attribute_string_http$$route` — HTTP route (from attributes_string['http.route'])
- `attribute_string_db$$system` — Database system
- `attribute_string_rpc$$system` — RPC system

**Core Columns:**

- `timestamp` — DateTime64(9)
- `trace_id` — FixedString(32)
- `span_id` — String
- `name` — Span operation name
- `duration_nano` — Span duration
- `resources_string` — Map(String, String) — Resource attributes
- `attributes_string` — Map(String, String) — Span attributes

---

## Correct Queries for v3

### Count Recent Canary Traces

```powershell
docker exec signoz-clickhouse clickhouse-client --query "
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE ``resource_string_service`$`$name``='canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE;"
```

### List All Service Names

```powershell
docker exec signoz-clickhouse clickhouse-client --query "
SELECT ``resource_string_service`$`$name`` AS service_name, count() AS span_count
FROM signoz_traces.signoz_index_v3
GROUP BY service_name
ORDER BY span_count DESC
LIMIT 20;"
```

**Current Results:**

```yaml
resonai-backend: 1391 spans
canary-test:     1 span (from manual test, older than 10 min)
```

### Timeline by Minute

```powershell
docker exec signoz-clickhouse clickhouse-client --query "
SELECT toStartOfMinute(timestamp) AS minute, count() AS c
FROM signoz_traces.signoz_index_v3
WHERE ``resource_string_service`$`$name``='canary-test'
  AND timestamp >= now() - INTERVAL 30 MINUTE
GROUP BY minute
ORDER BY minute DESC
LIMIT 10;"
```

---

## Platform Gap Status (Updated Understanding)

### What We Now Know

✅ **v3 schema structure identified** (signoz_index_v3 with materialized columns)  
✅ **Query method works** (found 1 existing canary-test span)  
✅ **Service name preservation works** (canary-test not overwritten to resonai-backend)  
❌ **Fresh traces still not persisting** (0 recent spans despite HTTP 200 from SigNoz)

### Evidence

```yaml
Historical span:     1 canary-test (all-time)
Fresh canary sent:   2025-10-23 21:39 UTC (HTTP 200)
Fresh span query:    0 (last 5 minutes)
Conclusion:          Exporter→ClickHouse persistence gap STILL PRESENT
```

---

## Why 51 Checks Showed 0

**Root Cause:** We were querying `span_attributes` table (which is empty in v3)

**Correct Table:** `signoz_index_v3` with `resource_string_service$$name` column

**Impact:**

- All 51 checks were querying the wrong table
- The checks were "working" (no errors) but looking in the wrong place
- Now corrected to v3 schema

---

## Scripts Updated

| Script | Old Table | New Table | Status |
|--------|-----------|-----------|--------|
| `gate-self-signal-check.ps1` | span_attributes | signoz_index_v3 | ✅ Fixed |
| `gate-advance.ps1` | span_attributes | signoz_index_v3 | ✅ Fixed |
| `gate-self-signal-monitor.ps1` | Uses check script | (inherits fix) | ✅ Ready |

---

## Next Steps

### 1. Restart Monitoring with Correct Query

✅ **DONE** — Monitoring loop restarted with v3 schema queries

### 2. Verify Fresh Traces Persist

⏳ **IN PROGRESS** — Monitoring loop will now correctly detect when SigNoz starts persisting

### 3. System for Trace Reingestion (User Request)

🔄 **PENDING** — Need to create system to:

- Understand v3 schema transformations
- Reingest modified traces if needed
- Handle service name renaming logic

---

## Platform Gap (Still Present)

**Despite correct v3 queries:**

- Fresh canary sent: ✅ HTTP 200
- Fresh trace in ClickHouse: ❌ 0 rows (last 5 min)
- Platform gap: **STILL PRESENT**

The exporter→ClickHouse persistence issue remains, but now we're querying the correct v3 schema structure.

---

**🐾 V3 schema discovered. Queries corrected. Monitoring restarted. Platform gap persists. Ready to build trace
reingestion system as requested.**
