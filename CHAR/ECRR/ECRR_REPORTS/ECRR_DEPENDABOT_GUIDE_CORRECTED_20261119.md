# ECRR — Dependabot guide lists root and run-archiver only, after the deployment-pipeline retirement

**Date:** 2026-11-19
**Actor:** Claude Code (local seat), on the operator's explicit go of 2026-11-16 (section 8) and answers of 2026-11-19 (I2)
**Scope:** PR #947, docs lane, merged as `d5b54848d` at 2026-11-19T04:35:01Z from the updated head `c424098d9`: one file, `docs/BossCat/DEPENDABOT_SECURITY_GUIDE.md`, 4 insertions and 4 deletions; two commits by the seat, `53ab853c3` (2026-11-17) and `c87a14be2` (2026-11-18), and two of GitHub's own branch updates.
**Verdict:** **GREEN** — the guide on `main` names the npm directories that `.github/dependabot.yml` has had since #943: the root and `BRAV/SCPT/run-archiver` (§3). On the updated head `c424098d9`: 15 check runs, all success, among them `docs_gate`, with the seven required checks green. The mirror copy under `CHAR/DOCS` still has the old text and changes at the batch's republish.
**Trigger:** section 8 of the go, after the retirement of `BRAV/INFR/deployment-pipeline` (#943): "The guide correction that follows is docs lane."

## 1. Examine

Read at `main` `b8428c4d6` (2026-11-17), the base #947 was built and reviewed on.

- **Two places named the retired directory or counted it.** Line 31, the npm line of the configuration sketch, listed `"/", "/BRAV/SCPT/run-archiver", "/BRAV/INFR/deployment-pipeline"`. Line 44, the table of monitored ecosystems, said "root + 2 tool dirs". The runbook names line 31; line 44 would have been false without its change. The footer, line 512, dated the guide 2026-09-01.
- **One slip that is not about the retirement.** Line 26, the header of the sketch, named #702 for the sidecars directory. #701 added it (`8dd73d84`); #702 was a Dependabot bump in that directory, merged later the same day. The guide's own footer already said #701.
- **Order.** The guide describes `.github/dependabot.yml`, so the correction had to follow #943. Until #943 was on `main` the old text was right, apart from the #702 slip.
- The guide carries no HISTORICAL or dated-record banner, so its body may be corrected.

## 2. Clean

PR #947 changes four lines of one file:

- Line 26: "sidecars dir added 2026-09-01 (#701); deployment-pipeline dir retired (#943)".
- Line 31: `"/" and "/BRAV/SCPT/run-archiver"`.
- Line 44: "root + `BRAV/SCPT/run-archiver`".
- Line 512: "Last Updated: 2026-11-18 (Dependabot config: deployment-pipeline directory retired, #943)". The date is the UTC date on which #943 merged; it was set in the second commit, `c87a14be2`, after GitHub's branch update of 2026-11-18 (answers of 2026-11-18, E3). The "truth pass 2026-09-25" on the same line stays.

Not done here: the mirror copy `CHAR/DOCS/docs/BossCat/DEPENDABOT_SECURITY_GUIDE.md` and the batch's line in `BOSSCAT_LOG.md`, each in its own pull request.

## 3. Report

| Check | Before, `main` at `ee2759019` | #947 at the updated head `c424098d9` | After the merge, `main` at `d5b54848d` |
| --- | --- | --- | --- |
| npm directories in the guide's sketch (line 31) | root, `BRAV/SCPT/run-archiver`, `BRAV/INFR/deployment-pipeline` | root, `BRAV/SCPT/run-archiver` | root, `BRAV/SCPT/run-archiver` |
| npm blocks in `.github/dependabot.yml` | `/` and `/BRAV/SCPT/run-archiver` (five update blocks, since #943) | the same | the same |
| Check runs on the head | — | 15, all success, among them `docs_gate`; the seven required checks green | — |
| `unit` job and OSV-Scanner check | — | absent by design: the only changed file is under `docs/` | — |
| Runs on `main` other than scheduled ones | — | — | 8 on `d5b54848d`, all success, among them Deploy Hub Website (run 44459321853) and OSV-Scanner (run 44459323034, no row) |
| `docs/` against its mirror `CHAR/DOCS/docs` | one file differs: the clean-host briefing (#944) | — | two files differ: the briefing and this guide |

- The two commits by the seat were measured before the go: 15 check runs, all success, on `53ab853c3` (2026-11-17) and on `c87a14be2` (2026-11-18). After the head check of 2026-11-19 the only new commit is GitHub's Update-branch merge `c424098d9`.
- The difference between `docs/` and the mirror is expected until the batch's mirror pull request (answers of 2026-11-18, E6; of 2026-11-19, J2).
- **Found, not changed:** `docs/BossCat/SECURITY_MAINTENANCE_MASTER_GUIDE.md` line 34 gives an older "Last Updated" for this guide. It was stale before this change and is a matter for the next truth pass.
- Proposed fragment for the batch's `BOSSCAT_LOG.md` line (docs lane):

```text
#947 (`d5b54848`, 2026-11-19T04:35Z) corrected `docs/BossCat/DEPENDABOT_SECURITY_GUIDE.md` after #943: the npm directories are the root and `BRAV/SCPT/run-archiver`, the sidecars directory came with #701 (not #702), and the footer is dated 2026-11-18. ECRR `ECRR_DEPENDABOT_GUIDE_CORRECTED_20261119.md`.
```

## 4. Role

Claude Code (local seat): the change, PR #947 and its description, the footer commit and description update of 2026-11-18 (E3), the merge as driver under section 5 of the go (`Driving:` comment on #946 at 04:20Z on 2026-11-19; GitHub's Update branch to `c424098d9`, then the squash `d5b54848d`), and this report. The seat wrote it from `main`; one read-only review agent then checked it against GitHub and the operator's texts, and its two findings are applied. Chat/review seat: the review of the head `53ab853c3`. Operator `@fubumaki`: the go of 2026-11-16 (section 8), the instruction of 2026-11-18 (E3) and the go for this merge at `c87a14be2` (answers of 2026-11-19, I2). Still the operator's: the go for this report (answers of 2026-11-19, J1).

**Status:** CLOSED (2026-11-19T04:35:01Z): merged as `d5b54848d`.
