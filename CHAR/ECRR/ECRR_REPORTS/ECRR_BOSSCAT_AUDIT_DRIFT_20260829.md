# ECRR — Full-Project Audit: Internals, Exponent Telemetry, Structural Drift

**Date**: 2026-08-29
**Actor**: Chat/review seat (Claude Code remote session, branch `claude/bosscat-audit-drift-ohc8yb`)
**Role**: Auditor — proposes, does not decide (per `docs/PURPOSE.md` authority model)
**Task**: OEM-requested audit: (1) internal component consistency after additions/removals, (2) exponent pipeline vs. reality, (3) drift from founding documents.
**Verdict**: ⚠️ Governance/evidence lanes healthy; executable layer substantially broken; exponent telemetry disconnected and non-measuring; founding architecture reversed without record.

---

## 1. Examine

### 1a. Internals — component consistency

The executable layer is unverified by CI (no workflow runs `pnpm build`/`test`/`lint` or `docker compose config`), which is why none of the following has surfaced:

- **Root `docker-compose.yml`** mounts `./configs/prometheus/prometheus.yml` and `./configs/dashboards` — `configs/` moved to `DELT/CONF/configs/`; Docker silently creates empty dirs. `demo-app` and the three `gpu-*` services reference images (`otel-otel-demo-app`, `otel-gpu-sidecar`) this file never builds; the gpu services also lost their `command:` lines (present only in `compose/legacy.yml`).
- **All four `compose/*.yml` files are unrunnable as written**: relative paths (`./clickhouse-cluster-config.xml`, `./signoz-collector-config.yaml`, `Dockerfile.demo`, `./sidecars/`, `./triton-models/`) resolve against `compose/`, where none of those files exist. Nothing in the repo invokes them with `--project-directory ..`.
- **`package.json`**: `dev/build/start/lint` (Next.js — no `app/`/`pages/` at root; moved to `ALFA/APPS/app`, `ALFA/CORE/pages`), `db:*` (Prisma — schema at `ALFA/LIBS/prisma/`), `gate:perf` (`tests/perf/gate.js` — no `tests/` dir), `emit:enhanced`, `security:scan|monitor|cleanup` (missing scripts) are all broken. `pnpm-workspace.yaml` lists non-existent `resonai-mock`. `AGENTS.md` cites a `pnpm agent:setup` script that does not exist.
- **Playwright/TS configs**: 3 of 4 Playwright configs point at moved/deleted test dirs; `tsconfig.error-watcher.json` points at pre-reorg `scripts/agent/error-watcher/`.
- **Workflows (63)**: broken paths in `gate-site-evidence.yml` (`tests/perf/gate.js`, live on dispatch/push), `signoz-automation-fresh.yml`, `bosscat-diagnostic.yml` (all six k6/locust paths pre-reorg; soft-fails so it "diagnoses nothing"), `multi-app-ci.yml` (missing requirements.txt masked by `|| true`; retirement rationale contradicts tree state). `docs/status/workflows.json` says 62 workflows, disk has 63 (`clean-host-freshness.yml` unregistered) — the exact drift `registry-guard.yml` exists to fail on.
- **`scripts/` vs `BRAV/SCPT/` have diverged**: 28+ colliding filenames, at least 6 with different content (`verify-iona-gate.ps1` 11.9KB vs 9.4KB; `diagnostic.sh` 197B vs 12.7KB), no declared source of truth. `.pre-commit-config.yaml` lints only `scripts/`, so the 758-file `BRAV/SCPT/` tree is never linted pre-commit.
- **`bosscat-svc2-api/` + `bosscat-svc3-worker/` are dead code**: no build, no compose, no CI; their own gate specs (`scripts/gate029/specs/*.json`) point `appPath` at `dotnet-test-app`. No `svc1` exists anywhere in the repo — grep returns zero hits.
- **CODEOWNERS** reserves six NATO subdirs that were never created (`ALFA/INST`, `BRAV/CICD`, `BRAV/HOOK`, `CHAR/AUDT`, `CHAR/REPO`, `DELT/LOAD`) and three non-existent files.
- **Root orphans**: `canary.yml`, `ci-cd-pipeline.yml`, `ci-cd-pipeline-ecrr.yml` (workflows outside `.github/workflows/` — never run), `vercel.json` (**invalid JSON** — `#` comments before `{`; targets moved `app/api/**`), `signoz-scan-critical-high.json` (220KB Trivy *log* misnamed `.json`), duplicate gate schemas (root vs `schema/` — diverged), `tests.schema.json` superseded, `third_party/resonai` submodule uninitialized yet cited by `AGENTS.md`. 23 of 24 root `.ps1` files unreferenced by any workflow.
- **Working-tree corruption**: 4 files under `CHAR/PRSV/archive/` carried bare `\r\r\r` runs that CRLF normalization rewrites on every checkout — every fresh clone showed a permanently dirty tree. (Fixed this session, see §2.)

### 1b. Exponents — are we seeing what is really happening?

**No. The exponent telemetry does not reflect reality, and in its current wiring cannot.**

- **Transport does not exist**: the estimators write `hurst_estimate` as a JSON field to relative `artifacts/*.json`; the collector (`config.yaml:33-39`) tails only `C:/logs/**/*.log`. The Hurst value physically cannot enter the pipeline.
- **The alert can never fire**: `signoz-hurst-exponent-drift-alert.json` queries `message contains "hurst_estimate" AND log.file.path contains "canary-pattern-results.json"` — data that never enters SigNoz. Its `threshold: 0.7` compares a *record count*, not the exponent value. Its JSON is not in the schema the repo's own installer (`bosscat-create-signoz-alerts.ps1`) speaks; the 8 alerts CI installs do not include it. `import-hurst-drift-alert.ps1` prints manual instructions and never imports.
- **The estimator is not a Hurst estimator**: all three copies (`canary-pattern-drills.ps1:180-191`, `investigate-poisson-anomaly.ps1:57-79`, `enhanced-statistical-validation.ps1:41-52`) compute single-scale `log(R/S)/log(n)` — no multi-window regression, no detrending, no small-sample correction. At n≈30-60 (below the repo's own stated 200-500 minimum) the standard error spans the entire 0.3-0.7 decision band.
- **Inputs are fabricated**: every exponent is computed on inter-arrivals the script generated from `System.Random` moments earlier — it measures the .NET PRNG, not the system. The "Steady" pattern's H=0.5 is a divide-by-zero fallback constant (inter-arrival is the literal `10`, StdDev=0) reported back as a confirmed prediction. The "enhanced" validator labels one exponential distribution as three patterns (all λ=0.1; committed evidence shows CV≈1 for all three, including "Steady" and "Pareto"). The bootstrap CI resamples with replacement, destroying the temporal ordering Hurst measures. `investigate-poisson-anomaly.ps1:277-330` hardcodes its findings text regardless of computed numbers.
- **Nothing runs**: no CI, no compose service; `setup-daily-pattern-drills.ps1:6` points at pre-reorg `scripts\canary-pattern-drills.ps1` and exits 1 before registering the task. Last evidence artifacts: 2025-10-01, containing unexpanded PowerShell variables.
- **The one live panel is mislabeled**: "Fractal Drift Detection" (`deploy-fractal-drift-dashboard.ps1:119-145`) plots coefficient of variation of `otelcol_exporter_queue_size` — real, measured, useful, and not fractal. The name is the only connection to the Hurst work.
- **Adjacent placeholder**: `scripts/rsi-extract.mjs:57` ships `convergence_rate_7d: 0.93 // TODO`; published `docs/status/*.json` carry the static value since 2025-10-13.

### 1c. Drift from founding documents

Original mission (`.agent/policies.md`, `.agent/runbook.md`): a small Windows OTel collector pack feeding Event Logs into self-hosted SigNoz. ADR-0001 (2025-10-09) imposed the ALFA/BRAV/CHAR/DELT tetragram explicitly to eliminate 17 legacy roots including `scripts/` and `docs/`, enforced by CI guardrail.

- **The tetragram was reversed in place, with no ADR**: `scripts/` and `docs/` are back in `BRAV/SCPT/guardrails.json` `allowed_top_level`. `CHAR/DOCS/ADR/` contains exactly one ADR — the reversal of the founding decision is unrecorded.
- **The guardrail cannot see the largest violation**: `check_guardrails.py:80-85` iterates *directories only*; over half the allowlist entries are files it can never evaluate. 130 loose root files, ~112 outside the allowlist, all invisible. This is the exact failure mode PURPOSE.md's rule names: *"A check must be able to both pass and fail."*
- **The guardrail is RED right now and nothing runs it**: `python3 BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json` exits 1 (`synthetic/` — an explicitly forbidden legacy root, re-created; `.kiro/` — unauthorized). Both enforcement workflows RETIRED 2026-08-03 to `workflow_dispatch`.
- **Evidence-to-product inversion**: `CHAR/EVID` 2,318 files + `CHAR/ECRR` 601 files vs. the actual deliverable `windows/otelcol/` — 2 files. Compliance plane outweighs application plane ~30:1.
- **Out-of-scope subsystems still live at root** despite Pack 3B split and `AGENTS.md`'s own out-of-scope declaration: web hub (`index.html`, `portal.html`, `patreon-cover-banner.html`, `CNAME`, `og/`, deployed by `deploy-moneycat.yml`), GPU/Triton/CUDA residue (`DELT/CONF/triton-models/`, 4 root gpu scripts, `Dockerfile.gpu-base`), viz/socm remnants across 9+ `docs/` subdirs.
- **Documentation contradicts itself**: `docs/REPOSITORY_STRUCTURE.md` (dated *after* ADR-0001) documents the abolished pre-tetragram layout with zero tetragram mentions. README says 386 ECRR reports, AGENTS.md says 385; actual: **409** (410 including this one). PURPOSE.md says 11 scheduled workflows; actual: 12 (the 12th, `clean-host-freshness.yml`, does carry the required written justification — the count is stale, the process held).
- **Six AGENTS.md copies**, three ECRR locations, three IONA_ERRORS copies, two CODEOWNERS, four agent frameworks (`.agent`, `.cursor`, `.kiro`, `otel-agent-coordination`), container definitions in four places.
- Mitigating: PURPOSE.md (2026-08-14) already names steady-state drift as the standing risk, and the actor-seat governance rules themselves are *not* violated — the drift is structural, not procedural.

---

## 2. Clean

Scope of this session was **audit, not remediation** — chat/review seat proposes, does not decide. One mechanical fix was applied because it blocked a clean working tree on every fresh clone:

- `c63ef1f` — renormalized bare-CR runs in 4 `CHAR/PRSV/archive/` reports (whitespace-only, 4 files / 5 lines; within GR-02 budget). Fresh clones now check out clean.

All other findings are left for OEM disposition (see §3 recommendations).

---

## 3. Report — ranked dispositions proposed

**P0 — truthfulness (the PURPOSE.md rule):**
1. Retire or rewrite the Hurst/fractal lane honestly: delete `signoz-hurst-exponent-drift-alert.json`, the three copy-pasted estimators, and `import-hurst-drift-alert.ps1`, or rebuild on real measured inter-arrivals with a multi-window estimator and a working transport. Rename the "Fractal Drift Detection" panel to what it is (queue-size CV).
2. Fix or remove `bosscat-diagnostic.yml` (reports "missing" for every path and passes) and the `|| true` mask in `multi-app-ci.yml` — both are checks that cannot fail.
3. Replace the `convergence_rate_7d` placeholder or remove the metric from published status JSON.

**P1 — live breakage:**
4. Repoint root `docker-compose.yml` `./configs/` → `DELT/CONF/configs/`; restore gpu `command:` lines or drop the gpu services; fix or park `compose/*.yml` (add `--project-directory` docs or move configs).
5. Refresh `docs/status/workflows.json` (62→63) before `registry-guard.yml` fails a workflow PR.
6. Fix `gate-site-evidence.yml` k6 path → `ALFA/TEST/load/k6/`.
7. Decide one canonical side of the `scripts/` vs `BRAV/SCPT/` fork (6+ diverged twins) and delete the other; extend pre-commit PSSA to the survivor.

**P2 — dead weight:**
8. Delete: `bosscat-svc2-api/`, `bosscat-svc3-worker/` (gate specs already run dotnet-test-app), root orphan workflows (`canary.yml`, `ci-cd-pipeline*.yml`), invalid `vercel.json`, `signoz-scan-critical-high.json`, duplicate root gate schemas, `requirements-synthetic.txt`/`synthetic/`, `tsconfig.error-watcher.json` or repoint it.
9. Fix broken `package.json` scripts or delete them (Next/Prisma/security:*/gate:perf); drop `resonai-mock` from workspace; fix 3 Playwright configs.
10. CODEOWNERS: remove the six never-created NATO dirs and three phantom files.

**P3 — record-keeping:**
11. Write ADR-0002 recording the tetragram partial reversal (or re-enforce ADR-0001 — either is defensible; the unrecorded state is not).
12. Extend `check_guardrails.py` to files, fix the diverged `guardrails.json` `tetragram_structure` block, and re-enable the guard on PRs — or formally retire ADR-0001.
13. Correct stale counts: README/AGENTS ECRR counts, PURPOSE.md workflow count, `docs/REPOSITORY_STRUCTURE.md` rewrite or deletion.

**Quantified before/after** (this session): dirty-on-clone files 4→0; ECRR reports 409→410; all other counts unchanged — this is an audit artifact, not a remediation.

---

## 4. Role

**Chat/review seat** (Claude Code remote session) acting as **Auditor** under the standing delegation model: this report proposes dispositions and decides none of them. No credentials touched, no browser steps, no secrets referenced by value. Evidence gathered read-only from the working tree at `0a6e222` plus one whitespace-only commit (`c63ef1f`). All checks reproducible:

```bash
python3 BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json  # exits 1
python3 -c "import json; json.load(open('vercel.json'))"                  # fails
grep -rn "svc1" --include="*.yml" --include="*.ps1" --include="*.json" .   # no hits
ls .github/workflows/*.yml | wc -l                                         # 63 vs workflows.json total:62
```

**ECRR Mantra**: *Examine → Clean → Report → Role — every change begins with evidence, removes drift, leaves an artifact, declares its actor.*

---

## Addendum (2026-08-29) — P0 tier executed on OEM order

OEM directed execution of the P0 tier ("start executing the P0 tier"). Applied on this branch:

- **P0-1** (`154114c`): Hurst/fractal lane retired — 13 files deleted (three estimators, the non-importing importer, the alert verifier, the daily-drills orchestration, `signoz-hurst-exponent-drift-alert.json`). All "Fractal Drift" labels over coefficient-of-variation queries renamed honestly: `deploy-fractal-drift-dashboard.ps1` → `deploy-queue-health-dashboard.ps1` (dashboard "Queue Health Monitors", panel "Queue Variability (CV)"), alert "Queue Variance Drift Detected", matching renames in `manual-dashboard-import.ps1`, `deploy-alerts.ps1`, `deploy-alert-thresholds-notifications.ps1`; dead Hurst/pattern query blocks removed from `test-signoz-queries.ps1`. Net −2,139 lines.
- **P0-2** (`2720af5`): `bosscat-diagnostic.yml` repointed to post-reorg paths with fatal repo-side checks (runner-env probes stay informational); `multi-app-ci.yml` `|| true` mask removed, real `ALFA/APPS/sidecars/requirements.txt` created from the sidecars' imports, false retirement rationale corrected.
- **P0-3** (`0b8a11d`): `convergence_rate_7d` placeholder replaced with `null` in `scripts/rsi-extract.mjs` and both published status JSONs; the ICF/RSI panel renders `-` for null.

Validation: both edited workflows parse (PyYAML), both status JSONs parse, `node --check` passes on the extractor, and a repo-wide sweep finds zero remaining live references to any deleted file (historical ECRR/evidence archives intentionally untouched). Budget note: P0-1 exceeds the GR-02 ≤10-file guideline (18 files, overwhelmingly deletions of one dead component); commits are split per item so the OEM can merge separately if lane discipline requires.

Remaining honesty items outside P0 scope, noted for P1+: `bosscat-gate-verify.yml:172` soft-fails the RSI extraction (`|| echo WARNING`), and `docs/status/*.json` still carry other unverified static fields (`self_heals_7d`, `u_turns_7d`, `kb_coverage`).

---

## Addendum (2026-08-29) — P1 tier executed on OEM order

OEM directed P1 execution and made the fork call: **BRAV/SCPT canonical, `scripts/` as thin operator wrappers**. Applied:

- **P1-4/5/6/8/9** (`97037ed`): root compose repointed to `DELT/CONF/configs/`, demo-app given a build stanza, the three unrunnable GPU services dropped (parked copies remain in `compose/docker-compose.unified.yml`); `compose/README.md` documents the `--project-directory` caveat; `workflows.json` registered `clean-host-freshness` (62→63, schema-validated); the deleted `tests/perf/gate.js` repointed to `ALFA/TEST/load/k6/gate-simple.js` in both `gate-site-evidence.yml` and `package.json`; the RSI/ICF `|| echo WARNING` masks removed (step-visible failure, `continue-on-error` keeps auxiliary feeds non-gating; extractor verified passing locally first); the four fabricated status fields with no producer, consumer, or schema (`self_heals_7d`, `u_turns_7d`, `kb_coverage`, `rsi_overhead_pct`) removed from published status JSON.
- **P1-7** (fork resolution): 25 basename collisions audited. Seven `scripts/` files were already house-pattern wrappers. Five consumer-matching or newer `scripts/` bodies promoted into `BRAV/SCPT` (`verify-iona-gate`, `diagnostic-shell-enhanced`, `playwright-dashboard-export`, `update-status-dashboard`, `test-bedrock-connection` — plus `lib/BossCat.Progress.psm1` they import); thirteen `scripts/` duplicates replaced with wrappers. **Carve-out:** node tooling (`.js`/`.ts`) stays canonical in `scripts/` where package.json points — identical BRAV copies deleted; the distinct IONA emitter renamed `BRAV/SCPT/emit-iona-span.ts` to end the basename collision. Pre-commit PSSA extended to `BRAV/SCPT/**/*.ps1`. Every remaining collision is now wrapper→implementation. `verify-integration.ps1` remains a double-wrapper to the root-level body — consolidation deferred to P2 (root orphan sweep).

---

## Addendum (2026-08-29) — P2 tier executed on OEM order

Branch first merged current `origin/main` (`b2f2a79`, waiver guide PR #645) — clean merge. Applied in `afa7cf4` + `537261f` (net −6,069 lines):

- **Deleted** (each reference-swept first): `bosscat-svc2-api/`, `bosscat-svc3-worker/` (nothing builds them; their gate specs run `dotnet-test-app`; no `svc1` exists), the three root-level workflows that never ran (`canary.yml`, `ci-cd-pipeline*.yml`), invalid `vercel.json`, the 220KB Trivy log named `.json`, both diverged root schema duplicates, `tsconfig.error-watcher.json`, `requirements-synthetic.txt`, and `playwright.chromium.config.ts` (MEMX viz-engine residue, zero consumers).
- **Audit correction**: `synthetic/` was **not** dead weight — live `gate-nightly.yml` passes `synthetic/send_synthetic_otel_simple.py` to `verify-pipeline.ps1`, and the `synthetic/` copy was the newer contract version. Resolved by promotion: newer emitter → `BRAV/SCPT/`, four callers repointed (`gate-nightly.yml`, `verifyIngestion.ts`, `bosscat-gate-one-liner.ps1`, the `verify-pipeline.ps1` default), forbidden legacy root then deleted. `schema/gate_verification.schema.json`, also flagged as an orphan in the audit, is consumed by Pester tests and **stays**.
- **Consolidated**: root `verify-integration.ps1` body → `BRAV/SCPT/` (P1 deferral closed); `scripts/` wrapper and bare-path callers repointed; `error-capture.ps1` AdapterPath fixed to the post-reorg error-watcher location.
- **Manifests**: 12 broken package.json scripts removed, `security:cleanup*` repointed to the only remaining copy; `resonai-mock` dropped from the workspace; `playwright.config.ts` → `BRAV/SCPT` with `webServer` removed (`pnpm dev` no longer exists); `playwright.smoke.config.ts` → `ALFA/TEST/unit/smoke`; 11 phantom CODEOWNERS lines removed (six never-created NATO dirs, two wrong ECRR paths, three nonexistent files).
- **Guardrail state**: `check_guardrails.py` violations 2 → 1. The remaining violation is `.kiro/` — an OEM governance decision (authorize in the allowlist or relocate), left for P3 alongside ADR-0002.

Validation: package.json / guardrails.json / pnpm-workspace / gate-nightly all parse; the promoted emitter compiles; a repo-wide sweep shows remaining name-matches only in legacy cleanup/fixer scripts and archives — no live invocations of anything deleted.

---

## Addendum (2026-08-29) — P3 tier executed on OEM order; ADR-0002 drafted both ways

Mechanics applied (direction-independent):

- **Guard is file-aware**: `check_guardrails.py` now scans top-level files against `allowed_top_level` (plus an optional `allowed_top_level_patterns`), and reads the tetragram plane sets from `guardrails.json` (single source of truth; the hardcoded table is fallback only). It reports honestly: **98 unauthorized root files + `.kiro/`** — the violation class that was structurally invisible before. Not wired into CI: re-enabling is the adopted ADR's enactment step.
- **`guardrails.json` matched to reality**: plane subdir sets reduced to what exists (phantoms like `ALFA/INST`, `BRAV/CICD`, `CHAR/AUDT` dropped; real `ALFA/OTEL`, `CHAR/ECRR`, `CHAR/PRSV`, `DELT/ARTF` authorized); 12 Pack 3B ghost allowlist entries pruned (`moneycat`, `scorebot`, `viz-engine-*`, `presets-projectm`, …) — 65 → 53 entries.
- **Stale governance text corrected**: README/AGENTS ECRR counts replaced with count-free references (410+ and how to count); the dead `pnpm agent:setup` citation in AGENTS.md marked; PURPOSE.md workflow count amended in place (11 → 12, noting the addition followed the document's own rule); `docs/REPOSITORY_STRUCTURE.md` rewritten from the abolished 2025 layout to the actual hybrid, with an explicit "describes, does not prescribe" caveat pending ADR-0002.

Decision materials delivered, not decided:

- **`CHAR/DOCS/ADR/0002-DRAFT-A-ratify-hybrid.md`** — ratify the hybrid: planes canonical for implementation, `docs/` ratified as source with mirror, `scripts/` wrapper-only, `.kiro/` authorized; enactment = triage the 98 files, re-enable the guard on PRs. Low cost, consistent with PURPOSE.md steady-state.
- **`CHAR/DOCS/ADR/0002-DRAFT-B-reenforce-tetragram.md`** — restore ADR-0001 in full: dissolve `scripts/`, flip the docs mirror, rehome the root files; phased with clean-host gate re-runs. Honest about the cost: churn of exactly the class PURPOSE.md exists to prevent, touching the live site and the clean-host host paths.
- The OEM adopts exactly one (rename to final, delete the other). Chat/review seat's recommendation, for what it is worth under the authority model: **Draft A** — it records reality, re-arms enforcement within days, and defers Draft B's churn until a PURPOSE.md trigger justifies it.

---

## Addendum (2026-08-29) — ADR-0002 Draft A ADOPTED by OEM; enactment executed

OEM adopted Draft A ("adopt Draft A and execute the enactment checklist"). Enacted on this branch:

**Root-file triage (98 files, every disposition reference-swept first):**
- **Deleted 7** true orphans: `validate-yaml.py`, `yaml-check.py`, `setup_cursor_implementer.sh`, `test-webhook-payload.json`, `queue-steward-dashboard-logs.json`, `patreon-cover-banner.html` (socm residue), `start-signoz.sh` (zero refs; the `.ps1` twin — which the clean-host E2E calls — stays blessed).
- **Rehomed 12**: three dated status artifacts → `CHAR/PRSV/root-status-artifacts/` (index links updated); the eight-file 2025 validation-campaign set (`chaos-drill`, `check-validation-status`, `quick-status-check`, `collect-validation-evidence`, `monitor-ci-background`, `monitor-parallel-validation`, `run-agent`, `test-reviewdog.js`) → `BRAV/SCPT/` with internal cross-refs converted to `$PSScriptRoot`; the mascot JPG → `assets/` with all three gate assertions updated (`bosscat-gate-verify.yml`, `guard-required-files.sh`, BOSS metadata).
- **Blessed 79** by name: tool dotfiles, the canonical stack configs (clickhouse XMLs, signoz collector/alert/dashboard files), the Pages site, and the heavily-wired operator scripts (`canary-test.ps1` 43 refs, `health-check.ps1` 36, `start-signoz.ps1` — called by the clean-host E2E). The evidence-driven call: mass-rehoming the referenced operator surface would have required editing 100+ consumers — Draft B churn under a Draft A adoption — so the working set is ratified in place, each file individually named in the allowlist.

**Governance mechanics:**
- `CHAR/DOCS/ADR/0002-ratify-hybrid.md` finalized (Status: Accepted, OEM decision recorded); both draft files removed from the tree (Draft B preserved at `ade4b6e` in history, adoptable later if a PURPOSE.md trigger fires).
- ADR-0001 header marked superseded-in-part with the precise scope of what stands and what is replaced.
- `.kiro/` exempted as agent-seat metadata; `__pycache__` added to temp exemptions.
- **Guard verified GREEN** (file-checking on, warnings only) *before* re-enabling `guardrails.yml` on `pull_request` — satisfying "must be GREEN at re-enable time". `workflows.json` updated for the trigger change so `registry-guard` stays satisfied.
- `docs/REPOSITORY_STRUCTURE.md` caveat flipped from "describes, does not prescribe" to the ratified state.

**Left for the operator (cannot be done from this seat):** marking `guardrails.yml` *required* in branch protection (GitHub admin UI), and the live RED demonstration — the first PR that adds a stray root file will show the guard failing, completing the last success criterion. Host-side note: any legacy scheduled task calling the rehomed validation scripts by `C:\otel\<name>.ps1` root path needs its path updated or retiring (the AGENTS.md rc=2 legacy-task disposition already tracks that class).


---

## Addendum (2026-08-29) — enactment demos complete; arc closed

- **GREEN demo**: PR #647 (operator's rebased ECRR sync) merged with Repository Structure Compliance passing on its first run as a *required* check.
- **RED demo** (OEM-ordered): PR #648 added one stray root file; the required check **failed** on it ([run 33254203928](https://github.com/MoneyCat-inc/otel-ops-pack/actions/runs/33254203928/job/99104976407)) and blocked the merge; PR closed unmerged, branch deleted.
- Operator follow-ups closed: Repository Structure Compliance added to required checks on `main`; scheduled-task sweep found a single root-path caller (`\otel_canary_10m` → `canary-check-min.ps1`, blessed at root — no change needed).

Every ADR-0002 success criterion is now demonstrated, both halves of "a check must be able to both pass and fail" on real PRs under branch protection. The audit arc — three-stream audit → P0–P3 → ADR-0002 adoption → enactment → verification — is complete.

---

## Addendum (2026-08-29) — CodeQL workflow consolidation (OEM-ordered backlog item)

OEM order: "consolidate the CodeQL workflows down to codeql.yml". Executed:

- **Deleted `.github/workflows/main.yml`** ("CodeQL") and **`.github/workflows/codeql-analysis.yml`** ("CodeQL Analysis"). Both were retired dispatch-only since the 2026-08-03 Phase 0 audit, and both are strict coverage subsets of `codeql.yml` ("CodeQL Advanced": actions + javascript-typescript + python, `security-extended` queries, push/PR/schedule). The only nominal delta — `codeql-analysis.yml` ran `security-and-quality` on javascript — has produced nothing since 2026-08-03 because the workflow could only fire by hand.
- **Registry**: `docs/status/workflows.json` 63 → 61 (two entries removed, `total` updated), mirrored identically to `CHAR/DOCS/docs/status/workflows.json` — registry-guard's deep semantic comparison (names, trigger booleans, total) satisfied without regeneration drift.
- **Branch protection unaffected**: the required "CodeQL" context is app-bound to github-code-scanning (app 57789), fed by `codeql.yml`'s analyses — not by the Actions workflow named "CodeQL" that this deletes (documented in `codeql.yml` and `required-check-shims.yml` headers).
- **Left alone, with reasons**: `security-scan.yml` also carries a CodeQL job but is an already-retired dispatch-only *bundle* (gitleaks + CodeQL + Trivy) whose header names its canonical successors — retiring the file entirely is a separate disposition, not part of this order. `docs/reference/reference-map.json` lists both deleted paths but is a stale generated snapshot (2026-08-15; already lists 11 dead workflows and misses one live) with no CI consumer — its fix is regeneration (`scripts/generate-reference-map.ts`), queued behind this, not a two-row hand edit.

Validation: all remaining workflow YAMLs parse; `workflows.json` validates against `docs/status/workflows.schema.json`; registry name-set equals the on-disk workflow set (61/61); `HEAD:docs` and `HEAD:CHAR/DOCS/docs` remain the same tree.
