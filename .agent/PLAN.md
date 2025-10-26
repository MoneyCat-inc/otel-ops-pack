# Gate #020 — Audio Canary & Rollout

**Authority:** BossCat OEM  
**Date:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Gate Type:** Production Deployment (Canary Rollout)  
**Status:** 🔵 **IN PROGRESS**

---

## 🎯 Goal

Implement automated audio canary state machine with observability and rollback for production-safe feature-flagged rollout. Two jobs: (CNY1) canary state machine with 0%→10%→50%→100% ramp and auto-halt on breach; (CNY2) observability dashboard + one-click rollback. Full ECRR, human-gated merge only.

**Target State:**
- Canary: 0% → 10% (5min) → 50% (2min) → 100% completion
- Auto-halt on KPI breach (underrun_ratio, jitter, or other thresholds)
- OTLP span emission with canary phase attributes
- One-click rollback capability
- Evidence complete

**Success Criteria:**
- Canary completes 100% with no alerts
- KPIs within thresholds at each phase
- Rollback verified functional
- Budgets respected (≤2 jobs, ≤10 files, ≤200 LOC/job)

---

## 📊 Lane & Scope

**Lane:** `viz-engine-projectm/**`, `docs/**`, monitoring/scripts  
**Scope:**
- Canary state machine logic
- Phase progression scheduler
- Health monitoring + breach detection
- OTLP span emission
- Rollback scripts/documentation
- Dashboard panels (optional)

**Out of Scope:**
- Audio algorithm changes
- Non-canary features
- AM Sine correlation fixes

---

## 🔒 Budgets & Guardrails

**Budgets:**
- ≤ **2 jobs** (CNY1: State Machine, CNY2: Observability/Rollback)
- ≤ **10 files** total
- ≤ **200 LOC per job**
- Single-writer lock
- Exit codes: 0/50/51/52/53
- Bots do **NOT** merge

**Two-Agent Discipline:**
- A (Implementer) writes
- B (Balancer) verifies (read-only)

**Stability Pack:**
- Human-gated merge required
- Branch protection enforced

---

## 🔧 Job Breakdown

### Job CNY1 — Canary State Machine (≤200 LOC, ≤6 files)

**Scope:** Automated canary deployment with phase progression

**Implementation:**
1. **State machine:** Phases: INIT → 10% → 50% → 100% → COMPLETE
2. **Timer-based progression:**
   - 0% → 10%: 5 minutes
   - 10% → 50%: 2 minutes
   - 50% → 100%: 2 minutes
3. **Health monitoring per phase:**
   - underrun_ratio < 0.5%
   - tick_jitter_ms(max) ≤ 8ms
   - (optional) r ≥ 0.78 for transients
4. **Auto-halt on breach:**
   - Immediate stop if any KPI exceeds threshold
   - Rollback to 0% (disable audio)
   - Alert emission
5. **OTLP span emission:**
   - Span name: `audio.enable.canary`
   - Attributes: `{phase, r, underrun_ratio, tick_jitter_ms}`
   - Environment: `deployment.environment=staging`

**Files:**
- canary-state.js or canary.js (~150 LOC)
- Integration with server.js (~30 LOC)
- Config file (optional, ~20 LOC)

**Acceptance:**
- Canary completes 100% with no breaches
- All phases monitored
- OTLP spans emitted
- Auto-halt tested (simulated breach)

---

### Job CNY2 — Observability & Rollback (≤200 LOC, ≤6 files)

**Scope:** Monitoring, rollback capability, incident response

**Implementation:**
1. **Rollback script:**
   - PowerShell or bash script
   - Sets AUDIO_ENABLED=false
   - Restarts service
   - Verifies audio stopped
   - ~60 LOC

2. **Dashboard/monitoring (optional):**
   - Canary status panel
   - Phase progression visualization
   - KPI metrics display
   - ~80 LOC (if implemented)

3. **Incident template:**
   - Markdown template for canary halt
   - Required fields: phase, KPIs, breach reason, rollback confirmation
   - ~30 LOC

4. **Evidence:**
   - Screenshot of successful canary (or dashboard)
   - Rollback test results
   - OTLP span examples

**Files:**
- rollback-audio.ps1 (~60 LOC)
- INCIDENT_TEMPLATE.md (~30 LOC)
- Optional: dashboard panel (~80 LOC)

**Acceptance:**
- Rollback script works (tested)
- Incident template complete
- Evidence captured

---

## 📂 Evidence Package

**Required Artifacts:**

1. **`GATE_020_CANARY_EVIDENCE.md`** — Comprehensive report:
   - Canary progression log (0%→10%→50%→100%)
   - KPI measurements at each phase
   - OTLP span examples
   - Rollback verification
   - Dashboard screenshots (optional)

2. **BOSSCAT_LOG:** One-liner for Gate #020 GREEN

3. **Dashboard update:** Gate #020 status

---

## 🚦 Gate Hand-Off Signal

**Post when GREEN:**

```
@cat ready-for-gate : #020

Status: GREEN
Evidence: GATE_020_CANARY_EVIDENCE.md
Canary: 0%→10%→50%→100% completed (no alerts)
KPIs: underrun<0.5%, jitter(max)≤8ms across phases
Rollback: Verified
Budgets: OK
ECRR: COMPLETE
```

---

## 🛡️ Exit Criteria

**GREEN (Exit 0):**
- Canary: 100% completion
- All phases: KPIs within thresholds
- OTLP spans: Emitted successfully
- Rollback: Tested and functional
- Budgets: Respected
- ECRR: Complete

**AMBER (Exit 50):**
- Canary partial (e.g., stopped at 50%)
- Some KPIs marginal
- Document issues

**FAIL (Exit 51):**
- Budgets exceeded
- Process violations

**BLOCKED (Exit 52):**
- Infrastructure issues
- KPI breaches unrecoverable

---

**Status:** 🔵 IN PROGRESS  
**Start:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM directive

---

🐾 *Gate #020 executing: Audio canary deployment with production safety.*
