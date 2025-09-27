# Manual Dashboard Import Guide
# Fractal Drift Monitors Dashboard for SigNoz

## Overview
This guide provides step-by-step instructions for manually importing the Fractal Drift Monitors dashboard into SigNoz when automated import fails.

## Dashboard Configuration
- **Name**: Fractal Drift Monitors
- **Description**: Queue pressure, send failure rates, and trace time-to-use monitoring for fractal drift detection
- **Version**: 1.0.0
- **Created**: 2025-01-27T06:58:00Z

## Manual Import Steps

### Step 1: Access SigNoz UI
1. Open your browser and navigate to: `http://localhost:8080`
2. If authentication is required, log in with your credentials
3. Navigate to **Dashboards** in the left sidebar

### Step 2: Create New Dashboard
1. Click **"New Dashboard"** or **"+"** button
2. Select **"Import Dashboard"** option
3. Choose **"Upload JSON file"** or **"Paste JSON"**

### Step 3: Import Dashboard JSON
Copy the following JSON configuration and paste it into the import dialog:

```json
{
  "title": "Fractal Drift Monitors",
  "description": "Queue pressure, send failure rates, and trace time-to-use monitoring for fractal drift detection",
  "version": "1.0.0",
  "created": "2025-01-27T06:58:00Z",
  "panels": [
    {
      "id": "queue-utilization-ratio",
      "title": "Queue Utilization Ratio",
      "type": "graph",
      "targets": [
        {
          "queryType": "promql",
          "expr": "otelcol_exporter_queue_size / otelcol_exporter_queue_capacity",
          "legendFormat": "Queue Utilization %"
        }
      ],
      "thresholds": [
        { "value": 0.7, "colorMode": "critical", "op": "gt" },
        { "value": 0.5, "colorMode": "warning", "op": "gt" }
      ]
    },
    {
      "id": "send-failure-rate",
      "title": "Send Failure Rate",
      "type": "graph",
      "targets": [
        {
          "queryType": "promql",
          "expr": "rate(otelcol_exporter_send_failed_spans_total[5m]) / rate(otelcol_exporter_sent_spans_total[5m])",
          "legendFormat": "Span Send Failure Rate"
        }
      ],
      "thresholds": [
        { "value": 0.05, "colorMode": "critical", "op": "gt" }
      ]
    },
    {
      "id": "trace-time-to-use",
      "title": "Trace Time-to-Use Latency",
      "type": "graph", 
      "targets": [
        {
          "queryType": "promql",
          "expr": "histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))",
          "legendFormat": "p95 Latency"
        }
      ],
      "thresholds": [
        { "value": 8, "colorMode": "critical", "op": "gt" }
      ]
    }
  ]
}
```

### Step 4: Configure Dashboard Settings
1. **Dashboard Name**: `Fractal Drift Monitors`
2. **Folder**: Create new folder `OTel Monitoring` or use existing
3. **Tags**: Add tags: `otel`, `fractal`, `drift`, `monitoring`, `queue`, `latency`
4. **Time Range**: Set default to `Last 1 hour`
5. **Refresh Interval**: Set to `5s`

### Step 5: Save and Verify
1. Click **"Import"** or **"Save"**
2. Verify the dashboard appears in your dashboard list
3. Click on the dashboard to open it
4. Verify all three panels are visible:
   - Queue Utilization Ratio
   - Send Failure Rate
   - Trace Time-to-Use Latency

## Panel Configuration Details

### Panel 1: Queue Utilization Ratio
- **Query**: `otelcol_exporter_queue_size / otelcol_exporter_queue_capacity`
- **Thresholds**: 
  - Critical: > 70%
  - Warning: > 50%
- **Purpose**: Monitor queue pressure and batch processing efficiency

### Panel 2: Send Failure Rate
- **Query**: `rate(otelcol_exporter_send_failed_spans_total[5m]) / rate(otelcol_exporter_sent_spans_total[5m])`
- **Threshold**: Critical: > 5%
- **Purpose**: Monitor exporter connectivity and SigNoz health

### Panel 3: Trace Time-to-Use Latency
- **Query**: `histogram_quantile(0.95, rate(otelcol_processor_batch_timeout_trigger_sent_duration_bucket[5m]))`
- **Threshold**: Critical: > 8 seconds
- **Purpose**: Monitor batch processor performance and network latency

## Troubleshooting

### Common Issues
1. **No Data**: Ensure OTel Collector is running and sending metrics
2. **Query Errors**: Verify metric names match your OTel Collector version
3. **Authentication**: Ensure you have proper permissions to create dashboards

### Verification Commands
```powershell
# Check OTel Collector status
Get-Service otelcol-contrib

# Check SigNoz health
curl -s http://localhost:8080/api/v1/health

# Check if metrics are available
curl -s "http://localhost:8080/api/v1/query?query=otelcol_exporter_queue_size"
```

## Next Steps
After successful import:
1. Set up alert rules for each panel
2. Configure notification channels
3. Test dashboard functionality with canary logs
4. Share dashboard with team members

## Support
If you encounter issues:
1. Check SigNoz logs: `docker logs signoz`
2. Verify OTel Collector configuration
3. Test metric queries in SigNoz UI
4. Review dashboard JSON syntax

---
**Created by**: Cursor-Local (Observability Copilot)  
**Date**: 2025-01-27  
**Version**: 1.0.0
