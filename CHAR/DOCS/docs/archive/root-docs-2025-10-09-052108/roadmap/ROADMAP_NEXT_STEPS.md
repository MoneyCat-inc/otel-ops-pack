# 🗺️ Roadmap Automation — Next Steps Checklist

## ✅ Current Status: System Deployed & Tested

**What's Working:**
- ✅ ECRR cycle runs successfully (`pnpm roadmap:update`)
- ✅ All artifacts generated correctly
- ✅ Docs rendered with summary/heatmap/Kanban sections
- ✅ Current state: All Red (placeholder, no tests parsed)

**Files Verified:**
- `scripts/roadmap/index.ts` — ECRR orchestrator
- `scripts/roadmap/examine.ts` — Phase 1: Parse tests
- `scripts/roadmap/clean.ts` — Phase 2: Compute statuses
- `scripts/roadmap/report.ts` — Phase 3: Generate docs
- `roadmap.json` — Schema with 17 features
- `docs/ROADMAP.md` — Generated output

---

## 📋 Next Actions

### 1. Feed Real Test Results

**When:** Before your next PR or when ready to see actual feature statuses

**Commands (PowerShell):**
```powershell
# Run PR tests (JSON output configured in playwright.noweb.config.ts)
pnpm test:pr

# Run nightly tests (JSON output configured in playwright.config.ts)
pnpm test:nightly

# Update roadmap (will compute Green/Yellow/Red from real results)
pnpm roadmap:update

# Review updated roadmap
Get-Content docs/ROADMAP.md | Select-Object -First 50
```

**Note:** The Playwright configs already include JSON reporters:
- `playwright.noweb.config.ts` → outputs `test-results-pr.json`
- `playwright.config.ts` → outputs `test-results-nightly.json`

Don't pass `--reporter` flags — they override the config!

**Expected Result:**
- Features with passing tests → ✅ Green
- Features with mixed results → 🟨 Yellow
- Features with no tests → 🟥 Red

---

### 2. Enable CI Automation

**When:** After confirming Step 1 works and you want automatic updates

**Commands (PowerShell):**
```powershell
# Copy workflow template to active directory (✅ Already done!)
Copy-Item templates/roadmap-update.yml .github/workflows/roadmap-update.yml

# Review workflow (optional)
Get-Content .github/workflows/roadmap-update.yml | Select-Object -First 30

# Commit and enable (PowerShell syntax)
git add .github/workflows/roadmap-update.yml
git commit -m "ci: enable ECRR roadmap auto-update`n`n## ECRR Gate`n- **Examine**: Roadmap automation tested locally`n- **Clean**: All phases complete successfully`n- **Report**: Docs generated and verified`n- **Role**: Cursor Agent (Observability Copilot)"
git push
```

**Status**: ✅ **Workflow file already copied!** (`.github/workflows/roadmap-update.yml` exists)

**What Happens:**
- Roadmap updates automatically on every push/PR
- Daily scheduled run at 6 AM UTC
- PR comments posted with roadmap summary
- Roadmap always stays current

---

### 3. Tag Your Playwright Tests (As Needed)

**When:** While writing new tests or updating existing ones

**Example:**
```typescript
// Match tags in roadmap.json → testTags
test('instant practice loads @smoke @pilot-core', async ({ page }) => {
  await page.goto('/try');
  await expect(page.locator('.pitch-meter')).toBeVisible();
});

test('prosody detection @prosody', async ({ page }) => {
  // Test prosody mini-phrases feature
});

test('accessibility skip links @a11y-smoke', async ({ page }) => {
  // Test accessibility features
});
```

**Tag Mapping (from `roadmap.json`):**
- `@smoke`, `@pilot-core` → M1 & M1.5 features
- `@prosody`, `@pitch-band`, `@resonance` → M2 Core Drills
- `@dashboard`, `@cohort-analytics` → M3 Adaptive
- `@nightly`, `@future` → Future features

---

## 🎯 Quick Commands Reference

```bash
# Update roadmap (full ECRR cycle)
pnpm roadmap:update

# Run tests + update roadmap
pnpm ci:roadmap

# Individual phases (for debugging)
pnpm roadmap:examine    # Parse test results
pnpm roadmap:clean      # Compute statuses
pnpm roadmap:report     # Generate docs

# View generated artifacts
cat docs/ROADMAP.md
cat .artifacts/roadmap-clean.json | jq '.milestones'
```

---

## 🔍 Troubleshooting

### Playwright error: "Cannot find module 'json=test-results-pr.json'"

**Issue:** Passing `--reporter` flags overrides the pre-configured reporters in Playwright configs.

**Solution:** Don't pass any reporter flags! The configs already have JSON reporters:

```powershell
# ✅ CORRECT: Just run tests without flags
pnpm test:pr       # Uses playwright.noweb.config.ts → test-results-pr.json
pnpm test:nightly  # Uses playwright.config.ts → test-results-nightly.json

# ❌ WRONG: Don't override with CLI flags
pnpm test:pr --reporter=json=test-results-pr.json  # Breaks config
```

**Why this works:**
- `playwright.noweb.config.ts` (line 19): `['json', { outputFile: 'test-results-pr.json' }]`
- `playwright.config.ts` (line 19): `['json', { outputFile: 'test-results-nightly.json' }]`

### PowerShell error: "token '&&' is not a valid statement separator"

**Issue:** PowerShell uses `;` not `&&` for command chaining.

**Fix:**
```powershell
# Wrong (bash syntax):
git add file.txt && git commit -m "message" && git push

# Correct (PowerShell syntax):
git add file.txt; git commit -m "message"; git push

# Or use separate lines:
git add file.txt
git commit -m "message"
git push
```

### Roadmap still shows all Red after running tests

**Check (PowerShell):**
```powershell
# 1. Test reports generated
Get-ChildItem test-results-*.json

# 2. Reports contain test data
Get-Content test-results-pr.json | Select-Object -First 20

# 3. Check examine phase parsed tests
Get-Content .artifacts/roadmap-examine.json | ConvertFrom-Json | Select-Object testsByTag
```

**Fix:**
```powershell
# Ensure reports exist and are valid JSON
Test-Path test-results-pr.json
Test-Path test-results-nightly.json

# If missing, create placeholder or run tests
if (-not (Test-Path test-results-pr.json)) {
    '{"suites": []}' | Out-File test-results-pr.json -Encoding utf8
}
```

### CI workflow not committing

**Check:**
1. Workflow has `contents: write` permission ✅ (already in template)
2. Branch protection allows bot commits
3. Workflow runs on correct branches (`main`, `develop`)

**Fix:**
- Review workflow logs in GitHub Actions
- Check `.github/workflows/roadmap-update.yml` is present

---

## 📊 Expected Evolution

### Current State (Oct 1, 2025)
```
All features: 🟥 Red
Reason: No test results parsed (placeholder JSON)
```

### After Running Real Tests (Step 1)
```
M1 Features: ✅ Green (smoke tests passing)
M1.5 Features: 🟨 Yellow (accessibility partial)
M2 Features: 🟥 Red (not implemented yet)
M3 Features: 🟥 Red (future work)
```

### After M2 Implementation
```
M1 Features: ✅ Green
M1.5 Features: ✅ Green
M2 Features: 🟨 Yellow → ✅ Green (as tests stabilize)
M3 Features: 🟥 Red
```

---

## 🎉 Success Criteria

You'll know the system is fully operational when:

- [x] `pnpm roadmap:update` runs without errors ✅ (Confirmed)
- [x] Artifacts generated in `.artifacts/` ✅ (Confirmed)
- [x] Docs generated in `docs/ROADMAP*.md` ✅ (Confirmed)
- [ ] Real test results show Green/Yellow statuses (After Step 1)
- [ ] CI workflow enabled and auto-committing (After Step 2)
- [ ] Roadmap stays current without manual intervention (After Step 2)

---

## 📚 Documentation

- **`docs/ROADMAP_AUTOMATION.md`** — Complete system documentation
- **`ROADMAP_AUTOMATION_IMPLEMENTATION.md`** — What was built
- **`ROADMAP_SYSTEM_READY.md`** — Quick start guide
- **`scripts/roadmap/README.md`** — Script reference

---

## 🚀 When You're Ready

Just run:
```bash
# Step 1: Generate real test results
pnpm test:pr --reporter=json --output-file=test-results-pr.json
pnpm roadmap:update

# Step 2: Enable CI (when ready)
cp templates/roadmap-update.yml .github/workflows/roadmap-update.yml
git add .github/workflows/roadmap-update.yml
git commit -m "ci: enable roadmap auto-update"
git push
```

---

**Status**: ✅ System deployed, tested, and ready for production use  
**Last Updated**: 2025-10-01  
**Role**: Cursor Agent (Observability Copilot)

