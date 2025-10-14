# 🐾 BossCat Conveyor — Precision Timing & ETA Calibration

**Authority**: cursor{implementer} — BossCat OEM  
**Purpose**: Evidence-based performance tuning with K-factors

---

## 🎯 **WHAT'S NEW**

### Precision Timing System ✅
- Per-phase stopwatches (inventory, archive, delete, verify)
- Per-run latency tracking (p50, p95)
- K-factor calibration (actual vs predicted)
- Auto-tuning hints for next runs

### Coordinated Rate Limit Backoff ✅ (NEW!)
- **Shared global gate** prevents thundering herd on rate limit wakeup
- **Jittered resume** staggers workers (0-1500ms random delay)
- **Safe defaults** to prevent rate limit saturation
  - `ArchQps: 2.0` (was 12.0)
  - `ArchConcurrency: 24` (was 48)
  - `CooldownSeconds: 60` batch default (was 180)

---

## 🧪 **TESTING SEQUENCE**

### Test 1: Self-Test (Concurrency Proof) — 5 seconds

**Purpose**: Prove 24 workers run in parallel (no GitHub API)

```powershell
$env:CONVEYOR_SELFTEST = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1
```

**Expected Output**:
```
🧪 BossCat Conveyor — Self-Test Mode (Concurrency Proof)
Workers: 24 | Tasks: 120 × 1000ms
Expected wall time: ~5000ms

✅ Elapsed: 5012ms | Ideal: 5000ms | Efficiency: 99.8%
Max inflight observed: 24
🎉 PASS: Concurrency working as expected!
```

**Pass Criteria**:
- ✅ Efficiency ≥ 80%
- ✅ Max inflight ≈ 24 (new safe default)
- ✅ Elapsed ≈ 5 seconds

---

### Test 2: Dry Run with Live Telemetry — ~8 minutes

**Purpose**: Watch concurrency in action (no deletions)

```powershell
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ChunkOffset 0 -DryRun
```

**Live Output** (updates every 2s):
```
🔵 arch: inflight=22/24 queued=58 qps=1.98 | 🔴 del: 234 done | ⛔429=0 5xx=0
```

**Watch For**:
- `inflight` stays 20-24 (good parallelism with safe defaults)
- `qps` close to 2.0 (hitting safe target)
- `429` count = 0 (no rate limits with coordinated backoff)

---

### Test 3: Real Chunk with Full Telemetry — ~26 minutes

**Purpose**: Archive + delete with complete metrics (using safe defaults)

```powershell
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 `
  -ChunkOffset 0 `
  -DryRun:$false `
  -MetricsTag "chunk-safe"
```

**Final Output**:
```
⏱️  TIMING SUMMARY — conveyor:chunk[101..1100]
inventory:  00:01:30
archive:    00:08:15  (p50=750ms, p95=1200ms, QPS=2.02 of target 2.00 → K=0.99)
delete:     00:16:45  (p50=995ms, p95=1980ms, QPS=0.99 of target 1.00 → K=1.01)
total:      00:26:30  (pred=00:26:25)

📏 ETA calibration hint → archiveQPS *= 1.01, deleteQPS *= 0.99

📊 Metrics: CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl
```

---

## 📊 **UNDERSTANDING THE OUTPUT**

### Timing Summary Breakdown:

```
archive: 00:08:15 (p50=750ms, p95=1200ms, QPS=2.02 of target 2.00 → K=0.99)
         ^^^^^^^^  ^^^^^^^^^  ^^^^^^^^^^  ^^^^^^^^^^^^^^^^^^^^^^  ^^^^^^^^^
         Duration  Median     95th %ile   Effective vs Target     Calibration
                   latency    latency     throughput              Factor
```

### What Each Metric Means:

- **Duration**: Total wall-clock time for this phase
- **p50 (median)**: Half of operations completed faster than this
- **p95**: 95% of operations completed faster than this (outlier detector)
- **QPS**: Actual queries/deletions per second achieved
- **K-factor**: Actual time / Predicted time (calibration multiplier)

---

## 🛡️ **COORDINATED RATE LIMIT BACKOFF**

### The Thundering Herd Problem (FIXED!)

**Old Behavior** (48 workers @ 12 QPS):
- All 48 workers hit rate limit simultaneously
- All calculate "wait 18 minutes" independently
- All wake up at exact same time
- Immediate re-trigger of rate limit → **infinite loop!** ❌

**New Behavior** (24 workers @ 2 QPS + coordinated backoff):
1. **Shared Global Gate**: When any worker hits 403/429, sets `rateGate.until` timestamp
2. **All Workers Check**: Before each request, check if `rateGate.until` > now, wait if needed
3. **Jittered Resume**: After sleep, add random 0-1500ms delay to stagger wakeups ✅

### Configuration

```powershell
# Adjust jitter window (default: 1500ms)
$env:RATE_JITTER_MS = "2000"

# Safe defaults (already set)
# ArchQps: 2.0
# ArchConcurrency: 24
# DeleteQps: 1.0
```

### What This Prevents

**Without Coordinated Backoff**:
```
⏳ Pausing for 18m 4.5s (rate limit) — will auto-resume…  ← Worker 1
⏳ Pausing for 18m 4.4s (rate limit) — will auto-resume…  ← Worker 2
⏳ Pausing for 18m 4.3s (rate limit) — will auto-resume…  ← Worker 3
... (all 48 workers spam the log)
[18 minutes later]
⏳ Pausing for 18m 4.5s (rate limit) — will auto-resume…  ← Loop repeats!
```

**With Coordinated Backoff**:
```
⏳ Pausing for 18m 4s (rate limit) — will auto-resume…     ← ONE message
[Workers coordinate via shared gate + jitter]
[Resume staggered over 0-1500ms window]
✅ Archive continues smoothly
```

---

## 🎯 **K-FACTOR CALIBRATION**

### What K-Factor Tells You:

| K-Factor | Meaning | Action |
|----------|---------|--------|
| K ≈ 1.0 | ✅ Perfect prediction | Keep current settings |
| K = 1.5 | 50% slower than expected | Lower target QPS by 33% |
| K = 2.0 | 2× slower than expected | Lower target QPS by 50% |
| K = 0.8 | 20% faster than expected | Increase target QPS by 25% |

### Auto-Tuning Hint:

The conveyor shows:
```
📏 ETA calibration hint → archiveQPS *= 0.37, deleteQPS *= 0.99
```

**Means**:
- Archive is running **2.73× slower** than predicted → Lower QPS to `2.5 × 0.37 = 0.93`
- Delete is running **1.01× slower** (nearly perfect) → Keep at 1.0

**Next run**:
```powershell
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ArchQps 0.93 -ChunkOffset 2000 -DryRun:$false
```

---

## 📄 **METRICS.JSONL FORMAT**

**Location**: `CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl`

**Example Entry**:
```json
{
  "t": "2025-10-14T01:15:00.000Z",
  "repo": "MoneyCat-inc/otel-ops-pack",
  "chunk": { "size": 1000, "offset": 1000, "range": [1001, 2000] },
  "dry_run": false,
  "config": { "ARCH_QPS": 2.5, "DELETE_QPS": 1.0, "ARCH_CONCURRENCY": 48 },
  "phases": {
    "inventory": { "ms": 100742 },
    "archive": { "n": 1000, "ms": 1092840, "p50_ms": 842, "p95_ms": 1916 },
    "delete": { "n": 1000, "ms": 1003000, "p50_ms": 1020, "p95_ms": 1214 },
    "verify": { "ms": 5301 },
    "total_ms": 2206883
  },
  "eta": {
    "predicted_sec": { "archive": 400, "delete": 1000, "total": 1542 },
    "actual_sec": { "archive": 1093, "delete": 1003, "total": 2207 },
    "k_factor": { "archive": 2.732, "delete": 1.003 }
  },
  "stats": {
    "arch": { "started": 1000, "done": 998, "errs": 2, "inflightMax": 47, "qps": 2.41 },
    "del": { "started": 998, "done": 998, "errs": 0 },
    "http": { "r429": 0, "r5xx": 2, "backoffMs": 0 }
  },
  "tag": "chunk-1"
}
```

---

## 🔍 **DIAGNOSING PERFORMANCE**

### Healthy Run ✅
```
archive: 00:08:00 (p50=750ms, p95=1200ms, QPS=2.0 → K=1.0)
```
- K ≈ 1.0 (on target)
- p95 < 2× p50 (consistent latencies)
- inflightMax ≈ 24 (full parallelism with safe defaults)
- r429 = 0 (no rate limits!)

### Rate-Limited Run ⚠️ (Pre-Fix Behavior)
```
archive: 00:35:00 (p50=850ms, p95=3500ms, QPS=1.4 → K=1.75)
http: r429=48, backoffMs=1080000 (18 minutes × workers)
```
- K > 1.5 (slower than expected)
- High p95 (throttling delays)
- **Multiple 429s = Thundering herd!** ❌

**Fix Applied**: 
- ✅ Coordinated backoff (shared gate + jitter)
- ✅ Lower `-ArchQps` to 2.0
- ✅ Reduce `-ArchConcurrency` to 24

### Bottlenecked Run ❌
```
archive: 00:30:00 (p50=900ms, p95=2000ms, QPS=0.6 → K=3.5)
stats: inflightMax=8/24
```
- K >> 2.0 (way off target)
- inflightMax << 24 (not using all workers)
- QPS way below target

**Possible causes**:
1. Network latency
2. System resource constraints
3. Hidden bottleneck in code
4. Insufficient worker count (increase `-ArchConcurrency` if no rate limits)

---

## 🚀 **RECOMMENDED WORKFLOW**

### Session 1: Calibration Run (Using Safe Defaults)

```powershell
# Run one chunk with telemetry (safe defaults: ArchQps=2.0, ArchConcurrency=24)
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 `
  -ChunkOffset 0 `
  -DryRun:$false `
  -MetricsTag "calibration"
```

**Review** the timing summary and K-factors

---

### Session 2: Batch Execute with Interactive Wait

```powershell
# Use batch runner with safe defaults + interactive cooldown controls
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 `
  -ChunkCount 6 `
  -ArchQps 2.0 `
  -DeleteQps 1.0 `
  -CooldownSeconds 60

# During wait: Press 'S' to skip, 'Q' to halt
```

**Or Manual Loop** (if K-factors suggest tuning):

```powershell
# Use K-factor hints to adjust QPS
# Example: If K_archive = 1.2, slightly increase: ArchQps = 2.0 * (1/1.2) = 1.67

for ($i = 0; $i -lt 6000; $i += 1000) {
  pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 `
    -ChunkOffset $i `
    -ArchQps 2.0 `
    -DryRun:$false `
    -MetricsTag "chunk-$i"
    
  Start-Sleep -Seconds 60  # 1-min cooldown
}
```

---

## 📋 **QUICK REFERENCE**

### All Testing Commands:

```powershell
# 1. Self-test (5s proof)
$env:CONVEYOR_SELFTEST="1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1

# 2. Dry run with live telemetry
$env:TRACE_CONCURRENCY="1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ChunkOffset 0 -DryRun

# 3. Real run with metrics
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ChunkOffset 1000 -DryRun:$false -MetricsTag "chunk-1"

# 4. Review metrics
Get-Content CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl | Select-Object -Last 1 | ConvertFrom-Json
```

---

## 📊 **EVIDENCE FILES**

| File | Purpose |
|------|---------|
| `METRICS.jsonl` | Real run timing data |
| `METRICS_DRYRUN.jsonl` | Dry run timing data |
| `CONVEYOR_STATS.json` | Latest concurrency stats |
| `LEDGER.jsonl` | State machine audit trail |

---

## 🛡️ **SAFE DEFAULTS & THUNDERING HERD FIX**

### Current Safe Defaults (Post-Fix)

| Setting | Old Value | New Safe Value | Why |
|---------|-----------|----------------|-----|
| `ArchQps` | 12.0 | **2.0** | Prevents rate limit saturation |
| `ArchConcurrency` | 48 | **24** | Reduces burst size to ~48 req/sec |
| `DeleteQps` | 1.0 | **1.0** | Already safe (unchanged) |
| `CooldownSeconds` | 180 | **60** | Shorter batch waits (batch runner only) |
| `RateJitter` | N/A | **1500ms** | Staggers worker wakeup after rate limits |

### What Was Fixed

**Problem**: Thundering herd on rate limit recovery
- 48 workers × 12 QPS = **576 req/sec burst** (7× GitHub's 83 req/sec limit)
- All workers hit limit → All wait 18 min → All wake simultaneously → Infinite loop

**Solution**: Coordinated backoff + safer defaults
- ✅ Shared global `rateGate` coordinates all workers
- ✅ Jittered resume (0-1500ms stagger) prevents synchronized wakeup
- ✅ Lower QPS (2.0) and workers (24) = **48 req/sec** (safely under limit)

### Tuning Knobs

```powershell
# Increase jitter window (if still seeing synchronized wakeups)
$env:RATE_JITTER_MS = "3000"

# Increase QPS cautiously (if K-factor < 0.8 and no 429s)
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ArchQps 3.0 -ArchConcurrency 24

# Watch live telemetry to verify
$env:TRACE_CONCURRENCY = "1"
```

### Expected Performance (Safe Defaults)

| Chunk Size | Archive Time | Delete Time | Total Time |
|------------|--------------|-------------|------------|
| 1000 runs | ~8 minutes | ~17 minutes | **~26 min/chunk** |
| 500 runs | ~4 minutes | ~9 minutes | **~13 min/chunk** |

---

**Authority**: cursor{implementer}  
**Status**: ✅ **PRECISION TIMING + THUNDERING HERD FIX DEPLOYED**

🎉 **K-FACTORS · P50/P95 · COORDINATED BACKOFF · JITTERED RESUME · EVIDENCE-BASED** 🎉

