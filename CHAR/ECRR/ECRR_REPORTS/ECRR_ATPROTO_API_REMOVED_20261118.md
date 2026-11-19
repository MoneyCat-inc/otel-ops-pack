# ECRR — Unused `@atproto/api` dependency and its pnpm override removed; zod 3 leaves the lock

**Date:** 2026-11-18
**Actor:** Claude Code (local seat), on the operator's explicit go of 2026-11-16 (section 8) and answers of 2026-11-18 (E1)
**Scope:** PR #945 (opened 2026-11-17), code lane: `package.json` (2 lines removed) and `pnpm-lock.yaml` (109 lines removed); branch commit `1a5429d1a`, squash-merged as `4c3761361`.
**Verdict:** **GREEN** — proven: the dependency, its override and the 13 lock packages that only it needed are gone, and nothing else in either file changed; no JavaScript or TypeScript file on `main` has named the package since #366, and no workflow ever did; pnpm 10.18.1 installs the result from the frozen lock in CI; the zod 3.25.76 row has left OSV-Scanner's list on `main` (§3). Not measured: whether Dependabot has closed alert 593, and anything outside git on the operator's host.
**Trigger:** the audit of 2026-11-01 recorded zod 3 as held in the lock by the `@atproto/api` pin, with nothing for Dependabot's security updater to open (finding P3-2, `ECRR_READY_FOR_GATE_AUDIT_20261101.md:114`); section 8 of the go lists the removal as a code-lane follow-up.

## 1. Examine

- **Where it came from.** `0d15e6550` (2025-10-18, socm Milestone B) added `"@atproto/api": "^0.13.0"` to `package.json` together with its first use, in `scripts/social/post.ts`. Eighteen files under `scripts/social/` came to load the package: 17 with a static import, and `post.ts` with `await import("@atproto/api")` (line 65 before #366).
- **Nobody has used it since 2026-07-24.** `926334108` (#366, the socm split) deleted all 18 with the rest of `scripts/social/` (32 files in all). A history search of `main` (`git log -S atproto --no-renames`) over `*.ts`, `*.tsx`, `*.mts`, `*.cts`, `*.js`, `*.jsx`, `*.mjs` and `*.cjs` lists those 18 paths and no other; #366 is the newest commit in it, and none of the paths exists at `b8428c4d6`. The same search over `.github/` and every `*.yml`, `*.yaml`, `*.py` and `*.sh` file finds only `pnpm-lock.yaml`. None of the 55 `package.json` scripts names social, Bluesky or atproto.
- **The override repeated the dependency.** `3f4f05421` (2026-07-20, subject `chore: pin @atproto/api to 0.15.27 (ESM/tsx compat)`) changed the dependency from `^0.20.28` to the exact `0.15.27` and added the same value under `pnpm.overrides`, four days before the scripts left. Seven days after the pin, the Dependabot batch #407 (`f0767fa47`) moved both lines to 0.20.34. Five Dependabot commits have moved them together since, last to 0.31.2 in #936 (`60e2c9d3f`, 2026-11-17). At `b8428c4d6` they are `package.json:64` and `package.json:134`, the third of 20 overrides. In the lock only the root importer asks for the package: no snapshot depends on `@atproto/api@0.31.2`.
- **What it held in the lock.** Thirteen packages are there only for it: `@atproto/api` 0.31.2, `@atproto/common-web` 0.5.17, `@atproto/lex-data` 0.1.10, `@atproto/lex-json` 0.1.9, `@atproto/lexicon` 0.7.19, `@atproto/syntax` 0.7.7, `@atproto/xrpc` 0.8.18, `await-lock` 3.0.0, `iso-datestring-validator` 2.2.2, `multiformats` 13.4.2, `tlds` 1.261.0, `unicode-segmenter` 0.14.5 and `zod` 3.25.76. No snapshot outside the 13 depends on any of them. zod 3.25.76 was required by four of the `@atproto/*` packages (`api`, `common-web`, `lexicon`, `xrpc`) and by nothing else.
- **Why it mattered.** zod 3.25.76 was one of the 13 rows OSV-Scanner listed on `main` when the change was planned: GHSA-mrhx-c7xc-m3w5, CVSS 8.2, fixed in 4.6.6 (push run 44192010649 at `b8428c4d6`; the same 13 rows as run 44152364568, which the operator's answers of 2026-11-18, E4, name as the known rows). It is also Dependabot alert 593 (high, `< 4.6.6`, `pnpm-lock.yaml`, opened 2026-10-24).

## 2. Clean

- `package.json`: two lines removed, the dependency (line 64) and the override (line 134). That leaves 27 dependencies (28 before) and 19 overrides (20 before). Parsed, the two versions differ in nothing else.
- `pnpm-lock.yaml`: 109 lines removed and none added: the override line (10), the importer entry (33-35), 47 lines of 13 package entries and 58 lines of 13 snapshot entries. No remaining entry changed. zod 4.6.7 stays, for the root dependency (`^4.6.7`), `eslint-plugin-react-hooks` 7.1.1 and `zod-validation-error` 4.0.2.
- How the lock was made, from the seat's log and two scripts posted on #945 (issuecomment-6965716529, 2026-11-18 01:00Z): `pnpm install --lockfile-only --ignore-scripts` with the pinned pnpm 10.18.1 removed the 109 lines and also the 36 `libc:` lines; a script put the 36 back, each after the `os:` line of its entry; the result is byte for byte the committed lock (sha256 `be168eda6f66caa6…`, which the blob at `1a5429d1a` also gives). On the committed pair a frozen lockfile-only run exited 0 and a plain one rewrote nothing. With `main`'s `package.json` the frozen run refused with exit 1, so the check can fail.
- The `libc:` lines stay on the operator's word (answers of 2026-11-18, E1: "as it stands, with its libc: lines"). The lock had none before Dependabot's #936 (`527435a66`: 0) and has 36 since (`60e2c9d3f`, `b8428c4d6` and `1a5429d1a`: 36 each). Why a regeneration on the seat's host drops them is not established.

Not done: the nested locks, `pnpm-workspace.yaml` and the dated records that name the package (§3).

## 3. Report

File figures are parsed from the blobs in the seat's clone (`git show <ref>:<path>`). Run figures are read from the job logs, on 2026-11-18. Before = `main` at `b8428c4d6`. After = #945's head `1a5429d1a`, which CI tested as merge commit `a0b222a` on that `main`.

| Check | `main` `b8428c4d6` | #945 head `1a5429d1a` |
| --- | --- | --- |
| `package.json`: dependencies / pnpm overrides | 28 / 20 | **27 / 19** |
| `pnpm-lock.yaml`: lines / packages / snapshots | 11,142 / 1,129 / 1,145 | **11,033 / 1,116 / 1,132** |
| Lock lines that name `atproto` / zod 3 (`zod@3`, `zod: 3.`) | 27 / 6 | **0 / 0** |
| `libc:` lines in the lock | 36 | 36 |
| `unit` job, `pnpm install --frozen-lockfile` (pnpm v10.18.1) | "Lockfile is up to date, resolution step is skipped"; `Packages: +1037` (run 44192009589, job 134423566851) | the same line; **`Packages: +1024`** (run 44197556601, job 134442863079) |
| `unit` job: jest / `node --test` / `tsc --noEmit` / ESLint step | 5 suites, 126 tests / 17 of 17 / success / success | 5 suites, 126 tests / 17 of 17 / success / success |
| OSV-Scanner | push run 44192010649, red: 13 rows in 9 packages, zod 3.25.76 among them; 1,129 packages read from `pnpm-lock.yaml` | pull-request scan, run 44197557219, green: "No issues found" against the base; 1,129 packages on the base, 1,116 on the head |
| Check runs | — | 22: 21 success, 1 skipped (`scan-scheduled`); the seven required contexts are success |

- ESLint's counts go to the run summary and to the `unit-test-results` artifact, not to the log. The table shows the step's outcome, which the log gives.
- **At the merge.** GitHub's "Update branch" moved #945 to `18429167a`. Check runs there: 23, of which 22 success and `scan-scheduled` skipped; the seven required contexts are success. The one check more than on `1a5429d1a` is `.github/dependabot.yml`, on pull requests since #943 changed that file. `unit` job there (run 44395209946, job 135123164553): the same frozen install with `Packages: +1024`; jest 5 suites, 126 tests; `node --test` 17 of 17; `tsc` success; ESLint 234 files, 3,336 errors (0 fatal) and 1,889 warnings, which is `main` after #943. OSV pull-request scan there (run 44395213131), read by rows: 3 rows on the base, 2 on the head, none added, the zod row gone. Squash-merged at 2026-11-18T20:54:24Z as `4c3761361`.
- **After the merge, on `main`.** Push runs: 7 on `4c3761361`, 6 success and OSV-Scanner failure. OSV-Scanner: push run 44395911508, 2 rows, glob 10.5.0 and glob 13.0.7 (GHSA-3g3m-2fjr-6pw4) in `pnpm-lock.yaml`; the zod row is gone. Dependabot's own runs: one, 44396147597 (npm, root), success; Dependabot closed its own #954 (npm-all group, opened 20:47Z) at 20:59Z, and the seat touches none of its pull requests (answers, E5). Of the 13 known rows, the zod row was this change's. The rows of `BRAV/INFR/deployment-pipeline/package-lock.json` left with #943, which deleted that file, and the three picomatch rows left earlier the same day with no lockfile change (advisory data; first in push run 44386644307). The two glob rows are #946's, which has no go, so OSV-Scanner stays red on `main`.
- **Not measured.** Dependabot alert 593 was open before the merge (read 2026-11-18 18:34Z). Its state after the merge is not read in this report.
- **What the checks cover.** On a pull request the frozen install runs in the `unit` job (`bosscat-gate-verify.yml:352`); the four `Gate Verify` jobs of the same workflow install with `--frozen-lockfile=false` (line 110). Neither the `unit` job nor OSV-Scanner is a required context. Three dispatch-only workflows also install from the frozen lock (`multi-app-ci.yml:113`, `bosscat-gate-bot-native.yml:64`, `bosscat-tetragram-guard.yml:27`). None of them ran on this change, and the operator's answers (D1) hold every dispatch but the prune's.
- Found, not changed:
  - `BRAV/SCPT/run-archiver/package-lock.json:26` and `BRAV/INFR/deployment-pipeline/package-lock.json:37` (at `b8428c4d6`) still say `"@atproto/api": "0.20.44"`, in the copy of the root dependency list under their `../../..` entry. #943 has since deleted the second file.
  - `pnpm-workspace.yaml` has an `overrides` block of its own (fast-json-patch `>=3.1.1`, protobufjs `>=7.5.5`, fast-xml-parser `>=5.3.5`). The lock's block mirrors `package.json`'s (protobufjs `>=8.0.1`, fast-xml-parser `>=5.3.4`).
  - Dated records that name the package stay as filed: `docs/BossCat/BOSSCAT_LOG.md` (lines 4 and 17 at `b8428c4d6`), `docs/status/misc/STATUS.md:139`, and `ECRR_READY_FOR_GATE_AUDIT_20261101.md:40` and `:114`.
  - The message of the branch commit `1a5429d1a` and the docstring of the posted `lock_tools.py` name a cause for the `libc:` lines (Dependabot's pnpm version). No cause is established, and the description of #945 says so.
  - The posted log's control (its section 6) shows pnpm's hint line and exit 1, not the error line. The operator's answers (G2e) give it as `ERR_PNPM_LOCKFILE_CONFIG_MISMATCH`, removed by the script's filter. The comment stays as posted (answers, A3).
  - #946 (glob override) changes the same two files and has no go. The operator's answers (E2) have its branch updated and its lock proof run again once #945 is on `main`. That was done at 20:56Z: the regenerated lock equals the updated head's byte for byte, and nothing was pushed (comment on #946).
- Proposed fragment for the batch's `BOSSCAT_LOG.md` line (docs lane, after the last of #943–#947):

```text
#945 removed the unused `@atproto/api` dependency and its pnpm override: nothing had imported it since the socm split (#366, 2026-07-24), 13 packages left `pnpm-lock.yaml` with it, zod 3.25.76 among them (GHSA-mrhx-c7xc-m3w5, audit finding P3-2), and the lock keeps its 36 `libc:` lines. OSV-Scanner on `main` after the merge: 2 rows, both glob (run 44395911508) (`ECRR_ATPROTO_API_REMOVED_20261118.md`).
```

## 4. Role

- Claude Code (local seat): the change, PR #945, the proof comment, the branch update and the squash merge on the operator's go, and this report. Its `Driving:` assignment for #943 to #945 is the comment on #943 of 2026-11-18T20:34Z. A read-only report agent drafted this report before the merge; the second reader planned for that draft did not run, and the seat spot-checked its counts, line numbers and commits and read the merge-time figures itself.
- Planning and review agents (2026-11-17): a planning agent and an independent critic of the plan, then review agents on `1a5429d1a`. The critic corrected the plan's predicted install count: `+1024` only with the `libc:` lines kept, `+1029` without them. The review asked for no change to the diff. Its corrections to the description have been made, among them the measured figures and the cause of the `libc:` lines, now marked as not established; the same sentence in the branch commit's message stands (§3).
- The review seat: ran the posted lock scripts unchanged on Linux (node 22.23.4, pnpm 10.18.1) and got the same lock log apart from the date, the node patch version and the timings (operator's answers, G1).
- Operator `@fubumaki`: the go to open this follow-up (2026-11-16, section 8) and the merge go for #945 at `1a5429d1a` (answers of 2026-11-18, E1).

**Status:** CLOSED (2026-11-18T20:54:24Z): merged as `4c3761361`.
