# Alert Thresholds & Notifications Guide

## Overview

The Alert Thresholds & Notifications system provides comprehensive alerting capabilities for the observability pipeline. It includes automated threshold management, multi-channel notifications, escalation procedures, and comprehensive testing capabilities.

## System Components

### 1. Alert Threshold Manager (`scripts/alert-threshold-manager.ps1`)
Comprehensive alert threshold configuration and management:

- **Threshold Categories**: Performance, Error, Availability, Security, Business
- **Severity Levels**: Info, Warning, Critical, Emergency
- **Escalation Policies**: Default, Security, Business
- **Configuration Management**: Export/Import capabilities
- **Validation**: Threshold validation and recommendations

### 2. Notification Manager (`scripts/notification-manager.ps1`)
Multi-channel notification delivery system:

- **Notification Channels**: Email, Slack, Teams, Webhook, PagerDuty
- **Templates**: Default, Critical, Emergency templates
- **Escalation Handling**: Severity-based template selection
- **Delivery Tracking**: Success/failure tracking
- **Testing**: Channel testing and validation

### 3. Escalation Manager (`scripts/alert-escalation-manager.ps1`)
Automated escalation procedures:

- **Escalation Policies**: Default, Security, Business policies
- **Escalation Levels**: Warning → Critical → Emergency
- **Timing**: Configurable escalation durations
- **Actions**: Notify, Log, Escalate, Page, Incident
- **Tracking**: Escalation history and status

### 4. Testing System (`scripts/alert-testing-system.ps1`)
Comprehensive alert system testing:

- **Test Types**: Thresholds, Notifications, Escalations, Integration
- **Test Categories**: Performance, Error, Availability, Security, Business
- **Automated Testing**: Automated test execution
- **Reporting**: Detailed test reports and recommendations

## Alert Threshold Categories

### Performance Alerts
**Purpose**: Monitor system and application performance metrics

| Alert Name | Threshold | Duration | Severity | Description |
|------------|-----------|----------|----------|-------------|
| High CPU Usage | >80% | 5m | Warning | CPU usage exceeds threshold |
| High Memory Usage | >1GB | 3m | Warning | Memory usage exceeds threshold |
| Slow Response Time | >2000ms | 5m | Warning | Average response time exceeds threshold |
| High Error Rate | >5% | 5m | Critical | Error rate exceeds acceptable threshold |

**Example Configuration**:
```json
{
  "name": "High CPU Usage",
  "description": "CPU usage exceeds threshold for sustained period",
  "query": "otelcol_process_cpu_seconds > 0.8",
  "threshold": 0.8,
  "operator": ">",
  "duration": "5m",
  "severity": "warning",
  "escalation": {
    "warning": "5m",
    "critical": "10m",
    "emergency": "15m"
  }
}
```

### Error Alerts
**Purpose**: Monitor application and system errors

| Alert Name | Threshold | Duration | Severity | Description |
|------------|-----------|----------|----------|-------------|
| Application Errors | >10 | 2m | Warning | Application error rate exceeds threshold |
| Database Errors | >5 | 1m | Critical | Database connection or query errors |
| Parser Errors | >0 | 1m | Critical | Log parsing errors detected |
| Network Errors | >3 | 2m | Warning | Network connectivity errors |

**Example Configuration**:
```json
{
  "name": "Application Errors",
  "description": "Application error rate exceeds threshold",
  "query": "count by (service.name) (level=\"ERROR\" and service.name != \"canary-test\") > 10",
  "threshold": 10,
  "operator": ">",
  "duration": "2m",
  "severity": "warning",
  "escalation": {
    "warning": "2m",
    "critical": "5m",
    "emergency": "10m"
  }
}
```

### Availability Alerts
**Purpose**: Monitor service availability and health

| Alert Name | Threshold | Duration | Severity | Description |
|------------|-----------|----------|----------|-------------|
| Service Down | =0 | 1m | Critical | Service is not responding |
| Canary Failure | =0 | 2m | Warning | Canary tests are failing or stopped |
| Queue Full | >90% | 1m | Critical | Export queue is at capacity |
| Ingestion Stalled | =0 | 5m | Critical | Log ingestion has stopped |

**Example Configuration**:
```json
{
  "name": "Service Down",
  "description": "Service is not responding",
  "query": "count by (service.name) (service.name != \"canary-test\") == 0",
  "threshold": 0,
  "operator": "==",
  "duration": "1m",
  "severity": "critical",
  "escalation": {
    "warning": "1m",
    "critical": "2m",
    "emergency": "5m"
  }
}
```

### Security Alerts
**Purpose**: Monitor security events and threats

| Alert Name | Threshold | Duration | Severity | Description |
|------------|-----------|----------|----------|-------------|
| Authentication Failures | >5 | 2m | Warning | High rate of authentication failures |
| Suspicious Activity | >0 | 1m | Critical | Suspicious activity detected |
| Privilege Escalation | >0 | 1m | Emergency | Privilege escalation attempt detected |
| Data Exfiltration | >0 | 1m | Emergency | Potential data exfiltration attempt |

**Example Configuration**:
```json
{
  "name": "Authentication Failures",
  "description": "High rate of authentication failures",
  "query": "count by (service.name) (message contains \"authentication\" and level=\"ERROR\") > 5",
  "threshold": 5,
  "operator": ">",
  "duration": "2m",
  "severity": "warning",
  "escalation": {
    "warning": "2m",
    "critical": "5m",
    "emergency": "10m"
  }
}
```

### Business Alerts
**Purpose**: Monitor business-critical metrics

| Alert Name | Threshold | Duration | Severity | Description |
|------------|-----------|----------|----------|-------------|
| Transaction Failures | >10 | 5m | Warning | High rate of transaction failures |
| Payment Failures | >5 | 2m | Critical | Payment processing failures |
| User Experience Degradation | >5000ms | 10m | Warning | User experience metrics degraded |
| Revenue Impact | >0 | 1m | Emergency | Revenue-impacting issues detected |

**Example Configuration**:
```json
{
  "name": "Transaction Failures",
  "description": "High rate of transaction failures",
  "query": "count by (service.name) (message contains \"transaction\" and level=\"ERROR\") > 10",
  "threshold": 10,
  "operator": ">",
  "duration": "5m",
  "severity": "warning",
  "escalation": {
    "warning": "5m",
    "critical": "10m",
    "emergency": "15m"
  }
}
```

## Notification Channels

### Email Notifications
**Configuration**:
```json
{
  "name": "Email Notifications",
  "type": "email",
  "config": {
    "smtp_server": "localhost",
    "smtp_port": 587,
    "username": "alerts@company.com",
    "password": "secure_password",
    "from_address": "alerts@company.com",
    "to_addresses": ["ops-team@company.com", "oncall@company.com"],
    "use_ssl": true
  }
}
```

**Template Example**:
```
Subject: [CRITICAL] High CPU Usage - test

Alert Notification
=================

Alert Name: High CPU Usage
Severity: CRITICAL
Environment: test
Description: CPU usage exceeds threshold for sustained period
Timestamp: 2024-01-01 10:00:00
Current Value: 85
Threshold: 80
Query: otelcol_process_cpu_seconds > 0.8

Escalation Level: critical
Notification ID: notif-20240101-100000

Please investigate this alert promptly.

Best regards,
Observability Team
```

### Slack Notifications
**Configuration**:
```json
{
  "name": "Slack Notifications",
  "type": "slack",
  "config": {
    "webhook_url": "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK",
    "channel": "#alerts",
    "username": "SigNoz Alerts",
    "icon_emoji": ":warning:"
  }
}
```

**Template Example**:
```
🚨 *High CPU Usage*
Severity: *CRITICAL*
Environment: test
Description: CPU usage exceeds threshold for sustained period
Current Value: 85
Threshold: 80
Time: 2024-01-01 10:00:00
Escalation: critical
```

### Microsoft Teams Notifications
**Configuration**:
```json
{
  "name": "Microsoft Teams Notifications",
  "type": "teams",
  "config": {
    "webhook_url": "https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK"
  }
}
```

**Template Example**:
```
**Alert Notification**

**Alert:** High CPU Usage
**Severity:** CRITICAL
**Environment:** test
**Description:** CPU usage exceeds threshold for sustained period
**Current Value:** 85
**Threshold:** 80
**Time:** 2024-01-01 10:00:00
**Escalation:** critical
```

### Webhook Notifications
**Configuration**:
```json
{
  "name": "Webhook Notifications",
  "type": "webhook",
  "config": {
    "url": "https://your-webhook-endpoint.com/alerts",
    "method": "POST",
    "headers": {
      "Content-Type": "application/json",
      "Authorization": "Bearer your-token"
    }
  }
}
```

**Payload Example**:
```json
{
  "alert_name": "High CPU Usage",
  "severity": "CRITICAL",
  "environment": "test",
  "description": "CPU usage exceeds threshold for sustained period",
  "timestamp": "2024-01-01 10:00:00",
  "current_value": "85",
  "threshold": "80",
  "escalation_level": "critical",
  "notification_id": "notif-20240101-100000"
}
```

### PagerDuty Notifications
**Configuration**:
```json
{
  "name": "PagerDuty Notifications",
  "type": "pagerduty",
  "config": {
    "integration_key": "your-pagerduty-integration-key",
    "severity_mapping": {
      "info": "info",
      "warning": "warning",
      "critical": "critical",
      "emergency": "critical"
    }
  }
}
```

**Payload Example**:
```json
{
  "routing_key": "your-pagerduty-integration-key",
  "event_action": "trigger",
  "dedup_key": "High CPU Usage-test-20240101-100000",
  "payload": {
    "summary": "High CPU Usage",
    "source": "SigNoz",
    "severity": "CRITICAL",
    "custom_details": {
      "description": "CPU usage exceeds threshold for sustained period",
      "environment": "test",
      "query": "otelcol_process_cpu_seconds > 0.8",
      "current_value": "85",
      "threshold": "80",
      "escalation_level": "critical"
    }
  }
}
```

## Escalation Procedures

### Default Escalation Policy
**Purpose**: Standard escalation procedure for all alerts

| Level | Duration | Channels | Recipients | Actions | Next Level |
|-------|----------|----------|------------|---------|------------|
| Warning | 5m | Email, Slack | Ops Team, On-call Engineer | Notify, Log | Critical |
| Critical | 10m | Email, Slack, Teams, PagerDuty | Ops Team, On-call Engineer, Senior Engineer | Notify, Log, Escalate | Emergency |
| Emergency | 15m | All Channels | All Recipients | Notify, Log, Escalate, Page | None |

### Security Escalation Policy
**Purpose**: Escalation procedure for security-related alerts

| Level | Duration | Channels | Recipients | Actions | Next Level |
|-------|----------|----------|------------|---------|------------|
| Warning | 2m | Email, Slack | Security Team, Ops Team | Notify, Log, Escalate | Critical |
| Critical | 5m | Email, Slack, Teams, PagerDuty | Security Team, Ops Team, Senior Engineer, Security Lead | Notify, Log, Escalate, Page | Emergency |
| Emergency | 10m | All Channels | Security Team, Ops Team, Senior Engineer, Security Lead, Management, CISO | Notify, Log, Escalate, Page, Incident | None |

### Business Escalation Policy
**Purpose**: Escalation procedure for business-critical alerts

| Level | Duration | Channels | Recipients | Actions | Next Level |
|-------|----------|----------|------------|---------|------------|
| Warning | 3m | Email, Slack | Business Team, Ops Team | Notify, Log | Critical |
| Critical | 5m | Email, Slack, Teams, PagerDuty | Business Team, Ops Team, Product Manager | Notify, Log, Escalate | Emergency |
| Emergency | 10m | All Channels | Business Team, Ops Team, Product Manager, Management, CEO | Notify, Log, Escalate, Page, Incident | None |

## Usage Examples

### Configure Alert Thresholds
```powershell
# Configure all alert thresholds
.\scripts\alert-threshold-manager.ps1 -Action "configure" -AlertType "all"

# Configure performance alerts only
.\scripts\alert-threshold-manager.ps1 -Action "configure" -AlertType "performance" -Severity "warning"

# Export alert configuration
.\scripts\alert-threshold-manager.ps1 -Action "export" -AlertType "all"
```

### Test Notification Channels
```powershell
# Test all notification channels
.\scripts\notification-manager.ps1 -Action "test" -Channel "all" -TestMode

# Test specific channel
.\scripts\notification-manager.ps1 -Action "test" -Channel "slack" -EscalationLevel "critical"

# Send test notification
.\scripts\notification-manager.ps1 -Action "send" -Channel "email" -AlertData $alertData
```

### Execute Escalation Procedures
```powershell
# Execute escalation for alert
.\scripts\alert-escalation-manager.ps1 -Action "escalate" -AlertId "alert-123" -EscalationLevel "critical"

# Test escalation policy
.\scripts\alert-escalation-manager.ps1 -Action "test" -EscalationLevel "emergency" -TestMode

# Get escalation status
.\scripts\alert-escalation-manager.ps1 -Action "status"
```

### Run Comprehensive Tests
```powershell
# Run all alert tests
.\scripts\alert-testing-system.ps1 -TestType "all" -TestMode

# Test specific alert category
.\scripts\alert-testing-system.ps1 -TestType "thresholds" -AlertCategory "performance"

# Test notification channels
.\scripts\alert-testing-system.ps1 -TestType "notifications" -Channel "slack" -Severity "critical"
```

## Testing Framework

### Test Types

#### Threshold Testing
- **Purpose**: Validate alert threshold logic
- **Tests**: Threshold evaluation, operator logic, duration validation
- **Categories**: Performance, Error, Availability, Security, Business
- **Output**: Pass/fail results with detailed error information

#### Notification Testing
- **Purpose**: Validate notification channel functionality
- **Tests**: Channel connectivity, message delivery, template rendering
- **Channels**: Email, Slack, Teams, Webhook, PagerDuty
- **Output**: Delivery status, response times, error details

#### Escalation Testing
- **Purpose**: Validate escalation procedures
- **Tests**: Escalation timing, channel selection, action execution
- **Policies**: Default, Security, Business
- **Output**: Escalation flow validation, timing verification

#### Integration Testing
- **Purpose**: Validate system integration
- **Tests**: SigNoz connectivity, collector health, notification channels
- **Components**: SigNoz, Collector, Notification Channels, Escalation System
- **Output**: Component health status, integration validation

### Test Execution

#### Automated Testing
```powershell
# Run comprehensive test suite
.\scripts\alert-testing-system.ps1 -TestType "all" -TestMode

# Test specific components
.\scripts\alert-testing-system.ps1 -TestType "thresholds" -AlertCategory "performance"
.\scripts\alert-testing-system.ps1 -TestType "notifications" -Channel "slack"
.\scripts\alert-testing-system.ps1 -TestType "escalations" -Severity "critical"
.\scripts\alert-testing-system.ps1 -TestType "integration"
```

#### Manual Testing
```powershell
# Test individual components
.\scripts\alert-threshold-manager.ps1 -Action "test" -Severity "critical" -TestMode
.\scripts\notification-manager.ps1 -Action "test" -Channel "all" -TestMode
.\scripts\alert-escalation-manager.ps1 -Action "test" -EscalationLevel "emergency" -TestMode
```

### Test Reports

#### Report Structure
```json
{
  "timestamp": "2024-01-01 10:00:00",
  "testId": "test-20240101-100000",
  "testType": "all",
  "alertCategory": "all",
  "severity": "all",
  "channel": "all",
  "testMode": true,
  "summary": {
    "total_tests": 25,
    "passed_tests": 23,
    "failed_tests": 2,
    "success_rate": "92.0%"
  },
  "details": [...],
  "recommendations": [...]
}
```

#### Report Analysis
- **Success Rate**: Overall test success percentage
- **Failed Tests**: Detailed failure analysis
- **Recommendations**: Actionable improvement suggestions
- **Trends**: Historical test performance

## Configuration Management

### Alert Threshold Configuration
```json
{
  "name": "High CPU Usage",
  "description": "CPU usage exceeds threshold for sustained period",
  "query": "otelcol_process_cpu_seconds > 0.8",
  "threshold": 0.8,
  "operator": ">",
  "duration": "5m",
  "severity": "warning",
  "labels": {
    "service": "observability-pipeline",
    "component": "alerting",
    "severity": "warning",
    "environment": "local",
    "alert_type": "performance"
  },
  "notificationChannels": ["email", "slack", "teams", "webhook", "pagerduty"],
  "escalation": {
    "warning": "5m",
    "critical": "10m",
    "emergency": "15m"
  }
}
```

### Notification Channel Configuration
```json
{
  "email": {
    "name": "Email Notifications",
    "enabled": true,
    "config": {
      "smtp_server": "localhost",
      "smtp_port": 587,
      "username": "alerts@company.com",
      "password": "secure_password",
      "from_address": "alerts@company.com",
      "to_addresses": ["ops-team@company.com", "oncall@company.com"],
      "use_ssl": true
    }
  }
}
```

### Escalation Policy Configuration
```json
{
  "default": {
    "name": "Default Escalation Policy",
    "description": "Standard escalation procedure for all alerts",
    "levels": {
      "warning": {
        "duration": "5m",
        "channels": ["email", "slack"],
        "recipients": ["ops-team", "oncall-engineer"],
        "actions": ["notify", "log"],
        "next_level": "critical"
      }
    }
  }
}
```

## Troubleshooting

### Common Issues

#### Alert Threshold Issues
- **Threshold Not Triggering**: Check query syntax, threshold values, duration settings
- **False Positives**: Adjust threshold values, increase duration, refine queries
- **Missing Alerts**: Verify query logic, check data availability, validate thresholds

#### Notification Issues
- **Delivery Failures**: Check channel configuration, verify credentials, test connectivity
- **Template Errors**: Validate template syntax, check placeholder values, test rendering
- **Channel Unavailable**: Verify channel status, check network connectivity, validate credentials

#### Escalation Issues
- **Escalation Not Triggering**: Check escalation policy, verify timing, validate actions
- **Incorrect Escalation**: Review escalation levels, check policy configuration, validate recipients
- **Escalation Loops**: Verify escalation logic, check next level configuration, validate policies

### Debugging Steps

1. **Check Alert Status**:
   ```powershell
   .\scripts\alert-threshold-manager.ps1 -Action "validate" -AlertType "all"
   ```

2. **Test Notification Channels**:
   ```powershell
   .\scripts\notification-manager.ps1 -Action "test" -Channel "all" -TestMode
   ```

3. **Verify Escalation Procedures**:
   ```powershell
   .\scripts\alert-escalation-manager.ps1 -Action "test" -EscalationLevel "critical" -TestMode
   ```

4. **Run Integration Tests**:
   ```powershell
   .\scripts\alert-testing-system.ps1 -TestType "integration" -TestMode
   ```

5. **Check System Health**:
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:8080/api/v1/health"
   Invoke-RestMethod -Uri "http://localhost:13134/healthz"
   ```

## Best Practices

### Alert Threshold Design
- **Start Conservative**: Begin with higher thresholds and reduce based on experience
- **Use Multiple Severities**: Implement warning, critical, and emergency levels
- **Consider Business Impact**: Align thresholds with business requirements
- **Regular Review**: Periodically review and adjust thresholds based on trends

### Notification Management
- **Channel Redundancy**: Use multiple notification channels for critical alerts
- **Template Consistency**: Maintain consistent templates across channels
- **Delivery Verification**: Implement delivery confirmation and retry logic
- **Channel Testing**: Regularly test notification channels

### Escalation Procedures
- **Clear Escalation Paths**: Define clear escalation procedures for each severity level
- **Appropriate Timing**: Set escalation timers based on alert criticality
- **Recipient Management**: Maintain up-to-date recipient lists
- **Escalation Testing**: Regularly test escalation procedures

### Testing and Validation
- **Regular Testing**: Implement regular automated testing of alert systems
- **Test Coverage**: Ensure comprehensive test coverage of all components
- **Test Automation**: Automate testing procedures where possible
- **Test Documentation**: Document test procedures and results

## Integration

### SigNoz Integration
- **Alert Configuration**: Import alert configurations into SigNoz
- **Dashboard Integration**: Create alert dashboards in SigNoz
- **Query Validation**: Validate alert queries in SigNoz UI
- **Health Monitoring**: Monitor SigNoz health for alert system

### CI/CD Integration
```yaml
# Example GitHub Actions workflow
- name: Test Alert System
  run: |
    pwsh -File scripts/alert-testing-system.ps1 -TestType "all" -TestMode
    
- name: Validate Alert Thresholds
  run: |
    pwsh -File scripts/alert-threshold-manager.ps1 -Action "validate" -AlertType "all"
```

### Monitoring Integration
- **Alert Metrics**: Track alert system performance metrics
- **Notification Metrics**: Monitor notification delivery rates
- **Escalation Metrics**: Track escalation effectiveness
- **System Health**: Monitor overall alert system health

## Files Created

```
scripts/alert-threshold-manager.ps1          # Alert threshold management
scripts/notification-manager.ps1              # Notification delivery system
scripts/alert-escalation-manager.ps1          # Escalation procedures
scripts/alert-testing-system.ps1              # Comprehensive testing system
docs/ALERT_THRESHOLDS_NOTIFICATIONS_GUIDE.md  # This documentation
artifacts/alert-thresholds-*.json             # Alert configurations
artifacts/notification-test-*.json            # Notification test results
artifacts/escalation-*.json                   # Escalation results
artifacts/alert-test-report-*.json           # Test reports
```

## Related Documentation

- [SigNoz UI Setup Guide](SIGNOZ_UI_SETUP_GUIDE.md)
- [Monitoring Setup Guide](MONITORING_SETUP_GUIDE.md)
- [OTel Collector Configuration](config.yaml)
- [Canary Pattern Drills Guide](CANARY_PATTERN_DRILLS_GUIDE.md)

## Support

For issues with alert thresholds and notifications:
1. Check alert system health: Run integration tests
2. Verify notification channels: Test channel connectivity
3. Review escalation procedures: Test escalation policies
4. Check system logs: Review alert system logs
5. Run comprehensive tests: Execute full test suite

---

**Last Updated**: 2025-09-24  
**Version**: 1.0.0  
**Status**: Production Ready
