# Follow-Up: Enable Blocking SBOM for Prod Gate

**Authority**: BossCat OEM  
**Prerequisite**: 3 successful prod gate runs with SBOM generation  
**Status**: ⏳ PENDING EVIDENCE

---

## Purpose

Make SBOM generation **mandatory** for prod gate after verifying stability over 3+ successful runs.

---

## Prerequisites (Evidence-Based Gate)

**Required Evidence** (collect from prod gate runs):

- [ ] **Run 1**: SBOM generated successfully at `DELT/ARTF/sbom.json`
- [ ] **Run 2**: SBOM generated successfully at `DELT/ARTF/sbom.json`
- [ ] **Run 3**: SBOM generated successfully at `DELT/ARTF/sbom.json`

**Success Criteria**:
- ✅ SBOM generation succeeds (no tooling errors)
- ✅ Checksums generate successfully (.sha256 files present)
- ✅ Artifacts upload to GitHub Actions (90-day retention)
- ✅ CI logs show: "✅ SBOM ready for upload at DELT/ARTF/sbom.json"

**Failure Criteria** (do NOT proceed if):
- ❌ SBOM generation fails in any run
- ❌ Checksums missing or invalid
- ❌ Artifact upload failures
- ❌ Path resolution issues

---

## Implementation

### One-Line Change

**File**: `.github/workflows/bosscat-gate-verify.yml`  
**Location**: Line 355 (current)

**Current** (non-blocking for all sites):
```yaml
continue-on-error: true
```

**Proposed** (blocking for prod, non-blocking for ci/local):
```yaml
continue-on-error: ${{ matrix.site != 'prod' }}
```

**Diff**:
```diff
- continue-on-error: true
+ continue-on-error: ${{ matrix.site != 'prod' }}
```

---

## Verification Steps

**After implementing**, verify prod gate behavior:

### Test 1: Prod Gate Success (Expected)
```bash
gh workflow run bosscat-gate-verify.yml -f site=prod -f gate=IONA
```
**Expected**: Gate passes, SBOM uploaded

### Test 2: Simulate SBOM Failure (Optional)
**Method**: Temporarily break Syft path in workflow  
**Expected**: Prod gate **FAILS** (blocking behavior)  
**Action**: Fix and rerun

### Test 3: CI/Local Gates Unaffected
```bash
gh workflow run bosscat-gate-verify.yml -f site=ci -f gate=IONA
```
**Expected**: Gate passes even if SBOM fails (non-blocking)

---

## Rollback Plan

**If blocking SBOM causes issues**:

1. **Immediate**: Revert commit (one-line change)
   ```bash
   git revert <commit-sha>
   git push origin main
   ```

2. **Emergency**: Override in workflow dispatch
   - Add input: `skip_sbom: true`
   - Conditional: `if: matrix.site == 'prod' && !inputs.skip_sbom`

3. **Root Cause**: Investigate Syft tooling, fix issues, re-enable

---

## PR Template

**Title**: `ci(gate): enable blocking SBOM for prod gate (evidence-based ratchet)`

**Body**:
```markdown
## Evidence-Based SBOM Enforcement

**Prerequisite**: 3 successful prod gate runs verified (SBOM generation stable)

### Change
Enable blocking SBOM for prod gate (strict mode alignment).

**File**: `.github/workflows/bosscat-gate-verify.yml` (line 355)

**Before**:
```yaml
continue-on-error: true  # Non-blocking for all sites
```

**After**:
```yaml
continue-on-error: ${{ matrix.site != 'prod' }}  # Blocking for prod, non-blocking for ci/local
```

### Rationale
- Prod = STRICT mode (per governance framework)
- SBOM generation verified stable over 3+ runs
- Supply chain integrity enforced
- Aligns with SLSA Level 3+ best practices

### Evidence
- Run 1: <link to workflow run>
- Run 2: <link to workflow run>
- Run 3: <link to workflow run>

### Rollback
One-line revert if issues arise (documented in FOLLOWUP_SBOM_BLOCKING.md)

### Budget
Files: 1 | LOC: 1 line change | Lane: CI/ops
ECRR: Present (this PR body)
```

**Labels**: `ci`, `ops`, `governance`

---

## Timeline

**Week 1** (Now → +7 days):
- Monitor 3 prod gate runs
- Collect evidence (workflow run links)
- Document success/failure in tracking issue

**Week 2** (+8 days):
- If stable → Create PR with evidence
- If issues → Investigate, fix, restart counter

**Week 3+** (+15 days):
- Merge if approved
- Monitor prod gate post-merge
- Document in next ECRR report

---

## Tracking

**Issue**: Create GitHub issue to track evidence collection  
**Assignee**: cursor{implementer} or designated monitor  
**Milestone**: Gate #007 follow-up (prod hardening)

**Commands**:
```bash
# Create tracking issue
gh issue create \
  --repo MoneyCat-inc/otel-ops-pack \
  --title "Track SBOM stability for prod blocking (3 runs)" \
  --body "See docs/BossCat/FOLLOWUP_SBOM_BLOCKING.md for details" \
  --label "ci,ops,tracking"
```

---

## Notes

- Keep this document in repo for traceability
- Reference in Gate #007 closeout as "deferred hardening"
- Update when evidence collected or decision made
- Align with governance: evidence-based, deterministic, reversible

---

**Status**: ⏳ PENDING EVIDENCE (awaiting 3 successful prod runs)  
**Owner**: cursor{implementer} (or designated)  
**Next Review**: After 3 prod gate runs with SBOM verification

