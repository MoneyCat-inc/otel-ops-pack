# MEMX Runbook

## Overview

This runbook covers incident response procedures for MEMX (Memory Observation Layer) issues. MEMX monitors browser memory usage, audio processing latency, and performance metrics.

## Quick Reference

### Key Metrics
- **WASM Heap**: WebAssembly memory usage
- **SAB Usage**: SharedArrayBuffer utilization (audio ring buffer)
- **Worklet Lag**: AudioWorklet processing latency
- **Memory Strain**: Overall memory pressure percentage
- **Frame Drops**: Rendering performance issues

### Critical Thresholds
- **WASM Heap**: >20MB (critical), >10MB (warning)
- **SAB Usage**: >95% (critical), >80% (warning)
- **Worklet Lag**: >100ms (critical), >50ms (warning)
- **Memory Strain**: >80% (critical), >50% (warning)
- **Frame Drops**: >5% (critical), >3% (warning)

## Incident Response Procedures

### 1. Worklet Lag High

**Symptoms:**
- AudioWorklet lag >50ms (warning) or >100ms (critical)
- Audio processing delays
- User reports of audio latency

**Investigation Steps:**
1. **Check PerfOverlay**: Open browser dev tools → Performance tab
2. **Verify Cross-Origin Isolation**: Check `window.crossOriginIsolated` in console
3. **Check Memory Usage**: Review WASM heap and SAB usage
4. **Correlate with Frame Drops**: Check if frame drops are also high

**Immediate Actions:**
1. **Toggle Reduced Load**: Disable non-essential features
2. **Check Recent Changes**: Review recent deployments
3. **Monitor Trends**: Check if lag is increasing over time

**Resolution Steps:**
1. **If isolation is false**: Check COOP/COEP headers
2. **If memory is high**: Investigate memory leaks
3. **If frame drops are high**: Check rendering performance
4. **File bug if lag persists**: Attach p95/p99 metrics + heap trend

**Prevention:**
- Monitor worklet lag trends
- Set up alerts for gradual increases
- Regular performance testing

### 2. Cross-Origin Isolation Disabled

**Symptoms:**
- `window.crossOriginIsolated` returns `false`
- SAB and WASM threads not functioning
- Degraded MEMX metrics

**Investigation Steps:**
1. **Check Headers**: Verify COOP/COEP headers in network tab
2. **Check Service Worker**: Ensure SW isn't stripping headers
3. **Check Edge Nodes**: Verify headers on CDN/edge
4. **Check Browser**: Test in different browsers

**Immediate Actions:**
1. **Check Header Configuration**: Review `next.config.js`
2. **Verify Deployment**: Check if headers are applied
3. **Test Locally**: Verify headers work in development

**Resolution Steps:**
1. **Fix Header Configuration**: Update `next.config.js` if needed
2. **Redeploy**: Deploy with known-good header map
3. **Verify**: Check headers in production
4. **Monitor**: Ensure isolation stays enabled

**Prevention:**
- Include header checks in CI/CD
- Regular header validation
- Monitor isolation status

### 3. SAB Backlog

**Symptoms:**
- SAB usage >80% (warning) or >95% (critical)
- Audio ring buffer filling up
- Audio dropouts or glitches

**Investigation Steps:**
1. **Correlate with Heap**: Check if WASM heap is also high
2. **Check Frame Drops**: See if rendering is affected
3. **Review Audio Processing**: Check worklet performance
4. **Check Recent Changes**: Look for WASM or audio changes

**Immediate Actions:**
1. **Monitor Trends**: Check if backlog is increasing
2. **Check Audio Quality**: Listen for dropouts
3. **Reduce Load**: Disable non-essential audio features

**Resolution Steps:**
1. **If heap is high**: Investigate memory leaks
2. **If frame drops are high**: Check rendering performance
3. **Roll back WASM changes**: If recent changes caused issues
4. **Widen buffer**: Only as last resort

**Prevention:**
- Monitor SAB usage trends
- Regular audio quality testing
- Careful WASM change management

### 4. OTel Disconnect

**Symptoms:**
- No MEMX metrics in SigNoz
- OTel collector not receiving data
- Infrastructure alerts firing

**Investigation Steps:**
1. **Check OTel Collector**: Verify collector is running
2. **Check SigNoz**: Ensure SigNoz is accessible
3. **Check Network**: Verify connectivity
4. **Check MEMX**: Ensure MEMX is enabled

**Immediate Actions:**
1. **Restart OTel Collector**: If collector is down
2. **Check Configuration**: Verify OTLP endpoints
3. **Test Connectivity**: Ping endpoints

**Resolution Steps:**
1. **Fix Collector**: Restart or reconfigure
2. **Update Endpoints**: If configuration is wrong
3. **Verify MEMX**: Ensure feature is enabled
4. **Test Integration**: Run verification script

**Prevention:**
- Monitor OTel collector health
- Regular integration testing
- Backup monitoring systems

### 5. Memory Strain High

**Symptoms:**
- Memory strain >50% (warning) or >80% (critical)
- Overall system performance degradation
- Multiple memory-related alerts

**Investigation Steps:**
1. **Check Individual Metrics**: Review WASM heap, SAB usage
2. **Check Trends**: See if strain is increasing
3. **Check User Impact**: Monitor user experience
4. **Check System Resources**: Review overall system health

**Immediate Actions:**
1. **Reduce Load**: Disable non-essential features
2. **Monitor Closely**: Watch for further increases
3. **Check User Impact**: Ensure users aren't affected

**Resolution Steps:**
1. **Identify Root Cause**: Find which metric is driving strain
2. **Address Specific Issue**: Use appropriate runbook section
3. **Optimize Memory**: If needed, optimize memory usage
4. **Monitor Recovery**: Ensure strain decreases

**Prevention:**
- Regular memory optimization
- Monitor memory trends
- Set up gradual increase alerts

## Escalation Procedures

### Level 1: Warning Alerts
- **Response Time**: 15 minutes
- **Actions**: Investigate, monitor, document
- **Escalation**: If not resolved in 30 minutes

### Level 2: Critical Alerts
- **Response Time**: 5 minutes
- **Actions**: Immediate investigation, potential rollback
- **Escalation**: If not resolved in 15 minutes

### Level 3: System Down
- **Response Time**: 2 minutes
- **Actions**: Emergency response, rollback if needed
- **Escalation**: Immediate notification to on-call

## Monitoring and Alerting

### Key Dashboards
- **MEMX Overview**: High-level health indicators
- **Memory Metrics**: WASM heap, SAB usage, strain
- **Performance Metrics**: Worklet lag, frame drops
- **Infrastructure**: OTel health, SigNoz status

### Alert Channels
- **Slack**: #memx-alerts channel
- **Email**: memx-team@resonai.com
- **PagerDuty**: Critical alerts only

### Alert Groups
- **Memory**: High strain, WASM growth, SAB backlog
- **Performance**: Worklet lag, frame drops
- **Infrastructure**: OTel disconnect, session stall

## Troubleshooting Commands

### Check MEMX Status
```powershell
# Verify MEMX integration
.\scripts\verify-memx-integration.ps1

# Check OTel health
Invoke-WebRequest -Uri "http://localhost:13134/healthz"

# Check SigNoz health
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health"
```

### Generate Test Data
```powershell
# Basic canary test
.\scripts\memx-canary-test.ps1

# Stress test
.\scripts\memx-stress-test.ps1 -StressMemory -DurationSeconds 120

# Test specific scenarios
.\scripts\memx-stress-test.ps1 -JitterFrames -PauseStreaming
```

### Check Browser Console
```javascript
// Check cross-origin isolation
console.log('Cross-origin isolated:', window.crossOriginIsolated);

// Check SharedArrayBuffer
console.log('SAB available:', typeof SharedArrayBuffer !== 'undefined');

// Check MEMX metrics
console.log('MEMX store:', window.memxStore);
```

## Prevention and Maintenance

### Regular Tasks
- **Weekly**: Review alert effectiveness
- **Monthly**: Update thresholds based on trends
- **Quarterly**: Review and update runbook

### Testing
- **Daily**: Canary tests
- **Weekly**: Stress tests
- **Monthly**: Full integration tests

### Documentation
- **Incident Reports**: Document all incidents
- **Lessons Learned**: Update procedures based on incidents
- **Training**: Ensure team knows procedures

## Contact Information

### Team Contacts
- **Primary On-Call**: memx-oncall@resonai.com
- **Secondary On-Call**: memx-backup@resonai.com
- **Team Lead**: memx-lead@resonai.com

### Escalation Contacts
- **Engineering Manager**: eng-manager@resonai.com
- **SRE Team**: sre-team@resonai.com
- **Product Team**: product-team@resonai.com

## Appendix

### Common Issues and Solutions

#### Issue: MEMX not showing data
**Solution**: Check if feature flag is enabled, verify OTel integration

#### Issue: Alerts not firing
**Solution**: Check alert rules, verify notification channels

#### Issue: Dashboard not loading
**Solution**: Check SigNoz health, verify dashboard configuration

#### Issue: High false positive rate
**Solution**: Adjust thresholds, review alert logic

### Useful Links
- **SigNoz Dashboard**: http://localhost:8080/dashboards
- **OTel Collector**: http://localhost:13134
- **MEMX Labs**: http://localhost:3000/labs/memx
- **Documentation**: docs/SIGNOZ_MEMX_SETUP.md
