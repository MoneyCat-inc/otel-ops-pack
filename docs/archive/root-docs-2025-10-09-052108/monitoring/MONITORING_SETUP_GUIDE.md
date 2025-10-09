# 🎯 Optimized Pipeline Monitoring Setup

## Dashboard Import

### Queue Pressure Dashboard

1. **Open SigNoz UI**: http://localhost:8080
2. **Navigate**: Dashboards → Import
3. **Upload**: `artifacts/signoz-dashboard-config.json`
4. **Verify**: All 6 panels load correctly:
   - Queue Utilization Ratio
   - Queue Size vs Capacity (24h Trend)
   - Send Failure Rate
   - Trace Time-to-Use (p50/p95/p99)
   - Fractal Drift Detection
   - Batch Efficiency

### Fractal Drift Monitors Dashboard

1. **Open SigNoz UI**: http://localhost:8080
2. **Navigate**: Dashboards → Import
3. **Upload**: `artifacts/signoz-fractal-drift-dashboard.json`
4. **Verify**: All 6 panels load correctly:
   - Exporter Queue Ratio (Real-time + 24h Trend)
   - Send Failure Rate (by Exporter, by Error Type)
   - Trace Time-to-Use (p50/p95/p99)
   - Fractal Drift Detection (Pattern Variance Analysis)
   - Batch Efficiency & Size Distribution
   - Memory Usage & Limits

### Optimized Pipeline Dashboard

1. **Open SigNoz UI**: http://localhost:8080
2. **Navigate**: Dashboards → Import
3. **Upload**: `artifacts/optimized-pipeline-dashboard.json`
4. **Verify**: All 9 panels load correctly

## Dashboard Features

### 📊 **Queue Pressure Monitoring**

#### Queue Utilization Ratio
- **Purpose**: Real-time queue pressure monitoring
- **Thresholds**: Green <70%, Yellow 70-80%, Red >80%
- **Alert**: Queue utilization >80% for 5 minutes

#### Queue Size vs Capacity Trend
- **Purpose**: Track queue size trends over 24 hours
- **Visualization**: Time series with dual lines
- **Alert**: Queue size approaching capacity

#### Send Failure Rate
- **Purpose**: Monitor exporter send failures
- **Thresholds**: Green <1%, Yellow 1-5%, Red >5%
- **Alert**: Send failure rate >5% for 2 minutes

#### Trace Time-to-Use Percentiles
- **Purpose**: Monitor batch processing latency
- **Metrics**: p50, p95, p99 latencies
- **Alert**: p95 latency >2s for 5 minutes

#### Fractal Drift Detection
- **Purpose**: Detect pattern variance in queue behavior
- **Metrics**: Queue size and send failure variance
- **Alert**: Variance >2x baseline for 10 minutes

#### Batch Efficiency
- **Purpose**: Monitor batch processing efficiency
- **Thresholds**: Green >200, Yellow 128-200, Red <128
- **Alert**: Batch efficiency <128 for 5 minutes

### 🔄 **Fractal Drift Monitoring**

#### Exporter Queue Ratio
- **Purpose**: Real-time queue utilization monitoring
- **Visualization**: Time series with 24h trend
- **Alert**: Queue ratio >0.7 for 10 minutes

#### Send Failure Rate
- **Purpose**: Monitor exporter failures by type
- **Visualization**: Time series with exporter breakdown
- **Alert**: Failure rate >5% for 2 minutes

#### Trace Time-to-Use
- **Purpose**: Monitor batch processing latency
- **Metrics**: p50, p95, p99 percentiles
- **Alert**: p95 latency >8s for 5 minutes

#### Fractal Drift Detection
- **Purpose**: Detect pattern variance in system behavior
- **Metrics**: Queue size, send failure, and latency variance
- **Alert**: Variance >2x baseline for 10 minutes

#### Batch Efficiency & Size Distribution
- **Purpose**: Monitor batch processing performance
- **Metrics**: Average batch size and batches per second
- **Alert**: Batch efficiency <128 for 5 minutes

#### Memory Usage & Limits
- **Purpose**: Monitor collector memory consumption
- **Metrics**: Memory usage vs limits
- **Alert**: Usage >80% of limit for 5 minutes

### 🔄 **Unified Pipeline Overview**
- Markdown panel explaining the Logs → Metrics → Traces workflow
- Key optimizations: 200ms batches, 50% volume reduction, sub-second latency

### 📊 **Recent Logs (5m)**
- ClickHouse SQL view of latest pipeline entries
- Inspect WARN/INFO bodies for noise patterns
- Query: `SELECT timestamp, severity_text, body, attributes FROM logs WHERE timestamp >= now() - INTERVAL 5 MINUTE ORDER BY timestamp DESC LIMIT 100`

### 📈 **Metrics Snapshot (1m)**
- Real-time stat group showing:
  - Accepted Logs/s
  - Filtered Logs/s  
  - Exporter Errors/s

### ⏱️ **Trace Duration (p95/p99)**
- Dual-line chart for latency quantiles
- Catches processing latency drift
- Both p95 and p99 visible on same chart

### 🎛️ **Additional Panels**
- Log Volume by Source (time series)
- Noise Filter Effectiveness (stat)
- Windows Event Log Sources (table)
- Export Error Rate (time series)
- Batch Size Distribution (histogram)

## Alert Import

1. **Navigate**: Alerts → Import
2. **Upload**: `artifacts/noise-pattern-alerts.json`
3. **Configure**: 5 alert rules for noise volume, latency spikes, errors, new event IDs, batch anomalies

## Live Monitoring

```powershell
# Quick health check
pwsh -File scripts/monitor-optimized-pipeline.ps1 -DurationMinutes 5

# Continuous monitoring
pwsh -File scripts/monitor-optimized-pipeline.ps1 -Continuous
```

## Troubleshooting

**If Recent Logs panel shows noise:**
- Check the noise filter rules in `config.yaml`
- Extend filter patterns for new Windows Event IDs
- Monitor the "Noise Filter Effectiveness" stat

**If latency spikes:**
- Check "Trace Duration (p95/p99)" panel
- Verify batch size stays around 256 records
- Monitor "Export Error Rate" for backend issues

**If metrics don't load:**
- Ensure OTel collector is running: `sc query otelcol-contrib`
- Check SigNoz collector health: http://localhost:13134/metrics
- Verify port mappings: 5317/5318 → 14317/14318

## Next Steps

1. Import dashboard and verify all panels render
2. Set up alert notifications (email/Slack)
3. Monitor "Recent Logs (5m)" for noise patterns
4. Tune filter rules based on observed patterns
5. Set up automated reports for daily/weekly summaries

The optimized pipeline is now fully observable with unified Logs → Metrics → Traces visibility! 🚀