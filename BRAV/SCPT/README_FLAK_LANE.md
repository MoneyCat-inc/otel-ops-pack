# FLAK Lane: Changed-Paths Smoke Testing

**Owner:** AUTO-BOTS-FLAK-ALFA  
**Purpose:** Fast, reliable smoke tests for changed files only  
**Runtime Target:** ≤3 minutes  
**Authority:** BossCat OEM P1-A directive

---

## Usage

### In CI (GitHub Actions)

```yaml
- name: FLAK Smoke Test
  run: bash BRAV/SCPT/flak-changed-paths-smoke.sh
  timeout-minutes: 3
```

### Locally

```bash
# From repo root
bash BRAV/SCPT/flak-changed-paths-smoke.sh
```

---

## What It Tests

1. **Test Files**: Runs affected `*.spec.*` and `*.test.*` files
2. **Workflows**: Validates YAML syntax for changed workflow files
3. **TypeScript**: Quick type-check on changed TS/JS files (sample)

---

## Scope Limitations (Rule #7)

- Only tests **changed paths** (not full suite)
- Focuses on `**/tests/**` and `**/playwright/**`
- Samples large changesets (max 5 TS files type-checked)

---

## Evidence Trail

All actions logged to `.agent/EVIDENCE.log` with:
- Event timestamps
- Actor: `FLAK-ALFA`
- Phase: examine → report
- Status: pass/fail

---

## Lane Governance

**Budget:**
- Files: 2 (script + README)  
- LOC: ~85 (well under 200 limit)

**Single-Writer:**
- Lane: `FLAK`
- Writer: AUTO-BOTS-FLAK-ALFA
- Monitor: AUTO-BOTS-FLAK-BETA (reads evidence)

**Kill-Switch:**
- Honors `.agent/LOCK`
- Exits immediately if kill-switch active

---

## DoD (Definition of Done)

✅ Runtime ≤ 3 minutes  
✅ CI fails on any test failure  
✅ Scope limited to changed paths  
✅ Evidence logged to `.agent/EVIDENCE.log`  
✅ ECRR report generated  
✅ BOSSCAT_LOG entry added

---

**Authority:** BossCat OEM Gate #006 P1-A  
**Seal:** 🐾 FLAK Lane Implementation

