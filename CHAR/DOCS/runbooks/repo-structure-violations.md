# Runbook: Repository Structure Violations

**Purpose:** Guide for resolving guardrails violations  
**Owner:** BossCat OEM / DevOps Team  
**Last Updated:** 2025-10-09

---

## Overview

The repository uses automated guardrails to enforce the tetragram (ALFA/BRAV/CHAR/DELT) structure. This runbook explains common violations and how to fix them.

---

## Common Violations

### 1. Forbidden Legacy Root Directory

**Error:**
```
[ERROR] Found N forbidden legacy root directories:
  ❌ scripts/
```

**Meaning:** A directory that should not exist at repository root is present

**Forbidden Roots:**
- scripts/, docs/, config/, configs/
- docker/, helm/, deployment-pipeline/
- artifacts/, reports/, playwright-report/
- assets/, baseline/, test-payloads/, templates/
- tests/, tools/, synthetic/
- archive/, backups/

**Fix:**
```powershell
# These should be migrated to tetragram structure
# Example: scripts/ → BRAV/SCPT/
git mv <forbidden-dir> <appropriate-tetragram-location>
git commit -m "fix(structure): migrate <dir> to tetragram location"
```

**Prevention:** These are in .gitignore; if they reappear, check for:
- Accidental creation
- Incorrect branch merge
- Manual directory creation

### 2. Unauthorized Top-Level Directory

**Error:**
```
[ERROR] Found N unauthorized top-level directories:
  ❌ my-new-feature/
```

**Meaning:** Directory at root that's not in the allowed list

**Allowed at root:**
- ALFA/, BRAV/, CHAR/, DELT/ (planes)
- .github/, .agent/ (special)
- Standard files: README.md, package.json, etc.

**Fix Option 1 - Migrate to appropriate plane:**
```powershell
# Determine which plane this belongs in:
# - Application code → ALFA/
# - Build/automation → BRAV/
# - Documentation → CHAR/
# - Configuration/data → DELT/

git mv my-new-feature ALFA/APPS/my-new-feature
git commit -m "fix(structure): move my-new-feature to ALFA/APPS"
```

**Fix Option 2 - Add to allowed list (if intentional):**
```json
// BRAV/SCPT/guardrails.json
{
  "rules": {
    "allowed_top_level": [
      "ALFA", "BRAV", "CHAR", "DELT",
      "my-new-feature"  // ← Add with justification
    ]
  }
}
```

### 3. Plane Subdirectory Naming Violation

**Error:**
```
[ERROR] Found N plane subdirectory violations:
  ❌ ALFA/my-feature: not 4-char UPPERCASE
```

**Meaning:** Subdirectory doesn't follow 4-letter naming convention

**Rules:**
- Exactly 4 characters
- UPPERCASE only
- Alphabetic only (no numbers/symbols)
- Must be in allowed set for that plane

**Fix:**
```powershell
# Rename to 4-letter UPPERCASE
git mv ALFA/my-feature ALFA/FEAT
# Or move under existing 4-letter dir
git mv ALFA/my-feature ALFA/APPS/my-feature

# Add to allowed set if new category
# Edit BRAV/SCPT/guardrails.json:
# "ALFA": {"SRCE", "TEST", ..., "FEAT"}
```

### 4. Path Depth Exceeded

**Error:**
```
[WARN] Found N paths exceeding max depth:
  ⚠️ ALFA/APPS/my-app/src/components/ui/buttons/primary/variants/large (depth: 11)
```

**Meaning:** Directory nesting too deep (default: 7 levels)

**Fix:**
- Flatten structure
- Move deeply nested items up
- Consider if depth is necessary

**Adjust threshold (if justified):**
```json
// BRAV/SCPT/guardrails.json
{
  "rules": {
    "max_path_depth": 10  // Increase if needed with justification
  }
}
```

---

## Running Guardrails Check

### Local Check
```powershell
python BRAV\SCPT\check_guardrails.py --config BRAV\SCPT\guardrails.json
```

### CI Check
- Runs automatically on all PRs
- Required to pass before merge to main
- Workflow: `.github/workflows/guardrails.yml`

---

## Quick Fixes

### Reset to Baseline
```powershell
# If you have forbidden roots, check which branch you're on
git branch
git checkout main  # Baseline is clean

# If main has issues, check recent commits
git log --oneline -10
```

### Find What Introduced Violation
```powershell
# Find when directory was added
git log --all --full-history -- <directory-name>/

# See what's in it
dir <directory-name>
```

### Emergency Override (Use Sparingly)
If you need to bypass temporarily (testing, emergency):
```powershell
# Skip workflow
git commit --no-verify

# OR adjust guardrails.json temporarily (must revert!)
```

**⚠️ Warning:** Always revert overrides. They defeat the purpose.

---

## Plane Assignment Guide

**Where should new directories go?**

| Content Type | Plane | Example Location |
|-------------|-------|------------------|
| Application source code | ALFA | ALFA/APPS/app-name/ |
| Test suites | ALFA | ALFA/TEST/unit/ |
| Dev tooling | ALFA | ALFA/TOOL/cli/ |
| CI/CD scripts | BRAV | BRAV/SCPT/ |
| Docker configs | BRAV | BRAV/DOCK/ |
| Infrastructure as code | BRAV | BRAV/INFR/ |
| Documentation | CHAR | CHAR/DOCS/ |
| ECRR reports | CHAR | CHAR/EVID/ECRR_REPORTS/ |
| Audit logs | CHAR | CHAR/AUDT/ |
| Configuration files | DELT | DELT/CONF/ |
| Test fixtures | DELT | DELT/FIXT/ |
| Templates | DELT | DELT/TMPL/ |

---

## Escalation

**If guardrails are blocking valid work:**

1. Check if violation is real (run check locally)
2. Consult this runbook for fix
3. If structure is legitimately needed, discuss with team
4. Update guardrails.json with justification
5. Include in PR description why exemption needed

**Contact:** BossCat OEM (@BossCat) for structural decisions

---

## References

- **ADR-0001:** This decision record
- **Guardrails Config:** BRAV/SCPT/guardrails.json
- **Check Script:** BRAV/SCPT/check_guardrails.py
- **Migration Guide:** BRAV/SCPT/README_NEXT_STEPS.md
- **Evidence:** CHAR/EVID/gate/

---

🐾 **When in doubt, ask: "Which plane does this belong to?" ALFA (app), BRAV (build/ops), CHAR (docs/evidence), or DELT (data/config).**

---

_Runbook: Repository Structure Violations_  
_Maintained by: BossCat OEM_  
_Version: 1.0_

