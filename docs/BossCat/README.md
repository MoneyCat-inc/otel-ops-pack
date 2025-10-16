# BossCat Operations Guide

![Gate Status](https://img.shields.io/badge/Gate-READY-green?style=flat-square&logo=checkmarx)
![Guardrails](https://img.shields.io/badge/Guardrails-LOCKED-blue?style=flat-square&logo=shield)
![Collector](https://img.shields.io/badge/Collector-RUNNING-green?style=flat-square&logo=opentelemetry)

[![BossCat Gate Verification](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-gate-verify.yml/badge.svg)](../../actions/workflows/bosscat-gate-verify.yml)
[![BossCat Regression Matrix](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-regression-matrix.yml/badge.svg)](../../actions/workflows/bosscat-regression-matrix.yml)
[![Weekly Re-Cert](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/guardrails-recert.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/guardrails-recert.yml)
[![Monthly Rollup](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-monthly-evidence-rollup.yml/badge.svg)](https://github.com/MoneyCat-inc/otel-ops-pack/actions/workflows/bosscat-monthly-evidence-rollup.yml)

• Governance: [Run Branch Protection Setup](../../actions/workflows/bosscat-branch-protection.yml)

Purpose: Governance and local-first operations for Resonai [OTel].

Key Artifacts:
- docs/ecrr/ECRR_REPORTS/ - ECRR audit trails
- docs/observability/snapshots/ - Dashboard exports
- docs/status/ - Status and test summaries
- docs/IONA_ERRORS.md - Error ledger
- docs/BossCat/visuals/ - MILK control surface
- docs/ecrr/ECRR_REPORTS/ECRR_MILK_CONSOLIDATED_LATEST.md - MILK lane summary
- docs/BossCat/visuals/presets/registry.json - MILK preset registry (moods/tags)

Runbooks:
- Gate verify: pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -Strict
- ECRR benchmark: pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1
- Watchdog control: pwsh -File BRAV/SCPT/watchdog-control.ps1 [start|stop|status|logs|evidence] [gate|site|both]
- MILK visuals: start docs\BossCat\visuals\control.html

## 🚀 Quick Commands

### Gate Verification
```
# Default (auto-detect strictness by site)
pnpm run agent:ready-for-gate

# Explicit per-site helpers
pnpm run agent:ready-for-gate:local
pnpm run agent:ready-for-gate:ci
pnpm run agent:ready-for-gate:stg
pnpm run agent:ready-for-gate:prod
```

- Purpose: Run local gate verification and generate artifacts.
- Produces:
  - `DELT/ARTF/gate-verification-results.json` — Gate verification results with verdict
  - `PR_COMMENT_IONA_GATE_002_FINAL.md` — Formatted PR comment for gate approval
  - ECRR gate reports (when applicable) in `docs/ecrr/ECRR_REPORTS/`
- Use cases:
  - Local pre-flight checks before PR submission
  - Manual gate verification during development
  - Refreshing gate artifacts for status dashboard
- Alias for: `pwsh -File scripts/verify-iona-gate.ps1 -OutputJson DELT/ARTF/gate-verification-results.json -PrCommentPath PR_COMMENT_IONA_GATE_002_FINAL.md`

### MILK Visual Control
```
# Open control surface
start docs\BossCat\visuals\control.html

# Verify installation
node scripts/visuals/visu-shim.ts verify

# Get control path
node scripts/visuals/visu-shim.ts url

# Test automation commands
node scripts/visuals/visu-shim.ts test
```

- Purpose: Launch BossCat visual control surface (Butterchurn/MilkDrop)
- Lane: MILK (MilkDrop Integration Layer & Kit)
- Features: Real-time audio visualization, preset management, automation API
- Docs: `docs/BossCat/visuals/CONTROL_README.md`

## 🐾 BossCat Seal

All operations follow ECRR methodology (Examine → Clean → Report → Role) and maintain full audit trails in `docs/ecrr/ECRR_REPORTS/`.

**Tetragram Lanes**:
- **ALFA**: Agent Framework & Automation
- **BRAV**: Build, Release, Archive & Versioning
- **CHAR**: CHaracterization, Analysis & Reporting
- **DELT**: Deployment, Evidence, Logs & Telemetry
- **MILK**: MilkDrop Integration Layer & Kit

For detailed documentation, see lane-specific subdirectories under `docs/BossCat/`.
