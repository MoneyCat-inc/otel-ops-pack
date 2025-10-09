# ✅ Playwright Reporter Syntax — Fixed

**Date:** 2025-10-01  
**Issue:** Workflow and docs used incorrect `--output-file` flag  
**Fix:** Updated to correct Playwright syntax `--reporter=json=filename.json`

---

## 🐛 Issue

The workflow template and guidance documents used:
```bash
# ❌ WRONG (Playwright doesn't recognize --output-file)
pnpm test:pr --reporter=json --output-file=test-results-pr.json
```

This caused the error:
```
error: unknown option '--output-file=test-results-pr.json'
```

---

## ✅ Fix Applied

Updated to correct Playwright syntax:
```bash
# ✅ CORRECT
pnpm test:pr --reporter=json=test-results-pr.json
pnpm test:nightly --reporter=json=test-results-nightly.json
```

---

## 📝 Files Updated

1. **`templates/roadmap-update.yml`** (lines 45, 51)
   - Changed: `--reporter=json --output-file=test-results-pr.json`
   - To: `--reporter=json=test-results-pr.json`

2. **`ROADMAP_NEXT_STEPS.md`** (lines 29-33, 141-143)
   - Updated main commands section
   - Updated troubleshooting section

3. **`ROADMAP_STATUS.md`** (lines 32-34)
   - Updated Step 1 commands

---

## 🔄 Update Your Workflow

Since you already copied the workflow file, you need to update it:

```powershell
# Re-copy the fixed template
Copy-Item templates/roadmap-update.yml .github/workflows/roadmap-update.yml -Force

# Commit the fix
git add .github/workflows/roadmap-update.yml templates/roadmap-update.yml ROADMAP_NEXT_STEPS.md ROADMAP_STATUS.md
git commit -m "fix: correct Playwright reporter syntax in roadmap workflow

Changed from --reporter=json --output-file=FILE
to --reporter=json=FILE (correct Playwright syntax)

## ECRR Gate
- **Examine**: Identified incorrect flag usage
- **Clean**: Updated workflow + docs with correct syntax
- **Report**: All files updated consistently
- **Role**: Cursor Agent (Observability Copilot)"
```

---

## ✅ Verification

Test the corrected syntax locally:

```powershell
# This should now work correctly
pnpm test:pr --reporter=json=test-results-pr.json

# Verify output file created
Test-Path test-results-pr.json
# Should return: True

# Update roadmap with real data
pnpm roadmap:update
```

---

## 📊 Expected Behavior

**Before (with incorrect syntax):**
```
error: unknown option '--output-file=test-results-pr.json'
❌ Tests don't run
```

**After (with correct syntax):**
```
✅ Tests run successfully
✅ test-results-pr.json created with test data
✅ pnpm roadmap:update shows Green/Yellow statuses
```

---

## 🎯 Summary

- ✅ Workflow template fixed (`templates/roadmap-update.yml`)
- ✅ Guidance docs updated (`ROADMAP_NEXT_STEPS.md`, `ROADMAP_STATUS.md`)
- ✅ Correct syntax: `--reporter=json=filename.json`
- 🔄 Action required: Re-copy template to workflow file

---

**Status:** ✅ Fix complete, ready to test  
**Next Step:** Re-copy template and commit the fix

