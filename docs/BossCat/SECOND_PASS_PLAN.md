<!-- markdownlint-disable MD013 MD034 -->
# Second Pass Plan

**otel-ops-pack** · drafted 2026-08-15 · grounded against `origin/main` @ `4469d10de` · authority: BossCat OEM  
**Executor:** Cursor{Implementer}  
**Status:** Wave 0 decisions **APPROVED** 2026-08-15 (OEM recommendations affirmed)

| Metric | Value |
|--------|-------|
| markdownlint errors | 10,718 across 370 live docs files |
| Root scripts, zero code/CI refs | 16 / 39 (docs-only) |
| `.git` pack | ~725 MB history (working tree ~3.4 MB tracked binaries; local `size-pack` ~584 MB @ execute) |
| Retired workflows still dispatchable | 3 |
| Files hardcoding OTLP ports | ~70 |

---

## WAVE 0 — Decisions (BossCat)

Three policy calls. Waves 1–3 are delegable after these.

### D1 — The 725 MB history · risk: high · gates Wave 3

**Options:** (a) `git-filter-repo` + coordinated force-push; (b) leave history, document `git clone --filter=blob:none`; (c) nothing.

**Decision: (b).** Document partial clone for newcomers. Revisit (a) only with a declared freeze and every implementer seat notified. See [PARTIAL_CLONE.md](./PARTIAL_CLONE.md).

### D2 — ECRR continuation-marker policy · risk: low · unblocks MissingFourSection

**Options:** (a) honor marker only when named parent exists and contains `## Examine`; (b) always require four sections in-file; (c) status quo.

**Decision: (a).** Processor honors `<!-- continuation of <parent>.md … -->` only when the parent file exists beside the report and itself contains an Examine header (lean or numbered). The check can still fail.

### D3 — Retired workflows: fix or delete · risk: low · 3 files

**Targets:** `gate-verify.yml`, `bosscat-regression-matrix.yml`, `nightly-reference-map.yml` (retired 2026-08-03, `workflow_dispatch` retained).

**Decision: delete.** Headers already designate git history as the restore path. Closes the dead `otlp_ports` contract without building a producer for a retired consumer.

---

## WAVE 1 — Quick wins (one PR each)

| ID | Item | Lane | Done when |
|----|------|------|-----------|
| Q1 | Rename `docs/BossCat/REFERENCE_MAP.md` → `ARCHITECTURE_MAP.md` | docs | `map:generate --strict` exits 0; no link regressions |
| Q2 | Invert `!artifacts/**/*.json` to allowlist | gitignore | allowlisted trackable; novel names ignored; tracked JSON unaffected |
| Q3 | Root de-clutter phase two (16 zero-ref scripts → `scripts/legacy/`) | code + docs pair | root ~125; `git grep` authority; run-cards still resolve |
| Q4 | Repair or retire `.agent/test-conflict-resolution.ps1` | code | AST 0 errors, or file out of live tree |
| Q5 | Clear TS 5.0/7.0 `baseUrl` deprecation (TS5101) | code | `tsc --noEmit` exits 0 on clean main |

## WAVE 2 — Measured burn-downs

Each B-item starts with a **measurement commit**, then batches to lane budgets.

| ID | Item | Lane | Done when |
|----|------|------|-----------|
| B1 | Docs lint debt (archive dated session reports, then `--fix` live remainder) | docs | touching live docs no longer trips GR-03 on pre-existing debt; archives byte-identical |
| B2 | External link rot (lychee full-scope, then fix/annotate) | docs | zero unannotated 404s in live docs |
| B3 | Ports: one config source + convert consumers | code | `git grep -E '\b532[01]\b'` on converted files = source + tests only |
| B4 | PSScriptAnalyzer / AST sweep (`BRAV/SCPT`, `scripts/`) | code | 0 parse errors live; PSSA count recorded |

## WAVE 3 — Weight (gated on D1)

With D1 = (b): one docs surface ([PARTIAL_CLONE.md](./PARTIAL_CLONE.md)). `CHAR/EVID` stays keep-all; guard future accumulation. No history rewrite without freeze.

---

## Operating rules (from pass one)

1. `git grep <ref>` is completeness authority (`rg` from `.` misses dot-dirs; `--hidden` still defers to `.gitignore`).
2. Every touched gate must be shown to **pass and fail** before merge (probe both directions in the PR body).
3. Archives stay as filed. Corrections are addenda. Migration prose is never rewritten into new port numbers.
4. Probes never use real filenames; never run in a tree holding uncommitted operator work — use a worktree.
5. Delta-apply onto moved files. If main advanced, port the diff; never overwrite.
6. A PR isn’t delivered until `gh pr checks` says so — a cancelled run is not a failure; find the run for the current head SHA.
7. Prior “fixed” claims are unverified. Measure on current main before scoping.

## Sequencing

| Order | Item | Blocker |
|-------|------|---------|
| 0 | D1–D3 | — (done 2026-08-15) |
| 1 | Q1, Q2, Q4, Q5 parallel | none |
| 1 | Q3 code + docs pair | none |
| 2 | B1–B4 | measurement commit each |
| 3 | Weight / partial-clone docs | D1 (satisfied by (b)) |

Every number above was measured against `origin/main` @ `4469d10de` on 2026-08-15. B-items re-measure before scoping.
