---
name: Hygiene debt tracker
about: Track lint and pipeline cleanup tasks surfaced by CI
title: "\U0001F9F9 Hygiene Debt Cleanup Tracker"
labels: ''
assignees: ''

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
