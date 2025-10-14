# 🐾 BossCat Run Archiver — PowerShell Edition

**Authority**: BossCat OEM  
**Purpose**: Archive & prune GitHub Actions workflow runs  
**Status**: ✅ PRODUCTION-READY

---

## 🎯 Quick Start

### Step 1: Preflight (Generate KeepSet/TrimSet)

```powershell
pwsh BRAV/SCPT/run-archiver/preflight.ps1
```

**Outputs**:
- `.agent/tmp/KEEPSET.txt` — Newest 100 run IDs
- `.agent/tmp/TRIMSET.txt` — Older completed run IDs to archive
- `.agent/tmp/preflight-summary.json` — Stats

---

### Step 2: Dry Run (Archive Only)

```powershell
pwsh BRAV/SCPT/run-archiver/execute-backfill.ps1 -DryRun
```

**What it does**:
- Archives all TrimSet runs (logs + artifacts + manifest)
- Generates badges and TL;DR
- Appends evidence JSONL
- **Does NOT delete** runs

---

### Step 3: Execute (Archive + Delete)

```powershell
pwsh BRAV/SCPT/run-archiver/execute-backfill.ps1 -DeleteAfterArchive -DryRun:$false
```

**What it does**:
- Archives all TrimSet runs
- **Deletes** runs from Actions UI (1/sec)
- Reduces count to ~100

---

## 📋 Script Reference

### preflight.ps1

**Purpose**: Generate KeepSet and TrimSet

**Parameters**:
- `-Repo` — Repository (default: MoneyCat-inc/otel-ops-pack)
- `-Keep` — How many newest to keep (default: 100)

**Outputs**:
- `.agent/tmp/KEEPSET.txt`
- `.agent/tmp/TRIMSET.txt`
- `.agent/tmp/preflight-summary.json`

---

### backfill.ps1

**Purpose**: Archive/delete runs for ONE shard

**Parameters**:
- `-Repo` — Repository
- `-Shard` — Shard index (0-7)
- `-Shards` — Total shards (default: 8)
- `-MaxParallel` — Concurrent downloads (default: 4)
- `-DeleteAfterArchive` — Delete after archiving (default: false)
- `-DryRun` — Archive only, no deletes (default: true)

**Outputs**:
- `CHAR/EVID/artifacts/ecrr/arch/YYYY/MM/run-<id>/`
  * manifest.json
  * logs.zip (with SHA256)
  * artifact-*.zip (with SHA256)
  * badge.svg
  * TLDR.md
- `CHAR/EVID/artifacts/ecrr/arch/EVIDENCE.jsonl` (append)

---

### execute-backfill.ps1

**Purpose**: Execute ALL shards sequentially

**Parameters**:
- `-Repo` — Repository
- `-Shards` — Total shards (default: 8)
- `-MaxParallel` — Per-shard concurrency (default: 4)
- `-DeleteAfterArchive` — Delete after archiving
- `-DryRun` — Archive only

**Behavior**:
- Runs shards 0 through (Shards-1) sequentially
- Waits for each shard to complete
- Reports final count

---

## 🔧 Configuration

### Shard Count

**Recommended**:
- **4 shards**: Safer, more conservative
- **8 shards**: Balanced (default)
- **16 shards**: Faster (for large inventories)

**Note**: Each shard processes `TrimSet.Count / Shards` runs

### MaxParallel

**Recommended**:
- **2**: Very conservative (slower)
- **4**: Balanced (default)
- **8**: Aggressive (watch rate limits)

**Note**: Parallel downloads within each shard

---

## 📊 Evidence Structure

```
CHAR/EVID/artifacts/ecrr/arch/
├── 2025/
│   ├── 10/
│   │   ├── run-18400000000/
│   │   │   ├── manifest.json
│   │   │   ├── logs.zip
│   │   │   ├── artifact-123.zip
│   │   │   ├── badge.svg
│   │   │   └── TLDR.md
│   │   ├── run-18400000001/
│   │   │   └── ...
│   └── ...
└── EVIDENCE.jsonl (append-only ledger)

docs/BossCat/run-reports/
├── archived/
│   └── 2025/
│       ├── 09/
│       │   └── run-*.md (1,191 reports)
│       └── 10/
│           └── run-*.md (7,327 reports)
├── badges/
│   └── run-*.svg (8,518 badges)
└── INDEX.jsonl (queryable index)
```

---

## 🔍 **Queryable Index**

### **Auto-Generated During Archive**

Each archived run appends a JSONL record to `docs/BossCat/run-reports/INDEX.jsonl`:

```json
{"id":"18485761625","workflow":"JFrog SAST Scan","conclusion":"cancelled","duration":62,"date":"2025-10-14","actor":"fubumaki","path":"2025/10/run-18485761625.md"}
```

### **Backfill Index**

Regenerate index from all existing reports:

```powershell
pwsh BRAV/SCPT/run-archiver/generate-index.ps1
```

Or use `-BackfillIndex` flag in batch runner:

```powershell
pwsh BRAV/SCPT/run-archiver/run-batch.ps1 -ChunkCount 5 -BackfillIndex
```

### **Query Examples**

**Top 10 Failed Workflows:**
```powershell
Get-Content docs/BossCat/run-reports/INDEX.jsonl | 
  ConvertFrom-Json | 
  Where-Object {$_.conclusion -eq 'failure'} | 
  Group-Object workflow | 
  Sort-Object Count -Descending | 
  Select-Object -First 10
```

**See `INDEX_GUIDE.md` for:**
- Dashboard templates
- Duration analysis
- Failure trends
- CSV export for Excel/Tableau
- Grafana integration

---

## ⏱️ Timeline Estimates

### Dry Run (Archive Only)
- **Preflight**: ~2 minutes
- **8 Shards × ~1,800 runs each**: ~30-60 minutes total
- **Commits**: Automatic (per shard)

### Full Run (Archive + Delete)
- **Archive**: ~30-60 minutes
- **Delete**: ~4 hours (14,400 runs × 1 second)
- **Total**: ~4.5-5 hours

---

## 🛡️ Safety Features

### Kill-Switch ✅
- Checks `.agent/LOCK` before execution
- Aborts if present (ECRR doctrine)

### Bounded Retry ✅
- 3 attempts per API call
- Exponential backoff (2^n seconds)
- Logs failures, continues processing

### Rate Limiting ✅
- 1 second delay between DELETEs
- Configurable MaxParallel for GETs
- Respects GitHub secondary rate limits

### Evidence Trail ✅
- Manifest with checksums
- JSONL append-only ledger
- Badges + TL;DR per run
- Complete audit trail

---

## 📚 References

- [GitHub REST API - Workflow Runs](https://docs.github.com/en/rest/actions/workflow-runs)
- [GitHub CLI - gh run](https://cli.github.com/manual/gh_run)
- [Rate Limit Best Practices](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api)
- BossCat AGENTS.md — ECRR doctrine, budgets, lanes

---

**Authority**: BossCat OEM  
**Status**: Production-ready  
**Seal**: 🐾

