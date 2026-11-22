# ECRR — Fresh-host start order: `start-signoz.ps1` before any compose command in `README.md` and the clean-host briefing

**Date:** 2026-11-18
**Actor:** Claude Code (local seat), on the operator's explicit go of 2026-11-16 (section 8) and answers of 2026-11-18 (E1)
**Scope:** PR #944, docs lane: `README.md` and `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md`, 2 files, 5 insertions and 3 deletions (commit `2e83f8bc3`, merged as `f12958d9a`).
**Verdict:** **AMBER** — both documents now give a fresh host one start order, what they say about the script, the helper and the compose file matches the code on `main` (read, not run), and all 15 check runs on the head named in E1 passed. Not proven by a run: the order on a clean host (the last recorded clean-host run, 2026-08-23, predates #910) and the refusal of `docker compose pull` and `up` (only `docker compose config` was measured). Closes GREEN when a clean-host run made after #910 is recorded in `CHAR/EVID/clean-host/latest.json` (the operator's paused drill, #849, by 2026-12-07) and an addendum here names it.
**Trigger:** #910 (`f64e8b5de`, 2026-11-17) made the five compose files require `SIGNOZ_JWT_SECRET`, with no default. `ECRR_SIGNOZ_CREDENTIALS_IN_TREE_20261104.md` names the two places that still put a compose command first (F7 at line 90 and its addendum at line 147), and section 8 of the go asked for the correction in the docs lane.

## 1. Examine

All at `main` `b8428c4d6`.

- **`README.md:52`**, the Docker requirement, told a fresh host to "run `docker compose pull` before `docker compose up`" (`a0ace24d`, 2026-07-25T23:47Z). It was the file's only line naming `docker compose`, and no line named `start-signoz.ps1`.
- **The briefing** (`docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md`, from #389, `c21aa9aa`). Line 66, the canonical-targets row, offered "Root `docker-compose.yml` via `start-signoz.ps1` or `docker compose up -d`". Line 46, the seat table, said "Scripted compose up" (#832, `c193b064`). The Phase 2 block (lines 115-119) already ran `pwsh -File C:\otel\start-signoz.ps1` first, with no reason given. `.kiro/agents/bosscat.json:10` loads this briefing as an agent resource.
- **What #910 changed.** `docker-compose.yml:102-103` takes the variable as `${SIGNOZ_JWT_SECRET:?set SIGNOZ_JWT_SECRET in .env}`: the file's only two `${...}` references, with no default and no `env_file`. The four files under `compose/` carry the same form, and `git log -S` over the five files returns #910 alone. A fresh clone has no `.env` (`.gitignore:46`; the file is not tracked), and `.env.example:10` leaves the value empty. #910 also added the helper `BRAV/SCPT/security/ensure-signoz-signing-key.ps1` (70 lines) and its call at `start-signoz.ps1:9`, ahead of the script's first compose call at line 13. The helper writes 64 hex characters from the OS random generator when the value is missing, empty or a placeholder, keeps an existing value and prints none (lines 46-51 and 56-69). So on a fresh clone the variable has no value until the script has run.
- **What the record already held.** `ECRR_SIGNOZ_CREDENTIALS_IN_TREE_20261104.md` records `docker compose config` exiting 1 with "required variable SIGNOZ_JWT_SECRET is missing a value" on the five compose files (lines 72 and 126). For `pull` and `up` it says the review found the refusal and the driver measured it with `config -q` only (line 147).
- **No clean-host run since #910.** `CHAR/EVID/clean-host/latest.json` is `clean-host-e2e-20260823`, GREEN, dated 2026-08-23. The drill is paused and is the operator's to run by 2026-12-07 (`BOSSCAT_LOG.md`, **[CLEAN-HOST E2E GATE: PAUSED]**, 2026-11-17T13:46Z); #849 is open. Its gate clock (`docs/runbooks/clean-host-e2e.md:23`) is `scripts/windows/invoke-clean-host-e2e.ps1`, which clones and then calls `.\start-signoz.ps1` (lines 220-235), holds no compose command and names neither document. The drill already uses the right order; it does not test the corrected text.

## 2. Clean

- `README.md:52`, one line replaced. A fresh host runs `pwsh -File .\start-signoz.ps1` from the repository root before any `docker compose` command. The line says what the script does first (a random `SIGNOZ_JWT_SECRET` into `.env`, an existing value kept), why (`docker-compose.yml` has no default, and compose stops with "required variable SIGNOZ_JWT_SECRET is missing a value"), and that the script then starts the stack, which pulls the images on a first run. The measured pull time stays (about 6.2 of 7.5 minutes, `clean-host-e2e-20260726`). The advice to pull before `up` is gone, because `pull` is itself a compose command.
- Briefing line 66: the script is the only start, with the reason in the cell, and "any `docker compose` command before `start-signoz.ps1` has run" joins the "Do **not** use" column. The row still has three cells.
- Briefing Phase 2 block: two comment lines (116-117) above the unchanged command say to run it first, from `C:\otel`, and why.
- Briefing line 46: "Scripted compose up" becomes "Scripted SigNoz start (`start-signoz.ps1`)".
- Nothing else changes: no code, no workflow, no mirror file. Neither document has a HISTORICAL or dated-record banner in its first ten lines, so their bodies were edited.

## 3. Report

Before = `main` `b8428c4d6`; after = #944's head `2e83f8bc3`, the commit the go names (E1). Both were read with `git show` and `git diff` in a clone; the checks were read on GitHub on 2026-11-18. None of the batch's other four pull requests (#943, #945, #946, #947) touches either file.

| Check | Before | After |
| --- | --- | --- |
| `README.md`: lines naming `docker compose` / `start-signoz.ps1` | line 52 / none | line 52 / line 52 |
| `README.md:52`: first command for a fresh host | `docker compose pull` | **`pwsh -File .\start-signoz.ps1`**, from the repository root |
| Briefing line 66: ways to start the stack | 2: `start-signoz.ps1` or `docker compose up -d` | **1**: `start-signoz.ps1`; a compose command before it is under "Do **not** use" |
| Briefing Phase 2 block | lines 115-119, no reason given | lines 115-121, two comment lines above the same command |
| Lines / bytes (`git diff --numstat`: 1 and 1, 4 and 2) | README 186 / 8,617; briefing 205 / 10,349 | README 186 / 8,969; briefing 207 / 10,689; LF, no BOM |
| Briefing blob: source / mirror copy under `CHAR/DOCS/` | `a033325e` / `a033325e` | `21f9eb70` / `a033325e` |
| Check runs on `2e83f8bc3` (seven workflow runs, all `pull_request`) | — | **15 of 15 success**, the seven required checks among them |
| Check runs on the updated head `86b16e2fa` | — | **16 of 16 success**, the seven required checks among them; the sixteenth is a check named `.github/dependabot.yml`, on pull requests since #943 changed that file |

- `docs_gate` (run 44197093900): budget 2 of 10 files and 8 of 200 lines; markdownlint-cli2 0.14.0 over 2 files, 0 errors; lychee 0.20.1, 45 link results, 38 with status 200, 7 excluded, none failed. `gitleaks` (run 44197093765): 1 commit scanned, no leaks.
- What the checks cannot show: none runs the documented commands. In run 44197093508 the three Gate/Site required checks ran their `PR lane short-circuit` step and skipped their k6, trace and site steps (`gate-site-evidence.yml:42, 91, 151`), and the publish job skipped `deploy-pages`. The checks show that the text is well formed, not that the order works.
- Unit job and OSV pull-request scan: absent by design. Both changed files are `.md` files, and `bosscat-gate-verify.yml:22-26` and `osv-scanner.yml:23-27` skip `docs/**` and `**/*.md` on pull requests; neither workflow has a run on `2e83f8bc3`.
- Merged 2026-11-18T20:48:38Z as `f12958d9a`: squash, after GitHub's "Update branch" (to `86b16e2fa`) and fresh checks; the `Driving:` comment for the three merges of E1 is on #943 (20:34Z). Runs on `main` from the merge: 8, of which 7 success (`deploy-hub.yml` run 44394903546 among them) and OSV-Scanner failure. OSV-Scanner on `main` after the merge: run 44394904067, 3 rows (glob 10.5.0, glob 13.0.7 and zod 3.25.76, all in `pnpm-lock.yaml`), the same as before it. Dependabot's own runs: none on this commit.
- Recorded by the seat when it built the change, and not re-run for this report: in a fresh clone of `b8428c4d6` without `.env`, `docker compose config -q` (Compose v5.3.1) exits 1 with "required variable SIGNOZ_JWT_SECRET is missing a value: set SIGNOZ_JWT_SECRET in .env" (#944's commit message and description). Not measured by anyone: `pull` and `up` without the variable (section 5 of the go allows the seat `config -q` only), and `start-signoz.ps1` with the helper on a clean host, its first-run image pull included.
- Found, not changed:
  - `compose/README.md:4-7` still says "Prefer: `docker compose up -d`", and `docs/runbooks/signoz-stack-upgrade.md` has compose commands on 17 lines (`pull` and `up -d` among them) and names neither `start-signoz.ps1` nor the variable. Both are live documents outside the two the go named. The plan lists more under `docs/`; they were not re-read for this report.
  - `BRAV/SCPT/preflight-health-check.ps1:159`, which the briefing's Phase 2 runs through the three-line wrapper `scripts/preflight-health-check.ps1`, prints on a failed check the hint `docker-compose -f compose/docker-compose-signoz.yml up -d`: the parked file that briefing line 66 lists under "Do **not** use". Code lane.
  - `start-signoz.ps1:13` has no exit-code check and the wait at lines 17-24 has no limit, so a first compose call that fails (its `-f docker-compose.yml` is relative to the current directory) leaves the script waiting for ClickHouse without end. Read in the code, not run. It is why "from the repository root" and "from `C:\otel`" are in the new text. Code lane.
  - `README.md:52` says "an existing value is kept". With the variable set in the process environment the helper writes nothing (helper lines 31-34): true for a fresh host, incomplete for others.
  - The briefing's Status line (lines 6-7) still says "next gate before Mon 2026-09-28"; the gate is paused to 2026-12-07.
  - `bosscat-governance.yml`, by its own header the only commit-message lint in the repository, skips docs-only pull requests (lines 12-16), so it has no run on `2e83f8bc3`; its commit-message step runs on pull requests only (lines 50-51), so a push to `main` does not lint the squash subject either. The title starts with `docs`.
  - The README no longer names a way to pull the images ahead of the gate clock. The operator decided it: merged as it stands, no pre-pull sentence (answers of 2026-11-18, E1).
  - From this merge until the batch's mirror pull request the briefing and its mirror copy differ: expected, and not a stop (answers of 2026-11-18, E6). `README.md` has no mirror copy; `CHAR/DOCS/README.md` is another file.
- Proposed fragment for the batch's `BOSSCAT_LOG.md` line:

```text
#944 (docs lane, `f12958d9a`): `README.md:52` and the clean-host briefing (lines 46 and 66 and the Phase 2 block) now send a fresh host to `start-signoz.ps1` before any `docker compose` command, because compose has had no default for `SIGNOZ_JWT_SECRET` since #910. The refusal is measured for `docker compose config` only and the new order has no clean-host run yet (#849, by 2026-12-07); `ECRR_START_SIGNOZ_BEFORE_COMPOSE_20261118.md`, AMBER.
```

## 4. Role

Claude Code (local seat): the plan, the change (`2e83f8bc3`), PR #944 (opened 2026-11-17T23:11Z), the merge as driver and this report, which a read-only report agent drafted before the merge; the second reader planned for that draft did not run, and the seat spot-checked its line references, blob ids and history and read the merge-time figures itself. Review agents started by the seat: a critique of the plan before the change, which corrected its statements about the title lint and added the gitleaks `named-secret-literal` rule and the script's endless wait; and a review of the pull request as opened, which asked for no change to the diff and for two corrections to the description (it now carries both), and left four notes. All seven workflow runs on `2e83f8bc3` came from the `pull_request` event; none was dispatched. Operator `@fubumaki`: the go of 2026-11-16 (section 8), the merge go and the decision on the pre-pull sentence (answers of 2026-11-18, E1), and the clean-host drill (#849) that closes this report.

**Status:** OPEN: merged as `f12958d9a` (2026-11-18T20:48:38Z); closes with an addendum when a clean-host run made after #910 is on record (#849, the operator, by 2026-12-07).
