# Resonai Backend - Monitoring and Alerting Setup
# Comprehensive monitoring configuration for production deployment

## 🎯 Monitoring Overview

This document provides a complete monitoring and alerting setup for the Resonai backend, integrating with SigNoz for observability and ensuring privacy compliance.

## 📊 SigNoz Dashboard Configuration

### Core Metrics Dashboard

```json
{
  "dashboard": {
    "title": "Resonai Backend - Core Metrics",
    "panels": [
      {
        "title": "API Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "{{method}} {{route}}"
          }
        ]
      },
      {
        "title": "API Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p95"
          },
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p50"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m]) / rate(http_requests_total[5m])",
            "legendFormat": "Error Rate"
          }
        ]
      },
      {
        "title": "Active Users",
        "type": "stat",
        "targets": [
          {
            "expr": "count by (cohort) (resonai_engagement_events_total{event=\"session_start\"})",
            "legendFormat": "Active Users"
          }
        ]
      }
    ]
  }
}
```

### Privacy Compliance Dashboard

```json
{
  "dashboard": {
    "title": "Resonai Backend - Privacy Compliance",
    "panels": [
      {
        "title": "PII Detection Events",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(resonai_privacy_events_total{event_type=\"pii_detected\"}[5m])",
            "legendFormat": "PII Detected"
          }
        ]
      },
      {
        "title": "Consent Changes",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(resonai_privacy_events_total{event_type=\"consent_change\"}[5m])",
            "legendFormat": "Consent Changes"
          }
        ]
      },
      {
        "title": "Data Export Requests",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(resonai_privacy_events_total{event_type=\"data_export\"}[5m])",
            "legendFormat": "Data Exports"
          }
        ]
      },
      {
        "title": "Account Deletions",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(resonai_privacy_events_total{event_type=\"data_deletion\"}[5m])",
            "legendFormat": "Account Deletions"
          }
        ]
      }
    ]
  }
}
```

### Engagement Analytics Dashboard

```json
{
  "dashboard": {
    "title": "Resonai Backend - Engagement Analytics",
    "panels": [
      {
        "title": "Session Events",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(resonai_engagement_events_total{event=\"session_start\"}[5m])",
            "legendFormat": "Session Starts"
          },
          {
            "expr": "rate(resonai_engagement_events_total{event=\"session_end\"}[5m])",
            "legendFormat": "Session Ends"
          }
        ]
      },
      {
        "title": "Badge Unlocks",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(resonai_engagement_events_total{event=\"badge_unlock\"}[5m])",
            "legendFormat": "Badge Unlocks"
          }
        ]
      },
      {
        "title": "Streak Activity",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(resonai_engagement_events_total{event=\"streak_tick\"}[5m])",
            "legendFormat": "Streak Updates"
          }
        ]
      },
      {
        "title": "Cohort Distribution",
        "type": "pie",
        "targets": [
          {
            "expr": "count by (cohort) (resonai_engagement_events_total)",
            "legendFormat": "{{cohort}}"
          }
        ]
      }
    ]
  }
}
```

## 🚨 Alerting Rules

### Critical Alerts

```yaml
groups:
  - name: resonai-backend-critical
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
        for: 2m
        labels:
          severity: critical
          service: resonai-backend
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value | humanizePercentage }} for the last 5 minutes"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: critical
          service: resonai-backend
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s"

      - alert: ServiceDown
        expr: up{job="resonai-backend"} == 0
        for: 1m
        labels:
          severity: critical
          service: resonai-backend
        annotations:
          summary: "Resonai backend service is down"
          description: "Service has been down for more than 1 minute"

      - alert: DatabaseConnectionFailed
        expr: resonai_database_health_check == 0
        for: 2m
        labels:
          severity: critical
          service: resonai-backend
        annotations:
          summary: "Database connection failed"
          description: "Database health check is failing"

### Warning Alerts

      - alert: HighMemoryUsage
        expr: (resonai_memory_usage_bytes / resonai_memory_total_bytes) > 0.8
        for: 10m
        labels:
          severity: warning
          service: resonai-backend
        annotations:
          summary: "High memory usage"
          description: "Memory usage is {{ $value | humanizePercentage }}"

      - alert: HighCPUUsage
        expr: resonai_cpu_usage_percent > 80
        for: 10m
        labels:
          severity: warning
          service: resonai-backend
        annotations:
          summary: "High CPU usage"
          description: "CPU usage is {{ $value }}%"

      - alert: LowDiskSpace
        expr: (resonai_disk_free_bytes / resonai_disk_total_bytes) < 0.1
        for: 5m
        labels:
          severity: warning
          service: resonai-backend
        annotations:
          summary: "Low disk space"
          description: "Disk space is {{ $value | humanizePercentage }} free"

### Privacy Compliance Alerts

      - alert: PIIDetectionSpike
        expr: rate(resonai_privacy_events_total{event_type="pii_detected"}[5m]) > 10
        for: 1m
        labels:
          severity: critical
          service: resonai-backend
          compliance: privacy
        annotations:
          summary: "PII detection spike"
          description: "High rate of PII detection events: {{ $value }} per second"

      - alert: ConsentChangeSpike
        expr: rate(resonai_privacy_events_total{event_type="consent_change"}[5m]) > 5
        for: 2m
        labels:
          severity: warning
          service: resonai-backend
          compliance: privacy
        annotations:
          summary: "Consent change spike"
          description: "High rate of consent changes: {{ $value }} per second"

      - alert: DataExportSpike
        expr: rate(resonai_privacy_events_total{event_type="data_export"}[5m]) > 2
        for: 2m
        labels:
          severity: warning
          service: resonai-backend
          compliance: privacy
        annotations:
          summary: "Data export spike"
          description: "High rate of data export requests: {{ $value }} per second"

### Engagement Alerts

      - alert: LowEngagement
        expr: rate(resonai_engagement_events_total{event="session_start"}[1h]) < 1
        for: 30m
        labels:
          severity: warning
          service: resonai-backend
          category: engagement
        annotations:
          summary: "Low user engagement"
          description: "Very low session start rate: {{ $value }} per hour"

      - alert: EngagementDrop
        expr: (rate(resonai_engagement_events_total{event="session_start"}[1h]) / rate(resonai_engagement_events_total{event="session_start"}[1h] offset 1h)) < 0.5
        for: 1h
        labels:
          severity: warning
          service: resonai-backend
          category: engagement
        annotations:
          summary: "Significant engagement drop"
          description: "Engagement dropped by {{ $value | humanizePercentage }} compared to previous hour"
```

## 📈 Custom Metrics

### Resonai-Specific Metrics

```typescript
// Engagement metrics
const engagementCounter = new Counter({
  name: 'resonai_engagement_events_total',
  help: 'Total engagement events',
  labelNames: ['event', 'cohort', 'user_id_hash'],
});

const engagementDuration = new Histogram({
  name: 'resonai_session_duration_seconds',
  help: 'Session duration in seconds',
  labelNames: ['cohort'],
  buckets: [30, 60, 300, 600, 1800, 3600],
});

// Privacy metrics
const privacyCounter = new Counter({
  name: 'resonai_privacy_events_total',
  help: 'Total privacy-related events',
  labelNames: ['event_type', 'user_id_hash'],
});

const consentGauge = new Gauge({
  name: 'resonai_consent_settings_total',
  help: 'Total consent settings by type',
  labelNames: ['consent_type', 'value'],
});

// Coach portal metrics
const coachGrantCounter = new Counter({
  name: 'resonai_coach_grants_total',
  help: 'Total coach grants created',
  labelNames: ['scope', 'coach_id'],
});

const coachAccessCounter = new Counter({
  name: 'resonai_coach_access_total',
  help: 'Total coach portal accesses',
  labelNames: ['grant_id', 'coach_id'],
});

// System metrics
const databaseHealthGauge = new Gauge({
  name: 'resonai_database_health_check',
  help: 'Database health check status',
});

const backgroundJobCounter = new Counter({
  name: 'resonai_background_jobs_total',
  help: 'Total background jobs processed',
  labelNames: ['job_type', 'status'],
});
```

## 🔍 SigNoz Queries

### Performance Queries

```sql
-- API Performance
SELECT 
  route,
  method,
  percentile(99, duration_ms) as p99_latency,
  percentile(95, duration_ms) as p95_latency,
  percentile(50, duration_ms) as p50_latency,
  count(*) as total_requests
FROM api_requests 
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY route, method
ORDER BY p99_latency DESC;

-- Error Rate by Route
SELECT 
  route,
  count(*) FILTER (WHERE status_code >= 400) as error_count,
  count(*) as total_count,
  (count(*) FILTER (WHERE status_code >= 400)::float / count(*)) * 100 as error_rate
FROM api_requests 
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY route
HAVING count(*) > 10
ORDER BY error_rate DESC;
```

### Engagement Queries

```sql
-- User Engagement Trends
SELECT 
  DATE_TRUNC('hour', timestamp) as hour,
  count(*) FILTER (WHERE event = 'session_start') as sessions_started,
  count(*) FILTER (WHERE event = 'session_end') as sessions_ended,
  count(*) FILTER (WHERE event = 'badge_unlock') as badges_unlocked
FROM events 
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour;

-- Cohort Analysis
SELECT 
  cohort,
  count(DISTINCT user_id_hash) as unique_users,
  count(*) as total_events,
  avg(extract(epoch from (max(timestamp) - min(timestamp)))) as avg_session_duration
FROM events 
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY cohort
ORDER BY unique_users DESC;
```

### Privacy Compliance Queries

```sql
-- Privacy Event Summary
SELECT 
  event_type,
  count(*) as event_count,
  count(DISTINCT user_id_hash) as unique_users
FROM privacy_events 
WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY event_type
ORDER BY event_count DESC;

-- Consent Changes Over Time
SELECT 
  DATE_TRUNC('hour', timestamp) as hour,
  field,
  count(*) as changes
FROM consent_audit_log 
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY hour, field
ORDER BY hour, field;
```

## 🚀 Deployment Commands

### Start Monitoring Stack

```bash
# Start SigNoz stack
docker-compose up -d signoz-frontend signoz-otel-collector clickhouse

# Start Resonai backend with monitoring
docker-compose up -d resonai-backend

# Verify monitoring
curl http://localhost:8080/api/v1/health
curl http://localhost:8889/metrics
```

### Import Dashboards

```bash
# Import core metrics dashboard
curl -X POST http://localhost:8080/api/v1/dashboards \
  -H "Content-Type: application/json" \
  -d @monitoring/dashboards/core-metrics.json

# Import privacy compliance dashboard
curl -X POST http://localhost:8080/api/v1/dashboards \
  -H "Content-Type: application/json" \
  -d @monitoring/dashboards/privacy-compliance.json

# Import engagement analytics dashboard
curl -X POST http://localhost:8080/api/v1/dashboards \
  -H "Content-Type: application/json" \
  -d @monitoring/dashboards/engagement-analytics.json
```

### Setup Alerting

```bash
# Create alert rules
curl -X POST http://localhost:8080/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d @monitoring/alerts/critical-alerts.yaml

# Setup notification channels
curl -X POST http://localhost:8080/api/v1/notification-channels \
  -H "Content-Type: application/json" \
  -d @monitoring/notifications/slack-webhook.json
```

## 📋 Monitoring Checklist

### Daily Checks
- [ ] API response times < 200ms p95
- [ ] Error rate < 1%
- [ ] Database connection health
- [ ] SigNoz collector status
- [ ] Background job completion

### Weekly Checks
- [ ] Privacy compliance metrics
- [ ] Engagement trends
- [ ] Resource utilization
- [ ] Alert rule effectiveness
- [ ] Dashboard accuracy

### Monthly Checks
- [ ] Retention policy compliance
- [ ] Data export/deletion metrics
- [ ] Coach portal usage
- [ ] Performance optimization opportunities
- [ ] Security audit results

This comprehensive monitoring setup ensures the Resonai backend operates reliably while maintaining strict privacy compliance and providing actionable insights into user engagement patterns.
