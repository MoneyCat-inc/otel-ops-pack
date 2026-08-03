# otel-ops-pack — Roadmap 2026 H2

**Drafted:** 2026-08-03 by Claude (chat/review seat) for operator review

**Supersedes:** `roadmap.json` (last updated 2025-10-01, tracks pre-split Resonai product
milestones — to be retired in Phase 2)

**Landing path:** docs-lane PR via Cursor{Implementer}; this file is a draft and carries no
authority until merged

**Method:** every phase closes with an ECRR report and an operator-approved gate; lane discipline
applies (docs / code / CI never mixed)

---

## Guiding verdict

The post-June-2026 operating model — lean evidence-first ECRRs, operator-gated milestones, one
deliberate change at a time — is correct. This roadmap does not restructure the project. It
subtracts legacy machinery, forces one deferred architectural decision, and then answers the
purpose question the infrastructure has outgrown.

**Ordering rationale:** Phase 0 is pure risk-removal and unblocks everything (a clean working
tree). Phase 1 is the only open architectural contradiction. Phase 2 makes the repo's story match
its state. Phase 3 completes an in-flight commitment. Phase 4 is deliberately last: deciding what
the stack observes next deserves a clean, truthful repo underneath it.

---

## Phase 0 — Stop the self-inflicted drift (target: mid-Aug 2026)

**Problem:** A Windows scheduled task runs `parallel-agent-orchestrator.ps1` with 48 concurrent
agents on a 30-minute repeat, writing ~1,800 compliance JSONs/day. `artifacts/` holds ~13,700
files; `git status` times out. The repo is regrowing the disease the 2025 audit cured
(39,839 → 6,739 files).

**Work (lane: CI/ops):**

- Unregister the scaled-scheduler tasks (`scripts/setup-scaled-scheduler.ps1` family) and the 30s
  watchdog spawned at startup. Machine operator action — requires the keyboard.
- Archive `artifacts/ecrr-compliance-check-*.json` (13,685 files) to `otel-ops-evidence` under the
  existing retention policy (90-day raw, permanent monthly rollups); delete from working tree.
- Audit the 43 scheduled workflows (of 78 total); target ≤ 12 survivors. Each survivor gets a
  one-line justification in the workflow file header.
- Disable or fix the ECRR compliance engine: thresholds are currently 0 (`passed: true` is
  unconditional). Either give it real thresholds and a real consumer, or retire it.

**Exit criteria:** `git status` completes in seconds; artifacts/ ≤ 200 files; scheduled-task
inventory documented in an ECRR; no recurring writer left running against the working tree.

---

## Phase 1 — The Windows collector decision (target: end of Aug 2026)

**Problem:** Gate #026A (Oct 2025) declared the Windows collector intentionally bypassed — Docker
collectors carry telemetry. Yet it is pinned at v0.104.0 (July 2024; upstream is v0.157.0), and
continues to absorb investment: the Aug 2 repair session, the new watchdog, and the clean-host E2E
gate all center on it. The Nov 2025 Codex review flagged this; it has been unresolved for nine
months.

**Work (standalone gate — gate-definition change rules apply, evaluated under old rules, never
bundled with implementation):**

- Write a one-page decision memo: keep-as-first-class vs. retire. Chat/review seat can draft;
  operator decides.
- **If keep:** upgrade 0.104.0 → current, re-run clean-host E2E, update runbook version notes (the
  0.104.0 syntax caveats likely change).
- **If retire:** delete the service install path, watchdog, runbook, and repair surface; clean-host
  E2E simplifies to Docker-only and should get faster than 7.5 min.

**Exit criteria:** exactly one of the two branches executed to completion; no component that is
simultaneously deprecated and load-bearing.

---

## Phase 2 — Truth in steering documents (target: mid-Sep 2026)

**Problem:** The steering surfaces describe a project that no longer exists: `roadmap.json`
(Oct 2025, pre-split product milestones), `docs/GATE_STATUS_DASHBOARD.md` (frozen at Gate #031,
Nov 2025), `docs/BossCat/CHARTER.md` (agent hierarchy — IONA, QA Scribe, Codex Cloud — predating
the four-seat model), and AGENTS.md remnants (Patreon/Ko-fi/Bluesky upkeep belonging to the
split-out SOCM repo).

**Work (lane: docs):**

- Retire `roadmap.json`; this document (once merged) becomes the roadmap of record.
- Rewrite CHARTER to match the actual seat model: chat/review, Cursor{Implementer},
  Kiro{Implementer} (pending Phase 3 verdict), machine operator @fubumaki.
- Either automate the gate dashboard from real data or convert it to a dated historical archive
  with a pointer to the canonical log.
- Move social/monetization upkeep references to the SOCM repo; AGENTS.md keeps only what this repo
  owns.
- Fix or retire the `rtifacts/` evidence references (broken path in ~300 normalization addenda);
  bless the lean 2026 ECRR format as the template and archive the 2025 shell reports.

**Exit criteria:** a newcomer reading AGENTS.md + this roadmap + the latest ECRR gets an accurate
picture with zero contradictions; grep for `rtifacts/` returns nothing.

---

## Phase 3 — Kiro pilot completion & seat verdict (target: Oct 2026)

**State:** Examine complete (0.04 credits, abort threshold pinned at 500.69), Clean bootstrap
landed (#399). Ecosystem bet validated — AWS has made Kiro its flagship as Q Developer sunsets
(EOL Apr 2027).

**Work:**

- Complete Clean → Report → Role per the briefing: scheduled clean-host E2E automation as the
  pilot deliverable.
- Verdict gate: convert `Kiro{Implementer}` from provisional to permanent, or close the seat.
  Criteria set *before* the report is read: delivery within credit budget, no guardrail
  violations, evidence quality on par with Cursor lane.
- **Hard deadline inside this phase:** `EVIDENCE_REPO_TOKEN` expires 2026-10-22. Rotation is a
  machine-operator action; the armed amber workflow must be verified green after rotation. Do not
  let the pilot narrative crowd this out.

**Exit criteria:** pilot ECRR filed with an unambiguous seat verdict; token rotated with evidence;
clean-host E2E running on schedule without operator babysitting.

---

## Phase 4 — Purpose: what does this stack observe? (target: Nov 2026)

**Problem:** The original subject — Resonai, a browser-local PWA with no backend — emits no server
telemetry. The stack currently observes its own demo app. The infrastructure has outgrown its
subject; this is the real "where is it going" question, deferred until the repo underneath is
clean and truthful.

**Work (decision phase — chat/review seat drafts options, operator decides):**

- Candidate subjects to evaluate honestly, including costs of each:
  1. **Instrument a real workload** — any MoneyCat service with actual traffic (moneycat-site,
     scorebot, future backend work).
  2. **Productize the pack itself** — the 7.5-min time-to-first-trace Windows/SigNoz onboarding is
     the genuinely distinctive asset; polish as an installable/showcase artifact for others.
  3. **Deliberate steady-state** — declare the stack reference infrastructure, minimize upkeep
     (quarterly upgrade + prune cadence), and redirect energy to product repos.
- Write `docs/PURPOSE.md` recording the choice and its rejection reasons. One page. This becomes
  the test for every future gate: does the work serve the declared subject?

**Exit criteria:** PURPOSE.md merged; the next three proposed gates each cite it.

---

## Standing cadence (from Phase 0 onward)

- **Quarterly:** evidence-repo prune (age from filename timestamp, not mtime); dependency/stack
  upgrade check (SigNoz current as of v0.135.1, 2026-08-03).
- **Monthly:** evidence rollup to `otel-ops-evidence`.
- **Per change:** lean-format ECRR — quantified before/after, honest verdict, no checkbox
  apparatus.
- **Never:** a new recurring writer against the working tree without an owner, a review date, and
  a kill switch.

---

## Explicit non-goals for 2026 H2

- No new lanes, agents, or seats beyond the Kiro verdict.
- No new gate frameworks, compliance engines, or report-normalization campaigns.
- No monorepo re-expansion: social, viz, scoring, and site work stay in their split repos.
- No history rewrites — the one-per-lifetime `git filter-repo` budget remains spent.
