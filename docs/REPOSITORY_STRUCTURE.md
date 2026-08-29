# Repository Structure

**Rewritten 2026-08-29** (audit P3, `CHAR/ECRR/ECRR_REPORTS/ECRR_BOSSCAT_AUDIT_DRIFT_20260829.md`).
The previous version of this document, dated 2025-11-01, described the pre-tetragram layout
(`config/`, `scripts/`, `artifacts/`, `docs/` as canonical roots) three weeks *after*
ADR-0001 abolished it — the structure guide and the structure ADR described mutually
exclusive repositories. This version describes what is actually on disk.

> **Status caveat:** the repository today is a **hybrid** of the ADR-0001 tetragram and
> curated legacy roots. Whether that hybrid is ratified or rolled back is an open OEM
> decision — see the two ADR-0002 drafts in `CHAR/DOCS/ADR/`. Until one is adopted, this
> document describes, it does not prescribe.

## The four planes (ADR-0001, 2025-10-09)

| Plane | Subdirs (as they exist) | Holds |
|-------|------------------------|-------|
| `ALFA/` | `APPS CORE LIBS OTEL TEST TOOL` | Application plane: app trees, libs, canary emitters, tests (k6/locust/smoke under `ALFA/TEST/`) |
| `BRAV/` | `DOCK INFR SCPT` | Build/automation plane. **`BRAV/SCPT/` is the canonical PowerShell implementation tree** (fork resolution, 2026-08-29) |
| `CHAR/` | `DOCS ECRR EVID PRSV` | Compliance plane: docs mirror, ECRR audit trail (`CHAR/ECRR/ECRR_REPORTS/`), evidence, preservation archive |
| `DELT/` | `ARTF ASST CONF FIXT TMPL` | Data/config plane: artifacts, configs (`DELT/CONF/configs/` is what `docker-compose.yml` mounts), fixtures, templates |

The guard is `BRAV/SCPT/check_guardrails.py` with `BRAV/SCPT/guardrails.json` as its single
source of truth (the script's built-in table is fallback only). As of 2026-08-29 it checks
top-level **files as well as directories**. It is currently RED (unauthorized root files +
`.kiro/`) and is not wired into CI — re-enabling it is the enactment step of whichever
ADR-0002 is adopted.

## Legacy roots that remain, and their standing

| Root | Standing |
|------|----------|
| `docs/` | **Source of truth for documentation** (per `AGENTS.md`); `CHAR/DOCS/` is its read-only mirror. Inverts ADR-0001 — subject to the ADR-0002 call. |
| `scripts/` | **Thin operator wrappers only** — every colliding basename delegates to `BRAV/SCPT/`. Node tooling (`.mjs`/`.ts` entry points that package.json calls) is the exception: canonical here. |
| `windows/` | The actual deliverable: canonical Windows collector config (`windows/otelcol/`). |
| `compose/` | Parked compose variants; all require `docker compose --project-directory .. -f compose/<file>` (see `compose/README.md`). Root `docker-compose.yml` is the canonical stack. |
| `.agent/`, `.cursor/`, `.kiro/`, `otel-agent-coordination/` | Agent-seat frameworks. `.kiro/` is not in the guard allowlist — open OEM decision (ADR-0002). |
| `third_party/` | `third_party/resonai` is a registered but uninitialized submodule. |

## Root files

~150 entries live at the repository root: the canonical stack (`docker-compose.yml`,
`config.yaml`, `signoz-*.{yaml,json}`, `package.json`, tsconfigs, Playwright configs),
tool dotfiles, the Pages site (`index.html`, `portal.html`, `CNAME`, `og/`, `assets/`),
~24 operator `.ps1` scripts, and dated status artifacts. The file-aware guard now counts
98 of them as outside the allowlist; disposition (bless, rehome, or delete per file) is
ADR-0002 enactment work, not something this document decides.

## Where things run from

- **Health checks / monitoring:** `pwsh -File scripts\quick-monitor.ps1` (wrapper → `BRAV/SCPT/`)
- **Gate verification:** `pnpm agent:ready-for-gate` → `scripts/verify-iona-gate.ps1` (wrapper → `BRAV/SCPT/`)
- **Canary emitter:** `BRAV/SCPT/send_synthetic_otel_simple.py` (promoted from the deleted `synthetic/` root)
- **Tests:** `pnpm test` (jest), `pnpm test:pester`, k6 under `ALFA/TEST/load/k6/`
- **Docs site:** `docs/` → published via Pages; navigate from `docs/index.html`
