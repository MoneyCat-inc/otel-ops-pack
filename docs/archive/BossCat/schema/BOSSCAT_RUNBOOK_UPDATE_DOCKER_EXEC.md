# BossCat Runbook Update — Docker Exec Method Alignment

**Date:** 2025-10-23 17:30 UTC  
**Lane:** DOCS (documentation alignment)  
**Budgets:** ≤10 files, ≤200 LOC  
**Authority:** BossCat OEM Decision (A + C)

---

## Decision Summary

**Use:** Docker exec + span_attributes method (proven working in this environment)  
**Update:** BossCat runbook Sections 1-3 to match live implementation  
**Skip:** HTTP/8123 port mapping (infrastructure drift, not required for gate evidence)

---

## Runbook Patch — Sections 1-3 (Replace Entirely)

### **Section 1: Re-verify end-to-end span flow**

```powershell
# Send 5 canary spans to verify stability
1..5 | % { 
    pwsh -File .\send-canary-trace-direct.ps1
    Start-Sleep -Seconds 2
}

# Verify traces using docker exec method (environment-specific, tested)
$Query = @"
SELECT count()
FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE
"@

$count = docker exec signoz-clickhouse clickhouse-client --query "$Query"
Write-Host "Traces found: $count"
```

**Expected:** Counts increase with each canary burst (traces persisting consistently).

> **Note:** This deployment uses containerized ClickHouse without HTTP port mapping to the host. The `docker exec`
  method provides equivalent evidence without requiring infrastructure changes. Other deployments may use HTTP on
  `localhost:8123` if the port is exposed.

---

### **Section 2: Regenerate gate artifacts (ECRR)**

Capture evidence and keep it small/clean per BossCat budgets (≤10 files, ≤200 LOC). Include:

**A. Query Output** showing non-zero counts for `canary-test` in the last N minutes.

**Example Evidence Markdown:**

```markdown
# TRACE_GATE_VERIFICATION — 2025-10-23T17:30:00Z

## Evidence
- Endpoint/Protocol: docker exec (containerized ClickHouse client)
- Service: canary-test
- Window: now() - 5 min
- Query:
  ```sql
  SELECT count() FROM signoz_traces.span_attributes
  WHERE tagKey='service.name'
    AND stringTagValue='canary-test'
    AND timestamp >= now() - INTERVAL 5 MINUTE;
  ```

- Result: COUNT = [N spans detected]

## Contain

(n/a — verification only)

## Rollback

(n/a — no changes required)

## Report

Gate satisfied: traces persisted for canary-test. Flip WARN→GREEN.

```text

**B. Collector Config Excerpt** proving `resource/defaults: action: insert` (preserves service names).

**C. One-liner event log** in `docs/BossCat/BOSSCAT_LOG.md`:
```

- 2025-10-23T17:30:00Z TRACE_GATE ✅ spans for canary-test persisted (count=N, window=5m, method=docker-exec)

```text

**D. ECRR artifact JSON** under `artifacts/ecrr/gate/`:
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

> BossCat gate is pass/fail on objective evidence; treat this like the performance/observability quality gate described
  in our CI guide (thresholds + promote only on green).

---

### **Section 3: Flip the verdict**

**Condition to go GREEN:**

- `count() > 0` in **`signoz_traces.span_attributes`** (via docker exec)
- Filter: `tagKey='service.name'` AND `stringTagValue='canary-test'`
- Within **≤10 min** window
- Repeated run proves stability (counts increase with canary bursts)

**Action:** Post **@cat ready-for-gate** with the evidence bundle; BOSSCAT/IONA will mark GREEN.

**Example Gate Message:**

```bash
@cat ready-for-gate

🟢 GATE VERDICT: GREEN (Platform Fix Confirmed)

✅ Evidence Bundle:
- Traces for service.name='canary-test' detected in ClickHouse
- Query method: docker exec signoz-clickhouse clickhouse-client
- Table: signoz_traces.span_attributes  
- Span count (last 5 min): N
- Stability verified (5 canary bursts, consistent growth)
- Collector config: service.name preservation active (action: insert, not upsert)

📦 Artifacts:
- TRACE_GATE_VERIFICATION_YYYYMMDD.md (query output + verification)
- gate-verification-YYYYMMDD.json (ECRR artifact)
- signoz-collector-config.yaml (config proof: insert not upsert)
- send-canary-trace-direct.ps1 (reproducible test)

🎯 Gate transitions: 🟠 WARN → 🟢 GREEN
```

---

## Environment Note (Add to Runbook Appendix)

**Why Docker Exec Method:**

This deployment uses containerized ClickHouse (`signoz-clickhouse`) without HTTP port 8123 mapped to the Windows host.
The `docker exec` method provides equivalent gate evidence without infrastructure changes:

```powershell
# Containerized query (this environment)
docker exec signoz-clickhouse clickhouse-client --query "SELECT..."

# vs. HTTP endpoint (if port 8123 is exposed to host)
# curl "http://localhost:8123/?query=..."
```

Both methods query the same ClickHouse backend. Use whichever matches your deployment's port mapping.

**Schema Note:** This environment uses `signoz_traces.span_attributes` with `tagKey`/`stringTagValue` columns for
resource/span attributes, rather than top-level `serviceName` or `service_name` columns in the main spans table. Adjust
filters to match your ClickHouse schema version.

---

## Rationale (ECRR Alignment)

**Why not fix HTTP/8123 port mapping:**

- Infrastructure work not required for gate evidence
- Expands blast area and delays gate advancement
- ECRR doctrine: **small, safe steps**; **changed-paths only**
- Avoid broad infrastructure changes to satisfy verification preference
- Docker exec provides equivalent evidence without runtime changes

**Why docker exec is acceptable:**

- Queries same ClickHouse backend as HTTP
- Proven operational (validated in checks #2-3)
- No infrastructure drift
- Maintains ECRR single-writer discipline
- Complies with BossCat budgets (documentation change only)

---

## Implementation Status

**Live System (Current):**

- ✅ `gate-self-signal-check.ps1`: Uses docker exec + span_attributes
- ✅ `gate-self-signal-monitor.ps1`: Uses docker exec method (running)
- ✅ `GATE_SELF_SIGNAL_PROTOCOL.md`: Aligned to docker exec (fixed)
- ✅ `GATE_SELF_SIGNAL_OPERATIONAL_SUMMARY.md`: Aligned to docker exec (fixed)

**BossCat Official Runbook:**

- ⏳ Sections 1-3: Requires update with Runbook Patch above
- ⏳ Appendix: Requires Environment Note addition

---

## Budgets & Lane Compliance

| Item | Limit | Actual | Status |
|------|-------|--------|--------|
| **Files Changed** | ≤10 | 1 (runbook) | ✅ Within |
| **LOC Changed** | ≤200 | ~100 | ✅ Within |
| **Lane** | DOCS only | Documentation update | ✅ Compliant |
| **Runtime Changes** | None | None | ✅ Safe |
| **Infrastructure** | No changes | No port mapping | ✅ Clean |

---

## ECRR Framework

**Evidence:** Docker exec method proven operational (checks #2-3)  
**Contain:** Documentation alignment only (no runtime changes)  
**Rollback:** N/A (documentation update, easily reverted)  
**Report:** This update document captures decision and implementation

---

**🐾 Ready to apply runbook update to official BossCat documentation.**

**When you approve, I'll update the official runbook with the Runbook Patch above.**

