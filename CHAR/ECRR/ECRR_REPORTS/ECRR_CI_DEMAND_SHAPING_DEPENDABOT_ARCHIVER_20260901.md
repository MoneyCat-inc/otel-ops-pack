# ECRR — CI Demand Shaping II: Dependabot Grouping + Archiver Cadence

**Date:** 2026-09-01
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
**Verdict:** **GREEN** — two config-only changes attacking the demand share
that path filters (ECRR_CI_DEMAND_SHAPING_PATH_FILTERS_20260901) cannot reach

## 1. Examine

Post-path-filter survey of remaining run demand (all verified live 2026-09-01):

- **Dependabot cascade multiplier.** `.github/dependabot.yml` ran pip and npm
  **daily** across five update configs with **no `groups:` blocks**. August
  produced a 19-PR batch. Branch protection uses `strict` required checks
  (up-to-date-before-merge), so every merge stales every other open PR;
  Dependabot rebases them all; each rebase re-runs the ~10 checks that survive
  the PR path filters (CodeQL ×3, PSScriptAnalyzer, gitleaks,
  gate-site-evidence ×4, guardrails — required or deliberately unfiltered, and
  dependency diffs never match the docs-shaped filters anyway). Cost grows
  roughly quadratically with open-PR count.
- **run-archiver self-demand.** `run-archiver.yml` fired `*/30 * * * *`:
  ~1,490 runs/month, ~11% of August's 13,287 — the Loop-4 cleanup conveyor was
  itself a top run producer. The target repo `MoneyCat-inc/otel-ops-evidence`
  has **no `.github/` directory at all** (nothing fires on its pushes), and its
  last push preceded this audit by ~4 hours — most 30-min cycles are no-op
  polls.
- **Ruled out as further levers** (documented for completeness):
  `gate-site-evidence.yml` filtering needs inverse same-name shims for its
  three required contexts — first lever that *adds* machinery, for ~15-second
  jobs; poor value/risk. `guardrails.yml` checks repo structure, which docs
  diffs change — filtering it would be semantically wrong. Push-to-main
  filters are a coverage-policy change reserved for the operator. Other org
  repos: otel-ops-evidence has zero CI, viz-engine is archived, the rest
  (moneycat-site, scorebot, socm, otel-agent-coordination) have been dormant
  since mid-August or earlier — the demand problem lives entirely in this repo.

## 2. Clean

Subtraction/config-only; two files, no new machinery, no coverage loss:

| Change | Before | After | Why safe |
| --- | --- | --- | --- |
| `dependabot.yml`: `groups:` per ecosystem (version-updates and security-updates grouped separately), pip/npm root cadence daily → weekly | 5 ungrouped configs, pip/npm daily | 5 grouped configs, all weekly | Same dependencies still updated; one PR per ecosystem per interval instead of one per package. Security updates keep their own grouped PR so they land promptly and visibly. |
| `run-archiver.yml`: cron `*/30 * * * *` → `19 * * * *` | 48 runs/day | 24 runs/day | Evidence-latency only; no downstream CI on the evidence repo (verified). Off-hour minute dodges top-of-hour scheduler congestion. `workflow_dispatch` unchanged for on-demand runs. |

Registry note: `docs/status/workflows.json` compares trigger *booleans* only
(registry-guard deep semantic check); `schedule`/`workflow_dispatch` remain
true for run-archiver, so no regeneration is required.

## 3. Report

- **Archiver:** deterministic −~745 runs/month (~5–6% of August total).
- **Dependabot:** August's 19-PR batch becomes ~3–5 grouped PRs per week of
  updates; the strict-mode rebase cascade shrinks roughly quadratically with
  open-PR count. Estimated −5–15% of total runs depending on update mix —
  honest range, not a promise; the required lanes still run on every real
  dependency PR push, as they should.
- **Trade-offs accepted:** grouped PRs are larger to review (these are small
  tool dirs, not an app); a failing grouped update blocks its whole group
  until resolved; dependency updates land weekly instead of daily (security
  updates excepted — Dependabot raises grouped security PRs as alerts arrive,
  not on the weekly schedule).
- **Measure at the 2026-10-01 rollup**, jointly with the path-filter ECRR:
  re-run September per-workflow counts; expect run-archiver ≈ 720 (from
  ~1,490) and a visibly thinner Dependabot-week signature. Combined with path
  filters, the honest overall estimate is a 25–40% cut versus August.

## 4. Role

Claude (chat/review) surveyed remaining demand after the path-filter merge
(PR #694), verified the evidence repo's CI absence and org repo dormancy live,
edited two config files, and opened the PR under the operator's standing
delegation. PR left for operator review/merge. No credentials, no elevation.

**Status:** COMPLETE (pending PR review/merge)
