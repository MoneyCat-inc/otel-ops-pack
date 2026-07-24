<!-- markdownlint-disable MD013 MD022 MD032 MD058 -->
# ECRR — Pack 3B closeout (audit arc gate)

**Archive note:** filed under `docs/BossCat/` so this closeout rides the docs lane (CHAR disposition remains parked).


**Date:** 2026-07-24  
**Actor:** Cursor Agent (BossCat OEM authority)  
**Repo tip:** `cda689bf` (post-#377 main)  
**Role:** Report — pack-level verification after four Remove PRs

## Examine

| Checkpoint | Value |
|---|---|
| Briefing baseline `3105aef3` | 6990 tracked files |
| Pre-SOCM (parent #366) | **6991** |
| Post-moneycat HEAD | **6739** |
| Net delta (four lanes) | **−252** |

Per-lane `git ls-tree -r` tallies:

| Lane | Remove PR | Merge SHA | Before → After | Δ files |
|---|---|---|---|---|
| SOCM | [#366](https://github.com/MoneyCat-inc/otel-ops-pack/pull/366) | `92633410` | 6991 → 6870 | −121 |
| scorebot | [#373](https://github.com/MoneyCat-inc/otel-ops-pack/pull/373) | `a5d7c563` | 6870 → 6865 | −5 |
| viz | [#376](https://github.com/MoneyCat-inc/otel-ops-pack/pull/376) | `17e22a1e` | 6865 → 6755 | −110 |
| moneycat | [#377](https://github.com/MoneyCat-inc/otel-ops-pack/pull/377) | `cda689bf` | 6755 → 6739 | −16 |

Note: briefing expected ~7k → ~6.5k. Landing at **6739** is consistent — viz media was already purged from ops-pack history (mirror-only extract), so Remove PR LOC dwarfed file-count Δ.

## Clean — zero tracked lane paths

| Pattern | Tracked hits |
|---|---|
| `viz-engine-*` | **0** |
| `presets-projectm` | **0** |
| `scorebot/` | **0** |
| `moneycat/` | **0** |
| `docs/socm` | **0** |
| `docs/social` | **0** |
| `docs/bsky plan` | **0** |
| `scripts/social` | **0** |

Ops-pack still holds BossCat Bluesky *maintenance* docs (`docs/BossCat/BSKY_*`) — intentional; not the SOCM lane.

## Workflows

| Metric | Value |
|---|---|
| Pre-SOCM workflow YAMLs | **79** |
| Post-#377 workflow YAMLs | **76** |
| `docs/status/workflows.json` `total` | **76** (regenerated on Removes) |

Delta −3: `social_post.yml` (SOCM), `lumi-vizr-lane.yml` + `nightly-gpu-smoke.yml` (viz). `deploy-moneycat.yml` **rewritten** hub-only (kept). Briefing guessed 78→~72; recorded truth is 79→76.

## Lychee / rewritten pointers

| Remove PR | `lychee` job |
|---|---|
| #366 SOCM | green on Remove |
| #373 scorebot | green on Remove |
| #376 viz | green on Remove |
| #377 moneycat | **pass** — [run 30115977687](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/30115977687) |

## README Related repos

Four lines, four repos (ops-pack `README.md`):

- [socm](https://github.com/MoneyCat-inc/socm)
- [scorebot](https://github.com/MoneyCat-inc/scorebot)
- [viz-engine](https://github.com/MoneyCat-inc/viz-engine)
- [moneycat-site](https://github.com/MoneyCat-inc/moneycat-site)

## Sibling provenance

Each new repo README states extracted-from `@ 3105aef3` + commit-map in **otel-ops-evidence** `docs/filter-repo/commit-map-20260724.txt`. LICENSE present (MIT).

| Repo | Provenance |
|---|---|
| socm | present at extract |
| scorebot | `65a545e` (docs commit) |
| viz-engine | tidy Provenance line on main |
| moneycat-site | tidy Provenance line on main |

## Parked (explicit owners — not this pack)

| Item | Owner |
|---|---|
| `CHAR/` disposition | Fae / separate decision |
| 26 CHAR/docs hash mismatches | Fae (parked 15-min review) |
| `DELT/` (150 tracked) / `ALFA/` (119 tracked) lane-shaped contents | Flagged; decide later — not in Pack 3B mandate |
| `LUMI_API_KEY` on viz-engine | Fae mint scoped secret → re-enable Lumi cron |

## Credential hygiene (standing)

Master credentials only in human-owned browser tabs. Automation receives scoped, revocable keys only. Default on future STOPs: mint fresh + revoke anything that touched local automation.

## Role

**Pack 3B + audit arc verification gate: CLOSED** at ops-pack `@ cda689bf` with receipts above.

## Follow-up (non-blocking)

| Item | When |
|---|---|
| Rename `.github/workflows/deploy-moneycat.yml` → `deploy-hub.yml` (hub-only job; name still says moneycat) | Ride next docs-lane PR — not a standalone PR |
