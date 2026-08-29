# Repository Structure

**Rewritten 2026-08-29** (audit P3, `CHAR/ECRR/ECRR_REPORTS/ECRR_BOSSCAT_AUDIT_DRIFT_20260829.md`).
The previous version of this document, dated 2025-11-01, described the pre-tetragram layout
(`config/`, `scripts/`, `artifacts/`, `docs/` as canonical roots) three weeks *after*
ADR-0001 abolished it — the structure guide and the structure ADR described mutually
exclusive repositories. This version describes what is actually on disk.

> **Status:** the hybrid described here was **ratified by ADR-0002** (2026-08-29,
> `CHAR/DOCS/ADR/0002-ratify-hybrid.md`): planes canonical for implementation, `docs/` as
> documentation source with `CHAR/DOCS/` mirror, `scripts/` wrapper-only, `.kiro/` authorized.
> The structure guard is file-aware, GREEN, and re-enabled on pull requests.

## The four planes (ADR-0001, 2025-10-09)

| Plane | Subdirs (as they exist) | Holds |
|-------|------------------------|-------|
| `ALFA/` | `APPS CORE LIBS OTEL TEST TOOL` | Application plane: app trees, libs, canary emitters, tests (k6/locust/smoke under `ALFA/TEST/`) |
| `BRAV/` | `DOCK INFR SCPT` | Build/automation plane. **`BRAV/SCPT/` is the canonical PowerShell implementation tree** (fork resolution, 2026-08-29) |
| `CHAR/` | `DOCS ECRR EVID PRSV` | Compliance plane: docs mirror, ECRR audit trail (`CHAR/ECRR/ECRR_REPORTS/`), evidence, preservation archive |
| `DELT/` | `ARTF ASST CONF FIXT TMPL` | Data/config plane: artifacts, configs (`DELT/CONF/configs/` is what `docker-compose.yml` mounts), fixtures, templates |

The guard is `BRAV/SCPT/check_guardrails.py` with `BRAV/SCPT/guardrails.json` as its single
source of truth (the script's built-in table is fallback only). As of 2026-08-29 it checks
top-level **files as well as directories**. As of ADR-0002 enactment
(2026-08-29) it is GREEN and runs on every pull request via `guardrails.yml`.

## Legacy roots that remain, and their standing

| Root | Standing |
|------|----------|
| `docs/` | **Source of truth for documentation**; `CHAR/DOCS/` is its read-only mirror. Ratified by ADR-0002. |
| `scripts/` | **Thin operator wrappers only** — every colliding basename delegates to `BRAV/SCPT/`. Node tooling (`.mjs`/`.ts` entry points that package.json calls) is the exception: canonical here. |
| `windows/` | The actual deliverable: canonical Windows collector config (`windows/otelcol/`). |
| `compose/` | Parked compose variants; all require `docker compose --project-directory .. -f compose/<file>` (see `compose/README.md`). Root `docker-compose.yml` is the canonical stack. |
| `.agent/`, `.cursor/`, `.kiro/`, `otel-agent-coordination/` | Agent-seat frameworks. `.kiro/` authorized as seat metadata by ADR-0002. |
| `third_party/` | `third_party/resonai` is a registered but uninitialized submodule. |

## Root files

~150 entries live at the repository root: the canonical stack (`docker-compose.yml`,
`config.yaml`, `signoz-*.{yaml,json}`, `package.json`, tsconfigs, Playwright configs),
tool dotfiles, the Pages site (`index.html`, `portal.html`, `CNAME`, `og/`, `assets/`),
~24 operator `.ps1` scripts, and dated status artifacts. The ADR-0002 triage (2026-08-29)
dispositioned all of them: 7 deleted, 12 rehomed, 79 blessed by name in
`BRAV/SCPT/guardrails.json` — every top-level file is now individually authorized, and the
guard fails on any new stray.

## Where things run from

- **Health checks / monitoring:** `pwsh -File scripts\quick-monitor.ps1` (wrapper → `BRAV/SCPT/`)
- **Gate verification:** `pnpm agent:ready-for-gate` → `scripts/verify-iona-gate.ps1` (wrapper → `BRAV/SCPT/`)
- **Canary emitter:** `BRAV/SCPT/send_synthetic_otel_simple.py` (promoted from the deleted `synthetic/` root)
- **Tests:** `pnpm test` (jest), `pnpm test:pester`, k6 under `ALFA/TEST/load/k6/`
- **Docs site:** `docs/` → published via Pages; navigate from `docs/index.html`
