# Tetragram Quick Reference

**Version:** 1.2.1  
**Status:** Production Baseline  
**Last Updated:** 2025-10-09

---

## 🎯 Daily Operations

### Compliance Check
```bash
# Strict guardrails (required on main)
python3 BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json --strict

# Health snapshot
python3 BRAV/SCPT/tetragram_health.py > CHAR/EVID/health/snapshot-$(date +%F).json
```

### Scaffold New Components
```bash
# New application
bash BRAV/SCPT/new_app.sh my-service
# Creates: ALFA/APPS/my-service/

# New library
bash BRAV/SCPT/new_lib.sh ui-kit
# Creates: ALFA/LIBS/ui-kit/
```

### Build/Test/Deploy
```bash
# Build a single app
bash BRAV/SCPT/build.sh ALFA/APPS/my-service

# Test a single app
bash BRAV/SCPT/test.sh ALFA/APPS/my-service

# Deploy (package, push, rollout)
bash BRAV/SCPT/deploy.sh ALFA/APPS/my-service package
bash BRAV/SCPT/deploy.sh ALFA/APPS/my-service push
bash BRAV/SCPT/deploy.sh ALFA/APPS/my-service rollout
```

---

## 🛡️ Enforcement Rules

### Allowed Top-Level
```
ALFA/           # Application plane
BRAV/           # Build/Runtime/Automation/Verification
CHAR/           # Compliance/Human/Audit/Review
DELT/           # Data/Environment/Load/Test
.github/        # GitHub workflows
.agent/         # AI assistant context
+ standard files (README.md, package.json, etc.)
```

### 4-Letter Naming (Enforced)
```
ALFA/APPS/  ALFA/LIBS/  ALFA/CORE/  ALFA/OTEL/  ALFA/TEST/  ALFA/TOOL/
BRAV/SCPT/  BRAV/DOCK/  BRAV/INFR/
CHAR/DOCS/  CHAR/EVID/  CHAR/PRSV/
DELT/CONF/  DELT/ASST/  DELT/FIXT/  DELT/TMPL/
```

### Ephemeral Handling
**Allowed ephemerals:** `logs/`, `out/`, `tmp/`, `.cache/`, `coverage/`, `dist/`, `build/`, `.next/`

**Rules:**
- **Untracked:** Warned but ignored ✅
- **Tracked:** **FAIL** (must be in `.gitignore`) ❌

**Fix:**
```bash
echo "logs/" >> .gitignore
echo "out/" >> .gitignore
echo "tmp/" >> .gitignore
git add .gitignore
git commit -m "fix(gitignore): add ephemeral directories"
```

### Workflow Policy
- Logic delegated to **BRAV/SCPT/** scripts
- Inline `run:` blocks ≤ **20 lines**
- Complex logic in dedicated scripts

---

## 📊 Success Metrics

| Metric | Target | Frequency |
|--------|--------|-----------|
| **Guardrails pass rate (PRs)** | ≥95% | Weekly review |
| **CI time-to-first-step** | ≤60s | Per run |
| **Unauthorized roots** | 0 | Daily check |
| **Tracked ephemerals** | 0 | Daily check |
| **Path churn per release** | ≤10% | Monthly audit |

---

## 🧯 Recovery (Quick)

### Revert Bad Merge
```bash
# 1. Find merge commit
git log --oneline --merges -10

# 2. Revert (keeps history clean)
git revert -m 1 <merge_commit_sha>
git push origin main

# 3. Verify
python3 BRAV/SCPT/check_guardrails.py --strict
```

---

## 🔗 Key Documentation

**Core References:**
- `CHAR/EVID/BOSSCAT_GATE_APPROVAL_FINAL.md` - Gate approval
- `CHAR/EVID/TETRAGRAM_1.2.1_FINAL_STATUS.md` - Final status
- `CHAR/EVID/TETRAGRAM_DAY2_OPS_PACK.md` - Operations pack

**Runbooks:**
- `CHAR/DOCS/runbooks/tetragram-day2-operations.md` - Full operations guide
- `CHAR/DOCS/runbooks/tetragram-new-component.md` - Scaffolding guide
- `CHAR/DOCS/runbooks/repo-structure-violations.md` - Violation remediation

**Tools:**
- `BRAV/SCPT/README_NEXT_STEPS.md` - Tool documentation
- `BRAV/SCPT/guardrails.json` - Enforcement rules

---

## 🐾 Support

**Questions:** #tetragram-ops  
**Issues:** Open GitHub issue with label `tetragram`  
**Drift:** Automatic nightly alerts via `.github/workflows/drift-alert.yml`

---

**BossCat Standards:** Keep it clean. Keep it compliant. Keep it excellent.

**Seal:** 🐾

