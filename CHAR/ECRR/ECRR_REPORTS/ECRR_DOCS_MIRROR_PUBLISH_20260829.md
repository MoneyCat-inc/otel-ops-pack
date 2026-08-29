# ECRR — CHAR/DOCS Mirror: Missing Publish Step Built, Mirror Caught Up

**Date**: 2026-08-29
**Actor**: Chat/review seat (Claude Code remote session), on OEM order ("build it here")
**Task**: `CHAR/DOCS/README.md` instructed "edit /docs and run the publish step" — the publish step never existed, so the mirror drifted unconditionally since creation (found in the audit close-out; both seats verified no sync tooling anywhere).

## Examine
- `docs/` (source of truth per AGENTS.md, ratified by ADR-0002): 778 tracked files.
- `CHAR/DOCS/docs/` (mirror): 702 divergent entries vs source at `2f2ec48` — including the WAIVER-OTEL-001/002 guide additions (PR #645) absent from the mirror, and 839 stale files with no source counterpart.
- No script or workflow anywhere referenced a CHAR/DOCS sync; the only mentions were path string literals in two guard scripts.

## Clean
- **`BRAV/SCPT/publish-docs-mirror.ps1`** created: mirrors the *git-tracked* contents of `docs/` into `CHAR/DOCS/docs/` exactly (SHA-256 change detection, deletes removed files, prunes emptied dirs), `-DryRun` preview, `core.quotepath=off` so non-ASCII filenames survive. Hard scope guard: writes only inside `CHAR/DOCS/docs/` — the first-class content at `CHAR/DOCS/` top level (`ADR/`, `policies/`, `runbooks/`, …) is never touched. Manual by design per docs/PURPOSE.md (no new recurring writers).
- **One-time catch-up executed** (same semantics, run via Python in the Linux session since pwsh is unavailable there): copied 680, deleted 839, unchanged 98.
- `CHAR/DOCS/README.md` updated to name the actual command instead of promising nonexistent machinery.

## Report
- **Before**: `diff -rq docs CHAR/DOCS/docs` → 702 lines of divergence.
- **After**: `diff -rq docs CHAR/DOCS/docs` → **0**. The mirror's contract is true for the first time.
- Reproducible check: `pwsh -File BRAV/SCPT/publish-docs-mirror.ps1 -DryRun` on a clean checkout must report 0 copies / 0 deletes.

## Role
Chat/review seat executing an OEM-ordered build; local implementer seat stood down to avoid duplicate work. No credentials, no browser steps. Future cadence: run the publish step whenever `docs/` changes land — or fold it into the per-change checklist at the OEM's discretion.

---

## Addendum (2026-08-29) — operator dry-run investigated; two defects fixed (v2)

The operator's first Windows dry-run reported 200 copies / 3 deletes instead of 0/0. Blob-level comparison (`git ls-files -s` on both trees — platform-independent truth) showed the real state: **all 762 shared paths blob-identical, zero stale mirror files, 16 source files genuinely missing**.

- **Real defect — 16 files silently skipped**: `.gitignore` excludes `*.docx`/`*.pdf` repo-wide; the `docs/BossCat/Research/` binaries are tracked only via historical force-add. The catch-up sync copied them to the mirror worktree (which is why `diff -rq` legitimately verified 0), but `git add -A` skipped them as ignored. Fixed: the 16 force-added; the script now stages its own output with `git add -f` so this cannot recur.
- **False drift — ~200 phantom copies**: every flagged shared path was blob-identical; the mismatch was stale-smudge (worktree files materialized under older line-ending rules vs fresh `eol=lf` checkouts). Raw worktree-byte comparison (`Get-FileHash`) cannot distinguish this from drift. Fixed: the script now compares via `git hash-object` (clean-filtered), which is platform- and checkout-age-independent.

Post-fix parity: 778/778 tracked paths, 0 blob mismatches. Expected operator verification: v2 `-DryRun` reports 0 copies / 0 deletes; if any deletes persist on Windows, capture the paths (suspect Unicode-name edge) and report.
