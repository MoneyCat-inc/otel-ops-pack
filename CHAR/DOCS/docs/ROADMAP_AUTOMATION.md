# 🗺️ Roadmap Automation System (ECRR-Driven)

> ## ARCHIVED — snapshot of 2025-10, not current status
>
> Pre-Pack-3B-split Resonai-era document; describes systems retired by Roadmap 2026 H2
> (`docs/BossCat/ROADMAP_2026H2.md`, all phases closed 2026-08-14). Current authority:
> `docs/PURPOSE.md`. Bannered in place 2026-08-25 (audit follow-up); not maintained.

This document describes the **automated roadmap tracking system** that follows the **ECRR methodology** (Examine → Clean → Report → Role). The system automatically updates roadmap status based on CI test results, ensuring docs never drift from reality.

---

## 📋 Overview

The roadmap automation system:

1. **Examines** test results from PR and nightly CI runs
2. **Cleans** the data by mapping tests to roadmap features
3. **Reports** by generating Markdown documentation (heatmaps, Kanban boards, timelines)
4. **Declares Role** by attributing changes to the ECRR Roadmap Agent

### Benefits

- **No manual updates** — roadmap stays current automatically
- **Test-driven status** — Green/Yellow/Red reflects actual test health
- **Artifact-driven** — All changes are auditable via JSON snapshots
- **PR integration** — Roadmap updates included in every PR
- **ECRR compliance** — Follows project methodology rigorously

---

## 🏗️ Architecture

### Files

```
roadmap.json                      # Schema: milestones, features, test tags
scripts/roadmap/
  ├── examine.ts                  # Phase 1: Parse test results
  ├── clean.ts                    # Phase 2: Normalize to roadmap schema
  ├── report.ts                   # Phase 3: Generate Markdown docs
  └── index.ts                    # Orchestrator (runs all phases)

.artifacts/
  ├── roadmap-examine.json        # Raw test result mapping
  └── roadmap-clean.json          # Cleaned feature statuses

docs/
  ├── ROADMAP.md                  # Main roadmap (summary + heatmap + Kanban)
  ├── ROADMAP_HEATMAP.md          # Heatmap table only
  └── ROADMAP_KANBAN.md           # Kanban board only
```

### Data Flow

```
Playwright Test Results (JSON)
        ↓
    examine.ts → .artifacts/roadmap-examine.json
        ↓
    clean.ts → .artifacts/roadmap-clean.json
        ↓
    report.ts → docs/ROADMAP*.md + .artifacts/SSOT.md
        ↓
    Git commit → PR / main branch
```

---

## 🚀 Usage

### Local Development

```bash
# Run full ECRR cycle (all phases)
pnpm roadmap:update

# Run individual phases
pnpm roadmap:examine        # Parse test results
pnpm roadmap:clean          # Normalize statuses
pnpm roadmap:report         # Generate docs

# Run tests + update roadmap
pnpm ci:roadmap
```

### CI Integration

To enable automated roadmap updates in CI:

1. Copy the workflow template:
   ```bash
   cp templates/roadmap-update.yml .github/workflows/roadmap-update.yml
   ```

2. Commit and push:
   ```bash
   git add .github/workflows/roadmap-update.yml
   git commit -m "ci: add roadmap auto-update workflow"
   git push
   ```

3. The workflow runs on:
   - Every push to `main` or `develop`
   - Every pull request
   - Daily at 6 AM UTC (scheduled)
   - Manual trigger via GitHub Actions UI

---

## 📊 Roadmap Schema

The `roadmap.json` file defines:

- **Milestones** (M1, M1.5, M2, M3)
- **Features** within each milestone
- **Test tags** that map to each feature
- **Current status** (green/yellow/red)

### Example Feature Entry

```json
{
  "milestones": {
    "M1_Foundations": {
      "label": "M1 Foundations",
      "features": {
        "instant_practice": {
          "name": "Instant Practice (/try)",
          "description": "Instant Practice flow + Pitch Meter",
          "testTags": ["@smoke", "@pilot-core"],
          "testFiles": ["instant-practice.spec.ts"],
          "status": "green"
        }
      }
    }
  }
}
```

### Status Rules

The `clean.ts` script automatically determines status:

- **✅ Green**: All tests passing → feature is stable
- **🟨 Yellow**: Some tests passing/failing → feature in progress
- **🟥 Red**: All tests failing or no tests found → feature not started

---

## 🔄 ECRR Phases (Detailed)

### Phase 1: Examine 🔍

**Purpose**: Parse CI test results and extract test statuses by tag.

**Input**:
- `test-results-pr.json` (from `pnpm test:pr`)
- `test-results-nightly.json` (from `pnpm test:nightly`)

**Output**:
- `.artifacts/roadmap-examine.json` (raw test data grouped by tag)

**Command**:
```bash
pnpm roadmap:examine
# or with custom paths:
tsx scripts/roadmap/examine.ts --pr-report path/to/pr.json --nightly-report path/to/nightly.json
```

---

### Phase 2: Clean 🧹

**Purpose**: Map test tags to roadmap features and compute Green/Yellow/Red status.

**Input**:
- `.artifacts/roadmap-examine.json`
- `roadmap.json` (schema)

**Output**:
- `.artifacts/roadmap-clean.json` (normalized feature statuses)

**Command**:
```bash
pnpm roadmap:clean
# or with custom examine result:
tsx scripts/roadmap/clean.ts --examine-result path/to/examine.json
```

---

### Phase 3: Report 📝

**Purpose**: Generate human-readable Markdown documentation from cleaned data.

**Input**:
- `.artifacts/roadmap-clean.json`

**Output**:
- `docs/ROADMAP.md` (main roadmap with summary + heatmap + Kanban)
- `docs/ROADMAP_HEATMAP.md` (heatmap table)
- `docs/ROADMAP_KANBAN.md` (Kanban board)
- `.artifacts/SSOT.md` (updated roadmap section)

**Command**:
```bash
pnpm roadmap:report
# or with custom clean result:
tsx scripts/roadmap/report.ts --clean-result path/to/clean.json
```

---

### Phase 4: Role 🎭

**Purpose**: Declare ownership and commit artifacts.

**Actions**:
- Commit updated docs to Git
- Attribute changes to **ECRR Roadmap Agent**
- Update PR description with roadmap summary (if applicable)

**Automated by**:
- CI workflow (GitHub Actions)
- Or manual commit after running `pnpm roadmap:update`

---

## 🧪 Testing & Validation

### Verify the system works

```bash
# 1. Run tests to generate results
pnpm test:pr
pnpm test:nightly

# 2. Update roadmap
pnpm roadmap:update

# 3. Check generated docs
cat docs/ROADMAP.md
cat docs/ROADMAP_KANBAN.md

# 4. Verify artifacts
ls -lh .artifacts/roadmap-*.json
```

### Expected output

- `docs/ROADMAP.md` should have:
  - Summary section with milestone overview
  - Heatmap table with ✅🟨🟥 statuses
  - Kanban board with feature lists
- `.artifacts/SSOT.md` should have updated roadmap section

---

## 🛠️ Maintenance

### Adding a New Feature

1. Add to `roadmap.json`:
   ```json
   {
     "new_feature": {
       "name": "New Feature Name",
       "description": "What it does",
       "testTags": ["@new-feature"],
       "testFiles": ["new-feature.spec.ts"],
       "status": "red"
     }
   }
   ```

2. Write Playwright tests with matching tags:
   ```typescript
   test('new feature works @new-feature', async ({ page }) => {
     // test implementation
   });
   ```

3. Run roadmap update:
   ```bash
   pnpm roadmap:update
   ```

4. Commit changes:
   ```bash
   git add roadmap.json docs/ROADMAP*.md .artifacts/roadmap-*.json
   git commit -m "feat: add new feature to roadmap"
   ```

### Changing Status Thresholds

Edit `scripts/roadmap/clean.ts` and modify `determineFeatureStatus()`:

```typescript
// Example: require 90% pass rate for green
if (passedTests / totalTests >= 0.9) {
  return { status: 'green', ... };
}
```

---

## 📦 PR Checklist Integration

When creating a PR, the roadmap should be auto-updated. Ensure your PR body includes:

```markdown
## 🗺️ Roadmap Impact

- [ ] Roadmap updated via `pnpm roadmap:update`
- [ ] `docs/ROADMAP.md` reflects current feature status
- [ ] Artifacts committed: `.artifacts/roadmap-*.json`

**ECRR Gate:**
- ✅ **Examine**: Test results parsed
- ✅ **Clean**: Statuses normalized
- ✅ **Report**: Docs regenerated
- ✅ **Role**: ECRR Roadmap Agent
```

---

## 🎯 Acceptance Criteria

For the roadmap system to be considered working:

1. ✅ `roadmap.json` exists with all M1-M3 features mapped
2. ✅ `pnpm roadmap:update` runs without errors
3. ✅ `docs/ROADMAP.md` is generated with current statuses
4. ✅ CI workflow auto-commits roadmap updates on test runs
5. ✅ `.artifacts/SSOT.md` includes roadmap section
6. ✅ Roadmap reflects test health (Green = all passing, etc.)

---

## 🔗 Related Documents

- `roadmap.json` — Schema and feature definitions
- `docs/ROADMAP.md` — Generated roadmap (main view)
- `.artifacts/SSOT.md` — Single Source of Truth (includes roadmap)
- `templates/roadmap-update.yml` — CI workflow template
- `TASKS.md` — Task backlog (feeds into roadmap planning)

---

## 🐛 Troubleshooting

### Roadmap not updating

```bash
# Check test results exist
ls -lh test-results-*.json

# Run phases individually to isolate issue
pnpm roadmap:examine
pnpm roadmap:clean
pnpm roadmap:report
```

### Test tags not mapping to features

- Verify `testTags` in `roadmap.json` match `@tags` in Playwright tests
- Check `.artifacts/roadmap-examine.json` to see parsed tags

### CI workflow not committing

- Ensure workflow has `contents: write` permission
- Check branch protection rules allow bot commits
- Verify workflow runs on correct branches (`main`, `develop`)

---

## 🎉 Summary

The ECRR-driven roadmap automation ensures your project roadmap is:

- ✅ **Always current** (test-driven status)
- ✅ **Auditable** (JSON artifacts for every update)
- ✅ **Low maintenance** (runs automatically in CI)
- ✅ **Contributor-friendly** (clear Kanban + heatmap views)

**Next steps**: Copy `templates/roadmap-update.yml` to `.github/workflows/` and commit to enable automation!

