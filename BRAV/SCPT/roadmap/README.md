# 🗺️ Roadmap Automation Scripts

ECRR-driven roadmap tracking system that automatically updates project roadmap based on CI test results.

## Quick Start

```bash
# Update roadmap (full ECRR cycle)
pnpm roadmap:update

# Run individual phases
pnpm roadmap:examine    # Parse test results
pnpm roadmap:clean      # Normalize statuses
pnpm roadmap:report     # Generate docs
```

## Files

- `examine.ts` — Phase 1: Parse Playwright test results by tag
- `clean.ts` — Phase 2: Map tests to features, compute Green/Yellow/Red
- `report.ts` — Phase 3: Generate Markdown docs (heatmap, Kanban, timeline)
- `index.ts` — Orchestrator: runs all phases sequentially

## ECRR Phases

1. **🔍 Examine** → Parse `test-results-{pr,nightly}.json`
2. **🧹 Clean** → Map to `roadmap.json` schema, compute statuses
3. **📝 Report** → Generate `docs/ROADMAP*.md` + update `.artifacts/SSOT.md`
4. **🎭 Role** → Commit + attribute to ECRR Roadmap Agent

## Output Artifacts

- `.artifacts/roadmap-examine.json` — Raw test data by tag
- `.artifacts/roadmap-clean.json` — Cleaned feature statuses
- `docs/ROADMAP.md` — Main roadmap document
- `docs/ROADMAP_HEATMAP.md` — Heatmap table view
- `docs/ROADMAP_KANBAN.md` — Kanban board view

## Full Documentation

See: [`docs/ROADMAP_AUTOMATION.md`](../../docs/ROADMAP_AUTOMATION.md)

