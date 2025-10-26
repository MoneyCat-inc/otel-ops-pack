# Gate #019 — Audio Remediation Plan (AMBER → GREEN)

**Authority:** BossCat OEM  
**Date:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Gate Type:** Audio Remediation (Upgrade Gate #010 from AMBER → GREEN)  
**Status:** 🔵 **IN PROGRESS**

---

## 🎯 Goal

Improve audio reactivity and stability to promote **Gate #010** from AMBER → GREEN. Two small jobs: (R1) envelope calibration + feed mapping into projectM; (R2) enable audio by default via feature flag with canary and fallbacks. Keep budgets tight and evidence complete; merges remain human-gated.

**Target State:**
- r(envelope,intake) ≥ **0.78** across 3 scenarios
- underrun < **0.5%**
- overlay meter visible
- canary clean
- ECRR complete

**Success Criteria:**
- Gate #010 status: AMBER → GREEN
- Audio reactivity meets KPI thresholds
- No visual guard regressions
- Budgets respected (≤2 jobs, ≤10 files, ≤200 LOC per job)

---

## 📊 Lane & Scope

**Lane:** `viz-engine-projectm/**`, `docs/**` (docs-only), `viz-milk/**` (overlay only)  
**Scope:**
- C++/renderer audio envelope code
- Audio intake mapping
- Feature flags and configuration
- Canary deployment logic
- Optional: Milk v0 overlay meter

**Out of Scope:**
- Non-audio visual changes
- Unrelated feature additions
- Breaking changes to existing APIs

---

## 🔒 Budgets & Guardrails

**Budgets:**
- ≤ **2 jobs** (R1: Envelope/Intake, R2: Feature Flag/Canary)
- ≤ **10 files** total
- ≤ **200 LOC per job**
- Single-writer lock
- Exit codes: 0/50/51/52/53
- Bots do **NOT** merge

**Two-Agent Discipline:**
- A (Implementer) writes
- B (Balancer) verifies (read-only)
- B never acquires locks or writes

**Stability Pack:**
- Human-gated merge required
- Branch protection enforced
- PR + required status checks

---

## 🔧 Job Breakdown

### Job R1 — Envelope Calibration & Intake Mapping *(≤200 LOC, ≤6 files)*

**Scope:** C++/renderer audio envelope improvements

**Edits:**
1. Add **attack/release** envelope
   - Attack: 15-25 ms
   - Release: 120-180 ms
2. **Log-gain** mapping to highlight mid-energy dynamics
3. Export intake metrics:
   - `audio_rms_intake`
   - `audio_envelope`
   - `audio_peak`
4. Optional: Tiny overlay in Milk v0 (OSD meter) or `/milk/health` JSON fields

**Tests (changed-paths only):**
- **Synthetic 3-pack (60s each):**
  1. AM-sine
  2. Percussive clicks
  3. Bass sweep
- Compute **Pearson r(envelope,intake)** vs known envelopes
- **Pass criteria:** r ≥ **0.78** on each; underrun ratio < **0.5%**

**Artifacts:**
- `GATE_019_JOB_R1_EVIDENCE.md` (tables + brief plots)
- `.agent/EVIDENCE.log`

**Acceptance:**
- r(envelope,intake) ≥ 0.78 across all 3 scenarios
- Underrun ratio < 0.5%
- No test regressions
- Budgets/process respected

---

### Job R2 — Feature-Flag Enable + Canary *(≤200 LOC, ≤6 files)*

**Scope:** Feature flag deployment with canary rollout

**Edits:**
1. Default `AUDIO_ENABLED=true` behind config/flag
2. Keep **hard kill-switch** path for emergency disable
3. Canary ramp: **0% → 10% (5 min) → 50% (2 min) → 100%**
   - Auto-halt on breach
4. Emit synthetic span `audio.enable.canary` with attributes:
   - `r` (correlation)
   - `underrun_ratio`
   - `tick_jitter_ms`

**Acceptance (Go/No-Go):**
- Canary completes with **no alert**
- KPIs within thresholds:
  - `underrun_ratio < 0.5%`
  - `r ≥ 0.78`
  - `tick_jitter_ms(max) ≤ 8 ms`
- **No regressions** in visual guard metrics

**Artifacts:**
- `GATE_019_JOB_R2_EVIDENCE.md`
- Dashboard screenshot(s)
- `.agent/EVIDENCE.log`

---

## 📂 Evidence Package

**Required Artifacts:**

1. **`.agent/EVIDENCE.log`** — Complete execution trail:
   - `plan → preflight → lock → edit → test → report → exit`

2. **`GATE_019_JOB_R1_EVIDENCE.md`** — R1 results:
   - Envelope calibration details
   - Test results (3 scenarios)
   - Pearson r correlation tables
   - Underrun analysis

3. **`GATE_019_JOB_R2_EVIDENCE.md`** — R2 results:
   - Canary deployment log
   - KPI measurements
   - Dashboard screenshots
   - Visual guard confirmation

4. **BOSSCAT_LOG** — One-liner if GREEN

---

## 🚦 Gate Hand-Off Signal

**Post when GREEN:**

```
@cat ready-for-gate : #019

Status: GREEN
Evidence: GATE_019_JOB_R1_EVIDENCE.md, GATE_019_JOB_R2_EVIDENCE.md
KPIs: r≥0.78 (3/3 scenarios), underrun<0.5%, jitter(max)≤8ms
Canary: Completed (0%→10%→50%→100%) with no alerts
Budgets: OK
ECRR: COMPLETE
```

---

## 🏷️ Post-Approval Admin

**Tag:** `gate-019-green-2025-10-26`
- Annotate with commits + evidence paths

**Updates:**
- `docs/GATE_STATUS_DASHBOARD.md` (Gate #010 AMBER → GREEN)
- `BOSSCAT_LOG` (one-liner acceptance entry)

---

## 📋 Parallel Housekeeping (Low-Risk, Doc-Only)

**P2 — Archive Gate #016:**
- Move to `docs/archive/gates/2025-10/016/`
- Update index
- Commit in DOCS lane (≤1 file move list + index)

**Dependabot Rescan:**
- Passive monitoring (24h)
- Manual re-scan if needed
- Screenshot for Gate #018 evidence addendum

---

## 🛡️ Exit Criteria

**GREEN (Exit 0):**
- r(envelope,intake) ≥ 0.78 (3/3 scenarios)
- underrun < 0.5%
- tick_jitter_ms(max) ≤ 8 ms
- Canary: 100% with no alerts
- Visual guard: No regressions
- Budgets respected
- ECRR trail complete

**AMBER (Exit 50):**
- Partial success (1-2 scenarios pass)
- Document path to GREEN
- Evidence complete

**FAIL (Exit 51):**
- Budgets exceeded
- Process violations

**BLOCKED (Exit 52):**
- Cannot meet KPIs
- Breaking changes required
- Infrastructure issues

---

**Status:** 🔵 IN PROGRESS  
**Start:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM directive

---

🐾 *Audio remediation in progress. Upgrading Gate #010 AMBER → GREEN.*
