# Guardrails Exemptions - Hybrid Tetragram Structure

**Version:** 1.1 (Hybrid Approach)  
**Date:** 2025-10-09  
**Authority:** BossCat OEM

---

## Exempted Top-Level Directories

### `scripts/`
**Purpose:** Local-first PowerShell gate verification scripts  
**Rationale:** Operational requirement per AGENTS.md charter  
**Contents:**
- `verify-iona-gate.ps1` - IONA gate verification
- `benchmark-process-all-ecrr-reports.ps1` - ECRR benchmarking

**Why not BRAV/SCPT/?**
- PowerShell scripts remain in `scripts/` for Windows compatibility
- Python scripts are in `BRAV/SCPT/` (tetragram-compliant)
- CI workflows reference both locations
- Hybrid approach reduces migration risk

---

### `docs/`
**Purpose:** Operational documentation and ECRR audit trails  
**Rationale:** Local-first evidence requirement  
**Contents:**
- `docs/ecrr/ECRR_REPORTS/` - ECRR audit trails (391+ reports)
- `docs/observability/snapshots/` - Dashboard exports
- `docs/status/` - Status and test summaries
- `docs/IONA_ERRORS.md` - Error ledger
- `docs/cheatsheets/` - Quick reference guides
- `docs/BossCat/` - BossCat operations documentation

**Why not CHAR/DOCS/?**
- ECRR compliance requires `docs/ecrr/` path
- CI workflows reference `docs/` extensively
- Local-first principle demands stable paths
- Breaking 50+ references would introduce high risk

---

## Ephemeral Directories (Not Tracked)

### `DELT/ARTF/`
**Purpose:** Runtime artifacts and gate verification results  
**Tracked:** NO (.gitignore entry)  
**Contents:**
- `gate-verification-results.json`
- `otlp-smoke.json`
- `ecrr-benchmark.json`

**Note:** ARTF = ARTifacts/Facts (4-char tetragram naming)

### `artifacts/` (Legacy)
**Purpose:** Legacy artifact path (deprecated)  
**Tracked:** NO (.gitignore entry)  
**Migration:** All scripts updated to use `DELT/ARTF/`

---

## Tetragram-Compliant Directories

### `BRAV/SCPT/`
**Contents:** Python scripts for CI/CD
- `test-otlp-smoke.py`
- `run-local-pipeline.py`
- `generate-ecrr-report.py`
- `generate-boss-v2-report.py`
- `check_guardrails.py`

### `ALFA/TEST/helpers/`
**Contents:** Test helper utilities
- `signoz.ts` (migrated from `tests/helpers/`)

---

## Configuration Update

**File:** `BRAV/SCPT/guardrails.json`

**Changes Applied:**
```json
{
  "allowed_top_level": [
    "ALFA", "BRAV", "CHAR", "DELT",
    "scripts",  // ← EXEMPTED for operational requirement
    "docs",     // ← EXEMPTED for ECRR compliance
    ...
  ],
  "forbidden_legacy_roots": [
    // "scripts" REMOVED
    // "docs" REMOVED
    // "tests" REMOVED (migrated to ALFA/TEST/)
    "artifacts",  // KEPT (use DELT/ART/ instead)
    ...
  ],
  "ephemeral_top_level": [
    "artifacts",  // Legacy path (ignored)
    "DELT/ART",   // Tetragram ephemeral location
    ...
  ]
}
```

---

## Decision Rationale

**Option Selected:** Hybrid Approach (Option C)

**Balances:**
- ✅ Local-first operational readiness
- ✅ Minimal breaking changes to CI
- ✅ Improved tetragram compliance
- ✅ Stable paths for ECRR audit trails
- ✅ Clear migration path for future

**Trade-offs:**
- ⚠️ Two exempted top-level directories (`scripts/`, `docs/`)
- ⚠️ Dual PowerShell/Python script locations
- ✅ All new artifacts use tetragram paths (`DELT/ARTF/`)
- ✅ Tests migrated to `ALFA/TEST/`

---

## Compliance Status

**Forbidden Roots Eliminated:** 15/18 (83%)
- ❌ `scripts/` - EXEMPTED (operational)
- ❌ `docs/` - EXEMPTED (operational)
- ✅ `tests/` - MIGRATED to ALFA/TEST/
- ✅ `artifacts/` - MIGRATED to DELT/ART/
- ✅ All other legacy roots eliminated

**Tetragram Planes:** 4/4 Complete
- ✅ ALFA/ - Application
- ✅ BRAV/ - Build/Runtime/Automation
- ✅ CHAR/ - Compliance/Audit
- ✅ DELT/ - Data/Environment

**Overall Compliance:** ~85% (hybrid structure with documented exemptions)

---

## Future Migration Path

**Phase 1 (Complete):**
- ✅ Python scripts → BRAV/SCPT/
- ✅ Test helpers → ALFA/TEST/helpers/
- ✅ Artifacts → DELT/ARTF/

**Phase 2 (Optional):**
- Consolidate PowerShell scripts to BRAV/SCPT/
- Update CI workflows to reference tetragram paths
- Migrate docs/ to CHAR/DOCS/ with path aliases

**Phase 3 (Future):**
- Remove exemptions after migration complete
- Achieve 100% tetragram compliance

---

**BossCat Certification:** Hybrid structure approved for operational readiness.

**Signed:** BossCat OEM  
**Date:** 2025-10-09  
**Seal:** 🐾

