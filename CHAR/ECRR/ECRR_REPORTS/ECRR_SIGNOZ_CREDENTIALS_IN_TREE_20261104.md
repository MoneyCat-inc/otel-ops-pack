# ECRR — SigNoz credentials in the public tree: five API keys and the JWT signing default (found 2026-11-04)

**Date:** 2026-11-04
**Actor:** Claude (chat/review seat), from a claude.ai/code cloud session: a fresh clone of the repository, no host access, no credentials. Every value below is named by `sha256[:8]`, length and `file:line` only; no value was printed to output, a commit, a PR body or this report (one harness exception, §1d).
**Verdict:** **RED for the credentials until the operator revokes and rotates (F1, F2). GREEN for the tree once #909–#913 merge:** the five branches merged together leave 0 occurrences on `main` (§2).
**Trigger:** the 2026-11-04 OEM review of PRs #900–#908 found SigNoz credential literals on `main`. None of those PRs introduced them.

## 1. Examine

### 1a. What `main` carried (`729121a1`)

Found by fingerprint, by every 16-character window of each value, and by shape (any 44-character base64 token that decodes to 32 bytes; the shape sweep matched these five keys and nothing else).

| `sha256[:8]` | Length / shape | What it is | First committed | Lines on `main` | Status on record |
| --- | --- | --- | --- | --- | --- |
| `8abc66bc` | 44, base64, 32 B | SigNoz API key ("received from user" 2025-09-27) | 2025-09-27 `f27614f2` | 8: `BRAV/SCPT/setup-signoz-monitoring.ps1:7`; 7 in `CHAR/ECRR/ECRR_REPORTS/archive/` | no revocation on record |
| `869a41b7` | 44, base64, 32 B | SigNoz API key; shares its first ~30 characters with `8abc66bc` | 2025-09-28 `870b9c8a` | 4: `manage-signoz-alerts-api.ps1:5`, `test-signoz-api-auth.ps1:5`, `security/remediate-secrets.ps1:33`, `security/pre-commit-hook.sh:62` | no revocation on record |
| `3e775a2b` | 44, base64, 32 B | SigNoz API key (IONA-GATE-002) | 2025-09-28 `eec483e1` | 6: `create-signoz-compliance-dashboard.ps1:5`, `deploy-windows-canary-alert-api.ps1:5`, `security/remediate-secrets.ps1:21`, `:27`, `security/pre-commit-hook.sh:57`; 1 in `CHAR/ECRR/ECRR_REPORTS/archive/` | ordered revoked 2025-10-07 (checklist; mirror copy redacted by #643) |
| `089c8993` | 44, base64, 32 B | SigNoz API key | 2025-10-08 `2b0369c8` | 2: `check-alerts.ps1:1`, `debug-alert-fields.ps1:1` | no revocation on record |
| `c66026b5` | 44, base64, 32 B | SigNoz API key, Viewer, one day | 2025-10-27 `2dfd2d8d` | 14: 7 in `docs/` (two Gate 029/030 records and their `docs/gate/archive/` copies, plus three other gate records), 7 in the `CHAR/DOCS/docs/` mirror | recorded as expiring 2025-10-28 |
| `7b2b10c7` | 30 | SigNoz JWT signing secret: the compose default | 2025-09-30 `bc03083d` (#51) | 13: 5 compose lines (`docker-compose.yml:102-103`, `compose/docker-compose-signoz.yml:112`, `compose/docker-compose.unified.yml:93`, `compose/legacy.yml:194`); default `-ApiToken` of 7 `BRAV/SCPT/*.ps1` (line 6); browser fallback `ALFA/LIBS/lib/tracing.ts:27` | **the live secret 2025-10-05 → 2026-07-24** (§1b) |
| `26e535a5` | 23 | the first 23 characters of `7b2b10c7` | 2025-10-05 `583ba20c` | 1: `compose/docker-compose-signoz-simple.yml:58` | — |

**Total: 48 lines in 41 files, 7 values** (the five API keys, the JWT default, and its prefix). First-commit dates are author dates of the oldest commit that `git log -S` finds for each value.

Three findings were not called out in the review briefing:

- `security/pre-commit-hook.sh:57,62` and `security/remediate-secrets.ps1:21,27,33` stored the keys as *search patterns*: a scanner and a remediation script that kept the very values they were meant to remove.
- 8 lines in five `CHAR/ECRR/ECRR_REPORTS/archive/` reports (evidence lane): `8abc66bc` ×7, `3e775a2b` ×1.
- `deploy-windows-canary-alert-api.ps1:47` and `setup-signoz-monitoring.ps1:199` printed the first 8 characters of the token to the console.

### 1b. Exposure classes

| # | Class | Evidence |
| --- | --- | --- |
| E1 | **Current tree of a public repository.** Anyone can read all 48 lines on github.com today. | §1a sweep of `main` at `729121a1` |
| E2 | **History.** Every value is reachable from its first commit onward. The 2026-07-24 rewrite (Pack 3, `BOSSCAT_LOG` 15:51Z/15:53Z) purged media only. | `git log -S` per value |
| E3 | **PR refs.** `refs/pull/*/head` are GitHub-managed and read-only; a rewrite of `main` cannot reach them. | `git ls-remote`: 871 PR head refs. `refs/pull/51/head` (`84f4fed3`, not in `main`'s lineage) holds `3e775a2b 7b2b10c7 869a41b7 8abc66bc`; `refs/pull/901/head` (`baa7ce20`) holds all six fingerprinted values |
| E4 | **The JWT default was the live secret.** A tracked `.env` set `SIGNOZ_JWT_SECRET` (line 22, length 30, `7b2b10c7`) from its addition in `583ba20c` (2025-10-05) to its untracking in `c7076ca5` (2026-07-24), with no commit to it in between. After that, the same value stayed the compose default for any checkout without its own `.env`. Anyone with the public value can sign tokens with SigNoz's own key. | `git show 583ba20c:.env`, fingerprinted per variable; `git log -- .env` |
| E5 | **Network reach.** All five compose files published the SigNoz UI/API as `"8080:8080"`, every host interface, so E4 was usable by anyone who could reach the host's port 8080. | compose files on `main` |
| E6 | **Browser code.** `tracing.ts` put the JWT default into a `signoz-access-token` header from the browser, which would ship the value to every client of a bundle that included it. Nothing imports the file today (`git grep`), so this exposure was latent. | `ALFA/LIBS/lib/tracing.ts:27` |
| E7 | **Logs.** Two scripts printed an 8-character prefix of whatever token they used. | §1a |

### 1c. Why nobody saw it, and why history stays

- **The scanners never look back.** `gitleaks.yml` scans `base..head` on a PR and `--log-opts=-1` (the tip commit's patch) on push, on the daily schedule and on dispatch. A value committed in 2025 is never re-scanned. `.gitleaks.toml`'s global allowlist also skips `*.md`, `*.example` and `*.template` entirely, so the 22 markdown copies (7 in `docs/`, 7 in the mirror, 8 in the evidence archive) were invisible to it even when new. #643 (2026-08-28) redacted one mirror copy of `3e775a2b` to unanchor secret-scanning alert #2; its siblings in the tree were not swept.
- **History cannot be rewritten.** The one-per-lifetime `git filter-repo` budget is spent (`docs/BossCat/ROADMAP_2026H2.md:201`; spent on 2026-07-24, `BOSSCAT_LOG.md`), and E3 would survive a rewrite anyway, as would forks, clones and caches. Removing the live copies stops new copies, scanner anchors and copy-paste reuse. **Only revocation and rotation remove the risk** (F1, F2).

### 1d. Disclosure: this session's transcript

When PR #910's branch was created in the same working directory, `git checkout` put the original `BRAV/SCPT/security/pre-commit-hook.sh` back on disk. The Claude Code harness then attached a "file changed on disk" notice that quoted its lines 57 and 62 into the session transcript: **`3e775a2b` and `869a41b7` transited chat tooling** on 2026-11-04. Both were already public (E1–E3) and are in F1. Under the AGENTS.md blast-radius rule they are rotated with no further deliberation. After that, the remaining branches were built in separate `git worktree`s so that no further notice could carry a value.

## 2. Clean

One lane per PR (CHARTER, Lane discipline). Nothing was merged by this seat.

| PR | Lane | Lines removed | What else |
| --- | --- | --- | --- |
| #909 | code | 12 in 9 files (`089c8993`, `3e775a2b`, `869a41b7`, `8abc66bc`) | API scripts read `$env:SIGNOZ_API_KEY` and throw when it is unset (offline modes exempt); the token prefix is no longer printed; `remediate-secrets.ps1` matches the key shape; `pre-commit-hook.sh` blocks the five revoked keys by `sha256` prefix |
| #910 | code | 14 in 13 files (`7b2b10c7`, `26e535a5`) | `${SIGNOZ_JWT_SECRET:?set SIGNOZ_JWT_SECRET in .env}` in all five compose files; `signoz` bound to `127.0.0.1:8080`; the 7 scripts read `$env:SIGNOZ_API_KEY`; `tracing.ts` sends the header only when configured; new `BRAV/SCPT/security/ensure-signoz-signing-key.ps1` writes a random 256-bit value into `.env` from `start-signoz.ps1` and `startup-observability.ps1`; `.env.example` leaves it empty |
| #911 | docs | 7 in 7 files (`c66026b5`) | marker `[REDACTED-SigNoz-test-key-expired-2025-10-28]`; rule-scoped markdownlint line on the five `docs/gate/archive/` files (pre-existing findings) |
| #912 | docs (mirror) | 7 in 7 files (`c66026b5`) | `CHAR/DOCS/docs` republished from #911's `docs` tree |
| #913 (this PR) | evidence | 8 in 5 files (`8abc66bc` ×7, `3e775a2b` ×1) | markers `[REDACTED-SigNoz-key-8abc66bc-see-ECRR-20261104]` and #643's `[REDACTED-old-SigNoz-key-rotated-2025-10-07]`; three files staged byte-exact so their stray CRs are not rewritten; this report |

**Proof of the end state.** The five heads merged together with `git merge-tree` (no conflicts; combined commit `100cf044`, built before this report was added) give:

- 0 lines carrying any of the seven values or any 16-character window of one;
- 0 SigNoz-key-shaped tokens;
- 0 SigNoz JWT defaults (`:-`), 0 literal `SIGNOZ-API-KEY` header values, 0 literal `-ApiToken`/`-ApiKey` defaults, 0 `signoz-access-token` fallbacks;
- `docs` and `CHAR/DOCS/docs` as the same tree (`ace0ba2a`).

`docker compose config` (Compose v5.6.1) on each of the five compose files exits 1 with `required variable SIGNOZ_JWT_SECRET is missing a value: set SIGNOZ_JWT_SECRET in .env` when the variable is unset or empty, and exits 0 with the `signoz` port on `127.0.0.1` when it is set.

**Not cleaned, by design:** git history and `refs/pull/*` (§1c). The AtLogOn task `scripts/windows/ensure-signoz-stack.ps1` is not taught to generate a secret: a new value on a running host is a rotation, and rotation is the operator's.

## 3. Report

**F1 — RED, open (operator): revoke the API keys.** In SigNoz (Settings → API Keys), on every instance that ever used them: delete `8abc66bc`, `869a41b7`, `3e775a2b` and `089c8993` if they still exist, and confirm that `c66026b5` expired on 2025-10-28 as recorded. Mint replacements least-privilege and keep them in `$env:SIGNOZ_API_KEY` / the existing GitHub secret, never in a file. A key whose instance no longer exists needs no action beyond noting it.

**F2 — RED, open (operator): rotate the JWT signing secret.** On every host that has run the stack, after #910 merges: `git pull`, then `pwsh -File start-signoz.ps1`, or `pwsh -File BRAV/SCPT/security/ensure-signoz-signing-key.ps1` then `docker compose up -d`. The `signoz` container is recreated with a fresh value and every session signed with the public one stops working, so users sign in once more. Until then, the AtLogOn task's `compose up` fails closed with the message in §2 while the running containers keep their old configuration: that log line is the reminder.

**F3 — AMBER, open (operator): look for use of E4/E5.** The public JWT secret and the all-interfaces port overlapped for as long as both existed. SigNoz keeps no authentication audit log that this seat could read. The cheap checks are the user list and the API-key list for entries nobody made, and whether the host's port 8080 was ever reachable from outside the machine (firewall profile, port forwarding). #910 closes the port to loopback.

**F4 — AMBER, open (operator decides): the scanners cannot fail on this class.** Options, in order of value: (a) a scheduled full-tree scan (`gitleaks dir .` or `detect --no-git`), with the markdown allowlist narrowed rather than global; (b) wire `security/pre-commit-hook.sh`, which now carries the five revoked fingerprints, into `lefthook.yml`; (c) a weekly `git grep` for 44-character base64 tokens in CI. Option (a) is a CI/ops-lane PR. Per PURPOSE it must be able to both pass and fail, which is easy to prove with a seeded fixture.

**F5 — INFO: adjacent values in the same tracked `.env`.** It also carried `NEXTAUTH_SECRET` (length 41, `5199942c`) and `USER_HASH_SALT` (length 36, `7d24df90`) from 2025-10-05 to 2026-07-24. They are not SigNoz credentials and are in history only (0 occurrences in the current tree). If either value was ever used outside development, the blast-radius rule rotates it.

**F6 — INFO: parked compose file.** `compose/docker-compose-signoz-simple.yml` publishes ClickHouse `8123`/`9000` on every interface with an empty password. It is not a SigNoz credential and is out of this scope; loopback or delete in a follow-up.

**F7 — INFO: docs follow-ups (docs lane).** `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md` offers `docker compose up -d` as an alternative to `start-signoz.ps1`; on a clean clone that now needs the helper first. `docs/BossCat/SIGNOZ_BEST_PRACTICES.md:63` and `scripts/emit-synthetic-span.ts:18` refer to a `.env.template` that does not exist. The retired, dispatch-only `bosscat-gate-bot-native.yml` and `signoz-automation-fresh.yml` would need `SIGNOZ_JWT_SECRET` if dispatched (CI/ops lane).

**Merge order.** #909 and #910 are independent: they touch different hunks of `security/remediate-secrets.ps1`. Merge #911 before #912. This PR can merge at any time. F2 can only start after #910.

**Proposed `BOSSCAT_LOG.md` line (docs-lane companion, not applied by this PR):**

`- <ts>Z — **[SIGNOZ CREDENTIALS OUT OF THE PUBLIC TREE]** #909–#913, ECRR_SIGNOZ_CREDENTIALS_IN_TREE_20261104.md: 48 lines / 41 files / 7 values (five SigNoz API keys, the JWT signing default — live via the tracked .env 2025-10-05→2026-07-24 — and its prefix) removed by lane; compose now fails closed without SIGNOZ_JWT_SECRET and binds SigNoz to 127.0.0.1; start-signoz.ps1 generates the secret; history not rewritten (budget spent; refs/pull keep the values). Open: F1 revoke the keys, F2 rotate the JWT secret, F3 look for use, F4 a scan that can fail — operator. — **Claude (chat/review seat), cloud session**`

## 4. Role

- **Machine operator (`@fubumaki`):** F1 and F2 (revocation, rotation, the host steps), F3, the F4 decision, and every merge. These cannot be delegated: no other seat mints, reads or rotates a credential.
- **Claude (chat/review seat), cloud session:** measured the exposure by fingerprint, wrote #909–#913 and this report, and disclosed §1d. It did not merge, did not touch a host, and did not mint or rotate anything. It handled the already-public values only by program, matching them by fingerprint and never displaying them (§1d is the exception).
- **Kiro{Implementer} / Claude Code (local seat):** no part. F1 and F2 mint and rotate, so no implementer seat runs them.

**Status:** OPEN. Closes when F1 and F2 are recorded as done (an addendum here) and the five PRs are merged. The tree is GREEN at that point by the proof in §2.

## 5. Addendum (2026-11-17): merged; a sixth key; F1 and F2 widened; F4 answered

Filed by Claude Code (local seat), which drove the merges on the operator's explicit go of 2026-11-16. The corrections come from the chat/review seat's review of 2026-11-16 and were re-checked here against files, git history and run logs. No value was read, searched for or displayed: every value is named by `sha256[:8]`, length, path and commit, as above. Nothing above this section is edited.

**Merged.** Squash merges on 2026-11-17, one at a time, each after a branch update on GitHub and fresh checks on the updated head. The `Driving:` comment went on #909 at 00:00:52Z. The commits keep their `Actor:` lines as filed, and each squash body adds the `Driving:` line.

| PR | Merge commit | Merged (UTC) | Note |
| --- | --- | --- | --- |
| #909 | `2c1b9a34` | 00:04:32 | first run of its PowerShell, below |
| #910 | `f64e8b5d` | 00:12:13 | one fix commit by the driver, below |
| #911 | `7238ed5a` | 00:17:01 | redaction inside frozen records: the operator's exception, on the precedent of #643 |
| #913 | `d8dac859` | 00:21:01 | this report, merged as filed; the same exception for the five archived reports |
| #914 | `2e4324a2` | 00:24:37 | the scan that can fail; its report is `ECRR_GITLEAKS_SCAN_CAN_FAIL_20261117.md` |

- **#912 is superseded.** Its tree proof (`ace0ba2a`) was built on `729121a1`, and #914 and the log line move `docs/` again. The cascade's own mirror republish follows in a separate pull request, and #912 is closed after it. That republish cannot exist before this addendum and its log line are on `main`, so its tree proof is recorded in that pull request and not here.
- **§2's end state holds for the tree only after that republish.** By path, line and hunk range, #909 replaced 12 of the 48 lines, #910 14, #911 7 and #913 8. The other 7 are the `CHAR/DOCS/docs` copies of the records #911 redacted, which still carry `c66026b5`, one line each.

**The driver's part.** §4 says the local seat has no part and gives the operator "every merge". That was the position on 2026-11-04. On 2026-11-17 the local seat executed the five merges on the operator's explicit go, and GitHub records them under the operator's account, through which every seat acts. It also wrote these records, and before merging it ran what had never been run: no PowerShell in #909 or #910 had been executed by the authoring sessions or in review. It minted, read and rotated no credential. F1 and F2 stay with the operator.

- #909, at the merged head `6ee36e8c`: the PowerShell parser reports 0 errors in the eight changed `.ps1` files. With `SIGNOZ_API_KEY` and `SIGNOZ_API_TOKEN` removed in a child process, `check-alerts.ps1` stops at line 1, before its request, with "SigNoz API key required: set $env:SIGNOZ_API_KEY (no key is stored in this script)."
- #910: the helper resolved its default `-EnvFile` two directories up, which is `BRAV/.env`, a file Compose never reads. The driver's one fix commit, `df85bcdd`, changes that line to the repository root. The six helper checks then passed in a throwaway clone with dummy values (results in the comment on #910): a 64-hex value is written when none is set, an existing value is left unchanged, and nothing is written when the variable is set in the environment. `docker compose config -q` on the five compose files exits 1 with "required variable SIGNOZ_JWT_SECRET is missing a value" when the variable is absent, and exits 0 with a dummy.

**F1 widened: a sixth API key, and "delete every key".** `.gitleaksignore` (#914) lists a sixth SigNoz API key that §1a does not have: `b4376d4d`, 44 characters, in history only.

- `BRAV/SCPT/secrets/signoz.secrets.ps1:5`, from `3fdbd88d` (2025-10-09) until the file was deleted in `a88e155b` (2025-10-16).
- `docs/BossCat/SHOWTIME_VIEWS_DEPLOYED.md:168`, from `be93df58` (2025-10-08); the file moved to `CHAR/DOCS/docs/BossCat/` in `3891847c` (2025-10-09) and was deleted in `8ba9cbfd` (2026-08-29).
- Neither file is on `main` or on any branch tip. By blob identity, the tip trees of 50 of the 62 tags and of 505 of the 899 pull-request head refs still hold one or both files (measured on 2026-11-17).

F1 therefore reads: delete every API key in SigNoz, including any that is not recognised. Six keys have been public. The replacement stays least-privilege, as F1 says.

**F2 corrected.** F2 says that `git pull` and `start-signoz.ps1` recreate the container "with a fresh value", and that until then the AtLogOn task's `compose up` "fails closed". Neither holds on a host that still holds a value.

- The helper never replaces an existing value. It writes nothing when `SIGNOZ_JWT_SECRET` is set in the process environment (its lines 31 to 34), and it leaves a non-placeholder `.env` line unchanged (lines 46 to 51). Compose prefers the environment over `.env`.
- The logon task (`scripts/windows/ensure-signoz-stack.ps1`) runs `docker compose up -d` and never calls the helper. On a host with a value still set in the environment or in `.env`, the stack starts with the old secret and nothing fails.

So a rotation first clears the old value from every scope and from the `.env` line, and closes every process that inherited it. Only then does `start-signoz.ps1` print "Generated SIGNOZ_JWT_SECRET into ...". If it prints "Nothing written" or "left unchanged", an old value is still set somewhere.

**F4 answered by #914.** The scheduled scan now reads full history with markdown in scope, and a fixture harness proves on every run that the config can fail (`ECRR_GITLEAKS_SCAN_CAN_FAIL_20261117.md`). Option (b) is not taken. `BRAV/SCPT/security/pre-commit-hook.sh` greps the whole working tree, not the staged change, and exits 1 on any match of its name patterns or of a `your-...-here` placeholder. On `main` its name patterns match 56 tracked files and its placeholder check 25, `.env.example` and the compose lines of #910 among them, so the hook would refuse every commit. Nothing calls it today. Its list holds five fingerprints, not the sixth, and its comments call the keys "revoked", which no record supports yet.

**F7, two additions.**

- `README.md:52` still sends a fresh host to `docker compose pull` and `docker compose up`. The review found that both now fail closed without the helper; the driver measured the same refusal with `docker compose config -q` only. The go of 2026-11-16 has a docs-lane follow-up opened for this line and for the briefing line F7 names, so that a fresh host runs `start-signoz.ps1` before any compose command. It merges on its own go.
- The retired, dispatch-only `stress-test-nightly.yml` runs `docker compose up -d` (line 43) and sets no `SIGNOZ_JWT_SECRET`, like the two workflows F7 names. No change to it is planned.

**Ports.** #910 moved only the SigNoz UI and API to loopback: `127.0.0.1:8080:8080` in all five compose files. In the root `docker-compose.yml` the collector's 4317, 4318, 18888 and 18889 are still published on every interface (lines 188 to 191), and so is the demo app's 3001 when its `demo` profile is started (line 232). The four parked files under `compose/` publish further ports the same way. F3's "#910 closes the port to loopback" means 8080.

**Five values that stay in the tree and are in no part of this report.** By `sha8` and length: `0b3dc10f` (56, `BRAV/SCPT/signoz-auth-helpers.ps1:7`), `f0eb808a` (30) and `5aa2092d` (26) in `BRAV/SCPT/agent/staged-failure-drill.ps1` and three alert JSON files under `DELT/CONF/config/`, `8b62e59e` (49, `scripts/legacy/ops/security-remediation-ngrok.ps1:26`) and `ee58f3d0` (29, `.agent/github-integration.ps1:54`). That is 12 lines in 7 files; §3c of the gitleaks report lists them. They are not covered by the go of 2026-11-16. After the rotation sitting the operator says live or dead for each and gives a separate go for changing the lines without displaying them.

**Disclosure: the review's tooling.** From the chat/review seat's runbook of 2026-11-16. Its masking script missed three shapes: a value after the word Bearer, a value passed as a named PowerShell argument, and a quoted literal after `||`. Six review agents saw one or more of three values unmasked in their own tool output inside the cloud container: the old public JWT default (`7b2b10c7`) and the webhook secret and bearer (`f0eb808a`, `5aa2092d`). All three were readable on `main` at the time (2026-11-16). None reached the review seat's conversation, a report or GitHub; that rests on the runbook's statement and cannot be checked from this seat. The script now has a fingerprint deny-list: 8 of 66 known-value occurrences were left readable before, 0 after. Under the blast-radius rule the JWT default already owes its rotation (F2). For the two webhook values the operator's answer becomes "dead, recorded" or "rotated".

**Verdict and status:** unchanged. **RED and OPEN for F1 and F2**: no revocation and no rotation is on record. The next addendum here records the operator's rotation sitting: its date, the comparison results and the Gate Nightly run. F3 stays with the operator.
