# Vendor Security Scan Assessment

**Date:** 2025-10-25  
**Assessor:** Cursor{Implementer}  
**Authority:** Fubumaki (Repository Owner)  
**Purpose:** Determine which vendor scans to keep vs disable

---

## 🔍 Current State

**Working Internal Scans (GREEN):**
- ✅ Gitleaks Security Scan (secrets detection)
- ✅ BossCat Trivy Security Scan (containers + dependencies)
- ✅ CodeQL Analysis (SAST - in progress)
- ✅ PSScriptAnalyzer (PowerShell linting)
- ✅ DevSkim (security patterns)
- ✅ BossCat Tetragram Guard (naming compliance)
- ✅ BossCat Tetragram Guardrails (structure compliance)
- ✅ SBOM Stability Tracker (supply chain)

**Failing Vendor Scans (8):**
- ❌ Snyk Security
- ❌ Fortify AST Scan
- ❌ JFrog SAST Scan
- ❌ APIsec
- ❌ Mayhem for API
- ❌ Sysdig
- ❌ EthicalCheck-Workflow
- ❌ Jscrambler Code Integrity

---

## 📊 Vendor Scan Analysis

### Snyk Security
**Type:** Dependency + Container scanning  
**Overlap:** HIGH - Trivy already does this (and it's GREEN)  
**Credentials:** SNYK_TOKEN exists (Oct 5, 2025)  
**Value:** Duplicative with Trivy  
**Recommendation:** **DISABLE** (redundant coverage)

### Fortify AST Scan
**Type:** SAST (Static Application Security Testing)  
**Overlap:** HIGH - CodeQL already does this (and it's GREEN)  
**Credentials:** Missing (FOD_TENANT, FOD_USER, FOD_PASSWORD)  
**Cost:** Paid enterprise service  
**Recommendation:** **DISABLE** (CodeQL provides SAST)

### JFrog SAST Scan
**Type:** SAST + SCA  
**Overlap:** HIGH - CodeQL (SAST) + Trivy (SCA) cover this  
**Credentials:** Missing (JF_ACCESS_TOKEN)  
**Cost:** Paid enterprise service  
**Recommendation:** **DISABLE** (redundant)

### APIsec
**Type:** API security testing  
**Overlap:** MEDIUM - Specific to API endpoint testing  
**Credentials:** APISEC_USERNAME/PASSWORD exist (Oct 5, 2025)  
**Value:** Unique - API-specific testing  
**Recommendation:** **KEEP** (fix credential/config issue)

### Mayhem for API
**Type:** Fuzzing + API testing  
**Overlap:** MEDIUM - Similar to APIsec  
**Credentials:** Missing (MAYHEM_TOKEN)  
**Value:** Fuzzing is unique but overlaps with APIsec  
**Recommendation:** **DISABLE** (APIsec covers API testing)

### Sysdig
**Type:** Container runtime security  
**Overlap:** MEDIUM - Trivy covers container images, Sysdig adds runtime  
**Credentials:** Missing (SYSDIG_SECURE_TOKEN)  
**Value:** Runtime security monitoring  
**Recommendation:** **DISABLE** (runtime monitoring not critical for this project)

### EthicalCheck-Workflow
**Type:** Privacy/ethics compliance  
**Overlap:** LOW - Unique functionality  
**Credentials:** Unknown  
**Value:** Nice-to-have for compliance  
**Recommendation:** **DISABLE** (not critical for observability pipeline)

### Jscrambler Code Integrity
**Type:** Code obfuscation/protection  
**Overlap:** NONE - Unique functionality  
**Credentials:** Missing (JSCRAMBLER_ACCESS_KEY, SECRET_KEY)  
**Value:** Code protection (not applicable to open-source)  
**Recommendation:** **DISABLE** (not needed for open-source project)

---

## 🎯 Recommendations

### **DISABLE** (6 workflows) - Redundant or Not Applicable
1. ❌ Snyk Security (Trivy covers this)
2. ❌ Fortify AST Scan (CodeQL covers this)
3. ❌ JFrog SAST Scan (CodeQL + Trivy cover this)
4. ❌ Mayhem for API (APIsec covers this)
5. ❌ Sysdig (Runtime security not critical)
6. ❌ EthicalCheck-Workflow (Nice-to-have, not critical)
7. ❌ Jscrambler Code Integrity (Not applicable to open-source)

### **KEEP** (1 workflow) - Unique Value
1. ✅ APIsec - API-specific testing (fix credential issue)

---

## 📋 Implementation Plan

### Phase 1: Disable Redundant Workflows (Immediate)
**Action:** Add `if: false` to disable workflows without deleting them

**Workflows to disable:**
- snyk-security.yml
- fortify.yml
- jfrog-sast.yml
- mayhem-for-api.yml
- sysdig-scan.yml
- ethicalcheck.yml
- jscrambler-code-integrity.yml

**Time:** ~15 minutes

### Phase 2: Fix APIsec (If Needed)
**Action:** Debug credential/configuration issue
**Credentials:** APISEC_USERNAME/PASSWORD already exist
**Time:** ~30 minutes (depending on issue)

---

## 🎯 Expected Outcome

**Before:**
- 11 total security workflows
- 3 GREEN (internal)
- 8 RED (vendor)

**After:**
- 11 total workflows
- 3 GREEN (internal)
- 7 DISABLED (redundant vendor scans)
- 1 RED or GREEN (APIsec - to be fixed)

---

## 💡 Alternative: Keep All for Future

**If you prefer to keep all workflows** for future activation:
- Leave them as-is (failing)
- Document which credentials are needed
- Configure later when/if services are procured

This keeps options open without spending time on fixes that may not be used.

---

## 🐾 Recommendation

**My Call:** **Disable the 7 redundant vendor scans** to clean up CI noise.

**Rationale:**
- Core security covered by free/internal tools (Gitleaks, Trivy, CodeQL)
- Reduces CI execution time
- Eliminates failure noise
- Can re-enable later if needed
- Workflows remain in repo (not deleted, just disabled)

**Your call, Fubumaki:**
- **A** - Disable 7 redundant scans (clean up CI)
- **B** - Leave all as-is (future flexibility)
- **C** - Different approach

What would you like to do? 🐾

