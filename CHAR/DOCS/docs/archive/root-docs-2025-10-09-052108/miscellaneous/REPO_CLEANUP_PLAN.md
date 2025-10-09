# 🧹 Repository Cleanup Plan

**Issue:** Large file `archive/SignalSetup.exe` (239MB) in Git history blocks push  
**Solution:** Remove from history using BFG Repo-Cleaner or git filter-repo

---

## Option A: BFG Repo-Cleaner (Recommended - Fast & Safe)

### 1. Install BFG

```powershell
# Option 1: Using Chocolatey
choco install bfg-repo-cleaner

# Option 2: Download manually
# Visit: https://rtyley.github.io/bfg-repo-cleaner/
# Download bfg-X.X.X.jar
```

### 2. Create Fresh Clone (Safety Backup)

```powershell
cd C:\
git clone --mirror https://github.com/fubumaki/otel-ops-pack.git otel-backup.git
```

### 3. Remove Large Files

```powershell
cd c:\otel

# Remove all files larger than 100MB from history
java -jar bfg.jar --strip-blobs-bigger-than 100M .

# Or specifically remove SignalSetup.exe
java -jar bfg.jar --delete-files SignalSetup.exe .
```

### 4. Clean Up and Push

```powershell
# Clean up Git refs
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (WARNING: rewrites history)
git push origin --force --all
```

---

## Option B: Git Filter-Repo (Modern Alternative)

### 1. Install git-filter-repo

```powershell
# Install Python first (if not installed)
# Then install git-filter-repo
pip install git-filter-repo
```

### 2. Remove Large File from History

```powershell
cd c:\otel

# Remove specific file path
git filter-repo --path archive/SignalSetup.exe --invert-paths

# Force push
git push origin --force --all
```

---

## Option C: Quick Manual Fix (For This Branch Only)

If you just want to push THIS branch without full history cleanup:

```powershell
cd c:\otel

# Create a new clean branch from current commit
git checkout --orphan roadmap-automation-clean
git add -A
git commit -m "feat: ECRR roadmap automation system

Self-updating roadmap based on CI test results.

## Components
- roadmap.json: Schema with 17 features across 4 milestones
- scripts/roadmap/*: ECRR phases (examine/clean/report/orchestrator)
- templates/roadmap-update.yml: GitHub Actions workflow
- docs/ROADMAP*.md: Generated documentation

## ECRR Gate
- **Examine**: System tested locally, all phases working
- **Clean**: Artifacts and docs generated correctly
- **Report**: Documentation complete
- **Role**: Cursor Agent (Observability Copilot)

Status: Production-ready"

# Push new clean branch
git push --set-upstream origin roadmap-automation-clean
```

This creates a branch with NO history (no large files), just your current files.

---

## ⚠️ Important Notes

**Before force-pushing:**
1. ✅ Backup your repo: `git clone --mirror` to safe location
2. ✅ Coordinate with team (force push rewrites history)
3. ✅ All team members must re-clone after force push

**After force-push, team members must:**
```powershell
# Discard local branches
git fetch origin
git reset --hard origin/main
```

---

## 🎯 Recommended Approach

For your situation, I recommend **Option C** (orphan branch):
- ✅ No history rewriting needed
- ✅ Clean slate for roadmap automation
- ✅ No risk to main branch
- ✅ Can be merged via PR as usual

**Steps:**

```powershell
# 1. Create clean orphan branch
git checkout --orphan roadmap-automation-clean

# 2. Stage all current files
git add -A

# 3. Commit (creates new history starting here)
git commit -m "feat: ECRR roadmap automation system"

# 4. Push
git push --set-upstream origin roadmap-automation-clean

# 5. Create PR on GitHub as usual
# 6. After merge, delete old branches with large files
```

---

## 📋 Verification

After cleanup, verify large files are gone:

```powershell
# Check history size
git rev-list --objects --all | 
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  Where-Object { $_ -match '^blob' } |
  ForEach-Object { 
    $parts = $_ -split '\s+'
    [PSCustomObject]@{
      Size = [int]$parts[2]
      SHA = $parts[1]
      Path = $parts[3..($parts.Length-1)] -join ' '
    }
  } |
  Where-Object { $_.Size -gt 100MB } |
  Sort-Object Size -Descending
```

If this returns nothing, you're clean!

---

**Status:** Ready to execute  
**Recommendation:** Option C (orphan branch) for safety and simplicity

