# MEMX CI/CD Integration Guide

## Overview

This guide covers the complete CI/CD integration for MEMX, including automated testing, production deployment, and monitoring.

## Files Created

### 1. CI/CD Workflow
- **File**: `memx-ci-workflow.yml`
- **Location**: Copy to `.github/workflows/memx-ci.yml`
- **Purpose**: Automated testing on PRs, pushes, and nightly runs

### 2. Production Setup Script
- **File**: `scripts/setup-memx-production.ps1`
- **Purpose**: Configure MEMX for production deployment
- **Usage**: `.\scripts\setup-memx-production.ps1 -EnableStreaming`

### 3. Canary Test Script
- **File**: `scripts/memx-canary-test.ps1`
- **Purpose**: Generate test data and verify MEMX functionality
- **Usage**: `.\scripts\memx-canary-test.ps1 -DurationSeconds 60 -EnableStreaming`

## CI/CD Pipeline Jobs

### 1. MEMX Verification
- **Type**: Unit tests, type checking, Playwright tests
- **Triggers**: PR, push, nightly
- **Artifacts**: Playwright report, test results
- **Duration**: ~5-10 minutes

### 2. OTel Integration
- **Type**: Integration testing with OTel collector
- **Triggers**: After verification passes
- **Dependencies**: OTel collector, SigNoz
- **Duration**: ~2-3 minutes

### 3. Security Scan
- **Type**: Security audit, sensitive data check
- **Triggers**: After verification passes
- **Checks**: npm audit, secret scanning
- **Duration**: ~1-2 minutes

### 4. Performance Test
- **Type**: Performance monitoring
- **Triggers**: After verification passes
- **Metrics**: Response times, memory usage
- **Duration**: ~3-5 minutes

## Setup Instructions

### 1. Enable CI/CD
```bash
# Copy the workflow file
cp memx-ci-workflow.yml .github/workflows/memx-ci.yml

# Commit and push
git add .github/workflows/memx-ci.yml
git commit -m "Add MEMX CI/CD pipeline"
git push
```

### 2. Configure Production Environment
```powershell
# Enable MEMX in production
.\scripts\setup-memx-production.ps1 -EnableStreaming

# Or enable without streaming (local-only)
.\scripts\setup-memx-production.ps1
```

### 3. Run Canary Tests
```powershell
# Basic canary test
.\scripts\memx-canary-test.ps1

# Extended test with streaming
.\scripts\memx-canary-test.ps1 -DurationSeconds 120 -EnableStreaming -Verbose
```

## Monitoring and Observability

### 1. SigNoz Integration
- **Endpoint**: `http://localhost:8080`
- **Dataset**: `resonai_analytics`
- **Metrics**: `memx.wasm_heap.bytes`, `memx.sab.usage.pct`
- **Log Events**: `SAB_BACKLOG`, `WASM_GROW`, `WORKLET_LAG`

### 2. OTel Collector
- **Health Check**: `http://localhost:13134/healthz`
- **OTLP Endpoint**: `http://localhost:5318/v1/logs`
- **Configuration**: `config.yaml`

### 3. Playwright Reports
- **Location**: `playwright-report/index.html`
- **Retention**: 30 days
- **Coverage**: Cross-browser testing

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   - Development server: 3001 (3000 in use)
   - Playwright report: 9323
   - OTel collector: 5317/5318

2. **Cross-Origin Isolation**
   - Expected: `false` in test environment
   - Production: `true` with proper headers
   - Headers: COOP/COEP in `next.config.js`

3. **OTel Integration**
   - Check collector health: `http://localhost:13134/healthz`
   - Verify SigNoz: `http://localhost:8080/api/v1/health`
   - Check logs: `otelcol-contrib` service

### Debug Commands

```powershell
# Check MEMX status
.\scripts\verify-memx-integration.ps1

# Run Playwright tests
pnpm test:e2e --project=chromium

# Check OTel health
Invoke-WebRequest -Uri "http://localhost:13134/healthz"

# Check SigNoz health
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health"
```

## Production Deployment

### 1. Pre-deployment Checklist
- [ ] MEMX feature flag enabled
- [ ] OTel collector running
- [ ] SigNoz accessible
- [ ] Playwright tests passing
- [ ] Security scan clean

### 2. Deployment Steps
```powershell
# 1. Enable MEMX
.\scripts\setup-memx-production.ps1 -EnableStreaming

# 2. Run canary test
.\scripts\memx-canary-test.ps1 -DurationSeconds 300 -EnableStreaming

# 3. Verify in production
# Visit http://localhost:3001/labs/memx
# Check SigNoz for MEMX metrics
```

### 3. Post-deployment Monitoring
- Monitor SigNoz for MEMX events
- Check OTel collector logs
- Verify Playwright tests in CI
- Monitor performance metrics

## ECRR Integration

### 1. Add to ECRR Canary Schedule
```json
{
  "type": "memx-canary",
  "schedule": "0 2 * * *",
  "script": "scripts/memx-canary-test.ps1",
  "args": ["-DurationSeconds", "60", "-EnableStreaming"]
}
```

### 2. SSOT Artifacts
- MEMX test results
- Performance metrics
- OTel integration status
- SigNoz connectivity

## Support

For issues or questions:
1. Check the QA checklist: `docs/qa-checklist.md`
2. Review Playwright reports: `playwright-report/index.html`
3. Check OTel logs: `otelcol-contrib` service
4. Verify SigNoz: `http://localhost:8080`

## SigNoz Dashboard Integration

### Dashboard Files
- **Dashboard**: `signoz-memx-dashboard.json` - Complete dashboard configuration
- **Alerts**: `signoz-memx-alerts.json` - Alert rules and notification channels
- **Setup Guide**: `docs/SIGNOZ_MEMX_SETUP.md` - Detailed setup instructions
- **Import Script**: `scripts/import-memx-dashboard.ps1` - Automated import

### Dashboard Features
- **10 Panels**: Overview, WASM heap, SAB usage, worklet lag, strain events, frame budget, export metrics, logs, health, error rate
- **10 Alert Rules**: Memory strain, WASM growth, SAB backlog, worklet lag, frame drops, export failures, OTel disconnect, session stall, cross-origin isolation
- **Templating**: Time range, browser filters, auto-refresh
- **Thresholds**: Yellow (warning), Red (critical), Green (healthy)

### Quick Setup
```powershell
# Import dashboard and alerts
.\scripts\import-memx-dashboard.ps1

# Or dry run first
.\scripts\import-memx-dashboard.ps1 -DryRun
```

## Next Steps

1. **CI/CD**: Deploy the workflow to GitHub Actions
2. **Production**: Enable MEMX feature flag
3. **Import Dashboard**: Use the import script to set up SigNoz monitoring
4. **Monitoring**: Set up SigNoz alerts for MEMX metrics
5. **ECRR**: Add MEMX to canary schedule
6. **Documentation**: Update team documentation
