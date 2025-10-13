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
- docs/ecrr/ECRR_REPORTS/ — ECRR audit trails
- docs/observability/snapshots/ — Dashboard exports
- docs/status/ — Status and test summaries
- docs/IONA_ERRORS.md — Error ledger

Runbooks:
- Gate verify: pwsh -NoProfile -File scripts/verify-iona-gate.ps1 -Strict
- ECRR benchmark: pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1
- Watchdog control: pwsh -File BRAV/SCPT/watchdog-control.ps1 [start|stop|status|logs|evidence] [gate|site|both]

## 🚀 Quick Commands

### Gate Verification
```
pnpm run agent:ready-for-gate
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

### Dashboard Export
```
pnpm run export:signoz:playwright
```

- Purpose: Export SigNoz dashboards for nightly automation and documentation.
- Produces:
  - Dashboard screenshots (PNG) and data exports (JSON)
  - Observability snapshots under `docs/observability/snapshots/`
- Use cases:
  - Nightly dashboard automation (GitHub Actions workflow)
  - Manual captures for documentation and audits
- Alias for: `pwsh -File scripts/playwright-dashboard-export.ps1`
- Automation: Triggered by `.github/workflows/nightly-dashboard-export.yml`

### Typical Development Flow
```
# 1) Create branch and implement changes
git checkout -b feat/my-enhancement

# 2) Run local gate verification
pnpm run agent:ready-for-gate

# 3) Review gate results
type DELT/ARTF/gate-verification-results.json

# 4) If READY, push and open PR
git push origin feat/my-enhancement
# Create PR via your preferred tool (e.g., GitHub CLI or web)
```

## ECRR Benchmark Trend

- Latest summary JSON: `DELT/ARTF/ecrr-benchmark.json`
- Rolling CSV: `DELT/ARTF/ecrr-benchmark-trend.csv`
- Mirror CSV (for IDE/artifacts): `artifacts/ecrr-benchmark-trend.csv`
- Generate locally:
  - `pwsh -NoProfile -File scripts/benchmark-process-all-ecrr-reports.ps1`
  - `pwsh -NoProfile -File scripts/append-ecrr-benchmark-trend.ps1 -Dedup`
- CI/Nightly maintenance:
  - `.github/workflows/bosscat-gate-verify.yml`
  - `.github/workflows/nightly-dashboard-export.yml`

## Evidence Links

- Queue Steward Evidence: [artifacts/queue-steward-verification.txt](../../artifacts/queue-steward-verification.txt)
- ECRR Trend (CSV): [DELT/ARTF/ecrr-benchmark-trend.csv](../../DELT/ARTF/ecrr-benchmark-trend.csv)
- ECRR Benchmark (JSON): [DELT/ARTF/ecrr-benchmark.json](../../DELT/ARTF/ecrr-benchmark.json)
- Latest ECRR Gate Run: [docs/ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md](../ecrr/ECRR_REPORTS/ECRR_GATE_RUN_LATEST.md)

### Retention & Sampling Policy

- Sampling sources: on every gate verification (PR/CI) and nightly dashboard export.
- De-duplication key: `timestamp + commit + branch + latest_name` (keeps first occurrence).
- Retention window: last 365 days and at most 2000 rows (newest kept).
- Artifact retention in CI:
  - Gate verify artifacts: 30 days
  - Nightly artifacts: 90 days
- Tunables (optional):
  - `scripts/append-ecrr-benchmark-trend.ps1 -MaxDays <int> -MaxRows <int>`
  - Set `-MirrorCsv` to control the mirror path for IDEs.

## Automated Operations

**Daily:** GATE + SITE watchdogs keep collector running  
**Weekly:** Guardrails re-certification (Monday 03:00 UTC)  
**Monthly:** Evidence rollup and archival (1st day, 02:00 UTC)

## SBOM Strictness Toggle (Staged Re-Promotion)

**Current Mode**: Non-blocking (collecting evidence)  
**Toggle**: `SBOM_STRICT` (GitHub org/repo variable)  
**Default**: `false` (non-strict until proven stable)

### How It Works

The BossCat Gate Verification workflow includes SBOM generation for prod gates, but uses a **toggle-based promotion system** aligned with ICF doctrine (evidence → staged promotion).

**Non-Strict Mode** (`SBOM_STRICT=false` or unset):
- SBOM generation runs on every prod gate
- Failures logged but don't block the workflow
- Evidence collected via Issue #135 (automated tracking)
- Artifacts uploaded for manual review (90-day retention)

**Strict Mode** (`SBOM_STRICT=true`):
- SBOM generation failures **block** prod gate workflow
- Enforces supply chain integrity with hard gate
- Only promoted after evidence confirms stability (3-5 successful runs)
- Reversible via single variable change

### Promotion Plan

**Phase 1** (Current): Non-blocking evidence collection
- Monitor Issue #135 for SBOM generation patterns
- Track success rate over 3-5 prod gate runs
- Review failure logs for tooling issues
- **Duration**: 72 hours minimum

**Phase 2**: Staged promotion (when evidence is green)
- Set `SBOM_STRICT=true` in GitHub org/repo variables
- Monitor first 2-3 runs with strict enforcement
- Rollback if issues detected (set back to `false`)

**Phase 3**: Thorough hardening
- Install syft explicitly in workflow
- Add enhanced logging and diagnostics
- Implement fallback copy mechanisms
- Document troubleshooting procedures

### Manual Override

**To promote SBOM to strict mode**:
```bash
# Via GitHub web UI
# Settings → Secrets and variables → Actions → Variables
# Add/Edit: SBOM_STRICT = true

# Or via gh CLI
gh variable set SBOM_STRICT --body "true" --repo MoneyCat-inc/otel-ops-pack
```

**To rollback**:
```bash
gh variable set SBOM_STRICT --body "false" --repo MoneyCat-inc/otel-ops-pack
```

**Rationale**: This toggle-based approach follows BossCat doctrine:
- ✅ **Evidence-based**: Promotion only after stability proven
- ✅ **Reversible**: Single-variable change, no code edits
- ✅ **Safe**: Non-blocking by default, strict when ready
- ✅ **ECRR-aligned**: Examine → Contain → (evidence) → Promote

## Collector Recovery

**If collector fails repeatedly despite GATE bot:**

1. Check GATE bot logs:
   ```powershell
   Get-Content DELT/ARTF/watchdog-gate.log -Tail 50
   ```

2. Check Windows Event Log:
   ```powershell
   Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 10
   ```

3. Verify config is valid:
   ```powershell
   & "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" validate --config C:\otel\config.yaml
   ```

4. Check for port conflicts:
   ```powershell
   Get-NetTCPConnection -LocalPort 13134,5317,5318,8888,55679 -State Listen
   ```

5. Manual restart as admin:
   ```powershell
   sc stop otelcol-contrib
   Start-Sleep -Seconds 5
   sc start otelcol-contrib
   ```

6. If persistent, check GATE bot evidence:
   ```powershell
   Get-Content DELT/ARTF/watchdog-gate-evidence.json | ConvertFrom-Json
   ```
