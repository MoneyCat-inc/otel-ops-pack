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
