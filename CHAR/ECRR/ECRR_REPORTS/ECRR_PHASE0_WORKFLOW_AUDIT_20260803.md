# ECRR — Phase 0: CI Workflow Audit (78 → 11 scheduled)

**Date:** 2026-08-03  
**Actor:** Claude (chat/review seat); operator gate = PR review  
**Verdict:** **GREEN** — every workflow classified with a written reason; scheduled count 22 → 11 (target ≤ 12); no required branch-protection check touched

## 1. Examine

- 78 workflows in `.github/workflows/`. 22 carried `schedule:` triggers; the rest fire on push/PR/dispatch.
- Classification found four failure families: **duplicates** (three CodeQL setups, two gitleaks, four k6 gates for the same test app), **unreachable infrastructure** (workflows assuming `localhost:8080` SigNoz on hosted runners, or hardcoded `C:\Users\fubum` paths), **recurring writers** (nightly jobs committing snapshots/PRs into the ops-pack working tree, against the evidence-repo policy), and **no consumer** (rollups, KPI refreshes, smoke polls nobody reads — `hub-smoke` alone burned ~4,300 runs/month).
- Spot-checks corrected two audit-draft claims: `BRAV/SCPT/ci/run-scenario.js` and the `sec-archiver/` scripts **do** exist — those workflows are retired for infrastructure/policy reasons, not missing scripts. Genuinely missing: `scripts/repo-cleanup.ps1`, `codex/codex-review-openai.ps1`.
- Required branch-protection contexts (per `bosscat-branch-protection`): CodeQL, PSScriptAnalyzer, gitleaks, Gate k6, Gate synthetic trace, Site links/a11y/CSP — all live in keeper workflows.

## 2. Clean

- **47 workflows retired**: top-level `on:` block replaced with `workflow_dispatch` plus a three-line header (date, reason, restore instructions). History preserved; every workflow remains manually runnable; re-enabling is a one-commit revert from git history. `run-rotation`, `multi-app-ci`, and `perf-gate-demo` keep their dispatch inputs.
- **21 keepers** got a one-line `# KEEP` justification header (roadmap Phase 0 requirement).
- **10 dispatch-only workflows untouched** (zero scheduled cost): app-template, bosscat-branch-protection, bosscat-diagnostic, boss-gate-signal-and-merge, ci-disabled, gate-019-audio-r1-test, rsi-archive, rsi-index, run-archiver-backfill, plus required-check-shims (self-path PR trigger only, KEEP header added).
- `docs/status/workflows.json` regenerated with the repo's own `scripts/regenerate-workflows-registry.ps1` so `registry-guard` passes.

## 3. Report

| Metric | Before | After |
|---|---|---|
| Workflows with `schedule:` | 22 | **11** (target ≤ 12) |
| Workflows firing on push/PR | ~30 | 14 |
| CodeQL setups | 3 | 1 |
| gitleaks workflows | 3 (incl. security-scan job) | 1 |
| k6 gates for dotnet-test-app | 4 | 1 |
| Highest-frequency schedule | 10 min (hub-smoke) | 30 min (run-archiver) |
| Recurring PR-openers | 5 (status, kpis, registry-drift, sec-archive, rsi-sweep) | 0 |

Surviving scheduled 11: bosscat-monthly-evidence-rollup, codeql, evidence-pat-rotation-reminder, evidence-retention-prune, gate-nightly, gitleaks, osv-scanner, powershell, quil-docs-lane, run-archiver, trivy-security-scan.

Follow-ups filed here, not acted on: `trivy-security-scan` pins pre-upgrade image versions (signoz v0.96.1) — refresh; `bosscat-gate-verify` is heavyweight for its value — Phase 2 slimming candidate; local scheduled-task audit (11 Windows tasks) remains the other half of the recurring-writer criterion.

## 4. Role

Chat/review seat classified, edited, and documented; machine operator gates the merge via PR review. This closes the workflow half of the Phase 0 exit criterion "no recurring writer left running against the working tree" — the compliance-engine retire-or-fix decision remains the last open Phase 0 item.

**Status:** COMPLETE

## ECRR Gate

- Gate: PASS
- Scope: Structural normalization only.
- Evidence Reference: ECRR processor run 2026-08-18, 389/389 gated (PR #571).
- Guardrail: Append-only; original report body unchanged.
