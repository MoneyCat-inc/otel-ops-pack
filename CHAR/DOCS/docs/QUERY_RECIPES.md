# SigNoz Query Recipes for OTel Monitoring

## MEMX Memory Monitoring

### MEMX Memory Strain Alert
**PromQL Query**:
```promql
resonai_memx_strain_pct{service_name="resonai-frontend"} > 80
```
**Description**: Alert when memory strain exceeds 80%
**Key Points**:
- **Metric**: `resonai_memx_strain_pct` - Memory strain percentage (0-100)
- **Service Filter**: `service_name="resonai-frontend"` - Filters to Resonai frontend
- **Threshold**: 80% - Configurable based on performance requirements
- **Use Case**: Proactive monitoring of browser memory pressure

**Alert Conditions**:
- Threshold: 80
- Operator: Greater than
- Duration: 2 minutes
- Frequency: 30 seconds

**Alert States**:
- Firing: `strain.pct > 80%` for 2 consecutive minutes
- Resolved: `strain.pct <= 80%` for 2 consecutive minutes

### MEMX WASM Heap Growth Alert
**PromQL Query**:
```promql
resonai_memx_wasm_heap_bytes{service_name="resonai-frontend"} > 50 * 1024 * 1024
```
**Description**: Alert when WASM heap exceeds 50MB
**Key Points**:
- **Metric**: `resonai_memx_wasm_heap_bytes` - WASM linear memory usage
- **Threshold**: 50MB - Configurable based on application needs
- **Use Case**: Monitor ONNX runtime memory consumption

### MEMX Worklet Lag Alert
**PromQL Query**:
```promql
histogram_quantile(0.95, sum(rate(resonai_memx_worklet_ui_lag_bucket[5m])) by (le)) > 50
```
**Description**: Alert when 95th percentile worklet lag exceeds 50ms
**Key Points**:
- **Metric**: `resonai_memx_worklet_ui_lag` - UI-to-AudioWorklet lag histogram
- **Percentile**: P95 - 95th percentile latency
- **Threshold**: 50ms - Audio processing latency threshold
- **Use Case**: Monitor audio processing performance

### MEMX SAB Utilization Monitoring
**PromQL Query**:
```promql
resonai_memx_sab_used_bytes{service_name="resonai-frontend"} / 
resonai_memx_sab_capacity_bytes{service_name="resonai-frontend"} * 100
```
**Description**: SharedArrayBuffer utilization percentage
**Key Points**:
- **Used**: `resonai_memx_sab_used_bytes` - Current SAB occupancy
- **Capacity**: `resonai_memx_sab_capacity_bytes` - Total SAB capacity
- **Calculation**: (used / capacity) * 100
- **Use Case**: Monitor audio ring buffer utilization

### MEMX Dashboard Queries

#### Memory Strain Trend
```promql
resonai_memx_strain_pct{service_name="resonai-frontend"}
```

#### WASM Heap Usage Over Time
```promql
resonai_memx_wasm_heap_bytes{service_name="resonai-frontend"}
```

#### Worklet Lag Percentiles
```promql
histogram_quantile(0.50, sum(rate(resonai_memx_worklet_ui_lag_bucket[5m])) by (le))
histogram_quantile(0.90, sum(rate(resonai_memx_worklet_ui_lag_bucket[5m])) by (le))
histogram_quantile(0.95, sum(rate(resonai_memx_worklet_ui_lag_bucket[5m])) by (le))
```

#### SAB Utilization Rate
```promql
rate(resonai_memx_sab_used_bytes{service_name="resonai-frontend"}[5m])
```

#### Memory Metrics Summary
```promql
# Memory strain
resonai_memx_strain_pct{service_name="resonai-frontend"}

# WASM heap
resonai_memx_wasm_heap_bytes{service_name="resonai-frontend"}

# SAB utilization
resonai_memx_sab_used_bytes{service_name="resonai-frontend"} / 
resonai_memx_sab_capacity_bytes{service_name="resonai-frontend"} * 100

# Worklet lag P95
histogram_quantile(0.95, sum(rate(resonai_memx_worklet_ui_lag_bucket[5m])) by (le))
```

## ECRR Compliance Monitoring

### ECRR Compliance Rate Alert
**ClickHouse Query**:
```sql
SELECT
  toStartOfMinute(fromUnixTimestamp64Nano(timestamp)) AS ts_minute,
  avg(JSONExtractFloat(body, 'compliance_rate')) AS compliance_rate
FROM signoz_logs.logs_v2
WHERE JSONExtractString(body, 'dataset') = 'ecrr_compliance'
  AND replaceAll(attributes_string['log.file.path'], '\\', '/') = 'C:/logs/ecrr/compliance-trends.log'
  AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 30 MINUTE
GROUP BY ts_minute
ORDER BY ts_minute DESC
LIMIT 10;
```
**Key Points**:
- **Table**: `signoz_logs.logs_v2` (SigNoz's actual logs table)
- **JSON extraction**: `JSONExtractFloat(body, 'compliance_rate')` extracts numeric values
- **Dataset filter**: `JSONExtractString(body, 'dataset')` filters by dataset
- **Path normalization**: `replaceAll(attributes_string['log.file.path'], '\\', '/')` handles Windows paths
- **Timestamp**: `fromUnixTimestamp64Nano(timestamp)` converts nanoseconds to datetime
- **Use case**: Log-based alerts when JSON payload is not parsed into attributes

**Optional Query Builder Path (after enabling JSON parsing)**:
- Data Source: Logs
- Aggregate: avg(`attributes.compliance_rate`)
- Filters:
  - `attributes.dataset = 'ecrr_compliance'`
  - `attributes['log.file.path']` equals `C:/logs/ecrr/compliance-trends.log`
- Note: Requires the `json_parser` operators outlined in `docs/SIGNOZ_ECRR_COMPLIANCE_ALERT_GUIDE.md`.

**Alert Conditions**:
- Threshold: 80
- Operator: Below
- Duration: 5 minutes
- Frequency: 1 minute

**Alert States**:
- Firing: `compliance_rate < 80%` for 5 consecutive minutes
- Resolved: `compliance_rate >= 80%` for 5 consecutive minutes

**Expected Behavior**:
- Current compliance: ~0.11% (alert fires immediately)
- Alert Name: ECRR Compliance Threshold Breach
- Severity: Warning
- Dataset: `ecrr_compliance`

**Verification**:
- SigNoz UI -> Alerts: confirm status shows Firing and evaluation values.
- SigNoz UI -> Logs -> ClickHouse: run the query above; verify rows with `compliance_rate` ~ 0.11.
- Notification channel: check that alert notifications arrive when the threshold is breached.

**Reference**: `docs/SIGNOZ_ECRR_COMPLIANCE_ALERT_GUIDE.md`

## Queue Pressure Monitoring

### Queue Utilization Ratio
```promql
otelcol_exporter_queue_size / otelcol_exporter_queue_capacity * 100
```
**Description**: Shows queue utilization as a percentage. Values > 80% indicate high pressure.



