# Runbook: Agent Latency

**Service**: Agent Worker  
**Signal**: `histogram_quantile(0.95, sum by (le)(rate(job_duration_ms_bucket[5m]))) > 15000` (alert: JobLatencyP95High)  
**SLO**: `agent.job.run` P95 ≤ 15s (rolling 7d)

## 1) Triage (5–10 min)

### Immediate Checks
- [ ] Check SigNoz for slow `agent.job.run` spans in last 15m
- [ ] Inspect attributes: `job_type`, `duration_ms`, `queue_depth`
- [ ] Prometheus: `histogram_quantile(0.95, rate(job_duration_ms_bucket[5m]))`
- [ ] Check system resources: CPU, memory, disk I/O

### SigNoz Queries
```
# Find slow jobs in last 15 minutes
trace_id != "" AND service.name = "agent-task-management" AND attributes.duration_ms > 15000

# Filter by job type
trace_id != "" AND service.name = "agent-task-management" AND attributes.job_type = "migration" AND attributes.duration_ms > 15000

# Check for specific slow patterns
trace_id != "" AND service.name = "agent-task-management" AND attributes.duration_ms > 30000
```

### Prometheus Queries
```promql
# Current P95 latency
histogram_quantile(0.95, sum by (le)(rate(job_duration_ms_bucket[5m])))

# Latency by job type
histogram_quantile(0.95, sum by (le, job_type)(rate(job_duration_ms_bucket[5m])))

# Queue depth correlation
queue_depth

# System resource usage
process_cpu_seconds_total
process_resident_memory_bytes
```

## 2) Common Causes & Quick Fixes

### Resource Exhaustion
**Symptoms**: High CPU/memory usage, slow disk I/O
**Fix**: 
- Check system resources: `top`, `htop`, `iostat`
- Scale resources: `docker run --cpus=2 --memory=4g otel-collector`
- Clean up old artifacts: `rm -rf artifacts/*.old`

### Queue Backlog
**Symptoms**: High queue depth, jobs waiting
**Fix**: 
- Enable auto-throttle: `export AGENT_THROTTLE_THRESHOLD=3`
- Check for stuck jobs: `ps aux | grep agent`
- Consider emergency stop: `touch .agent/LOCK`

### External Dependencies
**Symptoms**: Network timeouts, slow API responses
**Fix**: 
- Check external service health
- Implement circuit breakers
- Add retry logic with backoff

### Large Job Processing
**Symptoms**: Specific job types taking longer
**Fix**: 
- Break down large jobs into smaller chunks
- Implement parallel processing
- Add progress indicators

## 3) Decision Tree

### Critical (P95 > 30s)
- **Immediate action required**
  - Enable auto-throttle
  - Check for stuck jobs
  - Consider emergency stop
  - Page on-call if > 15 minutes

### Warning (P95 > 15s)
- **Investigate and monitor**
  - Check specific job types
  - Monitor system resources
  - Look for patterns
  - Prepare for escalation

### Info (P95 > 10s)
- **Monitor and document**
  - Track trends
  - Check for gradual degradation
  - Document for capacity planning

## 4) Auto-Throttle for Latency

### When to Enable
- P95 latency > 30s for 5+ minutes
- Queue depth > 3 for 10+ minutes
- System resource usage > 80%

### Configuration
```bash
# Set environment variables
export AGENT_THROTTLE_THRESHOLD=3
export AGENT_CRITICAL_THRESHOLD=6
export AGENT_MAX_SLEEP_MS=15000
export AGENT_BASE_SLEEP_MS=3000

# Restart agent with throttling
pwsh -File .agent/scripts/status-synchronizer.ps1
```

### Monitor Recovery
- P95 latency should decrease within 15 minutes
- Queue depth should stabilize
- System resources should return to normal

## 5) Performance Optimization

### Job Optimization
- **Break down large jobs**: Split into smaller chunks
- **Parallel processing**: Use multiple workers
- **Progress indicators**: Show job progress
- **Timeout handling**: Set reasonable timeouts

### System Optimization
- **Resource scaling**: Increase CPU/memory
- **Disk optimization**: Use SSD, optimize I/O
- **Network optimization**: Use local endpoints
- **Caching**: Cache frequently accessed data

### Code Optimization
- **Algorithm efficiency**: Use efficient algorithms
- **Memory management**: Avoid memory leaks
- **Database optimization**: Optimize queries
- **API optimization**: Use pagination, filtering

## 6) Escalation

### Page On-Call When
- P95 latency > 60s for >15m
- System completely unresponsive
- Multiple job types affected
- Resource exhaustion

### Escalation Contacts
- **Primary**: On-call engineer
- **Secondary**: Team lead
- **Emergency**: CTO

### Information to Provide
- Latency metrics and trends
- SigNoz trace IDs
- System resource usage
- Steps already taken
- Impact assessment

## 7) Post-Incident

### Immediate Actions
- [ ] Identify root cause
- [ ] Implement temporary fix
- [ ] Monitor recovery
- [ ] Document incident

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

## 8) Prevention

### Proactive Monitoring
- [ ] Daily latency checks
- [ ] Weekly performance review
- [ ] Monthly capacity planning
- [ ] Quarterly SLO review

### Best Practices
- [ ] Keep job sizes small
- [ ] Implement proper timeouts
- [ ] Use circuit breakers
- [ ] Regular performance testing

### Testing
- [ ] Load testing with realistic data
- [ ] Stress testing for limits
- [ ] Performance regression testing
- [ ] Chaos engineering for resilience

---

**Last Updated**: 2025-09-27  
**Version**: 1.0.0  
**Maintainer**: Cursor Agent (Observability Copilot)
