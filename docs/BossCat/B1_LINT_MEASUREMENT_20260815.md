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
| Live set (glob method, see command below) | **271** files |
| Total errors (post fix1, this branch head) | **6,445** |
| Prior plan figure @ `4469d10de`, same method | 10,718 / 370 |

**Canonical command** (run from repo root; this is the CI config-resolution path —
`.markdownlint-cli2.yaml` base merged with `.markdownlint.json`, so MD013 enforces at 120):

```bash
npx --yes markdownlint-cli2@0.14.0 --config .markdownlint-cli2.yaml   "docs/**/*.md" "README.md" "!docs/archive" "!docs/gate/archive"
```

> Correction (OEM verify, 2026-08-15): an earlier revision recorded **7,402 / 244** here.
> That run did not reproduce under the command above (file count and error total both off;
> the error gap is consistent with MD013 falling back to 80 chars when the
> `.markdownlint.json` merge is missed) and stated no command. Superseded by the
> reproducible series: **10,718/370 → 6,445/271**. Numbers without commands are claims.

First `--fix` batch: 10 low-debt live files (1–3 errors each) cleared to **0** issues — see git history on this branch.

## Fix batch 2 (2026-08-15)

| Probe | Result |
|-------|--------|
| Before (canonical command @ `903b20df6`) | **6,445** / **271** (Linting: 272 = live docs + README) |
| Batch (10 files → 0 issues) | PATREON / PHASE3 / ReviewerB / ART_OF_ECRR / BSKY×2 / GATE_DECISIONS / KOFI weekly / SBOM_AUDIT / cheatsheets/cursor-support-runbook |
| After (same command) | **6,401** / **271** |

Skipped generated `docs/BossCat/AGENTS.md` (regen via `pnpm agent:setup`).
