<!-- markdownlint-disable MD022 MD031 MD032 MD036 -->
# GitHub Actions Workflow Cleanup Guide

> **SUPERSEDED (2026-09-02 truth pass).** Neither `scripts/archive-workflow-runs.ps1` nor
> `scripts/cleanup-old-workflow-runs.ps1` exists. The live tooling is `BRAV/SCPT/run-archiver/`
> (`run-conveyor.ps1`) driven by `.github/workflows/run-archiver.yml` (cron `19 */4 * * *`); the run
> counts below are 2025 figures.

**Authority:** BossCat OEM  
**Purpose:** Manage and archive 10,000+ workflow runs  
**Status:** ⛔ SUPERSEDED — see notice (the tools named here do not exist)

---

## 🎯 Problem

**Current State:** 10,149 workflow runs accumulated  
**Impact:** Cluttered UI, slower page loads, difficult to find recent runs  
**Solution:** Archive old runs, delete irrelevant/deprecated ones

---

## 🧹 Cleanup Strategy

### Phase 1: Archive (Preserve History)
```powershell
# Archive runs older than 90 days to CHAR/PRSV/archive/
pwsh -File scripts/archive-workflow-runs.ps1 -OlderThanDays 90
```

**Creates:**
- JSON archive with all run metadata
- Markdown summary report
- Compressed zip file

**Safe:** Read-only operation, doesn't delete anything

### Phase 2: Cleanup (Delete Old Runs)
```powershell
# DRY RUN first (recommended)
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -DryRun

# Execute cleanup
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -OlderThanDays 90
```

**Deletes:**
- All runs older than 90 days (configurable)
- Failed runs older than 30 days (configurable)

**Preserves:**
- Recent runs (last 7-30 days)
- Successful runs (audit trail)
- Tagged/release runs

---

## 📋 Recommended Cleanup Plan

### Conservative (Recommended First Time)
```powershell
# Keep 60 days, delete 180+ days
pwsh -File scripts/archive-workflow-runs.ps1 -OlderThanDays 180
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -KeepDays 60 -OlderThanDays 180
```

**Impact:** Delete ~8,000-9,000 runs (oldest 6+ months)  
**Preserve:** Last 60 days + successful runs

### Moderate (After Conservative)
```powershell
# Keep 30 days, delete 90+ days
pwsh -File scripts/archive-workflow-runs.ps1 -OlderThanDays 90
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -KeepDays 30 -OlderThanDays 90
```

**Impact:** Delete additional ~1,000-2,000 runs  
**Preserve:** Last 30 days + recent successful runs

### Aggressive (For Ongoing Maintenance)
```powershell
# Keep 14 days, delete 30+ days
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -KeepDays 14 -OlderThanDays 30
```

**Impact:** Keep repository very lean  
**Preserve:** Last 14 days only

---

## 🔧 Prerequisites

### 1. Authenticate GitHub CLI
```powershell
gh auth login
```

**Follow prompts:**
- Login method: Browser or Token
- Protocol: HTTPS
- Authenticate with: Browser

### 2. Verify Authentication
```powershell
gh auth status
```

**Expected:** "Logged in to github.com as [username]"

---

## 📊 Understanding the 10,149 Runs

### Likely Composition

**From browser inspection:**
- Multiple security scanning workflows (Fortify, JFrog, Sysdig, CodeQL, etc.)
- Canary test workflows (test(canary): correlation verification)
- ECRR compliance checks
- Gate verification workflows
- Nightly automation runs

**Many runs are expected failures:**
- Security scans finding known issues
- Gate verifications when stack wasn't ready
- Canary tests during development

### What to Keep

**Recent Runs (Last 30 Days):**
- Useful for debugging current issues
- Shows recent development activity
- Gate #006 and Phase 1/2 validation runs

**Successful Milestone Runs:**
- Runs associated with tags (gate-*, phase1-*, phase2-*)
- Release validations
- Successful ECRR compliance runs

### What to Delete

**Old Runs (90+ Days):**
- Ancient failed security scans
- Superseded canary tests
- Deprecated workflow runs

**Recent Failed Runs (30+ Days):**
- Known security scan failures
- Gate verification failures (stack issues)
- Canary tests from development phase

---

## 🚀 Step-by-Step Execution

### Step 1: Authenticate (One-Time)
```powershell
gh auth login
```

### Step 2: Archive Before Deleting (Safety)
```powershell
# Archive runs older than 90 days
pwsh -File scripts/archive-workflow-runs.ps1 -OlderThanDays 90

# Check the archive
Get-ChildItem CHAR\PRSV\archive\workflow-runs\*latest*.json
```

### Step 3: Dry Run (Preview)
```powershell
# See what would be deleted
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -DryRun

# Review output carefully
```

### Step 4: Execute Cleanup
```powershell
# Delete runs older than 90 days
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -OlderThanDays 90

# Monitor progress (shows every 50 deletions)
```

### Step 5: Verify Results
```powershell
# Check remaining runs
gh run list --limit 100 --repo MoneyCat-inc/otel-ops-pack

# Should see much fewer runs, all recent
```

---

## ⚠️ Important Notes

### Rate Limiting
**GitHub API limits:**
- 5,000 requests/hour for authenticated users
- Deleting runs is 1 request per run
- Batch deletions pause if rate limit hit

**Solution:** Script processes in batches of 1,000 with progress updates

### No Undo
**Once deleted, workflow runs cannot be recovered.**

**Mitigation:**
1. Always run archive script first
2. Use -DryRun to preview
3. Start conservative (90+ days)
4. Review archive before deleting

### What's NOT Deleted

**The cleanup script preserves:**
- ✅ Workflow files (.github/workflows/*.yml)
- ✅ Source code and commits
- ✅ Tags and releases
- ✅ Recent runs (within KeepDays)
- ✅ Archived metadata (in CHAR/PRSV/)

**Only run history UI entries are removed.**

---

## 📊 Expected Results

### Before Cleanup
- **Workflow Runs:** 10,149
- **Oldest Run:** ~6+ months ago
- **UI Performance:** Slow, cluttered
- **Find Recent Runs:** Difficult

### After Conservative Cleanup (180+ days)
- **Workflow Runs:** ~1,500-2,000
- **Oldest Run:** ~6 months ago
- **Reduction:** ~80%
- **UI Performance:** Much faster

### After Moderate Cleanup (90+ days)
- **Workflow Runs:** ~500-1,000
- **Oldest Run:** ~3 months ago
- **Reduction:** ~90%
- **UI Performance:** Fast

### After Aggressive Cleanup (30+ days)
- **Workflow Runs:** ~100-200
- **Oldest Run:** ~1 month ago
- **Reduction:** ~98%
- **UI Performance:** Very fast

---

## 🔄 Ongoing Maintenance

### Monthly Cleanup (Recommended)
```powershell
# First of each month: delete runs older than 90 days
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -OlderThanDays 90
```

### Quarterly Archive (Best Practice)
```powershell
# Every 3 months: archive then cleanup
pwsh -File scripts/archive-workflow-runs.ps1 -OlderThanDays 90
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -OlderThanDays 90
```

### Scheduled Task (Automation)
```powershell
# Create monthly cleanup task
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
    -Argument "-File C:\otel\scripts\cleanup-old-workflow-runs.ps1 -OlderThanDays 90"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 2am

Register-ScheduledTask -TaskName "BossCat-Workflow-Cleanup" `
    -Action $action -Trigger $trigger -Description "Monthly GitHub workflow run cleanup"
```

---

## 🐾 BossCat Governance

**Cleanup Policy:**
- Archive runs older than 90 days (quarterly)
- Delete archived runs after archival
- Keep last 30 days minimum
- Evidence logged to .agent/EVIDENCE.log

**Approval Required:** No (operational maintenance)  
**Evidence Required:** Yes (archive created before deletion)  
**Rollback:** Not applicable (archive preserved)

---

## 📚 References

**Scripts:**
- `scripts/archive-workflow-runs.ps1` — Archive metadata before deletion
- `scripts/cleanup-old-workflow-runs.ps1` — Delete old runs

**Documentation:**
- [GitHub CLI - gh run](https://cli.github.com/manual/gh_run)
- [GitHub Actions - Workflow runs API](https://docs.github.com/en/rest/actions/workflow-runs)

**BossCat:**
- `.agent/EVIDENCE.log` — Cleanup events logged here
- `CHAR/PRSV/archive/workflow-runs/` — Archives stored here

---

## 🎯 Quick Start

**Fastest path to clean repository:**

```powershell
# 1. Authenticate (one-time)
gh auth login

# 2. Archive (safety)
pwsh -File scripts/archive-workflow-runs.ps1 -OlderThanDays 90

# 3. Dry run (preview)
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -DryRun

# 4. Execute (delete)
pwsh -File scripts/cleanup-old-workflow-runs.ps1 -OlderThanDays 90

# 5. Verify (check results)
gh run list --limit 50 --repo MoneyCat-inc/otel-ops-pack
```

**Expected time:** 10-30 minutes (depending on run count)

---

**BossCat Approval:** Workflow cleanup utilities ready for use  
**Status:** ✅ DOCUMENTED — Execute when ready  
**Evidence:** Tools created, guide published

---

**END OF GUIDE**

