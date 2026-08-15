# 🟢 Gate GREEN Flip Procedure

**Date:** 2025-10-23  
**Authority:** BossCat OEM + Cursor{Implementer}  
**Status:** ✅ READY FOR EXECUTION

---

## 🎯 Purpose

Execute evidence-based gate advancement when SigNoz platform fix lands and traces begin persisting to ClickHouse.

**Gate Requirement:** Traces with `service.name="canary-test"` must persist in ClickHouse  
**Evidence Method:** Docker exec queries to span_attributes table  
**Success Criteria:** `count() ≥ 1` in last 5 minutes

---

## 🚀 Quick Execution (One Command)

```powershell
pwsh -File gate-advance.ps1
```

**Exit Codes:**

- **0 (GREEN)** — Traces detected, evidence packaged, ready for gate flip
- **1 (HOLD)** — No traces yet, platform gap persists

---

## 📋 What gate-advance.ps1 Does

### **Step 1: Send Canary Trace**

```powershell
pwsh -File .\send-canary-trace-direct.ps1
```

- Sends OTLP trace with `service.name="canary-test"` to SigNoz
- HTTP POST to localhost:5318/v1/traces
- Returns HTTP 200 on success

### **Step 2: Query ClickHouse for Traces**

```powershell
$query = @"
SELECT count()
FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND stringTagValue='canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE
"@
[int]$count = docker exec signoz-clickhouse clickhouse-client --query "$query"
```

**Method:** Docker exec (proven working in this environment)  
**Table:** signoz_traces.span_attributes  
**Filters:** tagKey + stringTagValue (resource attributes)

### **Step 3: Package Evidence**

Creates timestamped artifacts under `artifacts/ecrr/gate/`:

1. **`trace_count_YYYYMMDD_HHMMSS.txt`** — Span count from query
2. **`trace_timeline_YYYYMMDD_HHMMSS.txt`** — 30-min timeline (minute-by-minute)
3. **`service_name_YYYYMMDD_HHMMSS.txt`** — Service name assertion ("canary-test")

### **Step 4: Create ECRR JSON Artifact**

```json
{
  "t": "2025-10-23T19:50:00.000Z",
  "who": "Cursor{Implementer}",
  "type": "report",
  "lane": "gate",
  "msg": "Traces persisted for service.name=canary-test",
  "artifacts": [
    "artifacts/ecrr/gate/trace_count_YYYYMMDD_HHMMSS.txt",
    "artifacts/ecrr/gate/trace_timeline_YYYYMMDD_HHMMSS.txt",
    "artifacts/ecrr/gate/service_name_YYYYMMDD_HHMMSS.txt"
  ],
  "result": "GREEN",
  "evidence": {
    "service_name": "canary-test",
    "span_count": N,
    "window": "5 minutes",
    "query_method": "docker exec",
    "table": "span_attributes",
    "timestamp": "YYYYMMDD_HHMMSS"
  }
}
```

**Saved as:** `artifacts/ecrr/gate/ECRR_TRACE_PROOF_YYYYMMDD_HHMMSS.json`

### **Step 5: Return Exit Code**

- **If count ≥ 1:** Exit 0 (GREEN) + Print success message
- **If count = 0:** Exit 1 (HOLD) + Continue monitoring

---

## 🟢 Success Output (When Traces Appear)

```yaml
🟢 GATE ADVANCEMENT - TRACE VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📤 Step 1: Sending canary trace...
✅ SUCCESS: HTTP 200

🔍 Step 2: Querying ClickHouse for traces...
   Traces found (last 5 min): N

📦 Step 3: Packaging evidence...
   ✅ Saved: artifacts\ecrr\gate\trace_count_YYYYMMDD_HHMMSS.txt
   ✅ Saved: artifacts\ecrr\gate\trace_timeline_YYYYMMDD_HHMMSS.txt
   ✅ Saved: artifacts\ecrr\gate\service_name_YYYYMMDD_HHMMSS.txt

📋 Step 4: Creating ECRR artifact...
   ✅ ECRR artifact created: ECRR_TRACE_PROOF_YYYYMMDD_HHMMSS.json

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ GATE ADVANCEMENT: READY FOR GREEN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Evidence Package:
  - Trace count: N spans
  - Service: canary-test
  - Window: 5 minutes
  - Method: docker exec (validated)

Artifacts:
  - artifacts\ecrr\gate\trace_count_YYYYMMDD_HHMMSS.txt
  - artifacts\ecrr\gate\trace_timeline_YYYYMMDD_HHMMSS.txt
  - artifacts\ecrr\gate\service_name_YYYYMMDD_HHMMSS.txt
  - artifacts\ecrr\gate\ECRR_TRACE_PROOF_YYYYMMDD_HHMMSS.json

Next Steps:
  1. Review evidence artifacts
  2. Commit artifacts to repository
  3. Post @cat ready-for-gate with bundle
  4. Update BOSSCAT_LOG.md with gate entry

Gate Verdict: 🟠 WARN → 🟢 GREEN

Exit Code: 0 (GREEN)
```

---

## 📦 Post-Execution Steps (Manual)

After `gate-advance.ps1` returns exit 0:

### **1. Commit Evidence Artifacts**

```powershell
git add artifacts/ecrr/gate/
git commit -m "gate(evidence): trace persistence confirmed - canary-test spans in ClickHouse

Evidence:
- Trace count: N spans (last 5 min)
- Service: canary-test
- Query: docker exec span_attributes
- ECRR artifact: ECRR_TRACE_PROOF_YYYYMMDD_HHMMSS.json

Platform fix confirmed. Ready for gate advancement."
```

### **2. Update BossCat Log**

Append to `docs/BossCat/BOSSCAT_LOG.md`:

```markdown
- **2025-10-23T19:50:00Z** — Gate: Traces persisted (canary-test, count=N, window=5m, method=docker-exec) → GREEN
```

### **3. Post Gate Signal**

```bash
@cat ready-for-gate

🟢 GATE VERDICT: GREEN (Platform Fix Confirmed)

✅ Evidence:
- Traces for service.name='canary-test' detected in ClickHouse
- Query method: docker exec signoz-clickhouse clickhouse-client
- Table: signoz_traces.span_attributes
- Span count (last 5 min): N
- ECRR artifact: ECRR_TRACE_PROOF_YYYYMMDD_HHMMSS.json

📦 Artifacts:
- artifacts/ecrr/gate/trace_count_YYYYMMDD_HHMMSS.txt
- artifacts/ecrr/gate/trace_timeline_YYYYMMDD_HHMMSS.txt
- artifacts/ecrr/gate/ECRR_TRACE_PROOF_YYYYMMDD_HHMMSS.json
- signoz-collector-config.yaml (action: insert proof)

🎯 Gate transitions: 🟠 WARN → 🟢 GREEN
```

---

## 🔍 Diagnostic Queries (If count = 0)

### **Check All Recent Services**

```powershell
docker exec signoz-clickhouse clickhouse-client --query "
SELECT stringTagValue AS service_name, count() AS c
FROM signoz_traces.span_attributes
WHERE tagKey='service.name'
  AND timestamp >= now() - INTERVAL 5 MINUTE
GROUP BY service_name
ORDER BY c DESC
LIMIT 20;"
```

**Expected:** Should show `canary-test` if traces are persisting

### **Check Service Name Preservation**

```powershell
# Verify resource/defaults processor uses 'insert' not 'upsert'
Select-String "action: insert" C:\otel\signoz-collector-config.yaml -Context 2
```

**Expected:** Line 66 should show `action: insert`

### **Check Total Recent Spans**

```powershell
docker exec signoz-clickhouse clickhouse-client --query "
SELECT count() FROM signoz_traces.span_attributes
WHERE timestamp >= now() - INTERVAL 5 MINUTE;"
```

**Expected:** If 0 total spans, exporter→ClickHouse gap persists

---

## ECRR Framework Alignment

| Phase | Implementation | Artifact |
|-------|----------------|----------|
| **Evidence** | Docker exec queries, trace count | trace_count_*.txt, timeline |
| **Contain** | N/A (verification only) | — |
| **Rollback** | N/A (no changes) | — |
| **Report** | ECRR JSON artifact | ECRR_TRACE_PROOF_*.json |

**Color Code:** GREEN=0 (success), HOLD=1 (no traces yet)

---

## BossCat Compliance

| Requirement | Implementation | Status |
|-------------|-----------------|--------|
| **Single-Writer** | Lane-locked (gate lane only) | ✅ |
| **Budgets** | ≤10 files (4 artifacts) | ✅ |
| **LOC** | Compact JSON (<200 LOC) | ✅ |
| **Evidence-First** | Objective count() > 0 | ✅ |
| **Exit Codes** | GREEN=0, HOLD=1 | ✅ |

---

## Automated Detection Path

**Monitoring Loop** (`gate-self-signal-monitor.ps1`) runs every 2 minutes:

1. Sends canary trace
2. Queries ClickHouse
3. If count() > 0: Breaks with alert
4. Operator then runs: `pwsh -File gate-advance.ps1`
5. Gate advancement completes

**Manual Path:**

1. User signals "platform fix landed"
2. Run: `pwsh -File gate-advance.ps1`
3. If exit 0: Commit artifacts + post @cat ready-for-gate
4. Gate flips: 🟠 WARN → 🟢 GREEN

---

## Timeline (Low-Latency Mode)

```yaml
Platform fix lands
   ↓ (max 2 minutes)
Monitoring loop detects count() > 0
   ↓ (immediate)
Loop breaks with alert
   ↓ (operator runs gate-advance.ps1)
Evidence packaged (~30 seconds)
   ↓
Artifacts committed (~1 minute)
   ↓
@cat ready-for-gate posted (~1 minute)
   ↓
VERDICT: 🟢 GREEN (~3 minutes total)

Total time from fix to GREEN: ~5 minutes
vs. Old system (30-min polling): ~35 minutes
Improvement: 7x faster gate advancement
```

---

## 🐾 Current State

```yaml
Gate:               🟠 WARN (awaiting traces)
Monitoring:         🟢 RUNNING (2-min low-latency polling)
Gate Advancement:   ✅ READY (gate-advance.ps1 deployed)
Evidence Template:  ✅ READY (auto-packaging on exit 0)
Protocol:           ✅ ALIGNED (docker exec method)
```

---

**🟢 System fully armed for instant gate advancement when platform fix confirmed.**

When traces appear → gate-advance.ps1 → Evidence package → Commit → @cat ready-for-gate → 🟢 GREEN


