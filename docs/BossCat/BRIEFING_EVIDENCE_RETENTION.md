# Briefing: Evidence-repo retention policy

**Authority:** BossCat OEM / oversight seat (post–Pack 3B board)  
**Owner:** Cursor{Implementer}  
**Secret:** `EVIDENCE_REPO_TOKEN` (ops-pack → `MoneyCat-inc/otel-ops-evidence`)  
**Status:** ACTIVE

---

## Problem

Pack 2 Task 6 moved ~25k run reports out of ops-pack into private
`MoneyCat-inc/otel-ops-evidence`. The archiver
(`.github/workflows/run-archiver.yml`) still appends forever. The
33k-file pressure did not die — it **moved**. Without a rotation rule
on the evidence repo, we rebuild today's problem in the sibling.

Ops-pack already caps GitHub Actions UI runs (~100) and keeps monthly
rollups under `CHAR/PRSV/evidence-archives/`. Evidence-repo **raw**
reports had no prune.

---

## Policy

| Tier | Keep | Location |
|------|------|----------|
| Raw run reports | **90 days** | `otel-ops-evidence` → `docs/BossCat/run-reports/` (incl. `archived/`, `badges/`) |
| Monthly rollups | **permanent** | Ops-pack only: `bosscat-monthly-evidence-rollup.yml` → `CHAR/PRSV/evidence-archives/` |
| Prune cadence | **quarterly** + `workflow_dispatch` | `.github/workflows/evidence-retention-prune.yml` |

`workflow_dispatch` defaults to **dry_run=true**. Scheduled quarterly runs prune live (`dry_run=false`).

---

## Age derivation (required — never mtime)

**Classic bug:** `actions/checkout` sets filesystem mtimes to checkout
time. A prune that uses `LastWriteTime` / `mtime` deletes **nothing**
forever while reporting green.

**Rules (hard):**

1. Prefer a **filename / path stamp**:
   - Basename contains `YYYYMMDD` → that calendar day (UTC midnight).
   - Path matches `.../archived/YYYY/MM/...` → first day of that month (UTC).
2. Else fallback: `git log -1 --format=%ct -- <path>` (last commit touch).
3. **Never** use `LastWriteTime`, `mtime`, or any working-tree filesystem clock.

Dry-run and live manifests **must** include per file:

- `path`
- `derived_date` (ISO date)
- `date_source` ∈ {`filename`, `git-log`}
- `age_days`

First dispatch proves derivation via `date_source` breakdown before any
real delete.

---

## Scope & permanent whitelist

**Prune root:** `docs/BossCat/run-reports/` only.

Pack 3 commit-map (`docs/filter-repo/commit-map-20260724.txt`) lives
**outside** `run-reports/` — structurally unreachable. Keep an explicit
permanent whitelist as defense-in-depth:

- `docs/BossCat/run-reports/INDEX.jsonl`
- `docs/BossCat/run-reports/LATEST.md`
- `docs/BossCat/run-reports/.gitkeep`
- `docs/BossCat/run-reports/archived/.gitkeep`
- Any path matching `**/filter-repo/**` or `**/commit-map*`

**Workflow assertion:** if any would-delete path is outside
`docs/BossCat/run-reports/`, **fail loud** (exit non-zero). Scope bug
must not become quiet deletion.

Never touch ops-pack `CHAR/PRSV/evidence-archives/` (different repo /
path; out of scope of the evidence checkout).

---

## Git history growth (accepted)

Pruned blobs remain in `otel-ops-evidence` git history. Private
archive; slow growth expected. Someday-answer: periodic `git gc` /
re-clone. **No second rewrite budget** on the archive in this delivery.

---

## Implementation

| Piece | Path |
|-------|------|
| Prune workflow | `.github/workflows/evidence-retention-prune.yml` |
| Prune script | `BRAV/SCPT/evidence-retention/prune.mjs` |
| FG PAT amber | `.github/workflows/evidence-pat-rotation-reminder.yml` (`EXPIRES_ON=2026-10-22`) |
| Pointer README | `docs/BossCat/run-reports/README.md` |

Shipped code: PR #381. This briefing / pointer / log / ECRR: docs follow-up.

---

## Exit criteria / closeout

1. Briefing + pointer README merged.
2. Dry-run dispatch: would-delete counts + `date_source` breakdown in
   ECRR (`filename` vs `git-log`).
3. `BOSSCAT_LOG`: `[EVIDENCE RETENTION]` + `[FG PAT AMBER]` + `[LUMI AWAITING MINT]`.
4. Real prune (`dry_run=false`) only after dry-run looks sane (optional
   follow-up; not required to close this briefing).

**Actor:** Cursor{Implementer}
