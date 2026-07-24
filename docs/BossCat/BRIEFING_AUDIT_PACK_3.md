# BRIEFING — Audit Remediation Pack 3 (History + Split)

**Repo:** MoneyCat-inc/otel-ops-pack  
**Prerequisite:** Pack 2 (#357) merged; `EVIDENCE_REPO_TOKEN` provisioned; archiver green once.

## Strategic decision (filter-repo evidence cost) — LOCKED UP FRONT

History rewrite regenerates every SHA. `BOSSCAT_LOG`, gate evidence, and merged PR
comments cite commit SHAs (`4d7b7ca51`, `708be40`, …) that become dangling after
`git filter-repo` + GC. For an auditability-first repo, silent breakage is
self-inflicted damage.

**Required mitigation (do before force-push):**
1. Run `git filter-repo` with commit-map output (default: `.git/filter-repo/commit-map`).
2. Copy that map into **otel-ops-evidence** as a permanent translation table, e.g.
   `docs/filter-repo/commit-map-<UTC-date>.txt` (old SHA → new SHA).
3. Log one `BOSSCAT_LOG` line: rewrite date + evidence-repo path to the map.
4. That converts "history was rewritten" from a trail break into a documented,
   reversible-on-paper event.

## Branch-protection bypass (mechanical)

Force-push after filter-repo needs protection temporarily lifted. **Pre-log** that
bypass in `BOSSCAT_LOG` the same way Pack 1 logged `--admin` merges (structural
reason + restore step). Restore protection immediately after.

## Sequence
1. Provision / confirm `EVIDENCE_REPO_TOKEN` + archiver green
2. Merge Pack 2 (#357)
3. filter-repo (media/LFS purge targets from audit) **with commit-map → evidence repo**
4. Force-push (logged bypass) + restore protection
5. Repo split (viz-engine / scorebot / moneycat site / SOCM) per original audit

## Out of scope here
Pack 2 verification numbers live on #357 closing comment.
