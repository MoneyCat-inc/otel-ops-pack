# Dashboard Sanity Targets - ECRR Report

**Date**: 2025-09-27 04:35:31  
**Actor**: Cursor Agent (Observability Copilot)  
**Status**: ✅ COMPLETE

## 🔍 Examine - Current State
- **Post-Merge**: System deployed and operational
- **Monitoring Need**: First week sanity targets and alerts
- **Dashboard**: Comprehensive monitoring interface required
- **Targets**: Throughput, failure rate, latency, queue health, stability

## 🧹 Clean - Dashboard Actions
- **Sanity Targets**: Defined for first week monitoring
- **Dashboard Panels**: 8 panels for comprehensive monitoring
- **Alert Rules**: 5 alerts for critical conditions
- **Monitoring Schedule**: Daily and weekly review schedule

## 📝 Report - Dashboard Results

### Sanity Targets
- **Queue depth P95**
  - Metric: queue_depth
  - Target: ≤ 1
  - Threshold: 1
  - Query: histogram_quantile(0.95, queue_depth)
  - Alert: histogram_quantile(0.95, queue_depth) > 1
- **Job processing throughput**
  - Metric: jobs_processed_total
  - Target: increasing daily
  - Threshold: > 0 jobs/day
  - Query: increase(jobs_processed_total[1d])
  - Alert: rate(jobs_processed_total[1d]) == 0
- **Flaky test count**
  - Metric: ci_flaky_tests_count
  - Target: flat or trending down
  - Threshold: week-over-week decrease
  - Query: ci_flaky_tests_count
  - Alert: increase(ci_flaky_tests_count[7d]) > 0
- **Job failure rate on PR lane**
  - Metric: job_failure_rate
  - Target: < 1%
  - Threshold: 0.01
  - Query: rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m])
  - Alert: rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m]) > 0.01
- **Job duration P95**
  - Metric: job_duration_ms
  - Target: < 15s
  - Threshold: 15000
  - Query: histogram_quantile(0.95, rate(job_duration_ms_bucket[5m]))
  - Alert: histogram_quantile(0.95, rate(job_duration_ms_bucket[5m])) > 15000
### Dashboard Panels
- **Job Throughput**
  - Type: graph
  - Query: rate(jobs_processed_total[5m])
  - Target: > 0
- **Failure Rate**
  - Type: stat
  - Query: rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m]) * 100
  - Target: < 1%
- **Job Duration P95**
  - Type: graph
  - Query: histogram_quantile(0.95, rate(job_duration_ms_bucket[5m]))
  - Target: < 15000
- **Queue Depth**
  - Type: graph
  - Query: queue_depth
  - Target: ≤ 1
- **Flaky Tests**
  - Type: stat
  - Query: ci_flaky_tests_count
  - Target: trending down
- **System Health Score**
  - Type: stat
  - Query: system_health_score
  - Target: > 80%
- **OTLP Exporter Status**
  - Type: stat
  - Query: otlp_exporter_up
  - Target: = 1
- **Memory Usage**
  - Type: graph
  - Query: process_resident_memory_bytes / 1024 / 1024 / 1024
  - Target: < 2
### Alert Rules
- **ThroughputStopped**
  - Condition: rate(jobs_processed_total[1h]) == 0
  - Severity: critical
  - Description: Job processing has stopped
- **HighFailureRate**
  - Condition: rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m]) > 0.01
  - Severity: warning
  - Description: Failure rate exceeds 1%
- **HighLatency**
  - Condition: histogram_quantile(0.95, rate(job_duration_ms_bucket[5m])) > 15000
  - Severity: warning
  - Description: Job latency P95 > 15s
- **QueueBacklog**
  - Condition: queue_depth > 3
  - Severity: warning
  - Description: Queue depth > 3
- **FlakyTestsIncreasing**
  - Condition: increase(ci_flaky_tests_count[24h]) > 3
  - Severity: info
  - Description: Flaky test count increasing
### Monitoring Schedule
- **Daily Check**: 09:00 UTC
- **Weekly Review**: Monday 09:00 UTC
- **Escalation**: 24 hours
- **Reporting**: ECRR report generated

### Configuration Files
- **Dashboard Config**: artifacts/dashboard-sanity-targets.json
- **Timeframe**: 7 days
- **Panels**: 8
- **Targets**: 5
- **Alerts**: 5

## 🎭 Role - Actor Declaration
**Cursor Agent (Observability Copilot)**: Defined sanity targets, created dashboard configuration, implemented monitoring schedule, generated ECRR report.

## ✅ ECRR Gate
- **Examine**: ✅ Current state captured and analyzed
- **Clean**: ✅ Dashboard sanity targets implemented
- **Report**: ✅ Implementation results documented
- **Role**: ✅ Actor declared and responsibilities clear

---
**Dashboard Sanity Targets Complete**: 7-day monitoring plan operational
