# ECRR Report — SigNoz UI Map, Drilldown Assets, and Evidence Refresh

Date: 2025-09-22
Actors: Cursor Agent (implementation), fubumaki (approval)
Scope: Add navigational clarity for SigNoz, ship reusable drilldown assets, and refresh ECRR‑01 evidence

## Examine
- SigNoz version: v0.95.0 (`/api/v1/version`)
- Health: `/api/v1/health` returns `{"status":"ok"}`
- Management APIs: `/api/v5/*` require auth and may not be available locally
- Missing quick UI reference and importable drilldown assets

## Clean
- Added SigNoz UI Map
  - `docs/observability/SIGNOZ_UI_MAP.md` — routes, page anatomy, local API behavior, gotchas
  - Linked from `README.md` for discoverability
- Created drilldown assets
  - Saved view: `artifacts/signoz-saved-view-high-severity.json` (ERROR/WARN, 15m, group by service/severity)
  - Alert: `artifacts/signoz-alert-high-severity-service.json` (ERROR > 5 in 5m for `otelcol-contrib`)
  - Quick link: `artifacts/signoz-logs-deeplink.txt`
- Evidence refresh
  - Regenerated ECRR‑01 bundle using `scripts/ecrr/verify-headers.ps1` and `scripts/ecrr/collect-evidence.ps1`
  - Confirmed JSON reports parse; header lines present

## Report
- Files added/updated
  - `docs/observability/SIGNOZ_UI_MAP.md`
  - `README.md` (link to UI map)
  - `artifacts/signoz-saved-view-high-severity.json`
  - `artifacts/signoz-alert-high-severity-service.json`
  - `artifacts/signoz-logs-deeplink.txt`
- How to import
  - View: Logs → Views → Import → select `artifacts/signoz-saved-view-high-severity.json`
  - Alert: Alerts → Create/Import → use `artifacts/signoz-alert-high-severity-service.json` (or recreate via builder)
- Evidence verification snippet
  ```powershell
  pwsh -NoLogo -File scripts/ecrr/verify-headers.ps1 -Url http://localhost:3003 -WriteLog
  pwsh -NoLogo -File scripts/ecrr/collect-evidence.ps1 -BaseUrl http://localhost:3003
  (Get-Content 'artifacts/ecrr-01-playwright-isolation.json' -Raw | ConvertFrom-Json).stats.unexpected
  (Get-Content 'artifacts/ecrr-01-playwright-offline.json' -Raw | ConvertFrom-Json).stats.unexpected
  Get-Content 'artifacts/ecrr-01-verification.log' -TotalCount 3
  ```

## Role
- You (fubumaki): import the saved view and alert (if API import unavailable, use UI)
- Cursor Agent: maintain assets and update docs as versions change

## Acceptance
- UI map linked from README
- Saved view available; alert configured for `otelcol-contrib`
- ECRR‑01 bundle regenerated; both JSON files show `unexpected = 0`; header lines present

## Next
- Optionally wire management API usage with a PAT (`SIGNOZ_API_TOKEN`) for non-UI imports
- Add screenshots to `SIGNOZ_UI_MAP.md` and finalize a deep-link pattern if supported by the current build
