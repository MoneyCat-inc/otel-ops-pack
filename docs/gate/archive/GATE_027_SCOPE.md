# Gate #027 — Trace Unification, Coverage Expansion, ICF Lift

**Gate ID:** #027  
**Date:** 2025-10-27  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Timebox:** One session  
**Status:** ✅ IN EXECUTION

---

## 🎯 Objective

Unify trace paths, expand coverage, and raise convergence.

---

## 📊 Tracks

### Track 27A — Trace Path Unification (Windows Collector Parity)

**Goal:** Eliminate ambiguity between Windows Collector vs. direct-to-SigNoz; ensure both paths clean.

**Primary Path (Production):** .NET services point **direct to SigNoz OTLP gRPC** (port 14317) — proven working in Gate #026A

**Secondary Path (Parity):** Windows Collector traces pipeline operational (receive port 5317 → forward to SigNoz port 14317)

**Health Probe:** Assert `receiver.accepted_spans ≈ exporter.sent_spans` (±1%) for collector traces pipeline

**Acceptance:**
- ✅ Spans appear via **either path** (direct 14317 OR collector 5317) within 3 minutes
- ✅ Collector telemetry shows `failed_exports = 0` for spans during 5-minute laminar run
- ✅ Runbook updated with **canonical primary/secondary** endpoints

**Budget:** ≤10 files, ≤200 LOC

---

### Track 27B — .NET Coverage Expansion

**Goal:** Roll approved .NET auto-instrumentation pattern to **2 additional services**

**Services:** Select 2 production-relevant .NET services/apps

**Pattern:**
```powershell
$env:OTEL_SERVICE_NAME = "<service-name>"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:14317"  # Direct to SigNoz
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "grpc"
$env:OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=<env>,service.version=<version>"
# + profiler env vars (CORECLR_*, DOTNET_STARTUP_HOOKS, etc.)
```

**Acceptance:**
- ✅ **2 services** visible in SigNoz (services page + traces + runtime metrics)
- ✅ **Overhead <5%** vs. baseline for each service
- ✅ **Tags present:** deployment.environment, service.version on spans/metrics/logs

**Expected Coverage:**
- ASP.NET Core server spans
- HttpClient outbound spans
- Runtime metrics (GC, thread pool, memory)
- ILogger log correlation (if services use it)

**Budget:** ≤10 files, ≤200 LOC

---

### Track 27C — ICF Lift (51.77% → ≥70%)

**Goal:** Raise Convergence Index through repeatable improvement loop

**Current Baseline:** 51.77% (from Gate #026C)

**Target:** ≥70% OR +15-20 percentage points improvement

**Actions:**
1. Run ICF analyzer once per cycle
2. Append "Cycle Retrospective" to evidence
3. Implement **one safe micro-tuning** behind feature flag
4. Surface "Last 5 Improvement Actions" on dashboard ICF panel

**Acceptance:**
- ✅ **CI ≥70%** over last 10 cycles OR documented +15-20pp improvement
- ✅ Dashboard shows ICF panel with recent cycle deltas and applied lessons
- ✅ Cycle retrospective documented

**Budget:** ≤10 files, ≤200 LOC

---

## 🛡️ Budgets & Guardrails

**Per Track:**
- ≤10 files touched
- ≤200 LOC changed/added
- Single-writer lane (A=writer, B=monitor)
- Paired-agent verification
- ECRR on any anomaly

**Overall:**
- ≤30 files total (3 tracks × 10)
- ≤600 LOC total (3 tracks × 200)
- One session timebox

---

## ✅ Acceptance Tests

### 27A — Trace Path Unification
- [ ] Flip test app between direct (14317) and collector (5317)
- [ ] Spans appear either way
- [ ] Collector probe shows 0 failed exports
- [ ] Probe: `receiver.accepted_spans ≈ exporter.sent_spans` (±1%)

### 27B — Coverage Expansion
- [ ] 2 new services visible in SigNoz
- [ ] Traces + metrics + logs present
- [ ] Overhead <5% for each service
- [ ] Resource attributes: deployment.environment, service.version

### 27C — ICF Lift
- [ ] ICF analyzer run
- [ ] Cycle retrospective documented
- [ ] CI ≥70% OR +15-20pp improvement
- [ ] Dashboard ICF panel updated with improvement actions

---

## 🔄 Rollback Plan

**Track 27A:**
- Revert collector parity changes
- Keep direct path (14317) as primary
- Remove health probe if issues

**Track 27B:**
- Disable new service env vars
- Remove auto-instrumentation from services
- Revert to baseline

**Track 27C:**
- Restore ICF flag to previous value
- Revert micro-tuning if regression
- Dashboard rollback (remove improvement panel)

---

## 📦 Evidence Requirements

### Per Track
- **27A:** Collector probe output, SigNoz screenshots (both paths), runbook update
- **27B:** 2 service screenshots (traces/metrics/logs), overhead measurements
- **27C:** Cycle retrospective, CI delta chart, dashboard screenshot

### Overall
- `.agent/EVIDENCE.log` — Step-by-step execution log
- ECRR report (≤1 page)
- Artifacts in `artifacts/gate027/`
- SigNoz screenshots

---

## 🎯 Success Criteria Summary

**Gate #027 is complete when:**
1. ✅ Both trace paths working (direct + collector with probe)
2. ✅ 2 additional .NET services instrumented (overhead <5%)
3. ✅ ICF CI ≥70% OR +15-20pp improvement with evidence
4. ✅ All budgets honored (≤30 files, ≤600 LOC)
5. ✅ ECRR report generated
6. ✅ BossCat OEM approves
7. ✅ Tag applied: `gate-027-green-2025-10-27`

---

**Scope Created:** 2025-10-27 09:40:00 UTC  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Status:** ✅ APPROVED — Ready for Execution

**Seal:** 🐾 **Gate #027 Scope Document**

