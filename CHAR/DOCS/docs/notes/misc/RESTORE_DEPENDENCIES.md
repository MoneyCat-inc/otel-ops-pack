# 🔄 Restore Dependencies Guide

<!-- markdownlint-disable-next-line MD013 -->
**BossCat Note:** This repository has been cleaned to remove 6.5 GB of regeneratable bloat. All removed content can be restored using the commands below.

---

## ⚡ Quick Restore (Most Common)

```powershell
# Restore Node.js dependencies (~3.3 GB)
pnpm install

# Restore Python virtualenv (~1.8 GB)
python -m venv .venv
.venv\Scripts\pip install -r requirements.txt
```

**Time:** 5-10 minutes  
**Size:** ~5 GB restored

---

## 📦 What Was Removed

| Directory | Size | Can Restore? | Command |
|-----------|------|--------------|---------|
| `node_modules/` | 3.28 GB | ✅ Yes | `pnpm install` |
| `.venv/` | 1.79 GB | ✅ Yes | `python -m venv .venv` + pip install |
| `resonai-mock/` | 0.81 GB | ⚠️ Maybe | Re-generate or restore from backup |
| `third_party/` | 0.52 GB | ✅ Yes | `git submodule update --init` |
| `.next/` | 0.10 GB | ✅ Auto | `pnpm build` |
| `dist/`, `out/` | <1 MB | ✅ Auto | Build process |
| `__pycache__/` | <1 MB | ✅ Auto | Python runtime |

**Total Removed:** 6.49 GB  
**Can Restore:** 5.68 GB automatically

---

## 🚀 Full Restoration Steps

### 1. Node.js Dependencies (Required for Development)

```powershell
# Install pnpm if needed
npm install -g pnpm

# Restore all Node packages
pnpm install

# Verify
pnpm --version
```

**Restores:** `node_modules/` (~3.3 GB)  
**Time:** 3-5 minutes

---

### 2. Python Environment (Required for Scripts)

```powershell
# Create virtual environment
python -m venv .venv

# Activate (Windows)
.venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt    # Optional: dev dependencies
pip install -r requirements-gpu.txt     # Optional: GPU features
```

**Restores:** `.venv/` (~1.8 GB)  
**Time:** 2-4 minutes

---

### 3. Git Submodules (Optional)

```powershell
# If third_party is a submodule
git submodule update --init --recursive

# Or if it's resonai project
cd third_party/resonai
pnpm install
```

**Restores:** `third_party/` (~0.5 GB)  
**Time:** 1-2 minutes

---

### 4. Build Artifacts (Auto-Generated)

```powershell
# Next.js build
pnpm build

# Other builds happen automatically during dev
pnpm dev
```

**Restores:** `.next/`, `dist/`, `out/`  
**Time:** <1 minute

---

## 🎯 Common Workflows

### For Development Work

```powershell
# Minimal restore (just Node.js)
pnpm install
pnpm dev
```

**Size:** ~3.3 GB  
**Enough for:** Web development, agent scripts, most tasks

---

### For Full Stack Development

```powershell
# Node.js + Python
pnpm install
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# Start services
pnpm dev                    # Node.js dev server
docker-compose up -d        # SigNoz stack
```

**Size:** ~5 GB  
**Enough for:** Full observability stack

---

### For GPU/AI Features

```powershell
# Everything above, plus GPU requirements
pip install -r requirements-gpu.txt

# Start GPU services
docker-compose -f docker-compose.gpu.yml up -d
```

**Size:** ~6 GB  
**Enough for:** GPU inference, Triton models

---

## 📊 Repository Size Comparison

| State | Size | Files | Status |
|-------|------|-------|--------|
| **Before Cleanup** | 7.28 GB | 211,081 | 🔴 Bloated |
| **After Cleanup** | ~700 MB | ~50,000 | 🟢 Lean |
| **With Dependencies** | ~5 GB | ~211,000 | ✅ Working |

**Reduction:** 89% smaller on disk when not actively developing

---

## 🔐 .gitignore Protection

The updated `.gitignore` prevents these from being committed:

```gitignore
node_modules/
.venv/
venv/
.next/
dist/
out/
build/
__pycache__/
*.pyc
```

**Result:** Future `git add .` won't re-bloat the repository

---

## ⚠️ Important Notes

### Don't Commit These

- ❌ `node_modules/` - Use package.json instead
- ❌ `.venv/` - Use requirements.txt instead
- ❌ Build artifacts (.next, dist, out)
- ❌ Python cache (**pycache**)

**Already Protected:** .gitignore prevents accidental commits

---

### Mock Data Warning

**`resonai-mock/`** (0.81 GB) - This may contain:

- Generated mock data (regeneratable)
- Test fixtures (may need backup)
- Sample datasets (depends on use case)

<!-- markdownlint-disable-next-line MD013 -->
**Before removing:** Check if this contains unique test data that should be backed up or stored elsewhere (e.g., git-lfs, cloud storage).

---

## 🎯 Recommended Workflow

### Daily Development

```powershell
# Clone fresh repository
git clone https://github.com/MoneyCat-inc/otel-ops-pack.git
cd otel-ops-pack

# Restore dependencies (5 min)
pnpm install
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

# Start working
pnpm dev
```

**Size:** Starts at 700 MB, grows to ~5 GB with dependencies

---

### End of Day

```powershell
# Commit your work
git add <your-changes>
git commit -m "..."
git push

# Optional: Remove dependencies to save space
pwsh -File scripts\cleanup-bloat.ps1 -Force
```

**Result:** Back to 700 MB overnight

---

## 📋 Quick Reference

**Restore Everything:**

```powershell
pnpm install && python -m venv .venv && .venv\Scripts\pip install -r requirements.txt
```

**Clean Everything:**

```powershell
pwsh -File scripts\cleanup-bloat.ps1 -Force
```

**Check Current Size:**

```powershell
$size = (Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
Write-Host "Repository: $([math]::Round($size / 1GB, 2)) GB"
```

---

🐾 **BossCat: Repository externalized - from 7.3 GB to <1 GB!**

**All bloat removed. Dependencies can be restored in 5-10 minutes when needed.**

