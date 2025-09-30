# SigNoz ECRR Dashboard Setup Guide

## Overview
This guide walks you through importing the ECRR compliance dashboard into SigNoz and setting up alert rules for compliance monitoring.

## Prerequisites
- SigNoz running on http://localhost:8080
- ECRR metrics being exported via OTLP (scripts/export-ecrr-metrics-to-signoz.ps1)
- Dashboard JSON file: `artifacts/signoz-ecrr-dashboard.json`

## Step 1: Import Dashboard

### Via SigNoz UI:
1. Open SigNoz: http://localhost:8080
2. Navigate to **Dashboards** → **+ New Dashboard**
3. Click **Import JSON**
4. Upload or paste contents of `artifacts/signoz-ecrr-dashboard.json`
5. Click **Import**

### Via API (Alternative):
```bash
curl -X POST http://localhost:8080/api/v1/dashboards/import \
  -H "Content-Type: application/json" \
  -d @artifacts/signoz-ecrr-dashboard.json
```

## Step 2: Verify Dashboard Panels

After import, verify these panels are present:

### Panel 1: ECRR Compliance Trend
- **Query**: `ecrr_compliance_four_section_pct`
- **Type**: Line chart
- **Description**: Four-section structure compliance over time

### Panel 2: ECRR Gates Compliance
- **Query**: `ecrr_compliance_gate_pct`
- **Type**: Line chart
- **Description**: ECRR Gates compliance over time

### Panel 3: Compliance Summary
- **Query**: `ecrr_compliance_total_reports`
- **Type**: Stat panel
- **Description**: Total ECRR reports processed

## Step 3: Set Up Alert Rules

### Alert Rule 1: Four-section Compliance Drop
```yaml
name: "ECRR Four-section Compliance Drop"
description: "Alert when ECRR four-section compliance drops below 95%"
query: "ecrr_compliance_four_section_pct < 95"
duration: "5m"
severity: "warning"
```

### Alert Rule 2: Gates Compliance Drop
```yaml
name: "ECRR Gates Compliance Drop"
description: "Alert when ECRR gates compliance drops below 90%"
query: "ecrr_compliance_gate_pct < 90"
duration: "5m"
severity: "critical"
```

### Alert Rule 3: Compliance Trend Decline
```yaml
name: "ECRR Compliance Trend Decline"
description: "Alert when ECRR compliance shows declining trend"
query: "rate(ecrr_compliance_four_section_pct[1h]) < -0.05"
duration: "10m"
severity: "warning"
```

## Step 4: Configure Notification Channels

### Email Notifications:
1. Go to **Settings** → **Notification Channels**
2. Add **Email** channel
3. Configure SMTP settings
4. Test notification

### Slack Notifications:
1. Go to **Settings** → **Notification Channels**
2. Add **Slack** channel
3. Configure webhook URL
4. Test notification

## Step 5: Verify Metrics Flow

### Check Metrics in SigNoz:
1. Go to **Metrics** → **Explore**
2. Search for: `ecrr_compliance_*`
3. Verify metrics are being received
4. Check data freshness (should update daily)

### Query Examples:
```promql
# Four-section compliance
ecrr_compliance_four_section_pct

# Gates compliance
ecrr_compliance_gate_pct

# Total reports
ecrr_compliance_total_reports

# Compliance trend (rate of change)
rate(ecrr_compliance_four_section_pct[1h])
```

## Step 6: Dashboard Customization

### Add Custom Panels:
1. Click **+ Add Panel** in dashboard
2. Choose visualization type
3. Configure query and settings
4. Save panel

### Recommended Additional Panels:
- **Compliance Heatmap**: Show compliance by report type
- **Trend Analysis**: Moving averages and forecasts
- **Alert History**: Track alert frequency and resolution

## Troubleshooting

### Metrics Not Appearing:
1. Check OTLP export script: `scripts/export-ecrr-metrics-to-signoz.ps1`
2. Verify SigNoz collector is receiving data
3. Check network connectivity to SigNoz

### Dashboard Import Fails:
1. Validate JSON syntax in `artifacts/signoz-ecrr-dashboard.json`
2. Check SigNoz version compatibility
3. Try importing panels individually

### Alerts Not Triggering:
1. Verify alert rules are enabled
2. Check notification channel configuration
3. Test with manual alert trigger

## Monitoring Commands

### Check SigNoz Health:
```bash
curl http://localhost:8080/api/v1/health
```

### Verify Metrics Export:
```bash
curl http://localhost:8080/api/v1/metrics/query \
  -d '{"query": "ecrr_compliance_four_section_pct"}'
```

### Test Alert System:
```powershell
pwsh -File scripts/monitor-ecrr-alerts.ps1 -SendAlert
```

## Next Steps

1. **Production Alert Setup**: Update `artifacts/ecrr-alert-config.json` with production contacts
2. **Dashboard Sharing**: Share dashboard URL with team members
3. **Regular Monitoring**: Set up daily compliance reviews
4. **Continuous Improvement**: Refine thresholds based on historical data

## Support

For issues with SigNoz integration:
- Check SigNoz logs: `docker logs signoz-otel-collector`
- Verify OTLP endpoint: `http://localhost:5318/v1/metrics`
- Review ECRR export logs: `artifacts/ecrr-export-log.txt`
