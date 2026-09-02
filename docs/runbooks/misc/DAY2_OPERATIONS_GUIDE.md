<!-- markdownlint-disable MD022 MD031 MD032 MD036 MD040 -->
# Day-2 Operations Guide - Tetragram 1.2

> ## HISTORICAL — tetragram-1.2 day-2 guide (2025-10-09), predates ADR-0002
>
> Two rules here are no longer true: `scripts/` and `docs/` are **authorized roots** (ADR-0002
> ratified the hybrid on 2026-08-29 — `scripts/*.ps1` are thin wrappers over `BRAV/SCPT/`, `docs/` is
> the documentation source), so the "forbidden legacy root" error and the pre-commit `FORBID` list
> below would reject the repository's own current layout. The five root status files linked under
> "For Operations / For Compliance" were removed with the tetragram-1.2 milestone. The proposed
> "nightly health snapshot" would be a new recurring writer, which `docs/PURPOSE.md` forbids without an
> owner, review date and kill switch. The guardrail mechanics (`BRAV/SCPT/check_guardrails.py`,
> `guardrails.json`, ≤40 inline run lines) remain accurate — the guard is live on every PR.
>
> **Current layout and rules:** `docs/REPOSITORY_STRUCTURE.md`.

**Version:** 1.0  
**Baseline:** tetragram-1.2  
**Last Updated:** 2025-10-09  
**Status:** ✅ **Active**

---

## 🎯 Quick Reference

**Compliance Status:**
- ✅ Exit code: 0 (strict pass)
- ✅ Forbidden roots: 0
- ✅ Unauthorized directories: 0
- ✅ Path depth: Within limit (7)

**Run Anytime:**
```bash
# Guardrails check
python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json

# Health snapshot
python BRAV/SCPT/tetragram_health.py

# Create new app
bash BRAV/SCPT/new_app.sh <name>

# Create new library
bash BRAV/SCPT/new_lib.sh <name>
```

---

## 🛡️ Workflow Policy (Enforced)

### Rules
1. **Workflows delegate to BRAV/SCPT/** scripts
2. **Inline `run:` blocks ≤ 20 lines** (enforced at 40, ratcheting to 20)
3. **Ephemerals handled precisely:**
   - Untracked → Warned & ignored
   - Tracked → **FAIL** (add to .gitignore, untrack)

### Pattern: Thin Delegator (Good)
```yaml
- name: Build
  run: bash BRAV/SCPT/build.sh
```

### Anti-Pattern: Heavy Inline (Bad)
```yaml
- name: Build
  run: |
    # 40+ lines of inline logic
    # ❌ Fails guardrails
    # ❌ Hard to test locally
```

**See:** `CHAR/DOCS/runbooks/ci-delegation.md` for details.

---

## 📦 Adding New Components

### New Application
```bash
# Generate scaffold
bash BRAV/SCPT/new_app.sh my-service

# Or PowerShell
pwsh -File BRAV\SCPT\new_app.ps1 -Name my-service

# Result: ALFA/APPS/my-service/
# - src/index.js
# - config/
# - scripts/
# - README.md
# - package.json
```

### New Library
```bash
# Generate scaffold
bash BRAV/SCPT/new_lib.sh my-utils

# Or PowerShell
pwsh -File BRAV\SCPT\new_lib.ps1 -Name my-utils

# Result: ALFA/LIBS/my-utils/
# - src/index.js
# - README.md
# - package.json

# Use in apps
# import { util } from '@alfa/LIBS/my-utils';
```

### New Script
```bash
# Create in BRAV/SCPT/
cat > BRAV/SCPT/my-script.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Implementation
EOF

chmod +x BRAV/SCPT/my-script.sh

# Call from workflow
# - run: bash BRAV/SCPT/my-script.sh
```

### New Documentation
```bash
# Create in CHAR/DOCS/
mkdir -p CHAR/DOCS/guides
cat > CHAR/DOCS/guides/my-guide.md <<'EOF'
# My Guide
Content here
EOF
```

### New Configuration
```bash
# Create in DELT/CONF/
mkdir -p DELT/CONF/my-service
cat > DELT/CONF/my-service/config.yaml <<'EOF'
# Configuration
EOF
```

**See:** `CHAR/DOCS/runbooks/tetragram-new-component.md` for complete guide.

---

## 🔍 Troubleshooting Guardrails

### Error: "Forbidden legacy root"
**Cause:** Created directory with forbidden name (scripts/, docs/, config/, etc.)

**Fix:**
```bash
# Move to correct plane
git mv scripts BRAV/SCPT/legacy-scripts
# or delete if not needed
```

### Error: "Unauthorized top-level directory"
**Cause:** Created new directory at repo root

**Fix:**
```bash
# Move to appropriate plane
git mv my-new-dir ALFA/APPS/my-new-dir
# or CHAR/DOCS/, DELT/CONF/, etc.
```

### Error: "Ephemeral tracked"
**Cause:** Committed logs/, tmp/, or out/

**Fix:**
```bash
# Add to .gitignore
echo "logs/" >> .gitignore

# Untrack
git rm -r --cached logs/

# Commit
git add .gitignore
git commit -m "chore: untrack ephemeral logs/ directory"
```

### Error: "Path depth exceeds limit"
**Cause:** Directory nesting > 7 levels

**Fix:**
```bash
# Flatten structure
git mv deeply/nested/path/to/file shallower/file
```

**See:** `CHAR/DOCS/runbooks/repo-structure-violations.md` for details.

---

## 📊 Monitoring & Drift Prevention

### Nightly Health Snapshot (Recommended)
```bash
# Add to cron or scheduled workflow
python3 BRAV/SCPT/tetragram_health.py > CHAR/EVID/health/nightly-$(date +%F).json
```

### PR Guardrails (Active)
- ✅ `.github/workflows/guardrails.yml` runs on all PRs
- ✅ Required check on main branch
- ✅ Strict mode for main, regular for feature branches

### Local Verification (Before Push)
```bash
# Check before committing
python BRAV/SCPT/check_guardrails.py

# Verify your changes
git status
```

---

## 🔄 Governance: Adding New Top-Level Areas

**New top-level directories are disallowed by default.**

If you genuinely need a new plane-level area:

1. **Propose:** Open PR with ADR explaining why
2. **Add:** Include 4-letter subdir in appropriate plane
3. **Update:** Modify `BRAV/SCPT/guardrails.json` allowed list
4. **Evidence:** Document in `CHAR/EVID/<date>-change-justification.md`
5. **Review:** Require BossCat OEM approval

**Most cases:** Use existing planes instead
- Documentation? → `CHAR/DOCS/`
- Temporary? → `CHAR/PRSV/` or `.gitignore`
- Configuration? → `DELT/CONF/`
- Automation? → `BRAV/SCPT/`

---

## 🎨 TypeScript Path Aliases

**Configured in `tsconfig.base.json`:**
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@alfa/*": ["ALFA/*"],
      "@brav/*": ["BRAV/*"],
      "@char/*": ["CHAR/*"],
      "@delt/*": ["DELT/*"]
    }
  }
}
```

**Usage:**
```typescript
// Old: import { util } from '../../../lib/utils'
// New: import { util } from '@alfa/LIBS/lib/utils'

// Old: import { config } from '../../config/app'
// New: import { config } from '@delt/CONF/app'
```

**Benefits:**
- No path depth issues
- Refactor-safe imports
- Clear module boundaries
- IDE autocomplete works

---

## 🧪 Testing & Validation

### Before Committing
```bash
# 1. Run guardrails locally
python BRAV/SCPT/check_guardrails.py

# 2. Check git status
git status

# 3. Verify no ephemeral dirs tracked
git ls-files logs/ out/ tmp/ || echo "OK: not tracked"

# 4. Test your changes
npm test  # or equivalent
```

### After Merging
```bash
# Health snapshot
python BRAV/SCPT/tetragram_health.py

# Verify structure
python BRAV/SCPT/check_guardrails.py --strict
```

---

## 🚨 Emergency Procedures

### If Forbidden Root Reappears
```bash
# Don't panic - fix is mechanical
git mv <forbidden-dir> <tetragram-path>
git commit -m "fix: relocate <dir> to tetragram structure"

# Example
git mv scripts BRAV/SCPT/emergency-scripts
```

### If Multiple Violations Slip Through
```bash
# Use the batch mover
# 1. Update move_map.json with corrections
# 2. Run mover
python BRAV/SCPT/move_by_map.py

# 3. Commit and verify
git add -A
git commit -m "fix: batch relocate to tetragram structure"
python BRAV/SCPT/check_guardrails.py
```

### If Accidental Force Push
```bash
# Contact BossCat OEM immediately
# Restore from tag
git reset --hard tetragram-1.2

# Or restore from backup
# Evidence in CHAR/EVID/ can help reconstruct
```

---

## 📊 KPIs to Track

### Compliance Metrics
- **Forbidden roots:** Target 0, alert if > 0
- **Unauthorized dirs:** Target 0, alert if > 0
- **Guardrails pass rate:** Target ≥ 95% on PRs
- **Exit code:** Target 0 (clean pass)

### Operational Metrics
- **Time to find:** Target ≤ 3 clicks to locate code
- **CI entry latency:** Target ≤ 60s to first step
- **Path churn:** Target ≤ 10% import rewrites per major change
- **Scaffold usage:** Track new_app/new_lib usage

### Health Metrics
- **Nightly compliance:** Daily health snapshots
- **Drift detection:** Alert on new violations
- **Prevention rate:** Track blocked commits (pre-commit hooks)

---

## 🔧 Ratcheting & Hardening (When Ready)

### Phase 1: Ratchet Workflow Limit
**Current:** 40 lines  
**Target:** 20 lines

**Action:**
```json
// BRAV/SCPT/guardrails.json
"max_inline_run_lines": 20
```

**Impact:** 26 current workflows will need logic extracted to BRAV/SCPT/

### Phase 2: Extract Workflow Logic
**Target:** Clear all 26 workflow warnings

**Approach:**
- Small batches (3-5 workflows per PR)
- Extract to BRAV/SCPT/ scripts
- Test locally before committing
- Document in evidence

### Phase 3: Flatten Remaining Nested Dirs (Optional)
**Examples:**
- `CHAR/DOCS/ai-context/ai-context/` → `CHAR/DOCS/ai-context/`
- `CHAR/EVID/preview/preview/` → `CHAR/EVID/preview/`
- `CHAR/PRSV/comfort-cat-stubs/comfort-cat-stubs/` → `CHAR/PRSV/comfort-cat-stubs/`

**Impact:** Cleaner paths, better navigation

---

## 📚 Key Documentation

**For Developers:**
- `README.md` - Repository overview + tetragram structure
- `CHAR/DOCS/runbooks/tetragram-new-component.md` - How to add components
- `CHAR/DOCS/runbooks/ci-delegation.md` - Workflow best practices
- `CHAR/DOCS/ADR/0001-tetragram-baseline.md` - Architecture decisions

**For Operations:**
- `DAY2_OPERATIONS_GUIDE.md` - This document
- `VERIFICATION_READINESS_CHECKLIST.md` - Verification guide
- `TETRAGRAM_STATUS.md` - Current status
- `BRAV/SCPT/README_NEXT_STEPS.md` - Migration history

**For Compliance:**
- `GUARDRAILS_CLEAN_BASELINE.md` - Exit code 0 certification
- `READY_FOR_FINAL_GATE.md` - Gate readiness
- `TETRAGRAM_1.2_COMPLETE.md` - Milestone documentation
- `CHAR/EVID/gate/` - Gate approval bundle

---

## 🎯 Success Criteria (Ongoing)

**Daily:**
- ✅ Guardrails pass on all PRs
- ✅ No forbidden roots introduced
- ✅ Nightly health snapshots clean

**Weekly:**
- ✅ Zero structural drift
- ✅ Team using scaffolds correctly
- ✅ Documentation kept current

**Monthly:**
- ✅ Review optional improvements (workflow extraction, etc.)
- ✅ Update runbooks based on team feedback
- ✅ Capture lessons learned

---

## 🐾 BossCat OEM — Final Structural Gate Approval

**Decision:** ✅ **APPROVED** (tetragram-1.2)

**Scope:**
- ALFA/BRAV/CHAR/DELT structure locked
- 4-letter subdirectories enforced
- Guardrails strict on main
- Ephemerals handled precisely
- Prevention measures active

**Approval Artifacts (Version Controlled):**
- ✅ `CHAR/EVID/gate/guardrails.txt` (strict run)
- ✅ `CHAR/EVID/phase-f/final_guardrails_clean.txt`
- ✅ `CHAR/EVID/phase-f/final_health_clean.json`
- ✅ `GUARDRAILS_CLEAN_BASELINE.md`
- ✅ Tag: **tetragram-1.2**

**Evidence:** Complete ECRR trail with 100% violation reduction.

**Certification:** Structure is locked, compliant, and production-ready.

---

## 🚀 Operational Verification (When Ready)

**Prerequisites:**
1. Start SigNoz stack: `pwsh -File start-signoz.ps1` or `docker-compose up`
2. Start Resonai app: `npm run dev` (port 3000)
3. Start webhook server (port 3003)
4. Set environment: `$env:ALERT_WEBHOOK_URL = "http://localhost:3003/webhook"`

**Verification:**
```powershell
# Run BossCat final verification
pwsh -File BRAV\SCPT\bosscat-final-verification.ps1

# Or component verification
pwsh -File BRAV\SCPT\verify-all-components.ps1
```

**Evidence:**
```bash
# Capture operational baseline
mkdir -p CHAR/EVID/operational
cp artifacts/component-verification-report.json CHAR/EVID/operational/
git add CHAR/EVID/operational
git commit -m "docs(evidence): operational verification baseline"
```

---

## 📋 Governance: New Top-Level Areas

**Default:** New top-level directories are **disallowed**.

**To introduce safely:**

1. **Propose:**
   - Open PR with ADR in `CHAR/DOCS/ADR/`
   - Explain why existing planes don't fit

2. **Place:**
   - Create under appropriate plane with 4-letter name
   - Example: `ALFA/LABS/`, `BRAV/EXEC/`

3. **Update:**
   - Modify `BRAV/SCPT/guardrails.json` if needed
   - Add to plane's allowed 4-letter set in `check_guardrails.py`

4. **Prove:**
   - Evidence note in `CHAR/EVID/<date>-justification.md`
   - Guardrails still pass (exit 0)

5. **Protect:**
   - Require BossCat OEM review
   - Document in runbooks

**Most cases:** Use existing planes
- Docs? → `CHAR/DOCS/`
- Archive? → `CHAR/PRSV/`
- Config? → `DELT/CONF/`
- Script? → `BRAV/SCPT/`

---

## 🔔 Monitoring Setup

### Nightly Health Snapshot (Recommended)

**GitHub Actions:** (add to `.github/workflows/guardrails.yml`)
```yaml
nightly-health:
  if: github.event_name == 'schedule'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v5
      with: { python-version: "3.x" }
    - name: Nightly health snapshot
      run: |
        mkdir -p CHAR/EVID/health
        python3 BRAV/SCPT/tetragram_health.py > CHAR/EVID/health/nightly-$(date +%F).json
    - name: Upload health artifact
      uses: actions/upload-artifact@v4
      with:
        name: tetragram-health-$(date +%F)
        path: CHAR/EVID/health/nightly-*.json
```

### Required Checks (Active)
- ✅ Guardrails workflow required on main
- ✅ Strict mode for main branch
- ✅ Regular mode for feature branches

### Optional: Pre-Commit Hook
**Location:** `.git/hooks/pre-commit`

```bash
#!/usr/bin/env bash
set -euo pipefail
FORBID=( docs scripts docker helm config configs artifacts "~" )
EPHEMERAL=( logs out tmp .cache coverage dist build .next )

mapfile -t FIRSTS < <(git diff --cached --name-only | awk -F/ '{print $1}' | sort -u)
fail=0
for f in "${FIRSTS[@]}"; do
  for x in "${FORBID[@]}"; do
    [[ "$f" == "$x" ]] && echo "❌ forbidden: $f" && fail=1
  done
  for e in "${EPHEMERAL[@]}"; do
    [[ "$f" == "$e" ]] && echo "❌ ephemeral tracked: $e" && fail=1
  done
done
[[ $fail -ne 0 ]] && exit 1
```

**Make executable:** `chmod +x .git/hooks/pre-commit`

---

## 🧭 Where Things Go (Quick Decision Tree)

```
New thing to add?
│
├─ Runnable app/service?     → ALFA/APPS/<name>/
├─ Shared library/module?    → ALFA/LIBS/<name>/
├─ Test suite?               → ALFA/TEST/<name>/
├─ Developer tool?           → ALFA/TOOL/<name>/
│
├─ CI/CD script?             → BRAV/SCPT/
├─ Dockerfile?               → BRAV/DOCK/
├─ Helm chart?               → BRAV/INFR/
│
├─ Documentation?            → CHAR/DOCS/
├─ Policy?                   → CHAR/DOCS/policies/
├─ Test report?              → CHAR/EVID/
├─ Archive/experiment?       → CHAR/PRSV/
│
├─ Configuration?            → DELT/CONF/
├─ Alert config?             → DELT/CONF/alerts/
├─ Test fixture?             → DELT/FIXT/
├─ Static asset?             → DELT/ASST/
└─ Template?                 → DELT/TMPL/
```

**When in doubt:** Ask in team chat or check existing similar components.

---

## 🔧 Optional Hardening (Backlog)

### Priority 1: Ratchet Workflow Limit
- **Current:** 40 lines
- **Target:** 20 lines
- **Impact:** 26 workflows need extraction
- **Effort:** 2-3 hours (small batches)

### Priority 2: Flatten Nested Dirs
- **Examples:** `ai-context/ai-context/`, `preview/preview/`
- **Impact:** Cleaner paths
- **Effort:** 30 minutes

### Priority 3: Adopt Aliases Throughout
- **Target:** Replace relative imports with `@alfa/*` etc.
- **Impact:** Refactor-safe imports
- **Effort:** Incremental (touch as you go)

---

## 📈 Migration Summary (Reference)

| Metric | Achieved |
|--------|----------|
| **Phases completed** | 6 (B.1, B.2, D, C.4, E, F) |
| **Directories migrated** | 40+ |
| **Files relocated** | 200+ |
| **Commits** | 50+ |
| **Evidence docs** | 25+ |
| **Tools deployed** | 6 |
| **Violation reduction** | 100% (70 → 0) |
| **Exit code** | 0 (clean pass) |

---

## 🐾 BossCat Certification

**Day-2 Operations Status:** ✅ **ACTIVE**

**Baseline:** tetragram-1.2 (locked)

**Compliance:**
- ✅ 0 forbidden roots
- ✅ 0 unauthorized directories
- ✅ 0 path depth violations
- ✅ Exit code: 0

**Tooling:**
- ✅ 6 tools deployed
- ✅ Component scaffolds ready
- ✅ Runbooks complete

**Team Readiness:**
- ✅ README updated
- ✅ Onboarding docs available
- ✅ Scaffolds tested

**Status:** ✅ **SHIP WITH CONFIDENCE**

---

**BossCat OEM**  
*Executive Overseer Manager*  
MoneyCat Inc · Resonai [OTel]

*"Day-2 operations: Locked and loaded. Team equipped. Guardrails active. Ship it."*

---

**Version:** 1.0  
**Baseline:** tetragram-1.2  
**Last Updated:** 2025-10-09  
**Status:** ✅ **Active & Production Ready**

