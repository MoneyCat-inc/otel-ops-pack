<!-- markdownlint-disable MD013 MD034 MD060 -->
# B1 Measurement — docs lint debt (archive-first)

**Date:** 2026-08-15  
**Authority:** BossCat OEM · Second Pass Wave 2 B1  
**Actor:** Cursor{Implementer}  
**Grounded against:** `origin/main` @ `7fc711a9e` (+ docs_gate archive exclusion PR)

## Measurement

| Probe | Result |
|-------|--------|
| Live `docs/**/*.md` (excl. `docs/archive/`) | **477** |
| Already under `docs/archive/` | **131** |
| Dated session / planner archive candidates (this wave) | **105** |
| Worst known offender | `docs/BossCat/PLANNER_BRIEF_20251012.md` (hundreds of MD032/MD022 — not reflowed) |

Prior plan figure: **10,718** markdownlint errors across **370** live docs @ `4469d10de`. Re-rank after archive batches land (do not trust this doc for residual counts).

## Ordering

1. **Gate:** exclude `docs/archive/**` from docs_gate lintable set (markdownlint + lychee); budgets still count.
2. **Archive:** byte-identical `git mv` of dated session reports → `docs/archive/<same relative path>`.
3. **Then:** lint-fix live remainder in ≤10-file batches; path-fix Q3 stale run-card cites on live high-debt guides (own debt / budget).
4. **B2** lychee full-scope waits until archive PRs merge.

## Batch 1 scope

Trees / files moved in the paired commit (see git history):

- `docs/BossCat/2025-10/**`
- `docs/status/2025-10/**`
- `docs/gate/2025-10/**`
- `docs/evidence/2025-10/**`
- `docs/BossCat/PLANNER_BRIEF_20251012.md`
- `docs/BossCat/reports/**`

`lane:cleanup` AMBER — file count exceeds ≤10; lint never waived on live docs.

## Batch 2 scope

Additional dated session / gate / PR reports (byte-identical `git mv`, see git history):

- Remaining `docs/gate/2025-10/**` (approvals / certs; excluded living `GATE_GREEN_FLIP_PROCEDURE`)
- `docs/gate/misc/GATE_007_*`, `GATE_008_*`
- `docs/BossCat/*202510*`, diagnostic/ECRR/PR-summary/release-notes session files
- `docs/notes/misc/*202510*`, `docs/pr/2025-10/**`, `docs/runbooks/2025-10/**`, `docs/security/*202510*`

Re-measure residual live lint debt after merge before B1 fix batches.

## Batch 3 scope — archive phase closeout

Final dated session / gate-misc closeouts (10 files, ≤10 budget, no cleanup waiver):

- `docs/gate/misc/GATE_006_*`
- MILK / monetization / stakeholder / Bedrock session COMPLETE reports under `docs/notes/misc/`

**Archive phase: CLOSED** after this batch. Residual `*_COMPLETE.md` notes without dates (e.g. `CLEANUP_COMPLETE.md`) stay live pending case-by-case review — not auto-archived.

Next: remeasure markdownlint error count on the live set, then ≤10-file `--fix` batches. B2 lychee measurement unblocked.

## Remeasure (post archive batches 1–3, on closeout branch)

| Probe | Result |
|-------|--------|
| Live `docs/**/*.md` + README (excl. `docs/archive/**` and `docs/gate/archive/**`) | **244** |
| Files with ≥1 markdownlint error | **214** |
| Total errors | **7,402** |
| Prior plan figure @ `4469d10de` | 10,718 / 370 |

First `--fix` batch: 10 low-debt live files (1–3 errors each) cleared to **0** issues — see git history on this branch.
