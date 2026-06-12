# Commit Strategy - PR #942 Migration

**Date:** 2026-01-23  
**Status:** Ready for commit

---

## Recommended Commit Plan

### ✅ Commit 1: PR #942 Migration Implementation

**Files to add:**
```bash
git add viz-engine-projectm/CMakeLists.txt
git add viz-engine-projectm/gl_proc_resolver.cpp
git add viz-engine-projectm/gl_proc_resolver.hpp
git add viz-engine-projectm/gl_diagnostics.cpp
git add viz-engine-projectm/projectm_renderer.cpp
git add viz-engine-projectm/projectm_renderer.hpp
git add viz-engine-projectm/projectm-smoke-test.cpp
git add viz-engine-projectm/Dockerfile  # (modified)
```

**Documentation files:**
```bash
git add viz-engine-projectm/GLAD_SYMBOL_CONFLICT_PREVENTION.md
git add viz-engine-projectm/GLEW_GLAD_INVENTORY.md
git add viz-engine-projectm/PR_942_API_NOTES.md
git add viz-engine-projectm/PR_942_MIGRATION_COMPLETE.md
git add viz-engine-projectm/README_PR_942.md
```

**Commit message:**
```
feat(projectm): PR #942 migration - resolver-aware API integration

- Implement GL proc resolver (GLX/SDL/EGL support)
- Add projectM library integration wrapper
- Wire resolver-aware projectm_create_with_opengl_load_proc()
- Add smoke test with preset directory detection
- Update Dockerfile to fetch PR #942 branch
- Add CMakeLists.txt for native component builds
- Comprehensive documentation and diagnostics

ECRR: BossCat OEM | Executor: Cursor{Implementer}
Status: Integration complete, pending build/runtime validation
```

---

### ⚠️ Commit 2: Gate Artifacts (Optional - Evidence Trail)

**Decision needed:** Should gate verification artifacts be committed?

**Modified gate files:**
- `PR_COMMENT_IONA_GATE_002_FINAL.md` (modified)
- `docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md` (modified)

**New gate artifacts:**
- `artifacts/gate-verification-results.json` (auto-generated)
- `artifacts/canary-ecrr-report.txt` (evidence)
- `docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_20260123_141312.md` (timestamped ECRR)
- `docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_20260123_141631.md` (timestamped ECRR)

**Analysis:**
- `.gitignore` allows `artifacts/**/*.json` and `artifacts/**/*.txt` (exceptions)
- ECRR reports in `docs/ecrr/ECRR_REPORTS/` are typically tracked (evidence trail)
- Gate verification results are auto-generated and frequently updated
- PR comment templates are operational artifacts

**Recommendation:**
- ✅ **Commit:** ECRR reports (`docs/ecrr/ECRR_REPORTS/*.md`) - These are evidence artifacts
- ❓ **Optional:** `PR_COMMENT_IONA_GATE_002_FINAL.md` - PR comment template (operational)
- ❌ **Skip:** `artifacts/gate-verification-results.json` - Auto-generated, frequently updated
- ❓ **Optional:** `artifacts/canary-ecrr-report.txt` - Evidence, but in artifacts/ (check if needed)

**If committing gate artifacts:**
```bash
# ECRR reports (evidence trail)
git add docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_20260123_*.md
git add docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md

# PR comment (if keeping as template)
git add PR_COMMENT_IONA_GATE_002_FINAL.md

# Canary report (if evidence needed)
git add artifacts/canary-ecrr-report.txt
```

**Commit message (if used):**
```
docs(ecrr): Gate verification evidence - 2026-01-23

- Update ECRR_GATE_RUN_LATEST.md with latest gate run
- Add timestamped ECRR reports for gate verification
- Update PR comment template with gate results

ECRR: BossCat OEM | Gate: IONA | Site: ci | Verdict: READY
```

---

## Alternative: Separate Commits

If you prefer to keep gate artifacts separate:

```bash
# Commit 1: PR #942 implementation only
git add viz-engine-projectm/*.cpp viz-engine-projectm/*.hpp viz-engine-projectm/*.md viz-engine-projectm/CMakeLists.txt viz-engine-projectm/Dockerfile
git commit -m "feat(projectm): PR #942 migration - resolver-aware API integration"

# Commit 2: Gate artifacts (if desired)
git add docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_*.md PR_COMMENT_IONA_GATE_002_FINAL.md
git commit -m "docs(ecrr): Gate verification evidence - 2026-01-23"
```

---

## Recommendation Summary

1. **✅ Definitely commit:** All PR #942 migration files (12 files)
2. **✅ Commit:** ECRR reports (evidence trail)
3. **❓ Optional:** PR comment template (operational artifact)
4. **❌ Skip:** `artifacts/gate-verification-results.json` (auto-generated, frequently updated)

**Suggested approach:** Two commits - one for PR #942 implementation, one for gate evidence (if keeping evidence).
