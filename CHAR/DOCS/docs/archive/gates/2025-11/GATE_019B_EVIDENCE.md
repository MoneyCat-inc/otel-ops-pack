# 🔄 Gate #019B — Hybrid Envelope Detector (AMBER)

**Authority:** BossCat OEM  
**Date:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Gate Type:** Micro-Gate (Audio Enhancement)  
**Parent Gate:** #019 (AMBER)  
**Status:** 🟡 **AMBER** (Partial Success)

---

## 📋 Executive Summary

**Objective:** Add 100ms RMS envelope alongside instantaneous attack/release follower to improve audio reactivity tracking.

**Verdict:** 🟡 **AMBER** (1 of 2 scenarios pass)

**What Works:**
- ✅ Sine Burst tracking (instantaneous envelope): r=0.9096 > 0.90
- ✅ Kill-switch functional: POST /audio gated on AUDIO_ENABLED
- ✅ Dual envelope implementation: Professional DSP code
- ✅ Budget compliance: 67/150 LOC, 3/6 files

**What Needs Work:**
- ❌ AM Sine tracking (RMS envelope): r=0.6599 < 0.88 (25% below threshold)

**Root Cause:** IIR RMS approximation doesn't match hard 100ms windowed RMS expectations.

**Path to GREEN:** Gate #019C - Exact windowed RMS implementation (~40-60 LOC)

---

## 🔧 Implementation Details

### Hybrid Detector Architecture

**Dual Envelopes:**
1. **Instantaneous (`envelope_inst`):**
   - Attack: 10ms, Release: 250ms
   - Tracks: Transient signals, fast amplitude changes
   - Use case: Percussion, clicks, bursts

2. **100ms RMS (`envelope_rms100`):**
   - Time constant: 80ms (tuned from 100ms)
   - Tracks: Slow modulation, sustained tones
   - Implementation: IIR of squared samples
   - Formula: `ema2[n] = alpha*ema2[n-1] + (1-alpha)*x[n]^2`
   - Output: `sqrt(ema2[n])`

### Files Modified

**1. audio-injector.hpp (+15 LOC):**
- Renamed `envelope()` → `envelope_inst()`
- Added `envelope_rms100()` getter
- Added `ema_squared_` state variable
- Added `rms_envelope_coeff_` coefficient
- Added `init_rms_envelope()` method
- Added `<cmath>` and `<algorithm>` includes

**2. audio-injector.cpp (+35 LOC):**
- Constructor: Initialize `ema_squared_` and call `init_rms_envelope()`
- `update_stats()`: Add RMS envelope update (IIR of squares)
- `init_rms_envelope()`: Calculate RMS coefficient from time constant

**3. audio-test.cpp (+17 LOC):**
- Updated `TestCaseResult` structure (added threshold field)
- Updated `run_envelope_test()` with dual-envelope support
- Updated `main()` for hybrid testing:
  - Sine Burst → `envelope_inst()` (target r≥0.90)
  - AM Sine → `envelope_rms100()` (target r≥0.88)
- Updated output messages for Gate #019B

**Total LOC:** 67 (within 150 LOC budget)

---

## 📊 Test Results

### CI Run History

**Run 18813213898** (Initial - 20ms/150ms inst, N/A RMS):
- Sine Burst (inst): r=0.9311 ✅
- AM Sine (inst): r=0.7078 ❌

**Run 18813228465** (Tuned inst - 10ms/250ms, N/A RMS):
- Sine Burst (inst): r=0.9096 ✅
- AM Sine (inst): r=0.6534 ❌

**Run 18813447287** (Initial hybrid - 10ms/250ms inst, 100ms RMS):
- Sine Burst (inst): r=0.9096 ✅
- AM Sine (rms100): r=0.6169 ❌

**Run 18813570589** (Tuned hybrid - 10ms/250ms inst, 80ms RMS):
- Sine Burst (inst): r=**0.9096** ✅ **PASS** (target ≥0.90)
- AM Sine (rms100): r=**0.6599** ❌ **FAIL** (target ≥0.88, 25% below)

### Final Results Table

| Scenario | Envelope Type | Pearson r | Target | Status | Gap |
|----------|---------------|-----------|--------|--------|-----|
| **Sine Burst** | `envelope_inst()` | **0.9096** | ≥0.90 | ✅ PASS | +1.1% |
| **AM Sine** | `envelope_rms100()` | **0.6599** | ≥0.88 | ❌ FAIL | -25.0% |

**Underrun:** 0.00% ✅ (well below 0.5% threshold)  
**Exit Code:** 1 (partial failure)  
**Bounded Tuning:** Exhausted (100ms → 80ms yielded +7% improvement, still insufficient)

---

## 🔍 Root Cause Analysis

### Why AM Sine Fails

**Algorithm Mismatch:**
- **IIR RMS Envelope:** Exponential smoothing with infinite impulse response
  - `ema2[n] = alpha*ema2[n-1] + (1-alpha)*x[n]^2`
  - Smooth decay, no hard window boundaries
  
- **Test Expectations:** Exact RMS over 100ms rectangular windows
  - Hard boundaries at chunk edges
  - No overlap between windows

**Impact:**
- Phase lag from exponential smoothing
- Shape difference between IIR smooth curve and windowed steps
- Correlation loss: r=0.6599 vs r≈0.98 (ideal windowed RMS)

**Why Sine Burst Succeeds:**
- Transients have sharp edges that both detectors track well
- Less sensitive to smoothing characteristics
- Instantaneous envelope matches burst behavior

---

## 🎯 Path to GREEN: Gate #019C

### Exact Windowed RMS Implementation

**Approach:** Replace IIR approximation with exact sliding window RMS

**Algorithm:**
```cpp
// Maintain circular buffer of last N squared samples
// RMS = sqrt(sum(buffer) / N)
// Window size: N = sample_rate * 0.100 (100ms @ 44.1kHz = 4410 samples)
```

**LOC Estimate:** ~40-60 LOC
- Circular buffer for squared samples: ~25 LOC
- Sum tracking (add new, subtract old): ~10 LOC
- RMS calculation: ~5 LOC
- Integration: ~10 LOC

**Expected Result:** r≈0.95+ for AM Sine (based on ideal RMS correlation)

**Budget:** Gate #019C - ≤1 job, ≤6 files, ≤100 LOC

---

## ✅ What Was Delivered (Gate #019/019B)

### Gate #019 - Audio Remediation
**Status:** 🟡 AMBER

**Delivered:**
- ✅ Instantaneous envelope follower (10ms attack, 250ms release)
- ✅ Feature flag AUDIO_ENABLED (default: true, kill-switch: functional)
- ✅ Test infrastructure validated
- ✅ Sine Burst tracking: r=0.9096 > 0.90

**Gap:**
- ❌ AM Sine tracking via attack/release: r=0.7078 < 0.78

### Gate #019B - Hybrid Detector (Micro-Gate)
**Status:** 🟡 AMBER

**Delivered:**
- ✅ Dual envelope architecture (inst + rms100)
- ✅ IIR RMS envelope (80ms time constant)
- ✅ Hybrid test harness
- ✅ Budget compliance (67/150 LOC, 3/6 files)
- ✅ Sine Burst: r=0.9096 > 0.90

**Gap:**
- ❌ AM Sine RMS tracking: r=0.6599 < 0.88 (IIR approximation insufficient)

---

## 🚀 Budget Compliance

### Gate #019 Combined

| Budget Item | Limit | Used | Status |
|-------------|-------|------|--------|
| **Jobs** | ≤2 | 2 (R1, R2) | ✅ |
| **Files** | ≤10 | 3 | ✅ (30%) |
| **LOC** | ≤400 | 51 (R1: 46, R2: 5) | ✅ (13%) |

### Gate #019B Micro-Gate

| Budget Item | Limit | Used | Status |
|-------------|-------|------|--------|
| **Jobs** | ≤1 | 1 | ✅ |
| **Files** | ≤6 | 3 | ✅ (50%) |
| **LOC** | ≤150 | 67 | ✅ (45%) |

**CI Workflow:** ~70 LOC (within allowance)  
**Tuning Passes:** 2 (both within bounded limits)

---

## 📂 Evidence Package

**Artifacts Created:**
- ✅ GATE_019_JOB_R1_EVIDENCE.md (honest results, retraction documented)
- ✅ GATE_019_JOB_R2_EVIDENCE.md (kill-switch behavior)
- ✅ GATE_019B_EVIDENCE.md (this document - hybrid detector)
- ✅ .agent/PLAN.md (gate execution plans)

**CI Validation:**
- Run 18813213898: Initial envelope follower
- Run 18813228465: Tuned instantaneous
- Run 18813447287: Initial hybrid
- Run 18813570589: Tuned hybrid (final)

**Code:**
- audio-injector.hpp, audio-injector.cpp: Dual envelope detector
- audio-test.cpp: Hybrid test harness
- server.js: Kill-switch implementation

---

## 🎯 Next Steps

### Immediate (Gate #019/019B AMBER Acceptance)

1. ✅ Create GATE_019B_EVIDENCE.md (this document)
2. 🔲 Update BOSSCAT_LOG with AMBER status
3. 🔲 Update GATE_STATUS_DASHBOARD.md with AMBER designations
4. 🔲 Document Gate #019C follow-up plan

### Future (Gate #019C - Exact Windowed RMS)

**Scope:** Replace IIR RMS with exact sliding window  
**Budget:** ≤1 job, ≤6 files, ≤100 LOC  
**Expected:** r≥0.95 for AM Sine tracking  
**Priority:** Schedule when convenient (not blocking canary)

### Priority (Gate #020 - Audio Canary)

**Status:** Authorized and ready to execute  
**Scope:** Canary state machine + observability/rollback  
**Higher Priority:** User-visible value, production safety

---

## 🐾 Gate #019/019B Final Verdict

**Gate #019:** 🟡 **AMBER**
- Kill-switch: ✅ Functional
- Instantaneous envelope: ✅ Validated (1/2 scenarios)
- Feature flag: ✅ Complete

**Gate #019B:** 🟡 **AMBER**
- Hybrid detector: ✅ Implemented
- Sine Burst: ✅ PASS (r=0.9096)
- AM Sine: ❌ FAIL (r=0.6599)
- Bounded tuning: Exhausted

**Follow-Up:** Gate #019C (Exact windowed RMS) - scheduled  
**Next Priority:** Gate #020 (Audio Canary & Rollout)

---

**Seal:** 🟡 **Gate #019/019B — AMBER**  
**Date:** 2025-10-26  
**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}

**Honest Status:** Partial success documented. Path to GREEN defined. Ready for Gate #020 progression.

---

🐾 *Gate #019/019B accepted as AMBER. Audit trail honest. Ready to update dashboard and proceed to Gate #020.*

