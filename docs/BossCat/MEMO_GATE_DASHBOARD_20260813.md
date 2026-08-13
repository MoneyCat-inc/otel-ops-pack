# Decision memo — gate status dashboard: automate or archive

**Date:** 2026-08-13

**Drafted by:** Claude (chat/review seat) for operator decision

**Scope:** Roadmap 2026 H2, Phase 2 — truth in steering documents

**Recommendation:** **Archive.** The automate branch has no data to automate from.

---

## The finding that decides it

Phase 2 offers two options: *"either automate the gate dashboard from real data or convert it to a
dated historical archive with a pointer to the canonical log."*

**There is no real data.** The repo contains exactly one structured gate artefact,
`artifacts/gate-verification-results.json`, and it cannot feed this dashboard:

| Property | Value | Consequence |
|---|---|---|
| Shape | a **single object**, not a series | overwritten each run; no history to render |
| Gate identifier | `"IONA"` — a **lane name** | dashboard uses a `#001`–`#031` ledger; schemes differ |
| Verdict | `"READY"` | one row, not thirty-one |
| Timestamp | **2026-01-23** | the *automation input* is itself seven months stale |

No gate-history ledger exists anywhere in the repo. The `#001`–`#031` numbering lives only in prose
inside the dashboard itself.

So "automate" is not a matter of wiring up an existing feed. It means **designing a gate ledger that
has never existed and backfilling thirty-one historical gates out of prose**, then keeping it
current. That is building a new steering surface, in a phase whose stated purpose is making existing
surfaces truthful — and the roadmap's non-goals rule out new gate frameworks.

## State of the document

| Measure | Value |
|---|---|
| Length | 1,120 lines |
| Frozen at | Gate #031 |
| Latest date referenced | **2025-11-01** — over nine months old |
| Last content change | none; the 2026-06-26 commit was a reference update |
| Dead internal links | **23** |

The 23 dead links point at files removed by the Pack 3B splits and the 2025 audit —
`IONA_ERRORS.md`, `BossCat/TODO.md`, `docs/GATE_024_APPROVAL.md` and others. They surfaced when a
one-character fix pulled the file into lychee for the first time in #466, which is itself the
tell: nothing has read this document closely enough to notice, for nine months.

## Why archiving is the honest option

The dashboard is not wrong in the way a stale README is wrong. It is an accurate record of gates
`#001`–`#031` as they stood in November 2025. What is false is only its **framing as current
status** — the title says "status", and the reader assumes now.

Archiving keeps everything of value and removes the single false claim. Automating would discard a
truthful historical record in order to rebuild a live one from data that does not exist.

There is also already a canonical live surface: `docs/BossCat/BOSSCAT_LOG.md` carries the one-liner
per change, is genuinely current, and is where every recent gate outcome actually landed.

## Recommendation

Convert to a dated historical archive:

1. Retitle to make the freeze explicit — e.g. `GATE_STATUS_DASHBOARD (ARCHIVED 2025-11-01)`, with a
   header stating it is a snapshot of gates #001–#031 and is not maintained.
2. Point forward: a single line directing readers to `docs/BossCat/BOSSCAT_LOG.md` as the canonical
   current log, and to `CHAR/ECRR/ECRR_REPORTS/` for per-change evidence.
3. Leave the 23 dead links **as they are**, and say so in the header. They are accurate references
   to documents that existed when the snapshot was taken; repairing them would falsify the record,
   the same argument that spared the 314 historical `rtifacts/` strings in #466.
4. Move it under an archive path if the docs tree has one, so its status is legible from the
   location rather than only the title.

Cost: one docs PR, no new machinery, no data model to invent.

**If the operator prefers automate**, the first deliverable is not a dashboard but a decision about
what a "gate" is in the current four-seat model, and whether a numbered ledger still earns its
keep now that ECRRs carry per-change evidence. That question belongs in Phase 4 alongside the
purpose question, not here.
