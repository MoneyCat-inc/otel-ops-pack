# SigNoz Dashboard Import Guide

## Overview
This guide provides step-by-step instructions for importing the OTel Queue Pressure Dashboard into SigNoz.

## Prerequisites
- SigNoz running on http://localhost:8080
- Admin access to SigNoz UI
- Dashboard configuration file: `artifacts/signoz-queue-pressure-dashboard.json`

## Manual Import Steps

### 1. Access SigNoz Dashboard Management
1. Open browser: http://localhost:8080
2. Navigate to **Dashboards** in the left sidebar
3. Click **Import Dashboard** button

### 2. Import Queue Pressure Dashboard
1. Click **Upload JSON file**
2. Select file: `C:\otel\artifacts\signoz-queue-pressure-dashboard.json`
3. Click **Import**
4. Verify dashboard name: "OTel Queue Pressure Monitor"

### 3. Configure Dashboard Settings
1. **Title**: OTel Queue Pressure Monitor
2. **Description**: Monitor OpenTelemetry collector queue utilization and pressure indicators
3. **Tags**: otel, queue, pressure, monitoring
4. **Timezone**: Browser
5. **Refresh**: 30s (recommended)

### 4. Verify Panels
The dashboard should contain 5 panels:

#### Panel 1: Queue Utilization Ratio
- **Type**: Stat
- **Query**: `otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100`
- **Unit**: Percent
- **Thresholds**: Green (<70%), Yellow (70-90%), Red (>90%)

#### Panel 2: Queue Size vs Capacity
- **Type**: Time Series
- **Query**: `otelcol_exporter_queue_size` and `otelcol_exporter_queue_capacity`
- **Legend**: Queue Size, Queue Capacity

#### Panel 3: Send Failure Rate
- **Type**: Stat
- **Query**: `rate(otelcol_exporter_send_failed_log_records[5m])`
- **Unit**: Percent
- **Thresholds**: Green (<5%), Yellow (5-10%), Red (>10%)

#### Panel 4: Batch Timeout Triggers
- **Type**: Time Series
- **Query**: `rate(otelcol_processor_batch_timeout_trigger_send[5m])`
- **Legend**: Timeout Triggers/sec

#### Panel 5: Log Processing Rate
- **Type**: Time Series
- **Query**: `rate(otelcol_receiver_accepted_log_records[5m])`
- **Legend**: Logs/sec

### 5. Configure Alerts (Optional)
1. Navigate to **Alerts** → **New Alert**
2. Create alerts for:
   - Queue utilization > 80% for 5 minutes
   - Send failure rate > 10% for 2 minutes
   - Batch timeout triggers > 1/sec for 1 minute

## Troubleshooting

### Common Issues
1. **Import fails**: Check JSON file validity
2. **Panels show no data**: Verify OTel collector metrics are available
3. **Queries fail**: Check metric names and availability
4. **Dashboard not visible**: Check permissions and refresh

### Verification Commands
```powershell
# Check if metrics are available
curl http://localhost:8888/metrics | Select-String "otelcol_exporter_queue_size"

# Test SigNoz API access
curl -H "Authorization: Bearer $env:SIGNOZ_API_TOKEN" http://localhost:8080/api/v1/metrics
```

### Manual Panel Creation
If import fails, create panels manually:

1. **Add Panel** → **Query**
2. **Data Source**: Prometheus
3. **Query**: Use queries from `docs/QUERY_RECIPES.md`
4. **Visualization**: Select appropriate type (Stat, Time Series)
5. **Field**: Configure units and thresholds

## Query Recipes Reference

### Queue Utilization
```promql
otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100
```

### Send Failure Rate
```promql
rate(otelcol_exporter_send_failed_log_records[5m])
```

### Batch Timeout Triggers
```promql
rate(otelcol_processor_batch_timeout_trigger_send[5m])
```

### Log Processing Rate
```promql
rate(otelcol_receiver_accepted_log_records[5m])
```

## Next Steps
1. Verify dashboard displays data correctly
2. Configure alert thresholds
3. Set up notification channels
4. Test alert delivery
5. Monitor queue pressure patterns
