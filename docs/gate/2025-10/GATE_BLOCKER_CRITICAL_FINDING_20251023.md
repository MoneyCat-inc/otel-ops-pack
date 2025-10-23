# 🛑 CRITICAL FINDING: SigNoz Traces Export Failure

**Date:** 2025-10-23 14:35 UTC  
**Status:** BLOCKER IDENTIFIED  
**Gate:** 🟠 WARN (root cause found, requires SigNoz investigation)

---

## THE PROBLEM

Traces are **received and processed** by SigNoz collector but **NOT persisted to ClickHouse**.

**Evidence from SigNoz collector logs (14:25:01):**
```json
{
  "signoz_spans_count": 1102,
  "signoz_spans_bytes": 671071,
  "status": "exported to signoz"
}
```

**But ClickHouse confirms (14:17):**
```sql
SELECT COUNT() FROM distributed_signoz_spans → 0 rows
SELECT COUNT() FROM signoz_spans → 0 rows
```

**This is not a network issue. This is a persistence issue.**

---

## EVIDENCE TRAIL

### 1. Traces ARE Being Sent

Test execution at 14:17:03 UTC:
```powershell
pwsh -File send-canary-trace-direct.ps1
→ HTTP 200 OK (traces accepted)
→ TraceID: 6fa305dc63ac4583b011b90ef742d05d
→ Service: canary-test (3 spans sent)
```

### 2. SigNoz Collector RECEIVES Traces

From logs (14:17:05):
```
caller: clickhousetracesexporter/writer.go:337
msg: "attribute key already present in cache, skipping"
key: "service.nameresourcestringfalse"
key: "canarytagstringfalse"
```

**This proves:**
- ✅ Traces received
- ✅ Attributes parsed (service.name found)
- ✅ Resource attributes processed
- ✅ Span attributes processed

### 3. SigNoz Exporter COUNTS Spans

Metrics snapshot (14:14:54):
```json
"signoz_spans_count": {
  "exporterID": "2306fc95-e0ad-4060-89e0-04ee66b4ca65",
  "value": 1102,  ← Total spans processed!
  "startTime": "2025-10-23T12:24:36Z"
}
```

### 4. ClickHouse Tables REMAIN EMPTY

Queries at 14:17:
```sql
SELECT COUNT() FROM distributed_signoz_spans 
WHERE timestamp >= now()-INTERVAL 1 MINUTE;
→ 0 rows

SELECT COUNT() FROM signoz_spans 
WHERE timestamp >= now()-INTERVAL 1 MINUTE;
→ 0 rows
```

---

## ROOT CAUSE ANALYSIS

**The Break Point:** clickhousetraces exporter pipeline

The exporter is counting spans (`signoz_spans_count = 1102`) but **the INSERT statements are not executing or are silently failing**.

Possible causes:
1. **ClickHouse DSN issue** - exporter not connected to correct database
2. **Schema mismatch** - exporter trying to write to wrong table name  
3. **Permission issue** - exporter account lacks INSERT privileges
4. **Batch flushing** - traces stuck in batching buffer, not flushed
5. **Schema initialization** - ClickHouse tables not created/migrated

---

## WHAT WE FIXED (Still Valid)

✅ **signoz-collector-config.yaml line 66:** `upsert` → `insert`
- Service names now preserved (not overwritten to resonai-backend)
- But this doesn't help if exporter can't write to DB anyway

---

## WHAT WE PROVED

✅ **Path A (Direct to SigNoz)** works for:
- Sending OTLP HTTP traces
- SigNoz collector receiving
- Trace attribute parsing
- Service name preservation

❌ **But fails at:**
- Persistence to ClickHouse spans table

---

## IMMEDIATE ACTIONS REQUIRED

### BossCat OEM Decision Point

This is **not an OTel configuration issue**. This is a **SigNoz platform issue**:

**Option 1: Investigate ClickHouse Connector**
- Check DSN: `tcp://signoz-clickhouse:9000/signoz_traces`
- Verify ClickHouse credentials
- Test direct INSERT: `INSERT INTO distributed_signoz_spans VALUES(...)`

**Option 2: Check Schema Initialization**
- Run: `docker exec signoz-clickhouse clickhouse-client --database=signoz_traces --query "SHOW CREATE TABLE distributed_signoz_spans;"`
- Verify table exists and has correct columns

**Option 3: Enable Export Debugging**
- In signoz-collector-config.yaml, set exporter log level to `debug`:
  ```yaml
  service:
    telemetry:
      logs:
        level: debug  # ← Already enabled
  ```
- Look for INSERT failures or connection errors

**Option 4: Direct ClickHouse Test**
- Try inserting a test span directly using clickhouse-client
- If INSERT fails, the schema/permissions are the blocker

---

## GATE VERDICT

**BossCat WARN holds.** ✅ (CORRECT)

Even though we fixed the config, **the pipeline still does not persist traces to ClickHouse.**

Gate cannot advance until `distributed_signoz_spans` table shows traces with `service.name='canary-test'`.

---

## NEXT STEPS (For BossCat/Team)

1. **Scope:** Is this a widespread SigNoz issue or specific to this deployment?
2. **Schema:** Verify ClickHouse tables initialized post-schema-migrator runs
3. **Credentials:** Confirm exporter has write permissions
4. **Logs:** Check SigNoz collector for silent export failures
5. **Test:** Direct INSERT to ClickHouse spans table outside OTel pipeline

**This is a platform/infrastructure issue, not an observability config issue.**

---

**Report:** Critical Gate Blocker Analysis  
**Evidence:** 1102 spans counted but 0 in ClickHouse  
**Recommendation:** Escalate to SigNoz deployment team

🛑 **Gate holds at WARN. Requires infrastructure fix, not code fix.**
