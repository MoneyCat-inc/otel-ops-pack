# 🐾 Enable Gate/Site Evidence as Required Checks

**Authority**: BossCat OEM  
**Date**: 2025-10-13  
**Status**: 🟢 **GATE GREEN ACHIEVED** — Optional enforcement available

---

## 🎯 Purpose

Add Gate & Site Evidence checks as required status checks on the `main` branch to enforce 5/5 PASS before PR merges.

---

## ✅ What's Already Done

**Gate/Site System**: 🟢 **GREEN**
- Workflow: `gate-site-evidence.yml` operational
- Evidence: 5/5 PASS achieved (Run 18463803215)
- Self-contained: No external dependencies
- BossCat Log: GREEN flip recorded

**Branch Protection Workflow**: Updated
- File: `.github/workflows/bosscat-branch-protection.yml`
- Required checks: Aligned to gate/site job names
- Commit: 864ff14c

---

## 🚀 How to Enable (Manual - Recommended)

### Via GitHub UI (2 minutes)

1. Navigate to **Settings** → **Branches** → **main**
2. Find **Require status checks to pass before merging**
3. Click **Edit** on the rule
4. **Add** these three checks:
   - `Gate & Site Evidence (Non-Merging) / Gate • k6 thresholds`
   - `Gate & Site Evidence (Non-Merging) / Gate • synthetic trace (OTLP/HTTP)`
   - `Gate & Site Evidence (Non-Merging) / Site • links + a11y + CSP (coarse)`
5. **Keep existing checks**:
   - `BossCat — Gate Verify` (or remove if superseded)
   - `CodeQL`
   - `PSScriptAnalyzer`
   - `Gitleaks Security Scan`
6. Click **Save changes**

---

## 📋 Alternative: Via GitHub API

**Note**: Complex JSON structure, UI recommended

```bash
# Get current protection
gh api repos/MoneyCat-inc/otel-ops-pack/branches/main/protection > protection.json

# Edit protection.json to add three new contexts

# Apply updated protection
gh api -X PUT repos/MoneyCat-inc/otel-ops-pack/branches/main/protection --input protection.json
```

---

## ✅ Verification

After enabling, create a test PR and verify:

```bash
# Check required checks
gh api repos/MoneyCat-inc/otel-ops-pack/branches/main/protection \
  --jq '.required_status_checks.contexts[]'

# Expected output includes:
# Gate & Site Evidence (Non-Merging) / Gate • k6 thresholds
# Gate & Site Evidence (Non-Merging) / Gate • synthetic trace (OTLP/HTTP)
# Gate & Site Evidence (Non-Merging) / Site • links + a11y + CSP (coarse)
```

---

## 🎯 Impact

**With Enforcement**:
- ✅ PRs blocked until 5/5 PASS (perf + trace + site quality)
- ✅ Prevents regressions (broken links, performance, accessibility)
- ✅ Automated quality gates (zero manual review for evidence)

**Without Enforcement** (Current):
- ✅ Evidence still collected on all PRs
- ✅ Visible in PR checks (informational)
- ✅ No blocking (PRs can merge)

---

## 🔧 Troubleshooting

**If Checks Don't Appear on PR**:
1. Ensure workflow ran on the PR (check Actions tab)
2. Verify job names match exactly (case-sensitive)
3. Check workflow trigger includes `pull_request`

**If Workflow Fails**:
1. Check GATE_BASE_URL / OTLP_HTTP variables (optional)
2. Review workflow logs for k6/trace errors
3. Verify self-contained components (http-server, collector)

---

## 📚 Reference

**Workflow**: `.github/workflows/gate-site-evidence.yml`  
**Workflow runs**: https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/gate-site-evidence.yml  
**Historical evidence run id** (may 404): `18463803215`  
**Gate Criteria**: `docs/BossCat/GATE_CRITERIA.md`  
**Site Criteria**: `docs/BossCat/SITE_CRITERIA.md`  
**BossCat Log**: `docs/BossCat/BOSSCAT_LOG.md` (GREEN entry)

---

**Authority**: BossCat OEM  
**Seal**: 🐾 cursor{implementer}  
**Status**: Optional enhancement — Apply when ready

---

**TL;DR**: Gate/site evidence is GREEN and working. To enforce 5/5 PASS on PRs, add the three checks to branch protection via Settings → Branches → main.

