# Runbook: Flake Stability

**Service**: Test Stability  
**Signal**: `increase(ci_flaky_tests_count[24h]) > 3` (alert: FlakyTestsGrowing)  
**SLO**: `ci_flaky_tests_count` does not increase week-over-week

## 1) Triage (5–10 min)

### Immediate Checks
- [ ] Check current flaky test count: `ci_flaky_tests_count`
- [ ] Review recent flake reports: `ls -la .artifacts/flake-report-*.json`
- [ ] Check de-quarantine ledger: `cat .agent/unflakeLedger.json`
- [ ] Review test execution logs for patterns

### Prometheus Queries
```promql
# Current flaky test count
ci_flaky_tests_count

# Flaky test trend over time
increase(ci_flaky_tests_count[24h])
increase(ci_flaky_tests_count[7d])

# Flaky test rate
rate(flake_detected_total[5m])
rate(flake_quarantined_total[5m])
```

### SigNoz Queries
```
# Find flaky test detections
trace_id != "" AND service.name = "flake-detector" AND attributes.event = "flake_detected"

# Check test execution patterns
trace_id != "" AND service.name = "test-runner" AND attributes.status = "flaky"
```

## 2) Common Causes & Quick Fixes

### Test Environment Issues
**Symptoms**: Intermittent failures across multiple tests
**Fix**: 
- Check test environment stability
- Verify resource availability
- Check for race conditions
- Review test isolation

### External Dependencies
**Symptoms**: Failures related to external services
**Fix**: 
- Check external service health
- Implement proper mocking
- Add retry logic
- Use circuit breakers

### Test Data Issues
**Symptoms**: Failures related to test data
**Fix**: 
- Check test data consistency
- Implement proper cleanup
- Use deterministic test data
- Add data validation

### Code Changes
**Symptoms**: New flaky tests after code changes
**Fix**: 
- Review recent code changes
- Check for timing issues
- Verify test coverage
- Add proper assertions

## 3) Decision Tree

### Critical (Increase > 10 in 24h)
- **Immediate action required**
  - Pause affected test lanes
  - Investigate root cause
  - Implement emergency fixes
  - Page on-call if > 15 minutes

### Warning (Increase > 3 in 24h)
- **Investigate and monitor**
  - Check specific test patterns
  - Review recent changes
  - Monitor for trends
  - Prepare for escalation

### Info (Increase > 0 in 24h)
- **Monitor and document**
  - Track individual tests
  - Check for patterns
  - Document for analysis
  - Plan remediation

## 4) De-Quarantine Process

### When to De-Quarantine
- Test has been green for N consecutive nights (default: 3)
- No flaky behavior observed
- Test is stable and reliable

### How to De-Quarantine
```bash
# Run de-quarantine script
node scripts/agent/flake-dequarantine.mjs

# Review changes
git diff

# Open PR with de-quarantine changes
git add .
git commit -m "De-quarantine stable tests"
git push origin dequarantine-branch
```

### Monitor De-Quarantine
- Track de-quarantined tests
- Monitor for re-flaking
- Update ledger
- Report on success rate

## 5) Flake Detection and Quarantine

### Automatic Detection
- **Nightly runs**: Detect flaky tests
- **Quarantine**: Tag with `@flaky`
- **Tracking**: Update ledger
- **Reporting**: Generate reports

### Manual Quarantine
```bash
# Tag test as flaky
# In test file: test('@flaky test name', () => { ... })

# Update ledger manually
echo '{"test_file::test_name": {"greenStreak": 0, "firstSeen": "'$(date -Iseconds)'"}}' > .agent/unflakeLedger.json
```

### Quarantine Management
- **Tracking**: Maintain ledger
- **Monitoring**: Track green streaks
- **Reporting**: Generate reports
- **Cleanup**: Remove old entries

## 6) Escalation

### Page On-Call When
- Flaky test count > 20 for >24h
- Multiple test lanes affected
- System stability compromised
- No clear resolution path

### Escalation Contacts
- **Primary**: On-call engineer
- **Secondary**: Team lead
- **Emergency**: CTO

### Information to Provide
- Flaky test count and trends
- Affected test lanes
- Recent changes
- Steps already taken
- Impact assessment

## 7) Post-Incident

### Immediate Actions
- [ ] Identify root cause
- [ ] Implement temporary fixes
- [ ] Monitor recovery
- [ ] Document incident

### Follow-up Actions
- [ ] Root cause analysis within 24 hours
- [ ] Implement permanent fixes within 1 week
- [ ] Update test stability processes
- [ ] Conduct post-mortem if severity > warning

### Documentation
- [ ] Update troubleshooting guide
- [ ] Add new alert rules if needed
- [ ] Update SLO targets if appropriate
- [ ] Share learnings with team

## 8) Prevention

### Proactive Monitoring
- [ ] Daily flake count checks
- [ ] Weekly stability review
- [ ] Monthly trend analysis
- [ ] Quarterly SLO review

### Best Practices
- [ ] Write stable, deterministic tests
- [ ] Implement proper test isolation
- [ ] Use appropriate timeouts
- [ ] Regular test maintenance

### Testing
- [ ] Test stability testing
- [ ] Chaos engineering for resilience
- [ ] Regular test review
- [ ] Automated flake detection

## 9) Metrics and Reporting

### Key Metrics
- **Flaky test count**: Total quarantined tests
- **Detection rate**: New flaky tests per day
- **De-quarantine rate**: Tests rehabilitated per day
- **Stability trend**: Week-over-week change

### Reporting
- **Daily**: Flake count and trends
- **Weekly**: Stability report
- **Monthly**: Trend analysis
- **Quarterly**: SLO review

### Dashboards
- **Flake count**: Current and historical
- **Detection rate**: New flaky tests
- **De-quarantine rate**: Rehabilitated tests
- **Stability trend**: Week-over-week change

---

**Last Updated**: 2025-09-27  
**Version**: 1.0.0  
**Maintainer**: Cursor Agent (Observability Copilot)
