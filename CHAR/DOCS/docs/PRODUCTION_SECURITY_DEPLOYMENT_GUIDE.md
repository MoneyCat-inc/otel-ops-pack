# 🔐 Production Security Deployment Guide

## Environment Variables Setup

### **Required Environment Variables**

Set these environment variables on your SigNoz server before enabling webhook authentication:

```bash
# Webhook secret for SigNoz → Production Agent webhooks
export SIGNOZ_WEBHOOK_SECRET="prod-agent-webhook-secret-2025"

# Auth header for additional security layer
export SIGNOZ_WEBHOOK_AUTH="Bearer prod-agent-auth-token-2025"
```

### **Windows Environment Setup**

For Windows systems, set these in PowerShell:

```powershell
# Set environment variables (current session)
$env:SIGNOZ_WEBHOOK_SECRET = "prod-agent-webhook-secret-2025"
$env:SIGNOZ_WEBHOOK_AUTH = "Bearer prod-agent-auth-token-2025"

# Set environment variables (permanent)
[Environment]::SetEnvironmentVariable("SIGNOZ_WEBHOOK_SECRET", "prod-agent-webhook-secret-2025", "Machine")
[Environment]::SetEnvironmentVariable("SIGNOZ_WEBHOOK_AUTH", "Bearer prod-agent-auth-token-2025", "Machine")
```

### **Docker/Container Setup**

For containerized SigNoz deployments, add to your docker-compose.yml:

```yaml
services:
  signoz-frontend:
    environment:
      - SIGNOZ_WEBHOOK_SECRET=prod-agent-webhook-secret-2025
      - SIGNOZ_WEBHOOK_AUTH=Bearer prod-agent-auth-token-2025
```

### **Kubernetes Setup**

For Kubernetes deployments, create a secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: signoz-webhook-secrets
type: Opaque
data:
  webhook-secret: cHJvZC1hZ2VudC13ZWJob29rLXNlY3JldC0yMDI1  # base64 encoded
  webhook-auth: QmVhcmVyIHByb2QtYWdlbnQtYXV0aC10b2tlbi0yMDI1  # base64 encoded
```

Then reference in your deployment:

```yaml
spec:
  containers:
  - name: signoz-frontend
    env:
    - name: SIGNOZ_WEBHOOK_SECRET
      valueFrom:
        secretKeyRef:
          name: signoz-webhook-secrets
          key: webhook-secret
    - name: SIGNOZ_WEBHOOK_AUTH
      valueFrom:
        secretKeyRef:
          name: signoz-webhook-secrets
          key: webhook-auth
```

## SigNoz Webhook Configuration

### **Webhook Endpoint Configuration**

Configure SigNoz to send webhooks to your Production Agent System:

```yaml
# SigNoz alertmanager configuration
webhook_configs:
  - url: 'http://localhost:8080/api/v1/webhooks/production-agent'
    send_resolved: true
    http_config:
      basic_auth:
        username: 'webhook'
        password: 'prod-agent-webhook-secret-2025'
    headers:
      Authorization: 'Bearer prod-agent-auth-token-2025'
      Content-Type: 'application/json'
    title: 'Production Agent Alert'
    text: |
      Alert: {{ .GroupLabels.alertname }}
      Status: {{ .Status }}
      Severity: {{ .GroupLabels.severity }}
      
      {{ range .Alerts }}
      Summary: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
```

### **Alert Rules Configuration**

Import these alert rules into SigNoz:

```yaml
groups:
  - name: production-agent-system
    rules:
      # Heartbeat monitoring
      - alert: ProductionAgentHungDaemon
        expr: |
          count(
            signoz_logs_logs_v2{type="heartbeat_alert"}
          ) > 0
        for: 0m
        labels:
          severity: critical
          system: production-agent-system
          component: heartbeat
        annotations:
          summary: "Production Agent daemon appears hung"
          description: "Heartbeat age exceeds 5 minutes - automated restart triggered"
          runbook_url: "https://docs.example.com/runbooks/hung-daemon"
      
      # Remediation failure monitoring
      - alert: RemediationActionFailed
        expr: |
          count(
            signoz_logs_logs_v2{type="remediation_failure"}
          ) > 0
        for: 0m
        labels:
          severity: critical
          system: production-agent-system
          component: remediation
        annotations:
          summary: "Automated remediation action failed"
          description: "Remediation action failed - manual intervention may be required"
          runbook_url: "https://docs.example.com/runbooks/remediation-failure"
      
      # Multiple failures
      - alert: MultipleRemediationFailures
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

## Security Testing

### **Test Authentication**

```bash
# Test with correct credentials
pwsh -File scripts/agent/webhook-handler.ps1 -ValidateAuth -Secret "prod-agent-webhook-secret-2025" -AuthHeader "Bearer prod-agent-auth-token-2025"

# Test with incorrect credentials (should fail)
pwsh -File scripts/agent/webhook-handler.ps1 -ValidateAuth -Secret "wrong-secret" -AuthHeader "Bearer wrong-token"

# Test without authentication (should work)
pwsh -File scripts/agent/webhook-handler.ps1 -Action process
```

### **Verify Environment Variables**

```bash
# Check if environment variables are set
echo $SIGNOZ_WEBHOOK_SECRET
echo $SIGNOZ_WEBHOOK_AUTH

# Test webhook handler with environment variables
pwsh -File scripts/agent/webhook-handler.ps1 -ValidateAuth
```

## Production Deployment Checklist

- [ ] Set `SIGNOZ_WEBHOOK_SECRET` environment variable
- [ ] Set `SIGNOZ_WEBHOOK_AUTH` environment variable
- [ ] Configure SigNoz webhook endpoint with authentication
- [ ] Import alert rules for heartbeat and remediation failures
- [ ] Test webhook authentication in staging environment
- [ ] Monitor authentication logs in production
- [ ] Set up alert escalation procedures
- [ ] Document manual recovery procedures
- [ ] Train team on security procedures

## Security Best Practices

1. **Rotate Secrets Regularly**: Change webhook secrets monthly
2. **Monitor Access**: Log all webhook authentication attempts
3. **Use HTTPS**: Always use HTTPS for webhook endpoints in production
4. **Network Security**: Restrict webhook access to trusted networks
5. **Audit Logs**: Regularly review authentication and remediation logs
6. **Backup Procedures**: Document manual recovery procedures
7. **Incident Response**: Have procedures for security incidents

## Troubleshooting

### **Common Issues**

1. **Environment Variables Not Set**: Check with `echo $SIGNOZ_WEBHOOK_SECRET`
2. **Authentication Failures**: Verify secret and auth header match
3. **Webhook Not Working**: Check SigNoz webhook configuration
4. **Alerts Not Firing**: Verify alert rules are imported and active

### **Debug Commands**

```bash
# Check webhook handler logs
Get-Content C:\logs\queue\health.log -Tail 20 | Select-String "webhook"

# Check remediation logs
Get-Content C:\logs\queue\health.log -Tail 20 | Select-String "remediation"

# Test webhook endpoint
curl -X POST http://localhost:8080/api/v1/webhooks/production-agent \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer prod-agent-auth-token-2025" \
  -d @test-webhook-payload.json
```

## Next Steps

1. **Deploy Environment Variables**: Set secrets on SigNoz server
2. **Configure Webhooks**: Update SigNoz webhook configuration
3. **Import Alert Rules**: Add heartbeat and remediation failure alerts
4. **Test Authentication**: Verify webhook authentication works
5. **Run Failure Drill**: Test end-to-end alerting and remediation
6. **Monitor Operations**: Track authentication and remediation logs
7. **Tune Thresholds**: Adjust alert thresholds based on system behavior
