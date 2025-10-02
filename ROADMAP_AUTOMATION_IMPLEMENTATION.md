# 🚀 Roadmap Automation System — Implementation Complete

This document summarizes the **ECRR-driven roadmap automation system** that was implemented to keep the Resonai project roadmap current and test-driven.

---

## ✅ What Was Implemented

### 1. Core Schema (`roadmap.json`)

A canonical JSON schema defining:
- **4 milestones**: M1 Foundations, M1.5 Hardening, M2 Core Drills, M3 Adaptive
- **17 features** across all milestones
- **Test tag mappings** for each feature (e.g., `@smoke`, `@pilot-core`, `@prosody`)
- **Current statuses** (✅ Green, 🟨 Yellow, 🟥 Red)

**Path**: `roadmap.json`

---

### 2. ECRR Automation Scripts

Four TypeScript modules implementing the full ECRR cycle:

#### **Phase 1: Examine** (`scripts/roadmap/examine.ts`)
- Parses Playwright JSON test reports
- Groups tests by tag (e.g., `@smoke`, `@dashboard`)
- Outputs `.artifacts/roadmap-examine.json`

#### **Phase 2: Clean** (`scripts/roadmap/clean.ts`)
- Maps test tags to roadmap features
- Computes Green/Yellow/Red status based on test results:
  - **Green**: All tests passing
  - **Yellow**: Mixed (some passing, some failing/skipped)
  - **Red**: All failing or no tests found
- Outputs `.artifacts/roadmap-clean.json`

#### **Phase 3: Report** (`scripts/roadmap/report.ts`)
- Generates three Markdown views:
  - **Heatmap table** (feature vs stage vs status)
  - **Kanban board** (Green/Yellow/Red columns)
  - **Summary section** (milestone overview)
- Updates `docs/ROADMAP.md`, `docs/ROADMAP_HEATMAP.md`, `docs/ROADMAP_KANBAN.md`
- Updates `.artifacts/SSOT.md` with roadmap section

#### **Phase 4: Role** (`scripts/roadmap/index.ts`)
- Orchestrator that runs all phases
- Declares ownership (ECRR Roadmap Agent)
- Outputs execution summary

---

### 3. Package Scripts

Added to `package.json`:

```json
{
  "scripts": {
    "roadmap:examine": "tsx scripts/roadmap/examine.ts",
    "roadmap:clean": "tsx scripts/roadmap/clean.ts",
    "roadmap:report": "tsx scripts/roadmap/report.ts",
    "roadmap:update": "tsx scripts/roadmap/index.ts",
    "ci:roadmap": "pnpm test:pr && pnpm test:nightly && pnpm roadmap:update"
  }
}
```

**Usage**:
```bash
pnpm roadmap:update           # Run full ECRR cycle
pnpm ci:roadmap               # Run tests + update roadmap
```

---

### 4. CI Workflow Template

A GitHub Actions workflow that:
- Runs on push, PR, daily schedule, or manual trigger
- Executes PR and nightly tests
- Runs ECRR cycle (examine → clean → report)
- Auto-commits updated roadmap docs
- Posts PR comment with roadmap summary

**Path**: `templates/roadmap-update.yml`

**To activate**:
```bash
cp templates/roadmap-update.yml .github/workflows/roadmap-update.yml
git add .github/workflows/roadmap-update.yml
git commit -m "ci: enable roadmap auto-update"
```

---

### 5. Comprehensive Documentation

**Primary docs**:
- `docs/ROADMAP_AUTOMATION.md` — Full system documentation
- `scripts/roadmap/README.md` — Quick reference for scripts

**Generated artifacts** (after first run):
- `docs/ROADMAP.md` — Main roadmap (summary + heatmap + Kanban)
- `docs/ROADMAP_HEATMAP.md` — Heatmap table only
- `docs/ROADMAP_KANBAN.md` — Kanban board only
- `.artifacts/roadmap-examine.json` — Raw test data
- `.artifacts/roadmap-clean.json` — Cleaned statuses

---

## 🎯 How It Works (End-to-End)

### Automated Flow (CI)

```
1. Developer pushes code
   ↓
2. GitHub Actions runs tests (PR + nightly)
   ↓
3. Playwright generates test-results-{pr,nightly}.json
   ↓
4. ECRR Examine: Parse test results by tag
   ↓
5. ECRR Clean: Map tests → features, compute statuses
   ↓
6. ECRR Report: Generate docs/ROADMAP*.md
   ↓
7. ECRR Role: Commit + attribute to agent
   ↓
8. PR updated with roadmap summary comment
```

### Manual Flow (Local)

```bash
# Option 1: Full cycle
pnpm ci:roadmap

# Option 2: Individual phases
pnpm test:pr
pnpm test:nightly
pnpm roadmap:examine
pnpm roadmap:clean
pnpm roadmap:report

# Option 3: Update only (if tests already ran)
pnpm roadmap:update
```

---

## 📊 Current Roadmap Status (from `roadmap.json`)

### ✅ M1 Foundations (Complete)
- Instant Practice (/try) — Green
- Warmup FSM + Reflection — Green
- Local IndexedDB storage — Green
- Safety (silence pause, clipping) — Green

### ✅ M1.5 Hardening (Deployed)
- PR Test Lane (smoke+pilot-core) — Green
- Analytics + Live Dashboard — Green
- Cohort gating + rollback — Green
- Accessibility smokes — **Yellow** (failing tests)

### 🟨 M2 Core Drills (In Progress)
- Pitch Band drill — **Yellow**
- Resonance buckets — **Yellow**
- Prosody mini-phrases — Green
- Orb v2 (shimmer, hue) — **Yellow**
- Strain guardrails — **Yellow**

### 🟥 M3 Adaptive (Planned)
- Adaptive planner — **Red** (not started)
- Progress dashboard v1 — **Red** (not started)
- Carryover drills — **Red** (not started)
- Cohort analytics & data-control — **Red** (not started)

---

## 🧪 Testing the System

### Dry Run (No Tests Needed)

You can test the system even without test results by creating mock data:

```bash
# Create mock test results
echo '{"suites": []}' > test-results-pr.json
echo '{"suites": []}' > test-results-nightly.json

# Run roadmap update
pnpm roadmap:update

# Check generated docs
cat docs/ROADMAP.md
```

### Full Test (With Real Tests)

```bash
# 1. Run tests
pnpm test:pr --reporter=json --output-file=test-results-pr.json
pnpm test:nightly --reporter=json --output-file=test-results-nightly.json

# 2. Update roadmap
pnpm roadmap:update

# 3. Verify output
ls -lh docs/ROADMAP*.md
ls -lh .artifacts/roadmap-*.json
```

---

## 🔄 Maintenance Workflows

### Adding a New Feature

1. **Update `roadmap.json`**:
   ```json
   {
     "new_feature": {
       "name": "Feature Name",
       "testTags": ["@new-tag"],
       "testFiles": ["new-feature.spec.ts"],
       "status": "red"
     }
   }
   ```

2. **Write tests with matching tag**:
   ```typescript
   test('feature works @new-tag', async ({ page }) => {
     // ...
   });
   ```

3. **Update roadmap**:
   ```bash
   pnpm roadmap:update
   git add roadmap.json docs/ROADMAP*.md
   git commit -m "feat: add new feature to roadmap"
   ```

### Moving a Feature Between Milestones

Edit `roadmap.json` and move the feature object:

```json
// From M2_Core_Drills
"orb_v2": { ... }

// To M1_5_Hardening
"orb_v2": { ... }
```

Then run:
```bash
pnpm roadmap:update
```

### Marking a Feature Complete

Update status in `roadmap.json`:

```json
{
  "pitch_band": {
    "status": "green",
    "completedDate": "2025-10-01"
  }
}
```

Or let the automation handle it — once all tests pass, status will automatically become green!

---

## 🎯 Acceptance Criteria (All Met ✅)

- [x] **`roadmap.json` schema** with M1-M3 features and test tag mappings
- [x] **`examine.ts`** script parses Playwright JSON reports
- [x] **`clean.ts`** script computes Green/Yellow/Red statuses
- [x] **`report.ts`** script generates Markdown docs
- [x] **`index.ts`** orchestrator runs full ECRR cycle
- [x] **Package scripts** for local dev (`pnpm roadmap:update`)
- [x] **CI workflow template** for automated updates
- [x] **Comprehensive documentation** in `docs/ROADMAP_AUTOMATION.md`
- [x] **Zero linting errors** in TypeScript code

---

## 📦 Files Created

### Core Files
- `roadmap.json` — Schema (milestones, features, test tags)
- `scripts/roadmap/examine.ts` — ECRR Phase 1
- `scripts/roadmap/clean.ts` — ECRR Phase 2
- `scripts/roadmap/report.ts` — ECRR Phase 3
- `scripts/roadmap/index.ts` — ECRR Orchestrator
- `scripts/roadmap/README.md` — Quick reference

### Documentation
- `docs/ROADMAP_AUTOMATION.md` — System documentation
- `ROADMAP_AUTOMATION_IMPLEMENTATION.md` — This file

### Templates
- `templates/roadmap-update.yml` — CI workflow template

### Generated Artifacts (after first run)
- `docs/ROADMAP.md`
- `docs/ROADMAP_HEATMAP.md`
- `docs/ROADMAP_KANBAN.md`
- `.artifacts/roadmap-examine.json`
- `.artifacts/roadmap-clean.json`

### Package Updates
- `package.json` — Added 5 roadmap scripts

---

## 🚀 Next Steps

### Immediate (Recommended)

1. **Enable CI automation**:
   ```bash
   cp templates/roadmap-update.yml .github/workflows/roadmap-update.yml
   git add .github/workflows/roadmap-update.yml
   git commit -m "ci: enable roadmap auto-update"
   git push
   ```

2. **Generate initial roadmap**:
   ```bash
   # Create mock test results (or run real tests)
   echo '{"suites": []}' > test-results-pr.json
   echo '{"suites": []}' > test-results-nightly.json
   
   # Generate roadmap
   pnpm roadmap:update
   
   # Commit
   git add docs/ROADMAP*.md .artifacts/roadmap-*.json
   git commit -m "docs: initial roadmap generation"
   git push
   ```

### Future Enhancements

1. **Visual roadmap generation** (Python/Matplotlib):
   - Swimlane timeline diagrams
   - Gantt charts with actual dates
   - Heatmap visualizations

2. **Slack/Discord notifications**:
   - Post roadmap updates to team channels
   - Alert on status changes (Yellow → Green, Green → Red)

3. **Historical tracking**:
   - Store roadmap snapshots over time
   - Generate trend reports (time-in-status)

4. **Integration with GitHub Issues**:
   - Auto-label issues by milestone
   - Update issue status based on test results

---

## 🎉 Summary

The **ECRR-driven roadmap automation system** is now **fully implemented and ready to use**. It provides:

- ✅ **Automatic updates** from test results
- ✅ **Multiple views** (heatmap, Kanban, summary)
- ✅ **CI integration** via GitHub Actions
- ✅ **ECRR compliance** (Examine → Clean → Report → Role)
- ✅ **Low maintenance** (just update `roadmap.json` as features evolve)
- ✅ **Audit trail** via JSON artifacts

**The roadmap will never drift from reality again — it's now test-driven and self-updating!**

---

## 📞 Support

For questions or issues:
1. Check `docs/ROADMAP_AUTOMATION.md` (troubleshooting section)
2. Review `.artifacts/roadmap-*.json` for data inspection
3. Run individual phases (`examine`/`clean`/`report`) to isolate problems

**Role Declaration**: This system was implemented by **Cursor Agent: Observability Copilot** following ECRR methodology.

