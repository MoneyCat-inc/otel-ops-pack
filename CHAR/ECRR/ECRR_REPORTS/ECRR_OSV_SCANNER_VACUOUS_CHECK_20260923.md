# ECRR — OSV-Scanner: a green check that never scanned (2025-10-04 → 2026-09-23)

**Date:** 2026-09-23
**Actor:** Claude (chat/review), from a remote container with GitHub access to this repository only; fix pushed under the drive-to-green posture on a Dependabot PR
**Verdict:** **AMBER (NON-BLOCKING)** — the check is real as of `0acdeb5` (#799); the `main` baseline it now measures is not yet read from this seat and the first push run after merge is expected to go red
**Trigger:** Dependabot #799 (osv-scanner-action 2.5.1 → 2.6.0) turned `OSV-Scanner / scan-pr` red on 2026-09-21T17:12Z

## 1. Examine

### 1a. What the red run said

Run 35630481922 (head `94ce7ba`), job `scan-pr / osv-scan`, both scanner steps:

```
Incorrect Usage: flag provided but not defined: -skip-git
Exit code: 127
```

then v2.6.0's new completeness step (google/osv-scanner-action#139, "Fail the job when a scan does
not complete"): *"A scan did not complete, so the two sets of results cannot be compared. Failing the
job rather than reporting no new vulnerabilities found."*

### 1b. Why the flag is unknown

osv-scanner v2.0.0 (2025-03-17) removed `--skip-git` and made skipping the git root the default;
the opt-in is `--include-git-root` (google/osv-scanner#1584, merged 2025-02-07). The v2.6.0 help
text printed in the failing step lists `--include-git-root` and no `--skip-git`.

### 1c. The same failure on every "green" run before it

The workflow was created from GitHub's template on 2025-10-04 (`f40b863e`, action v1.7.1, where
`--skip-git` was valid). It never had a successful run until 2026-08-17 (Actions-validation defects,
fixed in `31423808`, `6da663e9`, `2d059a46`, `c42f709b`). `31423808` bumped the reusable to v2.5.1
and kept the v1 flag. From then on every run did this (job 106150937546, run 35538200970, push to
`main` at `38382457`, 2026-09-20T21:16Z, conclusion **success**):

```
osv-scanner-action@v2.5.1  "--format=json --output=results.json -r --skip-git ./"
  flag provided but not defined: -skip-git
  Exit code: 127                                  (scan step is continue-on-error)
osv-reporter-action@v2.5.1 "--output=results.sarif --new=results.json --fail-on-vuln=true"
  failed to open new results at results.json: failed to load 'results.json' - likely because previous step failed.
  No issues found                                 (exit 0)
upload-artifact: 589 bytes (an empty SARIF); code scanning: "Successfully uploaded results"
```

The reporter treated a missing results file as "no issues", the job went green, and an empty SARIF
was filed under the `osv-scanner` tool in code scanning every time. The tell nobody read: an SCA
scan of 1,700+ packages "completing" in 26–31 s.

| Measure | Value |
| --- | --- |
| Successful `osv-scanner.yml` runs 2026-08-17T09:05Z → 2026-09-23T21:00Z (all events, all branches) | **633**, of which **1** real (run 35921073411, the fix) |
| Scheduled Friday runs in that window (08-21, 08-28, 09-04, 09-11, 09-18) | 5 / 5 vacuous, all "success" |
| Real scans produced by this workflow since its creation on 2025-10-04 | **0** before 2026-09-23T21:13Z |
| Records that carried it as green | `ECRR_READY_FOR_GATE_AUDIT_20260919.md` §1a rows "CI green on `main`" and "Last scheduled run of each" ("OSV 09-18 ✅"), §1e ("OSV-Scanner, Trivy, gitleaks and GitGuardian all green"); `ECRR_READY_FOR_GATE_AUDIT_20260903.md` "8/8 workflows success"; Phase 0 audit 2026-08-03 KEEP justification "dependency SCA, distinct from CodeQL, low noise" |

Not required by branch protection (verified 2026-09-01, workflow header), so no merge was ever gated
on it. It is the second instance in this file's own history of `docs/PURPOSE.md` line 84 — *"A check
must be able to both pass and fail. Anything that cannot is broken, however green it looks"* — after
the YAML-validity class closed on 08-17 ("the check that can fail, for the class that could not").
The audits' method (read run conclusions, not job logs) could not catch it; job duration could have.

### 1d. Could not verify from this seat

- The findings on `main`. See §3.
- Whether any of them is already a Dependabot alert (the 09-03 audit recorded 0 open); OSV's
  deps.dev transitive resolution of unpinned `requirements.txt` floors covers ground Dependabot's
  manifest path does not.

## 2. Clean

CI lane only, pushed to Dependabot's branch as `0acdeb5` on #799 (Dependabot stops rebasing an
altered PR; acceptable, the PR is otherwise complete):

- `.github/workflows/osv-scanner.yml`: `--skip-git` removed from both `scan-args` blocks; dated
  comment records the removal, the upstream change, the exit-127 history and run 35538200970.
  Scan scope unchanged (v2's default is what the flag asked for). `-r ./` is also v2.6.0's default.
- No `osv-scanner.toml` added, no `--fail-on-vuln` softened, no path filter touched.

Validated before push: file parses (PyYAML), both `scan-args` read `-r\n./`. Validated after push by
the run itself (1c → 3).

## 3. Report

**First real scan** — run 35921073411, job 107384872408, head `0acdeb5` (PR mode: base `38382457`
vs head), 2026-09-23T21:13Z, 1 m 21 s:

| Manifest | Packages |
| --- | --- |
| `pnpm-lock.yaml` | 1,131 |
| `BRAV/INFR/deployment-pipeline/package-lock.json` | 539 |
| `BRAV/SCPT/run-archiver/package-lock.json` | 42 |
| `ALFA/APPS/sidecars/requirements.txt` | 9 |
| `otel-agent-coordination/requirements-dev.txt` | 5 |
| `requirements.txt` | 4 |
| total (+2 filtered local/unscannable) | **1,730** |

Both scans wrote results (`old-results.json`, `new-results.json`, 41,471 bytes zipped each) and
**exited 1**, osv-scanner's "vulnerabilities found" code. The PR reporter compared old vs new and
printed "No issues found": nothing *new* on the head, so the job is green and #799 is `clean`, 9/9.

**What the baseline contains is not readable from this container.** Artifact storage
(`*.blob.core.windows.net`), `api.osv.dev` and `api.deps.dev` are all denied by the egress policy.
An offline reproduction from the same tree (osv-scanner 2.6.0, offline npm + PyPI databases,
`--no-resolve`) found **0** across the same 1,730 packages, and pip-resolved transitive sets of the
three requirements files (48, 23 and 40 packages for Python 3.11/3.12) also scan **0** offline. The
online findings therefore sit in something this seat cannot reproduce — most plausibly deps.dev's
resolution of the unpinned Python floors, or data the API returns that the bulk offline database
does not. Two ways to read them, either is a browser click, neither needs a keyboard secret:

1. Run 35921073411 → artifact **`old-json-results`** (id 10776933046; retention 5 days, gone
   ~2026-09-28T21:14Z), or
2. the first push run on `main` after #799 merges: `scan-scheduled` runs the reporter with
   `--fail-on-vuln=true` and **no baseline**, so it prints the full table and goes **red** if the
   findings persist. That red is the check working for the first time, not a regression.

**Disposition per finding (operator decides, one PR per lane):** fixable → bump (Dependabot or a
manual `chore(deps)`); not fixable / not reachable → a dated entry in a new `osv-scanner.toml`
(`[[IgnoredVulns]]` with `reason` and `ignoreUntil`). Never the third option of dropping
`--fail-on-vuln` or re-adding a flag that makes the scan skip.

**Proposed `BOSSCAT_LOG.md` line (docs-lane companion, then mirror republish):**

> `- 2026-09-23T21:15:00Z — **[OSV-SCANNER: 11 MONTHS GREEN, NEVER SCANNED — FIXED]** Dependabot #799 (osv-scanner-action 2.6.0, fail-closed on incomplete scans) exposed that osv-scanner.yml passed the v1 flag --skip-git to the v2 scanner since the 08-17 bump (31423808): exit 127 every run, reporter printed "No issues found" on a missing file, 632 vacuous successes incl. 5 scheduled; before 08-17 the workflow had never run at all. Flag dropped on #799 (0acdeb5); first real scan 1,730 packages, PR clean, baseline on main exits 1 (findings present; table in the first push run). 09-19 audit OSV rows corrected by addendum. ECRR_OSV_SCANNER_VACUOUS_CHECK_20260923.md. — **Claude (chat/review)**`

**Method note for the next Ready-For-Gate audit:** add a duration sanity row for every scanner
lane (a scan that "succeeds" faster than its checkout is a scan that did not run), and read one job
log per KEEP security workflow, not the conclusion.

## 4. Role

Claude (chat/review): root-caused from job logs and upstream history, pushed the two-line fix to
the Dependabot branch under the drive-to-green posture for a watched PR, reproduced offline what
could be reproduced, and files this report. Machine operator `@fubumaki` owns the merge of #799,
the read of the baseline table, and every disposition in §3. Nothing on any host was touched.

**Status:** OPEN — closes when the first push run on `main` after #799 has been read and each
finding has a disposition on record.
