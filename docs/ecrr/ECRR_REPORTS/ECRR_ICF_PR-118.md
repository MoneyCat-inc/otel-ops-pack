# ECRR — ICF Action Plan: PR #118 Post-Merge Remediation

**Agent:** Cursor{Implementer}
**Date:** 2026-01-14

---


**Agent:** Cursor{Implementer}
**Date:** 2025-12-11

---


**Authority:** cursor{implementer} with BossCat OEM delegation  
**Priority:** P0 (production failures)  
**Date:** 2025-10-12  
**Scope:** Surgical fixes for build/guard failures

---

## 🔍 **Examine**

### PR #118 Context
- **PR:** #118 "Phase 2: Loop-Closing Machine MVP"
- **Merged:** 2025-10-10 23:16:50 UTC (admin override with check failures)
- **Impact:** Failures now in main branch affecting CI/CD pipeline

### Critical Failures Identified

#### 1. **Build Failure: signature-registry.json Path Mismatch**
**Root Cause:** Path inconsistency between generator and consumer scripts

**Analysis:**
```typescript
// gen-signature-registry.ts (line 73)
const outputPath = 'signature-registry.json';  // ❌ writes to root

// js-signature-guard.ts (line 13)
const REGISTRY_PATH = 'signature-registry.json';  // ❌ reads from root

// Actual file location:
ALFA/APPS/signature-registry.json  // ✅ tetragram location
```

**Evidence:**
- `scripts/generate-reference-map.ts` correctly references `ALFA/APPS/signature-registry.json`
- `scripts/classify-run.ts` uses fallback path checking (good pattern)
- Build scripts hardcoded to root path (causing failures)

**Changed Paths:**
- `scripts/build/gen-signature-registry.ts` (1 line)
- `scripts/build/js-signature-guard.ts` (1 line)

#### 2. **Gate Failure: GATE-BETA Monitor** (Non-Critical)
**Status:** Deferred to post-remediation assessment  
**Reason:** Signature registry fix may resolve downstream gate issues

#### 3. **Compliance Failure: Guardrails/Repo Structure** (Non-Critical)
**Status:** Monitoring after registry fix  
**Reason:** May be secondary effect of build failures

---

## 🧹 **Clean**

### Minimal Diff Strategy

**File 1:** `scripts/build/gen-signature-registry.ts`
```diff
- const outputPath = 'signature-registry.json';
+ const outputPath = 'ALFA/APPS/signature-registry.json';
```
**Rationale:** Align output path with tetragram structure  
**Risk:** LOW (file already exists at target location)

**File 2:** `scripts/build/js-signature-guard.ts`
```diff
- const REGISTRY_PATH = 'signature-registry.json';
+ const REGISTRY_PATH = 'ALFA/APPS/signature-registry.json';
```
**Rationale:** Align input path with tetragram structure  
**Risk:** LOW (file exists, scripts in same lane)

**Budget Compliance:**
- Files changed: 2 / 10 ✅
- LOC delta: 2 / 2,000 ✅
- Lanes: COMP (build scripts) ✅
- No workflow YAML changes ✅

---

## 📋 **Report**

### Local Gate Verification
```bash
# Pre-fix state
$ pnpm guard:signatures
❌ signature-registry.json not found

# Post-fix state (expected)
$ pnpm guard:signatures  
✅ Signature registry generated: ALFA/APPS/signature-registry.json

$ pnpm guard:js
✅ All scripts validated against registry
```

### Rollback Plan
```bash
# Single commit revert
git revert <commit-sha>

# Or manual rollback (restore original paths)
# scripts/build/gen-signature-registry.ts: line 73 → 'signature-registry.json'
# scripts/build/js-signature-guard.ts: line 13 → 'signature-registry.json'

# Restore root file if needed
cp ALFA/APPS/signature-registry.json signature-registry.json
```

### Evidence Artifacts
- **Before:** Build scripts fail (signature-registry.json not found)
- **After:** Build scripts succeed (file found at tetragram path)
- **Verification:** `pnpm guard:signatures && pnpm guard:js`

### Test Strategy
1. Run signature generation locally
2. Run signature guard validation
3. Push to PR branch
4. Monitor CI build job
5. If GREEN, human merge per Rule #9

---

## 🎯 **Role**

### Actor Assignments
- **Writer (Agent A):** cursor{implementer} (lane-locked to COMP)
- **Reader (Agent B):** IONA-CATS-GATE-BETA (gate verification, never writes)
- **Approver:** BossCat OEM (human merge after GREEN gates)

### Lane Compliance
- **Lane:** COMP ✅ (build scripts in `scripts/build/`)
- **Allowed Patterns:** `**/*.ts` (TypeScript build scripts) ✅
- **Forbidden:** Workflow YAML changes ❌ (not touched)
- **Budget:** 2 files, 2 LOC (well under 10 files / 2,000 LOC) ✅

### Evidence Trail
- **ECRR:** `docs/ecrr/ECRR_REPORTS/ECRR_ICF_PR-118.md` (this file)
- **BOSSCAT_LOG:** Entry to be added post-merge
- **PR Comment:** `@cat ready-for-gate` to trigger ICF gates

### Authority Chain
1. **BossCat OEM:** P0 remediation approval granted
2. **cursor{implementer}:** Execution authority (writer)
3. **IONA-CATS-GATE-BETA:** Verification authority (reader)

---

## ✅ **Success Criteria**

- [x] Root cause identified (path mismatch)
- [x] Minimal fix designed (2 lines)
- [x] Budget compliance verified (2/10 files, 2/2000 LOC)
- [x] Rollback plan documented
- [ ] Local verification passed
- [ ] PR created with `@cat ready-for-gate`
- [ ] CI gates GREEN
- [ ] Human merge per Rule #9
- [ ] BOSSCAT_LOG updated

---

## 📌 **Deferred Items**

**GATE-BETA Monitor Failure:**
- **Status:** Monitoring post-signature-fix
- **Hypothesis:** May resolve with registry availability
- **Fallback:** Separate minimal PR if persists

**Guardrails/Repo Structure:**
- **Status:** Monitoring post-signature-fix
- **Hypothesis:** Secondary effect of build failures
- **Fallback:** Assess after registry fix merges

---

## 🐾 **BossCat Seal**

**Authority:** cursor{implementer} with BossCat OEM P0 remediation approval  
**Scope:** Surgical (2 files, 2 LOC)  
**Risk:** LOW (path alignment only)  
**Rollback:** Single commit revert  
**Evidence:** ICF ECRR complete (Examine/Clean/Report/Role)

**Status:** ✅ **READY FOR EXECUTION**

---

**Next Step:** Apply fixes, verify locally, push PR, trigger gates.

_End of ICF ECRR Action Plan_


## Report

<!-- Add report/summary details here -->

## Role

<!-- Add role/next actions here -->