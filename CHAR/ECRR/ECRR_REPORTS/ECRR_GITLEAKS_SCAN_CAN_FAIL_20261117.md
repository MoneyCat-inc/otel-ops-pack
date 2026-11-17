# ECRR — gitleaks can now fail on this repository's leak classes: fixture proof, full-history scope, and a baseline of 55 old value groups (#914)

**Date:** 2026-11-17
**Actor:** Claude Code (local seat), driver of the 2026-11-17 security cascade on the operator's explicit go of 2026-11-16. #914 itself was written in a claude.ai/code cloud session (its commits carry `Actor: Claude (chat/review seat)`) and reviewed by the chat/review seat; this is the report that pull request owes. Every value below is named by `sha256[:8]` and length, as `.gitleaksignore` names it. No value was read, searched for or displayed for this report. Its figures come from CI job logs, from the files as merged and from #914's description, and §1 says which is which.
**Scope:** #914, CI lane with a one-off lane exception (§2), merged as `2e4324a2` on 2026-11-17T00:24:37Z: `.gitleaks.toml`, `.gitleaksignore` (new), `.github/workflows/gitleaks.yml`, `BRAV/SCPT/ci/gitleaks-fixtures.py` (new), `BRAV/SCPT/guardrails.json`, `docs/status/workflows.json`.
**Verdict:** **AMBER.** The gate itself is GREEN: the scan can fail on the leak classes this repository has had, CI proves the config on synthetic fixtures before every scan, and the nightly reads full history. What it is green over is not closed: the baseline holds 24 credential or credential-like value groups that nobody has confirmed dead, and five such values are still in the tree (§3).
**Trigger:** F4 of `ECRR_SIGNOZ_CREDENTIALS_IN_TREE_20261104.md` ("the scanners cannot fail on this class"), P2-2 of the 2026-11-01 audit, and the OEM review of 2026-11-04.

## 1. Examine

### 1a. What the lane could not see

From #914's description, measured there with gitleaks 8.24.3 and not re-measured here:

- **A custom rule reused the built-in id `generic-api-key`.** A same-id rule merges into the built-in one. The name of the variable became the reported secret and was filtered out, so the generic rule never reported.
- **A global path allowlist** skipped `.md`, `.example`, `.template`, README and `third_party/`. One SigNoz API value sat in 14 public `.md` lines from 2025-10-27 without a finding.
- **The schedule and the dispatch scanned one commit** (`--log-opts=-1`), as a push does. A value committed earlier was never read again.
- **The old SigNoz rule reported the name as its secret**, so `--redact` masked the name and left the value in the job log and in the report artifact.
- With the old config (blob `559b0e01`) the fixture harness catches 4 of its 23 positives and leaves 1 planted value in the redacted report. This "before" figure was measured in the authoring session (commit `9504a229`). The review confirmed only that the harness fails on the old config and on eight single-rule mutants. CI never ran it: there the harness and the config always come from the same checkout.

### 1b. What CI shows

Read from the job logs on 2026-11-17. Every run used gitleaks 8.24.3.

| Run | Event and head | `Prove the config on synthetic fixtures` | `Run Gitleaks` |
| --- | --- | --- | --- |
| 41760400116 | dispatch on #914's branch at `9504a229`, 2026-11-04 | pass: 23/23 positives, 26/26 negatives | **red**: full history, 1,921 commits, 1 finding outside the baseline |
| 41762366599 | dispatch on #914's branch at `b8a76b23`, 2026-11-04 | pass: 23/23, 27/27 | green: full history, 1,924 commits |
| 43986975492 | pull request, #914's final head `c6506599` | pass: 23/23, 27/27 | green: `d8dac859..c6506599`, 4 commits |
| 43987392467 | push, `main` at `2e4324a2` | pass: 23/23, 27/27 | green: the pushed commit |
| 43987433239 | dispatch, `main` at `2e4324a2`, 2026-11-17T00:24:59Z | pass: 23/23, 27/27 | green: full history, 1,933 commits, no leaks |
| 44000081389 | schedule, `main` at `2e4324a2`, 2026-11-17T02:02:53Z | pass: 23/23, 27/27 | green: full history, 1,933 commits, no leaks |

- From commit `e6ed7e88` on, the fixture step prints "PASS: positives caught 23/23, negatives clean 27/27, redaction ok, config structure ok" and "0 of 23 planted values present". It has passed in all 12 gitleaks runs that carried it: nine on #914's branch and three on `main`.
- **The scan step has been both red and green in CI.** Run 41760400116 failed on one finding of the new SigNoz rule at `ALFA/LIBS/lib/tracing.ts:29`, on another session's branch. It was a false positive on a letters-only variable name. Commit `e6ed7e88` allowlisted letters-only values for that rule and added fixture N27, and the next dispatch was green.
- **The fixture step has never failed in CI.** That it can fail rests on the authoring session and on the review (the old config, eight mutants).
- Run 43987433239 is the first full-history run on `main` after the cascade, and run 44000081389 is the first scheduled run of the new scope. Both scanned 1,933 commits (704.91 MB) against the 261 baseline fingerprints. The review had expected about 1,950 commits.

### 1c. The workflow as merged

`gitleaks.yml` scans `base..head` on a pull request and the pushed commit on a push. On the 02:00 UTC schedule and on dispatch it scans the full history of every branch and tag that checkout fetches, against `.gitleaksignore`. The job runs `Prove the config on synthetic fixtures` first and `Run Gitleaks` second. `refs/pull/*` are not fetched, so the pull-request refs that still hold the old values (E3 of the SigNoz report) are outside every scope.

## 2. Clean

#914 as merged. Its four gitleaks files on `main` are the blobs of the reviewed head `b8a76b23`.

- `.gitleaks.toml`: the built-in rules run as shipped, and the custom generic rule is renamed `api-key-assignment`. Five rules are new, for this repository's own leak classes: `bare-base64-key`, `named-secret-literal`, `powershell-secret-literal`, `compose-secret-default` and `signoz-api-key`. The global path allowlist is gone; three vendored page bundles are allowlisted on the rules that fire on them.
- `.gitleaksignore` (new): 261 commit fingerprints in 55 value groups, each annotated. It holds no value.
- `gitleaks.yml`: the fixture step, and full history on schedule and dispatch.
- `BRAV/SCPT/ci/gitleaks-fixtures.py` (new): 23 synthetic positives that must each be reported exactly once, 27 placeholders that must not be reported, a redaction check and a structural check of the config. The fixtures are built at run time from split literals.
- `BRAV/SCPT/guardrails.json` allows the new top-level file, and `docs/status/workflows.json` is regenerated.

The squash body of `2e4324a2` records two decisions by the operator:

- **The baseline is accepted as filed.** The file's own rule (its lines 15 to 17) admits only triaged findings: "credential revoked or confirmed dead, or not a credential". The operator accepted it on 2026-11-16 with 24 credential or credential-like groups not yet confirmed dead, so the nightly is green over them. The review tested a stricter variant that held those groups out of the baseline and did not recommend it: the nightly could not pass until a keyboard step, so a new leak would not change its colour.
- **A one-off exception to the lane rule.** The workflow (CI lane) landed with the config, the ignore file and two files under `BRAV/SCPT` (code lane), because it is one change to one gate. It sets no precedent. `docs/status/workflows.json` is not part of the exception: Registry Guard requires it with any workflow change.

Not done, by design: nobody edits `.gitleaksignore` as part of these records (F4), and no value was rotated, revoked or classified by a seat.

## 3. Report

### 3a. The 55 groups

A transcription of `.gitleaksignore` (blob `34b3c629`), recounted line by line: 261 fingerprints in 55 groups. By section that is 6 SigNoz API keys (83 fingerprints), 18 other credential or credential-like values (44), 7 labels, placeholders and markers (25) and 24 canary event tokens (109). "In the tree, as filed" is the file's own annotation, counted by its authoring session at `729121a1`. The next column is the state after the cascade, established by path, line and hunk range and not by a value search. The rules and the fingerprints of each group are in the file.

| # | `sha8` | Length | What, per the annotation | Findings | Commit dates (UTC) | In the tree, as filed | On `main` at `2e4324a2` | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `8abc66bc` | 44 | SigNoz API key | 35 | 2025-09-27 to 2025-10-22 | 8 lines, 5 files | none | Credential. Open under F1 of the SigNoz report. |
| 2 | `3e775a2b` | 44 | SigNoz API key | 23 | 2025-09-28 to 2025-10-08 | 6 lines, 5 files | none | Credential. Open under F1 of the SigNoz report. |
| 3 | `c66026b5` | 44 | SigNoz API key (described as a one-day test key) | 14 | 2025-10-27 to 2026-08-29 | 14 lines, 14 files | 7 lines, 7 files (mirror copies) until the republish | Credential. Open under F1 of the SigNoz report. |
| 4 | `869a41b7` | 44 | SigNoz API key | 5 | 2025-09-28 to 2025-10-08 | 4 lines, 4 files | none | Credential. Open under F1 of the SigNoz report. |
| 5 | `089c8993` | 44 | SigNoz API key | 4 | 2025-10-08 | 2 lines, 2 files | none | Credential. Open under F1 of the SigNoz report. |
| 6 | `b4376d4d` | 44 | SigNoz API key (the sixth) | 2 | 2025-10-08 to 2025-10-09 | none | none | Credential. Open under F1 of the SigNoz report (added by its §5). |
| 7 | `7b2b10c7` | 30 | `SIGNOZ_JWT_SECRET` compose default | 13 | 2025-09-30 to 2026-08-03 | 13 lines, 12 files | none | Credential-like. Open under F2 of the SigNoz report. |
| 8 | `0b3dc10f` | 56 | the 2025-09 `SIGNOZ_JWT_SECRET`, reused as a parameter default | 5 | 2025-09-19 to 2025-09-22 | 1 line, 1 file | as filed | Credential-like. Open here (F2, F3). Still in the tree. Asked: rotate if live. |
| 9 | `f0eb808a` | 30 | `SIGNOZ_WEBHOOK_SECRET` literal | 5 | 2025-10-02 | 5 lines, 4 files | as filed | Credential-like. Open here (F2, F3). Still in the tree. Asked: rotate if live. |
| 10 | `955940b5` | 16 | SigNoz UI admin password | 3 | 2025-10-02 to 2025-10-04 | none | none | Credential. Open here (F2). History only. Asked: confirm changed. |
| 11 | `75d8676a` | 29 | `CRON_SECRET` in a doc | 2 | 2025-09-28 to 2025-10-08 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 12 | `7d781201` | 39 | `AUTH_TOKEN` literal | 2 | 2025-10-02 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 13 | `820356b0` | 42 | `MAGIC_LINK_SECRET` in a doc | 2 | 2025-09-28 to 2025-10-08 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 14 | `a01c0f2d` | 18 | `MAGIC_LINK_SECRET` in a doc | 2 | 2025-09-28 to 2025-10-08 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 15 | `0537dfd2` | 14 | `NEXTAUTH_SECRET` compose default | 1 | 2025-09-28 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 16 | `259b329f` | 19 | Bluesky app password | 1 | 2025-10-18 | none | none | Credential. Open here (F2). History only. Asked: confirm revoked. |
| 17 | `26e535a5` | 23 | the first 23 characters of `7b2b10c7` | 1 | 2025-10-05 | 1 line, 1 file | none | Credential-like. Open under F2 of the SigNoz report. |
| 18 | `5199942c` | 41 | `NEXTAUTH_SECRET` in a committed `.env` | 1 | 2025-10-05 | none | none | Credential. Open here (F2). History only. INFO in F5 of the SigNoz report. Asked: rotate if live. |
| 19 | `5aa2092d` | 26 | bearer token of the webhook-handler drill | 1 | 2025-10-02 | 5 lines, 4 files | as filed | Credential-like. Open here (F2, F3). Still in the tree. Asked: rotate if live. |
| 20 | `8b62e59e` | 49 | ngrok-authtoken shape | 1 | 2025-10-04 | 1 line, 1 file | as filed | Credential. Open here (F2, F3). Still in the tree. Asked: confirm revoked. |
| 21 | `979a10ec` | 44 | webhook-auth value in a deployment guide | 1 | 2025-10-02 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 22 | `98c36d34` | 19 | SigNoz UI admin password | 1 | 2025-10-02 | none | none | Credential. Open here (F2). History only. Asked: confirm changed. |
| 23 | `a9d67955` | 40 | webhook-secret value in a deployment guide | 1 | 2025-10-02 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 24 | `d3ca3474` | 33 | `SIGNOZ_JWT_SECRET` inside a sed command in a doc | 1 | 2025-10-08 | none | none | Credential-like. Open here (F2). History only. No action named; awaits a classification. |
| 25 | `bbbe1c54` | 19 | label printed as "API key created in SigNoz" | 14 | 2025-10-27 to 2026-08-29 | 22 lines, 14 files | as filed | Not a credential. Closed. |
| 26 | `a2ae6a9e` | 12 | `your-...-key` placeholder in curl examples | 4 | 2025-09-25 | 15 lines, 8 files | as filed | Not a credential. Closed. |
| 27 | `69f5fb34` | 14 | identifier in a `.ps1` lookup | 2 | 2025-09-22 | 31 lines, 13 files | as filed | Not a credential. Closed. |
| 28 | `cd76b30a` | 16 | documentation anti-example | 2 | 2025-09-19 | 2 lines, 2 files | as filed | Not a credential. Closed. |
| 29 | `6babfcd9` | 18 | design color tokens | 1 | 2025-10-17 | 3 lines, 3 files | as filed | Not a credential. Closed. |
| 30 | `9a5a048e` | 27 | marker string in `guard-inflated-metrics.ps1` | 1 | 2026-09-02 | 5 lines, 4 files | as filed | Not a credential. Closed. |
| 31 | `e55b080f` | 22 | header value in a curl example | 1 | 2025-10-26 | none | none | Not a credential. Closed. |
| 32 | `3ce2b182` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 33 | `3fec6ce6` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 34 | `46270816` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-02 | 1 line, 1 file | as filed | Not a credential. Closed. |
| 35 | `47e2f996` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 36 | `5f2d6a35` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 37 | `6a159e99` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-02 | 4 lines, 1 file | as filed | Not a credential. Closed. |
| 38 | `87478ade` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-02 | 1 line, 1 file | as filed | Not a credential. Closed. |
| 39 | `8e8aac7b` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 40 | `8f1e21da` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-02 | 1 line, 1 file | as filed | Not a credential. Closed. |
| 41 | `91adff93` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 42 | `9c1ed738` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-02 | 2 lines, 1 file | as filed | Not a credential. Closed. |
| 43 | `a460751f` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 44 | `bafbe701` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 4 lines, 1 file | as filed | Not a credential. Closed. |
| 45 | `d27319f7` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 46 | `d831bf5e` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-02 | 1 line, 1 file | as filed | Not a credential. Closed. |
| 47 | `fb4d12b6` | 32 | canary event token (2025 drill trace marker) | 6 | 2025-09-28 to 2025-10-09 | 3 lines, 2 files | as filed | Not a credential. Closed. |
| 48 | `b767a4ba` | 32 | canary event token (2025 drill trace marker) | 4 | 2025-09-28 to 2025-10-09 | 8 lines, 2 files | as filed | Not a credential. Closed. |
| 49 | `a661c620` | 32 | canary event token (2025 drill trace marker) | 2 | 2025-09-28 to 2025-10-09 | 1 line, 1 file | as filed | Not a credential. Closed. |
| 50 | `d235f348` | 32 | canary event token (2025 drill trace marker) | 2 | 2025-09-28 to 2025-10-09 | 2 lines, 1 file | as filed | Not a credential. Closed. |
| 51 | `10ddcefb` | 32 | canary event token (2025 drill trace marker) | 1 | 2025-09-30 | 4 lines, 2 files | as filed | Not a credential. Closed. |
| 52 | `13fdb52e` | 32 | canary event token (2025 drill trace marker) | 1 | 2025-09-25 | none | none | Not a credential. Closed. |
| 53 | `27e08580` | 32 | canary event token (2025 drill trace marker) | 1 | 2025-09-25 | none | none | Not a credential. Closed. |
| 54 | `8469d7dc` | 32 | canary event token (2025 drill trace marker) | 1 | 2025-09-25 | none | none | Not a credential. Closed. |
| 55 | `a16c69fe` | 32 | canary event token (2025 drill trace marker) | 1 | 2025-09-25 | none | none | Not a credential. Closed. |

Of the 24 credential or credential-like groups, 15 name an operator action in their annotation (8 "confirm revoked", 2 "confirm changed", 5 "rotate if live" or, for `7b2b10c7`, "rotate if any deployment kept it") and 9 name none.

### 3b. Which report holds which group

- **Eight groups are in the SigNoz report**: `8abc66bc`, `869a41b7`, `3e775a2b`, `089c8993`, `c66026b5`, `7b2b10c7` and `26e535a5` in its §1a, and the sixth key `b4376d4d` in its §5 addendum. F1 and F2 stay RED there until the operator's rotation is recorded. This report does not re-grade them.
- **Sixteen groups are in no other report.** Eight await an operator action: `0b3dc10f`, `f0eb808a`, `5aa2092d` and `5199942c` (rotate if live), `8b62e59e` and `259b329f` (confirm revoked), `955940b5` and `98c36d34` (confirm changed). Eight await a classification: `75d8676a`, `7d781201`, `820356b0`, `a01c0f2d`, `0537dfd2`, `979a10ec`, `a9d67955` and `d3ca3474`. Four of the sixteen are still in the tree (§3c) and twelve are in history only.
- Two pointers, neither of them a classification. `5199942c` is named once, as INFO, in F5 of the SigNoz report. For the Bluesky app password, `docs/BossCat/ECRR_PACK3B_SOCM_LANE_CLOSEOUT_20260724.md` records on 2026-07-24 that the predecessor app password was already absent from the account; nothing ties that record to `259b329f` by fingerprint.

### 3c. Five values that stay in the tree

They are listed here by path and line, and were not opened.

| `sha8` | Length | Where | What | In the baseline |
| --- | --- | --- | --- | --- |
| `0b3dc10f` | 56 | `BRAV/SCPT/signoz-auth-helpers.ps1:7` | the 2025-09 `SIGNOZ_JWT_SECRET`, reused as a parameter default | yes, 5 fingerprints |
| `f0eb808a` | 30 | `BRAV/SCPT/agent/staged-failure-drill.ps1:190` and `:193`; line 27 of `signoz-heartbeat-alert.json`, `signoz-hung-daemon-alert.json` and `signoz-remediation-failure-alert.json` under `DELT/CONF/config/` | webhook secret | yes, 5 fingerprints |
| `5aa2092d` | 26 | `staged-failure-drill.ps1:191` and `:193`; line 28 of the same three JSON files | webhook bearer | yes, 1 fingerprint |
| `8b62e59e` | 49 | `scripts/legacy/ops/security-remediation-ngrok.ps1:26` | ngrok-authtoken shape | yes, 1 fingerprint |
| `ee58f3d0` | 29 | `.agent/github-integration.ps1:54` | webhook secret | **no group** |

- That is 12 lines in 7 files, 11 of them in 6 files for the four baselined groups. All seven files are the same blobs before and after the cascade.
- **The scan reports 2 of the 12 lines, and the baseline hides both.** They are `BRAV/SCPT/signoz-auth-helpers.ps1:7` and `BRAV/SCPT/agent/staged-failure-drill.ps1:190`, fingerprinted under their paths before the 2025-10 move to `BRAV/SCPT`. No rule reports the other nine lines of the four groups, and no rule reports the fifth value at all, in history or in a pull request. #914's description names two of the gaps: lowercase JSON names, and PowerShell values passed as named arguments.
- These lines are not covered by the go of 2026-11-16. After the rotation sitting the operator says live or dead for each value and gives a separate go that says how the lines are changed without displaying them.

### 3d. Findings

**F1 — GREEN, closed: the scan can fail.** The fixture step and the full-history scope are on `main` and green (§1b). The scan has failed in CI on a finding outside the baseline. F4 of the SigNoz report is answered by this change (recorded there, §5).

**F2 — AMBER, open (operator): sixteen groups in no other report.** Eight confirmations and eight classifications (§3b). Until each is on record, the nightly is green over values not yet confirmed dead.

**F3 — AMBER, open (operator, on a separate go): five values still in the tree**, ten of whose twelve lines no rule reports (§3c).

**F4 — INFO: seven "at HEAD" comments in `.gitleaksignore` are stale since the merges.** They are the seven values of the SigNoz report: `8abc66bc` (line 25), `3e775a2b` (63), `c66026b5` (88 and 89), `869a41b7` (106), `089c8993` (114), `7b2b10c7` (130) and `26e535a5` (196). Six should now read "not at HEAD". `c66026b5` reads "at HEAD in 7 line(s), 7 file(s)" until the mirror republish and "not at HEAD" after it. The 261 fingerprints are unaffected: they name commits in history. Nobody edits the file under these records. The comment-only refresh is code lane and goes with the change of F3, on its own go.

**F5 — INFO: what the gate still does not see**, from #914's own list of residuals:

- pull-request refs (§1c);
- lowercase JSON names with word-like values, and PowerShell values passed as named arguments;
- on a push, anything but the tip commit;
- the retired, dispatch-only `gitleaks-security-scan.yml`, which still scans one commit.

The nightly's scope also includes other seats' pushed branches, so a false positive there can turn it red. The config and the baseline live in the repository, so a change to either deserves a security review.

**F6 — INFO: one disclosure from #914's authoring session.** Its description reports that `5aa2092d` appeared once unmasked in that session's own tool output. The value is public at HEAD and is in no commit, comment or report. Under the blast-radius rule the operator's answer for it becomes "dead, recorded" or "rotated". The review seat's own disclosure is in §5 of the SigNoz report.

## 4. Role

- **Machine operator (`@fubumaki`):** accepted the baseline and the lane exception (go statement of 2026-11-16). Every confirmation, revocation and classification in §3 is the operator's, and so is the later go for the five values in the tree.
- **Claude (chat/review seat):** a cloud session under that label wrote #914; the review seat reviewed it and re-measured it in its own container.
- **Claude Code (local seat):** drove the merge (branch update on GitHub, checks on the updated head, squash pinned to that head), dispatched run 43987433239, read the 02:00 UTC run, and wrote this report from logs and files. It read no value, did not run the fingerprint inventory and did not edit `.gitleaksignore`.
- **Kiro{Implementer}:** no part.

**Status:** OPEN for F2 and F3. It closes when each of the sixteen groups has the operator's answer on record and the five values in the tree are changed under their own go. The eight groups of the SigNoz report close there.
