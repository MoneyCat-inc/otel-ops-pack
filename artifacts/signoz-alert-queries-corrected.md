# SigNoz Alert Queries - CORRECTED ClickHouse Format

## Alert 1: Windows Canary Log Absence Alert

**Alert Name**: Windows Canary Log Absence Alert  
**Description**: Alert when no canary logs are received for more than 5 minutes  
**Severity**: Critical  

### CORRECTED ClickHouse Query:
```sql
SELECT count() as canary_count
FROM signoz_logs
WHERE timestamp > now() - INTERVAL 5 MINUTE
  AND message LIKE '%windows-canary%'
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

### CORRECTED ClickHouse Query:
```sql
SELECT 
  (otelcol_exporter_queue_size / otelcol_exporter_queue_capacity) * 100 as queue_utilization
FROM signoz_metrics
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

### CORRECTED ClickHouse Query:
```sql
SELECT 
  ((otelcol_exporter_sent_spans - otelcol_exporter_send_failed_spans) / otelcol_exporter_sent_spans) * 100 as batch_efficiency
FROM signoz_metrics
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

### CORRECTED ClickHouse Query:
```sql
SELECT 
  histogram_quantile(0.95)(rate(otelcol_processor_batch_batch_send_size[5m])) as p95_latency_ms
FROM signoz_metrics
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

### CORRECTED ClickHouse Query:
```sql
SELECT 
  (otelcol_exporter_send_failed_spans / otelcol_exporter_sent_spans) * 100 as failure_rate
FROM signoz_metrics
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

## SIMPLIFIED QUERIES FOR TESTING

### Simple Canary Count Query:
```sql
SELECT count() as canary_count
FROM signoz_logs
WHERE message LIKE '%windows-canary%'
```

### Simple Log Count Query:
```sql
SELECT count() as log_count
FROM signoz_logs
WHERE timestamp > now() - INTERVAL 5 MINUTE
```

---

## Webhook Configuration

### CORRECTED Webhook URL:
```
http://127.0.0.1:3003/api/alerts/webhook
```

### Test the webhook:
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:3003/api/alerts/webhook" -Method Post -Body '{"test": "webhook test"}' -ContentType "application/json"
```
