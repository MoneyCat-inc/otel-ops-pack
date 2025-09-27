# SigNoz Query Recipes for Resonai Analytics

This document provides ready-to-use SigNoz query snippets for analyzing Resonai analytics data forwarded via OTLP.

> Cross-project context: for the executive and roadmap view, see the [ECRR Project Report](ECRR_PROJECT_REPORT.md).

## Filter Expressions

All queries should include the base filter to target Resonai analytics:
```
attributes.dataset = "resonai_analytics"
```

## Core Analytics Queries

### 1. Mic Permission Grant Rate

**Purpose**: Track microphone permission acceptance rate over time

**Query**:
```sql
count(attributes.event="permission_granted") / (count(attributes.event="permission_granted") + count(attributes.event="permission_denied")) * 100
```

**SigNoz UI Steps**:
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Logs → set Time Range to Last 15 minutes
2. Add filter: `severity_text` is in `ERROR, WARN`
3. (Optional) Add keyword in search bar
4. Group by `service.name`, `severity_text`
5. Expand a log → Attributes; open “View related trace” if shown


**Purpose**: Identify problematic analytics events

**Query**:
```sql
count by (attributes.event) WHERE attributes.dataset = "resonai_analytics" AND level="ERROR"
```

**SigNoz UI Steps**:
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
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
1. Go to Logs → Query Builder
2. Filter: `attributes.dataset = "resonai_analytics"`
3. Add Group By: `attributes.event`
4. Filter for funnel events
5. Calculate conversion rates

**Dashboard Panel**:
- **Title**: "User Journey Funnel"
- **Type**: Funnel Chart
- **Time Range**: 24 hours
- **Events**: screen_view → permission_granted → mic_session_start → activation

## Queue Pressure Monitoring

### 12. Queue Utilization Ratio

**Purpose**: Monitor OpenTelemetry collector queue pressure in real-time

**Query**:
```sql
rate(otelcol_exporter_queue_size[5m]) / rate(otelcol_exporter_queue_capacity[5m]) * 100
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Query: `rate(otelcol_exporter_queue_size[5m]) / rate(otelcol_exporter_queue_capacity[5m]) * 100`
3. Visualization: Single Stat
4. Unit: Percent (0-100)
5. Thresholds: Green <70%, Yellow 70-80%, Red >80%

**Dashboard Panel**:
- **Title**: "Queue Utilization Ratio"
- **Type**: Single Stat
- **Time Range**: 5 minutes
- **Thresholds**: Green <70%, Yellow 70-80%, Red >80%

### 13. Queue Size vs Capacity Trend

**Purpose**: Track queue size trends over time

**Query**:
```sql
-- Current Queue Size
rate(otelcol_exporter_queue_size[1m])

-- Queue Capacity
rate(otelcol_exporter_queue_capacity[1m])
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Add both queries above
3. Visualization: Time Series
4. Unit: Short (count)
5. Time Range: 24 hours

**Dashboard Panel**:
- **Title**: "Queue Size vs Capacity (24h Trend)"
- **Type**: Time Series
- **Time Range**: 24 hours
- **Interval**: 1 minute

### 14. Send Failure Rate

**Purpose**: Monitor exporter send failure rates

**Query**:
```sql
rate(otelcol_exporter_send_failed_spans[5m]) / rate(otelcol_exporter_sent_spans[5m]) * 100
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Query: Above expression
3. Visualization: Single Stat
4. Unit: Percent (0-10)
5. Thresholds: Green <1%, Yellow 1-5%, Red >5%

**Dashboard Panel**:
- **Title**: "Send Failure Rate"
- **Type**: Single Stat
- **Time Range**: 5 minutes
- **Thresholds**: Green <1%, Yellow 1-5%, Red >5%

### 15. Trace Time-to-Use Percentiles

**Purpose**: Monitor batch processing latency

**Query**:
```sql
-- p50 Latency
histogram_quantile(0.5, rate(otelcol_processor_batch_batch_send_latency_bucket[5m]))

-- p95 Latency
histogram_quantile(0.95, rate(otelcol_processor_batch_batch_send_latency_bucket[5m]))

-- p99 Latency
histogram_quantile(0.99, rate(otelcol_processor_batch_batch_send_latency_bucket[5m]))
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Add all three percentile queries
3. Visualization: Time Series
4. Unit: Milliseconds
5. Time Range: 1 hour

**Dashboard Panel**:
- **Title**: "Trace Time-to-Use (p50/p95/p99)"
- **Type**: Time Series
- **Time Range**: 1 hour
- **Thresholds**: p95 <2s, p99 <5s

### 16. Fractal Drift Detection

**Purpose**: Detect pattern variance in queue behavior

**Query**:
```sql
-- Queue Size Variance
stddev_over_time(rate(otelcol_exporter_queue_size[1m])[1h:1m])

-- Send Failure Variance
stddev_over_time(rate(otelcol_exporter_send_failed_spans[1m])[1h:1m])
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Add both variance queries
3. Visualization: Time Series
4. Unit: Short (variance)
5. Time Range: 24 hours

**Dashboard Panel**:
- **Title**: "Fractal Drift Detection (Pattern Variance)"
- **Type**: Time Series
- **Time Range**: 24 hours
- **Alert**: Variance >2x baseline

### 17. Batch Efficiency

**Purpose**: Monitor batch processing efficiency

**Query**:
```sql
rate(otelcol_processor_batch_batch_send_size_sum[5m]) / rate(otelcol_processor_batch_batch_send_size_count[5m])
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Query: Above expression
3. Visualization: Single Stat
4. Unit: Short (average batch size)
5. Thresholds: Green >200, Yellow 128-200, Red <128

**Dashboard Panel**:
- **Title**: "Batch Efficiency"
- **Type**: Single Stat
- **Time Range**: 5 minutes
- **Thresholds**: Green >200, Yellow 128-200, Red <128

## Fractal Drift Monitoring

### 18. Fractal Drift Detection

**Purpose**: Detect pattern variance in queue behavior and system performance

**Query**:
```sql
-- Queue Size Variance
stddev_over_time(rate(otelcol_exporter_queue_size[1m])[1h:1m])

-- Send Failure Variance
stddev_over_time(rate(otelcol_exporter_send_failed_spans[1m])[1h:1m])

-- Latency Variance
stddev_over_time(histogram_quantile(0.95, rate(otelcol_processor_batch_batch_send_latency_bucket[1m]))[1h:1m])
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Add all three variance queries
3. Visualization: Time Series
4. Unit: Short (variance)
5. Time Range: 24 hours

**Dashboard Panel**:
- **Title**: "Fractal Drift Detection (Pattern Variance Analysis)"
- **Type**: Time Series
- **Time Range**: 24 hours
- **Alert**: Variance >2x baseline

### 19. Memory Usage & Limits

**Purpose**: Monitor collector memory consumption

**Query**:
```sql
-- Memory Usage
otelcol_memory_usage_bytes

-- Memory Limit
otelcol_memory_limit_bytes
```

**SigNoz UI Steps**:
1. Go to Metrics → Query Builder
2. Add both memory queries
3. Visualization: Time Series
4. Unit: Bytes
5. Time Range: 1 hour

**Dashboard Panel**:
- **Title**: "Memory Usage & Limits"
- **Type**: Time Series
- **Time Range**: 1 hour
- **Alert**: Usage >80% of limit

## Performance Monitoring

### 18. TTV Distribution by Event

**Purpose**: Identify which events have performance issues

**Query**:
```sql
quantile(0.9, attributes.ttv_ms) by (attributes.event) WHERE attributes.dataset = "resonai_analytics" AND attributes.ttv_ms IS NOT NULL
```

**SigNoz UI Steps**:
1. Go to Logs → Query Builder
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
