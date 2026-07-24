# BRIEFING — Audit Remediation Pack 2 (Steps 5–7)

**Repo:** MoneyCat-inc/otel-ops-pack  
**Branch:** `audit-pack-2` off main (after Pack 1 PR merges)  
**Method:** ECRR per task. Each task = separate commit. Evidence lines noted per task.  
**Do not** touch `.git` history in this pack — filter-repo is Pack 3, gated on Task 6 completing.

**Ordering (hard):** Task **5A** must land before Task **5B**. Deleting the nested tree first is a
regression trap — the next scheduled archiver run will recreate `docs/BossCat/BossCat/`.

---

## DECISIONS

| ID | Status | Resolution |
|----|--------|------------|
| **D1** | **RESOLVED** | `docker-compose-optimized.yml` is the de facto canonical SigNoz stack (operator/ref counts beat plain `docker-compose.yml`). **Action in Task 7B:** rename `-optimized` → `docker-compose.yml`; move current default `docker-compose.yml` to `compose/legacy.yml` (or delete if superseded); update all references. Park `.viz` / `.gpu` in `compose/` unrenamed — they leave with the viz-engine repo split. |
| **D2** | **RESOLVED** | Secret name: `EVIDENCE_REPO_TOKEN`. Repo `MoneyCat-inc/otel-ops-evidence` (private) created. Fine-grained PAT: resource owner MoneyCat-inc, repo access **otel-ops-evidence only**, Contents R/W, 90-day expiry (log rotation date in BOSSCAT_LOG when provisioned). Archiver fails loud if secret missing (no continue-on-error). **STOP for live archiver** until secret is added under that exact name. |
| **D3** | **OPEN** | Run hash comparison of `CHAR/DOCS/docs/` vs `docs/`. Pure mirror → delete. Diverged → STOP, list paths in PR; do not delete. |

### Standing rule (gate definitions) — from Pack 1 retrospective

**Gate-definition changes land as standalone PRs evaluated under the old rules.** Do not ship a guard/budget/schema change in the same PR it unblocks. Pack 1’s GR-02 `workflows.json` LOC exclude was accepted as a one-off (documented on #350) because `registry-guard` / `registry-drift-check` still own the registry on their own lane — but it is not the pattern going forward.

---

## Task 5A — Fix run-archiver path-doubling bug

**Symptom:** `docs/BossCat/BossCat/run-reports/` exists (7,227 files) — the archive tree
copied into itself. Root cause is a relative output path resolved from the wrong CWD in
the archiver automation.

**Examine:**
1. Inspect `.github/workflows/run-archiver.yml`, `run-archiver-backfill.yml`,
   `run-rotation.yml`, and any script they invoke (likely under `BRAV/SCPT/` or `scripts/`).
2. Find where the output dir is built. Look for `docs/BossCat` concatenated onto a path
   that already ends in `docs/BossCat` (e.g. script `cd`s into the target then joins the
   full relative path again).

**Clean:**
3. Make the output path absolute from `$GITHUB_WORKSPACE` (or repo root), not CWD-relative.
4. Add a guard before write: if resolved path matches `*/BossCat/BossCat/*`, fail loudly.

**Report:** Note the exact line(s) changed and the faulty path expression in the commit body.
**Role:** Cursor implements; BossCat gate verifies no new nested dir appears on next
scheduled archiver run.

**Commit:** `fix(archiver): resolve output path from repo root; guard against nested BossCat/BossCat`

## Task 5B — Delete the nested duplicate tree

**Precondition:** 5A merged or in same branch (never delete before the writer is fixed —
it will regenerate).

1. Verify duplication before deleting: spot-check 10 files in
   `docs/BossCat/BossCat/run-reports/` against same-named files in
   `docs/BossCat/run-reports/` (hash compare). Record result.
2. `git rm -r docs/BossCat/BossCat/`
3. Also check `CHAR/DOCS/docs/` — it mirrors parts of `docs/`. Hash-compare a sample.
   If confirmed duplicate: delete. If it diverged: **DECISION D3** — STOP, list diverging files in the PR; do not delete.

**Commit:** `chore: remove nested docs/BossCat/BossCat duplicate tree (N files)`

---

## Task 6 — Extract run-report archive out of the working tree

**Scope:** `docs/BossCat/run-reports/` = 25,468 files (12,682 badge SVGs, 12,783 run MDs).

**Target state:**
- New repo `MoneyCat-inc/otel-ops-evidence` (private is fine) receives the full
  `run-reports/` tree, preserving directory structure. Plain copy, no history needed.
- Main repo keeps ONLY: monthly rollups (the `bosscat-monthly-evidence-rollup.yml`
  outputs) + a `docs/BossCat/run-reports/README.md` pointing at the evidence repo.
- Badges: keep only the latest badge per lane if anything in `docs/` embeds them;
  grep `docs/**/*.html` and `*.md` for `run-reports/badges/` references first and
  rewrite those links to the evidence repo raw URLs or drop them.

**Steps:**
1. Grep for inbound references to `run-reports/` across the repo (workflows, HTML
   dashboards, status pages, REFERENCES_MAP.md). List them. Rewrite each.
2. Copy tree to evidence repo, push, verify file count matches (25,468).
3. `git rm -r` the tree from main repo, leaving rollups + pointer README.
4. Update the archiver workflows (from 5A) to push new reports to the evidence repo
   (**DECISION D2** — deploy key or fine-grained PAT; flag to Fae which secret is needed; do NOT create/guess secrets).
5. Same treatment for `.backup.20250929-*` files under `CHAR/ECRR/ECRR_REPORTS/` and
   `windows/otelcol/*.backup-*`: delete outright, they are stale editor backups, not
   evidence. Count them in the commit message.

**Commits:**
- `docs: rewrite run-report references to evidence repo`
- `chore: extract run-reports archive to otel-ops-evidence (25,468 files)`
- `ci(archiver): publish new run reports to evidence repo`
- `chore: delete committed .backup.* files (N files)`

**Note:** clone size will NOT shrink until Pack 3 (filter-repo). Expected working-tree
reduction: ~33k files. State both numbers in the PR.

---

## Task 7 — Root sweep + compose canonicalization

### 7A Root evidence MDs
- **Also (from #352 follow-through, one pass):** (1) Restore `https://hub.resonai.uk` when live — README currently points at `docs/index.html` with a Pack2/7A TODO (stronger than a silent ignore). (2) Rule-scope the three whole-file `markdownlint-disable`s together — `README.md` (highest priority: HN/first-reader surface), `docs/runbooks/windows-collector.md`, `docs/BossCat/BOSSCAT_LOG.md` — replace blankets with specific `MD0xx` lists so new lint debt cannot accumulate silently.
- 127 evidence/session MDs at root (`GATE_*`, `BOSSCAT_*`, `SESSION_*`, `AMBER_*`,
  `COLLECTOR_5317_*`, etc.). Move to `docs/gate/archive/` preserving names.
  Use `git mv` so history follows.
- KEEP at root: `README.md`, `AGENTS.md`, `CHANGELOG.md`, `LICENSE`, `SECURITY.md`
  (if present), `CONTRIBUTING.md` (if present).
- Grep for inbound links to each moved file (README, docs hub, REFERENCES_MAP) and fix.
- **Commit:** `docs: move 127 root evidence reports to docs/gate/archive/`

### 7B Compose canonicalization
Current: 7 compose files at root. Target (**D1 RESOLVED**):
- Promote `docker-compose-optimized.yml` → `docker-compose.yml` (canonical SigNoz stack; bare `docker compose up` must run the right stack).
- Move today's default-named `docker-compose.yml` → `compose/legacy.yml` (or delete if superseded).
- Park `docker-compose.viz.yml` / `docker-compose.gpu.yml` in `compose/` **unrenamed** (viz-engine lane; leave with repo split).
- Other variants → `compose/` with a `compose/README.md` table: file → purpose → status (active / experimental / deprecated).
- Grep scripts and workflows for `-f docker-compose` references; update paths (especially the former `-optimized` refs).
- **Commit:** `chore(compose): promote optimized to canonical docker-compose.yml; variants to compose/`

### 7C Historical 5317/5318 scripts (decision pre-made — implement as stated)
- Scripts under `scripts/gate*/` and `scripts/windows/` that hardcode 5317/5318 are
  frozen historical evidence. Do NOT rewrite their logic.
- Add a header comment block to each:
  `# HISTORICAL (Gate-era): ports 5317/5318 predate the 5320/5321 move. Do not use as reference. See windows/otelcol/README.md.`
- EXCEPTION: any such script still invoked by a live workflow or scheduled task must be
  fixed to 5320/5321 instead. Grep `.github/workflows/` for each script name to classify.
  List the classification (frozen vs live) in the PR.
- **Commit:** `docs(scripts): mark gate-era 5317/5318 scripts historical; fix N still-live callers`

---

## Verification gate (whole pack)
- `find . -type f -not -path './.git/*' | wc -l` before/after — expect ~39.8k → ~6.5k.
- No file matches `*/BossCat/BossCat/*`.
- No `.backup.*` files tracked.
- Root `*.md` count ≤ 10.
- Link-check workflow (`link-check.yml`) passes.
- All compose references resolve (`docker compose config -q` on canonical file).



## Protection-fix PRs (before Pack 2 multi-PR stretch)

Standalone gate-def PRs after #353. Shim job names must match branch-protection **check names exactly**:
- Source of truth: **Settings → Branches → required checks list** (what GitHub received), not YAML alone.
- Reported name = job 
ame: (or job id if unnamed) — **not** the workflow 
ame:.
- Matrix jobs: jobname (value).
- Reusable workflow jobs: caller-job / inner-job.
- Copy the decorated form verbatim into the shim; mismatch = path-filter deadlock returns.

## Out of scope (Pack 3)
- `git filter-repo` history purge + LFS for media (`docs/Art/*.mp4`, `CHAR/DOCS/docs/LOGO/`)
- Repo split (viz-engine / scorebot / moneycat site / SOCM out of this repo)
