# 🐾 Gate #024 - Scope Document (DRAFT)

**Authority:** BossCat OEM  
**Date:** 2025-10-26 UTC  
**Lane:** DOCS (planning artifact, no merges by bots)  
**Status:** DRAFT FOR REVIEW

---

## 🎯 Objectives

**Gate #024: Performance Optimization & System Hardening**

**Focus Areas:**
1. **Performance:** Improve AudioSwitch propagation from ~1.2s toward ≤1.0s target
2. **Hardening:** Affirm kill-switches + budgets in all runbooks
3. **ICF (Iterative Convergence Framework):** Add improvement loop tracking to dashboards

---

## 📊 Track 1: Performance Optimization

### Objective
Reduce AudioSwitch cluster propagation from current ~1.2s to ≤1.0s target (17% improvement)

### Current Baseline (Gate #023)
- Disable propagation: 1279ms
- Enable propagation: 1158ms
- Average: 1218ms
- Target: 1000ms
- Gap: 218ms (18% improvement needed)

### Proposed Optimizations

**1. Redis Pub/Sub Optimization**
- Reduce poll interval in verification (currently 200ms)
- Implement immediate event notification (vs polling)
- Measure actual Redis delivery times
- Target: <100ms Redis path

**2. Local Switch Performance**
- Profile file write operations
- Consider in-memory cache with periodic flush
- Batch multiple state changes if rapid
- Target: <50ms local update

**3. Network Optimization**
- Verify no network throttling in Docker
- Consider Redis pipelining for bulk operations
- Measure container-to-container latency
- Target: <50ms network overhead

### Test Harness Requirements
- High-frequency toggle test (10 toggles/second for 60s)
- Measure p50, p95, p99 latencies
- Collector telemetry: `audioswitch_propagation_seconds` histogram
- Verification: All percentiles meet ≤1.0s target

### Success Criteria
- p95 propagation ≤ 1000ms
- p99 propagation ≤ 1500ms
- Zero timeouts or synchronization failures
- No performance regression under load

---

## 🛡️ Track 2: System Hardening

### Objective
Ensure all recovery paths have kill-switches, budgets, and ECRR evidence

### Runbook Audit

**Required in All Runbooks:**
- ✅ Kill-switch procedure (emergency disable)
- ✅ Recovery path with rollback
- ✅ Budget documentation (LOC, files, duration)
- ✅ ECRR evidence generation
- ✅ Troubleshooting scenarios (≥3 per runbook)

**Runbooks to Audit:**
1. `docs/runbooks/windows-collector.md` (Gate #022)
2. `docs/runbooks/audioswitch-cluster.md` (Gate #023)
3. Future runbooks (as added)

### Kill-Switch Verification

**Verify All Paths Have Emergency Stops:**
- Audio: `/admin/audio {enabled:false}` ✅ (BOSSCAT-021A/023A)
- Canary: `/canary/halt` ✅ (Gate #020)
- Rollback: `scripts/rollback-audio.ps1` ✅ (BOSSCAT-021A)
- Collector: Service stop via runbook ✅ (Gate #022)

**Additions:**
- System-wide emergency stop script
- Health check kill-switch dashboard
- Automated kill-switch verification in CI/CD

### Budget Enforcement

**Guardrails:**
- ≤200 LOC per job (existing standard)
- ≤10 files touched per job
- Single-writer lanes only
- Evidence artifacts required

**Audit:**
- Review all Gate #019-#023 for budget compliance
- Document any overages with justification
- Codify budget checks in preflight

---

## 📈 Track 3: ICF (Iterative Convergence Framework)

### Objective
Document "learn and converge" patterns while maintaining local-first determinism

### Dashboard Enhancements

**Convergence Index** (document-only in this gate):
- Track last 5 improvements
- Measure: Performance gain per iteration
- Display: Trend line showing convergence toward target
- Alert: Diminishing returns indicator

**Example Metrics:**
```
Improvement #1: 2000ms → 1218ms (39% gain)
Improvement #2: 1218ms → 1000ms (18% gain, target)
Improvement #3: Maintain ≤1000ms under load
```

### Improvement Loop Section

**Add to Dashboards:**
- Current baseline
- Target metric
- Last 5 iterations with gains
- Convergence trend
- Recommendations for next iteration

**Format:**
```markdown
## Improvement Loop

**Current:** 1218ms average propagation
**Target:** ≤1000ms
**Gap:** 218ms (18%)

### Recent Improvements
1. 2025-10-26: Redis pub/sub added (2000ms → 1218ms, 39% gain)
2. [Next iteration slot]
```

### Documentation Requirements

- ICF principles document (≤150 LOC)
- Example dashboard template
- Convergence tracking script (optional)
- Integration with existing ECRR methodology

---

## 🔧 Scope Constraints

### Agent Pairing
- **Agent A:** Writer (Cursor{Implementer})
- **Agent B:** Monitor (observation only, no writes)
- Mutex: `.agent/JOB.lock` with heartbeat ≤60s

### Lane Discipline
- **Lane:** DOCS for planning artifacts
- **Evidence:** DELT/ARTF/ for JSON artifacts
- **Logs:** docs/BossCat/BOSSCAT_LOG.md one-liners
- **No bot merges:** Human-gated only

### Budgets
- ≤2 jobs per track
- ≤10 files touched per job
- ≤200 LOC per job
- Changed-paths smoke only

### Preflight Requirements
```bash
pnpm agent:preflight
# Exit 0 = OK
# Exit 50 = kill-switch active
# Exit 51 = git state blocked
```

---

## 🧪 Verification Matrix

### PERF-01: Propagation Speed
- **Target:** p95 ≤ 1000ms
- **Test:** High-frequency toggle (10/s for 60s)
- **Evidence:** Histogram + percentiles

### HARD-01: Runbook Audit
- **Target:** All runbooks have kill-switches + budgets
- **Test:** Manual review checklist
- **Evidence:** Audit report JSON

### HARD-02: Kill-Switch Verification
- **Target:** All emergency stops functional
- **Test:** Execute each kill-switch, verify effect
- **Evidence:** Test results JSON

### ICF-01: Dashboard Template
- **Target:** Convergence tracking documented
- **Test:** Template validated against example data
- **Evidence:** Template file + example

---

## 📂 Deliverables (Estimated)

### Track 1: Performance
- Performance test harness script (~100 LOC)
- Optimization implementations (~50-100 LOC)
- Benchmark results JSON
- Performance report MD

### Track 2: Hardening
- Runbook audit checklist
- Kill-switch verification script (~80 LOC)
- Audit results JSON
- Hardening report MD

### Track 3: ICF
- ICF principles document (~150 LOC)
- Dashboard template
- Example convergence data
- Integration guide

**Total Estimated:** ~400-500 LOC across 8-12 files

---

## ⏱️ Timeline (Estimated)

- **Track 1:** 2-3 hours (test harness + optimization + verification)
- **Track 2:** 1-2 hours (audit + kill-switch tests)
- **Track 3:** 1-2 hours (documentation + templates)
- **Total:** 4-7 hours implementation time

---

## 🎯 Success Criteria

**Gate #024 Approved When:**
- ✅ PERF-01: p95 propagation ≤1000ms verified
- ✅ HARD-01: All runbooks audited and compliant
- ✅ HARD-02: All kill-switches tested and functional
- ✅ ICF-01: Dashboard template documented and validated
- ✅ Evidence artifacts complete
- ✅ BOSSCAT_LOG updated
- ✅ All budgets honored

**Risk:** LOW (optimization + documentation, no breaking changes)

---

## 📋 Dependencies

**Prerequisites:**
- Gate #023 complete ✅ (cluster infrastructure operational)
- Gate #022 complete ✅ (runbooks established)
- Docker infrastructure stable ✅

**No External Dependencies**

---

## 🔄 ECRR Integration

**Examine:** Measure current baseline (propagation times, runbook coverage)  
**Clean:** Optimize hot paths, audit runbooks, document gaps  
**Report:** Generate performance benchmarks, audit results, ICF templates  
**Role:** Cursor{Implementer} (writer) + Monitor (observer)

---

**Status:** DRAFT FOR REVIEW (DOCS lane, no bot merges)  
**Authority:** BossCat OEM  
**Next:** Await review and approval to proceed with implementation

🐾

