# SBOM First-Run Triage — Operational Checklist

> **Dated record (post-Gate #007, 2025-10-12) — 2026-09-02 truth pass.** `continue-on-error` now
> sits at line 165 of `bosscat-gate-verify.yml`; `gh workflow run … -f site= -f gate=` will fail
> (the dispatch takes no inputs — site/gate are matrix values); docs-only PRs no longer trigger the
> lane (`paths-ignore` since 2026-09-01). Procedure kept as the first-run record.

**Authority**: BossCat OEM — Operational Readiness  
**Purpose**: Quick triage for SBOM blocking enforcement (now live in prod)  
**Date**: Post-Gate #007 (2025-10-12)

---

## Status: SBOM Blocking LIVE

**As of PR #134 merge** (2025-10-12T22:15:44Z):

- ✅ SBOM generation is **BLOCKING for prod gate**
- ✅ SBOM generation is **non-blocking for ci/local**
- ✅ Enforcement active (line 355: `continue-on-error: ${{ matrix.site != 'prod' }}`)

**Impact**: Next prod PR will **FAIL** if SBOM generation fails

---

## Quick Triage Commands

### 1. Test SBOM Generation Locally

```bash
# Install dependencies (if not already)
pnpm install

# Generate SBOM using Syft
pnpm comp:sbom

# Check where SBOM landed (workflow searches 3 locations)
ls -lh DELT/ARTF/sbom.json 2>/dev/null && echo "✅ Found at canonical location" || \
ls -lh sbom.json 2>/dev/null && echo "⚠️ Found at root (workflow will copy)" || \
ls -lh artifacts/sbom.json 2>/dev/null && echo "⚠️ Found in artifacts/ (workflow will copy)" || \
echo "❌ SBOM not generated — check Syft installation"

# Generate checksums manually (verify workflow behavior)
if [ -f "DELT/ARTF/sbom.json" ]; then
  sha256sum DELT/ARTF/sbom.json
elif [ -f "sbom.json" ]; then
  sha256sum sbom.json
fi

# Check SBOM contents
jq '.components | length' DELT/ARTF/sbom.json 2>/dev/null || \
jq '.components | length' sbom.json 2>/dev/null || \
echo "Cannot read SBOM JSON"
```

---

### 2. Verify Syft Installation

```bash
# Check if Syft is available
which syft || echo "❌ Syft not in PATH"

# Check Syft version
syft version

# Expected: syft 0.x.x or later
```

**If Syft missing**:

```bash
# Install Syft (Linux/macOS)
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Or via package manager
# macOS: brew install syft
# Linux: See https://github.com/anchore/syft#installation
```

---

### 3. Check pnpm comp:sbom Script

```bash
# Verify script exists
cat package.json | jq '.scripts."comp:sbom"'

# Expected: "tsx scripts/comp/syft-sbom.ts" or similar

# Check if script file exists
ls -lh scripts/comp/syft-sbom.ts
```

**If script missing**: Check `scripts/comp/` directory for SBOM generation logic

---

### 4. Monitor Prod Gate Run

**Trigger manually** (if workflow_dispatch available):

```bash
gh workflow run bosscat-gate-verify.yml -f site=prod -f gate=IONA
```

**Or wait for next PR** (automatic trigger on pull_request to main)

**Watch live**:

```bash
gh run watch --exit-status
```

**Check specific run**:

```bash
# List recent runs
gh run list --workflow bosscat-gate-verify.yml --limit 5

# View specific run
gh run view <run_id>
```

---

### 5. Verify SBOM Step Summary

**After prod gate runs**, check GitHub Actions UI:

1. Navigate to: <https://github.com/MoneyCat-inc/otel-ops-pack/actions>
2. Find latest "BossCat Gate Verification" run
3. Check job summary for "📦 SBOM & Supply Chain Artifacts" section

**Expected**:

```markdown
### 📦 SBOM & Supply Chain Artifacts

✅ **SBOM Generated**: `DELT/ARTF/sbom.json`
- **Checksum**: `a1b2c3d4e5f6g7h8...`
- **Size**: 45K

✅ **Signature Registry**: Present

**Artifact**: `sbom-attestation-12345`
**Retention**: 90 days
**Tracking**: Issue #135
```

**If Missing**:

```markdown
⚠️ **SBOM Missing** — Review logs above

**Impact**: Non-blocking for this run (tracking stability)
```

(Note: Should not happen in prod with blocking enforcement)

---

## Rollback Procedure (If Needed)

### If SBOM Fails in Prod Gate

**Symptom**: Prod gate FAILS with SBOM generation error

**Immediate Action** (restore non-blocking):

```bash
# Revert PR #134 merge commit
git revert de2be498

# Or edit workflow directly (faster)
# Change line ~355 in .github/workflows/bosscat-gate-verify.yml:
# From: continue-on-error: ${{ matrix.site != 'prod' }}
# To: continue-on-error: true

git add .github/workflows/bosscat-gate-verify.yml
git commit -m "fix(gate): temporarily restore non-blocking SBOM (tooling issue)

SBOM generation failing in prod gate. Restoring non-blocking behavior while investigating.

Root cause: [TBD - Syft version/path/configuration]
Rollback: Temporary (will re-enable after fix)
ECRR: Incident report required

Files: 1 | Actor: cursor{implementer}"

git push origin main
```

**Rollback Time**: ~5 minutes

---

### Post-Rollback Investigation

**Check**:

1. Syft version compatibility
2. Path resolution logic (3 locations checked)
3. NPM/pnpm package availability
4. Network access (if Syft downloads)
5. File permissions (DELT/ARTF directory)

**Test Locally**:

```bash
# Run full SBOM workflow locally
pnpm comp:sbom

# Check output
find . -name "sbom.json" -type f

# Verify JSON validity
jq . sbom.json | head -20
```

**Fix and Re-Enable**:

- Fix root cause
- Test SBOM generation in dev
- Create PR to re-enable blocking
- Reference this triage doc in ECRR

---

## Issue #135 Monitoring

**Automated Tracking**:

- Tracker workflow runs after each prod gate (success-only)
- Updates Issue #135 automatically
- Shows SBOM status, artifact links, checksums

**Manual Check**:

```bash
# View Issue #135
gh issue view 135 --repo MoneyCat-inc/otel-ops-pack

# Check tracker workflow runs
gh run list --workflow sbom-stability-tracker.yml --limit 5
```

---

## Success Indicators

**First Prod Run** (Critical):

- ✅ SBOM generates without errors
- ✅ Checksums created (SHA256)
- ✅ Artifacts upload successfully
- ✅ Gate passes
- ✅ Step summary shows success
- ✅ Issue #135 auto-updated

**Ongoing** (Week 1-2):

- ✅ Success rate ≥95%
- ✅ No rollback needed
- ✅ Stable SBOM generation
- ✅ Consistent artifact uploads

---

## Failure Indicators

**Watch For**:

- ❌ Prod gate fails with SBOM error
- ❌ "SBOM Missing" in step summary
- ❌ Syft command not found
- ❌ Path resolution issues
- ❌ Checksum generation fails

**If Detected**: Execute rollback procedure above, investigate, fix, re-enable

---

## Commands Cheat Sheet

```bash
# Test SBOM locally
pnpm comp:sbom

# Check Syft
which syft && syft version

# Trigger prod gate (manual)
gh workflow run bosscat-gate-verify.yml -f site=prod -f gate=IONA

# Watch run
gh run watch

# Check Issue #135
gh issue view 135

# Rollback (emergency)
git revert de2be498 && git push origin main

# Or quick fix
# Edit .github/workflows/bosscat-gate-verify.yml line ~355
# Change: continue-on-error: ${{ matrix.site != 'prod' }}
# To: continue-on-error: true
```

---

## References

- **Workflow**: `.github/workflows/bosscat-gate-verify.yml` (lines 314-396)
- **Tracker**: `.github/workflows/sbom-stability-tracker.yml`
- **Script**: `scripts/track-sbom-stability.ps1`
- **Audit Procedure**: `docs/BossCat/SBOM_AUDIT_PROCEDURE.md`
- **Follow-Up Plan**: `docs/BossCat/FOLLOWUP_SBOM_BLOCKING.md`
- **Issue #135**: <https://github.com/MoneyCat-inc/otel-ops-pack/issues/135>

---

## Contact

**Operational Issues**: cursor{implementer} or BossCat OEM  
**ECRR Required**: Any rollback or enforcement failure  
**Tracking**: Automated via Issue #135 (hands-free)

---

**Last Updated**: 2025-10-12 (post-Gate #007 merge)  
**Status**: SBOM blocking LIVE — First-run triage ready

