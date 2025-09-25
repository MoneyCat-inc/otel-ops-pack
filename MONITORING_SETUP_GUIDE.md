# 🎯 Optimized Pipeline Monitoring Setup

## Dashboard Import

1. **Open SigNoz UI**: http://localhost:8080
2. **Navigate**: Dashboards → Import
3. **Upload**: `artifacts/optimized-pipeline-dashboard.json`
4. **Verify**: All 9 panels load correctly

## Dashboard Features

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

## IONA Supervisor Operations

### Agent Lifecycle Management

```powershell
# Check supervisor status
pwsh -File scripts/agents/supervisor.ps1 -Action status

# Spawn an agent
pwsh -File scripts/agents/supervisor.ps1 -Action spawn -SpecPath specs/sample-companion.json

# Monitor agent execution
pwsh -File scripts/agents/supervisor.ps1 -Action await -Id <ticket-id> -TimeoutMs 30000

# Terminate agent if needed
pwsh -File scripts/agents/supervisor.ps1 -Action terminate -Id <ticket-id> -Reason "operator stop"
```

### Emergency Controls

```powershell
# Emergency stop (pause all agents)
touch .agent/LOCK

# Resume operations
rm .agent/LOCK

# Run verification tests
pwsh -File scripts/agents/verify-supervisor.ps1 -Quick
```

### Agent Modes

- **Companion**: Conversational assistance with humor gating
- **Archivist**: Documentation and knowledge management  
- **Cipher**: Security analysis and compliance checking
- **MarketAnalyst**: Business intelligence and metrics analysis
- **Care**: Health monitoring and maintenance tasks

## Next Steps

1. Import dashboard and verify all panels render
2. Set up alert notifications (email/Slack)
3. Monitor "Recent Logs (5m)" for noise patterns
4. Tune filter rules based on observed patterns
5. Set up automated reports for daily/weekly summaries
6. **Configure IONA agents** for automated monitoring and maintenance
7. **Test supervisor** with verification suite before production use

The optimized pipeline is now fully observable with unified Logs → Metrics → Traces visibility and intelligent agent automation! 🚀