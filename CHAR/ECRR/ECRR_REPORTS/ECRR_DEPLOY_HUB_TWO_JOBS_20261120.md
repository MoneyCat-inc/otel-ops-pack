# ECRR — Deploy Hub Website builds and deploys in two jobs

**Date:** 2026-11-20
**Actor:** Claude Code (local seat), on the operator's answers of 2026-11-20 (S3) and their second block (U1, W2)
**Scope:** PR #962, CI lane, merged as `065cb3ccf` at 2026-11-20T18:46:38Z from the head `870f1feee`, which sat on `main` at `472129a34` (no branch update): `.github/workflows/deploy-hub.yml` (10 insertions, 4 deletions) and the regenerated `docs/status/workflows.json` (one line); one commit by the seat.
**Verdict:** **GREEN** — for what S3 asked: the workflow on `main` builds the hub in one job and deploys it in a second, and its first run, 44795968450, started by the merge itself, deployed the hub from `main`: both jobs success, and the hub serves the reports of #959 and #960 (§3). On the head `870f1feee`: 25 check runs, 24 success and `scan-scheduled` skipped by design, with the seven required checks green. Not shown: why the deploy step found no artifact on the two failed pushes, or that the split prevents it (two runs of the new file so far; §3).
**Trigger:** point S3 of the operator's answers of 2026-11-20, after Deploy Hub Website had failed on two merges in a row and the one re-run that was allowed had failed as well: "Open, and do not merge, one CI-lane pull request that changes only .github/workflows/deploy-hub.yml and the regenerated docs/status/workflows.json".

## 1. Examine

- **What the workflow did.** `deploy-hub.yml` deploys the hub (`hub.resonai.uk`) on every push to `main` that touches the site's paths, `CHAR/**` and `docs/**` among them. It had one job, `deploy`, with six steps: check out, set up Pages, build the site folder, pack it, upload it as the artifact `github-pages`, and deploy it with `actions/deploy-pages@v5`. That last step first asks GitHub for the run's artifacts of that name.
- **Three attempts failed in that step.** The times are from the job logs:

| Run, attempt | Started by | Upload finalized | The deploy step asked | It found | Outcome |
| --- | --- | --- | --- | --- | --- |
| 44623595257, 1 (the last good run) | the merge of #955, `ea76c1adf` | 2026-11-19T21:55:45.57Z | 0.45 s later | one artifact | deployed |
| 44624637058, 1 | the merge of #959, `ba74fcb5f` | 2026-11-19T22:02:15.24Z | 0.45 s later | none | failed: `No artifacts named "github-pages" were found for this workflow run` |
| 44694482152, 1 | the merge of #960, `472129a34` | 2026-11-20T07:22:40.43Z | 0.42 s later | none | failed with the same error |
| 44694482152, 2 (the one re-run) | the seat's re-run, started at 07:22:52Z | 2026-11-20T07:23:07.83Z | 0.33 s later | two | failed: `Multiple artifacts named "github-pages" were unexpectedly found for this workflow run. Artifact count is 2.` |

- **What did not differ.** All four attempts resolved the same action commits (`checkout` 3d3c42e5, `configure-pages` 45bfe019, `upload-artifact` cf430e03, `deploy-pages` 368f8252). The good run and the first failure ran on the same runner image (ubuntu-26.04, 20261111.196.1), six and a half minutes apart; the two attempts of run 44694482152 ran on the next image (20261116.202.1). Between the good run and the first failure only a report file changed in this repository.
- **The re-run.** The operator's third block of 2026-11-19 (P2) allowed one re-run of the failed job for this error, and the merge tool made it for run 44694482152. In a one-job workflow the re-run uploads again, so the run then held two `github-pages` artifacts and the deploy step refused them. The operator withdrew P2 in the answers of 2026-11-20 (S1): "The re-run that P2 allowed could not work in this workflow, because its one job both uploads and deploys."
- **What the hub served meanwhile.** The deployment of run 44623595257, built from `ea76c1adf`: the hub stayed up, without the reports of #959 and #960. Read on 2026-11-20 at 18:41Z, before the fix: the root answered HTTP 200 with `Last-Modified: Thu, 19 Nov 2026 21:55:50 GMT`, and the two report pages answered 404.
- **Two stops.** The seat stopped after each failed run (go, section 5). The operator's blocks name the stops by 2026-11-19 22:02Z and 2026-11-20 07:23Z; the third block of 2026-11-19 (P1) lifted the first, and the second block of 2026-11-20 (U2) lifted the second for four named merges.

## 2. Clean

PR #962 is one commit by the seat, `870f1feee` (2026-11-20, `Actor: Claude Code (local seat)`):

- **Two jobs in place of one.** `build` holds the five existing steps, moved unchanged, up to and including the upload of `github-pages`. `deploy` has `needs: build`, takes over the `environment` block and holds only the step "Deploy to GitHub Pages".
- **Unchanged:** the triggers and their paths, the workflow-level permissions, the concurrency block, the artifact's name, every action version, and the build script.
- **Beyond the wording of S3:** two comment lines in the file's header (one dated note, wrapped). The description of #962 said so, and the operator's go names them (second block of 2026-11-20, U1: "with its two header comment lines").
- `docs/status/workflows.json`: one line, the size of this workflow (2,485 to 2,745 bytes), written by `scripts/regenerate-workflows-registry.ps1`. `Verify Registry Freshness` checks it with the workflow file.

Not done here: a retry inside the deploy job, a newer action version, a dispatch.

## 3. Report

| Check | Before: `main` at `472129a34` | #962 at the head `870f1feee` | After the merge: `main` at `065cb3ccf` |
| --- | --- | --- | --- |
| Jobs of Deploy Hub Website | one, `deploy` | a pull request does not start this workflow | two: `build`, then `deploy` |
| The run of the push | 44694482152: failed in both attempts (§1) | — | 44795968450: `build` success (18:46:45Z to 18:46:55Z), `deploy` success (18:46:59Z to 18:47:07Z); one attempt |
| From the upload's end to the deploy step's question | 0.42 s and 0.33 s, inside the one job | — | 7.42 s, across the two jobs: finalized 18:46:53.68Z, asked 18:47:01.09Z, "Found 1 artifact(s)" |
| `github-pages` artifacts of the run | two | — | one |
| The hub | root HTTP 200, `Last-Modified` of 2026-11-19 21:55:50 GMT; the reports of #959 and #960: 404 (read 18:41:42Z) | — | root HTTP 200; both reports HTTP 200, byte for byte the files on `main` (read 18:47:20Z) |
| Check runs on the head | — | 25: 24 success, 1 skipped (`scan-scheduled`); the seven required checks green; `Verify Registry Freshness` success | — |
| `unit` job | — | the jest, `node --test`, `tsc` and ESLint steps success | — |
| OSV-Scanner rows | 1: `effect` 3.20.0 in `pnpm-lock.yaml` (GHSA-7589-6fvf-x4pw, rated high) | PR scan, run 44696672484: 1 on the base, 1 on the head, none added | push run 44795970211: the same row and no other |
| Runs on `main` other than scheduled ones | 8 on `472129a34`: Deploy Hub Website failed (above), OSV-Scanner failed for the one row, the other six success | — | 9 on `065cb3ccf`: OSV-Scanner failed for the one row, the other eight success, Deploy Hub Website among them |
| Open alerts, by the runbook's three commands | 18:41Z: Dependabot 1 (alert 632); code scanning 1, from osv-scanner (alert 11433); secret scanning 0 | — | 18:52Z: the same two alerts and no other; secret scanning 0 |

- **The one OSV row and the two alerts** are one advisory, GHSA-7589-6fvf-x4pw, rated high, for `effect` 3.20.0. The version was in the lock on `main` before this batch (at `b8428c4d`), so the operator's rules read the row as advisory-only (answers of 2026-11-18, E4; third block of 2026-11-19, Q1): it is told, and it is not a stop. #962 does not touch it.
- **The next push.** The merge of #961 (`f2e3ec506`, 18:55:36Z), the lean report for #948, started run 44797348763: `build` success (18:55:41Z to 18:55:52Z), `deploy` success (18:55:57Z to 18:56:05Z), one attempt, one artifact; the deploy step asked 8.12 s after the upload's end and found the one artifact.
- **Runner images of the new runs.** In run 44795968450 `build` ran on ubuntu-26.04 20261116.202.1 and `deploy` on 20261111.196.1; in run 44797348763 both ran on 20261116.202.1. The failures of §1 happened on both of these images, so the image does not separate good runs from bad ones.
- **What is shown, and what is not.** Shown: on the two failed pushes the deploy step asked for the run's artifacts within half a second of the upload's end and was told there were none. Not shown: why GitHub listed none at that moment. The good run before them asked just as early (0.45 s) and found the artifact, so the timing alone does not separate good runs from bad ones either. That a job of its own for the deploy prevents the failure is a reading: the new file has run twice so far, and each time the deploy step asked seconds after the upload and found the one artifact. Two runs cannot show that it always will: the one-job file had deployed the four pushes before #959 without this error too (runs 44459909267, 44460968622, 44461437998 and 44623595257). Eight of the nine Pages starter workflows in `actions/starter-workflows`, as the seat read them on 2026-11-20, build and deploy in two jobs (`static.yml` has one).
- **What the split gives by construction.** A failed `deploy` job can be re-run alone; that re-run uploads nothing, so the run still has one `github-pages` artifact. This is untried: neither run has needed it. The operator's second block of 2026-11-20 (V3) allows the seat one such re-run, and only for the runs that its four named merges start, when the build job has succeeded and the run lists exactly one `github-pages` artifact. It is not a standing rule.
- **Never re-run** run 44694482152 or run 44624637058: a re-run executes the one-job workflow file of its own commit.
- **The mirror.** `CHAR/DOCS/docs/status/workflows.json` differs from `docs/status/workflows.json` until the batch's mirror republish.
- No log fragment is proposed here: the batch's log line carries the hub's part as the operator's second block of 2026-11-20 gives it (X2).

## 4. Role

Claude Code (local seat): the stops after the two failed runs, the re-run of 07:22:52Z under P2, the reading of the four attempts, the change, PR #962 and its description, the merge as driver under section 5 of the go (`Driving:` comment on #962 at 18:41Z, with a link to the one on #959; the squash `065cb3ccf`), the reading of run 44795968450 job by job, and this report. The seat wrote it from the job logs, the saved API answers and the merge-time readings; one read-only review agent then checked it against those and the operator's texts, and its findings are applied (the time of the re-run, the scope of V3, the count of earlier good runs, the runner images of the new runs, and what the verdict leaves open). Chat/review seat: by its note to the operator it read the change before the go (both workflow files parsed, the six steps compared) and it wrote the blocks the operator adopted. Operator `@fubumaki`: the answers of 2026-11-20 (S1 to S4) and the go for this merge at `870f1feee` (second block, U1). Still the operator's: the go for this report (second block, W2).

**Status:** CLOSED: merged as `065cb3ccf` (2026-11-20T18:46:38Z); the first run of the new file deployed the hub.
