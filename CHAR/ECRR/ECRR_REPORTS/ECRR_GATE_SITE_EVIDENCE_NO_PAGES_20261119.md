# ECRR — gate-site-evidence no longer deploys to Pages, and takes k6 from the pinned setup action

**Date:** 2026-11-19
**Actor:** Claude Code (local seat), on the operator's answers of 2026-11-18 (F1) and of 2026-11-19 (I3)
**Scope:** PR #948, CI lane, merged as `852cd8fa7` at 2026-11-19T04:40:14Z from the updated head `89b99c075`: `.github/workflows/gate-site-evidence.yml` (16 insertions, 15 deletions) and the regenerated `docs/status/workflows.json` (one line); one commit by the seat, `c0d7f09ac` (2026-11-18), and GitHub's own branch update of 2026-11-19.
**Verdict:** **AMBER** — the workflow on `main` can no longer replace the hub site: its publish job uploads the status folder as a run artifact, and the workflow holds no Pages permission (§2). On the updated head `89b99c075`: 26 check runs, 25 success and `scan-scheduled` skipped by design, with the seven required checks green; the new upload ran on the pull request itself. AMBER because the new `Setup k6` step has never run in this workflow: a pull-request run skips the k6 steps, and nobody dispatches the workflow until the operator says so (§3). Closes GREEN with an addendum when a dispatch the operator has allowed shows the k6 job passing.
**Trigger:** point F1 of the operator's answers of 2026-11-18, after the dispatch of 2026-11-17 (run 44153344159) had failed in `Install k6` and had replaced the hub site on Pages: "Open, and do not merge, one CI-lane pull request that changes only .github/workflows/gate-site-evidence.yml and docs/status/workflows.json". F1 also says: "Its lean report follows its merge, as section 8 says, and covers the outage and the k6 failure."

## 1. Examine

- **What the workflow did on a dispatch.** `gate-site-evidence.yml` has two triggers: `pull_request` on `main`, where its three gate jobs are required checks, and `workflow_dispatch`. Its fourth job, the publish job, uploaded its `status` folder (two files, `LATEST.json` and `LATEST.md`) as a Pages artifact and, on a dispatch only, deployed it. This repository has one Pages site, the hub, which `deploy-hub.yml` deploys on pushes to `main`. So each dispatch put a two-file bundle in the hub's place until the next push that started `deploy-hub.yml`.
- **The two outages.** The workflow has two dispatch runs, and both replaced the hub:

| Dispatch run | On | Jobs | Hub replaced | Hub back |
| --- | --- | --- | --- | --- |
| 41333286676, 2026-11-01T17:47Z | `1bd34fa4b` | all four success | 17:49Z (deploy step 17:49:04Z to 17:49:11Z) | 17:56Z, `deploy-hub.yml` run 41333961928 on the push of #882: about seven minutes |
| 44153344159, 2026-11-17T18:57Z | `60e2c9d3f` | "Gate • k6 thresholds" failure in `Install k6`; "Gate • synthetic trace (OTLP/HTTP)", "Site • links + a11y + CSP (coarse)" and the publish job success | 18:58Z (deploy step 18:58:08Z to 18:58:16Z) | 22:32Z, `deploy-hub.yml` run 44190907914 on the push of #941: about 3 h 34 min |

- **How the second one was found.** The seat's stop report of 2026-11-17 18:58Z named the failed k6 job and not the publish job's deployment, and the operator answered that stop without knowing of it. The chat/review seat found the outage in its review; the push of #941 restored the hub at 22:32Z. The operator's answers of 2026-11-18 let the merges of #941 and #942 stand (A1) and set three rules: a stop report lists every job of the failed run and what each changed outside the run (C1); a fact left out of a stop report that could have changed the answer reopens that stop (C2); nobody dispatches this workflow until its repair is on `main` and the operator says so (C3). The dispatch of 2026-11-17 had been proposed by the chat/review seat (point 3 of the supplement of 2026-11-16 to the go), as the log line of 2026-11-18T16:56Z records.
- **The k6 failure.** In run 44153344159 `ubuntu-latest` was Ubuntu 26.04. The `Install k6` step wrote a keyring and added k6's apt repository; apt ignored the keyring ("unsupported filetype") and refused the repository (`NO_PUBKEY`), and the step ended with exit code 100. On 2026-11-01, on Ubuntu 24.04, the same step had passed. The step installed whatever k6 was current, 2.3.0 on 2026-11-01.

## 2. Clean

PR #948 is one commit by the seat, `c0d7f09ac` (2026-11-18, `Actor: Claude Code (local seat)`), and GitHub's own Update-branch merge `89b99c075`:

- **Pages.** The publish job's Pages upload step and its deploy step are removed. The `status` folder is uploaded with `actions/upload-artifact@v7` as `ecrr-status`, kept 14 days. `pages: write` and `id-token: write` are removed from the workflow-level `permissions`, the only place they stood, so all four jobs have `contents: read` only. The job is renamed "Publish status bundle as run artifact (no trunk writes)"; it is not a required check.
- **k6.** `Install k6` is replaced by the `Setup k6` step of `gate-026-performance.yml`: the same pinned commit of the setup action and `k6-version: '0.57.0'`, with the condition of the step it replaces.
- **Unchanged:** the two triggers, the three required job names, the concurrency block, the jobs `gate_trace` and `site_checks`, and every other step of `gate_perf`.
- `docs/status/workflows.json`: one line, the size of this workflow (9,900 to 10,017 bytes), written by `scripts/regenerate-workflows-registry.ps1`. Registry Guard requires it with the workflow file, as in #914.

Where the change goes beyond the wording of F1 (the artifact's name and its 14 days, the permissions removed at workflow level, the job's new name, the tag `@v7`) is listed in the description of #948, each with its smallest alternative; the operator gave the go for the head as it stood.

Not done here: a dispatch, and a newer k6.

## 3. Report

| Check | `main` at `d5b54848d` | #948 at the updated head `89b99c075` | After the merge, `main` at `852cd8fa7` |
| --- | --- | --- | --- |
| Pages permissions in the workflow | `pages: write`, `id-token: write` | none; `contents: read` only | none |
| Publish job | uploads a Pages artifact; deploys on a dispatch | "Publish status bundle as run artifact (no trunk writes)": success, the `ecrr-status` upload ran | — |
| k6 step of the gate job | `Install k6` (apt) | `Setup k6`, skipped on a pull request like the step it replaces | **not run yet** |
| Check runs on the head | — | 26: 25 success, 1 skipped (`scan-scheduled`); the seven required checks green; `Verify Registry Freshness` success | — |
| `unit` job | — | run 44459515400: `Packages: +1009`; jest 5 suites, 126 tests; `node --test` 17 of 17; the `tsc` and ESLint steps success | — |
| OSV-Scanner rows | push run 44459323034, success: no row | PR scan, run 44459515695: no row on the base, none on the head | push run 44459909755, success: no row |
| Runs on `main` other than scheduled ones | 8 on `d5b54848d`, all success | — | 9 on `852cd8fa7`, all success, among them Deploy Hub Website (run 44459909267), which deployed the hub from `docs/` as before |
| Open alerts, by the runbook's three commands | 04:31Z: Dependabot 0; code scanning 1 from CodeQL; secret scanning 0 | — | 04:46Z: Dependabot 0; code scanning 1 from CodeQL; secret scanning 0: nothing new |
| Dispatch runs of the workflow | two: 41333286676 and 44153344159 | none | none: C3 stands |

- **What is not proven.** The pinned commit of the setup action has run only on `windows-latest` in this repository, in `gate-026-performance.yml`. The action's `v1` tag with the same k6 version ran once on `ubuntu-latest`, on 2026-07-24 (run 30115733634 of `perf-gate-demo.yml`), and passed; nothing has run it on Ubuntu 26.04. The description of #948 says it "has never run on Ubuntu in this repository", which is too wide by that one run. k6 goes from the 2.3.0 the apt step installed on 2026-11-01 back to the pinned 0.57.0; the gate script (`ALFA/TEST/load/k6/gate-simple.js`) uses `http.get`, `sleep` and two thresholds, which was read, not run. The setup action downloads the k6 release archive over HTTPS and checks no checksum or signature, where apt checked a repository signature.
- **A required check now fetches the setup action on every pull request.** The runner downloads every action a job names while it sets the job up, also for a step it then skips. "Gate • k6 thresholds" passed on `89b99c075` with the new step in place.
- **Other open pull requests** show the publish job under its old name until their branches are updated.
- **Never re-run runs 44153344159 or 41333286676.** A re-run executes the workflow file of its own commit, with the deploy step, and would replace the hub again.
- Proposed fragment for the batch's `BOSSCAT_LOG.md` line (docs lane):

```text
#948 (`852cd8fa`, 2026-11-19T04:40Z) repaired `gate-site-evidence.yml` after the hub outages of 2026-11-01 and 2026-11-17: the publish job uploads its status bundle as a run artifact and the workflow holds no Pages permission; k6 comes from the pinned setup action (0.57.0) instead of apt. The new k6 step is untested in this workflow until the operator allows a dispatch (answers of 2026-11-18, C3). ECRR `ECRR_GATE_SITE_EVIDENCE_NO_PAGES_20261119.md`.
```

## 4. Role

Claude Code (local seat): the dispatch of 2026-11-17 and its incomplete stop report, the reading of the four runs on 2026-11-18, the change, PR #948 and its description, the merge as driver under section 5 of the go (`Driving:` comment on #946 at 04:20Z on 2026-11-19; GitHub's Update branch to `89b99c075`, then the squash `852cd8fa7`), and this report. The seat wrote it from the runs and the description; one read-only review agent then checked it against GitHub and the operator's texts, and its two findings are applied. Chat/review seat: it proposed the dispatch of 2026-11-17, found the outage, and reviewed the head `c0d7f09ac`. Operator `@fubumaki`: the answers of 2026-11-18 (A1, C1 to C3, F1) and the go for this merge at `c0d7f09ac` (answers of 2026-11-19, I3). Still the operator's: the go for this report (answers of 2026-11-19, J1), and whether and when a dispatch is allowed.

**Status:** OPEN: merged as `852cd8fa7` (2026-11-19T04:40:14Z); closes with an addendum when a dispatch the operator has allowed shows the k6 job passing.
