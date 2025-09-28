# Tools Directory

This directory contains automation tools for the INV-04 fast wins implementation.

## Files

### `pw-json-reporter.js`
- **Purpose**: Lightweight Playwright reporter that writes machine-readable JSON summaries
- **Output**: 
  - `.artifacts/test-reports/playwright-summary.json` - Overall test run summary
  - `.artifacts/test-reports/playwright-tests.json` - Individual test results
- **Usage**: `npx playwright test --reporter=./tools/pw-json-reporter.js`

### `scripts/ci/emit-ssot.ts`
- **Purpose**: Generates SSOT (Single Source of Truth) markdown from test results
- **Output**: `.artifacts/SSOT.md` - Human-readable test summary
- **Usage**: `npx ts-node scripts/ci/emit-ssot.ts`

## Integration

These tools are integrated into the CI workflow (`ci-pr.yml`) to provide:
1. **Machine-readable test data** for `cursor-gap-closer` agent
2. **Human-readable summaries** for PR reviews
3. **Artifact-first approach** - all data flows through structured files

## Agent Integration

The `cursor-gap-closer` agent can:
- **Refresh SSOT** → Copy top block into `RUN_AND_VERIFY.md`
- **Quarantine flakies** → Parse `playwright-tests.json` for `@flaky` tags
- **Log trendlines** → Stash history in `.artifacts/history/`
