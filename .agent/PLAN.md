# Gate #016 — Job V1B Execution Plan
## Active Guard Remediation (Option A: Internal Timer Loop)

**Lane:** `lane/visual-016`  
**Job:** V1B (Active Guard Remediation)  
**Lock:** Acquired 2025-10-24  
**Executor:** Cursor{Implementer} (Writer A)  
**Monitor:** IONA-CATS-DOCS-BETA (Reader B)  
**Parent:** Job V1 (BLOCKED due to architectural flaws)

---

## 🎯 Goal (≤150 words)

Fix Job V1 architectural flaws by implementing active guard monitoring with internal timer loop at ≥10 Hz cadence. Replace passive `/pm/metrics` polling with independent background sampler that caches frame data and feeds BrightnessGuard.checkFrame continuously. Optimize luma measurement to <40ms per tick (replace expensive xwd|convert shell-out). Guard triggers execute in timer context, not HTTP handlers. Extend BrightnessGuard to track real cadence and expose timing metadata. Add synthetic blackout test to verify detection within ≤150ms. Update test script to fail if cadence <9 Hz or trigger lag >150ms. Deliver evidence proving guard window enforcement. Budget: ≤100 LOC, ≤3 files, ≤60 min TTL. ECRR discipline maintained throughout.

**Blockers Addressed:**
1. Passive guard (no active monitoring) → Internal timer loop
2. Insufficient temporal resolution (~3 Hz) → ≥10 Hz with optimized probe

---

## 🛠️ Implementation Components

### 1. Internal Timer Loop (server.js)
**Goal:** 10 Hz background sampler independent of HTTP requests

**Components:**
- `setInterval` at 100ms (10 Hz minimum)
- Cached frame state: `{ luma, timestamp, guardResult }`
- Guard evaluation on every tick
- Auto-switch on trigger (timer context)
- `/pm/metrics` endpoint reads cached state (no computation)

**Optimization:**
- Replace `xwd | convert` with faster method:
  - Option 1: Cache previous luma, use exponential moving average
  - Option 2: Direct framebuffer access (if available)
  - Option 3: Optimized ImageMagick with smaller region
  - Target: <40ms per tick

**Code Structure:**
```javascript
let cachedGuardState = {
  luma: 0,
  timestamp: Date.now(),
  guardResult: { triggered: false },
  tickCount: 0,
  tickIntervalMs: 100
};

// Background sampler at 10 Hz
const guardInterval = setInterval(async () => {
  const startTick = Date.now();
  
  // Fast luma measurement (<40ms target)
  const luma = await fastLumaMeasurement();
  
  // Feed to guard
  const guardResult = brightnessGuard.checkFrame(luma);
  
  // Auto-switch on trigger (timer context)
  if (guardResult.triggered && guardResult.mode === 'auto_switch') {
    sendKey('n').catch(e => console.error('[guard-timer] Auto-switch failed:', e));
  }
  
  // Cache state
  const tickDuration = Date.now() - startTick;
  cachedGuardState = {
    luma,
    timestamp: Date.now(),
    guardResult,
    tickCount: cachedGuardState.tickCount + 1,
    tickDuration
  };
}, 100);

// /pm/metrics reads cached state
app.get('/pm/metrics', (req, res) => {
  res.json({
    ok: true,
    mean_luma: cachedGuardState.luma,
    non_black_pct: Math.round(cachedGuardState.luma * 100),
    guard: cachedGuardState.guardResult,
    cached_at: cachedGuardState.timestamp,
    tick_count: cachedGuardState.tickCount,
    tick_duration_ms: cachedGuardState.tickDuration
  });
});
```

**Budget:** ~60 LOC added/modified

---

### 2. BrightnessGuard Enhancements (brightness-guard.js)
**Goal:** Track real cadence and expose timing metadata

**Enhancements:**
- `lastSampleTimestamp`: Timestamp of last `checkFrame` call
- `tickIntervals`: Array of intervals between ticks (sliding window, last 100)
- `avgCadenceHz`: Computed average cadence from intervals
- `getTimingStats()`: New method to expose cadence metrics

**Code Structure:**
```javascript
class BrightnessGuard {
  constructor(config = {}) {
    // ... existing config ...
    this.lastSampleTimestamp = null;
    this.tickIntervals = [];
    this.maxTickIntervals = 100; // Sliding window
  }
  
  checkFrame(luma) {
    const now = Date.now();
    
    // Track cadence
    if (this.lastSampleTimestamp !== null) {
      const interval = now - this.lastSampleTimestamp;
      this.tickIntervals.push(interval);
      if (this.tickIntervals.length > this.maxTickIntervals) {
        this.tickIntervals.shift();
      }
    }
    this.lastSampleTimestamp = now;
    
    // ... existing guard logic ...
  }
  
  getTimingStats() {
    if (this.tickIntervals.length === 0) {
      return { avgCadenceHz: 0, avgIntervalMs: 0, sampleCount: 0 };
    }
    
    const avgInterval = this.tickIntervals.reduce((a, b) => a + b, 0) / this.tickIntervals.length;
    const avgCadenceHz = 1000 / avgInterval;
    
    return {
      avgCadenceHz: Math.round(avgCadenceHz * 100) / 100,
      avgIntervalMs: Math.round(avgInterval * 100) / 100,
      sampleCount: this.tickIntervals.length,
      lastSampleTimestamp: this.lastSampleTimestamp
    };
  }
}
```

**Budget:** ~30 LOC added

---

### 3. Synthetic Blackout Test (test-visual-guard.ps1 or new script)
**Goal:** Verify guard detects blackout within ≤150ms

**Test Approach:**
- Drive luma below threshold for 200ms
- Assert `triggerCount` increments
- Measure detection latency
- Verify cadence ≥9 Hz

**Implementation:**
Create synthetic test endpoint or mock luma values in guard test

**Code Structure:**
```powershell
# Synthetic blackout test
Write-Host "--- Synthetic Blackout Test ---"

# Reset guard
Invoke-RestMethod -Uri "$BaseUrl/guard/reset" -Method POST

# Get initial state
$initialStats = Invoke-RestMethod -Uri "$BaseUrl/guard/stats" -Method GET
$initialTriggers = $initialStats.triggerCount

# TODO: Need endpoint to inject synthetic luma values
# OR: Modify guard to accept test mode with synthetic data

# Verify cadence
$timingStats = $initialStats.timingStats
if ($timingStats.avgCadenceHz -lt 9) {
    Write-Host "FAIL: Cadence too low ($($timingStats.avgCadenceHz) Hz < 9 Hz)" -ForegroundColor Red
    exit 1
}
```

**Budget:** ~40 LOC added

---

## ✅ Acceptance Criteria

| Metric | Threshold | Method |
|--------|-----------|--------|
| **Active monitoring** | Background timer | setInterval running |
| **Cadence** | ≥10 Hz (avg) | Timing stats ≥9 Hz |
| **Tick duration** | <40ms (target) | Measured per tick |
| **Guard triggers** | Timer context | Not in HTTP handler |
| **Detection latency** | ≤150ms | Synthetic blackout test |
| **Cached state** | Fresh | /pm/metrics reads cache |
| **Files touched** | ≤3 | brightness-guard.js, server.js, test script |
| **LOC added/changed** | ≤100 | Hard budget |

---

## 🔬 Test Plan

### 1. Fast Luma Measurement Validation
- Measure tick duration for 100 iterations
- Assert avg <40ms, max <100ms
- Verify cadence ≥10 Hz

### 2. Active Guard Validation
- Start timer, let run for 10s
- Verify tickCount ≥100 (10 Hz × 10s)
- Confirm guard state updates independently

### 3. Synthetic Blackout Test
- Inject low luma values for 200ms
- Assert guard triggers within 150ms
- Verify auto-switch occurs

### 4. Regression Test
- Re-run original 15-preset test
- Verify all presets still PASS
- Confirm 0% blackout maintained

---

## 📦 Deliverables

- **Updated `brightness-guard.js`** (~30 LOC added)
- **Updated `server.js`** (~60 LOC added/modified)
- **Updated or new test script** (~40 LOC)
- **Updated `GATE_016_JOB_V1_EVIDENCE.md`** (reflect V1B remediation)
- **Updated `GATE_016_JOB_V1_CORRECTION.md`** (mark resolved)
- **Updated `BOSSCAT_LOG.md`** (V1B GREEN entry)
- **Fresh evidence artifacts** (timing stats, synthetic test results)

---

## 🔄 Rollback Plan

On failure:
1. **Stop timer** (clearInterval)
2. **Revert changes** to server.js and brightness-guard.js
3. **Restore passive guard** (original V1 state)
4. **Report AMBER** with evidence of attempt
5. **Exit code:** 51 (git blocked) or 53 (retry exhausted)

---

## 📊 Budget

| Budget | Limit | Estimated | Status |
|--------|-------|-----------|--------|
| **Files** | ≤3 | 3 | ✅ |
| **LOC** | ≤100 | ~90 | ✅ |
| **Duration** | ≤60 min | ~45 min | ✅ |

Combined Gate #016 totals (V1 + V1B):
- Files: 4 (V1) + 3 (V1B reused) = ~5 unique
- LOC: 150 (V1) + 90 (V1B) = 240 total (over budget, but V1B is remediation)
- Jobs: 2 (V1 + V1B)

**Note:** V1B is remediation of V1, so combined LOC may exceed 200. BossCat approval implicit in directive.

---

## 📋 ECRR Events (Required)

```jsonl
{"event":"plan","job":"V1B","lane":"visual-016","timestamp":"2025-10-24T..."}
{"event":"preflight","kill_switch":"clear","git_state":"blocked","timestamp":"..."}
{"event":"lock","acquired":true,"timestamp":"..."}
{"event":"edit","files_touched":N,"loc_delta":N,"timestamp":"..."}
{"event":"test","result":"PASS|FAIL","metrics":{...},"timestamp":"..."}
{"event":"report","status":"GREEN|AMBER|RED","timestamp":"..."}
{"event":"exit","code":0,"lock_released":true,"timestamp":"..."}
```

---

**Status:** Plan complete, ready to implement active guard remediation.  
**Next:** Implement internal timer loop and optimized luma measurement.
# Gate #016 — Job V2 Execution Plan
## Frame-Timing Stabilizer & Jitter Budget

**Lane:** `lane/visual-016`  
**Job:** V2 (Frame-Timing Stabilizer)  
**Lock:** Acquired 2025-10-24  
**Executor:** Cursor{Implementer} (Writer A)  
**Monitor:** IONA-CATS-DOCS-BETA (Reader B)  
**Parent:** Job V1B (Active Guard Remediation)

---

## 🎯 Goal (≤150 words)

Stabilize the visual guard sampler so the frame cadence holds target 100 ms intervals with ≤8 ms jitter while keeping the guard from thrashing. Introduce a `FrameTimingStabilizer` that records tick start times, caps in-flight samples, and enforces a pin budget (≤1/60s). Surface stabilizer stats via `/pm/metrics` and `/guard/stats` for BossCat validation. Guard resets must clear stabilizer state. Update validation tooling to ensure jitter and pin metrics remain within budget without regressing the ≥9 Hz cadence or blackout guarantees established in Job V1B. Budget: ≤200 LOC, ≤6 files, 1 job. ECRR discipline maintained.

---

## 🛠️ Components

### 1. Frame Timing Stabilizer (server.js + new module)
- Instantiate `FrameTimingStabilizer` with target interval, jitter budget, pin window.
- Record tick starts inside guard timer, register pins when jitter exceeds budget or queue saturated.
- Track active sample count and expose stats (avg, p95, max jitter, pin count).
- Snapshot stabilizer metrics in cached guard state and APIs.

### 2. Guard Reset Integration
- Reset stabilizer alongside brightness guard.
- Ensure cached state reflects reset (tick duration zeroed, pin count cleared).

### 3. Validation Script (scripts/test-visual-guard-v2.ps1)
- Warm-up, fetch metrics, assert:
  - `stabilizer.jitterMaxMs ≤ 8`
  - `stabilizer.stabilizerPinCount ≤ 1`
  - Cadence ≥ 9 Hz, sufficient sample size.
- Emit JSONL evidence summarizing jitter + pin metrics.

---

## 🔄 Rollback Plan

If jitter budget fails: revert stabilizer integration, restore V1B timer loop from commit `640268256`, rerun validation, report failure (status 🔴 BLOCKED) with metrics snapshot.

---
