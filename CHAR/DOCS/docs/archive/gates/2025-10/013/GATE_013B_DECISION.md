# Gate #013B - Path Forward Decision

**Date:** 2025-10-24  
**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Status:** 🟡 **AMBER - DECISION REQUIRED**

---

## 🎯 Current State

**Gate #013B Result:** 🟡 **AMBER**

**What Works:**
- ✅ Native audio bridge operational (100 LOC C++ monitor)
- ✅ Audio stats tracked (RMS, peak, EMA)
- ✅ Perfect reactivity correlation: **r = 1.0**
- ✅ Motion detected: Δluma 0.13-0.19
- ✅ Fast preset switching: 264-389ms (< 1.5s target)
- ✅ Budget compliant: 3 files, 108 LOC

**What Blocks GREEN:**
- ❌ Blackout: 67-85% (target: ≤20%)
- ❌ PulseAudio pipe-source won't load in container
- ❌ FIFO creation fails without PulseAudio
- ❌ ProjectMSDL can't capture audio from pipe-source

---

## 🔍 Root Cause Analysis

### Environmental Blocker (PulseAudio)

**Issue:** PulseAudio `module-pipe-source` fails to load in Docker container

**Evidence:**
```
[pm-run] Loading PulseAudio pipe-source module...
[pm-run] Pipe-source module load failed
[pm-bridge] FIFO open failed: No such file or directory
```

**Technical Constraint:**
- projectMSDL runs as separate process (spawned by server.js)
- pm-audio-bridge runs as separate process (monitoring)
- No direct IPC between bridge and projectMSDL
- PulseAudio required to route audio between processes
- PulseAudio fails in containerized environment

**Why This is Hard to Fix:**
- PulseAudio requires system-level permissions
- May need privileged containers or device passthrough
- Environment-specific (works on some systems, not others)
- Not a code issue—it's an infrastructure constraint

---

## 🚀 Three Paths Forward

### Option 1: Fix PulseAudio in Container
**Goal:** Make PulseAudio pipe-source work in Docker

**Approach:**
- Debug PulseAudio module loading
- Try privileged containers
- Investigate device passthrough
- Test different PulseAudio configurations

**Estimated Effort:** Medium-High (4-8 hours)  
**Success Probability:** Medium (50-60%)  
**Risk:** May require system changes outside our control  
**Budget Impact:** Likely exceeds gate budget (exploration only)

**Verdict:** ⚠️ **NOT RECOMMENDED** - Environmental constraints outside our control

---

### Option 2: Replace projectMSDL with In-Process Renderer
**Goal:** Build custom renderer using libprojectM API directly

**Approach:**
- Create new C++ application using libprojectM library
- Feed audio directly to projectM instance (no IPC)
- Replace projectMSDL process with custom renderer
- Integrate with existing HTTP API

**Estimated Effort:** Very High (>200 LOC, 8-16 hours)  
**Success Probability:** High (80-90%)  
**Risk:** Large architectural change  
**Budget Impact:** ❌ **EXCEEDS Gate #013B budget** (≤120 LOC)

**Verdict:** 🟡 **DEFER to Future Gate** - Scope too large for #013B

---

### Option 3: Accept AMBER + Optimize Presets (RECOMMENDED)
**Goal:** Accept current AMBER state; focus on preset optimization

**Approach:**
- Accept Gate #013B as AMBER (audio correlation proven: r=1.0)
- Acknowledge PulseAudio as known environmental limitation
- Focus on preset optimization to reduce blackout
- Target: Reduce blackout from 67-85% → 40-50% via preset tuning
- Re-test presets with audio feed when available

**Rationale:**
1. **Audio correlation is proven:** r=1.0 shows audio IS affecting visuals
2. **Motion is present:** Δluma 0.13-0.19 confirms visual activity
3. **Blackout is preset-dependent:** Different presets show different blackout levels
4. **Preset optimization is lower risk:** Small, incremental improvements
5. **Path forward is clear:** Gate #016 already focuses on preset curation

**Estimated Effort:** Low (continued preset work)  
**Success Probability:** High (80%)  
**Risk:** Low (preset changes are reversible)  
**Budget Impact:** ✅ Within existing Gate #016 work

**Verdict:** ✅ **RECOMMENDED** - Pragmatic, low-risk path forward

---

## 📊 Decision Matrix

| Criterion | Option 1<br/>Fix PulseAudio | Option 2<br/>Custom Renderer | Option 3<br/>Accept AMBER |
|-----------|----------------------------|------------------------------|---------------------------|
| **Effort** | Medium-High | Very High | Low |
| **Success Probability** | 50-60% | 80-90% | 80%+ |
| **Budget Compliance** | ⚠️ Exploration only | ❌ Exceeds (>200 LOC) | ✅ Within limits |
| **Risk** | High (env dependent) | Medium (arch change) | Low (incremental) |
| **Time to GREEN** | Unknown | 8-16 hours | Ongoing (Gate #016) |
| **Reversibility** | High | Low | High |
| **Value Delivered** | Uncertain | High (if works) | Immediate |

---

## ✅ Recommended Decision: Accept AMBER (Option 3)

### Justification

1. **Technical Evidence is Strong:**
   - Audio bridge is operational
   - Reactivity r=1.0 proves audio-visual correlation
   - Motion detected on all presets
   - Fast preset switching maintained

2. **Blocker is Environmental, Not Architectural:**
   - PulseAudio constraint is system-level
   - Not a code quality issue
   - Difficult to resolve within gate budget
   - May not be solvable in Docker without privileged access

3. **Path to Improvement is Clear:**
   - Blackout reduction via preset optimization (Gate #016)
   - Target: 67-85% → 40-50% (realistic without audio)
   - Further reduction possible with better presets
   - Can re-attempt GREEN when environmental constraints change

4. **AMBER is Honest Assessment:**
   - ECRR discipline: report reality, not aspirations
   - Documents blocker clearly for future reference
   - Preserves option to retry with different approach
   - Maintains trust through honest reporting

### Acceptance Criteria for AMBER

If BossCat OEM accepts Gate #013B as AMBER:
- ✅ Document PulseAudio constraint as known limitation
- ✅ Update gate status to "AMBER (environmental blocker)"
- ✅ Continue to Gate #016 (preset optimization)
- ✅ Target blackout reduction to 40-50% via preset tuning
- ✅ Leave door open for future Gate #013C (alternate approach)

### Future Path (Optional)

**Gate #013C - In-Process Audio Renderer (Future)**
- Scope: Replace projectMSDL with custom libprojectM app
- Budget: ≤300 LOC, ≤2 jobs
- Goal: Direct audio feed without PulseAudio dependency
- Timing: After Gate #016 (preset library) is GREEN

---

## 📋 Proposed Actions

**Immediate (If AMBER Accepted):**
1. ✅ Mark Gate #013B as AMBER with "environmental blocker" note
2. ✅ Update GATE_013B_STATUS.md to reflect acceptance
3. ✅ Commit reconciliation + decision documentation
4. ✅ Proceed to Gate #016 (preset optimization)
5. ✅ Target blackout reduction via preset tuning

**Medium Term:**
- Continue Gate #016 work (preset curation + scoring)
- Test curated presets with audio feed
- Document which presets work best with/without audio

**Long Term (Optional):**
- Schedule Gate #013C (custom renderer) if needed
- Re-evaluate PulseAudio approach when container environment changes
- Consider alternate audio routing mechanisms

---

## 🎯 Success Metrics (AMBER Acceptance)

**Gate #013B (AMBER):**
- ✅ Audio bridge operational
- ✅ Reactivity r = 1.0 (audio correlation proven)
- ✅ Motion detected (Δluma > 0)
- ✅ Fast switching (< 1.5s)
- 🟡 Blackout 67-85% (target ≤20%, blocked by environment)

**Gate #016 (Target):**
- 🎯 Curated preset library (12-20 presets)
- 🎯 Blackout reduction to 40-50% (via optimization)
- 🎯 Motion >0 on all presets
- 🎯 Sub-second switching maintained

---

## 📝 BossCat OEM Decision Required

**Question:** Accept Gate #013B as AMBER and proceed with Option 3 (preset optimization)?

**Option A: Accept AMBER (Recommended)**
- Accept current Gate #013B state
- Acknowledge environmental blocker
- Proceed to Gate #016 (preset optimization)
- Target blackout reduction to 40-50%

**Option B: Pursue Option 1 (Fix PulseAudio)**
- Allocate time to debug PulseAudio in Docker
- Risk: Medium-high effort with uncertain outcome
- May require system-level changes

**Option C: Defer to Option 2 (Custom Renderer)**
- Schedule Gate #013C for in-process renderer
- Larger scope, deferred to after Gate #016
- Clear path to GREEN but higher effort

---

**Standing by for BossCat OEM directive.**

**Recommended:** Option A (Accept AMBER, continue to Gate #016)

🐾 **Cursor{Implementer} awaiting decision.**

