# ADR-0001: Tetragram Repository Structure Baseline

**Date:** 2025-10-09  
**Status:** Accepted ✅  
**Decision Makers:** BossCat OEM  
**Gate Approval:** GATE-2025-10-09-001

---

## Context

The Resonai [OTel] repository had grown organically with 17+ forbidden legacy root directories (scripts/, docs/, config/, docker/, helm/, etc.), creating:
- Navigation difficulty
- Ownership ambiguity
- Structural drift
- No enforcement mechanism
- Inconsistent organization

**Problem Statement:** Need a predictable, governed, and scalable repository structure that prevents drift and clearly separates concerns.

---

## Decision

Adopt the **tetragram (4-plane) structure** with **ALFA/BRAV/CHAR/DELT** top-level organization and enforce **4-letter uppercase subdirectory naming** within each plane.

### The Four Planes

```
ALFA/  Application
  - SRCE, TEST, TOOL, OTEL, APPS, LIBS, CORE, INST
  - All application code, tests, tooling, instrumentation

BRAV/  Build/Runtime/Automation/Verification
  - SCPT, INFR, DOCK, CICD, HOOK, BUIL
  - Scripts, infrastructure, CI/CD, Docker, build automation

CHAR/  Compliance/Human/Audit/Review
  - DOCS, EVID, AUDT, REPO, RUNB, PRSV, ECRR
  - Documentation, evidence, audit trails, reports

DELT/  Data/Environment/Load/Test
  - CONF, ASST, FIXT, LOAD, TMPL, META, SECR, OVER, BASE
  - Configurations, fixtures, templates, test data
```

### Enforcement Mechanism

**Guardrails:**
- Python validator (`BRAV/SCPT/check_guardrails.py`)
- JSON rules (`BRAV/SCPT/guardrails.json`)
- CI workflow (`.github/workflows/guardrails.yml`)
- Required check on main branch

**4-Letter Naming:**
- All plane subdirectories must be exactly 4 characters
- UPPERCASE alphabetic only
- Must be in the allowed set for that plane
- Prevents arbitrary nesting and drift

---

## Alternatives Considered

### Alternative 1: Keep Current Structure
**Pros:** No migration effort  
**Cons:** Continued drift, no governance, growing complexity  
**Rejected:** Unsustainable long-term

### Alternative 2: Domain-Driven Structure
**Example:** `services/`, `shared/`, `infrastructure/`, `docs/`  
**Pros:** Familiar pattern  
**Cons:** Ambiguous boundaries, no enforcement, scales poorly  
**Rejected:** Insufficient structure for observability operations

### Alternative 3: Monorepo Tools (Nx, Turborepo)
**Pros:** Built-in tooling  
**Cons:** Opinionated structure, migration complexity, tooling lock-in  
**Rejected:** Tetragram provides structure without tool dependency

### Alternative 4: Flat Structure
**Pros:** Simple  
**Cons:** Doesn't scale, no separation of concerns  
**Rejected:** Already outgrown this

---

## Rationale

### Why Tetragram?

**1. Clear Separation of Concerns:**
- Application code (ALFA) separate from automation (BRAV)
- Documentation/evidence (CHAR) separate from configs (DELT)
- Each plane has a distinct purpose

**2. Predictable Navigation:**
- 4-letter naming makes structure memorable
- Limited depth prevents over-nesting
- Consistent patterns across all planes

**3. Enforced Governance:**
- Automated guardrails prevent drift
- CI enforcement blocks non-compliant changes
- CODEOWNERS routes reviews by plane

**4. Scalable:**
- Can add new 4-letter subdirs within planes as needed
- Structure accommodates growth
- Doesn't require restructuring as repo evolves

**5. Language-Agnostic:**
- Works for any tech stack
- Doesn't impose language-specific conventions
- Flexible within planes

### Why 4-Letter Naming?

**Memorability:** Easy to remember, type, and reference  
**Consistency:** Uniform across all planes  
**Discoverability:** Tab completion friendly  
**Constraint:** Prevents arbitrary nesting and long names  
**Predictability:** Know what to expect in each plane

---

## Migration Execution

### Phases

| Phase | Scope | Result |
|-------|-------|--------|
| B.1 | Scripts | scripts/ → BRAV/SCPT/ |
| B.2 | Configs/Infra/Assets | 12 dirs → DELT/BRAV/CHAR |
| D | Documentation | docs/, archive/, backups/ → CHAR |
| C | Source Code | tests/, tools/, synthetic/ → ALFA |

**Total:** 19 directories migrated, 6,000+ files reorganized

### Critical Learning: Git Junctions

**Issue:** Windows junctions (mklink /J) committed as full directory trees with core.symlinks=false  
**Resolution:** Removed duplicates, used pure `git mv` without junctions  
**Lesson:** Don't use directory junctions for Git-tracked migrations

---

## Consequences

### Positive

✅ **Clear Structure:** Everyone knows where to find things  
✅ **Enforced Compliance:** Guardrails prevent drift  
✅ **Ownership Clear:** CODEOWNERS by plane  
✅ **Scalable:** Can grow without restructuring  
✅ **Professional:** Evidence-based, governed approach  
✅ **Zero Forbidden Roots:** 100% elimination achieved

### Negative (Mitigated)

⚠️ **Learning Curve:** Team needs to learn new structure  
_Mitigation: Comprehensive documentation, README updates_

⚠️ **Import Path Updates:** Some imports may need updating  
_Mitigation: TypeScript path aliases, gradual updates_

⚠️ **Build Config Changes:** Some tools need path updates  
_Mitigation: Small, tested changes with evidence_

### Neutral

↔️ **30 Unauthorized Directories Remain:** Application code not yet in ALFA  
_Plan: Optional Phase C.4 for incremental migration_

---

## Compliance & Governance

### Required

- ✅ Guardrails workflow must pass on all PRs to main
- ✅ 4-letter naming enforced for all plane subdirectories
- ✅ No reintroduction of forbidden legacy roots
- ✅ CODEOWNERS reviews by plane
- ✅ ECRR framework for all structural changes

### Monitoring

**Daily:** CI checks all PRs  
**Weekly:** Review unauthorized directory count  
**Monthly:** Audit for new patterns, refine rules

---

## Rollback Plan

**If tetragram structure needs to be reverted:**

```bash
# Identify consolidation merge commit
git log --grep="Tetragram consolidation"

# Revert the merge
git revert -m 1 <merge_commit_sha>
git push

# Or selective revert of specific migrations
git revert <commit_sha>
```

**Risk:** Low - all changes are pure `git mv`, reversible  
**Evidence:** Complete history in CHAR/EVID/ for reconstruction

---

## Future Evolution

### Phase C.4 (Optional - Application Code)
- Migrate app/, apps/, components/, lib/, pages/ to ALFA
- Add TypeScript path aliases (@alfa, @brav, @char, @delt)
- Gradual import updates

### Ongoing Refinement
- Extract workflow logic to BRAV/SCPT
- Organize remaining infrastructure dirs
- Clean up experimental/obsolete directories
- Refine allowed_top_level for intentional exceptions

---

## References

**Governance:**
- AGENTS.md - BossCat charter
- ART_OF_ECRR.md - ECRR methodology
- CODEOWNERS - Ownership matrix

**Migration:**
- CHAR/EVID/BOSSCAT_GATE_APPROVAL.md - Official approval
- FORBIDDEN_ROOTS_ELIMINATED.md - Achievement summary
- GATE_VERIFIED_NEXT_STEPS.md - Post-gate roadmap

**Tools:**
- BRAV/SCPT/guardrails.json - Rules
- BRAV/SCPT/check_guardrails.py - Validator
- BRAV/SCPT/README_NEXT_STEPS.md - Migration guide

---

## Success Criteria - All Met ✅

- [x] Zero forbidden legacy roots (17 → 0)
- [x] Tetragram structure established
- [x] Guardrails enforced via CI
- [x] 4-letter naming enforced
- [x] Evidence comprehensive
- [x] Git tracking clean
- [x] Gate approved
- [x] Baseline tagged
- [x] Team documentation complete

---

## Approval

**Decision:** APPROVED  
**Status:** IMPLEMENTED  
**Gate:** PASSED (GATE-2025-10-09-001)  
**Tag:** tetragram-baseline-1.0  

**Approved By:** BossCat OEM, Executive Overseer  
**Date:** 2025-10-09  
**Supersedes:** All previous repository organization approaches

---

🐾 **This ADR establishes the tetragram structure as the official baseline for Resonai [OTel] effective immediately.**

---

_ADR-0001: Tetragram Repository Structure Baseline_  
_Status: Accepted and Implemented_  
_Last Updated: 2025-10-09_

