# SigNoz Monitoring Quick Start Guide

## 🚀 **Your Resonai Analytics Pipeline is Ready for Production Monitoring!**

### ✅ **What's Already Working**
- **Pipeline Verification**: `scripts/verify-wiring.ps1` - Full end-to-end verification with ClickHouse fallback
- **Health Monitoring**: `scripts/monitor-pipeline-health.ps1` - Real-time pipeline monitoring
- **Alert Testing**: `scripts/test-alerts.ps1` - Test alert conditions and thresholds
- **Setup Assistant**: `scripts/setup-monitoring.ps1` - Interactive monitoring setup guide

### 🎯 **Quick Start Commands**

#### **Daily Health Check**
```powershell
pwsh -File scripts/verify-wiring.ps1
```

#### **Real-time Monitoring (1 hour)**
```powershell
pwsh -File scripts/monitor-pipeline-health.ps1 -DurationMinutes 60
```

#### **Continuous Monitoring**
```powershell
pwsh -File scripts/monitor-pipeline-health.ps1 -Continuous
```

#### **Test Alert Conditions**
```powershell
pwsh -File scripts/test-alerts.ps1
```

#### **Interactive Setup Guide**
```powershell
pwsh -File scripts/setup-monitoring.ps1 -OpenSigNoz -ShowInstructions
```

### 📊 **SigNoz Dashboard Setup**

#### **1. Open SigNoz UI**
- URL: `http://localhost:8080`
- Go to **Dashboards** → **New Dashboard**
- Name: `Resonai Analytics Overview`

#### **2. Essential Panels**

| Panel | Type | Query | Purpose |
|-------|------|-------|---------|
| **Event Volume** | Time Series | `count(*)` | Monitor overall activity |
| **Error Rate** | Stat | `count(*) where event contains 'error' / count(*) * 100` | Track error percentage |
| **TTV Performance** | Time Series | `avg(ttv_ms)`, `p50(ttv_ms)`, `p95(ttv_ms)` | Voice response metrics |
| **Event Types** | Pie Chart | `count(*) by event` | Event distribution |
| **Top Variants** | Bar Chart | `count(*) by variant` | Variant usage |
| **Sessions** | Stat | `count(distinct session_id)` | Unique user sessions |
| **Pipeline Health** | Stat | `count(*) where event = 'wiring_verification_test'` | Verify data flow |

#### **3. Dashboard Settings**
- **Filter**: `service.name = "resonai-analytics"`
- **Refresh**: 30 seconds
- **Time Range**: Last 24 hours
- **Auto-refresh**: Enabled

### 🚨 **Alert Configuration**

#### **Critical Alerts**
1. **High Error Rate** (> 5% for 5 min)
2. **Data Flow Stalled** (no events for 10 min)

#### **Warning Alerts**
1. **High TTV** (P95 > 1000ms for 5 min)
2. **Pipeline Health** (no verification for 30 min)

### 🔍 **Useful SigNoz Filters**

#### **Current Activity**
```
service.name = "resonai-analytics"
```

#### **Error Events**
```
service.name = "resonai-analytics" AND event contains "error"
```

#### **High TTV Events**
```
service.name = "resonai-analytics" AND ttv_ms > 1000
```

#### **Verification Events**
```
service.name = "resonai-analytics" AND event = "wiring_verification_test"
```

#### **Specific Session**
```
service.name = "resonai-analytics" AND session_id = "your-session-id"
```

### 📈 **Key Metrics to Monitor**

#### **Performance Metrics**
- **TTV (Time to Voice)**: Target < 500ms average, < 1000ms P95
- **Error Rate**: Target < 2%, Alert > 5%
- **Event Throughput**: Monitor events per minute
- **Session Activity**: Track unique user sessions

#### **Health Metrics**
- **Pipeline Verification**: Regular verification events
- **Data Freshness**: Recent events in last 10 minutes
- **Service Health**: SigNoz and ClickHouse availability

### 🛠️ **Troubleshooting**

#### **No Data in SigNoz**
```powershell
# Check services
sc query otelcol-contrib
curl http://localhost:8080/api/v1/health
curl "http://localhost:8123/?query=SELECT 1"

# Run verification
pwsh -File scripts/verify-wiring.ps1
```

#### **High TTV**
1. Check system resources (CPU, memory)
2. Review recent code changes
3. Monitor ClickHouse performance
4. Check for error patterns

#### **High Error Rate**
1. Check error event types in SigNoz
2. Review application logs
3. Verify data format consistency
4. Check OTel collector logs

### 📋 **Maintenance Schedule**

#### **Daily**
- [ ] Run `verify-wiring.ps1` health check
- [ ] Review dashboard metrics
- [ ] Check alert status

#### **Weekly**
- [ ] Review dashboard performance
- [ ] Test alert conditions
- [ ] Update documentation
- [ ] Check monitoring scripts

#### **Monthly**
- [ ] Analyze trends and adjust thresholds
- [ ] Review and optimize queries
- [ ] Update monitoring procedures
- [ ] Conduct monitoring health check

### 🎉 **Success Criteria**

Your monitoring setup is successful when:
- ✅ Verification script passes consistently
- ✅ Dashboards show real-time data
- ✅ Alerts trigger appropriately
- ✅ TTV metrics are within targets
- ✅ Error rates stay below thresholds
- ✅ Pipeline health is maintained

### 📚 **Documentation**

- **Complete Setup Guide**: `docs/SIGNOZ_MONITORING_SETUP.md`
- **Dashboard Config**: `docs/signoz-dashboard-config.json`
- **Verification Script**: `scripts/verify-wiring.ps1`
- **Monitoring Scripts**: `scripts/monitor-pipeline-health.ps1`
- **Alert Testing**: `scripts/test-alerts.ps1`

---

## 🚀 **You're Ready for Production Monitoring!**

Your Resonai analytics pipeline now has comprehensive monitoring with:
- **Real-time dashboards** for operational visibility
- **Automated alerts** for proactive issue detection  
- **Health checks** for pipeline verification
- **Performance monitoring** for TTV and error tracking
- **Troubleshooting tools** for rapid issue resolution

**Next Steps**: Follow the dashboard setup instructions and configure alerts to complete your monitoring setup!
