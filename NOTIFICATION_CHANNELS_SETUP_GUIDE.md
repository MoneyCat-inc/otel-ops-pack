# Notification Channels Setup Guide - Windows Logs Canary Alerts

## Overview

This guide provides step-by-step instructions for setting up notification channels in SigNoz to receive alerts when Windows Logs Canary entries are missing, indicating potential ingestion pipeline issues.

## Available Notification Channels

### 1. Email Notifications
**Best for**: Critical alerts, detailed information, audit trails

### 2. Slack Notifications  
**Best for**: Real-time team collaboration, quick responses

### 3. Microsoft Teams Notifications
**Best for**: Enterprise environments, structured alerts

### 4. Webhook Notifications
**Best for**: Custom integrations, automated responses

## Setup Instructions

### Email Notification Channel

#### Step 1: Access SigNoz UI
1. Open browser: **http://localhost:8080**
2. Navigate to: **Settings → Notification Channels**

#### Step 2: Create Email Channel
1. Click **"Create Channel"**
2. Select **"Email"** as channel type
3. Configure the following:

**Basic Settings:**
- **Name**: `Email-Alerts`
- **Description**: `Email notifications for Windows Logs Canary alerts`

**SMTP Configuration:**
- **SMTP Host**: `smtp.company.com` (replace with your SMTP server)
- **Port**: `587` (or `465` for SSL)
- **Username**: `alerts@company.com`
- **Password**: `[your SMTP password]`
- **Use TLS**: `Yes`

**Email Settings:**
- **To**: `admin@company.com, ops@company.com`
- **Subject**: `[SigNoz Alert] {{ .GroupLabels.alertname }}`
- **Body Template**:
```
Alert: {{ .GroupLabels.alertname }}
Severity: {{ .GroupLabels.severity }}
Status: {{ .Status }}
Component: {{ .GroupLabels.component }}
Duration: {{ .GroupLabels.duration }}

Description: {{ range .Alerts }}{{ .Annotations.description }}{{ end }}

Runbook: {{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }}

Timestamp: {{ .StartsAt }}
```

#### Step 3: Test Email Channel
1. Click **"Test"** to send a test notification
2. Verify email is received
3. Check spam folder if not received

### Slack Notification Channel

#### Step 1: Create Slack Webhook
1. Go to: **https://api.slack.com/messaging/webhooks**
2. Click **"Create New App"**
3. Choose **"From scratch"**
4. Enter app name: `SigNoz Alerts`
5. Select workspace
6. Go to **"Incoming Webhooks"**
7. Toggle **"Activate Incoming Webhooks"** to On
8. Click **"Add New Webhook to Workspace"**
9. Select channel: `#ops-alerts`
10. Copy webhook URL

#### Step 2: Create Slack Channel in SigNoz
1. In SigNoz UI: **Settings → Notification Channels**
2. Click **"Create Channel"**
3. Select **"Slack"**
4. Configure:

**Basic Settings:**
- **Name**: `Slack-Ops`
- **Description**: `Slack notifications for observability alerts`

**Slack Configuration:**
- **Webhook URL**: `https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK`
- **Channel**: `#ops-alerts`
- **Title**: `🚨 SigNoz Alert: {{ .GroupLabels.alertname }}`
- **Message**:
```
{{ range .Alerts }}{{ .Annotations.description }}{{ end }}

*Severity*: {{ .GroupLabels.severity }}
*Status*: {{ .Status }}
*Component*: {{ .GroupLabels.component }}
*Duration*: {{ .GroupLabels.duration }}

Runbook: {{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }}
```

#### Step 3: Test Slack Channel
1. Click **"Test"** in SigNoz
2. Check Slack channel for test message
3. Verify formatting and links work

### Microsoft Teams Notification Channel

#### Step 1: Create Teams Webhook
1. In Teams, go to the target channel
2. Click **"..."** → **"Connectors"**
3. Find **"Incoming Webhook"** → **"Configure"**
4. Enter name: `SigNoz Alerts`
5. Upload icon (optional)
6. Click **"Create"**
7. Copy webhook URL

#### Step 2: Create Teams Channel in SigNoz
1. In SigNoz UI: **Settings → Notification Channels**
2. Click **"Create Channel"**
3. Select **"Teams"**
4. Configure:

**Basic Settings:**
- **Name**: `Teams-Ops`
- **Description**: `Teams notifications for Windows Logs Canary alerts`

**Teams Configuration:**
- **Webhook URL**: `https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK`
- **Title**: `🚨 Windows Logs Canary Alert`
- **Message**:
```
{{ range .Alerts }}{{ .Annotations.description }}{{ end }}

**Severity**: {{ .GroupLabels.severity }}
**Status**: {{ .Status }}
**Component**: {{ .GroupLabels.component }}
**Duration**: {{ .GroupLabels.duration }}

[Runbook]({{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }})
```

#### Step 3: Test Teams Channel
1. Click **"Test"** in SigNoz
2. Check Teams channel for test message
3. Verify formatting and links work

### Webhook Notification Channel

#### Step 1: Create Webhook Endpoint
1. Set up HTTP endpoint to receive POST requests
2. Ensure endpoint can handle JSON payloads
3. Note the endpoint URL

#### Step 2: Create Webhook Channel in SigNoz
1. In SigNoz UI: **Settings → Notification Channels**
2. Click **"Create Channel"**
3. Select **"Webhook"**
4. Configure:

**Basic Settings:**
- **Name**: `Webhook-Generic`
- **Description**: `Generic webhook for custom integrations`

**Webhook Configuration:**
- **URL**: `http://localhost:8080/api/v1/webhook/alerts`
- **Method**: `POST`
- **Headers**:
  ```
  Content-Type: application/json
  X-Alert-Source: signoz
  ```
- **Body Template**:
```json
{
  "alert": "{{ .GroupLabels.alertname }}",
  "status": "{{ .Status }}",
  "severity": "{{ .GroupLabels.severity }}",
  "description": "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}",
  "labels": {{ .GroupLabels | toJson }},
  "timestamp": "{{ .StartsAt }}",
  "runbook": "{{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }}"
}
```

## Link Channels to Windows Logs Canary Alert

### Step 1: Edit Alert Configuration
1. Navigate to: **Alerts → Alert Rules**
2. Find **"Windows Logs Canary Missing (1 Hour)"**
3. Click **"Edit"**

### Step 2: Configure Notification Channels
1. Go to **"Notification Channels"** tab
2. Select channels:
   - ✅ **Email-Alerts**
   - ✅ **Slack-Ops**  
   - ✅ **Teams-Ops**
   - ❌ **Webhook-Generic** (optional)

### Step 3: Set Alert Group Settings
1. **Alert Group**: `Windows-Logs-Canary`
2. **Repeat Interval**: `1 hour`
3. **Group Wait**: `10 seconds`
4. **Group Interval**: `10 minutes`

### Step 4: Save and Test
1. Click **"Save"**
2. Verify alert configuration
3. Test by temporarily lowering threshold

## Testing Notification Channels

### Method 1: Lower Alert Threshold
1. Edit Windows Logs Canary alert
2. Change threshold from `1` to `10` (temporarily)
3. Change duration from `60m` to `1m`
4. Save and wait for alert to trigger
5. Verify notifications are received
6. Restore original settings

### Method 2: Manual Test
1. In SigNoz UI: **Settings → Notification Channels**
2. Select each channel and click **"Test"**
3. Verify test notifications are received
4. Check formatting and content

### Method 3: Stop Canary Generation
1. Temporarily disable Task Scheduler task
2. Wait 1+ hours for alert to trigger
3. Verify notifications are received
4. Re-enable Task Scheduler task

## Alert Template Variables

### Available Variables
- `{{ .GroupLabels.alertname }}` - Alert name
- `{{ .GroupLabels.severity }}` - Alert severity
- `{{ .GroupLabels.component }}` - Component (windows-logs)
- `{{ .GroupLabels.canary }}` - Canary type (true)
- `{{ .GroupLabels.duration }}` - Duration (1h)
- `{{ .Status }}` - Alert status (firing/resolved)
- `{{ .StartsAt }}` - Alert start time
- `{{ range .Alerts }}{{ .Annotations.description }}{{ end }}` - Alert description
- `{{ range .Alerts }}{{ .Annotations.runbook_url }}{{ end }}` - Runbook URL

### Sample Alert Payload
```json
{
  "alertname": "Windows Logs Canary Missing (1 Hour)",
  "severity": "warning",
  "component": "windows-logs",
  "canary": "true",
  "duration": "1h",
  "status": "firing",
  "description": "No Windows Event Log canary entries found in the last hour",
  "runbook_url": "http://localhost:8080/logs?query=attributes_string['dataset']%20%3D%20'windows'",
  "timestamp": "2025-01-27T10:30:00Z"
}
```

## Troubleshooting

### No Notifications Received
1. **Check channel configuration** - Verify URLs, credentials
2. **Test channels individually** - Use test button in SigNoz
3. **Check alert configuration** - Ensure channels are linked
4. **Verify alert triggers** - Check alert status and history
5. **Check spam folders** - For email notifications

### Incorrect Formatting
1. **Review template variables** - Ensure correct syntax
2. **Test with sample data** - Use test mode
3. **Check channel documentation** - Verify supported formats
4. **Validate JSON** - For webhook channels

### Rate Limiting Issues
1. **Adjust group intervals** - Increase group wait time
2. **Filter notifications** - Use alert grouping
3. **Implement backoff** - For webhook endpoints
4. **Monitor channel health** - Check delivery rates

## Best Practices

### Channel Selection
- **Critical alerts**: Use email + Slack/Teams
- **Operational alerts**: Use Slack/Teams only
- **Custom integrations**: Use webhooks
- **Audit requirements**: Always include email

### Message Content
- **Include context**: Component, severity, duration
- **Provide runbook links**: Direct links to troubleshooting
- **Use clear formatting**: Consistent structure across channels
- **Avoid noise**: Group related alerts, use appropriate intervals

### Escalation Procedures
1. **Level 1**: Slack/Teams notification
2. **Level 2**: Email notification (if no response in 15 minutes)
3. **Level 3**: Escalate to on-call engineer
4. **Level 4**: Page incident commander

## Maintenance

### Regular Checks
- **Monthly**: Test all notification channels
- **Quarterly**: Review and update templates
- **Annually**: Audit channel configurations and permissions

### Updates
- **Channel URLs**: Update when webhook endpoints change
- **Template Variables**: Update when SigNoz versions change
- **Escalation Procedures**: Update contact information regularly

## Integration with Monitoring

### Dashboard Integration
- Add notification channel status to monitoring dashboards
- Track alert delivery rates and response times
- Monitor notification channel health

### Logging
- Log notification delivery attempts
- Track alert escalation patterns
- Monitor notification channel performance

### Automation
- Auto-create notification channels for new environments
- Automate channel testing and validation
- Integrate with configuration management tools
