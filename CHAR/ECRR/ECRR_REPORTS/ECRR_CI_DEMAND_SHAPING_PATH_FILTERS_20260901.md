# ECRR — CI Demand Shaping: PR Path Filters (Non-Required Lanes)

**Date:** 2026-09-01
**Actor:** Claude (chat/review), execution under standing delegation from `@fubumaki`
**Verdict:** **GREEN** — four workflows path-filtered, zero required-check exposure; four of the originally-named eight skipped with cause (two retired, two app-bound required checks)

## 1. Examine

13,287 workflow runs since 2026-08-01 (~430/day), dominated by workflows firing on every PR push regardless of diff content. Verified live before touching anything:

- **Branch protection** (`branches/main/protection/required_status_checks`, `rules/branches/main` = `[]`, no rulesets): required contexts are `CodeQL` (app 57789), `PSScriptAnalyzer` (app 57789), `gitleaks`, `Gate • k6 thresholds`, `Gate • synthetic trace (OTLP/HTTP)`, `Site • links + a11y + CSP (coarse)`, and `Repository Structure Compliance` (new since the shim contract's 2026-07-24 header; from guardrails.yml). `docs/BossCat/REQUIRED_STATUS_CHECKS.md`'s claim that `bosscat-gate-verify` is required is **stale** — it is not in the live config.
- **Run volume since 08-01:** trivy 849, osv-scanner 858, bosscat-governance 841, bosscat-gate-verify 841 (× 4-site matrix = ~3,364 jobs), codeql 846 (× 3 languages), powershell 846, gitleaks 873.
- **Stale premises found:** `gitleaks-security-scan.yml` and `bosscat-tetragram-guard.yml` were retired 2026-08-03 (workflow_dispatch only) — no PR volume to shape. The live gitleaks lane is `gitleaks.yml`.

## 2. Clean

Subtraction/config-only, `pull_request` triggers only; `push` (main), `schedule`, `merge_group`, `workflow_dispatch`, and all concurrency blocks untouched.

**Filtered (none reports a required context — no shims needed):**

| Workflow | Filter | Why |
| --- | --- | --- |
| trivy-security-scan.yml | `paths`: `docker-compose*.yml`, `compose/**`, own file | Scans docker-compose.yml config + image pins that live in the workflow file itself; nothing else in a PR changes its results. Kills every Dependabot-lockfile-PR run. |
| osv-scanner.yml | `paths-ignore`: `docs/**`, `**/*.md` | Docs-only diffs cannot introduce dependency vulns; positive manifest globs rejected (ecosystem-enumeration risk). |
| bosscat-governance.yml | `paths-ignore`: `docs/**`, `**/*.md` | Substantive checks (scripts/*.ps1 syntax, ECRR-on-script-change) unaffected by docs diffs. Accepted loss: commit-message lint on docs-only PRs — repo squash-merges (branch subjects discarded) and docs PRs have docs-lane-checks.yml. |
| bosscat-gate-verify.yml | `paths-ignore`: `docs/**`, `**/*.md` | Heaviest PR lane (4 jobs × pnpm install per push). `assets/**` deliberately NOT ignored — guard-required-files.sh asserts the mascot under assets/. |

**Skipped with cause:**

| Workflow | Reason |
| --- | --- |
| codeql.yml | Required context `CodeQL` is bound to github-code-scanning (app 57789); an Actions shim can never satisfy it, so a filtered PR would deadlock at "Expected". Repo contract (file header + shim contract) already forbids filtering. |
| powershell.yml | Same app-57789 binding for `PSScriptAnalyzer`; same deadlock. Its header already says "No path filters". |
| gitleaks-security-scan.yml | Retired 2026-08-03, dispatch-only; the "3 pull_request references" are step conditions, not triggers. Nothing to filter. |
| bosscat-tetragram-guard.yml | Retired 2026-08-03, dispatch-only. Nothing to filter. |
| gitleaks.yml (live substitute for the retired file) | Required Actions context `gitleaks`, and secret scanning is content-agnostic — secrets leak in .md files too, and a PR-time skip would land the leak on main before detection. Filtering is semantically wrong regardless of shims; its header forbids it. |

`required-check-shims.yml` header + contract job extended with the 2026-09-01 audit: filtered set verified non-required, `Repository Structure Compliance` addition recorded, re-introduction rule stated (shim or unfilter before any filtered workflow is promoted to required).

## 3. Report

- Before: the four filtered workflows produced 3,389 of 13,287 runs since 08-01 (~26% of runs; a larger share of job-minutes — gate-verify alone is ~3,364 matrix jobs with pnpm installs).
- After: those runs stop for docs/markdown-only pushes and (trivy) for all dependency-only pushes; Dependabot update-branch cascades no longer re-run trivy at all. Exact reduction depends on diff mix; honest estimate is a 15–25% cut in total runs, concentrated in the most expensive lane. Measure at the 2026-10-01 rollup: re-run the per-workflow counts above for September.
- Coverage unchanged on main (push), schedules, and merge queues; required checks untouched by construction.
- Residual risk: if a filtered workflow is later added to branch protection without a shim, docs-only PRs will hang at "Expected" — the shim contract header now documents the cure.

## 4. Role

Claude (chat/review) audited live branch protection, edited four trigger blocks plus the shim contract, and opened the PR under the operator's standing delegation. PR left unmerged for operator review per task instruction. No credentials, no elevation.

**Status:** COMPLETE (pending PR review/merge)

---

## Measurement Addendum — 2026-10-01 (rollup checkpoint)

Measured, not derived: every figure below is a count of workflow runs from the Actions API
(`/actions/runs`, `created=` windows of one day or less, so no window hits the API's
1,000-result listing limit or the 2,500 `total_count` cap; run inventory saved per month and
re-summed). Counting is complete: `run-archiver.yml` runs with `permissions: actions: read`, so
its delete lane cannot delete anything — today's August recount (12,452) plus the 897 runs of
2026-09-01 before 16:00 UTC reproduces the 13,287 "since 08-01" recorded above on 09-01.

### Headline

| | August 2026 | September 2026 | Δ |
| --- | --- | --- | --- |
| Total runs | 12,452 (402/day) | 4,076 (136/day) | −67% |
| Pre-filter 09-01 (before #694 merged 16:00:24Z) | — | 897 | ~16 h of unshaped traffic, counted in Sept |
| Post-filter (09-01 16:00Z → 09-30) | — | 3179 (108/day) | |

The −67% is **not** this ECRR's effect. Two things it cannot claim:

- **5,033 August runs (40%) came from workflows that no longer exist.** Eleven push-triggered
  workflows at exactly 383 runs each (`rsi-sweep-nightly`, `bosscat-branch-protection`,
  `status-auto-update`, `nightly-tetragrammaton-benchmarks`, `adot-config-gate`,
  `signoz-automation`, `nightly-dashboard-export`, `repository-security-check`, `stress-test-pr`,
  `guardrails-recert`, `nightly-dashboard-reports`) fired on every branch push from 08-02 to
  08-17 before their retirement took effect, plus `k6-performance-gate` 368, `hub-smoke` 106,
  `icf-smoke` 90. September has zero runs of any of them. August on surviving workflows only:
  7,419 (239/day).
- **August was burst-shaped.** 08-13 to 08-15 alone produced 6,384 runs (51% of the month;
  deep-clean + Kiro pilot). The per-day median was 205 in August and 21 in September.

### The four filtered lanes

| Workflow | Aug runs (Aug proper; ECRR §1 figures were "since 08-01" incl. 09-01 morning) | Sept runs | Share of PR pushes that ran the lane, Aug → Sept post-filter |
| --- | --- | --- | --- |
| trivy-security-scan | 756 | 249 (−67%) | 100% → **3%** |
| osv-scanner | 766 | 347 (−55%) | 50% → 45% (already filtered before this ECRR) |
| bosscat-governance | 749 | 343 (−54%) | 99% → **45%** |
| bosscat-gate-verify | 749 | 343 (−54%) | 99% → **45%** |
| codeql / gitleaks (required, unfiltered) | 754 / 780 | 471 / 497 | 99% → 100% |

Runs per PR push (surviving workflows): 8.60 → 7.79 (−9%), net of the docs lanes
(`docs-lane-checks`, `docs-guard`, `guardrails`) that docs PRs trigger instead.
`bosscat-gate-verify` wall time: 23.7 → 10.7 run-hours (−55%; median run 98 → 101 s).

Caveat that flatters the filters: 55% of September's PR pushes were docs-only — the
2026-09-02 docs truth sweep (#704–#719) and its follow-ups. A code-heavy month will show a
smaller governance/gate-verify cut; the trivy cut (dependency-only pushes) should hold.

### Effect isolated on September's own volume

What September would have cost at August's per-event behaviour, component by component, on
September's actual 226 post-filter PR pushes, 23 Dependabot PRs and 29.3 days:

| Component | Runs avoided in Sept |
| --- | --- |
| trivy on every PR push | +220 |
| governance + gate-verify on docs-only pushes | +250 |
| Dependabot rebase cascade (10.7 → 4.4 pushes per PR; ECRR II) | +1273 |
| run-archiver cadence (ECRR II) | +498 |
| **Counterfactual** | **5420** vs actual 3179 → **−41%** |

**Verdict:** the combined 20–35% estimate (as corrected in ECRR II) is **met and exceeded on a
like-for-like basis**: −41% of what September would otherwise have run, above the range. The
least certain term is the Dependabot cascade (+1,273), which compares August's single 19-PR
batch with six batches of 4–5; without it the three firmer components give −23%, inside the
range. The raw "vs August" number (−67%) is dominated by retired workflows and activity level
and must not be quoted as the result of these changes. Required-check coverage unchanged, as
designed: CodeQL and gitleaks ran on 100% of PR pushes.

**Addendum status:** ACTIVE — §3's "measure at the 2026-10-01 rollup" is discharged; the
15–25% path-filter estimate stands as measured on the filtered lanes, with the mix caveat.
Original text above left intact per audit-trail convention. Actor: Claude (chat/review),
scheduled rollup requested by `@fubumaki` on 2026-09-01.
