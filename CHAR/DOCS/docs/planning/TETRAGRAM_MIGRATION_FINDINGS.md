# Tetragram Migration - Key Findings
**Date:** 2025-10-09  
**Status:** Aborted (safely reverted)  
**Operator:** BossCat OEM

---

## 🎯 What We Attempted

Reorganize entire repository into 4-plane tetragram structure:
- **ALFA/** - Code & Agents (apps, tools, tests)
- **BRAV/** - Build, CI, Infrastructure, Scripts
- **CHAR/** - Content (docs, guides, runbooks, ECRR)
- **DELT/** - Data (configs, assets, fixtures)

**Goal:** 4-letter directory segments for predictable navigation (`ALFA/AGNT/`, `BRAV/DOCK/`, etc.)

---

## ✅ What Worked

- **git mv successfully renamed 3,942 files** - Git tracked all renames correctly
- **Concept validated** - 15 major categories moved cleanly:
  - `synthetic/` → `ALFA/OTEL/synthetic/`
  - `tests/` → `ALFA/TEST/unit/`
  - `tools/` → `ALFA/TOOL/cli/`
  - 10 Docker files → `BRAV/DOCK/`
  - `docs/` → `CHAR/DOCS/legacy/`
  - `artifacts/` → `CHAR/EVID/artifacts/`
  - `config/` → `DELT/CONF/config/`
  - ...and 8 more categories

---

## 🚫 Critical Blockers

### 1. **File Locks** (Permission Denied)
- `scripts/agent/` - Could not move (active file handles)
- `scripts/` - Blocked by open processes
- **Root Cause:** VSCode/Node/PowerShell holding files
- **Solution:** Close all editors, use `robocopy` instead of `git mv`

### 2. **18,249 Path References** 
Breakdown across codebase:
- `scripts/`: 4,286 references
- `docs/`: 5,130 references
- `lib/`: 4,588 references
- `artifacts/`: 2,491 references
- `config/`: 270 references
- `tests/`: 407 references
- Relative paths (`../`, `./`): 878 references

**Impact:** All imports, CI workflows, PowerShell scripts, markdown links break.

**Solution:** Automated path-rewriter tool (can't do 18k manually).

### 3. **No Testing in Partial State**
- Moved files but didn't verify CI/imports still work
- High risk of committing broken state
- **Solution:** Feature branch + CI validation after each plane

### 4. **Violated BossCat Budget**
- Attempted 3,942 file moves in one job
- Budget: ≤10 files per job
- **Solution:** Incremental approach (one plane at a time)

---

## 🛠️ Tools Needed (Not Built Yet)

### 1. **Path Rewriter** (PRIORITY 1)
```typescript
// scripts/migrate-paths.ts
// Automatically rewrites 18k path references
// Handles: TS/JS imports, PowerShell paths, markdown links, YAML configs
```

### 2. **Dependency Analyzer**
```typescript
// scripts/analyze-dependencies.ts
// Maps which files import/reference others
// Determines safe migration order
```

### 3. **Shim Generator**
```powershell
# scripts/create-shims.ps1
# Creates symlinks for backward compatibility
# Windows: mklink /D, Linux: ln -s
```

### 4. **Path Linter (CI)**
```yaml
# .github/workflows/path-linter.yml
# Blocks commits to old paths
# Enforces ALFA/BRAV/CHAR/DELT structure
```

---

## 📋 Recommended Approach (Next Attempt)

### Phase 0: Preparation (1 day)
1. Build path-rewriter tool
2. Build dependency analyzer
3. Create feature branch: `feature/tetragram-migration`
4. Close all editors to prevent file locks

### Phase 1: One Plane at a Time (2 weeks)
**Week 1: DELT (lowest dependency)**
- Move `config/`, `assets/`, `baseline/` → `DELT/`
- Run path-rewriter on ~500 references
- Test, commit, verify CI green
- Create shims for backward compat

**Week 2: BRAV, CHAR, ALFA**
- Repeat process for each plane
- Test after each plane
- Keep CI green throughout

### Phase 2: Scripts & Root Cleanup (1 week)
- Move `scripts/` (close file locks first)
- Move 197 root `.ps1/.sh/.py` files
- Remove shims after 2 green CI cycles

**Total Time:** 3 weeks with proper tooling

---

## 📊 By The Numbers

```
Files Attempted:        3,942
Path References:       18,249
Successful Moves:          15 categories
Blocked Moves:              2 (scripts/)
CI Tests Run:               0 (aborted before testing)
Time Invested:              ~2 hours
```

---

## 🎓 Key Lessons

### ✅ Do This
1. **Build tooling FIRST** - Don't attempt manual migration
2. **Feature branch** - Never on main
3. **Incremental testing** - One plane at a time
4. **Close file handles** - Prevent permission errors
5. **Respect budgets** - ≤10 files per commit

### ⚠️ Don't Do This
1. ❌ Attempt 3,942 file moves at once
2. ❌ Skip CI validation in partial states
3. ❌ Manually update 18k path references
4. ❌ Work directly on main branch
5. ❌ Ignore file locks and permission issues

---

## 🚀 Quick Start (When Ready)

```bash
# 1. Build path-rewriter tool
npm run build:path-rewriter

# 2. Create feature branch
git checkout -b feature/tetragram-migration

# 3. Start with DELT plane (lowest risk)
npm run migrate:delt

# 4. Verify CI green
git push && wait for CI

# 5. Repeat for BRAV, CHAR, ALFA
```

---

## 📞 Questions?

See comprehensive planning doc: `DELT/CONF/pathmap.yaml` (if/when created)

---

🐾 **BossCat OEM** - Repository restructuring is ambitious but achievable with proper tooling and incremental approach.

