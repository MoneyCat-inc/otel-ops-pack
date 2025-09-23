# SigNoz Monitoring Setup for Resonai Analytics Pipeline

## Overview
This guide covers setting up comprehensive monitoring for the Resonai ↔ OTel ↔ SigNoz analytics pipeline, including dashboards, alerts, and real-time monitoring procedures.

## Prerequisites
- SigNoz running at `http://localhost:8080`
- Resonai analytics pipeline verified and working
- OTel Collector forwarding data to SigNoz
- ClickHouse accessible for direct queries

## 1. Dashboard Setup

### 1.1 Analytics Overview Dashboard

**Dashboard Name**: `Resonai Analytics Overview`

**Panels**:

#### Panel 1: Event Volume (24h)
- **Query**: `count(*)`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 24 hours
- **Visualization**: Line chart
- **Purpose**: Monitor overall analytics volume

#### Panel 2: Event Types Distribution
- **Query**: `count(*) by event`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 24 hours
- **Visualization**: Pie chart
- **Purpose**: See distribution of different event types

#### Panel 3: TTV (Time to Voice) Metrics
- **Query**: `avg(ttv_ms), p50(ttv_ms), p95(ttv_ms)`
- **Filter**: `service.name = "resonai-analytics" AND ttv_ms IS NOT NULL`
- **Time Range**: Last 24 hours
- **Visualization**: Stat panels
- **Purpose**: Monitor voice response performance

#### Panel 4: Error Rate
- **Query**: `count(*) where event contains "error" / count(*)`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 24 hours
- **Visualization**: Stat panel
- **Purpose**: Track error rates

#### Panel 5: Top Variants
- **Query**: `count(*) by variant`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 24 hours
- **Visualization**: Bar chart
- **Purpose**: See which variants are most active

#### Panel 6: Session Activity
- **Query**: `count(distinct session_id)`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 24 hours
- **Visualization**: Stat panel
- **Purpose**: Track unique sessions

### 1.2 Performance Monitoring Dashboard

**Dashboard Name**: `Resonai Performance Monitoring`

**Panels**:

#### Panel 1: TTV Trend (1h)
- **Query**: `avg(ttv_ms)`
- **Filter**: `service.name = "resonai-analytics" AND ttv_ms IS NOT NULL`
- **Time Range**: Last 1 hour
- **Visualization**: Line chart
- **Purpose**: Real-time TTV monitoring

#### Panel 2: TTV Percentiles
- **Query**: `p50(ttv_ms), p90(ttv_ms), p95(ttv_ms), p99(ttv_ms)`
- **Filter**: `service.name = "resonai-analytics" AND ttv_ms IS NOT NULL`
- **Time Range**: Last 1 hour
- **Visualization**: Line chart
- **Purpose**: TTV distribution analysis

#### Panel 3: Event Rate (5m)
- **Query**: `rate(count(*), 5m)`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 1 hour
- **Visualization**: Line chart
- **Purpose**: Event throughput monitoring

#### Panel 4: Error Events
- **Query**: `count(*) where event contains "error"`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 1 hour
- **Visualization**: Line chart
- **Purpose**: Error tracking

### 1.3 System Health Dashboard

**Dashboard Name**: `Resonai System Health`

**Panels**:

#### Panel 1: Pipeline Health
- **Query**: `count(*) where event = "wiring_verification_test"`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 1 hour
- **Visualization**: Stat panel
- **Purpose**: Verify pipeline is working

#### Panel 2: Data Freshness
- **Query**: `max(timestamp)`
- **Filter**: `service.name = "resonai-analytics"`
- **Time Range**: Last 1 hour
- **Visualization**: Stat panel
- **Purpose**: Ensure data is flowing

#### Panel 3: OTel Collector Status
- **Query**: `count(*) where service.name = "otel-collector"`
- **Filter**: `service.name = "otel-collector"`
- **Time Range**: Last 1 hour
- **Visualization**: Stat panel
- **Purpose**: Monitor OTel collector health

## 2. Alert Setup

### 2.1 High Error Rate Alert

**Alert Name**: `Resonai High Error Rate`
- **Condition**: Error rate > 5% for 5 minutes
- **Query**: `count(*) where event contains "error" / count(*) > 0.05`
- **Filter**: `service.name = "resonai-analytics"`
- **Evaluation Window**: 5 minutes
- **Severity**: Critical
- **Notification**: Email/Slack

### 2.2 TTV Performance Alert

**Alert Name**: `Resonai High TTV`
- **Condition**: P95 TTV > 1000ms for 5 minutes
- **Query**: `p95(ttv_ms) > 1000`
- **Filter**: `service.name = "resonai-analytics" AND ttv_ms IS NOT NULL`
- **Evaluation Window**: 5 minutes
- **Severity**: Warning
- **Notification**: Email/Slack

### 2.3 Data Flow Alert

**Alert Name**: `Resonai Data Flow Stalled`
- **Condition**: No events for 10 minutes
- **Query**: `count(*) = 0`
- **Filter**: `service.name = "resonai-analytics"`
- **Evaluation Window**: 10 minutes
- **Severity**: Critical
- **Notification**: Email/Slack

### 2.4 Pipeline Health Alert

**Alert Name**: `Resonai Pipeline Health`
- **Condition**: No verification events for 30 minutes
- **Query**: `count(*) where event = "wiring_verification_test" = 0`
- **Filter**: `service.name = "resonai-analytics"`
- **Evaluation Window**: 30 minutes
- **Severity**: Warning
- **Notification**: Email/Slack

## 3. Real-time Monitoring Procedures

### 3.1 Daily Health Check

```powershell
# Run verification script
pwsh -File scripts/verify-wiring.ps1

# Check SigNoz UI
Start-Process "http://localhost:8080"
```

**Checklist**:
- [ ] Verification script passes
- [ ] Recent events visible in SigNoz
- [ ] TTV metrics within normal range
- [ ] Error rate < 5%
- [ ] All dashboards showing data

### 3.2 Real-time Monitoring Queries

#### Check Current Activity
```sql
SELECT count(*) as events, 
       avg(ttv_ms) as avg_ttv,
       count(*) where event contains "error" as errors
FROM signoz_logs.distributed_logs_v2 
WHERE timestamp >= now() - INTERVAL 5 MINUTE 
  AND service.name = "resonai-analytics"
```

#### Check TTV Performance
```sql
SELECT p50(ttv_ms) as p50_ttv,
       p90(ttv_ms) as p90_ttv,
       p95(ttv_ms) as p95_ttv,
       p99(ttv_ms) as p99_ttv
FROM signoz_logs.distributed_logs_v2 
WHERE timestamp >= now() - INTERVAL 1 HOUR 
  AND service.name = "resonai-analytics"
  AND ttv_ms IS NOT NULL
```

#### Check Error Patterns
```sql
SELECT event, count(*) as error_count
FROM signoz_logs.distributed_logs_v2 
WHERE timestamp >= now() - INTERVAL 1 HOUR 
  AND service.name = "resonai-analytics"
  AND event contains "error"
GROUP BY event
ORDER BY error_count DESC
```

### 3.3 Troubleshooting Procedures

#### No Data in SigNoz
1. Check OTel Collector service: `sc query otelcol-contrib`
2. Check SigNoz health: `curl http://localhost:8080/api/v1/health`
3. Check ClickHouse: `curl "http://localhost:8123/?query=SELECT 1"`
4. Run verification script: `pwsh -File scripts/verify-wiring.ps1`

#### High TTV
1. Check system resources (CPU, memory)
2. Review recent code changes
3. Check for error patterns in logs
4. Monitor ClickHouse performance

#### High Error Rate
1. Check error event types in SigNoz
2. Review application logs
3. Check OTel collector logs
4. Verify data format consistency

## 4. Dashboard Import/Export

### 4.1 Export Dashboard Configuration
```json
{
  "dashboard": {
    "title": "Resonai Analytics Overview",
    "panels": [
      {
        "title": "Event Volume (24h)",
        "type": "graph",
        "targets": [
          {
            "expr": "count(*)",
            "legendFormat": "Events"
          }
        ]
      }
    ]
  }
}
```

### 4.2 Import Dashboard
1. Go to SigNoz UI → Dashboards
2. Click "Import Dashboard"
3. Paste JSON configuration
4. Save and configure alerts

## 5. Monitoring Scripts

### 5.1 Health Check Script
```powershell
# scripts/monitor-pipeline-health.ps1
param(
    [int]$DurationMinutes = 60
)

Write-Host "=== Resonai Pipeline Health Monitor ===" -ForegroundColor Green

# Run verification
Write-Host "Running verification..." -ForegroundColor Yellow
pwsh -File scripts/verify-wiring.ps1

# Check SigNoz metrics
Write-Host "Checking SigNoz metrics..." -ForegroundColor Yellow
$metrics = Invoke-RestMethod -Uri "http://localhost:8123/?query=SELECT count(*) as events, avg(ttv_ms) as avg_ttv FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 5 MINUTE AND service.name = 'resonai-analytics'"

Write-Host "Recent Activity (5min):" -ForegroundColor Green
Write-Host "  Events: $($metrics.data[0][0])" -ForegroundColor White
Write-Host "  Avg TTV: $($metrics.data[0][1])ms" -ForegroundColor White

# Monitor for specified duration
Write-Host "Monitoring for $DurationMinutes minutes..." -ForegroundColor Yellow
Start-Sleep -Seconds ($DurationMinutes * 60)
```

### 5.2 Alert Test Script
```powershell
# scripts/test-alerts.ps1
Write-Host "=== Testing SigNoz Alerts ===" -ForegroundColor Green

# Test error rate alert
Write-Host "Testing error rate alert..." -ForegroundColor Yellow
$errorRate = Invoke-RestMethod -Uri "http://localhost:8123/?query=SELECT count(*) where event contains 'error' / count(*) FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 5 MINUTE AND service.name = 'resonai-analytics'"

Write-Host "Current error rate: $($errorRate.data[0][0])" -ForegroundColor White

# Test TTV alert
Write-Host "Testing TTV alert..." -ForegroundColor Yellow
$ttvP95 = Invoke-RestMethod -Uri "http://localhost:8123/?query=SELECT p95(ttv_ms) FROM signoz_logs.distributed_logs_v2 WHERE timestamp >= now() - INTERVAL 5 MINUTE AND service.name = 'resonai-analytics' AND ttv_ms IS NOT NULL"

Write-Host "Current P95 TTV: $($ttvP95.data[0][0])ms" -ForegroundColor White
```

## 6. Best Practices

### 6.1 Dashboard Design
- Keep dashboards focused on specific use cases
- Use consistent color schemes
- Include both real-time and historical views
- Add context and documentation

### 6.2 Alert Configuration
- Set appropriate thresholds based on historical data
- Use multiple severity levels
- Include runbook links in alert descriptions
- Test alerts regularly

### 6.3 Monitoring Strategy
- Monitor both technical and business metrics
- Set up escalation procedures
- Document troubleshooting steps
- Regular review and adjustment of thresholds

## 7. Maintenance

### 7.1 Weekly Tasks
- Review dashboard performance
- Check alert effectiveness
- Update documentation
- Test monitoring scripts

### 7.2 Monthly Tasks
- Analyze trends and adjust thresholds
- Review and optimize queries
- Update monitoring procedures
- Conduct monitoring health check

## 8. Troubleshooting

### 8.1 Common Issues
- **No data**: Check OTel collector and SigNoz services
- **Slow queries**: Optimize ClickHouse queries
- **Missing alerts**: Verify alert configuration
- **Dashboard errors**: Check query syntax and filters

### 8.2 Support Resources
- SigNoz documentation
- ClickHouse documentation
- OTel collector documentation
- Internal runbooks and procedures
