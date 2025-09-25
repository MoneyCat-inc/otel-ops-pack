# SigNoz Queue Pressure Dashboard Guide

## Overview

The SigNoz Queue Pressure Dashboard provides comprehensive monitoring of OpenTelemetry collector queue performance and pressure indicators. This dashboard helps identify bottlenecks, capacity issues, and performance degradation in the observability pipeline.

## Dashboard Components

### Key Metrics Monitored

1. **Queue Size vs Capacity**
   - `otelcol_exporter_queue_size` - Current items in export queue
   - `otelcol_exporter_queue_capacity` - Maximum queue capacity
   - **Purpose**: Monitor queue utilization and capacity planning

2. **Queue Utilization Percentage**
   - Calculated as: `(queue_size / queue_capacity) * 100`
   - **Thresholds**: 
     - Green: <70%
     - Yellow: 70-90%
     - Red: >90%

3. **Enqueue Failures**
   - `otelcol_exporter_enqueue_failed_log_records`
   - `otelcol_exporter_enqueue_failed_metric_points`
   - **Purpose**: Detect when items cannot be added to the queue

4. **Batch Processing Performance**
   - `otelcol_processor_batch_batch_size_trigger_send`
   - `otelcol_processor_batch_timeout_trigger_send`
   - **Purpose**: Monitor batching efficiency and timeout triggers

5. **Send Success Rate**
   - Calculated from sent vs failed metrics
   - **Purpose**: Overall pipeline health indicator

6. **Memory Pressure**
   - `otelcol_process_memory_rss`
   - **Purpose**: Detect memory-related performance issues

## Installation

### Prerequisites
- SigNoz running on `http://localhost:8080`
- OpenTelemetry collector configured with queue metrics
- PowerShell 7.0+ for automation scripts

### Quick Setup

1. **Import Dashboard Configuration**:
   ```powershell
   pwsh -File scripts/import-queue-pressure-dashboard.ps1 -TestMetrics
   ```

2. **Manual Import in SigNoz UI**:
   - Navigate to: `http://localhost:8080` → Dashboards → New Dashboard
   - Dashboard Name: "OTel Queue Pressure Monitoring"
   - Add panels using the queries from `signoz-queue-pressure-dashboard.json`

3. **Configure Alerts**:
   - High Queue Utilization (>90% for 5m)
   - Queue Enqueue Failures (>0 for 2m)
   - Low Send Success Rate (<95% for 5m)
   - High Memory Usage (>1GB for 5m)

## Dashboard Panels

### Panel 1: Queue Size vs Capacity
- **Type**: Time Series Graph
- **Queries**: 
  - `otelcol_exporter_queue_size`
  - `otelcol_exporter_queue_capacity`
- **Purpose**: Visualize queue utilization over time

### Panel 2: Queue Utilization %
- **Type**: Stat Panel
- **Query**: `(otelcol_exporter_queue_size / otelcol_exporter_queue_capacity) * 100`
- **Purpose**: Quick overview of queue pressure

### Panel 3: Enqueue Failures
- **Type**: Stat Panel
- **Query**: `rate(otelcol_exporter_enqueue_failed_log_records[5m]) + rate(otelcol_exporter_enqueue_failed_metric_points[5m])`
- **Purpose**: Monitor queue admission failures

### Panel 4: Batch Processing Performance
- **Type**: Time Series Graph
- **Queries**:
  - `rate(otelcol_processor_batch_batch_size_trigger_send[5m])`
  - `rate(otelcol_processor_batch_timeout_trigger_send[5m])`
- **Purpose**: Monitor batching efficiency

### Panel 5: Send Success Rate
- **Type**: Stat Panel
- **Query**: Complex calculation of success rate
- **Purpose**: Overall pipeline health

### Panel 6: Memory Pressure
- **Type**: Stat Panel
- **Query**: `otelcol_process_memory_rss / 1024 / 1024`
- **Purpose**: Monitor memory usage

### Panel 7: Queue Pressure Heatmap
- **Type**: Heatmap
- **Query**: `histogram_quantile(0.95, rate(otelcol_processor_batch_batch_send_size.bucket[5m]))`
- **Purpose**: Visualize batch size distribution

### Panel 8: Queue Health Status Table
- **Type**: Table
- **Purpose**: Tabular view of key metrics

## Alert Configuration

### Critical Alerts

1. **High Queue Utilization**
   - **Condition**: Queue utilization > 90% for 5 minutes
   - **Severity**: Critical
   - **Action**: Immediate investigation required

2. **Queue Enqueue Failures**
   - **Condition**: Any enqueue failures for 2 minutes
   - **Severity**: Warning
   - **Action**: Check collector configuration and capacity

### Warning Alerts

3. **Low Send Success Rate**
   - **Condition**: Success rate < 95% for 5 minutes
   - **Severity**: Warning
   - **Action**: Investigate network or SigNoz connectivity

4. **High Memory Usage**
   - **Condition**: Memory usage > 1GB for 5 minutes
   - **Severity**: Warning
   - **Action**: Check for memory leaks or high load

## Troubleshooting

### Common Issues

1. **Missing Metrics**
   - **Symptom**: Panels show "No data"
   - **Solution**: Verify collector configuration includes queue metrics
   - **Check**: Run `scripts/import-queue-pressure-dashboard.ps1 -TestMetrics`

2. **High Queue Utilization**
   - **Symptom**: Queue utilization consistently > 90%
   - **Solutions**:
     - Increase `queue_size` in collector config
     - Increase `num_consumers` for parallel processing
     - Check SigNoz ingestion capacity

3. **Enqueue Failures**
   - **Symptom**: Non-zero enqueue failure rates
   - **Solutions**:
     - Check queue capacity settings
     - Verify memory limits
     - Check for processing bottlenecks

4. **Memory Pressure**
   - **Symptom**: High memory usage
   - **Solutions**:
     - Adjust `memory_limiter` settings
     - Reduce batch sizes
     - Check for memory leaks

### Configuration Tuning

#### Collector Configuration (`config.yaml`)
```yaml
exporters:
  otlp/sigz:
    sending_queue:
      storage: file_storage
      queue_size: 5000        # Increase for higher throughput
      num_consumers: 4        # Increase for parallel processing

processors:
  memory_limiter:
    check_interval: 2s
    limit_percentage: 80      # Adjust based on system capacity
    spike_limit_percentage: 25
```

## Monitoring Best Practices

1. **Baseline Establishment**
   - Monitor queue metrics during normal operation
   - Establish baseline utilization patterns
   - Set appropriate alert thresholds

2. **Capacity Planning**
   - Monitor queue utilization trends
   - Plan capacity increases before hitting limits
   - Consider seasonal or usage pattern variations

3. **Performance Optimization**
   - Use batch processing metrics to optimize batch sizes
   - Monitor timeout triggers to adjust batch timeouts
   - Balance memory usage vs processing efficiency

4. **Alert Management**
   - Set up escalation procedures for critical alerts
   - Regular review of alert effectiveness
   - Document response procedures

## Files Created

- `signoz-queue-pressure-dashboard.json` - Dashboard configuration
- `scripts/import-queue-pressure-dashboard.ps1` - Import automation script
- `docs/QUEUE_PRESSURE_DASHBOARD_GUIDE.md` - This documentation

## Related Documentation

- [SigNoz UI Setup Guide](SIGNOZ_UI_SETUP_GUIDE.md)
- [Monitoring Setup Guide](MONITORING_SETUP_GUIDE.md)
- [OTel Collector Configuration](config.yaml)

## Support

For issues with the queue pressure dashboard:
1. Check SigNoz health: `http://localhost:8080/api/v1/health`
2. Verify collector metrics: Run the test script
3. Review collector logs for errors
4. Check SigNoz ingestion capacity

---

**Last Updated**: 2025-09-24  
**Version**: 1.0.0  
**Status**: Production Ready
