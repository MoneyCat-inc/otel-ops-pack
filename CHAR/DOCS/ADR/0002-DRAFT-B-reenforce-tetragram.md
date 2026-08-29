# ADR-0002 (DRAFT B): Re-enforce the ADR-0001 Tetragram

**Date:** 2026-08-29 (draft)
**Status:** DRAFT — one of two alternatives (see `0002-DRAFT-A-ratify-hybrid.md`).
The OEM adopts exactly one; on adoption it is renamed `0002-…` final and the other draft is deleted.
**Drafted by:** Chat/review seat (proposes, does not decide — `docs/PURPOSE.md` authority model)

---

## Context

Identical to Draft A's context section (read it there): the hybrid drifted in unrecorded,
enforcement is off, and the file-aware guard reports 98 unauthorized root files plus `.kiro/`.

---

## Decision (Draft B)

**Restore ADR-0001 in full.** Zero legacy roots is re-adopted as the standing criterion; the
2026 reversals are treated as drift to be migrated back, not ratified.

| Item | Disposition |
|------|-------------|
| `docs/` | Migrates into `CHAR/DOCS/` as the **source** (mirror direction flips back). GitHub Pages build repointed to publish from `CHAR/DOCS/`. `docs/` root removed and returns to `forbidden_legacy_roots`. |
| `scripts/` | Dissolved. Wrappers deleted; every caller (`package.json`, runbooks, `.cursorrules`, README quick commands, `ci-verify.ps1` host paths) repointed to `BRAV/SCPT/…` directly. Node tooling moves to `ALFA/TOOL/` or `BRAV/SCPT/` with package.json updated. |
| Root files (98 flagged) | Rehomed by class: stack configs → `DELT/CONF/` with `docker-compose.yml` and collector mounts updated; operator `.ps1` → `BRAV/SCPT/`; site files (`index.html`, `CNAME`, `og/`, `assets/`…) → `CHAR/DOCS/` publish tree or split out to `moneycat-site`; dated status artifacts → `CHAR/PRSV/`; dotfiles that tools require at root are the only blessed exceptions. |
| `.kiro/` | Relocated where tooling permits, else added to hidden-tool exemptions (like `.cursor/`) with a written justification — not the allowlist. |
| Guard | `guardrails.yml` re-enabled as a required PR check once migration lands, file-checking on, allowlist reduced to the tetragram planes + tool-required root files. |

## Enactment (phased, each phase its own ECRR + green gate)

1. **Phase R.1 — scripts/**: repoint all callers, delete wrappers, drop the root. (Smallest;
   proves the loop.)
2. **Phase R.2 — root files**: rehome by class; every path consumer updated and validated
   (`docker compose config`, gate workflows, Pages build).
3. **Phase R.3 — docs/**: flip the mirror; repoint Pages; largest blast radius (778 files,
   every inbound link, the live site).
4. Re-enable the guard as required; update ADR-0001 status to "re-affirmed"; delete Draft A.

## Consequences

- **Positive:** one structure, one rule, no mirror ambiguity; ADR-0001's criteria become true
  again instead of historical.
- **Negative (substantial, stated honestly):** multi-hundred-file migration touching the live
  Pages site, every operator runbook, and host-side absolute paths (`C:\otel\scripts\…`) on the
  machine that runs the clean-host gate — the one thing `docs/PURPOSE.md` says must keep
  working. This is exactly the class of churn PURPOSE.md's steady-state exists to prevent, and
  adopting Draft B implicitly amends that posture. The 2025 lesson (Windows junctions corrupting
  a bulk `git mv`) applies to any redo.
- **Risk controls:** phase gates; no phase merges red; clean-host E2E drill re-run after R.2 and
  R.3 before the standing proof is considered valid.

## Success criteria (must be able to fail)

- [ ] `scripts/` and `docs/` absent from the tree and present in `forbidden_legacy_roots`
- [ ] Guard GREEN on main, required on PRs, and RED on a test PR re-adding a legacy root
- [ ] Clean-host E2E gate GREEN on the migrated layout
- [ ] Pages site serves correctly from the new source
- [ ] ADR-0001 re-affirmed; Draft A deleted
