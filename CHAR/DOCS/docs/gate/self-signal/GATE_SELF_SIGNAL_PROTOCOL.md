# 🔔 Gate Self-Signal Protocol

**Status:** ✅ ACTIVE  
**Date:** 2025-10-23  
**Authority:** Cursor{Implementer} under ECRR + BossCat gate discipline  
**Current Gate:** 🟠 WARN (awaiting platform fix)

---

## 🎯 Purpose

Enable **autonomous detection** when SigNoz platform team fixes the exporter→ClickHouse gap, without requiring human
ping. Gate advancement is triggered by **objective evidence** (traces appear) detected through continuous self-signal
checks.

---

## 📋 Self-Signal Protocol

### **Command**

```powershell
pwsh -File gate-self-signal-check.ps1
```

### **What It Does**

1. ✅ Sends canary trace (OTLP HTTP) with `service.name="canary-test"`
2. ✅ Waits 2 seconds for ClickHouse ingestion
3. ✅ Queries: `SELECT count() FROM signoz_traces.span_attributes WHERE tagKey='service.name' AND
   stringTagValue='canary-test' AND timestamp >= now() - 10 min` (via docker exec)
4. ✅ Returns exit code based on result

### **Exit Codes**

| Code | Signal | Meaning | Action |
|------|--------|---------|--------|
| **0** | 🟢 GREEN | count() > 0 | Platform fix landed → Execute gate runbook |
| **1** | 🟠 WARN | count() = 0 | Platform gap persists → Hold, continue ECRR |
| **2** | ⚠️ ERROR | Query failed | ClickHouse unreachable → Check infrastructure |

---

## ?? Section 1 - Re-Verify End-to-End Span Flow

```powershell
# Send 5 canary bursts (ensures stability)
1..5 | ForEach-Object {
    pwsh -File .\send-canary-trace-direct.ps1
    Start-Sleep -Seconds 2
}

# Query ClickHouse using the vetted method
$Query = @"
SELECT count()
FROM signoz_traces.span_attributes
WHERE tagKey=''service.name''
  AND stringTagValue=''canary-test''
  AND timestamp >= now() - INTERVAL 5 MINUTE
"@

$count = docker exec signoz-clickhouse clickhouse-client --query "$Query"
Write-Host "Traces found (last 5 minutes): $count"
```

- **Expectation:** `$count` increases as each canary burst lands. Record the starting value and the post-burst value.
- **Result > 0:** Continue to Section 2.
- **Result = 0:** Hold at ?? WARN and resume monitoring; do not advance the gate.

---

## ?? Section 2 - Regenerate Gate Artifacts (ECRR)

Stay within budgets (<= 10 files, <= 200 LOC). Capture:

1. **Query evidence markdown** (`TRACE_GATE_VERIFICATION_YYYYMMDD.md`)

   ```markdown
   # TRACE_GATE_VERIFICATION - 2025-10-23T17:30:00Z

   ## Evidence
   - Query method: docker exec signoz-clickhouse clickhouse-client
   - Table: signoz_traces.span_attributes
   - Filter: tagKey=''service.name'', stringTagValue=''canary-test''
   - Window: now() - 5 minutes
   - Result: COUNT = <N>
   ```

2. **Collector config excerpt** proving `resource/defaults` uses `action: insert`.
3. **BossCat log entry** (`docs/BossCat/BOSSCAT_LOG.md`)

   ```text
   - 2025-10-23T17:30:00Z TRACE_GATE ✅ spans for canary-test persisted (count=N, window=5m, method=docker-exec)
   ```

4. **ECRR JSON artifact** (`artifacts/gate-verification-YYYYMMDD.json`)

   ```json
   {
     "gate": "trace-persistence",
     "verdict": "GREEN",
     "timestamp": "2025-10-23T17:30:00Z",
     "evidence": {
       "service_name": "canary-test",
       "span_count": "N",
       "window": "5 minutes",
       "query_method": "docker exec",
       "table": "span_attributes",
       "stability": "confirmed"
     }
   }
   ```

Keep the changed-paths tight; no extra files beyond the bundle above.

---

## ?? Section 3 - Flip the Verdict

**Go GREEN only when all checklist items pass:**

- `count() > 0` in `signoz_traces.span_attributes` for the last <= 10 minutes.
- Stability proven (burst counts increase and are documented in Section 2 evidence).
- `signoz-collector-config.yaml` shows `action: insert` (service.name preserved).
- Evidence bundle assembled (markdown, JSON artifact, config excerpt, BossCat log entry, script reference).
- No new blockers discovered during verification.

**Ready-for-gate message (paste-ready):**

```bash
@cat ready-for-gate

?? GATE VERDICT: GREEN (Platform Fix Confirmed)

? Evidence:
- docker exec signoz-clickhouse clickhouse-client query (span_attributes, service.name=''canary-test'')
- Window: last 5 minutes, COUNT = N
- Stability: 5 burst sample, counts increased each run
- Collector resource/defaults: action=insert (service.name preserved)

?? Artifacts:
- TRACE_GATE_VERIFICATION_YYYYMMDD.md
- artifacts/gate-verification-YYYYMMDD.json
- docs/BossCat/BOSSCAT_LOG.md (entry appended)
- signoz-collector-config.yaml excerpt
- send-canary-trace-direct.ps1 (reference test)

?? Gate Transition: ?? WARN -> ?? GREEN
```

If any item fails, return to monitoring and do **not** signal.

---

## ??? Continuous Monitoring (Optional)

The background loop remains authorized until the platform fix lands:

```powershell
while ($true) {
    & pwsh -File gate-self-signal-check.ps1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "?? PLATFORM FIX DETECTED - Execute runbook" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 1800
}
```

---

## ?? Appendix A - Environment Note

- **Why docker exec:** ClickHouse HTTP port 8123 is not exposed to the Windows host. Executing the client inside the
  container reaches `tcp://signoz-clickhouse:9000/signoz_traces` without infrastructure changes.
- **Schema nuance:** `service.name` resides in `signoz_traces.span_attributes` (`tagKey`, `stringTagValue`). Index
  tables queried by serviceName will return 0 even when data exists.
- **Optional hardening:** To preserve original service names, keep `action: insert` (never `upsert`) in
  `resource/defaults`.

---

## ?? Doctrine Alignment

| Principle | Implementation |
|-----------|-----------------|
| **Evidence-first** | docker exec + span_attributes query with recorded counts |
| **Fast feedback** | Self-signal loop plus 5-burst verification |
| **Gate discipline** | Checklist enforced before posting @cat ready-for-gate |
| **Single writer** | Docs lane only, budgets within limits |
| **Safe promotion** | GREEN signal only after evidence bundle is complete |

---

**?? Self-signal active. Autonomous detection engaged. Awaiting platform resolution.**

When traces land -> Gate advances -> Ready-for-gate signal -> ?? GREEN

??
