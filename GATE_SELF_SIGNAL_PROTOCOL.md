# 🔔 Gate Self-Signal Protocol

**Status:** ✅ ACTIVE  
**Date:** 2025-10-23  
**Authority:** Cursor{Implementer} under ECRR + BossCat gate discipline  
**Current Gate:** 🟠 WARN (awaiting platform fix)

---

## 🎯 Purpose

Enable **autonomous detection** when SigNoz platform team fixes the exporter→ClickHouse gap, without requiring human ping. Gate advancement is triggered by **objective evidence** (traces appear) detected through continuous self-signal checks.

---

## 📋 Self-Signal Protocol

### **Command**
```powershell
pwsh -File gate-self-signal-check.ps1
```

### **What It Does**
1. ✅ Sends canary trace (OTLP HTTP) with `service.name="canary-test"`
2. ✅ Waits 2 seconds for ClickHouse ingestion
3. ✅ Queries: `SELECT count() FROM signoz_traces.distributed_signoz_spans WHERE serviceName='canary-test' AND timestamp ≥ now() - 10 min`
4. ✅ Returns exit code based on result

### **Exit Codes**

| Code | Signal | Meaning | Action |
|------|--------|---------|--------|
| **0** | 🟢 GREEN | count() > 0 | Platform fix landed → Execute gate runbook |
| **1** | 🟠 WARN | count() = 0 | Platform gap persists → Hold, continue ECRR |
| **2** | ⚠️ ERROR | Query failed | ClickHouse unreachable → Check infrastructure |

---

## 🚀 Gate Advancement Runbook (When Signal = GREEN)

Once self-signal returns exit code **0** (traces detected):

### **Step 1: Verify Stability (2 min)**
```powershell
# Send 5 more canary bursts
1..5 | % {
    pwsh -File .\send-canary-trace-direct.ps1
    Start-Sleep -Seconds 2
}

# Re-query counts (should increase)
$query = "SELECT count() FROM signoz_traces.distributed_signoz_spans
          WHERE serviceName='canary-test'
            AND toDateTime(startTime/1e9) >= now() - INTERVAL 5 MINUTE;"
$url = "http://localhost:8123/?query=$([uri]::EscapeDataString($query))"
(Invoke-WebRequest -UseBasicParsing $url).Content
```

**Expected:** Counts increase with each burst (traces persisting consistently)

### **Step 2: Capture Evidence (2 min)**

Create `gate-advancement-evidence-YYYYMMDD.md`:

```markdown
# Gate Advancement Evidence — Platform Fix Confirmed

## Evidence
- **Service:** canary-test
- **Traces found:** [count from query]
- **Query timestamp:** [UTC timestamp]
- **ClickHouse query:**
  ```sql
  SELECT count() FROM signoz_traces.distributed_signoz_spans
  WHERE serviceName='canary-test'
    AND toDateTime(startTime/1e9) >= now() - INTERVAL 5 MINUTE;
  ```

## Config State
- `signoz-collector-config.yaml` line 66: `action: insert` ✅
- Service name preservation: CONFIRMED
- Exporter endpoint: `tcp://signoz-clickhouse:9000/signoz_traces` ✅

## Stability Test
- Canary burst 1: X spans
- Canary burst 2: X+N spans
- Canary burst 3: X+2N spans
- ... (consistent growth) ✅
```

### **Step 3: Regenerate ECRR Artifacts (3 min)**

```powershell
# Create compact gate-verification artifact
$artifact = @{
    gate = "trace-persistence"
    verdict = "GREEN"
    timestamp = (Get-Date -AsUTC).ToString("o")
    evidence = @{
        service_name = "canary-test"
        span_count = [count from query]
        stability = "confirmed"
        config_state = "insert (not upsert)"
    }
    action = "ready-for-gate"
} | ConvertTo-Json -Depth 4

$artifact | Out-File "artifacts/gate-verification-YYYYMMDD.json"
git add artifacts/gate-verification-YYYYMMDD.json
git commit -m "gate(verification): platform fix confirmed - traces persisting"
```

### **Step 4: Signal Ready (2 min)**

Post to repository (PR comment or status update):

```
@cat ready-for-gate

🟢 GATE VERDICT: GREEN (Platform Fix Confirmed)

✅ Evidence Bundle:
- Traces for service.name='canary-test' detected in ClickHouse
- Stability verified (5 canary bursts, consistent growth)
- Collector config: service.name preservation active (insert, not upsert)
- SigNoz exporter→ClickHouse gap: RESOLVED

📦 Artifacts:
- gate-advancement-evidence-YYYYMMDD.md (query output + verification)
- gate-verification-YYYYMMDD.json (ECRR compact artifact)
- signoz-collector-config.yaml (config excerpt)
- send-canary-trace-direct.ps1 (reproducible test)

🎯 Gate transitions: 🟠 WARN → 🟢 GREEN
```

---

## 🛡️ Continuous Monitoring (Optional)

Run self-signal check periodically to detect platform fix the moment it lands:

```powershell
# Check every 30 minutes (background job)
while ($true) {
    $result = & pwsh -File gate-self-signal-check.ps1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ PLATFORM FIX DETECTED - Execute gate runbook" -ForegroundColor Green
        break
    }
    Start-Sleep -Seconds 1800  # 30 minutes
}
```

---

## 📊 State Transitions

```
Initial State
│
├─ Self-Signal Check Runs
│  │
│  ├─ Exit 0 (traces found)
│  │  └─ EXECUTE GATE RUNBOOK
│  │     └─ Verify stability
│  │     └─ Capture evidence
│  │     └─ Regenerate ECRR
│  │     └─ Signal ready-for-gate
│  │     └─ VERDICT: 🟢 GREEN (promote)
│  │
│  └─ Exit 1 (no traces) OR Exit 2 (error)
│     └─ HOLD at 🟠 WARN
│     └─ Blocker persists
│     └─ Re-check in 30 min (optional continuous monitoring)
```

---

## 🔐 Gate Advancement Criteria (Must ALL Pass)

1. ✅ Self-signal returns **exit code 0** (traces detected)
2. ✅ Stability verified (canary bursts show consistent trace growth)
3. ✅ Service name preserved (no `upsert` overwrite)
4. ✅ Evidence bundle attached (query output, config excerpt, ECRR artifact)
5. ✅ No new issues detected in ClickHouse schema/permissions

**Only when ALL 5 met:** Verdict flips 🟠 WARN → 🟢 GREEN

---

## 📦 Handoff Kit (Final)

Ready for immediate attachment when signal = GREEN:

- ✅ `gate-advancement-evidence-YYYYMMDD.md` (query output + verification)
- ✅ `gate-verification-YYYYMMDD.json` (ECRR compact artifact)
- ✅ `signoz-collector-config.yaml` (config proof: insert not upsert)
- ✅ `send-canary-trace-direct.ps1` (reproducible test)
- ✅ `PLATFORM_ESCALATION_DIAGNOSTIC_20251023.md` (prior diagnostics)

---

## 🐾 Doctrine Alignment

| Principle | Implementation |
|-----------|-----------------|
| **Fast feedback** | Self-signal runs anytime, no human blocker |
| **ECRR compliance** | Evidence-first (objective trace presence) |
| **Gate discipline** | Objective criteria: count() > 0 + repeatable |
| **Single writer** | Lane clean, budgets enforced (<200 LOC artifacts) |
| **Safe promotion** | All 5 criteria must pass before GREEN |

---

**🔔 Self-signal active. Autonomous detection engaged. Awaiting platform resolution.**

When traces land → Gate advances → Ready-for-gate signal → 🟢 GREEN

🐾
