# Dashboard Setup Guide - Windows Logs Canary Monitoring

## Overview

This guide provides comprehensive instructions for setting up and configuring the Windows Logs Canary monitoring dashboard in SigNoz to provide real-time visibility into the observability pipeline health.

## Dashboard Components

### 1. Canary Count Panel
- **Purpose**: Shows total canary entries in the last hour
- **Type**: Stat panel with color-coded thresholds
- **Thresholds**: Red (0), Yellow (1), Green (5+)
- **Query**: Count of Windows logs canary entries

### 2. Generation Rate Panel
- **Purpose**: Displays canary generation rate over time
- **Type**: Graph panel showing trends
- **Time Range**: Last hour with hourly grouping
- **Use Case**: Identify generation patterns and anomalies

### 3. Recent Entries Panel
- **Purpose**: Lists the most recent canary entries
- **Type**: Table panel with timestamp and content
- **Limit**: Last 10 entries
- **Use Case**: Quick verification of recent activity

### 4. Windows Log Volume Panel
- **Purpose**: Shows total Windows Event Log volume
- **Type**: Graph panel for context
- **Use Case**: Compare canary volume to total Windows logs

### 5. Health Status Panel
- **Purpose**: Binary health indicator
- **Type**: Stat panel with status mapping
- **Logic**: HEALTHY if canaries in last 15 minutes, UNHEALTHY otherwise
- **Use Case**: Quick health assessment

### 6. Alert Status Panel
- **Purpose**: Shows current alert condition
- **Type**: Stat panel with status mapping
- **Logic**: OK if canaries ≥ 1 in last hour, ALERT otherwise
- **Use Case**: Immediate alert status visibility

### 7. Timeline Panel
- **Purpose**: Long-term canary generation trends
- **Type**: Graph panel with 6-hour view
- **Use Case**: Historical analysis and pattern recognition

## Import Instructions

### Step 1: Access SigNoz UI
1. Open browser: **http://localhost:8080**
2. Navigate to: **Dashboards**

### Step 2: Create New Dashboard
1. Click **"New Dashboard"** or **"Import Dashboard"**
2. Select **"Import JSON"** option
3. Copy contents from: `signoz-windows-logs-canary-dashboard.json`
4. Paste into the import field

### Step 3: Configure Dashboard Settings
1. **Title**: `Windows Logs Canary Monitoring`
2. **Description**: `Dashboard for monitoring Windows Event Log canary ingestion and pipeline health`
3. **Tags**: `windows`, `logs`, `canary`, `observability`
4. **Refresh Rate**: `30 seconds`
5. **Time Range**: `Last 1 hour`

### Step 4: Save and Test
1. Click **"Save"** to create the dashboard
2. Verify all panels load correctly
3. Test with canary generation

## Panel Configuration Details

### Canary Count Panel
```sql
SELECT count() as value 
FROM logs 
WHERE attributes_string['dataset'] = 'windows' 
  AND body LIKE '%windows-logs-canary%' 
  AND timestamp >= now() - INTERVAL 1 HOUR
```

**Thresholds:**
- Red: 0 canaries (critical)
- Yellow: 1 canary (warning)
- Green: 5+ canaries (healthy)

### Generation Rate Panel
```sql
SELECT count() as value 
FROM logs 
WHERE attributes_string['dataset'] = 'windows' 
  AND body LIKE '%windows-logs-canary%' 
  AND timestamp >= now() - INTERVAL 1 HOUR 
GROUP BY timestamp 
ORDER BY timestamp
```

### Health Status Panel
```sql
SELECT CASE WHEN count() > 0 THEN 1 ELSE 0 END as value 
FROM logs 
WHERE attributes_string['dataset'] = 'windows' 
  AND body LIKE '%windows-logs-canary%' 
  AND timestamp >= now() - INTERVAL 15 MINUTE
```

**Status Mapping:**
- 0: UNHEALTHY
- 1: HEALTHY

### Alert Status Panel
```sql
SELECT CASE WHEN count() < 1 THEN 1 ELSE 0 END as value 
FROM logs 
WHERE attributes_string['dataset'] = 'windows' 
  AND body LIKE '%windows-logs-canary%' 
  AND timestamp >= now() - INTERVAL 1 HOUR
```

**Status Mapping:**
- 0: OK (no alert)
- 1: ALERT (alert condition met)

## Dashboard Features

### Real-time Updates
- **Refresh Rate**: 30 seconds
- **Auto-refresh**: Enabled
- **Live Data**: Real-time canary monitoring

### Interactive Elements
- **Time Range Picker**: Adjustable time windows
- **Panel Links**: Direct links to related views
- **Annotations**: Canary test run markers

### Navigation Links
- **SigNoz Logs Query**: Direct link to filtered logs
- **Alert Configuration**: Link to alert management
- **Task Scheduler Status**: Link to scheduler monitoring

## Testing and Validation

### Test 1: Generate Canaries
```powershell
# Generate test canaries
.\scripts\windows-logs-canary-test.ps1 -Count 5

# Verify dashboard updates within 30 seconds
# Expected: Canary count increases, health status shows HEALTHY
```

### Test 2: Verify Health Status
```powershell
# Wait 15+ minutes without generating canaries
# Expected: Health status changes to UNHEALTHY
# Expected: Alert status changes to ALERT after 1 hour
```

### Test 3: Check Timeline
```powershell
# Generate canaries at different times
# Expected: Timeline shows generation patterns
# Expected: Annotations mark test runs
```

## Customization Options

### Panel Modifications
1. **Adjust Thresholds**: Change color coding values
2. **Modify Queries**: Update SQL queries for different metrics
3. **Change Time Ranges**: Adjust panel-specific time windows
4. **Add Panels**: Include additional monitoring metrics

### Dashboard Variables
Add dashboard variables for dynamic filtering:
```json
{
  "name": "canary_type",
  "type": "textbox",
  "label": "Canary Type",
  "query": "windows-logs-canary"
}
```

### Advanced Queries
```sql
-- Canary success rate
SELECT countIf(body LIKE '%SUCCESS%') / count() * 100 as success_rate
FROM logs 
WHERE attributes_string['dataset'] = 'windows' 
  AND body LIKE '%windows-logs-canary%' 
  AND timestamp >= now() - INTERVAL 1 HOUR

-- Average canary generation interval
SELECT avg(timeDiff('second', prev_timestamp, timestamp)) as avg_interval
FROM (
  SELECT timestamp, lag(timestamp) OVER (ORDER BY timestamp) as prev_timestamp
  FROM logs 
  WHERE attributes_string['dataset'] = 'windows' 
    AND body LIKE '%windows-logs-canary%' 
    AND timestamp >= now() - INTERVAL 6 HOUR
)
```

## Integration with Monitoring

### Alert Integration
- Dashboard panels reflect alert conditions
- Health status directly correlates with alert triggers
- Timeline shows alert resolution patterns

### Notification Integration
- Dashboard links to notification channels
- Status panels provide context for alerts
- Historical data supports incident analysis

### Runbook Integration
- Dashboard serves as primary monitoring interface
- Links provide direct access to troubleshooting tools
- Status indicators guide response procedures

## Troubleshooting

### Dashboard Not Loading
1. **Check SigNoz Status**: Verify SigNoz is running
2. **Validate JSON**: Ensure dashboard JSON is valid
3. **Check Permissions**: Verify dashboard access rights
4. **Refresh Browser**: Clear cache and reload

### Panels Not Updating
1. **Check Refresh Rate**: Verify auto-refresh is enabled
2. **Validate Queries**: Test queries in SigNoz logs interface
3. **Check Time Range**: Ensure time range includes data
4. **Verify Data Source**: Confirm logs are being ingested

### Incorrect Data Display
1. **Validate Queries**: Test queries independently
2. **Check Attribute Names**: Verify attribute syntax
3. **Review Time Zones**: Ensure consistent time handling
4. **Validate Thresholds**: Check color coding logic

### Performance Issues
1. **Optimize Queries**: Use appropriate time ranges
2. **Reduce Refresh Rate**: Increase refresh interval
3. **Limit Panel Count**: Remove unnecessary panels
4. **Check Data Volume**: Monitor ingestion rates

## Best Practices

### Dashboard Design
- **Keep it Simple**: Focus on essential metrics
- **Use Consistent Colors**: Red for problems, green for healthy
- **Provide Context**: Include related metrics for comparison
- **Enable Interactions**: Add links and annotations

### Query Optimization
- **Use Appropriate Time Ranges**: Balance detail vs performance
- **Limit Result Sets**: Use LIMIT clauses for large datasets
- **Index Attributes**: Ensure frequently queried attributes are indexed
- **Cache Results**: Use dashboard caching when appropriate

### Monitoring Strategy
- **Set Appropriate Thresholds**: Based on actual usage patterns
- **Monitor Trends**: Watch for gradual changes over time
- **Correlate Metrics**: Look for relationships between panels
- **Document Procedures**: Create runbooks for common scenarios

## Maintenance

### Regular Tasks
- **Weekly**: Review dashboard performance and accuracy
- **Monthly**: Update thresholds based on usage patterns
- **Quarterly**: Evaluate panel effectiveness and relevance
- **Annually**: Review overall dashboard design and strategy

### Updates and Improvements
- **Add New Metrics**: Include additional monitoring dimensions
- **Refine Thresholds**: Adjust based on operational experience
- **Enhance Visualizations**: Improve chart types and layouts
- **Expand Integration**: Add links to additional tools and systems

## Advanced Features

### Dashboard Sharing
- **Public Dashboards**: Share with external stakeholders
- **Embedded Dashboards**: Include in external applications
- **Export Options**: Generate reports and screenshots
- **Access Control**: Manage user permissions and roles

### Automation Integration
- **API Access**: Programmatic dashboard management
- **Configuration Management**: Version control for dashboard configs
- **Deployment Automation**: Automated dashboard deployment
- **Monitoring Integration**: Connect with external monitoring systems
