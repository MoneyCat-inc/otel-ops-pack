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

## 6. Addendum (2026-11-17): OSV-Scanner on `main`, the "October" rollup, and where 126 comes from

Three corrections, owed since §6e of the 2026-11-01 audit (`ECRR_READY_FOR_GATE_AUDIT_20261101.md`) and filed with the records of the 2026-11-17 security cascade (#909 to #914). Nothing above this section is edited. Run conclusions are the latest attempt's, read from the Actions API on 2026-11-17.

1. **OSV-Scanner was not green on `main`.** This corrects the header's Verdict, the first bullet under §1b's second table, and the OSV-Scanner row of that table.
   - The Verdict says "every scanner is green again on `main`". On this report's own merge commit (`50afce78`) seven push workflows were green and OSV-Scanner was red: run 41337995237 counted 13 known vulnerabilities in 9 packages.
   - OSV-Scanner on `main` was last green on 2026-09-25 (push run 36082335303 and scheduled run 36148970175, both on `61476bf3`). Its next run was red: push run 36836304172 on 2026-10-01T08:26:24Z, on `c9e0cb27` (the merge of #850), with 20 known vulnerabilities in 8 packages. The three lockfiles are the same blobs in both commits, so advisories published in between turned it red, not a change in the tree.
   - It has not been green since. From 2026-10-01 to 2026-11-17, 57 push runs and 7 scheduled runs on `main` all failed: 61 at the step `Run osv-scanner-reporter`, and the scheduled runs of 10-16, 10-23 and 10-30 were refused by the lock. The reporter counted 35 known vulnerabilities on 10-09, 86 at the first push after the unlock (run 41319346891), 13 on this report's merge commit and 12 after the cascade of 2026-11-17 (run 43987393200 on `2e4324a2`).
   - §1b says OSV "had already been red on since 10-16 and is green since #876/#881 cleared it". The red began on 10-01, the 10-16 run was a refusal, and the push runs on the merges of #876 and #881 failed (41332913858 with 32 known vulnerabilities, 41333501065 with 16).
   - The table's "Last green before" (2026-10-14T01:00Z) and "First green after" (2026-11-01T15:06Z) for OSV-Scanner are `pull_request` runs on the head of #860 (38493386644 and 41319489316), not runs on `main`. On `main`, the last OSV scan that executed before the lock was the scheduled run of 10-09 (37958827652) and the first after it was the push run of 2026-11-01T15:04:38Z. Both were red.
   - Read the Verdict's clause as: every scanner except OSV-Scanner was green again on `main`. OSV-Scanner was red for cause before the lock and still is.

2. **The run refused on 2026-11-01 was the 2026-11 rollup, not October's.** This corrects §1a's 09:49:20Z row, the third bullet under §1b's second table, and the last sentence of §5.
   - The workflow `BossCat — Monthly Evidence Rollup` (`bosscat-monthly-evidence-rollup.yml`, cron `0 2 1 * *`) names its branch, pull request, report and tarball after the month it runs in. A run on 2026-11-01 is the 2026-11 rollup, as §5 itself shows: #884 is `chore(evidence): monthly rollup 2026-11`.
   - The October rollup ran on schedule on 2026-10-01, fifteen days before the lock: run 36836113682, #850, merged as `c9e0cb27`.
   - The refused run is 41290452543 (`schedule`, 2026-11-01T09:49:20Z). Its only job ended in two seconds with no steps and the billing annotation. Dispatch 41337514096 replaced it the same day, 8 hours 47 minutes later, and landed #884 as `0e161c2f`. So §5's "one working day late" is wrong as well: the 2026-11 rollup exists, and it started 16 hours 37 minutes after its 02:00Z cron slot.

3. **Where 126 comes from.** The number is in §1d's last bullet, in F1 and in the proposed log line; no table derives it.
   - 126 is every `schedule` run created in the lock window (2026-10-16T04:31Z to 2026-11-01T15:01Z). All 126 failed: run-archiver 60, Gate Nightly 17, gitleaks 17, Registry Drift Check 17, CodeQL 3, OSV-Scanner 3, PSScriptAnalyzer 2, Quil DOCS Lane 2, the PAT rotation reminder 2, Clean-Host E2E Freshness 2 and the monthly rollup 1.
   - Under §1b's 20-second rule that is 108 refused scheduled runs (the "of which scheduled" column), the 17 nightlies and one archiver run: 108 + 17 + 1.
   - That archiver run (39279191853, 2026-10-19T15:35:36Z) was refused like the other 59: its only job ended in two seconds with no steps and the billing annotation. Its run record closed 30 minutes later, which put it outside the 20-second rule and into the row "failed for reasons of their own". By job record the split is 109 refused and 17 executed, and the archiver row of the second table would read 60, not 59. The audit's §6a (item 10) calls it "the one archiver run that executed and failed"; it did not execute.
   - F1's "(201 refused runs plus 36 re-run later; 126 of them scheduled scans and housekeeping)" reads as a subset, and it is not one. The 201 refused runs hold 108 scheduled runs, and the runs re-run after the unlock are all `pull_request` runs. 126 is reached only by adding the 17 nightlies and the archiver run, which §1b's first table counts outside the 201 and the 36. §1d's "126 scheduled failures" is right as written. The log line of 2026-11-01 (#887) carries F1's wording.

**Status:** unchanged. CLOSED for F1; OPEN for F2 (detector) and F3 (meter).
