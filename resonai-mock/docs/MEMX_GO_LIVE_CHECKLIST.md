# MEMX Go-Live Checklist

## Pre-Deployment Checklist

### 1. Import + Wire Notifications

```powershell
# Dry-run first
.\scripts\import-memx-dashboard.ps1 -DryRun

# Real import
.\scripts\import-memx-dashboard.ps1

# Configure notification channels in signoz-memx-alerts.json
# - Update Slack webhook URL
# - Update email addresses
# - Test notification channels

# Re-import with updated notifications
.\scripts\import-memx-dashboard.ps1 -Force
```

### 2. Seed Signals (Canary)

```powershell
# 2-minute synthetic load to populate panels & alerts
.\scripts\memx-canary-test.ps1 -DurationSeconds 120 -EnableStreaming -Verbose

# Stress test to verify alert thresholds
.\scripts\memx-stress-test.ps1 -StressMemory -DurationSeconds 90
.\scripts\memx-stress-test.ps1 -JitterFrames -DurationSeconds 90
.\scripts\memx-stress-test.ps1 -PauseStreamingSeconds 120
```

### 3. Verify the Three Pillars

#### Isolation
- [ ] `crossOriginIsolated` shows **true** on real deploy
- [ ] COOP/COEP headers properly configured
- [ ] SAB/WASM threads unlocked
- [ ] Test in production environment

#### Low-Latency Audio Path
- [ ] AudioWorklet stable with `latencyHint: 0`
- [ ] EC/NS/AGC disabled in getUserMedia constraints
- [ ] Sample rate handling (48 kHz typical on Windows)
- [ ] No start-of-speech gating or surprise gain shifts

#### Local-First Metrics & Flow
- [ ] MEMX export/IDB working correctly
- [ ] Flows unaffected by MEMX activation
- [ ] Session schema extended properly
- [ ] Export produces valid JSON

## Initial 48-Hour Baselines

### Starting Thresholds

| Signal                     |   Green |    Warn |    Critical | Notes                                               |
| -------------------------- | ------: | ------: | ----------: | --------------------------------------------------- |
| **WASM heap**              |  ≤ 8 MB | > 10 MB |     > 20 MB | raise slowly; watch growth slope, not just absolute |
| **SAB usage**              |  < 70 % |  ≥ 80 % |      ≥ 95 % | correlate with worklet lag                          |
| **AudioWorklet lag (p95)** | < 30 ms | ≥ 50 ms |    ≥ 100 ms | protect real-time UX                                |
| **Frame drops (1m)**       |   < 1 % |   ≥ 3 % |       ≥ 5 % | tie to frame budget panel                           |
| **Cross-origin isolation** |    true |       — | false 1 min | failing → SAB disabled (expect degraded metrics)    |
| **OTel ingest gap**        | < 1 min | ≥ 3 min |     ≥ 5 min | infra page & alert                                  |

> **Tip**: Let "warning" pages you; reserve "critical" for wake-ups.

### SLO Sketch (Product-Level)

- **Real-time pipeline SLO**: p95 AudioWorklet lag ≤ 50 ms during active practice sessions (weekly)
- **Isolation SLO**: crossOriginIsolated true ≥ 99.5% of practice page views (rolling 7d)
- **Export reliability SLO**: MEMX export success ≥ 99% with valid JSON schema (rolling 7d)

## Alert Dry-Runs (Noisy-Pager Prevention)

### Test Each Alert Rule

```powershell
# Push heap & SAB
.\scripts\memx-stress-test.ps1 -EnableStreaming -StressMemory -DurationSeconds 90

# Nudge worklet lag / frame budget
.\scripts\memx-stress-test.ps1 -JitterFrames -DurationSeconds 90

# Simulate OTel gap
.\scripts\memx-stress-test.ps1 -PauseStreamingSeconds 120
```

### Verify Alert Triggers

- [ ] High memory strain alert fires
- [ ] WASM heap growth alert fires
- [ ] SAB backlog alert fires
- [ ] Worklet lag alert fires
- [ ] Frame drops alert fires
- [ ] OTel disconnect alert fires
- [ ] Session stall alert fires
- [ ] Cross-origin isolation alert fires

### Test Notification Channels

- [ ] Slack webhook receives alerts
- [ ] Email notifications sent
- [ ] Alert severity levels correct
- [ ] Runbook URLs accessible

## CI Guard (Quick Add)

### Dashboard Validation

```yaml
- name: Validate MEMX Dashboard
  working-directory: ./resonai-mock
  run: pwsh -File scripts/validate-memx-dashboard.ps1
```

### Alert Testing in Staging

```yaml
- name: Test MEMX Alerts
  working-directory: ./resonai-mock
  run: pwsh -File scripts/validate-memx-dashboard.ps1 -TestAlerts
```

### SSOT Block for Nightly Report

```json
{
  "memx_status": {
    "dashboards_loaded": true,
    "alerts_fired": 0,
    "max_lag_p95": "25ms",
    "cross_origin_isolated": true,
    "otel_connected": true
  }
}
```

## Runbook Stubs

### 1. Worklet Lag High
- **Grab PerfOverlay** → confirm isolation → toggle reduced load → file bug if lag persists (attach p95/p99 + heap trend)

### 2. Isolation Disabled
- **Check COOP/COEP** on edge node; verify SW isn't stripping headers; redeploy with known-good header map

### 3. SAB Backlog
- **Correlate with heap & frame-drops**; roll back any recent WASM change; widen buffer only as last resort

## Production Deployment Steps

### 1. Enable MEMX in Production

```powershell
# Enable MEMX with streaming
.\scripts\setup-memx-production.ps1 -EnableStreaming

# Verify configuration
Get-Content .env.local | Select-String "MEMX"
```

### 2. Deploy CI/CD Pipeline

```bash
# Copy workflow to GitHub
cp memx-ci-workflow.yml .github/workflows/memx-ci.yml

# Commit and push
git add .github/workflows/memx-ci.yml
git commit -m "Add MEMX CI/CD pipeline"
git push
```

### 3. Import Dashboard

```powershell
# Import dashboard and alerts
.\scripts\import-memx-dashboard.ps1

# Verify import
.\scripts\validate-memx-dashboard.ps1
```

### 4. Run Initial Canary

```powershell
# Generate initial data
.\scripts\memx-canary-test.ps1 -DurationSeconds 300 -EnableStreaming -Verbose

# Verify data in SigNoz
# Visit http://localhost:8080/dashboards
```

### 5. Monitor and Tune

- [ ] Monitor dashboard for 24-48 hours
- [ ] Adjust thresholds based on observed patterns
- [ ] Tune alert rules if needed
- [ ] Update runbook based on real incidents

## Post-Deployment Verification

### 1. Dashboard Verification

- [ ] All panels load correctly
- [ ] Metrics appear within 5 minutes
- [ ] Time range controls work
- [ ] Browser filters work
- [ ] Auto-refresh functioning

### 2. Alert Verification

- [ ] All alert rules active
- [ ] Notification channels working
- [ ] Alert groups configured
- [ ] Escalation policies set

### 3. Integration Verification

- [ ] OTel collector receiving data
- [ ] SigNoz storing metrics
- [ ] MEMX page accessible
- [ ] Export functionality working

### 4. Performance Verification

- [ ] No impact on page load times
- [ ] No impact on audio processing
- [ ] No impact on user experience
- [ ] Memory usage within expected ranges

## Rollback Plan

### If Issues Arise

1. **Disable MEMX**: Set `NEXT_PUBLIC_FEATURE_MEMX=0` in production
2. **Restart Services**: Restart development server
3. **Verify Rollback**: Confirm MEMX is disabled
4. **Investigate**: Use runbook to identify root cause
5. **Fix and Redeploy**: Address issues and redeploy

### Emergency Contacts

- **Primary On-Call**: memx-oncall@resonai.com
- **Secondary On-Call**: memx-backup@resonai.com
- **Team Lead**: memx-lead@resonai.com

## Success Criteria

### 48-Hour Success Metrics

- [ ] Dashboard shows consistent data
- [ ] Alert thresholds appropriate
- [ ] No false positives
- [ ] No performance degradation
- [ ] User experience unaffected
- [ ] Team comfortable with monitoring

### 7-Day Success Metrics

- [ ] SLOs met consistently
- [ ] Alert effectiveness >90%
- [ ] Runbook procedures validated
- [ ] Team trained on procedures
- [ ] Documentation complete

## Next Steps After Go-Live

1. **Monitor**: Watch dashboard for 48 hours
2. **Tune**: Adjust thresholds based on real data
3. **Train**: Ensure team knows procedures
4. **Document**: Update runbook with lessons learned
5. **Optimize**: Improve based on observations
6. **Scale**: Consider expanding to other features

## Support Resources

- **Runbook**: `docs/MEMX_RUNBOOK.md`
- **Setup Guide**: `docs/SIGNOZ_MEMX_SETUP.md`
- **CI Guide**: `README-MEMX-CI.md`
- **QA Checklist**: `docs/qa-checklist.md`
- **SigNoz Dashboard**: http://localhost:8080/dashboards
- **MEMX Labs**: http://localhost:3000/labs/memx
