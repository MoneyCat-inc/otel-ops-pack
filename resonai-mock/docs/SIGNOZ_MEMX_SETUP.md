# SigNoz MEMX Dashboard Setup Guide

## Overview

This guide covers setting up the MEMX Memory Observation Dashboard in SigNoz, including panels, alerts, and monitoring configuration.

## Files

- **Dashboard**: `signoz-memx-dashboard.json` - Complete dashboard configuration
- **Alerts**: `signoz-memx-alerts.json` - Alert rules and notification channels
- **Setup Guide**: This document

## Dashboard Panels

### 1. MEMX Overview
- **Type**: Stat panels
- **Metrics**: Frames/sec, Avg Strain %, Peak WASM Heap, Avg SAB Usage %
- **Purpose**: High-level health indicators

### 2. WASM Heap Memory
- **Type**: Time series
- **Metrics**: `memx_wasm_heap_bytes`, P95 WASM Heap
- **Thresholds**: 10MB (yellow), 20MB (red)
- **Purpose**: Monitor WebAssembly memory usage

### 3. SharedArrayBuffer Usage
- **Type**: Time series
- **Metrics**: `memx_sab_usage_percent`, `memx_sab_capacity_bytes`
- **Thresholds**: 80% (yellow), 95% (red)
- **Purpose**: Track audio ring buffer utilization

### 4. AudioWorklet Lag
- **Type**: Time series
- **Metrics**: `memx_worklet_lag_ms`, P95 Worklet Lag
- **Thresholds**: 50ms (yellow), 100ms (red)
- **Purpose**: Monitor audio processing latency

### 5. Memory Strain Events
- **Type**: Time series
- **Metrics**: `memx_memory_strain_percent`, Strain Events/sec
- **Thresholds**: 50% (yellow), 80% (red)
- **Purpose**: Track overall memory pressure

### 6. Frame Budget & Performance
- **Type**: Time series
- **Metrics**: `memx_frame_budget_ms`, `memx_dropped_frames_total`
- **Thresholds**: 16.67ms (yellow), 8.33ms (red)
- **Purpose**: Monitor rendering performance

### 7. Export & Session Metrics
- **Type**: Time series
- **Metrics**: Exports/sec, Session Duration, Session Frame Count
- **Purpose**: Track data export and session statistics

### 8. Strain Events Log
- **Type**: Logs panel
- **Query**: `{dataset="resonai_analytics"} |= "MEMX" |= "strain"`
- **Purpose**: View detailed strain event logs

### 9. OTel Integration Health
- **Type**: Stat panels
- **Metrics**: OTel Collector status, SigNoz status
- **Purpose**: Monitor infrastructure health

### 10. MEMX Error Rate
- **Type**: Stat panels
- **Metrics**: Errors/sec, Error Rate %
- **Thresholds**: 0.1/sec (yellow), 1/sec (red)
- **Purpose**: Track error rates

## Alert Rules

### Memory Alerts
- **High Memory Strain**: >80% for 5 minutes
- **Critical Memory Strain**: >95% for 2 minutes
- **WASM Heap Growth**: >20MB for 10 minutes

### Performance Alerts
- **SAB Backlog**: >90% for 3 minutes
- **AudioWorklet Lag**: >100ms for 5 minutes
- **Frame Drops**: >5% for 2 minutes

### Infrastructure Alerts
- **OTel Disconnect**: No metrics for 5 minutes
- **Session Stall**: No frames for 30 seconds
- **Cross-Origin Isolation**: Disabled for 1 minute

## Setup Instructions

### 1. Import Dashboard

```bash
# Copy dashboard JSON to SigNoz
curl -X POST http://localhost:8080/api/v1/dashboards \
  -H "Content-Type: application/json" \
  -d @signoz-memx-dashboard.json
```

### 2. Configure Alerts

```bash
# Import alert rules
curl -X POST http://localhost:8080/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d @signoz-memx-alerts.json
```

### 3. Set Up Notification Channels

Update the notification channels in `signoz-memx-alerts.json`:

```json
{
  "name": "memx-alerts",
  "type": "webhook",
  "settings": {
    "url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "title": "MEMX Alert",
    "text": "{{ .GroupLabels.alertname }}: {{ .Annotations.summary }}"
  }
}
```

### 4. Verify Metrics

Check that MEMX metrics are being received:

```bash
# Check for MEMX metrics
curl "http://localhost:8080/api/v1/query?query=memx_wasm_heap_bytes"

# Check for strain events
curl "http://localhost:8080/api/v1/query?query={dataset=\"resonai_analytics\"} |= \"MEMX\""
```

## Dashboard Features

### Templating
- **Time Range**: 5m, 15m, 1h, 6h, 24h
- **Browser Filter**: Filter by browser type
- **Auto-refresh**: 30 seconds

### Annotations
- **Deployments**: Mark deployment events
- **Strain Events**: Highlight strain events in logs

### Thresholds
- **Yellow**: Warning conditions
- **Red**: Critical conditions
- **Green**: Healthy conditions

## Monitoring Best Practices

### 1. Baseline Establishment
- Monitor for 24-48 hours to establish baselines
- Note peak usage patterns
- Identify normal strain levels

### 2. Alert Tuning
- Adjust thresholds based on observed patterns
- Set up escalation policies
- Test alert notifications

### 3. Performance Optimization
- Use P95/P99 percentiles for latency metrics
- Monitor trends over time
- Correlate with user experience metrics

### 4. Capacity Planning
- Track memory growth trends
- Plan for peak usage periods
- Set up capacity alerts

## Troubleshooting

### Common Issues

1. **No Metrics Appearing**
   - Check OTel collector health
   - Verify MEMX feature flag is enabled
   - Check browser console for errors

2. **Alerts Not Firing**
   - Verify alert rules are active
   - Check notification channel configuration
   - Test with manual alert triggers

3. **Dashboard Not Loading**
   - Check SigNoz service health
   - Verify dashboard JSON format
   - Check for metric name conflicts

### Debug Commands

```bash
# Check OTel collector status
curl http://localhost:13134/healthz

# Check SigNoz health
curl http://localhost:8080/api/v1/health

# List available metrics
curl "http://localhost:8080/api/v1/label/__name__/values"

# Check specific MEMX metrics
curl "http://localhost:8080/api/v1/query?query=memx_%7B%7D"
```

## Integration with CI/CD

### 1. Dashboard Validation
Add to CI pipeline to validate dashboard configuration:

```yaml
- name: Validate MEMX Dashboard
  run: |
    # Validate JSON format
    python -m json.tool signoz-memx-dashboard.json
    
    # Check for required panels
    grep -q "memx-overview" signoz-memx-dashboard.json
```

### 2. Alert Testing
Test alerts in staging environment:

```bash
# Trigger test alert
curl -X POST http://localhost:8080/api/v1/alerts/test \
  -H "Content-Type: application/json" \
  -d '{"alert_id": "memx-high-memory-strain"}'
```

### 3. Performance Monitoring
Monitor dashboard performance:

```bash
# Check dashboard load time
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:8080/dashboards/memx"
```

## Maintenance

### 1. Regular Updates
- Review and update thresholds monthly
- Add new metrics as MEMX evolves
- Update documentation with changes

### 2. Performance Optimization
- Optimize queries for better performance
- Use recording rules for expensive queries
- Monitor dashboard load times

### 3. Alert Management
- Review alert effectiveness quarterly
- Update runbook URLs
- Test notification channels regularly

## Support

For issues or questions:
1. Check SigNoz documentation
2. Review MEMX implementation logs
3. Check OTel collector status
4. Contact the observability team

## Next Steps

1. **Deploy Dashboard**: Import the dashboard configuration
2. **Configure Alerts**: Set up notification channels
3. **Establish Baselines**: Monitor for 24-48 hours
4. **Tune Thresholds**: Adjust based on observed patterns
5. **Integrate with CI/CD**: Add validation to pipeline
6. **Train Team**: Ensure team knows how to use the dashboard
