# Gate #019B — Hybrid Envelope Detector (Micro-Gate)

**Authority:** BossCat OEM  
**Date:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Gate Type:** Micro-Gate (Audio Enhancement)  
**Parent Gate:** #019 (AMBER - reclassified)  
**Status:** 🔵 **IN PROGRESS**

---

## 🎯 Goal

Add 100ms RMS envelope alongside instantaneous attack/release follower. Expose both. Update tests to correlate Sine-Burst → env_inst and AM-Sine → env_rms100. Keep budgets tight; human-gated merge.

**Target State:**
- AM-Sine: r(env_rms100, expected) ≥ **0.88**
- Sine-Burst: r(env_inst, expected) ≥ **0.90**
- Underrun < **0.5%**
- ECRR complete

**Success Criteria:**
- Both scenarios pass
- Budget compliant (≤1 job, ≤6 files, ≤150 LOC)
- Evidence complete

---

## 📊 Lane & Scope

**Lane:** `viz-engine-projectm/**`, `docs/**` (docs-only)  
**Scope:**
- C++ audio-injector (add RMS envelope)
- Test harness (dual-envelope validation)
- Evidence documentation

**Out of Scope:**
- Non-audio changes
- Feature additions beyond RMS envelope

---

## 🔒 Budgets & Guardrails

**Budgets:**
- ≤ **1 job** (Hybrid detector implementation)
- ≤ **6 files**
- ≤ **150 LOC**
- Single-writer lock
- Exit codes: 0/50/51/52/53
- Bots do **NOT** merge

**Stability Pack:**
- Human-gated merge required
- Branch protection enforced

---

## 🔧 Implementation Plan

### 1. RMS Detector (IIR of Squares)

**Algorithm:**
```cpp
alpha_rms = exp(-1/(τ·fs)), where τ=0.100s
ema2[n] = alpha_rms*ema2[n-1] + (1-alpha_rms)*x[n]^2
env_rms100 = sqrt(ema2[n])
```

**Keep:** Current instantaneous follower as `env_inst`

**Add:** 100ms RMS envelope as `env_rms100`

**LOC Estimate:** ~30 LOC (detector + init)

---

### 2. API/Telemetry

**Getters:**
- `envelope_inst()` (current envelope, renamed)
- `envelope_rms100()` (new RMS envelope)

**Optional:** Add to `/audio/stats` endpoint

**LOC Estimate:** ~5 LOC

---

### 3. Test Harness Updates

**AM-Sine Test:**
- Compute ground-truth via windowed RMS (100ms) over input
- Correlate vs `env_rms100`
- Target: r ≥ 0.88

**Sine-Burst Test:**
- Correlate expected burst envelope vs `env_inst`
- Target: r ≥ 0.90

**LOC Estimate:** ~25 LOC (test logic updates)

---

### 4. Evidence

**Artifacts:**
- `GATE_019B_EVIDENCE.md` — 2x2 table, CI run ID, results
- `.agent/EVIDENCE.log` — Execution trail
- **BOSSCAT_LOG:** "#019 reclassified AMBER; #019B closes AM-Sine gap"

---

## 🎯 Acceptance Criteria

| Scenario | Envelope | Expected | Threshold |
|----------|----------|----------|-----------|
| **Sine-Burst** | `env_inst` | Burst shape | r ≥ **0.90** |
| **AM-Sine** | `env_rms100` | RMS modulation | r ≥ **0.88** |
| **Buffer** | underrun | - | **< 0.5%** |

---

## 🔧 Bounded Tuning (If Needed)

**If AM-Sine r < 0.88:**
- Adjust τ to 80-120ms (one pass only)
- Rerun CI
- If still failing → ECRR and hold (do not expand scope)

---

## 🚦 Gate Hand-Off Signal

**Post when GREEN:**

```
@cat ready-for-gate : #019B

Status: GREEN
Evidence: GATE_019B_EVIDENCE.md
KPIs: AM-Sine r(env_rms100)≥0.88, Sine-Burst r(env_inst)≥0.90, underrun<0.5%
Budgets: OK (≤1 job, ≤6 files, ≤150 LOC)
ECRR: COMPLETE
Notes: #019 reclassified AMBER; #019B closes AM-Sine gap
```

---

## 📋 Dashboard Updates

**Gate #019:** Mark as AMBER (partial success)  
**Gate #019B:** Add as IN-PROGRESS → GREEN on completion  
**BOSSCAT_LOG:** Record reclassification + micro-gate

---

## 🛡️ Exit Criteria

**GREEN (Exit 0):**
- AM-Sine: r(env_rms100) ≥ 0.88
- Sine-Burst: r(env_inst) ≥ 0.90
- Underrun < 0.5%
- Budgets respected
- ECRR complete

**AMBER (Exit 50):**
- One scenario passes
- Document path to GREEN

**FAIL (Exit 51):**
- Budgets exceeded

**BLOCKED (Exit 52):**
- Cannot meet KPIs after tuning

---

**Status:** 🔵 IN PROGRESS  
**Start:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM directive

---

🐾 *Executing hybrid detector: instantaneous + 100ms RMS envelope.*
