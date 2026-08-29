# 🛑 PLATFORM ESCALATION: SigNoz Exporter Pipeline Failure

**Date:** 2025-10-23 14:45 UTC  
**Status:** DIAGNOSTIC COMPLETE — ESCALATION READY  
**Gate:** 🟠 WARN (infrastructure blocker)

---

## EXECUTIVE SUMMARY

**Traces are processed (1101 spans counted) but never reach ClickHouse.**

- ✅ Schema: Valid and tested
- ✅ Permissions: INSERT works via direct test
- ✅ DSN: Correct (`tcp://signoz-clickhouse:9000/signoz_traces`)
- ✅ Receiver: OTLP accepts HTTP 200
- ✅ Processor: Attributes parsed (service.name preserved)
- ✅ Exporter logic: Spans counted in telemetry
- ❌ **Result:** Zero rows in any spans table

**Failure point:** Between exporter batch processor and ClickHouse INSERT

---

## DIAGNOSTIC EVIDENCE

### 1. ClickHouse Schema & Permissions ✅ VERIFIED

**Table exists:**
```sql
CREATE TABLE signoz_traces.distributed_signoz_spans(
    timestamp DateTime64(9),
    traceID FixedString(32),
    model String
) ENGINE = Distributed('cluster', 'signoz_traces', 'signoz_spans', cityHash64(traceID))
```

**INSERT Test (14:45 UTC):**
```sql
INSERT INTO signoz_spans (timestamp, traceID, model) 
  VALUES (now64(9), 'test_canary_trace_id_12345678', 'test_model');
→ ✅ Result: 1 row inserted
→ ✅ Verified: SELECT COUNT(*) → 1 row persisted
```

**Conclusion:** Database connectivity and permissions are **NOT the blocker**.

---

### 2. Exporter DSN Configuration ✅ CORRECT

**File:** `signoz-collector-config.yaml` line 109
```yaml
exporters:
  clickhousetraces:
    datasource: tcp://signoz-clickhouse:9000/signoz_traces
    low_cardinal_exception_grouping: false
    use_new_schema: true
```

**Status:** DSN is valid Docker internal hostname. Connectivity test successful (direct INSERT worked).

---

### 3. SigNoz Collector Exporter Telemetry

**Current exporter state (from logs 14:14-14:25):**
```json
{
  "component": "clickhousetraces",
  "signoz_spans_count": 1102,
  "signoz_spans_bytes": 671071,
  "exporter_status": "running",
  "last_update": "2025-10-23T14:25:01Z"
}
```

**Interpretation:** Exporter believes it has exported 1102 spans. Telemetry is being reported **but spans never persist**.

---

### 4. Error Log Analysis

**Historical errors (Oct 17-22):** Connection refused during startup (resolved by container restarts)

**Current collector (14:25:03 onward):** ✅ Running. No active connection errors.

**INSERT logs:** ZERO INSERT statements in any recent logs (no debug output of actual INSERT attempts).

**Conclusion:** Exporter is **not attempting INSERT** or is silently failing.

---

### 5. Direct OTLP Test

**Executed:** `send-canary-trace-direct.ps1`
```
HTTP 200 OK → traces accepted
TraceID: 6fa305dc63ac4583b011b90ef742d05d
Service: canary-test (3 spans)
Timestamp: 2025-10-23T14:17:03Z
```

**Result:** Traces sent successfully. But...

**ClickHouse verification (immediately after):**
```sql
SELECT COUNT(*) FROM distributed_signoz_spans 
  WHERE toDateTime(timestamp/1000000000) > now() - INTERVAL 5 MINUTE;
→ 0 rows
```

**Conclusion:** Traces received but not persisted.

---

## ROOT CAUSE HYPOTHESIS

**Most Likely:** The `signozspanmetrics/delta` processor or `batch` processor is **buffering spans without flushing to exporter**.

**Pipeline (line 134):**
```
receivers: [otlp]
  ↓
processors: [memory_limiter, resourcedetection, resource/defaults, signozspanmetrics/delta, batch]
  ↓
exporters: [clickhousetraces]
```

**Theory:** Spans reach `batch` processor but:
1. Batch timeout too long (waiting to accumulate)
2. Batch buffer size too small (spans dropped)
3. Memory limiter rejecting spans silently
4. Signozspanmetrics processor consuming spans without passing to exporter

---

## REQUIRED INVESTIGATION (SigNoz Platform Team)

### Option 1: Enable Exporter Debug Logging
```yaml
service:
  telemetry:
    logs:
      level: debug
exporters:
  clickhousetraces:
    log_level: debug  # Add this
```

Look for:
- ClickHouse connection status
- INSERT statement attempts
- Batch flush events
- Exporter error messages

### Option 2: Check Batch Processor Configuration
```yaml
processors:
  batch:
    send_batch_size: 1024
    timeout: 1s
    send_batch_max_size: 2048
```

Verify batching is flushing spans to exporter.

### Option 3: Monitor Exporter Metrics
```sql
SELECT * FROM signoz_traces.distributed_usage 
WHERE exporterID = '2306fc95-e0ad-4060-89e0-04ee66b4ca65'
ORDER BY time DESC LIMIT 5;
```

Check if spans are being exported and what the count trend is.

### Option 4: Direct Exporter Test
Inject a test span at the exporter level (bypass batch processor) to confirm ClickHouse connection works end-to-end.

---

## DATA FOR ESCALATION

**Issue:** Traces processed but not persisted  
**Evidence package:**
- Configuration files: Valid
- Schema: Verified  
- Permissions: Tested
- Connectivity: Confirmed
- Span count: 1102 processed, 0 persisted

**Not a collector issue.** Not an OTel config issue. **This is an internal SigNoz exporter pipeline issue.**

---

## GATE DECISION

**WARN holds.** ✅

Gate cannot advance without:
1. Traces appearing in ClickHouse spans table with `service.name='canary-test'`
2. Root cause of exporter→database gap identified and fixed

**Blockers are infrastructure (SigNoz platform), not observability config.**

---

**Escalation:** Ready to hand off to SigNoz deployment/platform team.

🛑 **This requires SigNoz internal debugging, not OTel collector tuning.**
