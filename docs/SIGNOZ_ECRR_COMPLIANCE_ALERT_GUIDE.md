# SigNoz ECRR Compliance Alert Guide

**Purpose**: SigNoz alert configuration for Queue Steward ECRR compliance monitoring.

**Scope**: Alert rules, dashboards, and queries to ensure Queue Steward operates within ECRR guardrails.

---

## Alert Rules Configuration

### 1. Queue Depth Critical Alert

**Alert Name**: `queue-depth-critical`
**Severity**: Critical
**Query**:
```sql
SELECT 
  max(JSON_EXTRACT(body, '$.queueLength')) as max_queue_depth
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 5 MINUTES
GROUP BY toStartOfMinute(timestamp)
HAVING max_queue_depth > 200
```

**Threshold**: `max_queue_depth > 200`
**Duration**: 15 minutes
**Action**: Page on-call engineer

### 2. Queue Depth Warning Alert

**Alert Name**: `queue-depth-warning`
**Severity**: Warning
**Query**:
```sql
SELECT 
  max(JSON_EXTRACT(body, '$.queueLength')) as max_queue_depth
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 5 MINUTES
GROUP BY toStartOfMinute(timestamp)
HAVING max_queue_depth > 100
```

**Threshold**: `max_queue_depth > 100`
**Duration**: 10 minutes
**Action**: Slack notification

### 3. Error Rate Alert

**Alert Name**: `queue-error-rate-critical`
**Severity**: Critical
**Query**:
```sql
SELECT 
  countIf(JSON_EXTRACT(body, '$.lastError') IS NOT NULL) as error_count,
  count() as total_count,
  error_count / total_count as error_rate
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 5 MINUTES
GROUP BY toStartOfMinute(timestamp)
HAVING error_rate > 0.10
```

**Threshold**: `error_rate > 0.10` (10%)
**Duration**: 10 minutes
**Action**: Page on-call engineer

### 4. Processing Stall Alert

**Alert Name**: `queue-processing-stall`
**Severity**: Critical
**Query**:
```sql
SELECT 
  count() as jobs_processed
FROM logs 
WHERE dataset = 'agent_queue'
  AND JSON_EXTRACT(body, '$.jobsProcessed') > 0
  AND timestamp > now() - INTERVAL 15 MINUTES
GROUP BY toStartOfMinute(timestamp)
HAVING jobs_processed = 0
```

**Threshold**: `jobs_processed = 0`
**Duration**: 15 minutes
**Action**: Page on-call engineer

### 5. Kill Switch Active Alert

**Alert Name**: `queue-kill-switch-active`
**Severity**: Warning
**Query**:
```sql
SELECT 
  JSON_EXTRACT(body, '$.killSwitch') as kill_switch_active
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 MINUTE
HAVING kill_switch_active = true
```

**Threshold**: `kill_switch_active = true`
**Duration**: 1 minute
**Action**: Slack notification

---

## Dashboard Panels

### Queue Health Overview Panel

**Panel Title**: Queue Health Overview
**Query**:
```sql
SELECT 
  timestamp,
  JSON_EXTRACT(body, '$.queueLength') as queue_length,
  JSON_EXTRACT(body, '$.readyCount') as ready_count,
  JSON_EXTRACT(body, '$.running') as running_jobs,
  JSON_EXTRACT(body, '$.jobsProcessed') as jobs_processed,
  JSON_EXTRACT(body, '$.killSwitch') as kill_switch
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
LIMIT 100
```

**Visualization**: Time series graph
**Metrics**: queue_length, ready_count, running_jobs, jobs_processed

### Error Rate Trend Panel

**Panel Title**: Error Rate Trend
**Query**:
```sql
SELECT 
  toStartOfMinute(timestamp) as minute,
  countIf(JSON_EXTRACT(body, '$.lastError') IS NOT NULL) as error_count,
  count() as total_count,
  error_count / total_count as error_rate
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 24 HOUR
GROUP BY minute
ORDER BY minute DESC
```

**Visualization**: Time series graph
**Metrics**: error_rate (percentage)

### Processing Rate Panel

**Panel Title**: Jobs Processed Per Minute
**Query**:
```sql
SELECT 
  toStartOfMinute(timestamp) as minute,
  max(JSON_EXTRACT(body, '$.jobsProcessed')) as jobs_processed
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 24 HOUR
GROUP BY minute
ORDER BY minute DESC
```

**Visualization**: Time series graph
**Metrics**: jobs_processed

---

## Compliance Monitoring Queries

### ECRR Gate Compliance Check

**Query Name**: ECRR Gate Status
**Purpose**: Verify Queue Steward operates within ECRR guardrails
**Query**:
```sql
SELECT 
  timestamp,
  JSON_EXTRACT(body, '$.queueLength') as queue_length,
  JSON_EXTRACT(body, '$.killSwitch') as kill_switch,
  JSON_EXTRACT(body, '$.lastError') as last_error,
  CASE 
    WHEN queue_length < 50 AND kill_switch = false AND last_error IS NULL 
    THEN 'ECRR_COMPLIANT'
    ELSE 'ECRR_VIOLATION'
  END as ecrr_status
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
```

**Expected Result**: All rows should show `ECRR_COMPLIANT`

### Shadow vs Canonical Verification

**Query Name**: Shadow Canonical Drift Detection
**Purpose**: Monitor for drift between shadow and canonical writes
**Query**:
```sql
SELECT 
  timestamp,
  JSON_EXTRACT(body, '$.shadowMode') as shadow_mode,
  JSON_EXTRACT(body, '$.driver') as driver,
  CASE 
    WHEN shadow_mode = false AND driver = 'sqlite' 
    THEN 'CANONICAL_MODE'
    WHEN shadow_mode = true 
    THEN 'SHADOW_MODE'
    ELSE 'MIXED_MODE'
  END as mode_status
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
```

**Expected Result**: All rows should show `CANONICAL_MODE`

### Performance Budget Compliance

**Query Name**: Performance Budget Check
**Purpose**: Verify jobs complete within performance budgets
**Query**:
```sql
SELECT 
  timestamp,
  JSON_EXTRACT(body, '$.queueLength') as queue_length,
  JSON_EXTRACT(body, '$.p95JobMs') as p95_job_ms,
  CASE 
    WHEN queue_length < 100 AND p95_job_ms < 300000 
    THEN 'BUDGET_COMPLIANT'
    ELSE 'BUDGET_EXCEEDED'
  END as budget_status
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
```

**Expected Result**: All rows should show `BUDGET_COMPLIANT`

---

## Alert Configuration Steps

### 1. Create Alert Rules

1. Navigate to SigNoz UI: http://localhost:8080
2. Go to **Alerts** -> **Create Alert**
3. For each alert above:
   - Copy the query
   - Set the threshold and duration
   - Configure notification channels (Slack, PagerDuty, etc.)

### 2. Create Dashboard

1. Go to **Dashboards** -> **Create Dashboard**
2. Add panels using the queries above
3. Configure visualization types and refresh intervals
4. Save as "Queue Steward ECRR Compliance"

### 3. Set Up Notifications

**Slack Integration**:
- Channel: `#queue-steward-alerts`
- Severity mapping:
  - Critical: `@channel` mention
  - Warning: No mention

**PagerDuty Integration**:
- Service: Queue Steward
- Escalation policy: Engineering Team
- Severity mapping:
  - Critical: P1 incident
  - Warning: P2 incident

---

## Compliance Checklist

### Daily Checks

- [ ] Queue depth < 100 (warning threshold)
- [ ] Error rate < 5%
- [ ] Jobs processing steadily
- [ ] Kill switch remains false
- [ ] Canonical mode active (shadow mode off)

### Weekly Reviews

- [ ] Review alert history and false positives
- [ ] Update thresholds based on workload patterns
- [ ] Verify ECRR compliance queries return expected results
- [ ] Test alert notification channels

### Monthly Audits

- [ ] Review dashboard performance and relevance
- [ ] Update compliance queries as system evolves
- [ ] Document any threshold adjustments
- [ ] Verify backup and recovery procedures

---

## Troubleshooting Alert Issues

### Common Problems

1. **Alerts not firing**: Check query syntax and data availability
2. **False positives**: Adjust thresholds based on historical data
3. **Missing data**: Verify collector and SigNoz connectivity
4. **Notification failures**: Test Slack/PagerDuty integrations

### Debug Queries

**Check Data Availability**:
```sql
SELECT 
  count() as log_count,
  min(timestamp) as earliest,
  max(timestamp) as latest
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
```

**Verify Alert Query Logic**:
```sql
SELECT 
  timestamp,
  JSON_EXTRACT(body, '$.queueLength') as queue_length,
  queue_length > 200 as exceeds_threshold
FROM logs 
WHERE dataset = 'agent_queue'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
LIMIT 10
```

---

**Last Updated**: 2025-09-30  
**Maintainer**: Observability Copilot  
**Related**: `docs/QUEUE_STEWARD_OPERATOR_QUICK_REFERENCE.md`