# MEMX Launch Runbook

## 🚀 Launch Day Checklist

### Pre-Launch (30 minutes before)

- [ ] **Copy CI workflow**: `cp memx-ci-workflow.yml .github/workflows/memx-ci.yml`
- [ ] **Import dashboards**: `.\scripts\import-memx-dashboard.ps1 -DryRun` then real run
- [ ] **Configure notifications**: Update Slack webhook URLs in `signoz-memx-alerts.json`
- [ ] **Verify OTel**: Check `http://localhost:13134/healthz` and `http://localhost:8080/api/v1/health`

### Launch (T-0)

- [ ] **Enable MEMX**: `.\scripts\setup-memx-production.ps1 -EnableStreaming`
- [ ] **Run canary**: `.\scripts\memx-canary-test.ps1 -DurationSeconds 120 -EnableStreaming -Verbose`
- [ ] **Stress test**: `.\scripts\memx-stress-test.ps1 -StressMemory -DurationSeconds 90`
- [ ] **Verify dashboard**: Visit `http://localhost:8080/dashboards` - all 10 panels green

### Post-Launch (First 2 hours)

- [ ] **Monitor alerts**: Check Slack #memx-alerts channel
- [ ] **Verify metrics**: MEMX data appearing in SigNoz within 5 minutes
- [ ] **Check isolation**: `window.crossOriginIsolated === true` in production
- [ ] **Test export**: MEMX export functionality working
- [ ] **Performance check**: No impact on page load times

### 48-Hour Monitoring

- [ ] **Baseline establishment**: Note normal WASM heap (≤8MB), SAB usage (<70%), worklet lag (<30ms)
- [ ] **Threshold tuning**: Adjust alert thresholds based on real traffic patterns
- [ ] **False positive check**: Ensure warning alerts don't fire excessively
- [ ] **SLO validation**: p95 lag ≤50ms, isolation ≥99.5%, export success ≥99%

## 🚨 Quick Commands

### Enable MEMX
```powershell
.\scripts\setup-memx-production.ps1 -EnableStreaming
```

### Run Tests
```powershell
# Canary test
.\scripts\memx-canary-test.ps1 -DurationSeconds 120 -EnableStreaming -Verbose

# Stress test
.\scripts\memx-stress-test.ps1 -StressMemory -DurationSeconds 90
```

### Check Status
```powershell
# Verify integration
.\scripts\verify-memx-integration.ps1

# Validate dashboard
.\scripts\validate-memx-dashboard.ps1
```

### Import Dashboard
```powershell
# Dry run first
.\scripts\import-memx-dashboard.ps1 -DryRun

# Real import
.\scripts\import-memx-dashboard.ps1
```

## 🚨 Emergency Rollback

### If Issues Arise
1. **Disable MEMX**: Set `NEXT_PUBLIC_FEATURE_MEMX=0` in production
2. **Restart services**: Restart development server
3. **Verify rollback**: Confirm MEMX is disabled
4. **Investigate**: Use `docs/MEMX_RUNBOOK.md` for troubleshooting

### Rollback Commands
```powershell
# Disable MEMX
(Get-Content .env.local) -replace 'NEXT_PUBLIC_FEATURE_MEMX=1', 'NEXT_PUBLIC_FEATURE_MEMX=0' | Set-Content .env.local

# Restart server
# Kill existing process and restart with pnpm dev
```

## 📊 Success Criteria

### 2-Hour Success
- [ ] Dashboard shows consistent data
- [ ] No critical alerts firing
- [ ] Page load times unchanged
- [ ] User experience unaffected

### 48-Hour Success
- [ ] Stable baselines established
- [ ] Alert thresholds appropriate
- [ ] No false positives
- [ ] Team comfortable with monitoring

### 7-Day Success
- [ ] SLOs met consistently
- [ ] Alert effectiveness >90%
- [ ] Runbook procedures validated
- [ ] Documentation complete

## 🚨 Key Alerts to Watch

| Alert | Threshold | Action |
|-------|-----------|--------|
| **High Memory Strain** | >80% for 5min | Check WASM heap, SAB usage |
| **Critical Memory Strain** | >95% for 2min | **IMMEDIATE ACTION** - reduce load |
| **WASM Heap Growth** | >20MB for 10min | Investigate memory leaks |
| **SAB Backlog** | >90% for 3min | Check worklet lag, frame drops |
| **Worklet Lag** | >100ms for 5min | Check isolation, reduce load |
| **OTel Disconnect** | No metrics for 5min | **CRITICAL** - check OTel collector |

## 📞 Emergency Contacts

- **Primary On-Call**: memx-oncall@resonai.com
- **Secondary On-Call**: memx-backup@resonai.com
- **Team Lead**: memx-lead@resonai.com

## 🔗 Quick Links

- **SigNoz Dashboard**: http://localhost:8080/dashboards
- **MEMX Labs**: http://localhost:3000/labs/memx
- **OTel Health**: http://localhost:13134/healthz
- **Full Runbook**: `docs/MEMX_RUNBOOK.md`
- **Setup Guide**: `docs/SIGNOZ_MEMX_SETUP.md`

## 📋 Post-Launch Tasks

### Day 1
- [ ] Monitor dashboard continuously
- [ ] Respond to any alerts immediately
- [ ] Document any issues found
- [ ] Update team on status

### Day 2-3
- [ ] Tune alert thresholds
- [ ] Update runbook with lessons learned
- [ ] Train team on procedures
- [ ] Plan for full rollout

### Week 1
- [ ] Validate SLOs
- [ ] Optimize performance
- [ ] Complete documentation
- [ ] Hand off to operations team

---

## 🎯 Launch Day Success = Green Dashboard + No Critical Alerts + Happy Users

**Remember**: MEMX is designed to be non-intrusive. If anything breaks, roll back immediately and investigate using the full runbook.
