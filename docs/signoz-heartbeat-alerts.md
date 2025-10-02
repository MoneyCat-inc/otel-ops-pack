# SigNoz Heartbeat Alert Rules

## Overview
This document provides SigNoz alert rules for monitoring the Production Agent System heartbeat and implementing automated remediation for hung daemons.

## Alert Rules

### 1. Heartbeat Alert Detection
**Rule Name**: `Production Agent Heartbeat Alert`
**Query**: 
```sql
SELECT * FROM signoz_logs.logs_v2 
WHERE attributes['type'] = 'heartbeat_alert' 
AND attributes['system'] = 'production-agent-system'
AND timestamp >= now() - INTERVAL 1 MINUTE
```

**Alert Condition**: 
- Trigger when any heartbeat alert is detected
- Severity: `WARNING`
- Notification: Send to monitoring team

### 2. Hung Daemon Detection
**Rule Name**: `Production Agent Hung Daemon`
**Query**:
```sql
SELECT * FROM signoz_logs.logs_v2 
WHERE attributes['type'] = 'heartbeat_alert' 
AND attributes['system'] = 'production-agent-system'
AND attributes['details.ageSeconds'] > 300
AND timestamp >= now() - INTERVAL 5 MINUTES
```

**Alert Condition**:
- Trigger when heartbeat age exceeds 5 minutes (300 seconds)
- Severity: `CRITICAL`
- Notification: Send to on-call team
- Auto-remediation: Trigger daemon restart

### 3. Heartbeat Age Monitoring
**Rule Name**: `Production Agent Heartbeat Age`
**Query**:
```sql
SELECT 
  attributes['heartbeat.ageSeconds'] as age_seconds,
  attributes['heartbeat.status'] as status,
  timestamp
FROM signoz_logs.logs_v2 
WHERE attributes['system'] = 'production-agent-system'
AND attributes['heartbeat.ageSeconds'] IS NOT NULL
AND timestamp >= now() - INTERVAL 1 MINUTE
```

**Alert Condition**:
- Warning when heartbeat age > 60 seconds
- Critical when heartbeat age > 180 seconds
- Severity: `WARNING` / `CRITICAL`

## Dashboard Panels

### Heartbeat Status Panel
**Panel Type**: Time Series
**Query**:
```sql
SELECT 
  timestamp,
  attributes['heartbeat.ageSeconds'] as age_seconds
FROM signoz_logs.logs_v2 
WHERE attributes['system'] = 'production-agent-system'
AND attributes['heartbeat.ageSeconds'] IS NOT NULL
ORDER BY timestamp DESC
LIMIT 100
```

### Alert History Panel
**Panel Type**: Table
**Query**:
```sql
SELECT 
  timestamp,
  attributes['level'] as level,
  attributes['message'] as message,
  attributes['details.pid'] as pid,
  attributes['details.ageSeconds'] as age_seconds
FROM signoz_logs.logs_v2 
WHERE attributes['type'] = 'heartbeat_alert'
AND attributes['system'] = 'production-agent-system'
ORDER BY timestamp DESC
LIMIT 50
```

## Automated Remediation

### Webhook Integration
**Endpoint**: `http://localhost:8080/api/v1/alerts/webhook`
**Payload**:
```json
{
  "alerts": [
    {
      "status": "firing",
      "labels": {
        "alertname": "Production Agent Hung Daemon",
        "severity": "critical",
        "system": "production-agent-system"
      },
      "annotations": {
        "summary": "Production Agent daemon appears hung",
        "description": "Heartbeat age exceeds 5 minutes"
      }
    }
  ]
}
```

### Remediation Actions
1. **Immediate**: Send notification to on-call team
2. **Automated**: Trigger daemon restart script
3. **Escalation**: If restart fails, escalate to engineering team

## Implementation Steps

1. **Create Alert Rules** in SigNoz UI
2. **Configure Webhook** for automated remediation
3. **Set up Dashboard** panels for monitoring
4. **Test Alert Rules** with simulated hung daemon
5. **Verify Remediation** works correctly

## Monitoring Commands

```bash
# Check current heartbeat status
pnpm agent:status-system

# View recent alerts in SigNoz
# Navigate to: http://localhost:8080/alerts

# Check OTel metrics log
Get-Content C:/logs/queue/health.log -Tail 10

# Test alert by stopping daemon
pnpm agent:stop
# Wait 5+ minutes, then check SigNoz alerts
```

## Troubleshooting

### Common Issues
1. **Alerts not firing**: Check query syntax and log format
2. **Webhook not working**: Verify endpoint URL and payload format
3. **False positives**: Adjust alert thresholds based on system behavior

### Debug Commands
```bash
# Check SigNoz logs for heartbeat data
curl -s "http://localhost:8080/api/v1/logs?query=system%3Dproduction-agent-system" | jq

# Verify alert rules are active
curl -s "http://localhost:8080/api/v1/alerts" | jq
```

---

## 🚨 **Recovery Failure Alert Templates**

### **Remediation Failure Detection**

SigNoz can detect when automated remediation actions fail by monitoring the `remediation_failure` log events:

#### **Query for Remediation Failures**
```sql
SELECT 
    timestamp,
    level,
    message,
    details.action,
    details.reason,
    details.exitCode,
    details.errorMessage
FROM signoz_logs.logs_v2 
WHERE 
    type = 'remediation_failure'
    AND timestamp >= now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
```

#### **Alert Rule: Remediation Action Failed**
```yaml
alert: RemediationActionFailed
expr: |
  count(
    rate(signoz_logs_logs_v2{type="remediation_failure"}[5m])
  ) > 0
for: 0m
labels:
  severity: critical
  system: production-agent-system
  component: remediation
annotations:
  summary: "Automated remediation action failed"
  description: "Remediation action {{ $labels.action }} failed with exit code {{ $labels.exitCode }}"
  runbook_url: "https://docs.example.com/runbooks/remediation-failure"
```

#### **Alert Rule: Multiple Remediation Failures**
```yaml
alert: MultipleRemediationFailures
expr: |
  count(
    rate(signoz_logs_logs_v2{type="remediation_failure"}[10m])
  ) > 2
for: 2m
labels:
  severity: critical
  system: production-agent-system
  component: remediation
annotations:
  summary: "Multiple remediation failures detected"
  description: "More than 2 remediation failures in the last 10 minutes"
  runbook_url: "https://docs.example.com/runbooks/multiple-failures"
```

#### **Alert Rule: Daemon Start Failure**
```yaml
alert: DaemonStartFailure
expr: |
  count(
    signoz_logs_logs_v2{type="remediation_failure", details_action="start"}
  ) > 0
for: 0m
labels:
  severity: critical
  system: production-agent-system
  component: daemon
annotations:
  summary: "Daemon start failure"
  description: "Automated daemon start failed - manual intervention required"
  runbook_url: "https://docs.example.com/runbooks/daemon-start-failure"
```

#### **Alert Rule: Health Check Failure After Restart**
```yaml
alert: HealthCheckFailureAfterRestart
expr: |
  count(
    signoz_logs_logs_v2{type="remediation_failure", details_action="restart", details_exitCode="3"}
  ) > 0
for: 0m
labels:
  severity: critical
  system: production-agent-system
  component: health-check
annotations:
  summary: "Health check failed after daemon restart"
  description: "Daemon restarted but health check failed - system may be unstable"
  runbook_url: "https://docs.example.com/runbooks/health-check-failure"
```

### **Dashboard Panel: Remediation Failures**

Add this panel to your Production Agent System dashboard:

```json
{
  "title": "Remediation Failures",
  "type": "table",
  "targets": [
    {
      "expr": "SELECT timestamp, details.action, details.exitCode, details.errorMessage FROM signoz_logs.logs_v2 WHERE type = 'remediation_failure' AND timestamp >= now() - INTERVAL 24 HOUR ORDER BY timestamp DESC LIMIT 10",
      "format": "table"
    }
  ],
  "fieldConfig": {
    "defaults": {
      "custom": {
        "displayMode": "list",
        "filterable": true
      }
    }
  }
}
```

### **Recovery Failure Runbook**

#### **Exit Code Reference**
- **Exit Code 1**: Daemon stop failure or daemon not running
- **Exit Code 2**: Daemon start failure or health check failure after start
- **Exit Code 3**: Health check failure after restart
- **Exit Code 4**: Unknown action or invalid parameters

#### **Manual Recovery Steps**
1. **Check daemon status**: `pnpm agent:status-system`
2. **Check logs**: `Get-Content C:\logs\queue\health.log -Tail 20`
3. **Manual restart**: `pnpm agent:stop && pnpm agent:start`
4. **Force kill if needed**: `Get-Process -Name node | Stop-Process -Force`
5. **Verify health**: `pnpm agent:health`

---

## 🔐 **Webhook Security Configuration**

### **Environment Variables**
Set these environment variables for webhook authentication:

```bash
# Webhook secret for SigNoz
export SIGNOZ_WEBHOOK_SECRET="your-secure-webhook-secret-here"

# Auth header for additional security
export SIGNOZ_WEBHOOK_AUTH="Bearer your-auth-token-here"
```

### **Webhook Handler with Authentication**
```bash
# Enable authentication validation
pwsh -File scripts/agent/webhook-handler.ps1 -ValidateAuth -Secret "your-secret" -AuthHeader "Bearer token"
```

### **SigNoz Webhook Configuration**
```yaml
webhook_configs:
  - url: 'http://localhost:8080/api/v1/webhooks/production-agent'
    send_resolved: true
    http_config:
      basic_auth:
        username: 'webhook'
        password: 'your-webhook-secret'
    headers:
      Authorization: 'Bearer your-auth-token'
```
