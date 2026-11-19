# ECRR — glob 10.x and 13.x moved to 14.0.6 with two scoped pnpm overrides; OSV-Scanner on `main` lists no row

**Date:** 2026-11-19
**Actor:** Claude Code (local seat), on the operator's explicit go of 2026-11-16 (section 8) and answers of 2026-11-19 (I1)
**Scope:** PR #946, code lane, merged as `ee2759019` at 2026-11-19T04:24:06Z from the head `797d8d8a8`: `package.json` (3 insertions, 1 deletion) and `pnpm-lock.yaml` (7 insertions, 131 deletions); one commit by the seat, `0fe60c354` (2026-11-17), and GitHub's own branch update of 2026-11-18.
**Verdict:** **GREEN** — glob 10.5.0 and 13.0.7 are out of the lock and their five dependents resolve glob 14.0.6. The first OSV-Scanner run on `main` after the merge (44458070265) lists no row, and it did scan: `pnpm-lock.yaml` with 1,101 packages, and the reporter printed "No issues found" (§3). On the head `797d8d8a8`: 23 check runs, 22 success and `scan-scheduled` skipped by design, with the seven required checks green. The two code-scanning alerts of the glob rows closed and no alert opened (§3). Not shown by any run on GitHub: that the five dependents work with glob 14.0.6, which no workflow exercises; that rests on a local replay, which the review seat reproduced on Linux (§1).
**Trigger:** the fourth follow-up in section 8 of the go: "The glob override, only if the first OSV run after PR 936 still lists glob (code lane)." It did: run 44152364568, on `60e2c9d3`, listed glob 10.5.0 and glob 13.0.7 under GHSA-3g3m-2fjr-6pw4.

## 1. Examine

The advisory ranges, the ranges the dependents declare and the way pnpm matches a selector come from the description of #946, where they were established on 2026-11-17; they were not read again for this report.

- **The two rows are one advisory.** GHSA-3g3m-2fjr-6pw4 covers glob from 9.0.0 to below 14.0.2, so no 10.x or 13.x release clears it. glob 10.5.0 came in through `rimraf` 5.0.10 and `test-exclude` 7.0.2; glob 13.0.7 through `@jest/reporters`, `jest-config` and `jest-runtime` 30.5.2. The root's own `glob` is `^14.0.6`, and `ajv-cli` 5.0.0 brings glob 7.2.3 (it declares `^7.1.0`).
- **Why 14.0.6.** The runbook asks for "14.0.2 or later". A second advisory by glob's maintainer, GHSA-qxr8-q827-836c, covers 13.0.5 to 14.0.5 and was not in OSV when the change was made. `^14.0.6` is also the root's range, so the dependents share the copy the lock already held.
- **Why two selectors.** pnpm 10.18.1 matches an override selector against the range a dependent declares. `glob@10` and `glob@13` move those two majors and nothing else; they cannot reach glob 7.2.3 or the root's own range. The operator kept this form (answers of 2026-11-18, E2: "Keep the two override selectors").
- **A finding from the baseline.** Before this change glob 10.5.0 on `main` found nothing for a pattern with a wildcard: `test-exclude` returned 0 files where the branch returns 32, and `rimraf` with its glob option deleted nothing. From the published sources: the blanket `minimatch` override puts glob 10.5.0 on minimatch 11.0.8, which hands back a `Matcher` object for each wildcard part where glob 10.5.0 tests for a `RegExp`. Nothing in the repository calls those paths, so it was a latent break, and the override removes it for the dependents of glob 10.
- **How the dependents were tested.** No workflow runs jest with coverage, and plain jest never loads glob, so the unit job cannot fail on this change. The proof is a local replay in a throwaway clone (Windows, Node 22.23.2, pnpm 10.18.1, frozen install), once on `main` and once on the branch; its logs and scripts are in the first comment on #946, with corrections in the second. The review seat ran the posted scripts unchanged on Linux (Node 22.23.4, pnpm 10.18.1) with the same results; no run on GitHub records that.
- **Not covered.** glob 7.2.3 stays on minimatch 11.0.8 under the same blanket override. The review seat measured on Linux that it throws on wildcard patterns; the seat measured on Windows, on the branch install, a `TypeError` for every pattern it tried that has a `*` or `?` part. The JSON gate passes `ajv-cli` literal paths only. #946 does not change that pairing.

## 2. Clean

PR #946 is one commit by the seat, `0fe60c354` (2026-11-17T23:17Z, `Actor: Claude Code (local seat)`), and GitHub's own Update-branch merge `797d8d8a8` (2026-11-18T20:56Z, with `main` at `4c3761361`):

- `package.json`: two entries appended to `pnpm.overrides`: `"glob@10": "^14.0.6"` and `"glob@13": "^14.0.6"`.
- `pnpm-lock.yaml`: the two override lines; five snapshot lines changed to `glob: 14.0.6`; 15 packages and their 15 snapshots removed (glob 10.5.0 and 13.0.7 with `path-scurry` 1.11.1 and 2.0.2, `lru-cache` 10.4.3, `jackspeak` 3.4.3 and nine more). The lock was made with `pnpm install --lockfile-only --ignore-scripts`; its 36 `libc:` lines, which a regeneration on this host drops, were put back by script, as in #945.
- On the updated head the lock proof was run again in a fresh clone (answers of 2026-11-18, E2): the regenerated lock is byte for byte the head's lock (sha256 `807d63fc668828d8`), so no further commit was pushed. `main` did not move between that update and the merge.

Not done here: the blanket `minimatch` override, the second overrides block in `pnpm-workspace.yaml` (pnpm 10.18.1 does not use it for the lock), and a coverage step in the unit job, which would be a CI-lane change.

## 3. Report

| Check | Before: `main` at `4c3761361` | #946 at the head `797d8d8a8` | After the merge, `main` at `ee2759019` |
| --- | --- | --- | --- |
| Packages OSV-Scanner reads in `pnpm-lock.yaml` | 1,116 (run 44395911508) | — | **1,101** (run 44458070265) |
| OSV-Scanner rows | push run 44395911508, failure: 2 rows, glob 10.5.0 and glob 13.0.7 | PR scan, run 44396208679: base 2 rows, head **0** | push run 44458070265, success: **no row** |
| Check runs on the head | — | 23: 22 success, 1 skipped (`scan-scheduled`, which runs on push and schedule only); the seven required checks green | merged at that head |
| `unit` job | run 44395209946, the pull-request run on #945's updated head, the content that merged as `4c3761361`: `Packages: +1024`; jest 5 suites, 126 tests; `node --test` 17 of 17; `tsc` clean; ESLint 234 files, 3,336 errors, 1,889 warnings | run 44396208410: `Packages: +1009`; jest 5 suites, 126 tests; `node --test` 17 of 17; `tsc` clean; ESLint 234 files, 3,336 errors, 1,889 warnings | push run 44458069213, success: `Lockfile is up to date`, `Packages: +1009`, jest 5 suites, 126 tests |
| Runs on `main` other than scheduled ones | — | — | 8 on `ee2759019`, all success: seven push runs and Dependabot's own run (next row) |
| Dependabot's own runs | — | — | run 44458223387 (npm, root), success; Dependabot then moved its own #957, which the seat does not touch (answers of 2026-11-18, E5) |
| Open alerts, by the runbook's three commands | 04:19Z: Dependabot 0; code scanning 1 from CodeQL and 2 from `osv-scanner`; secret scanning 0 | — | 04:31Z: Dependabot 0; code scanning 1 from CodeQL; secret scanning 0 |

- **The green OSV run was read, not taken by its colour.** A green run that had not scanned has happened before (run 35538200970). In run 44458070265 the scan job (135337869940) shows the scanner and the reporter as succeeded; its log shows `pnpm-lock.yaml` scanned with 1,101 packages, 15 fewer than the run before, carries no advisory table line and ends with "No issues found". The action's "Check that the scan completed" step is skipped in a green run and ran in the red run before it.
- **Sources.** The ESLint totals come from `eslint-results.json` in each run's `unit-test-results` artifact. The rows of the pull-request scan come from its `old-json-results` and `new-json-results` artifacts; its log prints only "No issues found" for the comparison.
- **Alerts.** The two `osv-scanner` alerts that closed are 11367 and 11431 (both the glob advisory, rated medium). The one from CodeQL is alert 11432, which opened with #943 and is recorded in the lean report for #943 (#955). To tell which alert is new and how it is rated (answers of 2026-11-19, K1), the seat also listed the Dependabot and code-scanning tabs by number, tool, rule and rating; that goes beyond the runbook's "counts and tool names only", and the operator has been told. No secret-scanning alert was listed or opened.
- **The description's expectations, read again after the merge:** `Packages: +1009` with 1,101 packages in the lock, as predicted for the case that #945 merges first. Its sentence that OSV-Scanner "stays red on `main`" was written while other rows remained; they left through #943, #945 and advisory data alone on 2026-11-18, so the run is green.
- **"For the first time" in the squash body is wrong.** The squash body of #946 says OSV-Scanner on `main` is "expected to list no row for the first time". It is the first green run since 2026-09-25: green runs that scanned exist from that day, for example run 36082335303 (1,121 packages, "No issues found"), and the newest before the merge is the scheduled run 36148970175. A commit message on `main` is not rewritten, so the correction stands here.
- **Found, not changed:** the pairing of glob 7.2.3 with minimatch 11.0.8 (§1).
- Proposed fragment for the batch's `BOSSCAT_LOG.md` line (docs lane):

```text
#946 (`ee275901`, 2026-11-19T04:24Z) moved the dependents of glob 10.x and 13.x to glob 14.0.6 with two scoped pnpm overrides (GHSA-3g3m-2fjr-6pw4; 15 packages left the lock). OSV-Scanner on `main` lists no row, for the first time since 2026-09-25 (run 44458070265, read as a scan: 1,101 packages, "No issues found"), and the two `osv-scanner` alerts closed. ECRR `ECRR_GLOB_OVERRIDE_20261119.md`.
```

## 4. Role

Claude Code (local seat): the change, PR #946, its description and its three comments of 2026-11-18 (the proof logs, the corrections, and the lock proof on the head after the branch update of E2), the merge as driver under section 5 of the go (`Driving:` comment on #946 at 04:20Z on 2026-11-19, then the squash `ee2759019`), the readings after the merge, and this report. The seat wrote it from its own logs; one read-only review agent then checked its figures, ids, times and quotations against GitHub and the operator's texts, and its findings are applied (one wrong statement, "for the first time", and five loose ones). Chat/review seat: the review of the head `0fe60c354`, the Linux reproduction of the proof scripts, and the measurement of glob 7.2.3 on Linux. Operator `@fubumaki`: the go of 2026-11-16 (section 8), the instructions of 2026-11-18 (E2, G2, G3) and the go for this merge at `797d8d8a8` (answers of 2026-11-19, I1). Still the operator's: the go for this report (answers of 2026-11-19, J1) and what to do about glob 7.2.3 under the `minimatch` override.

**Status:** CLOSED (2026-11-19T04:24:06Z): merged as `ee2759019`; OSV-Scanner on `main` lists no row.
