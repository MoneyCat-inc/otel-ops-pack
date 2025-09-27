# Runbook: Agent Job Failures

**Service**: Agent Worker  
**Signal**: `increase(jobs_failed_total[15m]) > 0` (alert: AgentJobFailures)  
**SLO**: Job failure rate ≤ 1% (rolling 7d)

## 1) Triage (5–10 min)

### Immediate Checks
- [ ] Check SigNoz for `agent.job.run` ERROR spans in last 15m
- [ ] Inspect attributes: `job_type`, `attempt`, exception message
- [ ] Prometheus: `rate(jobs_failed_total[5m])` and `queue_depth`
- [ ] Check agent logs: `tail -f .agent/logs/agent.log`

### SigNoz Queries
```
# Find failed jobs in last 15 minutes
trace_id != "" AND status = "ERROR" AND service.name = "agent-task-management"

# Filter by job type
trace_id != "" AND status = "ERROR" AND attributes.job_type = "ecrr_bridge"

# Check for specific error patterns
trace_id != "" AND status = "ERROR" AND attributes.exception.message contains "timeout"
```

### Prometheus Queries
```promql
# Current failure rate
rate(jobs_failed_total[5m]) / rate(jobs_processed_total[5m])

# Queue depth
queue_depth

# Failure rate by job type
rate(jobs_failed_total[5m]) by (job_type) / rate(jobs_processed_total[5m]) by (job_type)
```

## 2) Common Causes & Quick Fixes

### Budget Exceeded
**Symptoms**: "Budget exceeded" errors, early job termination
**Fix**: 
- Reduce job size in `.agent/config.json`
- Check file count: `find . -name "*.ps1" | wc -l`
- Check LOC count: `find . -name "*.ps1" -exec wc -l {} + | tail -1`

### External Flake
**Symptoms**: Intermittent failures, network timeouts
**Fix**: 
- Quarantine via flake job: `node scripts/agent/flake-dequarantine.mjs`
- Verify nightly retries are working
- Check external service health

### Collector Down
**Symptoms**: OTLP export failures, telemetry errors
**Fix**: 
- Check collector status: `docker ps | grep otel-collector`
- Restart collector: `docker restart otel-collector`
- Verify telemetry is best-effort (agent should still run)

### Resource Exhaustion
**Symptoms**: Memory errors, CPU spikes, disk space issues
**Fix**:
- Check resource usage: `top`, `htop`, `df -h`
- Scale resources: `docker run --memory=4g otel-collector`
- Clean up old artifacts: `rm -rf artifacts/*.old`

## 3) Decision Tree

### High Priority (Critical)
- **Queue depth > 3 AND failure ratio > 5%**
  - Enable auto-throttle (expect recovery within 15m)
  - Check for stuck jobs: `ps aux | grep agent`
  - Consider emergency stop: `touch .agent/LOCK`

### Medium Priority (Warning)
- **Same job_type failing repeatedly**
  - Pause lane via `.agent/LOCK`
  - Investigate specific job type
  - Fix root cause, then resume

### Low Priority (Info)
- **Intermittent failures < 1%**
  - Monitor for 30 minutes
  - Check if pattern emerges
  - Document for future investigation

## 4) Auto-Throttle Activation

### When to Enable
- Queue depth sustained > 3 for 10+ minutes
- Failure rate > 5% for 5+ minutes
- System resource usage > 80%

### How to Enable
```bash
# Set environment variables
export AGENT_THROTTLE_THRESHOLD=3
export AGENT_CRITICAL_THRESHOLD=6
export AGENT_MAX_SLEEP_MS=15000

# Restart agent with throttling
pwsh -File .agent/scripts/status-synchronizer.ps1
```

### Monitor Recovery
- Queue depth should decrease within 15 minutes
- Failure rate should return to < 1%
- System resources should stabilize

## 5) Escalation

### Page On-Call When
- `SLOBurn_fast` fires (critical) for >15m
- Queue depth > 10 for >30m
- Failure rate > 10% for >15m
- System completely unresponsive

### Escalation Contacts
- **Primary**: On-call engineer
- **Secondary**: Team lead
- **Emergency**: CTO

### Information to Provide
- Error messages and stack traces
- SigNoz trace IDs
- Prometheus query results
- Steps already taken
- Impact assessment

## 6) Post-Incident

### Immediate Actions
- [ ] Add test or guard to prevent recurrence
- [ ] Link PR + SSOT entry
- [ ] Tag failures with cause label for future triage
- [ ] Update runbook if new patterns discovered

### Follow-up Actions
- [ ] Root cause analysis within 24 hours
- [ ] Implement permanent fix within 1 week
- [ ] Update monitoring and alerting
- [ ] Conduct post-mortem if severity > warning

### Documentation
- [ ] Update troubleshooting guide
- [ ] Add new alert rules if needed
- [ ] Update SLO targets if appropriate
- [ ] Share learnings with team

## 7) Prevention

### Proactive Monitoring
- [ ] Daily health checks
- [ ] Weekly capacity planning
- [ ] Monthly performance review
- [ ] Quarterly SLO review

### Best Practices
- [ ] Keep job sizes small (< 10 files, < 200 LOC)
- [ ] Implement proper error handling
- [ ] Use circuit breakers for external calls
- [ ] Regular dependency updates

### Testing
- [ ] Load testing with realistic data
- [ ] Chaos engineering for resilience
- [ ] Regular disaster recovery drills
- [ ] Automated testing for critical paths

---

**Last Updated**: 2025-09-27  
**Version**: 1.0.0  
**Maintainer**: Cursor Agent (Observability Copilot)
