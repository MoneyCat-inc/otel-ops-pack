# Gate #014 - Authoring + Feedback Loop

**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Date:** 2025-10-24  
**Status:** 🟢 **OPEN** - Ready for execution

---

## 🎯 Objective

Deliver the **human-in-the-loop preset authoring workflow** and visual scoring loop over the operational **pm-engine** + **scorebot**, enabling rapid iteration on Milkdrop presets with immediate visual feedback and metrics.

---

## ✅ Acceptance Criteria (GREEN)

1. **✅ Fast Preset Switching:** `/preset` endpoint ≤1.5s (already achieved: 209-349ms)
2. **✅ Visual Capture:** `/snap.jpg` + `/pm/metrics` functional and accessible
3. **✅ Authoring Loop Script:** Runs N iterations:
   - Load preset
   - Wait 3s for render stabilization
   - Capture frame
   - Collect metrics (blackout, motion, mean luma)
   - Log decision to JSONL
4. **✅ Evidence:** JSONL trace per iteration + N snapshots saved to `artifacts/pm/author/`

---

## 📦 Scope (Bounded Execution)

### Files Modified: ≤3
1. **`scripts/author-loop.ps1`** (~120 LOC)
   - Iterate over preset list
   - Call pm-engine APIs
   - Collect and score visuals
   - Generate ECRR JSONL evidence

2. **`viz-engine-projectm/server.js`** (≤40 LOC, if needed)
   - Verify `/pm/metrics` exposes all required fields
   - Add any missing metrics (motion energy window)

3. **`docs/BossCat/GATE_014_PLAN.md`** (this file, ~40 LOC)
   - Declare intent before move
   - Define scope, tests, acceptance

**Total LOC:** ≤200 (within budget)  
**Files:** 3 (within ≤10 guideline)  
**Lane:** Single-writer (Cursor{Implementer})

---

## 🔧 Technical Design

### Authoring Loop Flow
```
FOR each preset in list:
  1. POST /pm/preset → load preset
  2. WAIT 3s → render stabilization
  3. GET /snap.jpg → capture frame
  4. GET /pm/metrics → collect metrics
  5. SCORE → calculate decision (blackout, motion, luma)
  6. LOG → append to JSONL
  7. SAVE → frame to artifacts/pm/author/
END
```

### Metrics Collected
- **Blackout %** - percentage of near-black pixels
- **Mean Luma** - average brightness (0-1 scale)
- **Motion** - frame-to-frame Δluma (if multi-iteration)
- **Preset Name** - for traceability
- **Timestamp** - for sequencing
- **Decision** - PASS/WARN/FAIL based on thresholds

### Evidence Format (JSONL)
```json
{"ts":"2025-10-24T10:45:00Z","preset":"starter_bass.milk","blackout_pct":15.2,"mean_luma":0.78,"motion":0.045,"decision":"PASS","snapshot":"snap_001.jpg"}
{"ts":"2025-10-24T10:45:03Z","preset":"sample_basic.milk","blackout_pct":8.1,"mean_luma":0.85,"motion":0.067,"decision":"PASS","snapshot":"snap_002.jpg"}
```

---

## 🧪 Validation Tests

### Test 1: Single Preset Loop
```powershell
pwsh scripts/author-loop.ps1 -Presets "presets-projectm/starter_bass.milk" -Iterations 1
```

**Expected:**
- 1 JSONL entry
- 1 snapshot in `artifacts/pm/author/`
- Metrics populated

### Test 2: Multi-Preset Loop
```powershell
pwsh scripts/author-loop.ps1 -Presets "presets-projectm/*.milk" -Iterations 3
```

**Expected:**
- 3 JSONL entries per preset
- N×3 snapshots
- Motion deltas calculated

### Test 3: Threshold-Based Filtering
```powershell
pwsh scripts/author-loop.ps1 -Presets "presets-projectm/*.milk" -BlackoutThreshold 25 -MinLuma 0.2
```

**Expected:**
- Only presets meeting thresholds marked PASS
- Others marked WARN/FAIL
- Evidence JSON complete

---

## 📊 Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Execution Time** | <30s for 3 presets | Wall clock |
| **API Latency** | Preset switch <1.5s | HTTP timer |
| **Evidence Quality** | 100% JSONL valid | JSON parse |
| **Snapshot Quality** | >0 bytes, valid JPEG | File size + type |
| **LOC Budget** | ≤200 | `git diff --stat` |
| **File Budget** | ≤3 | `git diff --name-only` |

---

## 🔐 Guardrails (ECRR Compliance)

### Examine
- Current pm-engine state verified via `/health`
- Presets list validated (file exists, readable)
- Output directory writable

### Clean
- No state leaks between iterations
- Temp files cleaned
- Container state unchanged

### Report
- JSONL evidence complete
- Snapshots archived
- Metrics logged
- BOSSCAT_LOG entry

### Role
- **A (Writer):** Cursor{Implementer} executes bounded changes
- **B (Observer):** BossCat OEM reviews evidence and approves

---

## 🚀 Execution Plan

### Phase 1: Infrastructure Verification (5 min)
- ✅ pm-engine running
- ✅ `/health`, `/pm/metrics`, `/snap.jpg` responding
- ✅ Presets directory accessible

### Phase 2: Script Implementation (30 min)
- Create `scripts/author-loop.ps1`
- Implement iteration logic
- Add metrics collection
- Generate JSONL evidence

### Phase 3: Validation (15 min)
- Run Test 1 (single preset)
- Run Test 2 (multi-preset)
- Verify evidence quality
- Check file/LOC budgets

### Phase 4: Gate Closure (10 min)
- Update BOSSCAT_LOG
- Archive evidence
- Generate status report

**Total Estimated Time:** ~60 minutes

---

## 📋 Rollback Plan

**If issues encountered:**
1. Stop execution immediately
2. Preserve logs and partial evidence
3. `git checkout scripts/` to restore state
4. Report blocker to BossCat OEM
5. Do not proceed without approval

**Rollback triggers:**
- API failures (>3 consecutive)
- Budget breach (LOC >200 or files >3)
- Evidence corruption
- Container instability

---

## 🔗 Dependencies

**Upstream (Required):**
- ✅ Gate #012B GREEN - pm-engine operational
- ✅ Gate #013 AMBER - API endpoints functional

**Downstream (Enables):**
- Gate #015 - Cursor co-author (MCP integration)
- Gate #016 - Preset library curation
- Gate #017 - Automated A/B testing

---

## 🐾 Approval & Execution

**Declared Intent:** ✅ Documented (this file)  
**Budget:** ✅ ≤3 files, ≤200 LOC  
**Authority:** BossCat OEM directive received  
**Executor:** Cursor{Implementer} standing by

**Status:** 🟢 **APPROVED FOR EXECUTION**

---

**Next Action:** Implement `scripts/author-loop.ps1` and execute validation tests.

