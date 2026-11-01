# ECRR — Actions billing lock: 16 days without scheduled scans (2026-10-16 → 2026-11-01)

**Date:** 2026-11-01
**Actor:** Claude Code (local seat), from the operator's checkout. Measurements via the Actions and Dependabot REST APIs with the operator's `gh` auth (repo scope); the billing endpoints need `admin:org` and were not readable from this seat.
**Verdict:** **CLOSED for the incident (it was RED while it lasted); OPEN for detection (F2) and for the meter behind the invoice (F3).** No residual exposure found: nothing merged during the lock, no credential expired inside the gap, every scanner is green again on `main`.
**Trigger:** the 2026-11-01 Dependabot batch review (operator: "11 dependency PRs waiting to be processed") found eight of ten bot PRs red with every check failing in 1–3 s. The first job annotation read: *"The job was not started because your account is locked due to a billing issue."*

## 1. Examine

### 1a. Timeline (UTC)

| When | What |
| --- | --- |
| 2026-10-15T23:04:09Z | Last successful GitHub-hosted run before the lock (Archive & Analyze Workflow Runs, schedule). |
| 2026-10-16T04:31:37Z | First refused run (Archive & Analyze, schedule): job `completed/failure`, zero steps, the billing annotation. Every GitHub-hosted job after it carries the same annotation. |
| 2026-10-16T07:00:45Z | Gate Nightly Verification `verify` runs 14 steps on the self-hosted runner `otel-windows` (24 s) and fails at `actions/upload-artifact`: *"Failed to CreateArtifact: Artifact storage quota has been hit. Unable to upload any new artifacts."* Daily until 2026-11-01T09:02Z, 17 runs, same shape. |
| 2026-10-16 → 2026-11-01 | Dependabot's own updater jobs (event `dynamic`, Dependabot's infrastructure) keep running: 75 success / 16 failure; 14 of the 16 are the deployment-pipeline corepack defect fixed by #872, not the lock. |
| 2026-10-19 → 2026-10-26 | Dependabot opens the weekly batch (#861–#870); each PR's checks fail at start. The two PRs created before the lock (#857 on 10-13, #860 on 10-14) keep their green checks. |
| 2026-11-01T09:49:20Z | The scheduled monthly evidence rollup for October is refused. |
| 2026-11-01 ≈14:50Z | Found during the batch review; operator pointed to the organization's billing page. |
| 2026-11-01T15:00:57Z | Test re-run (OSV-Scanner, attempt 2 on the #860 head) still refused. |
| 2026-11-01 07:01 PST = 15:01Z | GitHub receipt: *GitHub Enterprise Cloud — Usage, Sep 1–30 2026, $21.00 + tax = $25.20*, account `money-cat`, charged to the card the operator had just updated. |
| 2026-11-01T15:03:40Z | Attempt 3 of the same run `in_progress`, 17 steps, runner `GitHub Actions 1000115337`. The lock released between 15:01 and 15:03. |
| 2026-11-01T15:04:35Z → 17:53Z | Recovery cascade, 16 squash merges; recorded in `docs/BossCat/BOSSCAT_LOG.md` (2026-11-01T17:53Z line, #882, mirror #883). |
| 2026-11-01T18:36:43Z | Monthly evidence rollup dispatched by hand (run 41337514096) to replace the refused 09:49Z run. |

### 1b. Blast radius (measured, not derived)

Method: `gh run list --created <day>..<day> --limit 1000 --json databaseId,name,conclusion,createdAt,updatedAt,event,headBranch` for every day from 2026-10-10 to 2026-11-01 (22 one-day windows, 792 runs, de-duplicated by id; one-day windows keep each query under the listing endpoint's 1,000-result truncation). The lock window is *created* between 2026-10-16T04:31Z and 2026-11-01T15:01Z. A run's `conclusion` is its latest attempt's, so runs re-run after the unlock are classified separately; "refused" means `failure` with `updatedAt − createdAt ≤ 20 s`, which was verified on samples to mean zero steps and the billing annotation.

| Class | Runs |
| --- | --- |
| Created in the window | 352 |
| Dependabot updater jobs (`dynamic`), unaffected by the lock | 91 (75 ok, 16 fail) |
| Everything else | 261 |
| — refused at their first and only attempt | 201 |
| — refused at the first attempt, re-run green after the unlock (batch PR heads) | 36 |
| — Gate Nightly: executed on the self-hosted runner, failed at artifact upload | 17 |
| — failed for reasons of their own, on or after a re-run (OSV findings on batch heads, one commit-message gate, one archiver run) | 7 |

Refused runs by workflow, with the scheduled share and the gap they opened:

| Workflow | Refused | of which scheduled | Last green before | First green after |
| --- | --- | --- | --- | --- |
| Archive & Analyze Workflow Runs | 59 | 59 | 2026-10-15T23:04Z | 2026-11-01T15:07Z |
| Gitleaks Security Scan | 27 | 17 | 2026-10-15T06:42Z | 2026-11-01T15:04Z |
| Registry Drift Check | 17 | 17 | 2026-10-15T08:33Z | next schedule |
| CodeQL Advanced | 14 | 3 | 2026-10-14T01:00Z | 2026-11-01T15:04Z |
| OSV-Scanner | 13 | 3 | 2026-10-14T01:00Z | 2026-11-01T15:06Z |
| PSScriptAnalyzer | 13 | 2 | 2026-10-14T01:00Z | 2026-11-01T15:04Z |
| BossCat Governance Suite | 11 | 0 | 2026-10-14T01:00Z | 2026-11-01T15:04Z |
| BossCat Gate Verification (`ubuntu-latest`) | 11 | 0 | 2026-10-14T01:00Z | 2026-11-01T15:04Z |
| 🐾 BossCat Tetragram Guardrails | 11 | 0 | 2026-10-14T01:00Z | 2026-11-01T15:06Z |
| Gate & Site Evidence (Non-Merging) | 11 | 0 | 2026-10-14T01:00Z | 2026-11-01T15:06Z |
| Registry Guard | 3 | 0 | — | 2026-11-01T15:26Z |
| Quil DOCS Lane Automation | 2 | 2 | 2026-10-12T11:36Z | next schedule |
| Evidence PAT Rotation Reminder | 2 | 2 | 2026-10-12T21:00Z | next Monday |
| Clean-Host E2E Freshness | 2 | 2 | 2026-10-12T21:14Z | next schedule |
| BossCat · Trivy Security Scan | 2 | 0 | — | 2026-11-01T15:07Z |
| Gate-026 Performance Gate | 2 | 0 | — | 2026-11-01T15:26Z |
| BossCat — Monthly Evidence Rollup | 1 | 1 | 2026-10-01 (#850) | dispatched 18:36Z, see §5 |

What that means in exposure terms:

- **No secret scan, no CodeQL, no OSV scan of `main` for 16 days** (17 scheduled gitleaks runs, 3 CodeQL, 3 OSV refused). Nothing merged in that time, so `main` did not change; the gap is in *re-scanning* against advisories published meanwhile. The first post-unlock runs were green for gitleaks and CodeQL; OSV went red on the transitive npm backlog it had already been red on since 10-16 and is green since #876/#881 cleared it.
- **The nightly verification ran but could not keep its evidence.** All 17 nightly runs executed on `otel-windows` and failed only at the summary upload. Their step logs survive in the run pages; the artifacts do not exist.
- **The October evidence rollup did not run on schedule.** Dispatched by hand after the unlock (§5).
- **The PAT reminder was silent on 10-19 and 10-26.** No expiry fell inside or near the gap: `EVIDENCE_REPO_TOKEN` 2026-12-23, `BOSSCAT_TOKEN` 2027-08-26 (dates from the workflow's matrix).
- **11 PR heads** carried refused checks; all were re-run green and merged in the cascade.

### 1c. Cause and release

GitHub's own description (docs.github.com → Billing → "Unlocking a locked account"): an account is locked when a payment is past due or a card authorization hold fails; paid features lock, and a failed hold can block Actions even on the Free plan. Here the receipt names the cause: a **September usage invoice of $25.20** ($21.00 "GitHub Enterprise Cloud — Usage", Sep 1–30, plus tax) on the `money-cat` billing account that had not been paid. The org API reports plan `free`; the invoice line is the new billing platform's usage line for the account that owns this org. The operator updated the card, the charge posted at 15:01Z, and the lock released within two minutes.

Which meter produced the $21 is not readable from this seat. Two facts point at Actions storage: the nightly's upload error names the artifact storage quota, and this repository holds about 9,000 artifact records (most expired; the live set measured 0.01 GB over the first page of the listing, the rest not measurable reliably through the paginated endpoint). The org's five private repositories have had no Actions runs since August, so metered minutes are an unlikely source. The Copilot per-user budget the operator set the same day is a separate control and did not release the lock.

### 1d. Why nobody noticed for sixteen days

- Every signal that could have said "CI is dead" was itself an Actions job: the nightly, the drift check, the monthly rollup, the PAT reminder, the archiver. All were refused at start, or ran and could not publish. This is the class the 2026-08-25 rollup finding named: machinery that cannot signal.
- The nightly *did* run on the self-hosted runner, so a watcher that only checked "did a job execute today" would have been fooled; its failure was at the billed upload step.
- The host task `OTel-Canary-ECRR` runs every five minutes (`BRAV/SCPT/canary-ecrr.ps1`) and checks local ports, the local UI and the local collector. It never looks at GitHub.
- In the PR list, a refused check is indistinguishable at a glance from a failing test: red, `BLOCKED`, a one-line job. The signature is only visible in the job's duration (1–3 s, zero steps) and its annotation.
- Whether GitHub's failed-workflow e-mails reached an inbox and were read was not examined; 126 scheduled failures accumulated without a reaction.

## 2. Clean

Nothing in the repository needed cleaning: the lock left no files, only run history (the 201 refused runs stay as records and the archiver files them like any other). Recovery actions, all recorded elsewhere:

- The cascade of 16 squash merges, 15:04–17:53Z, including the four seat PRs and the OpenTelemetry sdk-trace 3.0 migration: log line 2026-11-01T17:53Z (#882), mirror #883.
- Dead checks re-run per PR head, then superseded by rebases; nothing merged on a check that had not executed.
- Monthly evidence rollup dispatched at 18:36:43Z (run 41337514096), result in §5.
- Not done, by design: no change to billing, budgets, notification settings or the host task. Those are the operator's calls (§3).

## 3. Report

**F1 — RED, closed.** A $25.20 past-due invoice silenced every GitHub-hosted job on the org for 16 days (201 refused runs plus 36 re-run later; 126 of them scheduled scans and housekeeping). Released by payment at 15:01Z on 2026-11-01. No code reached `main` meanwhile, so the exposure is the missed re-scans, not a change that escaped scanning.

**F2 — AMBER, open: no detector.** Three options, in order of preference.

- **D1 (recommended): make the host canary look at GitHub.** `canary-ecrr.ps1` already runs every five minutes on `otel-windows` with the operator's `gh` login on the host. Add one check: `gh run list --limit 20 --json status,conclusion,createdAt,updatedAt`; if the last five *completed* runs are all `failure` and each lasted ≤ 20 s, write a RED line to the canary report and open or update one issue titled "Actions jobs are being refused at start" (de-duplicate with `gh issue list --search` on the title). A refused scheduled run arrives at least every six hours (the archiver), so the detector fires within a working day. Issue creation needs a token with `issues: write` on this repository only; under the blast-radius rule that is a fine-grained PAT scoped to this repo, not the operator's session token. Roughly 30 lines in a tracked script; no new workflow, because a workflow cannot report its own refusal.
- **D2: freshness of a published artifact.** The status bundle published to Pages by Gate & Site Evidence carries a timestamp; an external uptime monitor could alert when it ages past 36 hours. Weaker: that workflow only runs on dispatch and on pull requests, so its freshness already varies by days.
- **D3: mail rule.** GitHub e-mails the author of a failed scheduled workflow. A rule that escalates "N failures of the same scheduled workflow in a row" would have fired on 10-17. Depends entirely on inbox discipline, which this incident shows cannot be assumed.

**F3 — AMBER, open: which meter.** The operator can read it on the organization's billing usage page (Billing & licensing → Usage, filter Actions storage / Copilot) — that page is the only place the $21 is itemized. If it is artifact storage, the archiver's 4-hourly report artifacts and the nightly summaries are the candidates to shorten (retention days on `actions/upload-artifact`), and the expired-artifact backlog is GitHub's to purge. If it is Copilot, the new per-user budget already caps it.

**F4 — GREEN.** No credential expired silently: both PAT expiry dates sit after the window. The self-hosted runner itself was healthy throughout (it executed 17 jobs).

**Disposition (operator decides).** D1 is the one that would have caught this incident on day one and needs no new workflow. If chosen, it is a code-lane PR touching `BRAV/SCPT/canary-ecrr.ps1` plus one scoped secret on the host; the first proof is a dry run against the run list from this window, which must produce a RED line, and against today's list, which must not.

**Proposed `BOSSCAT_LOG.md` line (docs-lane companion, not applied by this PR):**

`- <ts>Z — **[ECRR: ACTIONS BILLING LOCK 10-16→11-01]** `ECRR_ACTIONS_BILLING_LOCK_20261101.md` (#<this PR>): 201 refused runs + 36 re-run, 126 of them scheduled; nightly ran on the self-hosted runner but lost its artifacts; cause a $25.20 past-due usage invoice, released at 15:01Z by payment; F2 detector (host canary + issue) and F3 meter open for the operator. Actor: Claude Code (local seat).`

## 4. Role

- **Machine operator (@fubumaki):** the billing page, the card, the budget, the receipt; the "run the cascade" go. Only seat that could clear the lock.
- **Claude Code (local seat):** found the lock during the batch review, measured it, drove the recovery cascade, dispatched the rollup, wrote this report.
- **Dependabot:** unaffected; its updater runs on GitHub's side of the billing boundary, which is why its PRs kept arriving into a repository that could not test them.

**Status:** CLOSED for F1. OPEN for F2 (the operator picks D1/D2/D3) and F3 (the meter). Closes when a detector is in place and has passed its dry run against this window's run list.

## 5. Addendum (2026-11-01, same day) — monthly rollup re-run

Run 41337514096 (`workflow_dispatch`, 18:36:43Z) replaces the refused scheduled run of 09:49:20Z. It completed `success` at 18:37:05Z, opened #884 (`chore(evidence): monthly rollup 2026-11`, authored and auto-merged under the workflow's PAT, merged 18:37:47Z, commit `0e161c2f`) with `ECRR_EVIDENCE_ROLLUP_2026-11.md` and the `evidence-rollup-2026-11.tar.gz` archive. The October evidence rollup therefore exists, one working day late and otherwise as the schedule would have produced it.
