# IONA → SigNoz Quick Reference

## 🎯 **Status: PRODUCTION READY** ✅

The IONA Supervisor → SigNoz observability pipeline is **live and verified end-to-end**.

## 📊 **Core Metrics Available**

```promql
# Job Throughput (Primary Success Metric)
sum(rate(iona_jobs_completed_total{mode!=""}[5m])) by (mode)

# Job Success Rate
(sum(rate(iona_jobs_completed_total{mode!=""}[5m])) by (mode) / 
 (sum(rate(iona_jobs_completed_total{mode!=""}[5m])) by (mode) + 
  sum(rate(iona_jobs_failed_total{mode!=""}[5m])) by (mode))) * 100

# Job Duration p95
histogram_quantile(0.95, sum(rate(iona_job_duration_ms_bucket{mode!=""}[5m])) by (mode, le))

# Queue Depth
sum(iona_jobs_queued{mode!=""}) by (mode)

# Active Jobs
sum(iona_jobs_running{mode!=""}) by (mode)
```

## 🚀 **Quick Start Commands**

```powershell
# Generate test data
pwsh -NoProfile -File scripts/iona-supervisor-runner.ps1 -JobCount 5 -EnableTracing

# Quick verification
pwsh -NoProfile -File scripts/test-iona-metrics.ps1 -JobCount 3

# Full verification
pwsh -NoProfile -File verify-iona-signoz-integration.ps1 -JobCount 2 -EnableTracing

# Set up daily verification (Admin required)
pwsh -NoProfile -File scripts/setup-iona-scheduled-verification.ps1
```

## 📈 **SigNoz UI Navigation**

1. **Dashboard Import**: Dashboards → Import → Upload `artifacts/iona-supervisor-dashboard.json`
2. **Metrics Query**: Metrics → Explorer → `sum(rate(iona_jobs_completed_total{mode!=""}[5m])) by (mode)`
3. **Traces**: Traces → Search → Filter: `service.name = "iona-supervisor"`
4. **Alerts**: Alerts → New Alert → Use PromQL queries above

## 🔧 **Key Files**

| File | Purpose |
|------|---------|
| `scripts/metrics.ps1` | OTLP helpers (Send-IonaMetric, Send-IonaSpan) |
| `scripts/iona-supervisor-runner.ps1` | Demo workload with instrumentation |
| `verify-iona-signoz-integration.ps1` | End-to-end verification |
| `artifacts/iona-supervisor-dashboard.json` | SigNoz dashboard import |
| `scripts/daily-iona-verification.ps1` | Automated regression detection |
| `IONA_SIGNOZ_DEPLOYMENT_GUIDE.md` | Complete setup guide |

## 🎛️ **Dashboard Panels**

- **Job Throughput (5m rate)** - Primary success metric
- **Job Success Rate (%)** - Color-coded health indicator  
- **Job Duration p95 (ms)** - Performance monitoring
- **Current Queue Depth** - Real-time capacity tracking
- **Active Jobs** - Current workload visibility
- **Error Rate by Type** - Failure analysis
- **Job Duration Percentiles** - Performance distribution

## 🚨 **Alerting Recommendations**

```promql
# High error rate (>10% failures)
sum(rate(iona_jobs_failed_total{mode!=""}[5m])) by (mode) > 0.1

# Queue backup (>20 jobs)
sum(iona_jobs_queued{mode!=""}) by (mode) > 20

# Slow jobs (>10s p95)
histogram_quantile(0.95, sum(rate(iona_job_duration_ms_bucket{mode!=""}[5m])) by (mode, le)) > 10000
```

## 🔍 **Troubleshooting**

| Issue | Solution |
|-------|----------|
| No metrics visible | Run `scripts/test-iona-metrics.ps1` |
| Dashboard import fails | Check JSON format, verify SigNoz permissions |
| Verification fails | Check `artifacts/iona-integration-verify.txt` |
| Collector issues | `sc query otelcol-contrib` |
| SigNoz health | `curl http://localhost:8080/api/v1/health` |

## 📅 **Maintenance**

- **Daily**: Automated verification via scheduled task
- **Weekly**: Review dashboard panels and alert thresholds  
- **Monthly**: Clean up old verification logs (`artifacts/daily-iona-verification-*.log`)

## 🎉 **Success Criteria**

✅ **OTLP endpoints responding** (`http://localhost:5318/v1/metrics`)  
✅ **Demo workload generating metrics** (iona_jobs_completed_total)  
✅ **SigNoz ingestion confirmed** (API queries return data)  
✅ **Dashboard ready for import** (JSON format validated)  
✅ **Verification automated** (scheduled task available)  

---

**Integration Status**: 🟢 **LIVE**  
**Last Verified**: 2025-09-24 22:30:00  
**Actor**: Cursor Agent - Observability Copilot
