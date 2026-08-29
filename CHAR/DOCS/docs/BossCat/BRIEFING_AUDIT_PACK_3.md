# BRIEFING — Audit Remediation Pack 3 (History + Split)

**Repo:** MoneyCat-inc/otel-ops-pack  
**Prerequisite:** Pack 2 (#357) merged; D2 closed (`EVIDENCE_REPO_TOKEN` FG-r2;
archiver green; closeout on `origin/main` as `c937bd832` — tree-identical to
local `e264960ab`; GitHub rebase-merge rewrote author/committer to
**BossCat OEM Bot** / Cursor machine identity — chat review never appears in
git metadata). Pre-rewrite: Pack 2 7B compose-path regression fixed (#360 —
gates → canonical `docker-compose.yml`; parked signoz variant not CI-tested);
shim contract re-audited (#361 — #356 holds; zero shim reintro; U+2022 poller
gotcha documented).

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
3. ~~Compose-path Pack 2 7B regression fix (#360)~~ — smoke green; gates use
   canonical `docker-compose.yml`; `demo-app` under `profiles: [demo]`
4. ~~Gate-def contract re-audit (#361)~~ — #356 holds; no shim reintro;
   U+2022 check-context poller gotcha documented
5. ~~Quiet-repo gate~~ (0 open PRs; 68 stale remote branches pruned after mirror)

6. ~~Mirror snapshot~~ (`E:\otel-ops-pack-pre-pack3.git`; main=`c2ff77f3b`; heads/tags match; holds `c937bd832`)

7. ~~filter-repo~~ (purged `docs/Art/*.mp4` + `CHAR/DOCS/docs/LOGO/`; commit-map → evidence `docs/filter-repo/commit-map-20260724.txt`)

8. ~~Force-push~~ (protection deleted briefly → push `978d3f36` → restored; allow_force_pushes=false)

9. ~~**Post-rewrite verification**~~ (map D2 + mirror still holds old SHAs; logged)

10. Repo split (viz-engine / scorebot / moneycat site / SOCM) per original audit

## Out of scope here

Pack 2 verification numbers live on #357 closing comment.
