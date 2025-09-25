# 🐞 IONA Error Ledger

This file catalogs all detected errors, violations, and resolutions for IONA.  
It complements **IONA_README.md** (Error Cataloguing System section) and follows the Detect → Resolve → Verify → Close Loop workflow.

---

## 🔖 Error Types
- **Usage Error** – mis-prompting, unclear input
- **System Error** – mode drift, citation misfire, over-brevity
- **Guardrail Violation** – style, empathy, or safety breach

---

## 📋 Log Format

```yaml
id: 2025-01-27-001
type: Guardrail Violation
context: Cipher mode returned sarcasm during sensitive query
impact: Tone inconsistent with affirming guidelines
resolution: Adjust humor gate → stricter positivity filter
status: ✅ Fixed in Config v1.1
evidence: commit/PR #123, smoke test run `tests/smoke/cipher-tone.spec.ts`
```

---

## 📓 Sample Entries

### Entry 2025-01-27-001

* **Type**: Guardrail Violation
* **Context**: Cipher mode response contained sarcasm during a sensitive query
* **Impact**: Broke tone guardrails; could cause user discomfort
* **Resolution**: Humor gate adjusted in Config v1.1
* **Status**: ✅ Verified fix via smoke test
* **Evidence**: `IONA_Config.json` (v1.1 update), `cipher-tone.spec.ts`

---

## 🧩 Traceability Rules

1. Each entry **must** include:
   * ID (timestamp-based, unique)
   * Type
   * Context + Impact
   * Resolution
   * Status
   * Evidence link (config, test, or PR)
2. Max 10 open entries per pass.
3. Resolved entries must be closed with ✅ and supporting evidence.

---

## 🔮 Next Steps

* Automate ID stamping via script (v1.2)
* Add severity levels (info/warning/error/critical)
* Export ledger as JSON for dashboard integration

---

## 📊 Error Statistics

**Total Entries**: 1  
**Open Issues**: 0  
**Resolved Issues**: 1  
**Last Updated**: 2025-01-27

---

*This ledger is maintained alongside IONA_README.md and follows the ECRR methodology for transparent error tracking and resolution.*
