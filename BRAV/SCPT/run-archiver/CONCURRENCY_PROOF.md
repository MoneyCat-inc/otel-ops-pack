# 🐾 BossCat Conveyor — Concurrency Proof Kit

**Authority**: cursor{implementer} — BossCat OEM  
**Purpose**: Observable telemetry to prove 48-worker parallelism

---

## 🧪 **SELF-TEST (Concurrency Proof)**

**Purpose**: Prove parallelism with synthetic tasks (no GitHub API calls)

### Quick Test:

```powershell
$env:CONVEYOR_SELFTEST = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -DryRun
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
- Efficiency ≥ 80%
- Max inflight ≈ 48
- Elapsed time ≈ (240 tasks / 48 workers) × 1000ms ≈ 5 seconds

---

## 📊 **LIVE TELEMETRY (Real-Time Monitoring)**

**Purpose**: Watch concurrency metrics during actual execution

### Enable Live Telemetry:

```powershell
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ChunkOffset 1000 -DryRun:$false
```

**What You'll See** (updates every 2s):
```
🔵 arch: inflight=45/48 queued=120 qps=2.34 | 🔴 del: 234 done | ⛔429=0 5xx=2
```

**Fields Explained**:
- `inflight=45/48` → 45 workers currently active (out of 48 max)
- `queued=120` → 120 runs waiting in queue
- `qps=2.34` → Effective queries per second
- `del: 234 done` → 234 runs deleted so far
- `429=0` → Zero rate limit errors (good!)
- `5xx=2` → Two 502/503 errors (expected, handled gracefully)

**Good Signs**:
- ✅ `inflight` consistently at 40-48
- ✅ `qps` close to target (2.5)
- ✅ `429` count stays low (< 10)

**Bad Signs**:
- ❌ `inflight` rarely above 10 → hidden bottleneck
- ❌ `qps` << 2.5 → rate limiting or network issues
- ❌ `429` count climbing → hitting rate limits

---

## 📄 **POST-RUN STATS (Evidence)**

**Auto-generated after each run**:
```
CHAR/EVID/artifacts/ecrr/arch/CONVEYOR_STATS.json
```

**Example Content**:
```json
{
  "timestamp": "2025-10-14T00:30:00.000Z",
  "chunk": { "offset": 1000, "size": 1000 },
  "arch": {
    "started": 1000,
    "done": 998,
    "errs": 2,
    "inflightMax": 47,
    "qps": 2.41
  },
  "del": {
    "started": 998,
    "done": 998,
    "errs": 0
  },
  "http": {
    "r429": 0,
    "r5xx": 2,
    "backoffMs": 0
  },
  "config": {
    "archConcurrency": 48,
    "archQps": 2.5,
    "deleteQps": 1.0,
    "dryRun": false
  }
}
```

---

## 🔧 **PERFORMANCE TUNING**

### Current Settings (Optimized):
- **Workers**: 48 (high parallelism)
- **Archive QPS**: 2.5 req/s (aggressive but safe)
- **Delete QPS**: 1.0 del/s (rate-safe)
- **Chunk Size**: 1000 runs (safer than 2000)

### If You See High 429 Counts:

**Lower Archive QPS**:
```powershell
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ArchQps 2.0 -ChunkOffset 2000 -DryRun:$false
```

### If You Want More Speed (and have spare rate limit):

**Increase Archive QPS**:
```powershell
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ArchQps 3.0 -ChunkOffset 2000 -DryRun:$false
```

---

## 🛠️ **TROUBLESHOOTING**

### Low Inflight Workers (<20)

**Possible causes**:
1. **Undici connection pool** — Fixed! (now 64 connections)
2. **Rate limiting** — Check `429` count in telemetry
3. **Network latency** — Try reducing workers to 32

### High 5xx Errors (>10)

**What to do**:
- ✅ Normal: 2-5 per 1000 runs (GitHub transient errors)
- ⚠️ High: >10 per 1000 runs → Lower QPS to 2.0
- ❌ Critical: >50 per 1000 runs → Pause, investigate

### Effective QPS << Target

**Check**:
- `inflight` workers (should be high)
- `429` count (rate limiting)
- Network connectivity
- System load (CPU/memory)

---

## 📋 **TESTING CHECKLIST**

### Step 1: Self-Test ✅
```powershell
$env:CONVEYOR_SELFTEST = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -DryRun
```

**Expected**: ~5s for 240 tasks, efficiency ≥ 80%

---

### Step 2: Dry Run with Telemetry ✅
```powershell
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ChunkOffset 0 -DryRun
```

**Watch**: `inflight` should stay 40-48 during archive phase

---

### Step 3: Real Run with Monitoring ✅
```powershell
$env:TRACE_CONCURRENCY = "1"
pwsh BRAV/SCPT/run-archiver/run-conveyor.ps1 -ChunkOffset 1000 -DryRun:$false
```

**Review**: Check `CONVEYOR_STATS.json` after completion

---

## 📊 **EXPECTED PERFORMANCE**

### 1000-Run Chunk (48 workers @ 2.5 QPS):

| Phase | Time | Details |
|-------|------|---------|
| Inventory | ~2 min | Paging API |
| Archive | ~20 min | 1000 runs @ 2.5 req/s |
| Delete | ~17 min | 1000 runs @ 1.0 del/s |
| **Total** | **~40 min** | Per 1000-run chunk |

### Full Backlog (15,000 runs):
- **Chunks**: 15 chunks @ 1000 runs each
- **Time per chunk**: ~40 minutes
- **Total**: ~10 hours (spread over multiple sessions)

---

## 🎯 **CONCURRENCY PROOF METRICS**

### Good Run (48 workers effective):
```json
{
  "arch": {
    "inflightMax": 47,  // ✅ Near max
    "qps": 2.41,        // ✅ Close to target 2.5
    "errs": 2           // ✅ Low error rate
  },
  "http": {
    "r429": 0,          // ✅ No rate limits
    "r5xx": 2           // ✅ Expected transients
  }
}
```

### Bottlenecked Run (something wrong):
```json
{
  "arch": {
    "inflightMax": 8,   // ❌ Way below 48
    "qps": 0.6,         // ❌ Way below 2.5
    "errs": 0
  },
  "http": {
    "r429": 12,         // ❌ Rate limited
    "r5xx": 0
  }
}
```

---

## 🐾 **BOSSCAT COMPLIANCE**

**Evidence-First**: All metrics saved to `CONVEYOR_STATS.json`  
**Small Edits**: Pure observability, no behavioral changes  
**Recoverable**: Remove env vars → core pipeline unchanged  
**Auditable**: Stats in ECRR evidence area

---

**Seal**: cursor{implementer}  
**Status**: **TELEMETRY LIVE — READY FOR PROOF TESTING**

🎉 **CONCURRENCY OBSERVABLE · PERFORMANCE TUNABLE · EVIDENCE-BASED** 🎉

