# BRIEFING — Audit Remediation Pack 3 (History + Split)

**Repo:** MoneyCat-inc/otel-ops-pack  
**Prerequisite:** Pack 2 (#357) merged; D2 closed (`EVIDENCE_REPO_TOKEN` FG-r2;
archiver green; closeout on `origin/main` as `c937bd832` — tree-identical to
local `e264960ab`; GitHub rebase-merge rewrote author/committer to
**BossCat OEM Bot** / Cursor machine identity — chat review never appears in
git metadata).

## Strategic decision (filter-repo evidence cost) — LOCKED UP FRONT

History rewrite regenerates every SHA. `BOSSCAT_LOG`, gate evidence, and merged PR
comments cite commit SHAs (`4d7b7ca51`, `708be40`, `c937bd832`, …) that become
dangling after `git filter-repo` + GC. For an auditability-first repo, silent
breakage is self-inflicted damage.

**Required mitigation (do before force-push):**

1. Run `git filter-repo` with commit-map output (default: `.git/filter-repo/commit-map`).
2. Copy that map into **otel-ops-evidence** as a permanent translation table, e.g.
   `docs/filter-repo/commit-map-<UTC-date>.txt` (old SHA → new SHA).
3. Log one `BOSSCAT_LOG` line: rewrite date + evidence-repo path to the map
   (map entry must cover the D2 FG-r2 closeout SHA among others).
4. That converts "history was rewritten" from a trail break into a documented,
   reversible-on-paper event.

## Quiet-repo gate (before rewrite) — LOCKED

`git filter-repo` rewrites the whole object graph, not a branch tip. Any unmerged
lineage becomes an orphaned pre-rewrite history that can never merge cleanly
(every ancestor SHA changes underneath it).

**Do before snapshot / filter-repo:**

1. Land or abandon every unmerged branch worth caring about
   (`audit-pack-2`: tip tree was ≡ main except superseded log → **abandon** after
   D2 closeout on `origin/main`; delete local + remote).
2. Close or merge all open PRs (incl. Dependabot) — no open PR heads into rewrite.
3. Push all remotes you intend to keep; confirm `origin/main` is the sole live tip.
4. Local rollback mirror: `git clone --mirror <origin-url> otel-ops-pack-pre-pack3.git`
   (keep offline; do not push from it except as restore).
5. Pre-log protection lift in `BOSSCAT_LOG` (reason = filter-repo force-push;
   restore step explicit). Lift → force-push → restore immediately.

## Branch-protection bypass (mechanical)

Force-push after filter-repo needs protection temporarily lifted. **Pre-log** that
bypass in `BOSSCAT_LOG` the same way Pack 1 logged `--admin` merges (structural
reason + restore step). Restore protection immediately after.

## Sequence

1. ~~Provision / confirm `EVIDENCE_REPO_TOKEN` + archiver green~~ (D2 closed)
2. ~~Merge Pack 2 (#357)~~
3. Quiet-repo gate (abandon `audit-pack-2`, clear open PRs, remotes pushed)
4. Mirror snapshot (`git clone --mirror` local rollback)
5. filter-repo (media/LFS purge targets from audit) **with commit-map → evidence repo**
6. Force-push (logged bypass) + restore protection
7. **Post-rewrite verification (gate closes on proof):**
   - Confirm commit-map contains `c937bd832` → `<newSHA>`.
   - Confirm `git rev-parse origin/main` (post-push) equals the mapped `<newSHA>`.
   - Confirm mirror clone still resolves `c937bd832` (`git -C <mirror> rev-parse c937bd832`
     and `git -C <mirror> cat-file -t c937bd832` → `commit`).
   - Log one `BOSSCAT_LOG` line: mapped SHA pair + mirror path held.
8. Repo split (viz-engine / scorebot / moneycat site / SOCM) per original audit

## Known gate debt (pre-Pack 3)

Smoke Test (Changed Paths) fails on docs-only PRs: workflow still points at
`docker-compose-signoz.yml`, removed when Pack 2 promoted compose to
`docker-compose.yml` / `compose/*`. Not a flake — environmental path drift.
Fix or path-filter before trusting post-rewrite gate green as proof.

## Out of scope here

Pack 2 verification numbers live on #357 closing comment.
