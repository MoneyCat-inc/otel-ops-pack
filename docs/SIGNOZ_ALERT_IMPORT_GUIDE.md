# SigNoz Alert Import Guide

## Overview

This guide explains how to import and configure the ECRR Canary alert in SigNoz to monitor the health of the OpenTelemetry canary testing system.

## Prerequisites

- SigNoz UI accessible at `http://localhost:8080`
- Admin access to SigNoz
- ECRR canary scheduler running (`OTel-ECRR-Canary` task)
- Alert JSON file: `signoz-ecrr-canary-alert.json`

## Alert Configuration

The ECRR Canary alert monitors for missing canary signals in the observability pipeline:

- **Alert Name**: ECRR Canary Missing
- **Severity**: Warning
- **Threshold**: Less than 1 canary in 15 minutes
- **Evaluation Window**: 15 minutes
- **Alert Frequency**: Every 5 minutes
- **Query**: `service.name = 'ecrr-canary' AND attributes.canary.type = 'ecrr-enhanced'`

## Import Steps

### 1. Access SigNoz Alerts

1. Open SigNoz UI: `http://localhost:8080`
2. Navigate to **Alerts** in the left sidebar
3. Click **New Alert** button

### 2. Import Alert Configuration

1. Click **Import JSON** or **Import** button
2. Open the file `signoz-ecrr-canary-alert.json` from the project root
3. Copy the entire JSON content
4. Paste into the import dialog
5. Click **Import** or **Save**

### 3. Configure Notification Channels

1. After import, click on the **ECRR Canary Missing** alert
2. Navigate to **Notifiers** tab
3. Add notification channels:
   - **email-default**: For email notifications
   - **slack-default**: For Slack notifications (if configured)

### 4. Save and Activate

1. Click **Save** to save the alert configuration
2. Ensure the alert is **Active** (toggle should be ON)
3. The alert will start monitoring immediately

## Verification

### 1. Check Alert Status

1. Go to **Alerts** → **Alert List**
2. Find **ECRR Canary Missing** alert
3. Verify status is **Active**
4. Check last evaluation time

### 2. Test Alert (Optional)

To test the alert:

1. Stop the ECRR canary scheduler:
   ```powershell
   Disable-ScheduledTask -TaskName 'OTel-ECRR-Canary'
   ```

2. Wait 15+ minutes for the alert to trigger

3. Check alert status in SigNoz UI

4. Re-enable the scheduler:
   ```powershell
   Enable-ScheduledTask -TaskName 'OTel-ECRR-Canary'
   ```

### 3. Verify Canary Data

Check that canary data is flowing:

1. Go to **Logs** in SigNoz UI
2. Apply filter: `service.name = 'ecrr-canary' AND attributes.canary.type = 'ecrr-enhanced'`
3. Should see recent canary entries every ~10 minutes

## Alert Details

### Query Breakdown

```sql
service.name = 'ecrr-canary' AND attributes.canary.type = 'ecrr-enhanced'
```

- **service.name**: Filters for the canary service
- **attributes.canary.type**: Filters for ECRR-enhanced canary type
- **Group By**: Groups by service name and canary type for counting

### Condition Logic

- **Threshold**: 1 (minimum expected canaries)
- **Operator**: below (alert when count is below threshold)
- **Evaluation Window**: 15 minutes (looks back 15 minutes)
- **Alert Frequency**: 5 minutes (re-evaluates every 5 minutes)
- **Missing Data**: Alert if no data points in evaluation window

### Expected Behavior

- **Normal**: Alert remains green, no notifications
- **Missing Canary**: Alert triggers after 15 minutes of no canary data
- **Recovery**: Alert resolves when canary data resumes

## Troubleshooting

### Alert Not Triggering

1. **Check Query**: Verify the query matches actual log data
2. **Check Time Range**: Ensure evaluation window covers recent data
3. **Check Threshold**: Verify threshold is appropriate
4. **Check Data Flow**: Confirm canary data is reaching SigNoz

### Alert Triggering Too Often

1. **Increase Threshold**: If canary frequency is lower than expected
2. **Adjust Evaluation Window**: Increase window if canaries are irregular
3. **Check Query**: Ensure query is not too broad

### No Canary Data

1. **Check Scheduler**: Verify `OTel-ECRR-Canary` task is running
2. **Check Collector**: Ensure OTel collector is running and receiving data
3. **Check Logs**: Look for errors in canary execution logs
4. **Check Network**: Verify OTLP endpoint connectivity

## Maintenance

### Regular Checks

- Monitor alert status weekly
- Verify canary data is flowing
- Check notification channels are working
- Review alert frequency and thresholds

### Updates

- Alert configuration can be modified in SigNoz UI
- JSON file can be updated and re-imported
- Notification channels can be added/removed as needed

## Related Files

- `signoz-ecrr-canary-alert.json`: Alert configuration
- `scripts/canary-ecrr.ps1`: Canary execution script
- `C:\otel\artifacts\canary-ecrr-report.txt`: Latest canary report
- `C:\logs\ecrr-canary-test.log`: Canary execution logs

## Support

For issues with this alert configuration:

1. Check SigNoz documentation
2. Review canary execution logs
3. Verify OTel collector configuration
4. Check Windows Event Log for canary entries