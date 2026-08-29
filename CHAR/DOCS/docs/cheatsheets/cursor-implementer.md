# Cursor Implementer — Local Ops Run

Run end-to-end local checks, capture screenshots, and write ECRR evidence.

Quick start

- Install deps: `pnpm i`
- Single run (local site):
  - `pnpm ops:cursor:run`
- Multi-iteration (3 runs, 2s delay):
  - `pwsh -File scripts/cursor-implementer-run.ps1 -Site local -Loops 3 -DelaySec 2`

What it does

- Runs gate verification (IONA) and writes `gate-results.json`
- Probes SigNoz UI `/api/v1/health` and collector (13134/healthz or 18888/metrics)
- Captures status page screenshot under `docs/observability/snapshots/`
- Writes dashboard data to `docs/status/tests.json`
- Produces an ECRR report under `CHAR/ECRR/ECRR_REPORTS/`
- Organizes per-run artifacts in `DELT/ARTF/cursor-runs/run_<timestamp>/`

Options

- `-Site <ci|local|prod>` set site context (default: local)
- `-Gate <name>` gate id (default: IONA)
- `-Loops <n>` repeat iterations (default: 1)
- `-DelaySec <n>` seconds between iterations (default: 2)
- `-UseMock` respect mock mode where applicable
- `-EmitSynthetic` attempt trace emission via `pnpm emit`
- `-Strict` flip verdict to NOT_READY on any failure

Outputs

- DELT/ARTF/cursor-runs/run_YYYYMMDD_HHMMSS/iter-XX/
  - gate-results.json, summary.json, status.png, status.json
- docs/status/tests.json: gate dashboard input
- CHAR/ECRR/ECRR_REPORTS/ECRR_CURSOR_RUN_`<timestamp>`.md

Notes

- SigNoz UI must be reachable at `http://127.0.0.1:8080`
- Collector health is probed via host ports 13134 or 18888
- Screenshots are CSP-safe (served from localhost)

