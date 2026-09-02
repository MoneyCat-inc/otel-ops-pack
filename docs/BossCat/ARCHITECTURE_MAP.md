<!-- markdownlint-disable MD013 MD034 -->
# BossCat Architecture Map — Components, Flows, and Links

> ## HISTORICAL — design map of October 2025, not the current system
>
> This map describes the ingest → normalize → classify → summarize "loop-closing" spine and its
> dashboards as the "single source of truth for how the system fits together". Per the 2026-09-01
> status addendum in `LOOP_CLOSING_MACHINE_ARCHITECTURE.md`, that spine **exists as scripts but was
> never wired into any live workflow**; `nightly-ecrr-aggregates.yml` was retired 2026-08-03, and
> `stress-test-pr.yml` and `config/policy/` no longer exist. Kept as the record of the design.
>
> **For how the repository actually fits together, read:** `docs/REPOSITORY_STRUCTURE.md` (planes,
> roots, where things run) and `docs/architecture/CURRENT_ARCHITECTURE.md` (telemetry topology).

## Purpose

- Single source of truth for how BossCat’s bot-native observability system fits together.
- Updated as the project evolves; use the JSON map for tooling and dashboards.

## System Overview

- Phases: Phase 1 (Prevention), Phase 2 (Intelligence), Phase 3 (Learning/Autonomy)
- Loops: Run (ALFA), PR (BRAV), Workflow (CHAR), Org (DELT)
- ECRR: Examine → Clean → Report → Role at every scale

## Key Components (by flow)

- Correlation (Lane A)
  - Library: `scripts/lib/correlation.ts`
  - Logger: `scripts/lib/logger.ts`
  - Emitters: `scripts/emit-synthetic-span.ts`, `scripts/examples/log-with-trace.ts`
  - Verifier: `scripts/verify-correlation.ps1`
  - Evidence + Report: `.agent/EVIDENCE.log`, `CHAR/ECRR/ECRR_REPORTS/ECRR_PHASE2_W2_CORRELATION_*.md`
- Ingest (ALFA-2)
  - Webhook/CLI: `scripts/ingest-worker.ts`, helpers: `scripts/ingest-utils.ts`
  - Backfill: `scripts/ingest-backfill.ps1`
  - Outputs (per run dir): `meta.json`, `logs/*`, `events.jsonl`
- Normalize → Classify → Summarize (BRAV-2 / CHAR-2)
  - Normalize: `scripts/normalize-events.ts` → `events.jsonl`, `signatures.json`
  - Classify: `scripts/classify-run.ts` → `labels.json`
  - Summarize: `scripts/summarize-run.ts` → `summary.md`
  - Orchestrator: `scripts/run-normalize-summarize.ps1`
- Act (CHAR-2)
  - PR Comment: `scripts/actor-pr-comment.ts` (reads `summary.md`, `labels.json`)
- Policy & Registry (Phase 3 Quickstart)
  - Signature Registry: `ALFA/APPS/signature-registry.json`
  - Policy: `config/policy/ecrr-policy.json`
  - Rerun Guard: `scripts/auto-rerun-guard.ps1`
- Dashboards (DELT-2)
  - Rollups: `scripts/dashboard-query.ts`
  - Nightly: `.github/workflows/nightly-ecrr-aggregates.yml`
  - Tiles Spec: `docs/observability/snapshots/ecrr-dashboard-tiles.json`
- CI Pilots
  - Gate: `.github/workflows/bosscat-gate-verify.yml` (ECRR pilot steps appended)
  - Stress PR: `.github/workflows/stress-test-pr.yml` (ECRR pilot steps appended)

## Data Products (per run)

- Required files in `artifacts/ecrr/org=<org>/repo=<repo>/dt=<yyyy>/<mm>/<dd>/run=<id>/`:
  - `meta.json` (ingest), `logs/*` (ingest/enrich)
  - `events.jsonl`, `signatures.json` (normalize)
  - `labels.json` (classify), `summary.md` (summarize)

## Dependencies (flow order)

- Ingest → Normalize → Classify → Summarize → Act
- Classifier optionally annotates from `signature-registry.json`
- Actor optionally uses policy/owners for links (via labels)
- Rollups consume `signatures.json` and `labels.json`

## NPM Scripts (entry points)

- `pnpm ingest:worker` — Start webhook server
- `pnpm ingest:backfill` — Historical fetch (gh api)
- `pnpm normalize:run` — Build events/signatures for RUN_DIR
- `pnpm classify:run` — Build labels.json for RUN_DIR
- `pnpm summarize:run` — Build summary.md for RUN_DIR
- `pnpm ecrr:process` — Normalize + Summarize runner (PowerShell)
- `pnpm dashboard:rollup` — 7-day aggregates for dashboards

## Workflows

- Gate Verify: `.github/workflows/bosscat-gate-verify.yml` (pilot ECRR + PR comment)
- Stress Test PR: `.github/workflows/stress-test-pr.yml` (pilot ECRR + PR comment)
- Nightly Aggregates: `.github/workflows/nightly-ecrr-aggregates.yml`

## Evidence & Reports

- Evidence ledger: `.agent/EVIDENCE.log`
- ECRR reports: `CHAR/ECRR/ECRR_REPORTS/*`
- Validation summaries: `PHASE2_VALIDATION_COMPLETE.md`, `PHASE1_COMPLETE_PR_BODY.md`, `TETRAGRAM_PHASE1_EXECUTION_SUMMARY.md`

## Machine-readable map

- JSON: `docs/reference/reference-map.json`
- Generate: `pnpm map:generate`

## Maintenance

- Update this file when adding/changing components.
- Keep `docs/reference/reference-map.json` in sync via the generator script.
- Add an evidence entry for any structural changes (files, workflows, policies).

## Importance System (Docs Priority)

- Purpose: keep critical documents discoverable as the system scales.
- Levels (4-tier):
  - P0 Critical — canonical design/governance specs and gate-deciding reports
  - P1 High — operational guides, living indices, pilots and validation summaries
  - P2 Medium — implementation notes, examples, playbooks
  - P3 Low — archival, historical snapshots
- Source of truth: `docs/reference/docs-index.json`
- Display: surfaced in `docs/reference/reference-map.json` and status.html (counts + top P0)
