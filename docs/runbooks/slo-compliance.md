# Runbook: SLO Compliance

**Service**: Service Level Objectives  
**Signal**: SLO violation alerts (SLOAvailabilityViolation, SLOLatencyViolation, SLOStabilityViolation)  
**SLOs**: Availability ≥ 99%, Latency P95 ≤ 15s, Stability (no increase in flaky tests)

## 1) Triage (5–10 min)

### Immediate Checks
- [ ] Check SLO violation type and severity
- [ ] Review 7-day rolling metrics
- [ ] Check current system state
- [ ] Assess impact on users

### Prometheus Queries
```promql
# Availability SLO (7-day rolling)
slo_availability:7d

# Latency SLO (7-day rolling)
slo_latency_p95:7d

# Stability SLO (7-day rolling)
slo_stability:7d

# Current metrics
rate(jobs_processed_total[5m])
rate(jobs_failed_total[5m])
histogram_quantile(0.95, sum by (le)(rate(job_duration_ms_bucket[5m])))
ci_flaky_tests_count
```

### SigNoz Queries
```
# Service availability
trace_id != "" AND service.name = "agent-task-management" AND status = "ERROR"

# Latency analysis
trace_id != "" AND service.name = "agent-task-management" AND attributes.duration_ms > 15000

# Stability issues
trace_id != "" AND service.name = "flake-detector" AND attributes.event = "flake_detected"
```

## 2) SLO Violation Types

### Availability Violation (SLO < 99%)
**Symptoms**: High failure rate, service unavailability
**Impact**: Users cannot complete tasks
**Priority**: Critical

### Latency Violation (P95 > 15s)
**Symptoms**: Slow response times, user frustration
**Impact**: Poor user experience
**Priority**: High

### Stability Violation (Flaky tests increasing)
**Symptoms**: Inconsistent test results, reduced confidence
**Impact**: Development velocity, code quality
**Priority**: Medium

## 3) Decision Tree

### Critical (Availability < 95%)
- **Immediate action required**
  - Check system health
  - Enable auto-throttle
  - Consider emergency stop
  - Page on-call immediately

### High (Availability < 99% OR Latency > 30s)
- **Investigate and fix**
  - Check specific issues
  - Implement fixes
  - Monitor recovery
  - Prepare for escalation

### Medium (Latency > 15s OR Stability issues)
- **Monitor and plan**
  - Track trends
  - Plan improvements
  - Document issues
  - Schedule fixes

## 4) Recovery Actions

### Availability Recovery
1. **Identify root cause**
   - Check system health
   - Review error logs
   - Check external dependencies

2. **Implement fixes**
   - Fix immediate issues
   - Implement circuit breakers
   - Add retry logic

3. **Monitor recovery**
   - Track availability metrics
   - Verify SLO compliance
   - Document lessons learned

### Latency Recovery
1. **Identify bottlenecks**
   - Check system resources
   - Review slow queries
   - Check external dependencies

2. **Optimize performance**
   - Scale resources
   - Optimize algorithms
   - Implement caching

3. **Monitor recovery**
   - Track latency metrics
   - Verify SLO compliance
   - Document improvements

### Stability Recovery
1. **Identify flaky tests**
   - Review test reports
   - Check test environment
   - Review recent changes

2. **Fix stability issues**
   - Fix flaky tests
   - Improve test isolation
   - Add proper timeouts

3. **Monitor recovery**
   - Track stability metrics
   - Verify SLO compliance
   - Document improvements

## 5) SLO Monitoring

### Daily Checks
- [ ] Review SLO compliance dashboard
- [ ] Check for violations
- [ ] Monitor trends
- [ ] Document issues

### Weekly Reviews
- [ ] Analyze SLO trends
- [ ] Review violation patterns
- [ ] Plan improvements
- [ ] Update targets if needed

### Monthly Reviews
- [ ] Comprehensive SLO analysis
- [ ] Review and update SLOs
- [ ] Plan capacity improvements
- [ ] Document lessons learned

## 6) Escalation

### Page On-Call When
- Availability < 95% for >15m
- Latency > 60s for >15m
- Multiple SLO violations
- System completely unresponsive

### Escalation Contacts
- **Primary**: On-call engineer
- **Secondary**: Team lead
- **Emergency**: CTO

### Information to Provide
- SLO violation details
- Current metrics
- Impact assessment
- Steps already taken
- Recovery timeline

## 7) Post-Incident

### Immediate Actions
- [ ] Document SLO violation
- [ ] Identify root cause
- [ ] Implement fixes
- [ ] Monitor recovery

### Follow-up Actions
- [ ] Root cause analysis within 24 hours
- [ ] Implement permanent fixes within 1 week
- [ ] Update SLO targets if appropriate
- [ ] Conduct post-mortem if severity > warning

### Documentation
- [ ] Update SLO documentation
- [ ] Add new alert rules if needed
- [ ] Update monitoring and alerting
- [ ] Share learnings with team

## 8) SLO Management

### Setting SLOs
- **Availability**: Based on user impact
- **Latency**: Based on user expectations
- **Stability**: Based on development needs

### Updating SLOs
- **Review quarterly**: Assess if targets are appropriate
- **Consider user feedback**: Adjust based on user needs
- **Monitor trends**: Update based on system performance
- **Document changes**: Keep SLO documentation current

### SLO Communication
- **Team awareness**: Ensure team understands SLOs
- **User communication**: Communicate SLO status to users
- **Stakeholder updates**: Regular updates to stakeholders
- **Documentation**: Keep SLO documentation current

## 9) Prevention

### Proactive Monitoring
- [ ] Daily SLO compliance checks
- [ ] Weekly trend analysis
- [ ] Monthly capacity planning
- [ ] Quarterly SLO review

### Best Practices
- [ ] Set realistic SLO targets
- [ ] Monitor SLO compliance
- [ ] Implement proper alerting
- [ ] Regular SLO reviews

### Testing
- [ ] Load testing for capacity
- [ ] Chaos engineering for resilience
- [ ] SLO compliance testing
- [ ] Regular disaster recovery drills

---

**Last Updated**: 2025-09-27  
**Version**: 1.0.0  
**Maintainer**: Cursor Agent (Observability Copilot)
