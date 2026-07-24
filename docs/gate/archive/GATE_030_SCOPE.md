# Gate #030 — Evidence-as-Code v1: Unified Telemetry Proofs

**Gate ID:** #030  
**Title:** Evidence-as-Code v1 — Unified Telemetry Proofs (Traces + Logs + Metrics)  
**Date:** 2025-10-27  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Status:** ✅ **APPROVED — Ready to Execute**

---

## 🎯 Objectives

Extend Gate #029-H1's API-signed proof system to create **unified proof artifacts** that verify all three observability signals (traces, logs, metrics) are present in SigNoz.

**Goal:** CI GREEN only if **traces + logs + metrics** all produce ≥1 result in the last N minutes (service-scoped).

---

## 📋 Success Criteria

### 1. Unified Proof Script ✅

**File:** `scripts/windows/proof-of-telemetry.ps1`

**Requirements:**
- Query all three signals: traces, logs, metrics
- Use SigNoz API `/api/v5/query_range` endpoint
- SIGNOZ-API-KEY authentication
- Generate unified JSON proof artifact
- Exit codes: 0 (GREEN), 1 (AMBER), 2 (RED), 21 (config error)

**Functions Required:**
- `Query-SigNozSignal` (generic query for any signal type)
- Proof generation with all three signal results
- Exit logic based on signal presence

### 2. Unified Proof Artifact Schema

**Output Path:** `artifacts/proofs/unified-proof-<service>-<timestamp>.json`

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
      "endpoint": "http://localhost:8080/api/v5/query_range"
    },
    "logs": {
      "count": 42,
      "status": "PASS",
      "endpoint": "http://localhost:8080/api/v5/query_range"
    },
    "metrics": {
      "count": 8,
      "status": "PASS",
      "endpoint": "http://localhost:8080/api/v5/query_range"
    }
  },
  "overall_status": "PASS",
  "timestamp": "20251027-163000",
  "verification_type": "api-signed-unified",
  "api_version": "v5"
}
```

### 3. Exit Logic

**Exit GREEN (0):** All three signals present (count ≥ threshold)  
**Exit AMBER (1):** 1-2 signals present, not all three (if `-ExpectAll` flag)  
**Exit RED (2):** 0 signals present or API error  
**Exit RED (21):** Configuration error (missing API key/service name)

### 4. Documentation

**File:** `docs/runbooks/unified-telemetry-proofs.md`

**Contents:**
- Overview (extending Gate #029-H1)
- Configuration (environment variables)
- Usage examples (local + CI/CD)
- Unified proof schema
- Exit codes reference
- Troubleshooting per signal
- Migration guide from single-signal proofs

---

## 🛠️ Implementation Plan

### Component 1: proof-of-telemetry.ps1 (≤240 LOC)

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
  - Generic query for "traces", "logs", or "metrics"
  - Returns count + metadata

**Main Logic:**
1. Validate API key (SIGNOZ_API_KEY env var)
2. Query traces → count
3. Query logs → count
4. Query metrics → count
5. Aggregate results
6. Generate unified proof JSON
7. Determine exit code
8. Output proof path + summary

**LOC Estimate:** ~230 LOC

### Component 2: unified-telemetry-proofs.md (Documentation)

**Sections:**
- Overview
- Configuration
- Usage (local + CI/CD)
- Unified proof schema
- Exit codes
- Troubleshooting
- API reference
- Migration guide

**LOC Estimate:** ~400 lines (docs not counted in code LOC)

### Component 3: GATE_030_IMPLEMENTATION_COMPLETE.md (Evidence)

**Contents:**
- Implementation summary
- Budget assessment
- Test results
- Evidence artifacts
- Approval recommendation

**LOC Estimate:** ~300 lines (docs not counted in code LOC)

---

## 📦 Budget

### Files

**Target:** ≤3 files  
**Planned:**
1. `scripts/windows/proof-of-telemetry.ps1` (NEW)
2. `docs/runbooks/unified-telemetry-proofs.md` (NEW)
3. `GATE_030_IMPLEMENTATION_COMPLETE.md` (NEW)

**Status:** ✅ **Within budget** (3/3 files)

### LOC

**Target:** ≤250 LOC  
**Estimate:**

| Component | LOC | Description |
|-----------|-----|-------------|
| Parameters & setup | ~30 | Validation, env vars |
| Query-SigNozSignal | ~50 | Generic query function |
| Query execution (3x) | ~30 | Call function for each signal |
| Unified proof generation | ~50 | Aggregate results, generate JSON |
| Exit logic | ~20 | Determine GREEN/AMBER/RED |
| Logging & output | ~40 | Console output, error handling |
| **Total** | **~220** | **✅ Within budget** |

**Margin:** +30 LOC buffer

---

## 🧪 Testing Strategy

### Test Case 1: All Signals Present

**Setup:** Service with full instrumentation (traces + logs + metrics)  
**Command:** `pwsh -File .\scripts\windows\proof-of-telemetry.ps1 -ServiceName "iona-app" -ExpectAll`  
**Expected:** Exit 0 (GREEN), unified proof with all three signals ≥1

### Test Case 2: Only Traces Present

**Setup:** Service sending only traces  
**Expected:** Exit 1 (AMBER) if `-ExpectAll`, exit 0 otherwise

### Test Case 3: No Signals Present

**Setup:** Nonexistent service  
**Expected:** Exit 2 (RED), unified proof with all counts=0

### Test Case 4: Missing API Key

**Setup:** SIGNOZ_API_KEY not set  
**Expected:** Exit 21 (RED), error message

---

## 📊 Query Payloads

### Traces Query
```json
{
  "start": <timestamp>,
  "end": <timestamp>,
  "requestType": "scalar",
  "compositeQuery": {
    "queries": [{
      "type": "builder_query",
      "spec": {
        "name": "A",
        "signal": "traces",
        "aggregations": [{"expression": "count()", "alias": "span_count"}],
        "filter": {"expression": "serviceName = 'service-name'"}
      }
    }]
  }
}
```

### Logs Query
```json
{
  "signal": "logs",
  "filter": {"expression": "service_name = 'service-name'"}
}
```

### Metrics Query
```json
{
  "signal": "metrics",
  "filter": {"expression": "service_name = 'service-name'"}
}
```

---

## ✅ Acceptance Checklist

- [ ] proof-of-telemetry.ps1 created (≤240 LOC)
- [ ] Query-SigNozSignal function works for all three signals
- [ ] Unified proof JSON generated with all signals
- [ ] Exit codes correct (0, 1, 2, 21)
- [ ] Runbook created (unified-telemetry-proofs.md)
- [ ] All 4 test cases pass
- [ ] CI/CD example in runbook
- [ ] Evidence document created
- [ ] Dashboard updated
- [ ] Tag: `gate-030-green-2025-10-27`

---

## 🚀 Execution Sequence

**Phase 1:** Create proof-of-telemetry.ps1 (30-40 min)  
**Phase 2:** Test with live services (15-20 min)  
**Phase 3:** Create documentation (20-30 min)  
**Phase 4:** Create evidence + update dashboard (10-15 min)  
**Phase 5:** Git commit + push (5 min)

**Total:** ~90 minutes

---

**Scope Approved:** 2025-10-27 16:40:00 UTC  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM (Fubumaki)  
**Budget:** 3 files, 250 LOC  
**Status:** ✅ **READY TO EXECUTE**

🐾 **Gate #030 — Evidence-as-Code v1 Scope Defined**

