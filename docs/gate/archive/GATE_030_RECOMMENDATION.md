# Gate #030 Recommendation: Evidence-as-Code v1

**Proposed Gate:** #030  
**Title:** Evidence-as-Code v1 — Unified Telemetry Proofs (Traces + Logs + Metrics)  
**Date:** 2025-10-27  
**Authority:** BossCat OEM (Fubumaki)  
**Status:** RECOMMENDED — Awaiting approval to begin

---

## Executive Summary

Extend Gate #029-H1's API-signed proof system to include **logs and metrics** alongside traces, creating a unified proof artifact that verifies all three observability signals are present in SigNoz.

**Goal:** CI GREEN only if **traces + logs + metrics** all produce ≥1 result in the last N minutes (service-scoped).

---

## Objective

Unify proofs for **traces + logs + metrics** via SigNoz `/api/v5/query_range` endpoint (three sub-checks), generating comprehensive evidence artifacts that replace manual verification across all three observability pillars.

---

## Motivation

### Current State (Post-Gate #029-H1)

- ✅ **Traces:** API-signed proof via Query-SigNozTraces function
- ❌ **Logs:** Manual verification in SigNoz UI
- ❌ **Metrics:** Manual verification in SigNoz UI

### Desired State (Gate #030)

- ✅ **Traces:** API-signed proof
- ✅ **Logs:** API-signed proof
- ✅ **Metrics:** API-signed proof
- ✅ **Unified Proof:** Single JSON artifact with all three signals

---

## Success Criteria

### 1. Query Functions for All Three Signals

**Required:**
- `Query-SigNozTraces` (existing, from Gate #029-H1)
- `Query-SigNozLogs` (new)
- `Query-SigNozMetrics` (new)

**Each function:**
- Queries SigNoz `/api/v5/query_range` with appropriate `signal` parameter
- Returns count of matching records
- Handles errors gracefully
- Uses `SIGNOZ-API-KEY` authentication

### 2. Unified Proof Artifact

**Schema:**
```json
{
  "probe": "signoz-unified",
  "service": "bosscat-svc2-api",
  "timeframe": "3 min",
  "startMs": 1730047200000,
  "endMs": 1730047380000,
  "signals": {
    "traces": {
      "count": 15,
      "status": "PASS",
      "endpoint": "http://127.0.0.1:3301/api/v5/query_range"
    },
    "logs": {
      "count": 42,
      "status": "PASS",
      "endpoint": "http://127.0.0.1:3301/api/v5/query_range"
    },
    "metrics": {
      "count": 8,
      "status": "PASS",
      "endpoint": "http://127.0.0.1:3301/api/v5/query_range"
    }
  },
  "overall_status": "PASS",
  "timestamp": "20251027-160000",
  "verification_type": "api-signed-unified",
  "api_version": "v5"
}
```

### 3. Exit Logic

**Exit GREEN (0):** All three signals present (count ≥ threshold)  
**Exit AMBER (1):** 1-2 signals present, not all three  
**Exit RED (2):** 0 signals present or API error

### 4. CI/CD Integration

**GitHub Actions Example:**
```yaml
- name: Verify all telemetry signals in SigNoz
  shell: pwsh
  env:
    SIGNOZ_API_KEY: ${{ secrets.SIGNOZ_API_KEY }}
    SIGNOZ_BASE_URL: ${{ vars.SIGNOZ_BASE_URL }}
    SIGNOZ_SERVICE_NAME: bosscat-svc2-api
  run: |
    ./scripts/windows/proof-of-telemetry.ps1 -ServiceName bosscat-svc2-api -ExpectAll
```

**Fail if:** Any signal missing (exit 1 or 2)

---

## Implementation Approach

### Option 1: Extend health-check-otlp.ps1

**Pros:**
- Builds on existing Gate #029-H1 implementation
- Reuses Query-SigNozTraces function
- Maintains backward compatibility

**Cons:**
- Script grows larger (currently 343 LOC, would add ~150 LOC)
- Mixed responsibility (collector path check + unified proof)

### Option 2: Create New proof-of-telemetry.ps1 (RECOMMENDED)

**Pros:**
- Clean separation of concerns
- Focused on proof generation only
- Easier to test and maintain
- Can call health-check-otlp.ps1 for collector path check if needed

**Cons:**
- Duplicate Query-SigNozTraces function (or extract to shared module)

**Recommendation:** Create `scripts/windows/proof-of-telemetry.ps1` (new file) with unified proof logic.

---

## Budget

### Files

**Target:** ≤3 files  
**Planned:**
1. `scripts/windows/proof-of-telemetry.ps1` (NEW) — Main script
2. `docs/runbooks/unified-telemetry-proofs.md` (NEW) — Documentation
3. `GATE_030_EVIDENCE.md` (NEW) — Evidence document

**Status:** ✅ **Within budget** (3/3 files)

### LOC

**Target:** ≤250 LOC  
**Estimate:**

| Component | LOC | Description |
|-----------|-----|-------------|
| Parameters & setup | ~30 | ServiceName, SigNozUrl, ApiKey validation |
| Query-SigNozTraces | ~50 | Copy from Gate #029-H1 |
| Query-SigNozLogs | ~45 | Similar to traces, different signal |
| Query-SigNozMetrics | ~45 | Similar to traces, different signal |
| Unified proof generation | ~50 | Aggregate results, generate JSON |
| Exit logic | ~20 | Determine GREEN/AMBER/RED |
| **Total** | **~240** | **✅ Within budget** |

**Margin:** +10 LOC buffer

---

## Detailed Design

### Script: proof-of-telemetry.ps1

**Parameters:**
```powershell
param(
    [string]$ServiceName = $env:SIGNOZ_SERVICE_NAME,
    [string]$SigNozUrl = $env:SIGNOZ_BASE_URL,
    [int]$LookbackMinutes = 3,
    [int]$ExpectAtLeast = 1,
    [switch]$ExpectAll  # Exit RED if any signal missing
)
```

**Functions:**
- `Query-SigNozSignal($ServiceName, $SigNozUrl, $ApiKey, $Signal, $LookbackMinutes)`
  - Generic query function for traces/logs/metrics
  - `$Signal` parameter: "traces", "logs", or "metrics"

**Main Logic:**
1. Validate ApiKey (SIGNOZ_API_KEY env var)
2. Query traces → count
3. Query logs → count
4. Query metrics → count
5. Aggregate results
6. Generate unified proof JSON
7. Determine exit code based on counts
8. Output proof path + summary

**Exit Codes:**
- `0` (GREEN): All signals present (if `-ExpectAll`) or at least one signal present
- `1` (AMBER): Some signals missing (only if `-ExpectAll`)
- `2` (RED): All signals missing or API error
- `21` (RED): Configuration error (missing API key/service name)

### Logs Query Payload

```json
{
  "start": 1730047200000,
  "end": 1730047380000,
  "requestType": "scalar",
  "compositeQuery": {
    "queries": [{
      "type": "builder_query",
      "spec": {
        "name": "A",
        "signal": "logs",
        "aggregations": [{"expression": "count()", "alias": "log_count"}],
        "filter": {"expression": "service_name = 'bosscat-svc2-api'"},
        "disabled": false
      }
    }]
  }
}
```

### Metrics Query Payload

```json
{
  "start": 1730047200000,
  "end": 1730047380000,
  "requestType": "scalar",
  "compositeQuery": {
    "queries": [{
      "type": "builder_query",
      "spec": {
        "name": "A",
        "signal": "metrics",
        "aggregations": [{"expression": "count()", "alias": "metric_count"}],
        "filter": {"expression": "service_name = 'bosscat-svc2-api'"},
        "disabled": false
      }
    }]
  }
}
```

---

## Testing Strategy

### Test Case 1: All Signals Present

**Setup:** Service instrumented, sending traces/logs/metrics  
**Command:** `pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "bosscat-svc2-api" -ExpectAll`  
**Expected:** Exit 0 (GREEN), proof file with all three signals ≥1

### Test Case 2: Only Traces Present

**Setup:** Service sending only traces  
**Command:** `pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "bosscat-svc2-api" -ExpectAll`  
**Expected:** Exit 1 (AMBER), proof file shows traces>0, logs=0, metrics=0

### Test Case 3: No Signals Present

**Setup:** Service not running or not sending telemetry  
**Command:** `pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "nonexistent-service" -ExpectAll`  
**Expected:** Exit 2 (RED), proof file shows all counts=0

### Test Case 4: Missing API Key

**Setup:** SIGNOZ_API_KEY not set  
**Command:** `pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "bosscat-svc2-api"`  
**Expected:** Exit 21 (RED), error message about missing API key

---

## Migration Path

### For Users (Backward Compatible)

**Current (Gate #029-H1):**
```powershell
# Traces only
pwsh -File .\scripts\windows\health-check-otlp.ps1 -ServiceName "bosscat-svc2-api" -UseApiProof
```

**New (Gate #030):**
```powershell
# All three signals
pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "bosscat-svc2-api" -ExpectAll
```

**Both scripts coexist:** `health-check-otlp.ps1` remains for collector path verification, `proof-of-telemetry.ps1` for unified proofs.

---

## Documentation

### Runbook: unified-telemetry-proofs.md

**Contents:**
- Overview (extending Gate #029-H1)
- Configuration (same env vars)
- Usage examples (local + CI/CD)
- Exit codes reference
- Unified proof schema
- Troubleshooting per signal
- Migration guide from Gate #029-H1
- API reference for logs/metrics queries

---

## Risks & Mitigations

### Risk: Logs/Metrics Query API Not Supported

**Mitigation:** Verify SigNoz version supports `/api/v5/query_range` for logs/metrics signals (v0.31+). Document minimum SigNoz version requirement.

### Risk: Different Response Formats

**Mitigation:** Test with live SigNoz instance to confirm response parsing logic works for all three signals. Include fallback parsing logic.

### Risk: User Confusion (Two Scripts)

**Mitigation:** Clear documentation explaining when to use each script:
- `health-check-otlp.ps1`: Collector path (5317) verification
- `proof-of-telemetry.ps1`: Unified telemetry proof generation

---

## Timeline

**Estimated Effort:** 2-3 hours

| Phase | Task | Duration |
|-------|------|----------|
| 1 | Create proof-of-telemetry.ps1 | 60 min |
| 2 | Test with live SigNoz | 30 min |
| 3 | Create unified-telemetry-proofs.md runbook | 30 min |
| 4 | Create GATE_030_EVIDENCE.md | 20 min |
| 5 | Update dashboard + approval | 10 min |

**Total:** ~2.5 hours

---

## Acceptance Checklist

- [ ] proof-of-telemetry.ps1 created (≤240 LOC)
- [ ] Query-SigNozSignal function works for traces/logs/metrics
- [ ] Unified proof JSON generated with all three signals
- [ ] Exit codes correct (0=GREEN, 1=AMBER, 2=RED, 21=config error)
- [ ] Runbook created (unified-telemetry-proofs.md)
- [ ] Testing complete (all 4 test cases pass)
- [ ] CI/CD example added to runbook
- [ ] Dashboard updated with Gate #030 section
- [ ] Evidence document created (GATE_030_EVIDENCE.md)
- [ ] Tag: `gate-030-green-2025-10-XX`

---

## Follow-Up: Gate #031+ Ideas

**Potential extensions:**
- **Exemplar linking:** Include trace IDs in log/metric proofs
- **Threshold tuning:** Configurable thresholds per signal
- **Historical trending:** Track proof results over time
- **Alert integration:** Webhook to Slack/Teams on proof failures
- **Redaction:** Sensitive data filtering in proof artifacts

---

## Approval Request

**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM (Fubumaki)  
**Status:** RECOMMENDED

**Request:** Approve Gate #030 scope and proceed with implementation.

**Rationale:**
- Natural extension of Gate #029-H1 hygiene patch
- Completes observability proof coverage (traces + logs + metrics)
- Within budget (3 files, 240 LOC)
- High value for gate approvals (comprehensive evidence)
- CI/CD ready for automated verification

**Next Step:** Await BossCat OEM approval to begin Gate #030 implementation.

---

**Date:** 2025-10-27  
**Status:** RECOMMENDED  
**Tag Suggestion:** `gate-030-green-2025-10-XX` (upon completion)

**Seal:** 🐾 **Gate #030 — Evidence-as-Code v1 Recommended**

