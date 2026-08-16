# ECRR — viz-engine Phase 1 Decision: Cold Archive

**Timestamp:** 2026-08-16T21:10:00Z
**Gate / Site:** viz-engine post-extraction audit / Phase 1 reactivation gate
**Actor:** Claude (chat/review)
**Authority:** BossCat OEM; merge + final-decision authority delegated to Claude by **@fubumaki** this session
**Verdict:** **GREEN** — detachment hygiene merged; Phase 1 decided: **cold archive**

---

## Examine

Audit of `MoneyCat-inc/viz-engine` (2026-08-16), full findings in viz-engine `docs/ROADMAP.md`:

- Detachment from ops-pack verified clean at code level; provenance pointers both
  directions (ops-pack README → repo; repo README → extraction SHA `3105aef3` +
  commit-map in otel-ops-evidence). Extraction SHA verified present in ops-pack history.
- Loose ends found: 4 authoring scripts stranded in ops-pack (dead since #376);
  stale compose README rows.
- **Nightly GPU Smoke failed 23/23 nights since extraction** — hosted
  `windows-latest` has no GPU, no local Triton (:8000/:8003), no `ollama`.
  A gate that cannot pass.
- Repo dormant since extraction day (2026-07-24): no commits, branches, or PRs.
- Audit correction: `LUMI_API_KEY` **is** provisioned (scoped, minted+rotated
  2026-07-25 per `[LUMI ROTATED]`, dry-run 30164377792 non-skip SUCCESS) —
  the original audit note "parked until secret is minted" was stale; only the
  cron unpark remained.

## Clean

1. **viz-engine#1** (merged 2026-08-16T20:54:58Z): rehomed the 4 scripts, parked
   nightly GPU smoke schedule (dispatch-only, reason in workflow header), added
   `docs/ROADMAP.md`.
2. **otel-ops-pack#541** (merged 2026-08-16T20:55:31Z): removed the stranded
   scripts, fixed compose README rows, pointer to new home.
3. **Phase 1 decision — COLD ARCHIVE.** Rationale: active visualizer effort is
   the native MilkDrop3 lane (`bosscat-vizr`); two active visual engines is one
   too many; butterchurn/scorebot authoring has no near-term consumer; both
   schedules parked so carrying cost ≈ 0; reactivation cost = exactly the
   Phase 2 baseline work (playbook retained in ROADMAP Phases 2–5).
4. viz-engine closeout PR: README archive banner + ROADMAP Phase 1 marked
   decided + Lumi-status correction; repo flipped to GitHub **archived**
   (read-only) after merge. Unarchive is a one-click reversal.

## Report

- Coupling after closeout: **provenance pointers only**, no live code coupling
  either direction. Frozen gate-019 evidence retained in ops-pack.
- Artifacts: viz-engine#1, ops-pack#541, viz-engine closeout PR, this ECRR,
  BOSSCAT_LOG one-liner.

## Role (follow-ups)

- **Machine operator (@fubumaki), optional housekeeping:** revoke the OpenAI
  `lumi-vizr` project key — the archived repo has no consumer for
  `LUMI_API_KEY`. Consistent with the post-FG-r2 least-privilege standing rule.
  Re-mint scoped if Phase 4 is ever funded.
- No other maintenance expected. Reactivation path: unarchive repo → ROADMAP
  Phase 2.
