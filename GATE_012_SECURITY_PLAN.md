# Gate #012 - Security Remediation Plan

**Authority:** BossCat OEM  
**Date:** 2025-10-25  
**Gate:** #012  
**Purpose:** Eliminate Dependabot vulnerabilities (1 critical, 3 high, 3 moderate)

---

## Scope

**Mode:** Human-run security gate with ECRR discipline  
**Lane:** Security remediation (DOCS lane for evidence)  
**Budgets:** ≤2 jobs, ≤10 files, ≤200 LOC per job

---

## Job S1 - Dependency Safety Upgrades

**Goal:** Eliminate critical/high vulnerabilities via patch/minor updates

**Scope:**
- `package.json`
- `pnpm-lock.yaml`
- Build scripts with pinned versions

**Steps:**
1. Generate audit baseline: `pnpm audit --json > artifacts/security/pnpm-audit-before-$(date +%Y%m%d).json`
2. Apply patch/minor updates only (no breaking majors)
3. Rebuild and test
4. Generate audit after: `pnpm audit --json > artifacts/security/pnpm-audit-after-$(date +%Y%m%d).json`

**Success Criteria:**
- Critical: 1 → 0
- High: 3 → 0 (or reduced with justification)
- Exit code: 0

**Files:** ≤6  
**LOC:** ≤200

---

## Job S2 - Container Base Refresh

**Goal:** Update container base images and reduce moderate vulnerabilities

**Scope:**
- `Dockerfile*`
- Base image tags/digests
- OS package sets

**Steps:**
1. Pin base images to patched digests
2. Minimize packages (--no-install-recommends)
3. Clear apt caches
4. Scan containers locally
5. Attach scan reports as evidence

**Success Criteria:**
- Critical: 0
- High: 0
- Moderate: Documented with justification
- Exit code: 0

**Files:** ≤6  
**LOC:** ≤200

---

## Evidence Requirements

**Artifacts:**
- `artifacts/security/pnpm-audit-before-*.json`
- `artifacts/security/pnpm-audit-after-*.json`
- `artifacts/security/container-scan-*.txt`
- `GATE_012_SECURITY_EVIDENCE.md`

**Tests:**
- Changed-paths tests only
- Gate verification scripts
- No regression in existing functionality

---

## Gate Signal (When Complete)

```
@cat ready-for-gate : #012

Status: GREEN
Evidence: GATE_012_SECURITY_EVIDENCE.md
Security: critical=0, high=0 (post-remediation)
Budgets: OK
ECRR: COMPLETE
```

---

## Governance

- ✅ Single-writer lock
- ✅ Lane/budget enforcement
- ✅ Exit codes (0/50/51/52/53)
- ✅ ECRR artifacts
- ✅ Human-gated merge (PR with status checks)

---

**Status:** Plan prepared, awaiting BossCat OEM GO for execution

**Cursor{Implementer}**

