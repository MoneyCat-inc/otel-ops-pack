# 🔒 Guardrails Configuration - LOCKED

**Lock Date:** 2025-10-10  
**Commit:** fa5cb6b  
**Authority:** BossCat OEM  
**Status:** ✅ PRODUCTION APPROVED

---

## Lock Certification

**I, BossCat OEM, certify that:**

This guardrails configuration (`BRAV/SCPT/guardrails.json`) has been tested, verified, and approved for production use. It represents the **hybrid tetragram structure** that balances operational requirements with structural compliance.

**Configuration Hash:**
```
SHA256: To be computed on lock
Version: 1.1 (Hybrid)
Exit Code: 0 (PASSING)
```

---

## Locked Configuration Summary

### Exempted Directories (Operational Requirement)
- `scripts/` - Local-first PowerShell gate scripts
- `docs/` - ECRR audit trails and evidence infrastructure

### Tetragram Planes (4-letter naming enforced)
- `ALFA/` - Application plane
- `BRAV/` - Build/Runtime/Automation/Verification plane
- `CHAR/` - Compliance/Human/Audit/Review plane
- `DELT/` - Data/Environment/Load/Test plane (includes ARTF/)

### Ephemeral Directories (Not tracked)
- `artifacts/` (legacy - use DELT/ARTF/)
- `DELT/ARTF/` (runtime artifacts)
- `logs/`, `out/`, `tmp/` (build outputs)

---

## Verification

**Last Verification:**
```bash
$ python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json
Exit Code: 0
Result: ✅ Repository structure complies with tetragram guardrails
Date: 2025-10-10
Commit: fa5cb6b
```

**Reproduce:**
```bash
git checkout fa5cb6b
python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json
```

---

## Modification Policy

**This configuration is LOCKED for production.**

Changes require:
1. BossCat OEM approval
2. ECRR evidence of testing
3. Updated lock certification
4. New configuration hash

**To propose changes:**
1. Create `BRAV/SCPT/guardrails.candidate.json`
2. Test with `--config guardrails.candidate.json`
3. Document in ECRR report
4. Submit for BossCat review

---

**Lock Status:** 🔒 **LOCKED**  
**Authority:** BossCat OEM  
**Date:** 2025-10-10  
**Seal:** 🐾

