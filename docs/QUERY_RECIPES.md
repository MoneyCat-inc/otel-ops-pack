# SigNoz Query Recipes for OTel Monitoring

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



