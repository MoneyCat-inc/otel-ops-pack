# 🎯 Batch Execution Guide — Interactive Wait Controls

## ✨ New Features

### **Interactive Countdown Timer**
Between each chunk, the system shows:
- **Visual progress bar** with time remaining
- **Real-time countdown** (MM:SS format)
- **Keyboard controls** for operator interaction

### **Operator Controls**
During any wait period:
- Press **`S`** → Skip wait immediately, continue to next chunk
- Press **`Q`** → Quit/Halt entire batch operation gracefully
- Do nothing → Auto-proceeds when countdown reaches 0

---

## 🚀 Quick Start

### **Process Remaining 6 Chunks with Interactive Controls**

```powershell
cd c:\otel

# Execute batch with interactive wait (default: 180s between chunks)
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 6
```

### **Faster Iteration (30-second cooldown)**

```powershell
# Shorter cooldown for rapid execution
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 6 -CooldownSeconds 30
```

### **Dry Run Test**

```powershell
# Test the interactive controls without real deletions
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 2 -DryRun -CooldownSeconds 10
```

---

## 📋 Full Parameter Reference

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-ChunkCount` | 6 | Number of chunks to process |
| `-StartOffset` | 0 | Starting chunk offset |
| `-ChunkSize` | 1000 | Runs per chunk |
| `-ArchQps` | 12.0 | Archive requests/sec |
| `-DeleteQps` | 1.0 | Delete requests/sec |
| `-CooldownSeconds` | 60 | Wait time between chunks |
| `-DryRun` | false | If true, no deletions |
| `-BackfillIndex` | false | Rebuild INDEX.jsonl after completion |

---

## 🎮 Interactive Wait Display

```
⏱️  Cooldown period between chunks
   [S] Skip wait  |  [Q] Quit/Halt  |  Auto-continue in...

   ████████████████████████░░░░░░░░░░░░░░░░  02:35
```

**During wait:**
- Progress bar fills left-to-right
- Countdown updates every second
- Press `S` or `Q` anytime to control flow

---

## 🔄 Typical Workflow

### **Example: Process 6 chunks to reach 100-run target**

```powershell
# Start batch execution
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 6

# Chunk 1 runs... (24 minutes)
# ✅ Chunk 1 complete!

# Interactive wait appears:
# ⏱️  Cooldown before Chunk 2
#    [S] Skip wait  |  [Q] Quit/Halt  |  Auto-continue in...
#    ████████████░░░░░░░░░░░░░░░░░░░░░░  02:45

# Options:
# 1. Wait 3 minutes (do nothing) → Auto-continue
# 2. Press 'S' → Skip to Chunk 2 immediately
# 3. Press 'Q' → Stop after Chunk 1, clean exit

# Chunk 2 runs... (24 minutes)
# ... repeats for all 6 chunks
```

---

## 🛑 Graceful Halt

If you press **`Q`** during a wait:

```
🛑 HALTED by operator - stopping execution...

════════════════════════════════════════════════════════
📊 BATCH SUMMARY (HALTED)
════════════════════════════════════════════════════════
Completed: 3 chunks
Failed:    0 chunks
Halted at: Chunk 4 of 6
════════════════════════════════════════════════════════
```

**All completed work is preserved:**
- Checkpoints saved
- Evidence recorded in LEDGER.jsonl
- Metrics logged to METRICS.jsonl

**Resume later by adjusting `-StartOffset`:**
```powershell
# If halted at Chunk 4, resume from offset 3000
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -StartOffset 3000 -ChunkCount 3
```

---

## ⏭️ Skip Wait

If you press **`S`** during a wait:

```
✅ Skipped by operator - continuing immediately...

⏭️  Cooldown skipped - proceeding to next chunk

╔════════════════════════════════════════════════════════╗
║  📦 CHUNK 5 of 6 (offset 4000)
╚════════════════════════════════════════════════════════╝
```

**Use when:**
- System is healthy and doesn't need cooldown
- You're monitoring and want to accelerate
- Testing/debugging workflow

---

## 📊 Final Summary

After all chunks complete (or if halted):

```
════════════════════════════════════════════════════════
📊 BATCH EXECUTION COMPLETE
════════════════════════════════════════════════════════
Completed: 6 / 6 chunks
Failed:    0 chunks
════════════════════════════════════════════════════════
```

**Exit codes:**
- `0` = Success (all chunks completed or graceful halt)
- `1` = Failure (one or more chunks failed)

---

## 🎯 Recommended Usage for Current Cleanup

You have **~5,000 runs remaining** (5 chunks).

### **Option A: Automated with Cooldown + Index (Recommended)**
```powershell
# Complete cleanup with automatic index rebuild at the end
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 5 -BackfillIndex

# Timeline: ~2h 5m (including cooldowns) + index backfill (~1 min)
# You can press 'S' to skip any cooldown if system is healthy
# INDEX.jsonl will be regenerated after all chunks complete
```

### **Option B: Rapid Execution**
```powershell
# Shorter cooldown for faster completion
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 5 -CooldownSeconds 30 -BackfillIndex

# Timeline: ~2h 2m (3 min saved) + index backfill
```

### **Option C: Manual Control**
```powershell
# 10-second cooldown, skip manually when ready
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 5 -CooldownSeconds 10

# Timeline: As fast as you want (press 'S' each time)
# Manually backfill index after: pwsh BRAV/SCPT/run-archiver/generate-index.ps1
```

---

## 🐾 BossCat Approved UX

**Key Improvements:**
- ✅ Visible progress during wait periods
- ✅ Operator control (skip/halt) at any time
- ✅ Graceful shutdown preserves all work
- ✅ Clear visual feedback with progress bars
- ✅ Resume-safe with checkpoint system

**No more blind waits!** 🎉

---

## 📝 Testing the Interactive Wait

Quick test to see the controls:

```powershell
# 30-second test with visual countdown
pwsh BRAV/SCPT/run-archiver/Wait-WithControl.ps1 -Seconds 30 -Message "Test countdown"

# Try pressing 'S' or 'Q' during the countdown
```

---

**Ready to execute?** Run the batch script from your terminal! 🚀

---

## 📊 **Index Backfill Feature**

### **What It Does**

The `-BackfillIndex` flag automatically regenerates `docs/BossCat/run-reports/INDEX.jsonl` after all chunks complete successfully.

**Index contains:**
- Run ID, workflow name, conclusion
- Duration, date, actor
- Relative path to archived report

**Use it for:**
- Workflow health dashboards
- Duration analysis and trends
- Failure rate tracking
- Performance regression detection

### **How It Works**

1. All chunks complete successfully
2. Script automatically calls `generate-index.ps1`
3. Scans all `*.md` files in `docs/BossCat/run-reports/archived/`
4. Rebuilds `INDEX.jsonl` with complete metadata
5. Displays summary: "Scanned X reports, wrote INDEX.jsonl"

### **Manual Backfill**

If you don't use `-BackfillIndex`, run it manually anytime:

```powershell
pwsh BRAV/SCPT/run-archiver/generate-index.ps1
```

### **Query Examples**

See `BRAV/SCPT/run-archiver/INDEX_GUIDE.md` for:
- PowerShell query examples
- Dashboard templates
- CSV export for Excel/Tableau
- Grafana/Prometheus integration

**Quick query:**
```powershell
# Top 10 failed workflows
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Where-Object {$_.conclusion -eq 'failure'} | 
  Group-Object workflow | 
  Sort-Object Count -Descending | 
  Select-Object -First 10
```

---

**Ready to execute?** Run the batch script from your terminal! 🚀

