# 🛡️ BossCat Tetragram Hardening Pack

**Version:** 1.0  
**Deployed:** 2025-10-09  
**Status:** ✅ Operational

---

## 🎯 What This Does

Prevents Cursor crashes by enforcing:
- ✅ **4-4-4-4 grammar** (`SET-SET-LANE-ROLE`)
- ✅ **A/B pair discipline** (Writer + Monitor)
- ✅ **Kill-switch respect** (`.agent/LOCK`)
- ✅ **Lane restrictions** (5 approved lanes only)
- ✅ **CI gate validation** (auto-blocks bad PRs)

---

## 🚀 Quick Start

### Before Committing Bot Changes

```bash
# Validate bot registry (fast)
pnpm agent:validate-names
```

### Test A/B Pairs (Optional)

```bash
# Test all lanes
pnpm agent:smoke:ssot
pnpm agent:smoke:flak
pnpm agent:smoke:sele
pnpm agent:smoke:comp
pnpm agent:smoke:docs
```

### Success Output

```
✅ Tetragram registry valid (4‑4‑4‑4; lanes ok; A/B pairs complete).
✅ A/B handshake healthy for lane SSOT.
```

---

## 📋 Bot Naming Rules (4-4-4-4)

### Grammar

```
SET-SET-LANE-ROLE

Example: AUTO-BOTS-SSOT-ALFA
         IONA-CATS-SSOT-BETA
```

### Components

| Part | Valid Values | Role |
|------|--------------|------|
| **SET (1st)** | `AUTO`, `IONA` | Organization |
| **SET (2nd)** | `BOTS`, `CATS` | Type |
| **LANE** | `SSOT`, `FLAK`, `SELE`, `COMP`, `DOCS` | Domain |
| **ROLE** | `ALFA`, `BETA` | Writer/Monitor |

### Discipline

- ✅ **Writers:** `AUTO-BOTS-*-ALFA` (modifies files)
- ✅ **Monitors:** `IONA-CATS-*-BETA` (verifies changes)
- ✅ **Pairing:** Exactly 1 ALFA + 1 BETA per lane

---

## 🔧 Scripts Available

```json
{
  "agent:validate-names": "Validate 4-4-4-4 grammar + pairs",
  "agent:smoke:ssot": "Test SSOT A/B pairing",
  "agent:smoke:flak": "Test FLAK A/B pairing",
  "agent:smoke:sele": "Test SELE A/B pairing",
  "agent:smoke:comp": "Test COMP A/B pairing",
  "agent:smoke:docs": "Test DOCS A/B pairing"
}
```

---

## ❌ Common Errors

### Error: "Not 4-4-4-4"

**Problem:** Bot code doesn't have 4 segments or segments aren't 4 characters  
**Fix:** Use format `AUTO-BOTS-SSOT-ALFA` (4 parts, 4 chars each)

---

### Error: "Invalid LANE 'XYZ'"

**Problem:** Lane name not in approved list  
**Fix:** Use one of: `SSOT`, `FLAK`, `SELE`, `COMP`, `DOCS`

---

### Error: "ALFA must belong to AUTO-BOTS"

**Problem:** Writer bot using wrong SET  
**Fix:** Writers must be `AUTO-BOTS-*-ALFA`, monitors `IONA-CATS-*-BETA`

---

### Error: "Lane requires exactly one ALFA and one BETA"

**Problem:** Missing ALFA or BETA partner in lane  
**Fix:** Add missing bot to complete A/B pair

---

### Error: "Kill-switch present"

**Problem:** `.agent/LOCK` file exists (intentional pause)  
**Fix:** Wait for lock removal (no action needed)

---

## 🎭 CI Behavior

### On Every PR

1. ✅ Validates 4-4-4-4 grammar
2. ✅ Tests all 5 A/B pairs
3. ✅ Shows gate signal on success

### Merge Requirements

- All validation checks pass
- All smoke tests pass (5/5)
- CI shows: `@cat ready-for-gate 🚪✅`

### On Failure

- ❌ PR blocked until fixed
- 📝 ECRR note generated (if smoke test fails)
- 🔍 Error list shows exactly what to fix

---

## 📂 Files

| File | Purpose |
|------|---------|
| `scripts/agent/validate-tetragram.ts` | 4-4-4-4 validator |
| `scripts/agent/smoke-ab.ts` | A/B pair smoke test |
| `.github/workflows/bosscat-tetragram-guard.yml` | CI workflow |
| `.agent/bots.schema.json` | JSON schema for IDE |
| `.agent/bots.json` | Bot registry |

---

## 🔒 Kill-Switch

### What It Does

If `.agent/LOCK` exists:
- ❌ All validation scripts exit immediately
- ❌ No bot work happens
- ✅ Human intervention mode active

### Usage

```bash
# Pause all bots (create lock)
touch .agent/LOCK

# Resume (remove lock)
rm .agent/LOCK
```

---

## 📊 Current Status

**Bot Registry:** `.agent/bots.json`  
**Total Bots:** 10 (5 lanes × 2 roles)  
**Validation:** ✅ All bots compliant  
**A/B Pairs:** ✅ 5/5 lanes complete

### Registry Health

```
✅ SSOT: AUTO-BOTS-SSOT-ALFA ↔ IONA-CATS-SSOT-BETA
✅ FLAK: AUTO-BOTS-FLAK-ALFA ↔ IONA-CATS-FLAK-BETA
✅ SELE: AUTO-BOTS-SELE-ALFA ↔ IONA-CATS-SELE-BETA
✅ COMP: AUTO-BOTS-COMP-ALFA ↔ IONA-CATS-COMP-BETA
✅ DOCS: AUTO-BOTS-DOCS-ALFA ↔ IONA-CATS-DOCS-BETA
```

---

## 📚 Documentation

**Full Reports:**
- `CHAR/ECRR/ECRR_REPORTS/HARDENING_PACK_TETRAGRAM_2025-10-09.md` (deployment)
- `CHAR/ECRR/ECRR_REPORTS/HARDENING_PACK_SUCCESS_2025-10-09.md` (verification)

**Quick Reference:** This file

---

## 🐾 BossCat Contact

**For Issues:**
1. Check ECRR reports for debugging context
2. Review error output (detailed and actionable)
3. Consult this README for common fixes
4. Escalate to BossCat OEM if persistent

**For Questions:**
- Grammar rules: See "Bot Naming Rules" above
- CI behavior: See "CI Behavior" above
- Kill-switch: See "Kill-Switch" above

---

## ✅ Quick Checklist

**Before committing bot changes:**
- [ ] Run `pnpm agent:validate-names`
- [ ] Fix any reported errors
- [ ] Optionally test A/B pairs
- [ ] Validation passes → safe to commit

**Before PR merge:**
- [ ] CI validation passes
- [ ] All smoke tests pass (5/5)
- [ ] Gate signal present: `@cat ready-for-gate 🚪✅`

---

**Hardening Pack Version:** 1.0  
**Last Updated:** 2025-10-09  
**Maintained By:** 🐾 BossCat OEM

**Status:** ✅ **OPERATIONAL** - Crash prevention active


