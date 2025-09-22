---
name: Hygiene debt tracker
about: Track lint and pipeline cleanup tasks surfaced by CI
labels: [hygiene]
title: "🧹 Hygiene Debt Cleanup Tracker"
assignees: []
---

This issue tracks cleanup tasks surfaced by CI (Hygiene, CodeQL, Gitleaks, Pester).

## Status
- Hygiene: ☐
- CodeQL: ☐
- Gitleaks: ☐
- Pester: ☐

## Subtasks
- [ ] yamllint: fix workflow formatting in `.github/workflows/*` (`yaml`, `hygiene`)
- [ ] otelcol dry-run: resolve errors in `config` / `configs/otel` (`otel`)
- [ ] PSScriptAnalyzer: address warnings in `scripts/*.ps1` (`powershell`)
- [ ] Ensure `.env.example` stays authoritative (`hygiene`)

## How to reproduce
```bash
npm run hygiene
```

Paste failing logs and link offending lines in PRs referencing this tracker.
