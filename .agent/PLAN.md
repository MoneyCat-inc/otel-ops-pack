# Gate #018 — Security Remediation Plan

**Authority:** BossCat OEM  
**Date:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Gate Type:** Security Remediation  
**Status:** 🔵 **IN PROGRESS**

---

## 🎯 Goal

Clear 2 Dependabot alerts (1 high, 1 moderate) without functional drift. Pin images/actions to safe versions. Produce before/after evidence. Two small jobs under budgets, ECRR trail complete, human-gated merge only.

**Target State:**
- critical = 0
- high = 0  
- moderate = 0 or documented with justification

**Success Criteria:**
- No test regressions
- Budgets respected (≤2 jobs, ≤10 files, ≤200 LOC per job)
- Complete evidence trail
- Human-gated merge only

---

## 📊 Lane & Scope

**Lane:** `security/*` and build/config files only  
**Scope:**
- `package.json` / lockfiles
- `Dockerfile*`
- `.github/workflows/**`
- Build scripts that pin versions

**Out of Scope:**
- Functional changes
- Feature additions
- Non-security refactoring

---

## 🔒 Budgets & Guardrails

**Budgets:**
- ≤ **2 jobs** (SR1: Dependencies, SR2: Supply-chain)
- ≤ **10 files** total
- ≤ **200 LOC per job**
- Single-writer lock
- Exit codes: 0/50/51/52/53
- Bots do **NOT** merge

**Two-Agent Discipline:**
- A (Implementer) writes
- B (Balancer) verifies (read-only)
- B never acquires locks or writes

**Stability Pack:**
- Human-gated merge required
- Branch protection enforced
- PR + required status checks

---

## 🔧 Job Breakdown

### Job SR1 — Dependency Remediation *(≤200 LOC, ≤6 files)*

**Scope:** Code/build dependencies  
**Files:** `package.json`, lockfile(s), build scripts

**Steps:**
1. Run audit **before** → save `audit-before.json`
2. Apply **patch/minor** upgrades (no breaking majors) to clear **high**
3. Evaluate **moderate** (upgrade if safe)
4. Rebuild and run changed-paths tests only
5. Run audit **after** → save `audit-after.json`

**Acceptance:**
- `critical=0`, `high=0`
- `moderate=0` **OR** justified in `SECURITY_NOTES.md` (CVE + reason + mitigation)
- No test regressions
- Budgets/process respected

---

### Job SR2 — Supply-Chain Hardening *(≤200 LOC, ≤6 files)*

**Scope:** Containers & CI

**Containers:**
- Pin base images to immutable **digests**
- Minimize OS packages
- Clear caches

**CI/CD:**
- Pin actions to stable tags/SHAs
- Tighten `permissions` (default `contents:read`, raise per-job only as needed)
- Record **branch-protection** snapshot (PR required + checks)

**Artifacts:**
- Container scan report (before/after)
- Base image digests list
- Branch protection proof

**Acceptance:**
- No new critical/high in runtime images or CI surface
- Branch-protection verified & recorded
- Budgets/process respected

---

## 📂 Evidence Package

**Required Artifacts:**

1. **`.agent/EVIDENCE.log`** — Complete execution trail:
   - `plan → preflight → lock → edit → test → report → exit`

2. **`GATE_018_SECURITY_EVIDENCE.md`** — Summary document:
   - Before→After table
   - Diffs
   - `audit-before.json`
   - `audit-after.json`
   - `base-image-digests.txt`
   - `scan-before.md`
   - `scan-after.md`
   - `bp-proof.png` (branch-protection snapshot)

3. **(Optional)** Synthetic trace:
   - `gate.018.security` tagged `deployment.environment=staging`
   - Dashboard screenshot attached

---

## 🚦 Gate Hand-Off Signal

**Post when evidence is complete:**

```
@cat ready-for-gate : #018

Status: GREEN
Evidence: GATE_018_SECURITY_EVIDENCE.md
Security: critical=0, high=0; moderate=0 or justified
Artifacts: audit-before.json, audit-after.json, base-image-digests.txt, scan-before.md, scan-after.md, bp-proof.png
Budgets: OK
ECRR: COMPLETE
```

---

## 🏷️ Post-Approval Admin

**Tag:** `gate-018-green-2025-10-26`
- Annotate with remediation commit + evidence paths

**BOSSCAT_LOG:** One-liner acceptance entry

---

## 📋 Parallel Housekeeping (Low-Risk, Doc-Only)

**P2 — Archive Gate #016:**
- Move to `docs/archive/gates/2025-10/016/`
- Update index
- Commit in DOCS lane (≤1 file move list + index)

**P3 — Progress Indicator Script:**
- Add `scripts/progress-indicators.ps1` in future cosmetic gate
- Keep separate from security scope

---

## 🛡️ Exit Criteria

**GREEN (Exit 0):**
- critical = 0
- high = 0
- moderate = 0 or documented
- Evidence complete
- Budgets respected
- ECRR trail complete

**FAIL (Exit 51):**
- Budgets exceeded
- Process violations

**BLOCKED (Exit 52):**
- Cannot clear critical/high
- Breaking changes required

---

**Status:** 🔵 IN PROGRESS  
**Start:** 2025-10-26  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM directive

---

🐾 *Security remediation in progress. Stability Pack guardrails enforced.*
