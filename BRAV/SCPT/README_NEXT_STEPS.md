# 🐾 BossCat Tetragram Migration - Next Steps

**Resonai [OTel] Repository Restructuring Guide**  
*Executive Overseer: BossCat OEM*

---

## 📋 Quick Reference

### Current Status
Run the guardrails checker to see current compliance:

```bash
# Unix/Linux/macOS
python3 BRAV/SCPT/check_guardrails.py

# Windows (PowerShell)
python BRAV\SCPT\check_guardrails.py
```

### One-Command Migrations

**Phase B.1 - Scripts Migration:**
```bash
# Unix
bash BRAV/SCPT/migrate_scripts.sh

# Windows PowerShell (as Administrator for junctions)
pwsh -File .\BRAV\SCPT\migrate_scripts.ps1
```

**Phase B.2 - Configs/Infra/Assets Migration:**
```bash
# Unix
bash BRAV/SCPT/migrate_configs.sh

# Windows PowerShell (as Administrator)
pwsh -File .\BRAV\SCPT\migrate_configs.ps1
```

**Shim Cleanup (after 2+ green CI cycles):**
```bash
# Unix (dry-run first)
bash BRAV/SCPT/cleanup_shims.sh --dry-run
bash BRAV/SCPT/cleanup_shims.sh

# Windows PowerShell
pwsh -File .\BRAV\SCPT\cleanup_shims.ps1 -DryRun
pwsh -File .\BRAV\SCPT\cleanup_shims.ps1
```

---

## 🎯 Migration Phases Overview

### Phase A: Foundation ✅ COMPLETE
- [x] Guardrails infrastructure installed
- [x] CI workflow enabled
- [x] Migration scripts prepared
- [x] CODEOWNERS configured
- [x] PR template created

### Phase B.1: Scripts → `BRAV/SCPT` 🔄 READY
**What:** Move all PowerShell, Bash, Python scripts from root `scripts/` to `BRAV/SCPT/`  
**Shim:** Creates `scripts → BRAV/SCPT` symlink/junction  
**Timeline:** 1 PR + 2 validation cycles before shim removal

**Steps:**
1. Run migration: `bash BRAV/SCPT/migrate_scripts.sh` (or `.ps1`)
2. Test key scripts via old paths (shim keeps them working)
3. Commit: `git add -A && git commit -m "chore(repo): move scripts → BRAV/SCPT with shim"`
4. Push and verify CI is green
5. Update workflow/doc references over next 2 cycles
6. Remove shim: `bash BRAV/SCPT/cleanup_shims.sh`

### Phase B.2: Configs/Infra/Assets → `DELT` & `BRAV` 🔄 READY
**What:** Organize configs, Docker, Helm, artifacts, test data  

**Mapping:**
- `config/`, `configs/` → `DELT/CONF/`
- `docker/` → `BRAV/DOCK/legacy/`
- `helm/`, `deployment-pipeline/` → `BRAV/INFR/`
- `artifacts/`, `reports/`, `playwright-report/` → `CHAR/EVID/`
- `assets/`, `baseline/`, `test-payloads/` → `DELT/ASST/`, `DELT/FIXT/`
- `templates/` → `DELT/TMPL/`

**Steps:**
1. Run migration: `bash BRAV/SCPT/migrate_configs.sh` (or `.ps1`)
2. Update CI workflow paths (if needed)
3. Test CI/CD pipelines
4. Commit: `git add -A && git commit -m "chore(repo): move configs/infra/assets to DELT/BRAV"`
5. After 2 green cycles, remove shims

### Phase C: Source Code → `ALFA` 📅 NEXT
**What:** Move application source, instrumentation, libraries  

**Mapping:**
- Core application code → `ALFA/CORE/`
- Instrumentation → `ALFA/INST/`
- Apps/demos → `ALFA/APPS/`
- Shared libraries → `ALFA/LIBS/`

**Considerations:**
- Requires import path rewrites (JS/TS, Python, Go)
- May need build tool config updates
- Larger scope - break into smaller PRs by module

### Phase D: Documentation → `CHAR` 📅 FUTURE
**What:** Consolidate documentation, guides, cheatsheets  

**Mapping:**
- `docs/` → `CHAR/DOCS/`
- `CHAR/ECRR/ECRR_REPORTS/` → `CHAR/EVID/ECRR_REPORTS/`
- `docs/observability/` → `CHAR/DOCS/observability/`

---

## 🛡️ Guardrails Enforced

The guardrails checker (`BRAV/SCPT/check_guardrails.py`) enforces:

### ✅ Allowed Top-Level Structure
- **Planes:** `ALFA/`, `BRAV/`, `CHAR/`, `DELT/`
- **Special:** `.github/`, `.agent/`, `.git/`
- **Standard files:** `README.md`, `package.json`, `AGENTS.md`, etc.

### ❌ Forbidden Legacy Roots
- `scripts/`, `docs/`, `config/`, `configs/`
- `docker/`, `helm/`, `deployment-pipeline/`
- `assets/`, `reports/`, `artifacts/`, `playwright-report/`
- `synthetic/`, `tests/`, `tools/`, `logs/`, `tmp/`, `backups/`, `archive/`

### 📏 Path Depth
- Maximum: 7 levels deep
- Prevents over-nesting

### 🔄 CI Workflow Rules
- Inline `run:` blocks: ≤ 20 lines (warns if exceeded)
- Encourages extracting logic to `BRAV/SCPT/` scripts

---

## 📊 Tetragram Structure Reference

```
.
├── ALFA/           # Application plane
│   ├── CORE/       # Core application logic
│   ├── INST/       # Instrumentation code
│   ├── APPS/       # Applications & demos
│   └── LIBS/       # Shared libraries
│
├── BRAV/           # Build/Runtime/Automation/Verification
│   ├── SCPT/       # Scripts (PowerShell, Bash, Python)
│   ├── INFR/       # Infrastructure (Helm, deployment)
│   ├── DOCK/       # Docker configs & Dockerfiles
│   ├── CICD/       # CI/CD pipeline definitions
│   └── HOOK/       # Git hooks & pre-commit scripts
│
├── CHAR/           # Compliance/Human/Audit/Review
│   ├── DOCS/       # Documentation & guides
│   ├── EVID/       # Evidence (reports, artifacts, snapshots)
│   ├── AUDT/       # Audit logs & compliance records
│   └── REPO/       # Reports & executive summaries
│
├── DELT/           # Data/Environment/Load/Test
│   ├── CONF/       # Configuration files
│   ├── FIXT/       # Test fixtures & baseline data
│   ├── ASST/       # Static assets
│   ├── LOAD/       # Load test scenarios
│   └── TMPL/       # Templates (config, code, etc.)
│
├── .github/        # GitHub workflows & templates
├── .agent/         # AI agent configurations
└── [standard files] # package.json, README.md, etc.
```

---

## 🔄 Migration Workflow

### Small PR Strategy
1. **One plane per PR** - keeps changes focused
2. **Budget: ≤10 files or ≤200 LOC** of non-move changes per PR
3. **Shims first, references later** - use shims to avoid breakage
4. **Evidence-based** - attach before/after tree, pathmap updates

### Validation Window
- **2 green CI/CD cycles** required before shim removal
- Allows time to catch integration issues
- Update references gradually during window

### Git Flow
```bash
# Create feature branch
git checkout -b chore/tetragram-phase-b1

# Run migration
bash BRAV/SCPT/migrate_scripts.sh

# Review changes
git status
git diff

# Commit with ECRR format
git add -A
git commit -m "chore(repo): move scripts → BRAV/SCPT with shim

ECRR Evidence:
- Examine: Identified 47 scripts in root scripts/
- Clean: Migrated to BRAV/SCPT/ with backward-compat shim
- Report: Pathmap updated, CI workflow references preserved
- Role: BossCat OEM / Migration Agent"

# Push and create PR
git push -u origin chore/tetragram-phase-b1
```

### PR Template Usage
The PR template (`.github/pull_request_template.md`) guides you through:
- ECRR framework compliance
- Tetragram structure validation
- Testing checklist
- Migration phase tracking
- Gate readiness criteria

---

## 🚦 Gate Readiness Checklist

Before requesting final BossCat approval:

- [ ] All phases (B.1, B.2, C, D) complete
- [ ] All legacy directories removed
- [ ] Guardrails check: **GREEN** ✅
- [ ] Full CI/CD pipeline: **GREEN** ✅
- [ ] All shims removed
- [ ] Documentation updated
- [ ] Evidence bundle prepared in `CHAR/EVID/`
- [ ] No forbidden legacy roots present
- [ ] Path depth compliance verified
- [ ] CODEOWNERS configured and enforced

**Trigger gate review:** Comment on PR with `@cat ready-for-gate`

---

## 📞 Support & Troubleshooting

### Common Issues

**Q: Migration script says "Permission denied" on Windows**  
A: Run PowerShell as Administrator for junction creation.

**Q: Shim isn't working after migration**  
A: Check if shim was created: `ls -la` (Unix) or `dir` (Windows).  
Recreate manually: `ln -s BRAV/SCPT scripts` (Unix) or `cmd /c mklink /J scripts BRAV\SCPT` (Windows).

**Q: CI fails with "path not found" after migration**  
A: Check if shim exists. If not, either recreate it or update the CI workflow to use new paths.

**Q: Guardrails check fails on directories I need**  
A: Edit `BRAV/SCPT/guardrails.json` to add exemptions or adjust rules. Discuss with BossCat for permanent changes.

**Q: How do I know when to remove shims?**  
A: After **2 consecutive green CI/CD cycles** with no path-related errors.

### Emergency Rollback
If migration causes critical issues:

```bash
# Remove shim
rm scripts  # or: rmdir scripts (Windows)

# Restore from backup
git checkout HEAD~1 -- scripts/

# Or full revert
git revert HEAD
```

---

## 🎓 References

- **AGENTS.md** - BossCat governance framework
- **ART_OF_ECRR.md** - ECRR methodology deep dive
- **DECISIONS.md** - Architecture decision records
- **CODEOWNERS** - Ownership and approval matrix
- **Guardrails config:** `BRAV/SCPT/guardrails.json`

---

## 📬 Next Steps Summary

**Right Now (Phase B.1):**
```bash
python3 BRAV/SCPT/check_guardrails.py          # Check current state
bash BRAV/SCPT/migrate_scripts.sh              # Migrate scripts
git add -A && git commit -m "chore(repo): move scripts → BRAV/SCPT with shim"
git push                                       # Verify CI green
```

**After 2 Green Cycles:**
```bash
bash BRAV/SCPT/cleanup_shims.sh --dry-run     # Preview
bash BRAV/SCPT/cleanup_shims.sh               # Remove shims
git add -A && git commit -m "chore(repo): remove legacy shims after validation"
```

**Then Phase B.2, C, D...**

---

🐾 **BossCat says:** _"Take it one phase at a time. Small PRs, solid evidence, green CI. That's how we migrate without chaos."_

---

_Last updated: 2025-10-09_  
_Version: 1.0.0_  
_Maintained by: BossCat OEM_


