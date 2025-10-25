# Gate #016 — Job V1 Execution Plan
## Preset Safety & Brightness Guard

**Lane:** `lane/visual-016`  
**Job:** V1 (Preset Safety & Brightness Guard)  
**Lock:** Acquired 2025-10-24  
**Executor:** Cursor{Implementer} (Writer A)  
**Monitor:** IONA-CATS-DOCS-BETA (Reader B)

---

## 🎯 Goal (≤150 words)

Cut blackout behavior by curating a safe preset list and adding a low-luminance brightness guard. The guard computes per-frame median luma; if luma < L_min (0.06-0.08) for >100ms, the system overlays a subtle gradient fallback and/or auto-switches to the next safe preset. Configuration exposes L_min and guard window via config. Changed-paths tests run each curated preset for 60s, recording blackout_ratio and max_blackout_gap_ms. Accept when blackout_ratio ≤5% per preset and max_blackout_gap_ms ≤150ms. Maintain ECRR discipline: plan → preflight → lock → edit → test → report → exit. Balancer verifies; bots do not merge.

**Budgets:** ≤200 LOC, ≤6 files, ≤90 min TTL

---

## 🛠️ Components

### 1. Preset Safe List
- Leverage existing `presets-projectm/curated/` library (15 presets from Gate #016 scoring)
- Filter out any presets with blackout >5% from previous runs
- Create configuration file for safe preset rotation

### 2. Brightness Guard (Luminance Floor)
- Add per-frame luma computation (median or mean of frame pixels)
- Track low-luma duration (consecutive frames below L_min)
- Trigger guard after 100-150ms of low luma:
  - Option A: Overlay subtle gradient (floor brightness)
  - Option B: Auto-switch to next preset
- Log `blackout_guard_trigger` counter for evidence

### 3. Configuration
- `L_min`: 0.06-0.08 (normalized, configurable)
- `guard_window_ms`: 100-150 (configurable)
- `guard_mode`: "overlay" or "auto_switch"

---

## ✅ Acceptance Criteria

| Metric | Threshold | Method |
|--------|-----------|--------|
| **blackout_ratio** | ≤5% per preset | 60s test run |
| **max_blackout_gap_ms** | ≤150ms | Longest contiguous low-luma streak |
| **Files touched** | ≤6 | Hard budget |
| **LOC added/changed** | ≤200 | Hard budget |
| **ECRR** | Complete | plan, evidence, test, report |

---

## 🔬 Test Plan (Changed-Paths Only)

**Synthetic Visual Test:**
1. Run each curated preset for 60s
2. Capture frame luma at 60 FPS
3. Compute:
   - `blackout_ratio = frames_below_Lmin / total_frames`
   - `max_blackout_gap_ms = longest_consecutive_low_luma * (1000/60)`
4. Log guard trigger count
5. Record to JSONL evidence file

**Pass Criteria:**
- All curated presets meet blackout_ratio ≤5%
- All curated presets meet max_blackout_gap_ms ≤150ms
- Guard activates appropriately during low-luma periods

---

## 📦 Deliverables

- `viz-engine-projectm/brightness-guard.js` (or integrated into `server.js`)
- `config/visual-guard.json` (configuration)
- `scripts/test-visual-guard.ps1` (validation script)
- `GATE_016_JOB_V1_EVIDENCE.md` (results)
- `.agent/EVIDENCE.log` (JSONL events)
- `docs/BossCat/BOSSCAT_LOG.md` entry

---

## 🔄 Rollback Plan

On failure to meet acceptance criteria within TTL or budgets:
1. **Contain:** Stop testing, preserve evidence
2. **Rollback:** Revert all edits (≤6 files)
3. **Report:** Mark Job V1 AMBER/RED in evidence log
4. **Exit:** Code 53 (retry exhausted) or 51 (git blocked)

---

## 📊 ECRR Events (Required)

```jsonl
{"event":"plan","job":"V1","lane":"visual-016","timestamp":"2025-10-24T..."}
{"event":"preflight","kill_switch":"clear","git_state":"clean","timestamp":"..."}
{"event":"lock","acquired":true,"timestamp":"..."}
{"event":"edit","files_touched":N,"loc_delta":N,"timestamp":"..."}
{"event":"test","result":"PASS|FAIL","metrics":{...},"timestamp":"..."}
{"event":"report","status":"GREEN|AMBER|RED","timestamp":"..."}
{"event":"exit","code":0,"lock_released":true,"timestamp":"..."}
```

---

**Status:** Plan complete, lock acquired, ready to implement.  
**Next:** Implement brightness guard components and validation script.
