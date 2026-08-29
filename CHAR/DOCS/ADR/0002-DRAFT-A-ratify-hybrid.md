# ADR-0002 (DRAFT A): Ratify the Hybrid Structure

**Date:** 2026-08-29 (draft)
**Status:** DRAFT — one of two alternatives (see `0002-DRAFT-B-reenforce-tetragram.md`).
The OEM adopts exactly one; on adoption it is renamed `0002-…` final and the other draft is deleted.
**Drafted by:** Chat/review seat (proposes, does not decide — `docs/PURPOSE.md` authority model)

---

## Context (shared by both drafts)

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

Both drafts exist because the unrecorded state is the defect; either decision is defensible.

---

## Decision (Draft A)

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

## Enactment (the adoption checklist)

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

- [ ] Guard GREEN on main with file-checking on, and RED on a test PR adding a stray root file
- [ ] `guardrails.yml` required on PRs
- [ ] Zero full `.ps1` bodies under `scripts/` (wrapper rule holds)
- [ ] ADR-0001 header updated; Draft B deleted
