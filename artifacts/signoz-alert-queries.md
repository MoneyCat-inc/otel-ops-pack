# SigNoz Alert Queries - ClickHouse Format

## Alert 1: Windows Canary Log Absence Alert

**Alert Name**: Windows Canary Log Absence Alert  
**Description**: Alert when no canary logs are received for more than 5 minutes  
**Severity**: Critical  

### ClickHouse Query:
```sql
SELECT count() as canary_count
FROM signoz_logs.logs
WHERE timestamp > now() - INTERVAL 5 MINUTE
  AND message LIKE '%windows-canary%'
  AND timestamp > toDateTime(now()) - INTERVAL 5 MINUTE
```

### Alert Condition:
- **Threshold**: 0
- **Operator**: equals
- **Duration**: 5 minutes

---

## Alert 2: Queue Pressure High Alert

**Alert Name**: Queue Pressure High Alert  
**Description**: Alert when queue utilization exceeds 70% for 10 minutes  
**Severity**: Warning  

### ClickHouse Query:
```sql
SELECT 
  (otelcol_exporter_queue_size / otelcol_exporter_queue_capacity) * 100 as queue_utilization
FROM signoz_metrics.metrics
WHERE timestamp > now() - INTERVAL 10 MINUTE
  AND metric_name = 'otelcol_exporter_queue_size'
ORDER BY timestamp DESC
LIMIT 1
```

### Alert Condition:
- **Threshold**: 70
- **Operator**: greater than
- **Duration**: 10 minutes

---

## Alert 3: Batch Processing Efficiency Low Alert

**Alert Name**: Batch Processing Efficiency Low Alert  
**Description**: Alert when batch efficiency drops below 95%  
**Severity**: Warning  

### ClickHouse Query:
```sql
SELECT 
  ((otelcol_exporter_sent_spans - otelcol_exporter_send_failed_spans) / otelcol_exporter_sent_spans) * 100 as batch_efficiency
FROM signoz_metrics.metrics
WHERE timestamp > now() - INTERVAL 5 MINUTE
  AND metric_name IN ('otelcol_exporter_sent_spans', 'otelcol_exporter_send_failed_spans')
ORDER BY timestamp DESC
LIMIT 1
```

### Alert Condition:
- **Threshold**: 95
- **Operator**: less than
- **Duration**: 5 minutes

---

## Alert 4: Processing Latency Spike Alert

**Alert Name**: Processing Latency Spike Alert  
**Description**: Alert when P95 latency exceeds 2 seconds  
**Severity**: Warning  

### ClickHouse Query:
```sql
SELECT 
  histogram_quantile(0.95)(rate(otelcol_processor_batch_batch_send_size[5m])) as p95_latency_ms
FROM signoz_metrics.metrics
WHERE timestamp > now() - INTERVAL 5 MINUTE
  AND metric_name = 'otelcol_processor_batch_batch_send_size'
ORDER BY timestamp DESC
LIMIT 1
```

### Alert Condition:
- **Threshold**: 2000 (2 seconds in milliseconds)
- **Operator**: greater than
- **Duration**: 5 minutes

---

## Alert 5: Send Failure Rate High Alert

**Alert Name**: Send Failure Rate High Alert  
**Description**: Alert when send failure rate exceeds 5%  
**Severity**: Critical  

### ClickHouse Query:
```sql
SELECT 
  (otelcol_exporter_send_failed_spans / otelcol_exporter_sent_spans) * 100 as failure_rate
FROM signoz_metrics.metrics
WHERE timestamp > now() - INTERVAL 5 MINUTE
  AND metric_name IN ('otelcol_exporter_send_failed_spans', 'otelcol_exporter_sent_spans')
ORDER BY timestamp DESC
LIMIT 1
```

### Alert Condition:
- **Threshold**: 5
- **Operator**: greater than
- **Duration**: 5 minutes

---

## Webhook Configuration

### Webhook URL Setup:
1. **Name**: OTel Alerts Webhook
2. **Type**: Webhook URL
3. **URL**: `http://localhost:3003/api/alerts/webhook` (or your webhook endpoint)
4. **Authentication**: Leave empty for now
5. **Send resolved alerts**: ✅ Check this box

### Webhook Payload Example:
```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "Windows Canary Log Absence Alert",
        "severity": "critical"
      },
      "annotations": {
        "description": "Alert when no canary logs are received for more than 5 minutes",
        "summary": "No canary logs detected in the last 5 minutes"
      },
      "startsAt": "2025-09-24T22:50:00Z",
      "endsAt": "0001-01-01T00:00:00Z"
    }
  ],
  "groupLabels": {
    "alertname": "Windows Canary Log Absence Alert"
  },
  "commonLabels": {
    "severity": "critical"
  },
  "commonAnnotations": {
    "description": "Alert when no canary logs are received for more than 5 minutes"
  },
  "externalURL": "http://localhost:8080",
  "version": "4",
  "groupKey": "{}:{alertname=\"Windows Canary Log Absence Alert\"}"
}
```

---

## Manual Alert Setup Instructions

### Step 1: Create Alert Rules in SigNoz UI
1. Go to **Alerts** → **Alert Rules**
2. Click **Create Alert Rule**
3. For each alert above:
   - **Name**: Use the alert name from above
   - **Query**: Copy the ClickHouse query
   - **Threshold**: Set the threshold value
   - **Operator**: Set the comparison operator
   - **Duration**: Set the evaluation duration
   - **Severity**: Set the severity level

### Step 2: Create Notification Channel
1. Go to **Alerts** → **Notification Channels**
2. Click **New Notification Channel**
3. **Name**: OTel Alerts Webhook
4. **Type**: Webhook URL
5. **URL**: Your webhook endpoint
6. **Send resolved alerts**: ✅ Check
7. **Test**: Send a test notification

### Step 3: Assign Notification Channel
1. Go back to your alert rules
2. Edit each alert rule
3. Add the notification channel you created
4. Save the alert rule

---

## Testing the Alerts

### Test Canary Alert:
```powershell
# Generate canary logs
pwsh -File scripts/test-canary-alert.ps1 -GenerateCanary -DurationMinutes 2

# Wait 5+ minutes, then stop canary logs
pwsh -File scripts/test-canary-alert.ps1 -StopCanary

# Check if alert triggers
pwsh -File scripts/test-canary-alert.ps1 -TestAlert
```

### Verify Alert in SigNoz:
1. Go to **Alerts** → **Alert Rules**
2. Check the status of your alert rules
3. Look for any firing alerts
4. Check the notification channel for webhook calls
