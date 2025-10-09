# SigNoz ECRR Compliance Alert Configuration Guide

## Overview
This guide provides step-by-step instructions for configuring a SigNoz log-based alert to monitor ECRR compliance rates and trigger notifications when compliance drops below 80% for 5 minutes.

## Prerequisites
- SigNoz instance running and accessible
- ECRR compliance monitoring script generates logs in `C:/logs/ecrr/compliance-trends.log`
- Log entries contain JSON fields including `dataset="ecrr_compliance"` and `compliance_rate`

## Alert Configuration Steps

### 1. Navigate to SigNoz Alerts
1. Open SigNoz UI (typically `http://localhost:8080`).
2. Go to **Alerts -> New Alert**.
3. Select **Logs Based Alert**.

### 2. Configure Query
**Recommended: ClickHouse query**
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
- **Table**: `signoz_logs.logs_v2` (not `logs`)
- **JSON extraction**: `JSONExtractFloat(body, 'compliance_rate')` (not `json.compliance_rate`)
- **Dataset filter**: `JSONExtractString(body, 'dataset')` (not `json.dataset`)
- **Path normalization**: `replaceAll(attributes_string['log.file.path'], '\\', '/')` handles Windows path separators
- **Timestamp handling**: `fromUnixTimestamp64Nano(timestamp)` converts nanoseconds to datetime

**Optional: Enable Query Builder (requires JSON parsing in the collector)**
1. Edit `C:/otel/config.yaml` under `filelog/canary` to parse JSON and promote keys to attributes:
   ```yaml
   filelog/canary:
     include:
       - C:/logs/**/**/*.log
     start_at: end
     include_file_path: true
     include_file_name: true
     poll_interval: 200ms
     operators:
       - type: json_parser
         parse_from: body
       - type: move
         from: attributes.compliance_rate
         to: attributes['compliance_rate']
       - type: move
         from: attributes.dataset
         to: attributes['dataset']
   ```
2. Restart the Windows collector: `Restart-Service otelcol-contrib` (PowerShell with admin rights).
3. After restart, the SigNoz Query Builder can target `attributes.compliance_rate` and filter on `attributes.dataset` and `attributes['log.file.path']` without custom SQL.

### 3. Set Alert Conditions
- **Evaluate**: Use the query result (Query A).
- **Condition**: Below.
- **Threshold**: 80 (percent).
- **Match Type**: all the times (or on average, depending on noise tolerance).
- **For**: 5 minutes.
- **Evaluation Frequency**: 1 minute.
- **Missing data notification**: Enable if the compliance script should emit continuously.
- **Minimum data points**: 3 (guards against sparse samples).

### 4. Configure Alert Metadata
- **Severity**: Warning.
- **Name**: ECRR Compliance Threshold Breach.
- **Description**: Alert when ECRR compliance rate drops below 80% for 5 consecutive minutes.
- **Labels**:
  - `service=ecrr-compliance`
  - `dataset=ecrr_compliance`
  - `component=monitoring`

### 5. Set Up Notifications
1. Choose a notification channel (Slack, Email, Webhook, etc.).
2. Send a test notification to verify delivery.
3. Save the alert to activate it.

## Verification Steps

### 1. Preview Data
Use SigNoz **Logs -> ClickHouse** tab and run:
```sql
SELECT
  toFloat32(JSONExtractFloat(body, 'compliance_rate')) AS compliance_rate,
  JSONExtractString(body, 'dataset') AS dataset,
  replaceAll(attributes_string['log.file.path'], '\\', '/') AS log_path,
  fromUnixTimestamp64Nano(timestamp) AS event_time
FROM signoz_logs.logs_v2
WHERE JSONExtractString(body, 'dataset') = 'ecrr_compliance'
ORDER BY timestamp DESC
LIMIT 5;
```
Expected: Rows show `compliance_rate` near the latest value (e.g., 0.11) with `log_path` equal to `C:/logs/ecrr/compliance-trends.log`.

### 2. Test Alert Trigger
Generate a sample with low compliance to confirm the alert fires:
```powershell
pwsh -File scripts/monitor-ecrr-compliance-trends.ps1 -GenerateReport
```
The alert should enter the Firing state within 1-2 evaluation intervals because the sample rate is 0.11% (<80%).

### 3. Monitor Alert Status
- **Alerts dashboard**: Verify the alert status (Active/Firing) and recent evaluation values.
- **Alert history**: Review trigger and recovery timestamps.
- **Notification logs**: Confirm upstream channels received the event.

## Expected Behavior
- **Current sample**: compliance rate ~0.11% (below threshold).
- **Alert status after creation**: Firing.
- **Recovery condition**: compliance rate must remain >=80% for 5 consecutive minutes.

## Troubleshooting
1. **"Unknown table expression identifier 'logs'"**
   - Root cause: SigNoz stores log data in `signoz_logs.logs_v2`; the `logs` alias does not exist.
   - Fix: Use the fully-qualified table name in your query (`FROM signoz_logs.logs_v2`).
2. **Empty results**
   - Confirm the log file exists and contains fresh JSON entries.
   - Ensure the dataset filter uses `JSONExtractString(body, 'dataset') = 'ecrr_compliance'`.
   - Remove or adjust the time window (`now() - INTERVAL ...`) if you expect older data.
3. **Alert never fires**
   - Check that the threshold is set to 80 and match type is `all the times`.
   - Verify the evaluation window is 5 minutes and minimum data points is 3.
   - Confirm notification channels are enabled and not muted.

## Data Validation
```powershell
# Confirm the log file contains recent JSON entries
Get-Content C:/logs/ecrr/compliance-trends.log -Tail 5

# Check the scheduled task that generates the compliance data
Get-ScheduledTaskInfo -TaskName 'ECRR Compliance Monitoring'
```

## Integration with ECRR Workflow
- **Automated monitoring**: Scheduled task appends to `C:/logs/ecrr/compliance-trends.log` every 30 minutes and emits Application Event ID 4100.
- **Dashboards**: The SigNoz ECRR Compliance dashboard references the same dataset and query.
- **Trend tracking**: Historical compliance rates stay accessible in SigNoz for comparisons and audits.

## Next Steps
1. Save the alert using the query above.
2. Generate a compliance sample below 80% to validate alert firing.
3. Document the alert in `docs/QUERY_RECIPES.md` (already updated) and `docs/ECRR_PROJECT_REPORT.md` as needed.
4. Configure additional notifications or escalation paths if required.

## Queue Monitoring Integration

### Agent Queue Telemetry
The agent queue system emits structured telemetry to `C:\logs\queue\health.log` for SigNoz monitoring.

#### Data Pipeline
| Source Files | Processing | Output | SigNoz Filter | Query Target |
|--------------|------------|--------|---------------|--------------|
| `.agent/agent_queue.json`, `.agent/state.json` | PowerShell script -> `C:/logs/queue/health.log` | `filelog/canary` | Logs -> `message` contains `"dataset":"agent_queue"` | `signoz_logs.logs_v2` |

#### Telemetry Emission
```powershell
# Manual emission (scheduled task runs automatically every minute)
pwsh -File scripts/observability/emit-queue-telemetry.ps1 -RepoRoot . -OutputPath C:\logs\queue\health.log
```

#### SigNoz UI Navigation
UI -> Logs -> Explorer -> filter `log.file.path contains "C:/logs/queue/health.log"`

#### Queue Metrics Dashboard
**SigNoz Query for Queue Depth Trends:**
```sql
SELECT 
  toStartOfMinute(fromUnixTimestamp64Nano(timestamp)) AS ts,
  avg(JSONExtractInt(message, 'queueLength')) AS avg_queue_depth,
  avg(JSONExtractInt(message, 'readyCount')) AS avg_ready_count,
  avg(JSONExtractInt(message, 'pendingCount')) AS avg_pending_count,
  any(JSONExtractBool(message, 'killSwitch')) AS kill_switch_active
FROM signoz_logs.logs_v2
WHERE message LIKE '%"dataset":"agent_queue"%'
  AND attributes_string['log.file.path'] LIKE '%C:/logs/queue/health.log%'
  AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 1 HOUR
GROUP BY ts
ORDER BY ts DESC;
```

**Verification Query - Count Queue Telemetry:**
```sql
SELECT count(*) FROM signoz_logs.logs_v2 
WHERE message LIKE '%"dataset":"agent_queue"%' 
AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 1 HOUR;
```

**Verification Query - Current Queue Depth:**
```sql
SELECT avg(JSONExtractInt(message, 'queueLength')) AS queue_depth 
FROM signoz_logs.logs_v2 
WHERE message LIKE '%"dataset":"agent_queue"%' 
AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE;
```

#### Queue Health Alerts
**High Queue Depth Alert:**
```sql
SELECT 
  JSONExtractInt(message, 'queueLength') AS queue_length,
  JSONExtractString(message, 'agentName') AS agent_name,
  fromUnixTimestamp64Nano(timestamp) AS alert_time
FROM signoz_logs.logs_v2
WHERE message LIKE '%"dataset":"agent_queue"%'
  AND JSONExtractInt(message, 'queueLength') > 50
  AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE;
```

**Kill Switch Activated Alert:**
```sql
SELECT 
  JSONExtractString(message, 'agentName') AS agent_name,
  fromUnixTimestamp64Nano(timestamp) AS alert_time
FROM signoz_logs.logs_v2
WHERE message LIKE '%"dataset":"agent_queue"%'
  AND JSONExtractBool(message, 'killSwitch') = true
  AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE;
```

**Stuck Jobs Alert:**
```sql
SELECT 
  JSONExtractString(message, 'agentName') AS agent_name,
  JSONExtractString(message, 'lastRun') AS last_run,
  fromUnixTimestamp64Nano(timestamp) AS alert_time
FROM signoz_logs.logs_v2
WHERE message LIKE '%"dataset":"agent_queue"%'
  AND JSONExtractString(message, 'lastRun') < toString(now() - INTERVAL 30 MINUTE)
  AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 5 MINUTE;
```

#### Per-Lane Monitoring
**Lane Performance Dashboard:**
```sql
SELECT 
  JSONExtractString(message, 'lanes') AS lanes_data,
  fromUnixTimestamp64Nano(timestamp) AS ts
FROM signoz_logs.logs_v2
WHERE message LIKE '%"dataset":"agent_queue"%'
  AND fromUnixTimestamp64Nano(timestamp) >= now() - INTERVAL 1 HOUR
ORDER BY ts DESC
LIMIT 100;
```

### Queue Monitoring Setup
1. **Schedule Telemetry Emission**: Set up a scheduled task to run every minute:
   ```powershell
   # Create scheduled task for queue telemetry
   $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File C:\otel\scripts\observability\emit-queue-telemetry.ps1 -RepoRoot C:\otel"
   $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 365)
   Register-ScheduledTask -TaskName "AgentQueueTelemetry" -Action $action -Trigger $trigger -User "SYSTEM"
   ```

2. **Configure Collector**: Ensure `C:/otel/config.yaml` includes queue log processing:
   ```yaml
   filelog/queue:
     include:
       - C:/logs/queue/*.log
     start_at: end
     include_file_path: true
     operators:
       - type: json_parser
         parse_from: body
         output: body
   ```

## Related Documentation
- `docs/ECRR_COMPLIANCE_DEPLOYMENT_GUIDE.md`
- `docs/SIGNOZ_DASHBOARD_IMPORT_GUIDE.md`
- `scripts/monitor-ecrr-compliance-trends.ps1`
- `scripts/observability/emit-queue-telemetry.ps1`
- `alerts/ecrr-compliance-threshold.json`



