# SigNoz Query Recipes for Resonai Analytics

This document provides ready-to-use SigNoz query snippets for analyzing Resonai analytics data forwarded via OTLP.

> Cross-project context: for the executive and roadmap view, see the [ECRR Project Report](ECRR_PROJECT_REPORT.md).

## Filter Expressions

All queries should include the base filter to target Resonai analytics:
```
attributes.dataset = "resonai_analytics"
```

## IONA Supervisor Queries

### Job Throughput Analysis

**Purpose**: Monitor IONA job completion rates across different modes

**Query**:
```sql
sum(rate(iona_jobs_completed_total{mode="*"}[5m]))
```

**SigNoz UI Steps**:
1. Go to Metrics -> Explorer
2. Query: `sum(rate(iona_jobs_completed_total{mode="*"}[5m]))`
3. Group by: `mode`
4. Time range: 1 hour

**Dashboard Panel**:
- **Title**: "IONA Job Throughput"
- **Type**: Time Series
- **Time Range**: 1 hour
- **Query**: Above expression
- **Group by**: `mode`

### Job Success Rate

**Purpose**: Track IONA job success percentage by mode

**Query**:
```sql
(sum(rate(iona_jobs_completed_total{mode="*"}[5m])) by (mode) / (sum(rate(iona_jobs_completed_total{mode="*"}[5m])) by (mode) + sum(rate(iona_jobs_failed_total{mode="*"}[5m])) by (mode))) * 100
```

**SigNoz UI Steps**:
1. Go to Metrics -> Explorer
2. Query: Above expression
3. Group by: `mode`
4. Time range: 1 hour

### Job Duration Percentiles

**Purpose**: Monitor IONA job execution time performance

**Queries**:
```sql
-- Duration p50
histogram_quantile(0.50, sum(rate(iona_job_duration_ms_bucket{mode="*"}[5m])) by (mode, le))

-- Duration p90
histogram_quantile(0.90, sum(rate(iona_job_duration_ms_bucket{mode="*"}[5m])) by (mode, le))

-- Duration p95
histogram_quantile(0.95, sum(rate(iona_job_duration_ms_bucket{mode="*"}[5m])) by (mode, le))
```

**SigNoz UI Steps**:
1. Go to Metrics -> Explorer
2. Query: Above expressions (create separate panels for each percentile)
3. Group by: `mode`
4. Time range: 1 hour

### Queue Depth Monitoring

**Purpose**: Monitor IONA job queue depth by mode

**Query**:
```sql
sum(iona_jobs_queued{mode="*"}) by (mode)
```

**SigNoz UI Steps**:
1. Go to Metrics -> Explorer
2. Query: Above expression
3. Group by: `mode`
4. Time range: 1 hour

### Active Jobs Tracking

**Purpose**: Monitor currently running IONA jobs

**Query**:
```sql
sum(iona_jobs_running{mode="*"}) by (mode)
```

**SigNoz UI Steps**:
1. Go to Metrics -> Explorer
2. Query: Above expression
3. Group by: `mode`
4. Time range: 1 hour

### Error Rate Analysis

**Purpose**: Track IONA job failure rates by error type

**Query**:
```sql
sum(rate(iona_jobs_failed_total{mode="*"}[5m])) by (mode, error_type)
```

**SigNoz UI Steps**:
1. Go to Metrics -> Explorer
2. Query: Above expression
3. Group by: `mode`, `error_type`
4. Time range: 1 hour

### Trace Analysis

**Purpose**: Analyze IONA job execution traces

**SigNoz UI Steps**:
1. Go to Traces -> Search
2. Filter: `service.name = "iona-supervisor"`
3. Filter: `attributes.job.mode = "Companion"` (or specific mode)
4. Time range: 1 hour

**Trace Attributes to Filter By**:
- `job_id` - Specific job identifier
- `mode` - Job mode (Companion, Practice, Assessment, Analysis)
- `status` - Job status (started, completed, failed)
- `duration_ms` - Job execution time

## Core Analytics Queries

### 1. Mic Permission Grant Rate

**Purpose**: Track microphone permission acceptance rate over time

**Query**:
```sql
count(attributes.event="permission_granted") / (count(attributes.event="permission_granted") + count(attributes.event="permission_denied")) * 100
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.event`
4. Filter events: `attributes.event IN ("permission_granted", "permission_denied")`
5. Calculate percentage in dashboard

**Dashboard Panel**:
- **Title**: "Mic Permission Grant Rate"
- **Type**: Single Stat
- **Time Range**: 1 hour
- **Query**: Above expression
- **Thresholds**: Green >80%, Yellow 50-80%, Red <50%

### 2. Time to Value (TTV) Percentiles

**Purpose**: Measure performance metrics for TTV events

**Queries**:
```sql
-- TTV p50 (median)
quantile(0.5, attributes.ttv_ms) WHERE attributes.event="ttv_measured"

-- TTV p90
quantile(0.9, attributes.ttv_ms) WHERE attributes.event="ttv_measured"

-- TTV p95
quantile(0.95, attributes.ttv_ms) WHERE attributes.event="ttv_measured"

-- TTV p99
quantile(0.99, attributes.ttv_ms) WHERE attributes.event="ttv_measured"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics" AND attributes.event="ttv_measured"`
3. Add Group By: `attributes.ttv_ms`
4. Select percentile aggregation

**Dashboard Panels**:
- **Title**: "TTV Performance (ms)"
- **Type**: Time Series
- **Queries**: All percentiles above
- **Time Range**: 24 hours
- **Thresholds**: p50 <200ms, p90 <500ms, p95 <1000ms

### 3. Activation Rate

**Purpose**: Track user activation rate from practice sessions

**Query**:
```sql
count(attributes.event="activation") / count(attributes.event="screen_view" AND attributes.variant="practice") * 100
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.event`
4. Filter for activation and screen_view events
5. Calculate ratio in dashboard

**Dashboard Panel**:
- **Title**: "User Activation Rate"
- **Type**: Single Stat
- **Time Range**: 24 hours
- **Query**: Above expression
- **Thresholds**: Green >5%, Yellow 2-5%, Red <2%

## Event Volume Analytics

### 4. Top Events by Volume

**Purpose**: Identify most frequent user actions

**Query**:
```sql
count by (attributes.event) WHERE attributes.dataset = "resonai_analytics"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.event`
4. Order by count descending

**Dashboard Panel**:
- **Title**: "Top Events (24h)"
- **Type**: Table
- **Time Range**: 24 hours
- **Limit**: 10 rows

### 5. Event Volume Over Time

**Purpose**: Track analytics volume trends

**Query**:
```sql
count by (attributes.event) WHERE attributes.dataset = "resonai_analytics"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.event`
4. Select time series visualization

**Dashboard Panel**:
- **Title**: "Event Volume Trends"
- **Type**: Time Series
- **Time Range**: 7 days
- **Interval**: 1 hour

## Session Analytics

### 6. Session Duration Distribution

**Purpose**: Analyze user session patterns

**Query**:
```sql
count by (attributes.session_id) WHERE attributes.dataset = "resonai_analytics"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.session_id`
4. Count events per session

**Dashboard Panel**:
- **Title**: "Events per Session"
- **Type**: Histogram
- **Time Range**: 24 hours

### 7. Cohort Performance

**Purpose**: Compare performance across user cohorts

**Query**:
```sql
count by (attributes.cohort, attributes.event) WHERE attributes.dataset = "resonai_analytics"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.cohort`, `attributes.event`
4. Visualize as stacked bar chart

**Dashboard Panel**:
- **Title**: "Cohort Performance"
- **Type**: Bar Chart
- **Time Range**: 24 hours
- **Group By**: `attributes.cohort`

## Error Monitoring

### 8. Error Rate Tracking

**Purpose**: Monitor analytics processing errors

**Query**:
```sql
count(level="ERROR") / count(*) * 100 WHERE attributes.dataset = "resonai_analytics"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `level`
4. Calculate error percentage

**Dashboard Panel**:
- **Title**: "Analytics Error Rate"
- **Type**: Single Stat
- **Time Range**: 1 hour
- **Thresholds**: Green <1%, Yellow 1-5%, Red >5%

### 9. Failed Events Analysis
### 9.1 High-Severity Logs Drilldown (Comfort Cat)

Purpose: Quickly isolate actionable logs and surface hotspots

Filters:
```
severity_text in ["ERROR","WARN"]
```

Grouping:
- Group by: `service.name`, `severity_text`

Optional keyword slice:
```
severity_text in ["ERROR","WARN"] AND message contains "login"
```

SigNoz UI Steps:
1. Logs -> set Time Range to Last 15 minutes
2. Add filter: `severity_text` is in `ERROR, WARN`
3. (Optional) Add keyword in search bar
4. Group by `service.name`, `severity_text`
5. Expand a log -> Attributes; open "View related trace" if shown


**Purpose**: Identify problematic analytics events

**Query**:
```sql
count by (attributes.event) WHERE attributes.dataset = "resonai_analytics" AND level="ERROR"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics" AND level="ERROR"`
3. Add Group By: `attributes.event`
4. Order by count descending

**Dashboard Panel**:
- **Title**: "Failed Events"
- **Type**: Table
- **Time Range**: 24 hours

## A/B Testing Analytics

### 10. Variant Performance Comparison

**Purpose**: Compare A/B test variant performance

**Query**:
```sql
count by (attributes.variant, attributes.event) WHERE attributes.dataset = "resonai_analytics"
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.variant`, `attributes.event`
4. Compare conversion rates

**Dashboard Panel**:
- **Title**: "A/B Test Performance"
- **Type**: Bar Chart
- **Time Range**: 24 hours
- **Group By**: `attributes.variant`

### 11. Conversion Funnel Analysis

**Purpose**: Track user journey through key events

**Query**:
```sql
count by (attributes.event) WHERE attributes.dataset = "resonai_analytics" AND attributes.event IN ("screen_view", "permission_granted", "mic_session_start", "activation")
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.event`
4. Filter for funnel events
5. Calculate conversion rates

**Dashboard Panel**:
- **Title**: "User Journey Funnel"
- **Type**: Funnel Chart
- **Time Range**: 24 hours
- **Events**: screen_view -> permission_granted -> mic_session_start -> activation

## Performance Monitoring

### 12. TTV Distribution by Event

**Purpose**: Identify which events have performance issues

**Query**:
```sql
quantile(0.9, attributes.ttv_ms) by (attributes.event) WHERE attributes.dataset = "resonai_analytics" AND attributes.ttv_ms IS NOT NULL
```

**SigNoz UI Steps**:
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "resonai_analytics" AND attributes.ttv_ms IS NOT NULL`
3. Add Group By: `attributes.event`
4. Calculate p90 TTV

**Dashboard Panel**:
- **Title**: "TTV by Event (p90)"
- **Type**: Bar Chart
- **Time Range**: 24 hours
- **Thresholds**: Green <300ms, Yellow 300-600ms, Red >600ms

## Alerting Queries

### 13. High Error Rate Alert

**Purpose**: Alert when analytics error rate spikes

**Query**:
```sql
count(level="ERROR") / count(*) > 0.05 WHERE attributes.dataset = "resonai_analytics"
```

**Alert Configuration**:
- **Condition**: Above query returns true
- **Duration**: 5 minutes
- **Severity**: Critical

### 14. Low Activation Rate Alert

**Purpose**: Alert when activation rate drops

**Query**:
```sql
count(attributes.event="activation") / count(attributes.event="screen_view") < 0.02 WHERE attributes.dataset = "resonai_analytics"
```

**Alert Configuration**:
- **Condition**: Above query returns true
- **Duration**: 10 minutes
- **Severity**: Warning

### 15. High TTV Alert

**Purpose**: Alert when TTV performance degrades

**Query**:
```sql
quantile(0.95, attributes.ttv_ms) > 1000 WHERE attributes.dataset = "resonai_analytics" AND attributes.event="ttv_measured"
```

**Alert Configuration**:
- **Condition**: Above query returns true
- **Duration**: 5 minutes
- **Severity**: Warning

## API Usage Examples

### Using SigNoz API for Programmatic Queries

```bash
# Set up authentication
export SIGNOZ_API_TOKEN="your-token-here"

# Query recent analytics events
curl -X POST "http://localhost:8080/api/v5/query_range" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $SIGNOZ_API_TOKEN" \
  -d '{
    "start": 1640995200000,
    "end": 1640995260000,
    "requestType": "raw",
    "compositeQuery": {
      "queries": [{
        "type": "builder_query",
        "spec": {
          "name": "analytics_events",
          "signal": "logs",
          "filter": {
            "expression": "attributes.dataset = \"resonai_analytics\""
          },
          "order": [{"key": {"name": "timestamp"}, "direction": "desc"}],
          "limit": 100
        }
      }]
    }
  }'
```

## Dashboard Templates

### Complete Analytics Dashboard

1. **Overview Row**:
   - Event Volume (24h)
   - Error Rate (1h)
   - Activation Rate (24h)
   - TTV p50 (24h)

2. **Performance Row**:
   - TTV Percentiles (p50, p90, p95, p99)
   - TTV by Event
   - Session Duration Distribution

3. **User Behavior Row**:
   - Top Events by Volume
   - Conversion Funnel
   - Cohort Performance
   - A/B Test Results

4. **Monitoring Row**:
   - Failed Events
   - Error Trends
   - System Health
   - Alert Status

This comprehensive set of queries provides full observability into Resonai analytics performance and user behavior patterns.

## Infrastructure Monitoring (Local Host)

### Disk Usage Monitor

**Purpose**: Track disk usage readings generated by `monitor-disk-usage.ps1` with threshold-based alerting.

#### Core Queries

**All disk monitoring logs:**
```
attributes.dataset = "disk-monitor"
```

**Current disk usage percentage:**
```
attributes.percent_used WHERE attributes.dataset = "disk-monitor"
```

**Critical disk usage events:**
```
attributes.dataset = "disk-monitor" AND attributes.status = "critical"
```

**Warning disk usage events:**
```
attributes.dataset = "disk-monitor" AND attributes.status = "warning"
```

**Free space by drive:**
```
attributes.free_gb WHERE attributes.dataset = "disk-monitor"
```

#### Dashboard Panels

**1. Disk Usage Overview**
- Type: Single Stat
- Query: `attributes.percent_used` WHERE `attributes.dataset = "disk-monitor"`
- Time Range: Last 5 minutes
- Thresholds: Green <80%, Yellow 80-90%, Red >90%

**2. Disk Usage Trend**
- Type: Time Series
- Query: `attributes.percent_used` WHERE `attributes.dataset = "disk-monitor"`
- Time Range: 24 hours
- Group By: `attributes.drive`

**3. Free Space Alert**
- Type: Table
- Query: `attributes.free_gb, attributes.drive` WHERE `attributes.dataset = "disk-monitor"`
- Time Range: Last 5 minutes
- Sort: `attributes.free_gb` ascending

**4. Drive Status Summary**
- Type: Table
- Query: `attributes.drive, attributes.status, attributes.percent_used, attributes.free_gb` WHERE `attributes.dataset = "disk-monitor"`
- Time Range: Last 5 minutes
- Group By: `attributes.drive`

#### Alert Queries

**High disk usage warning:**
```
count() WHERE attributes.dataset = "disk-monitor" AND attributes.status = "warning" OVER last 5 minutes
```

**Critical disk usage:**
```
count() WHERE attributes.dataset = "disk-monitor" AND attributes.status = "critical" OVER last 1 minute
```

**Low free space:**
```
attributes.free_gb < 10 WHERE attributes.dataset = "disk-monitor"
```

#### SigNoz UI Steps
1. Go to Logs -> Query Builder
2. Filter: `attributes.dataset = "disk-monitor"`
3. Optional: add status filter (`attributes.status = "critical"` or `"warning"`)
4. Group by drive: `attributes.drive`
5. Use appropriate visualization (Single Stat, Time Series, Table)

#### Setup Commands
```powershell
# Setup monitoring
pwsh -File scripts/setup-disk-monitoring.ps1 -RunNow

# Generate alerts
pwsh -File scripts/setup-disk-alerts.ps1

# Manual check
pwsh -File scripts/monitor-disk-usage.ps1
```

For complete setup guide, see [DISK_MONITORING_GUIDE.md](DISK_MONITORING_GUIDE.md).




