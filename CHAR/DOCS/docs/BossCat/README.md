# BossCat Operations Guide

[![BossCat Gate Verification](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml)
[![Repository Structure Compliance](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/guardrails.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/guardrails.yml)
[![Monthly Rollup](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-monthly-evidence-rollup.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-monthly-evidence-rollup.yml)

Governance and local-first operations for **otel-ops-pack** (Resonai [OTel]).
*Rewritten 2026-09-01 — the previous version badged a workflow that no longer exists, described a
visuals lane split out in Pack 3B, and defined the planes differently from ADR-0001.*

## Read first

| Document | What it settles |
| --- | --- |
| [`CHARTER.md`](CHARTER.md) | The four seats, lane discipline, operating principles |
| [`../PURPOSE.md`](../PURPOSE.md) | Deliberate steady-state; the test every change must pass |
| [`ROADMAP_2026H2.md`](ROADMAP_2026H2.md) | Roadmap of record — all five phases closed 2026-08-14 |
| [`BOSSCAT_LOG.md`](BOSSCAT_LOG.md) | Live log, one line per change |
| [`REQUIRED_STATUS_CHECKS.md`](REQUIRED_STATUS_CHECKS.md) | Live required-check set on `main` |
| [`../REPOSITORY_STRUCTURE.md`](../REPOSITORY_STRUCTURE.md) | Planes, legacy roots, where things run from |

## Key artifacts

- `CHAR/ECRR/ECRR_REPORTS/` — per-change evidence (lean ECRR: quantified before/after, honest verdict)
- `docs/status/` — registries (`workflows.json` is CI-guarded) and the executive status page
- `docs/IONA_ERRORS.md` — error ledger
- `MoneyCat-inc/otel-ops-evidence` — raw evidence archive (monthly rollup, quarterly prune)

## Runbook commands

```powershell
# Gate verification (strict) — alias: pnpm run agent:ready-for-gate[:local|:ci|:stg|:prod]
pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -Strict

# ECRR benchmark across all reports
pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1

# Windows collector watchdog
pwsh -File BRAV/SCPT/watchdog-control.ps1 [start|stop|status|logs|evidence] [gate|site|both]

# Fast pipeline health
pwsh -File scripts/quick-monitor.ps1
```

Gate verification writes `artifacts/gate-verification-results.json` and, when applicable, an ECRR
gate report. `scripts/*.ps1` are thin wrappers; implementations live in `BRAV/SCPT/`.

## The planes (ADR-0001, ratified hybrid ADR-0002)

| Plane | Holds |
| --- | --- |
| `ALFA/` | Application: app trees, libs, canary emitters, tests |
| `BRAV/` | Build/automation: **`BRAV/SCPT/` is the canonical PowerShell tree** |
| `CHAR/` | Compliance: docs mirror, ECRR audit trail, evidence, preservation archive |
| `DELT/` | Data/config: artifacts, configs (`DELT/CONF/configs/`), fixtures, templates |

`docs/` is the documentation source of truth (`CHAR/DOCS/` mirrors it). Full detail in
`../REPOSITORY_STRUCTURE.md`.

## Lane discipline (from the charter)

One lane per pull request, never mixed: **docs** (`docs/**`, `README.md`; budget 10 files / 200 LOC,
`lane:cleanup` waiver for sweeps), **code**, **CI/ops** (`.github/workflows/**`, registry-guarded),
**evidence** (`CHAR/ECRR/**`). Conventional commit prefixes are enforced.

## Cadence (from PURPOSE.md)

Per change: lean ECRR · Monthly: evidence rollup · Quarterly: dependency/stack upgrade check and
evidence prune · Standing: the clean-host E2E gate stays green. No new recurring writer without an
owner, a review date and a kill switch.

## Historical material in this directory

Dated briefings, memos, measurement reports and run cards (`BRIEFING_*`, `MEMO_*`, `*_2026MMDD.md`,
`CLEAN_HOST_E2E_RUN_CARD_*`) are records of their own dates. Read them for provenance, not as
current instructions; corrections are filed as addenda.
