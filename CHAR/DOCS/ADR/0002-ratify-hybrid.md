# ADR-0002: Ratify the Hybrid Structure

**Date:** 2026-08-29
**Status:** Accepted ✅
**Decision Maker:** BossCat OEM ("adopt Draft A and execute the enactment checklist", 2026-08-29)
**Drafted by:** Chat/review seat; the alternative (re-enforce ADR-0001 in full) was drafted,
considered, and not adopted — its content is preserved in this branch's git history
(`CHAR/DOCS/ADR/0002-DRAFT-B-reenforce-tetragram.md` at `ade4b6e`) and remains adoptable
later if a `docs/PURPOSE.md` trigger justifies the churn.

---

## Context

ADR-0001 (2025-10-09) abolished 17 legacy roots — `scripts/` and `docs/` among them — and made a
CI guardrail a required check. What actually happened since:

- `docs/` returned as the **source of truth** for documentation, with `CHAR/DOCS/` demoted to a
  generated mirror (`AGENTS.md` records this, no ADR does).
- `scripts/` returned and, as of the 2026-08-29 fork resolution, holds **thin operator wrappers**
  delegating to `BRAV/SCPT/` plus canonical node tooling that `package.json` invokes.
- Both enforcement workflows were retired to `workflow_dispatch` on 2026-08-03.
- The guard became file-aware on 2026-08-29 and currently reports: **98 unauthorized top-level
  files and 1 unauthorized directory (`.kiro/`)** — quantified honest RED.
- ADR-0001's success criteria "zero forbidden legacy roots" and "guardrails enforced via CI"
  are no longer true, and no decision record says why.

Two drafts existed because the unrecorded state was the defect; either decision was defensible.
The OEM adopted this one.

---

## Decision

**Ratify the hybrid as the intended structure.** The tetragram remains canonical for
implementation, evidence, and configuration; a small, named set of legacy roots is ratified as
the operator/publishing surface:

| Root | Ratified role |
|------|---------------|
| `ALFA/ BRAV/ CHAR/ DELT/` | Canonical planes. `BRAV/SCPT/` owns every PowerShell implementation. |
| `docs/` | Documentation source of truth; `CHAR/DOCS/` is its read-only mirror (formalizes `AGENTS.md`). |
| `scripts/` | Wrapper-only operator surface + canonical node tooling (`.mjs`/`.ts` entry points package.json calls). A full `.ps1` implementation body appearing here is a violation. |
| `windows/`, `compose/` | Deliverable config and parked compose variants, as documented in `docs/REPOSITORY_STRUCTURE.md`. |
| `.kiro/` | **Authorized**: agent-seat metadata for the permanent Kiro implementer seat (AGENTS.md, 2026-08-14), added to the guard's tool-metadata exemptions beside `.cursor/` and `.agent/`. |

ADR-0001 is marked **superseded in part** (structure intent stands; zero-legacy-roots criterion
and the specific allowlist are replaced by this ADR).

## Enactment (executed 2026-08-29, this branch)

1. **Root-file triage** of the 98 flagged files, each to exactly one of: *bless* (add to
   `allowed_top_level` — canonical stack configs, dotfiles), *rehome* (dated status artifacts →
   `CHAR/PRSV/`, decorative assets → `assets/` or delete, orphan operator `.ps1` → `BRAV/SCPT/`
   with wrappers only where runbooks need them), or *delete*. Triage recorded in an ECRR.
2. Update `guardrails.json` to the post-triage allowlist; add `.kiro` to exemptions.
3. **Re-enable `guardrails.yml` on pull requests** (not scheduled — no new recurring writer,
   consistent with `docs/PURPOSE.md`). The guard must be GREEN on main at re-enable time and
   must stay able to fail.
4. Update ADR-0001 status header; delete Draft B.

## Consequences

- **Positive:** records reality; low migration cost; keeps operator ergonomics (`scripts\…` paths
  in runbooks stay valid); guard becomes enforceable again within days; consistent with
  PURPOSE.md steady-state ("the binding constraint on this estate is attention").
- **Negative:** ratifies two documentation trees (source + mirror) and a wrapper layer — accepted
  complexity, now with a written rule per root instead of drift.
- **Rollback:** adopt Draft B later; nothing here forecloses it.

## Success criteria (must be able to fail)

- [x] Root-file triage executed: 7 deleted, 12 rehomed (3 dated artifacts → `CHAR/PRSV/root-status-artifacts/`, 8 legacy validation scripts → `BRAV/SCPT/`, mascot → `assets/` with its 3 gate references updated), 79 blessed by name
- [x] Guard GREEN with file-checking on (verified on the enacting branch before re-enable)
- [x] `.kiro/` exempted as agent-seat metadata; `guardrails.json` is the guard's single source of truth
- [x] `guardrails.yml` re-enabled on `pull_request` (marking it *required* is a branch-protection setting — operator/admin step in the GitHub UI)
- [x] Zero full `.ps1` bodies under `scripts/` (wrapper rule holds as of the P1-7 fork resolution)
- [x] ADR-0001 header updated; Draft B removed from the tree (preserved in history)
- [x] RED verified: PR #648 (stray `RED_DEMO_STRAY_FILE.txt`) was blocked by a Repository Structure Compliance **failure** as a required check ([run 33254203928](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/33254203928/job/99104976407), 2026-08-29) and closed unmerged; the GREEN half was demonstrated on PR #647. All success criteria met.
