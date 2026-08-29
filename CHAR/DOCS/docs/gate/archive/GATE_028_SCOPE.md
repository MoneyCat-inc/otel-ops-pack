# Gate #028 — Complete Gate #027 Verification

**Gate ID:** #028  
**Date:** 2025-10-27  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Type:** Verification & Completion (Gate #027 carry-forward)  
**Timebox:** One session  
**Status:** ✅ IN EXECUTION

---

## 🎯 Objective

Complete the incomplete verification work from Gate #027 with realistic, achievable scope.

**Focus:** Finish what was started, not new features.

---

## 📊 Three Tracks (Carry-Forward from #027)

### Track 28A — Complete Trace Path Unification (from 27A)

**Goal:** Verify Windows Collector traces pipeline (5317) works with live application

**Current State:** ~60% complete
- ✅ Health probe exists (`scripts/windows/verify-collector-traces.ps1`)
- ✅ Runbook documents PRIMARY (14317) and SECONDARY (5317) paths
- ❌ Collector path (5317) never tested with live app

**Acceptance Criteria:**
1. ✅ Run minimal .NET test app pointing to `http://127.0.0.1:5317` (collector)
2. ✅ Health probe shows GREEN (accepted_spans ≈ sent_spans, ±1%)
3. ✅ Traces visible in SigNoz (via collector forwarding)
4. ✅ Evidence captured (probe output + SigNoz screenshot)

**Budget:** ≤5 files, ≤100 LOC (minimal scripting, reuse existing app)

**Why Achievable:** App already exists (dotnet-test-app), just change endpoint from 14317→5317, generate traffic, verify.

---

### Track 28B — Complete Coverage Expansion (from 27B)

**Goal:** Deploy at least ONE service using scripted pattern, verify telemetry end-to-end

**Current State:** ~40% complete
- ✅ Deployment scripts exist (`scripts/gate027/deploy-dotnet-service2.ps1`, `service3.ps1`)
- ✅ Pattern proven working (Gate #026A: bosscat-026a-dotnet)
- ❌ Services not deployed or verified

**Acceptance Criteria:**
1. ✅ Deploy ONE service using existing scripts (service2 OR service3, not both)
2. ✅ Service responds to HTTP requests
3. ✅ Traces visible in SigNoz (service name, spans, attributes)
4. ✅ Metrics visible in SigNoz (request duration, count)
5. ✅ Logs visible in SigNoz (if ILogger used)
6. ✅ Overhead measured (before/after, quick baseline)
7. ✅ Evidence captured (SigNoz screenshots + overhead report)

**Budget:** ≤5 files, ≤100 LOC (minor script fixes if needed, reuse existing)

**Why Achievable:** Scripts exist, pattern proven, just need to fix deployment issues and capture evidence.

---

### Track 28C — Reframe ICF Goals (from 27C)

**Goal:** Set incremental CI improvement target, fix extraction bug, update dashboard

**Current State:** ~30% complete
- ✅ ICF analyzer working (CI: 50.31%)
- ✅ Retrospective created
- ❌ Target (70%) unrealistic, bug in "Last 5 Actions" extraction, dashboard not updated

**Acceptance Criteria:**
1. ✅ Set **realistic incremental target:** CI 53-55% (+3-5pp improvement, not +20pp)
2. ✅ Fix "Last 5 Improvement Actions" extraction bug (returns 0 items)
3. ✅ Update dashboard with ICF improvement panel showing recent actions
4. ✅ Run analyzer, confirm improvement actions display correctly
5. ✅ Document trajectory: 50.31% (Gate 027) → target 53-55% (Gate 028) → 60% (Gate 030) → 70% (Gate 035)

**Budget:** ≤5 files, ≤100 LOC (bug fix + dashboard update)

**Why Achievable:** Incremental target realistic, bug fix is targeted, dashboard integration already proven (Gate #026C).

---

## 🛡️ Budgets & Guardrails

**Per Track:**
- ≤5 files touched
- ≤100 LOC changed/added
- Single-writer lane
- ECRR on anomaly

**Overall:**
- ≤15 files total (3 tracks × 5)
- ≤300 LOC total (3 tracks × 100)
- One session timebox
- Honest assessment if blocked

---

## ✅ Acceptance Tests

### 28A — Trace Path Verification
- [ ] Test app running with `OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:5317`
- [ ] Health probe exits 0 (GREEN)
- [ ] Probe shows: accepted_spans ≈ sent_spans (±1%), failed_exports = 0
- [ ] SigNoz shows traces from app via collector

### 28B — Service Deployment
- [ ] ONE service deployed and running
- [ ] HTTP requests return 200 OK
- [ ] SigNoz shows service (traces + metrics + logs)
- [ ] Overhead measured (before/after comparison)
- [ ] Evidence: 3+ SigNoz screenshots + overhead report

### 28C — ICF Improvement
- [ ] Incremental target set (+3-5pp)
- [ ] "Last 5 Actions" bug fixed (returns >0 items)
- [ ] Dashboard updated with improvement panel
- [ ] Analyzer run successful with actions displayed

---

## 🔄 Rollback Plan

**Track 28A:**
- Revert app endpoint back to 14317 (direct path)
- No production impact (testing only)

**Track 28B:**
- Stop deployed service
- No persistent changes

**Track 28C:**
- Revert analyzer script changes
- Revert dashboard update
- No data loss

---

## 📦 Evidence Requirements

### Per Track
- **28A:** Health probe output (GREEN), SigNoz screenshot (traces via collector)
- **28B:** 3+ SigNoz screenshots (service/traces/metrics), overhead report
- **28C:** Dashboard screenshot (improvement panel), analyzer output (with actions)

### Overall
- `.agent/EVIDENCE.log` — Execution steps
- ECRR report (≤1 page)
- Artifacts in `artifacts/gate028/`

---

## 🎯 Success Criteria Summary

**Gate #028 is complete when:**
1. ✅ Collector path (5317) verified working with health probe GREEN
2. ✅ ONE service deployed with verified telemetry (traces+metrics+logs)
3. ✅ ICF improvement panel on dashboard with realistic trajectory
4. ✅ All budgets honored (≤15 files, ≤300 LOC)
5. ✅ ECRR report generated
6. ✅ BossCat OEM approves
7. ✅ Tag applied: `gate-028-green-2025-10-27`

---

## 🔍 Why This Scope is Achievable

**Track 28A:** Simple endpoint change + verification (20 min)  
**Track 28B:** Existing scripts + minor fixes + evidence capture (30 min)  
**Track 28C:** Targeted bug fix + dashboard update (20 min)

**Total Estimated:** 70 minutes (well within one-session timebox)

**Risk:** LOW — All foundations from Gate #027 exist, no new features

---

**Scope Created:** 2025-10-27 10:35:00 UTC  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Status:** ✅ APPROVED — Ready for Execution

**Seal:** 🐾 **Gate #028 Scope Document — Realistic & Achievable**

