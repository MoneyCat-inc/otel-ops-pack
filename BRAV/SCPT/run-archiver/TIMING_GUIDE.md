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

---

## 🧪 **TESTING SEQUENCE**

### Test 1: Self-Test (Concurrency Proof) — 5 seconds

**Purpose**: Prove 48 workers run in parallel (no GitHub API)

```powershell
$env:CONVEYOR_SELFTEST = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1
```

**Expected Output**:
```
🧪 BossCat Conveyor — Self-Test Mode (Concurrency Proof)
Workers: 48 | Tasks: 240 × 1000ms
Expected wall time: ~5000ms

✅ Elapsed: 5012ms | Ideal: 5000ms | Efficiency: 99.8%
Max inflight observed: 48
🎉 PASS: Concurrency working as expected!
```

**Pass Criteria**:
- ✅ Efficiency ≥ 80%
- ✅ Max inflight ≈ 48
- ✅ Elapsed ≈ 5 seconds

---

### Test 2: Dry Run with Live Telemetry — ~20 minutes

**Purpose**: Watch concurrency in action (no deletions)

```powershell
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ChunkOffset 0 -DryRun
```

**Live Output** (updates every 2s):
```
🔵 arch: inflight=45/48 queued=120 qps=2.34 | 🔴 del: 234 done | ⛔429=0 5xx=2
```

**Watch For**:
- `inflight` stays 40-48 (good parallelism)
- `qps` close to 2.5 (hitting target)
- `429` count low (< 10 per 1000 runs)

---

### Test 3: Real Chunk with Full Telemetry — ~40 minutes

**Purpose**: Archive + delete with complete metrics

```powershell
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 `
  -ChunkOffset 1000 `
  -DryRun:$false `
  -MetricsTag "chunk-1"
```

**Final Output**:
```
⏱️  TIMING SUMMARY — conveyor:chunk[1001..2000]
inventory:  00:01:47
archive:    00:18:12  (p50=842ms, p95=1916ms, QPS=0.91 of target 2.50 → K=2.73)
delete:     00:16:41  (p50=1020ms, p95=1214ms, QPS=0.99 of target 1.00 → K=1.01)
total:      00:36:44  (pred=00:36:40)

📏 ETA calibration hint → archiveQPS *= 0.37, deleteQPS *= 0.99

📊 Metrics: CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl
```

---

## 📊 **UNDERSTANDING THE OUTPUT**

### Timing Summary Breakdown:

```
archive: 00:18:12 (p50=842ms, p95=1916ms, QPS=0.91 of target 2.50 → K=2.73)
         ^^^^^^^^  ^^^^^^^^^^  ^^^^^^^^^^^  ^^^^^^^^^^^^^^^^^^^^^^  ^^^^^^^^^^
         Duration  Median      95th %ile    Effective vs Target     Calibration
                   latency     latency      throughput              Factor
```

### What Each Metric Means:

- **Duration**: Total wall-clock time for this phase
- **p50 (median)**: Half of operations completed faster than this
- **p95**: 95% of operations completed faster than this (outlier detector)
- **QPS**: Actual queries/deletions per second achieved
- **K-factor**: Actual time / Predicted time (calibration multiplier)

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
archive: 00:20:00 (p50=800ms, p95=1800ms, QPS=2.5 → K=1.0)
```
- K ≈ 1.0 (on target)
- p95 < 2× p50 (consistent latencies)
- inflightMax ≈ 48 (full parallelism)

### Rate-Limited Run ⚠️
```
archive: 00:35:00 (p50=850ms, p95=3500ms, QPS=1.4 → K=1.75)
http: r429=15, backoffMs=180000 (3 minutes)
```
- K > 1.5 (slower than expected)
- High p95 (throttling delays)
- 429 count > 10 (hitting rate limits)

**Fix**: Lower `-ArchQps` to 2.0 or 1.5

### Bottlenecked Run ❌
```
archive: 00:45:00 (p50=900ms, p95=2000ms, QPS=0.6 → K=4.2)
stats: inflightMax=12/48
```
- K >> 2.0 (way off target)
- inflightMax << 48 (not using all workers)
- QPS way below target

**Possible causes**:
1. Network latency
2. System resource constraints
3. Hidden bottleneck in code

---

## 🚀 **RECOMMENDED WORKFLOW**

### Session 1: Calibration Run

```powershell
# Run one chunk with telemetry
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 `
  -ChunkOffset 1000 `
  -DryRun:$false `
  -MetricsTag "calibration"
```

**Review** the timing summary and K-factors

---

### Session 2: Tune & Execute

```powershell
# Use K-factor hints to adjust QPS
# Example: If K_archive = 2.0, use ArchQps = 2.5 * 0.5 = 1.25

for ($i = 2000; $i -lt 15000; $i += 1000) {
  pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 `
    -ChunkOffset $i `
    -ArchQps 1.25 `
    -DryRun:$false `
    -MetricsTag "chunk-$i"
    
  Start-Sleep -Seconds 300  # 5-min cooldown
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

**Authority**: cursor{implementer}  
**Status**: ✅ **PRECISION TIMING DEPLOYED**

🎉 **K-FACTORS · P50/P95 LATENCIES · AUTO-TUNING HINTS · EVIDENCE-BASED** 🎉

