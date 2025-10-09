# Tetragram Day-2 Operations Guide

**Version:** 1.0  
**Date:** 2025-10-09  
**Baseline:** tetragram-1.2.1-remediation  
**Status:** Production Operations

---

## 🎯 Purpose

This runbook ensures the tetragram baseline remains pristine during steady-state operations. Follow these practices to maintain 100% compliance, prevent structural drift, and operate with confidence.

---

## ✅ Immediate Post-Closure Actions (One-Time)

### 1. Publish GitHub Release

```bash
gh release create tetragram-1.2.1-remediation \
  --title "Tetragram 1.2.1 — Structural & Operational Remediation (Gates PASS)" \
  --notes-file CHAR/EVID/TETRAGRAM_1.2.1_FINAL_STATUS.md
```

**Verification:**
```bash
gh release view tetragram-1.2.1-remediation
```

### 2. Branch Protection Audit Checklist

Verify GitHub settings for `main` branch:

- [ ] **Required status checks:** `guardrails` (strict mode)
- [ ] **Required reviews:** ≥1 (dismiss stale approvals)
- [ ] **Linear history:** Enabled (or squash merges)
- [ ] **Restrict push access:** Configured (recommended)
- [ ] **Require signed commits/tags:** Enabled (recommended)

**GitHub Path:** Settings → Branches → Branch protection rules → `main`

### 3. Team Announcement Template

**Post to Slack/Teams/GitHub Discussion:**

```markdown
## 🐾 Tetragram 1.2.1 is Live — Both Gates PASS ✅

**Status:** 0/0/0 compliance (zero violations)

**Key Changes:**
- Workflows must delegate to **BRAV/SCPT/** scripts
- Inline `run:` in workflows ≤ 20 lines
- New components: use `BRAV/SCPT/new_app.sh` or `new_lib.sh`

**Evidence:** `CHAR/EVID/TETRAGRAM_1.2.1_FINAL_STATUS.md`

**Questions:** #tetragram-ops
```

---

## 🛡️ Steady-State Guardrails (What's Enforced)

### Allowed Top-Level Structure

```
ALFA/           # Application plane
BRAV/           # Build/Runtime/Automation/Verification
CHAR/           # Compliance/Human/Audit/Review
DELT/           # Data/Environment/Load/Test
.github/        # GitHub workflows
.agent/         # AI assistant context
+ standard files (README.md, package.json, etc.)
```

### Plane Subfolder Rules

**4-letter naming enforced:**
- `ALFA/APPS/`, `ALFA/LIBS/`, `ALFA/CORE/`, etc.
- `BRAV/SCPT/`, `BRAV/DOCK/`, `BRAV/INFR/`, etc.
- `CHAR/DOCS/`, `CHAR/EVID/`, `CHAR/PRSV/`, etc.
- `DELT/CONF/`, `DELT/ASST/`, `DELT/FIXT/`, `DELT/TMPL/`

### Ephemeral Directory Handling

**Allowed ephemerals:** `logs/`, `out/`, `tmp/`, `.cache/`, `coverage/`, `dist/`, `build/`, `.next/`

**Rules:**
- **Untracked:** Warned but ignored ✅
- **Tracked:** **FAIL** (must be in `.gitignore` + untracked) ❌

**Fix tracked ephemerals:**
```bash
echo "logs/" >> .gitignore
echo "out/" >> .gitignore
echo "tmp/" >> .gitignore
git add .gitignore
git commit -m "fix(gitignore): add ephemeral directories"
```

### Workflow Rules

**Thin YAML policy:**
- Logic delegated to **BRAV/SCPT/** scripts
- Inline `run:` blocks ≤ **20 lines**
- Complex logic extracted to dedicated scripts

**Bad (violation):**
```yaml
- run: |
    # 50 lines of bash logic...
```

**Good (compliant):**
```yaml
- run: bash BRAV/SCPT/deploy.sh "${{ matrix.app }}" rollout
```

### Enforcement Modes

- **`main` branch:** **Strict mode** (exit 1 on violations)
- **Feature branches:** Non-strict (warnings only)

---

## 📈 Day-2 Watchlist (First 2 Weeks)

Track these signals to maintain baseline integrity:

| Metric | Target | Action if Below |
|--------|--------|-----------------|
| **Guardrails pass rate (PRs)** | ≥95% | Review failing patterns, team training |
| **CI time-to-first-step** | ≤60s | Optimize workflow, check runner health |
| **Unauthorized roots** | 0 | Immediate remediation required |
| **Tracked ephemerals** | 0 | Add to .gitignore, clean working tree |
| **Path churn per release** | ≤10% | Review structural changes, use aliases |
| **Nightly health artifact** | Present | Fix cron job, check permissions |

### Monitoring Commands

**Daily:**
```bash
# Check guardrails
python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json --strict
```

**Weekly:**
```bash
# Health snapshot
python BRAV/SCPT/tetragram_health.py > CHAR/EVID/health/snapshot-$(date +%F).json

# Review PR metrics
gh pr list --state merged --limit 20 --json number,checks | jq '.[] | select(.checks[] | select(.name=="guardrails"))'
```

**Monthly:**
```bash
# Structural audit
git log --since="1 month ago" --name-status --oneline | grep "^R" | wc -l  # Path renames
find . -maxdepth 1 -type d | wc -l  # Top-level directory count
```

---

## 🔧 Hardening Backlog (High-Value, Low-Effort)

### Supply Chain Security

**Dependabot:**
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "docker"
    directory: "/BRAV/DOCK"
    schedule:
      interval: "weekly"
```

**OSSF Scorecard:**
```yaml
# .github/workflows/scorecard.yml
name: Scorecard supply-chain security
on:
  branch_protection_rule:
  schedule:
    - cron: '0 2 * * 0'  # Weekly
  push:
    branches: [ main ]
```

**SBOM Generation:**
```bash
# In BRAV/SCPT/build.sh
syft dir:. -o spdx-json > sbom.spdx.json
```

### Secrets Scanning

**Gitleaks (preferred):**
```bash
# Install
winget install gitleaks

# In .github/workflows/security.yml
- uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**GitHub Secret Scanning:**
- Enable in Settings → Code security and analysis
- Enable push protection

### Container Security

**Trivy Scan:**
```bash
# In BRAV/SCPT/deploy.sh after 'package'
trivy image ghcr.io/moneycat-inc/my-app:$TAG --exit-code 1 --severity HIGH,CRITICAL
```

### Environment Automation

**DEV Auto-Deploy:**
```yaml
# .github/workflows/deploy-dev.yml
on:
  push:
    branches: [ main ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: bash BRAV/SCPT/deploy.sh ${{ matrix.app }} rollout
        env:
          KUBE_CONTEXT: dev
```

### Governance

**Quarterly Reviews:**
- Audit 4-letter naming additions
- Review CODEOWNERS for new ALFA areas
- Update ADRs for structural decisions
- Assess guardrails effectiveness

**Action:** Schedule recurring calendar event for tetragram review

---

## 🧰 Quick Command Reference

### Guardrails & Health

```bash
# Run guardrails (strict on main)
python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json --strict

# Health snapshot
python BRAV/SCPT/tetragram_health.py > CHAR/EVID/health/snapshot-$(date +%F).json

# Validate pathmap
python BRAV/SCPT/validate_pathmap.py .
```

### Scaffolding New Components

```bash
# New application
bash BRAV/SCPT/new_app.sh my-service
# Creates: ALFA/APPS/my-service/

# New library
bash BRAV/SCPT/new_lib.sh ui-kit
# Creates: ALFA/LIBS/ui-kit/
```

### Build/Test/Deploy Workflow

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

### Migration & Moves

```bash
# Batch move using pathmap
python BRAV/SCPT/move_by_map.py

# Check if directory should be migrated
python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json
# (Will list unauthorized directories)
```

---

## 🧯 Recovery Drill (Practice Once)

### Scenario: Revert Mistaken Structural Merge

**Situation:** A PR merged with structural violations that broke guardrails.

**Recovery Steps:**

1. **Identify the merge commit:**
   ```bash
   git log --oneline --merges -10
   # Find: abc1234 Merge pull request #123 from feature/bad-structure
   ```

2. **Revert the merge (keeps history clean):**
   ```bash
   git revert -m 1 abc1234
   git push origin main
   ```

3. **Verify guardrails pass:**
   ```bash
   python BRAV/SCPT/check_guardrails.py --strict
   # Should exit 0
   ```

4. **Fix the original PR properly:**
   ```bash
   # On the feature branch
   git checkout feature/bad-structure
   git rebase main
   
   # Apply proper moves
   python BRAV/SCPT/move_by_map.py
   
   # Verify before re-merging
   python BRAV/SCPT/check_guardrails.py --strict
   ```

5. **Re-merge with clean structure:**
   ```bash
   git checkout main
   git merge feature/bad-structure
   git push origin main
   ```

**Practice this drill in a sandbox branch to build muscle memory.**

---

## 📊 Success Indicators

### Week 1
- [ ] GitHub release published
- [ ] Branch protection configured
- [ ] Team announcement posted
- [ ] Zero guardrails failures on main
- [ ] Nightly health snapshots running

### Week 2
- [ ] All PRs pass guardrails on first try
- [ ] No tracked ephemerals detected
- [ ] Recovery drill practiced
- [ ] CODEOWNERS reviewed

### Month 1
- [ ] PR pass rate ≥95%
- [ ] ≥3 new components scaffolded correctly
- [ ] Zero unauthorized root directories
- [ ] Hardening backlog items prioritized
- [ ] First quarterly review scheduled

---

## 🔗 Related Documentation

**Core References:**
- `CHAR/EVID/BOSSCAT_GATE_APPROVAL_FINAL.md` - Gate approval
- `CHAR/EVID/TETRAGRAM_1.2.1_FINAL_STATUS.md` - Final status
- `GUARDRAILS_CLEAN_BASELINE.md` - Baseline certification

**Runbooks:**
- `CHAR/DOCS/runbooks/tetragram-new-component.md` - Scaffolding guide
- `CHAR/DOCS/runbooks/repo-structure-violations.md` - Violation remediation

**Tools:**
- `BRAV/SCPT/README_NEXT_STEPS.md` - Tool documentation
- `BRAV/SCPT/guardrails.json` - Enforcement rules

---

## 📞 Support & Escalation

**For structural questions:**
- Review: `CHAR/DOCS/ADR/` (Architecture Decision Records)
- Check: `BRAV/SCPT/guardrails.json` for current rules
- Ask: #tetragram-ops channel

**For tooling issues:**
- Logs: Check CI workflow output
- Local test: Run guardrails locally before pushing
- Debug: Add `--verbose` flag to scripts

**For gate failures:**
- Immediate: Revert offending commit
- Root cause: Analyze guardrails output
- Remediate: Apply proper structure, re-test
- Document: Update evidence in `CHAR/EVID/`

---

## 🐾 BossCat Standards

**Maintain the baseline with:**
- ✅ Daily guardrails verification
- ✅ Weekly health snapshots
- ✅ Monthly structural audits
- ✅ Quarterly governance reviews
- ✅ Continuous team awareness

**The tetragram structure is production-approved. Keep it clean. Keep it compliant. Keep it excellent.**

---

**Version:** 1.0  
**Approved:** BossCat OEM  
**Date:** 2025-10-09  
**Seal:** 🐾

