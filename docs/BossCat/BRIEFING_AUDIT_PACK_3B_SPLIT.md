<!-- markdownlint-disable MD013 MD022 MD032 MD058 -->
# BRIEFING — Pack 3B: Repo Split (four lane manifests)

**Repo:** MoneyCat-inc/otel-ops-pack @ `3105aef3` (post-rewrite main)
**Design (locked):** one rewrite budget spent. Each lane extracts via
`git filter-repo --path …` on a FRESH clone pushed to a new repo; ops-pack side
is a normal `git rm` PR through live gates. No force-push to ops-pack, ever.
**Order:** SOCM → viz-engine → scorebot → moneycat-site.
**Inventory caveat:** path lists below were enumerated on a pre-Pack-2 snapshot.
Cursor MUST re-grep current main before each lane (root MDs moved to
`docs/gate/archive/`, compose variants moved to `compose/`). Treat lists as
seed sets, verify counts in the Examine step.

**Per-lane loop (ECRR, one PR pair per lane):**

1. Examine — re-grep manifest paths on current main; record file counts.
2. Extract — fresh clone → `filter-repo` with the lane's `--path` set →
   push to new repo → CI green THERE before touching ops-pack.
3. Remove — ops-pack PR: `git rm` the remove-set, delete lane workflows,
   add one-line README pointer, rewrite inbound docs-hub links.
4. Report — file counts (extracted = removed), link-check green, gate green.

**Secrets rule (all lanes):** never copy secret VALUES between repos. List the
secret NAMES each lane's workflows reference; Fae provisions them in the new
repo. Extraction clones must be checked for tracked env files before push.

---

## Lane 1 — SOCM  →  new repo `MoneyCat-inc/socm`

Smallest blast radius; carries its own credential surface — do this first.

**Extract set (`--path`):**

- `docs/socm/` (43 files), `docs/social/` (32), `docs/bsky plan/` (10)
- `scripts/social/` (entire dir: skyfeed, browser-login, post-*, deploy-custom-feeds, set-credentials)
- `scripts/monitor-bluesky-metrics.ps1`
- `.github/workflows/social_post.yml`

**Remove-from-ops-pack set:** same paths.

**Workflows:** `social_post.yml` → moves. `hub-smoke.yml` → **leave** (grep hit
is the docs hub, which stays with ops-pack; verify the hit is hub-only).

**Compose / runbooks:** none.

**Scripts classify:**

| Path | Call |
|---|---|
| `scripts/social/**` | move |
| `scripts/monitor-bluesky-metrics.ps1` | move |
| `scripts/hub-smoke-test.ps1` | leave (hub = ops-pack docs infra) |

**Secrets:** enumerate names referenced by `social_post.yml` and
`scripts/social/set-credentials.ps1` (Bluesky app password, any webhook
URLs). STOP and list for Fae; do not proceed to Remove until provisioned.

**Special check:** `.gitignore` entries `.env.socm` / `.env.social` — confirm
no such file is tracked anywhere in history of the extraction clone before
pushing the new repo public/private.

---

## Lane 2 — viz-engine  →  new repo `MoneyCat-inc/viz-engine`

Largest lane. **History source: the E: mirror**, not current origin — the LOGO
and video assets were purged from ops-pack history and only the mirror still
holds them. Extraction clone comes from
`E:\otel-ops-pack-pre-pack3.git` (clone it locally first; NEVER run
filter-repo inside the mirror itself — it is the untouched insurance).

**Extract set (`--path`):**

- `viz-engine-projectm/` (32), `viz-engine-butterchurn/` (9), `viz-engine-projectm-gpu/` (3)
- `presets-projectm/` (20) and all `*.milk` presets (28 — verify locations)
- `docs/milk-v0/` (7)
- `CHAR/DOCS/docs/LOGO/` and `docs/Art/` media (present only in mirror history)
- `scripts/visuals/` (Validate-Preset, build-milk-vendors), `scripts/demo/load-demo-preset.ps1`
- `compose/docker-compose.viz.yml`, `compose/docker-compose.gpu.yml` (current paths post-7B)
- runbooks: `docs/runbooks/audioswitch-cluster.md`, `docs/runbooks/vizr-troubleshooting.md`
- workflows: `lumi-vizr-lane.yml`, `nightly-gpu-smoke.yml`

**Remove-from-ops-pack set:** everything above as it exists on current main
(media already gone from main — nothing to rm there).

**GPU classification — the judgment call of this lane.** GPU appears in two
distinct roles; split accordingly:

| Pattern | Call | Rationale |
|---|---|---|
| `nightly-gpu-smoke.yml`, `verify-gpu-codex.ps1`, `gpu_bench.ts`, `gpu-fix-lane.ps1` | move | viz/render pipeline |
| `gpu-sidecar-*`, `*-gpu-sidecars.*`, `install-ollama-gpu.ps1`, `gpu-watchdog`, `gpu-automated-monitoring`, `setup-gpu-monitoring`, `gpu-signals.ts`, `enhanced-monitoring-with-gpu.ps1`, `import-gpu-dashboard-*` | **leave** | GPU-host *telemetry* — core observability, the ops-pack's actual product |
| anything ambiguous | leave + list in PR for Fae | default to ops-pack; moving is reversible, but a broken monitoring script on a Windows host is not a viz problem |

**Gate workflows referencing viz** (`bosscat-regression-matrix.yml`,
`gate-019-audio-r1-test.yml`, `gate-verify.yml`): **leave the workflows**,
delete/disable only their viz matrix rows or jobs; record which rows were
dropped. `gate-019-audio` is frozen gate evidence — annotate, don't delete.

**Secrets:** enumerate from the two moving workflows (GPU runner labels,
any registry tokens). STOP-list for Fae.

---

## Lane 3 — scorebot  →  new repo `MoneyCat-inc/scorebot`

**Extract set:** `scorebot/` (Dockerfile, requirements.txt, src — 6 files).
**Workflows:** none matched `scorebot` — verify on current main; if truly
none, the new repo needs a minimal CI (lint + docker build) before the
Remove PR, so the lane lands with a gate rather than bare.
**Scripts classify:** grep `scorebot` across `scripts/` + `BRAV/SCPT/` —
expected zero; record the zero.
**Secrets:** expected none; record.

Smallest lane — run it as the template-validation for moneycat.

---

## Lane 4 — moneycat-site  →  new repo `MoneyCat-inc/moneycat-site`

**Extract set:**

- `moneycat/` (site: html/css/js, deployment docs, `verify-deployment.ps1`)
- `og/` (2 files — verify they are the site's OpenGraph assets; if they serve
  the ops-pack README/hub instead, leave)
- `.github/workflows/deploy-moneycat.yml`
- `BRAV/SCPT/add-moneycat-footer.ps1`, `BRAV/SCPT/generate-moneycat-doc.ps1`

**Scripts classify:**

| Path | Call |
|---|---|
| `add-moneycat-footer.ps1`, `generate-moneycat-doc.ps1` | move |
| `signoz-export*.mjs`, `monitor-ci-pipeline.py`, `update-docs-index.ps1`, `run-archiver/**` | leave — grep hits are incidental (footer/branding strings), these are ops-pack tooling |
| `icf-smoke.yml` grep hit | verify; expected leave (ICF is ops-pack filename ratchet) |

**Secrets:** deployment target credentials in `deploy-moneycat.yml`
(hosting token / SSH). STOP-list for Fae.

---

## Pack-level verification gate (after all four Remove PRs merge)

**docs_gate on Remove:** apply label `lane:removal` — gate reports SKIPPED-by-design (not GR-02 FAIL).

- `git ls-files | wc -l` on ops-pack — record before/after per lane and total.
- Zero tracked paths matching: `viz-engine-*`, `presets-projectm`, `scorebot/`,
  `moneycat/`, `docs/socm`, `docs/social`, `docs/bsky plan`, `scripts/social`.
- Workflow count recorded (expect 78 → ~72); `workflows.json` regenerated
  (out of docs lane per #351).
- lychee green — every removed path's inbound link rewritten to its new repo.
- README updated: one "Related repos" block, four pointers, one line each.
- Each new repo: CI green, LICENSE present (MIT to match, unless Fae says
  otherwise per lane), README states provenance ("extracted from
  otel-ops-pack @ 3105aef3, history via filter-repo, commit-map in
  otel-ops-evidence").

## Out of scope

- `CHAR/` disposition (distinct tree; separate decision, not this pack)
- The 26 CHAR/docs hash mismatches (Fae's parked 15-minute review)
- DELT/ / ALFA/ lanes — not in the split mandate; flag contents in the
  final report if they look lane-shaped, decide later
