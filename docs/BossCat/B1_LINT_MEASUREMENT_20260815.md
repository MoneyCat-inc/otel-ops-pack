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
