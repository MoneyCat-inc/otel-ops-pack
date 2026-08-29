<!-- markdownlint-disable MD013 MD031 MD034 -->
# BRIEFING — Kiro pilot: scheduled clean-host E2E automation

**Authority:** OEM seat (D1–D4 pre-registered below)  
**Owner (brief / PR / ECRR):** Cursor{Implementer}  
**Owner (pilot implementer):** Kiro{Implementer} (provisional — peer seat, no nesting)  
**Owner (auth / mint):** Machine operator  
**Status:** **OEM-APPROVED — awaiting docs-lane merge; Kiro idle until then**  
**Candidate:** Scheduled clean-host E2E automation (Gate #022 follow-on)  
**Promise under test:** One delivery → ECRR verdict: standing seat / stays provisional / exits.

---

## OEM decisions (locked 2026-07-26)

| ID | Decision | Binding detail |
|----|----------|----------------|
| **D1** | **Pilot: approved** | Single delivery only. Closing ECRR renders standing / provisional / exit. No open-ended adoption. |
| **D2** | **Seat: provisional yes** | `Kiro{Implementer} (provisional — pilot-scoped)` in `AGENTS.md`. Same rules as Cursor: scoped creds, machine operator auth, actor per commit, **no nesting** between implementer seats. Tag resolves at pilot ECRR only. |
| **D3** | **H4 port-consistency: in scope, stretch** | Fourth in line. If credit cap threatens, **H4 is the first cut** — recorded here, not decided mid-pilot. |
| **D4** | **Credit cap: ≤50% of one month Pro** | Hard stop at cap; report partial + verdict. **First pilot act after merge:** verify whether hook executions draw from the same credit pool as spec/agent work; number goes in ECRR either way. No spend decisions inside the loop. |

Kiro touches nothing until this briefing (and the provisional seat line) merge through normal gates.

---

## Standing rules (pilot)

| Use Kiro for | Do **not** |
|--------------|------------|
| Spec-shaped feature work | Governance plane (Actions, PR evidence, BOSSCAT_LOG, ECRR authority) |
| Local hooks under Actions | AWS-side CI/CD or second evidence plane |
| Peer implementer seat | Nested Cursor→Kiro implementation chain |
| Spec **projected from** this briefing + `BRIEFING_CLEAN_HOST_E2E.md` | A second canonical spec authored beside briefings |

**Fail closed:** BossCat briefing stays canonical. Kiro `requirements.md` header must cite source path + SHA and state `projection — not canonical`.

---

## Why this item

Already half-specified and measured:

| Artifact | Role |
|----------|------|
| `docs/BossCat/BRIEFING_CLEAN_HOST_E2E.md` | Canonical stranger-path requirements |
| `CLEAN_HOST_E2E_RUN_CARD_20260726.md` + ECRR + `artifacts/clean-host-e2e-20260726.json` | GREEN baseline (7.47 min; `landed_main_sha` `312aff7db`) |

Automation goal: Phase-0 checkpoint → Phases 1–4 on gate clock → timing JSON + ECRR + BOSSCAT_LOG; fail closed on contamination, clock >30 min, or verify ≠ 0.

**Out of scope:** AWS merge gates; replacing `docs_gate`/registry Actions; concurrent Kiro+Cursor edits on one tree.

---

## Loop

```text
Canonical briefing → Kiro spec projection → review approve
  → Kiro implements on feature branch (Actor: Kiro{Implementer})
  → H1–H3 local hooks (H4 stretch) → Cursor PR via existing lanes
  → ECRR: seat verdict + hook credit-pool finding (D4)
```

### Pilot GREEN

- Automation merge-ready via normal PR path  
- Spec cites briefing; no contradictory shalls  
- First-push gates GREEN, or RED only on real defects (not MD013 / GR-02 churn)  
- Evidence + actor trailer; zero AWS evidence plane  
- Explicit standing-seat verdict  

**AMBER:** useful delivery but hooks/spec/cost incomplete — provisional remains.  
**RED:** nesting, second evidence plane, or gate bypass — revoke provisional; Kiro review-only.

---

## Examine → Clean (post-merge, before coding)

1. `kiro-cli whoami`; credit check (`/usage`) — abort if < headroom for one spec cycle under D4  
2. **D4 probe:** do hooks draw from the same Pro pool as agent/spec? Record in ECRR  
3. Snapshot briefing SHAs; feature branch from `origin/main` for Kiro only  
4. Steering bootstrap (Appendix A); hooks H1–H3 (Appendix B); H4 only if cap allows  
5. Spec projection from `BRIEFING_CLEAN_HOST_E2E.md` + automation delta above  

---

## Hooks (shift-left; never replace Actions)

| # | Hook | Trigger | Mirrors | Notes |
|---|------|---------|---------|-------|
| H1 | markdownlint docs | save `docs/**`, `README.md` | GR-03 | `markdownlint-cli2@0.14.0` + `.markdownlint-cli2.yaml` |
| H2 | lane-purity | pre-commit | GR-02 | Fail if staged mixes docs-lane with `CHAR/` / `artifacts/` / code |
| H3 | registry nudge | save `.github/workflows/**` | registry-guard/drift | Regen or fail-closed message |
| H4 | port consistency | save docs/config citing OTLP ports | audit headline | **Stretch; first cut under D4** |

---

## Appendix A — Steering (generated excerpt)

`.kiro/steering/bosscat-governance.md` — regenerate from root `AGENTS.md`; do not hand-edit. Must restate actor seats (incl. provisional Kiro), standing credential rules, GitHub-native evidence plane, lane discipline, briefing-canonical / spec-projection rule. Optional `.kiro/steering/otel-pipeline.md`: ports 5320/5321→4317, UI 8080, collector pin 0.104.0.

## Appendix B — Hook contracts

- **H1:** after write → `npx markdownlint-cli2@0.14.0 --config .markdownlint-cli2.yaml <files>`; no auto-disable.  
- **H2:** staged set mixes `docs/**|README.md` with non-docs → exit ≠0 (“split lanes”). No local `lane:removal` bypass.  
- **H3:** workflow edit → run documented registry regen or fail with nudge.  
- **H4 (stretch):** docs/config port claims vs bound ports (5320/5321 vs 4317/5317 class); drop first if D4 threatened.

## Appendix C — Non-goals

Second governance plane; Cursor→Kiro nesting for pilot impl; CodeCatalyst/Q as merge gates; hand-maintained steering drift; `.kiro/specs/` without briefing parent.

---

## Role / artifacts

| Artifact | Path |
|----------|------|
| This briefing | `docs/BossCat/BRIEFING_KIRO_PILOT_CLEAN_HOST_E2E_AUTOMATION.md` |
| Provisional seat | root `AGENTS.md` (companion PR — out of docs_gate lane) |
| Pilot ECRR | `CHAR/ECRR/ECRR_REPORTS/ECRR_KIRO_PILOT_<YYYYMMDD>.md` |

**Next after both merge:** Cursor confirms gates green → Kiro Examine (incl. D4 credit-pool probe) → Clean bootstrap → implement.
