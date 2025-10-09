# ECRR Compliance Alert Webhook Configuration

## Selected Configuration

### Webhook Service
- **Service**: webhook.site (for testing)
- **Purpose**: Capture and inspect webhook payloads during development/testing
- **URL**: https://webhook.site/97656595-ae7a-4524-9ef0-326ac6caad32
- **Email**: 97656595-ae7a-4524-9ef0-326ac6caad32@emailhook.site
- **DNS**: *.97656595-ae7a-4524-9ef0-326ac6caad32.dnshook.site

### Channel Configuration
- **Channel Name**: Signoz Webhook
- **Webhook URL**: https://webhook.site/97656595-ae7a-4524-9ef0-326ac6caad32
- **HTTP Method**: POST
- **Content Type**: application/json
- **Authentication**: None (for testing)
- **Send Resolved Alerts**: Enabled
- **Custom Headers**:
  - `X-Source: SigNoz-ECRR`
  - `X-Alert-Type: Compliance-Monitoring`

### SigNoz Setup Steps
1. **Navigate**: Settings → Notification Channels
2. **Create**: New Channel → Webhook
3. **Configure**:
   - Name: ECRR-Compliance-Alerts
   - URL: [webhook.site URL]
   - Method: POST
   - Content-Type: application/json
4. **Test**: Send test notification
5. **Save**: Channel configuration

### Alert Integration
1. **Edit Alert**: ECRR Compliance Threshold Breach
2. **Notification Channels**: Select ECRR-Compliance-Alerts
3. **Save**: Alert configuration

### Expected Payloads

#### Test Payload
```json
{
  "alert_name": "Test Alert",
  "severity": "info",
  "status": "test",
  "message": "This is a test notification"
}
```

#### Firing Alert Payload
```json
{
  "alert_name": "ECRR Compliance Threshold Breach",
  "severity": "warning",
  "status": "firing",
  "compliance_rate": 0.11,
  "threshold": 80,
  "dataset": "ecrr_compliance",
  "timestamp": "2025-09-28T20:00:00Z",
  "message": "ECRR compliance rate dropped below threshold"
}
```

#### Resolved Alert Payload
```json
{
  "alert_name": "ECRR Compliance Threshold Breach",
  "severity": "warning",
  "status": "resolved",
  "compliance_rate": 85.2,
  "threshold": 80,
  "dataset": "ecrr_compliance",
  "timestamp": "2025-09-28T20:05:00Z",
  "message": "ECRR compliance rate recovered above threshold"
}
```

### Verification Checklist
- [ ] Webhook channel created in SigNoz
- [ ] Test notification sent successfully
- [ ] Alert configured to use webhook
- [ ] Alert fires immediately (0.11% < 80%)
- [ ] Webhook receives firing notification
- [ ] Payload structure matches expected format

### Current Alert Status
- **Compliance Rate**: 0.11%
- **Threshold**: 80%
- **Expected Behavior**: Alert fires immediately upon creation
- **Webhook**: Will receive notification within 1 minute of alert creation

### Next Steps
1. Generate webhook.site URL
2. Configure SigNoz webhook channel
3. Test webhook functionality
4. Configure alert to use webhook
5. Verify alert firing and webhook delivery

### Troubleshooting
- **No webhook received**: Check webhook.site URL validity
- **Test fails**: Verify SigNoz can reach webhook.site
- **Alert not firing**: Check Query Builder configuration with `body.dataset` and `body.compliance_rate`
- **Wrong payload**: Verify alert metadata configuration

### Production Considerations
For production deployment, consider:
- **Authentication**: Add API key or bearer token
- **HTTPS**: Use secure webhook endpoints
- **Retry Logic**: Configure retry attempts for failed deliveries
- **Monitoring**: Monitor webhook delivery success rates
- **Rate Limiting**: Implement appropriate rate limiting
