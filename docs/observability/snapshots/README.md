# Observability Snapshots

This folder stores visual evidence artifacts generated locally and in CI.

Contents
- Status screenshots: `status-YYYYMMDDTHHMM.png` and metadata JSON
- Dashboard exports (if enabled by automation)

Generate a status page screenshot
- Prereqs: `pnpm i` (Playwright is a devDependency)
- Command: `pnpm export:status:screenshot`
- Output: `docs/observability/snapshots/status-*.png` + `status-*.json`

Notes
- A lightweight static server is started on `127.0.0.1:8787` to serve `docs/` so CSP stays self-only.
- Data sources: `DELT/ARTF/gate-verification-results.json` or `docs/status/tests.json`.
- Intended for local-first evidence. Safe to publish as build artifacts as well.
