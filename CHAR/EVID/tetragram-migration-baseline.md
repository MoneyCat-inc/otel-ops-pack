# 🐾 BossCat Tetragram Migration - Baseline Evidence

**Date:** 2025-10-09  
**Executor:** BossCat OEM  
**Purpose:** Establish pre-migration baseline for repository structure compliance

---

## Executive Summary

**Current Compliance Status:** ❌ **NON-COMPLIANT**

The repository requires migration to tetragram structure (ALFA/BRAV/CHAR/DELT) according to BossCat governance framework.

### Key Metrics

| Metric | Count | Status |
|--------|-------|--------|
| Forbidden Legacy Roots | 17 | ❌ Must migrate |
| Unauthorized Top-Level Dirs | 54 | ❌ Must organize |
| Paths Exceeding Max Depth | 136 | ⚠️ Mostly in venv |
| Non-Compliant Workflows | 44 | ⚠️ Extract to BRAV/SCPT |

---

## Detailed Findings

### ❌ Forbidden Legacy Root Directories (17)

These directories violate tetragram structure and must be migrated:

1. `archive/` → CHAR/EVID/archive/
2. `artifacts/` → CHAR/EVID/artifacts/
3. `assets/` → DELT/ASST/assets/
4. `backups/` → CHAR/EVID/backups/
5. `baseline/` → DELT/FIXT/baseline/
6. `config/` → DELT/CONF/config/
7. `configs/` → DELT/CONF/configs/
8. `deployment-pipeline/` → BRAV/INFR/deployment-pipeline/
9. `docker/` → BRAV/DOCK/legacy/
10. `docs/` → CHAR/DOCS/
11. `helm/` → BRAV/INFR/helm/
12. `playwright-report/` → CHAR/EVID/playwright-report/
13. `reports/` → CHAR/EVID/reports/
14. `scripts/` → BRAV/SCPT/
15. `synthetic/` → DELT/LOAD/synthetic/
16. `tests/` → ALFA/TEST/ or DELT/FIXT/
17. `tools/` → BRAV/SCPT/tools/

### ⚠️ Unauthorized Top-Level Directories (54)

Additional directories requiring categorization and migration:

**Hidden/Config dirs (.cursor, .vscode, .artifacts, .tmp):**
- May be exempted or cleaned up
- Not part of core tetragram structure

**Application code (app/, apps/, components/, lib/, pages/):**
- Migrate to ALFA/CORE/ or ALFA/APPS/

**Infrastructure (codex/, collector/, cuda/, gpu/, sidecars/):**
- Migrate to BRAV/INFR/ or DELT/CONF/

**Data/Test (experiments/, test-payloads/, test-results/, validation/):**
- Migrate to DELT/FIXT/ or DELT/LOAD/

**Build artifacts (out/, preview/):**
- Clean up or move to CHAR/EVID/

**Documentation stubs (comfort-cat-stubs/, visual-assets-draft/):**
- Consolidate to CHAR/DOCS/

**Upstream/Patches (patches/, upstream-contribution/):**
- Migrate to BRAV/INFR/upstream/ or CHAR/DOCS/

Full list available in guardrails output.

### 📏 Path Depth Violations (136)

Most violations are in Python virtual environments:
- `experiments/codex-local-logfilter/.venv/` - 126+ deep paths
- These are acceptable as they're in exempted directories

**Action:** Add `.venv` and virtual environment dirs to exemptions.

### 🔄 Workflow Recommendations (44)

Many GitHub workflows contain inline logic that could be extracted to `BRAV/SCPT/` scripts:

**Security Scanning (15 workflows):**
- apisec-scan, codeql, defender-for-devops, devskim, fortify, gitleaks, etc.
- Extract common scanning logic to `BRAV/SCPT/security/`

**BossCat/ECRR (8 workflows):**
- boss-gate-*, bosscat-*, ecrr-compliance, iona-gate-verify
- Already reference BRAV/SCPT in some cases

**SigNoz/Observability (7 workflows):**
- signoz-*, nightly-dashboard-*
- Extract to `BRAV/SCPT/observability/`

**Testing (5 workflows):**
- stress-test-*, nightly-gpu-smoke, nightly-tetragrammaton-benchmarks
- Extract to `BRAV/SCPT/testing/`

**Other (9 workflows):**
- CI, powershell, main, repository-security-check, etc.

---

## Migration Plan

### Phase B.1: Scripts (Immediate)
**Target:** `scripts/` → `BRAV/SCPT/`  
**Method:** `bash BRAV/SCPT/migrate_scripts.sh`  
**Shim:** Yes (scripts → BRAV/SCPT symlink)  
**Effort:** 1 PR

### Phase B.2: Configs/Infra/Assets (Week 1)
**Targets:**
- `config/`, `configs/` → `DELT/CONF/`
- `docker/` → `BRAV/DOCK/legacy/`
- `helm/`, `deployment-pipeline/` → `BRAV/INFR/`
- `artifacts/`, `reports/`, `playwright-report/` → `CHAR/EVID/`
- `assets/`, `baseline/`, `test-payloads/` → `DELT/ASST/`, `DELT/FIXT/`
- `templates/` → `DELT/TMPL/`

**Method:** `bash BRAV/SCPT/migrate_configs.sh`  
**Shim:** Yes (junctions for each)  
**Effort:** 1-2 PRs

### Phase C: Source Code (Week 2-3)
**Targets:**
- `app/`, `apps/`, `components/`, `lib/`, `pages/` → `ALFA/`
- Requires import path rewrites
- Break into multiple PRs by module

**Effort:** 3-5 PRs

### Phase D: Documentation (Week 3)
**Target:** `docs/` → `CHAR/DOCS/`  
**Method:** Manual migration with reference updates  
**Effort:** 1-2 PRs

### Phase E: Cleanup (Week 4)
**Tasks:**
- Remove shims after 2 green CI cycles
- Clean up unauthorized directories
- Update exemptions for acceptable items (.vscode, node_modules, etc.)
- Final guardrails validation

**Effort:** 1 PR

---

## Success Criteria

### Gate Approval Requirements

✅ **Structure Compliance:**
- [ ] All forbidden legacy roots removed
- [ ] Top-level limited to ALFA/BRAV/CHAR/DELT + standard files
- [ ] Path depth violations resolved (excluding exemptions)
- [ ] Guardrails check: **GREEN**

✅ **CI/CD Stability:**
- [ ] All workflows updated to new paths
- [ ] 2+ consecutive green CI/CD cycles
- [ ] No path-related errors in logs

✅ **Evidence & Documentation:**
- [ ] Migration evidence captured in CHAR/EVID/
- [ ] Pathmap updated and validated
- [ ] Documentation references updated
- [ ] ECRR report generated

✅ **Governance:**
- [ ] CODEOWNERS enforced
- [ ] PR template used for all migrations
- [ ] BossCat approval obtained

---

## Risk Assessment

### Low Risk
- Phase B.1 (scripts) - shims ensure backward compatibility
- Phase B.2 (configs) - junctions prevent breakage

### Medium Risk
- Phase C (source code) - requires import path rewrites
- Workflow updates - must coordinate across many files

### Mitigation
- Small PRs (≤10 files, ≤200 LOC non-move changes)
- Validation window (2 green cycles before shim removal)
- Roll-forward strategy (no rollbacks, fix forward)
- Comprehensive testing at each phase

---

## Timeline Estimate

| Phase | Duration | PRs | Effort |
|-------|----------|-----|--------|
| B.1 Scripts | 1 day | 1 | Low |
| B.2 Configs | 2-3 days | 1-2 | Medium |
| C Source | 1-2 weeks | 3-5 | High |
| D Docs | 2-3 days | 1-2 | Low |
| E Cleanup | 1-2 days | 1 | Low |
| **Total** | **3-4 weeks** | **7-11** | **Medium-High** |

With parallel work and automation, can compress to 2-3 weeks.

---

## Next Immediate Actions

1. **Review and approve this baseline** ✅
2. **Execute Phase B.1:** `bash BRAV/SCPT/migrate_scripts.sh`
3. **Create PR** with ECRR evidence
4. **Verify CI green** with shims in place
5. **Begin Phase B.2** after B.1 merges

---

## Evidence Artifacts

### Generated by This Assessment
- `BRAV/SCPT/guardrails.json` - Guardrails configuration
- `BRAV/SCPT/check_guardrails.py` - Validation tool
- `.github/workflows/guardrails.yml` - CI enforcement
- `BRAV/SCPT/migrate_scripts.sh` - Phase B.1 automation
- `BRAV/SCPT/migrate_configs.sh` - Phase B.2 automation
- `BRAV/SCPT/cleanup_shims.sh` - Post-validation cleanup
- `CODEOWNERS` - Governance ownership map
- `.github/pull_request_template.md` - ECRR PR template
- `BRAV/SCPT/README_NEXT_STEPS.md` - Migration guide
- `CHAR/EVID/tetragram-migration-baseline.md` - This document

### Command to Reproduce
```bash
python3 BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json
```

### Raw Output
See terminal output above (exit code: 1, non-compliant as expected)

---

## Approval

**Status:** 🔄 **AWAITING BOSSCAT REVIEW**

**BossCat Signature:** _________________________  
**Date:** _________________________

**Command to proceed:**
```bash
@cat ready-for-phase-b1
```

---

*Generated by: BossCat OEM Governance Framework*  
*Tool Version: guardrails.py v1.0.0*  
*Timestamp: 2025-10-09*

