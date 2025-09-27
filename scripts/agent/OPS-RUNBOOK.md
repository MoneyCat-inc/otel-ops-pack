# codex-local Premium Features - Operations Runbook

## 🎛️ Output Modes

### Quiet Mode (`-Quiet`)
Minimal output for CI/CD pipelines and automation.

```powershell
# Status check - single line output
pnpm agent:status-premium -Quiet
# Output: ACTIVE - 0 violations

# Guardrails check - single line output  
pnpm agent:guardrails-premium -Quiet
# Output: PASS - 0 violations found
```

### JSON Mode (`-Json`)
Structured output for parsing and automation.

```powershell
# Status as JSON
pnpm agent:status-premium -Json
# Output: {"timestamp":"2025-09-27T18:00:00.000Z","status":"active",...}

# Guardrails as JSON
pnpm agent:guardrails-premium -Json
# Output: {"violations":0,"filesProcessed":15,"exitCode":0,...}
```

### Verbose Mode (`-Verbose`)
Detailed progress information for debugging.

```powershell
# Demo with detailed output
pnpm agent:demo-premium -Verbose
```

### Detailed Mode (`-Detailed`)
Extended status information for troubleshooting.

```powershell
# Status with all details
pnpm agent:status-premium -Detailed
```

## 🛡️ Budget Controls

### Default Budgets
- **Files**: 10 files per cycle
- **Lines**: 200 LOC per cycle

### Override Budgets
```powershell
# Reduce budgets for safety
pnpm agent:guardrails-premium -Fix -MaxFiles 5 -MaxLines 100

# Increase budgets for large codebases
pnpm agent:guardrails-premium -Fix -MaxFiles 50 -MaxLines 1000
```

### Budget Warnings
- **75% threshold**: Yellow warning
- **90% threshold**: Orange warning  
- **100% threshold**: Red error, stops processing

## 🔒 Lock Mechanism

### When to Use `.agent/LOCK`
- **Emergency stop**: Immediate halt of all agent operations
- **Maintenance**: Pause during system updates
- **Debugging**: Stop operations to investigate issues
- **Resource constraints**: Pause when system is overloaded

### Setting Lock
```powershell
# Create lock file
"Emergency maintenance" | Set-Content .agent/LOCK

# Check status (will show LOCKED)
pnpm agent:status-premium -Quiet
# Output: LOCKED - 0 violations
```

### Removing Lock
```powershell
# Remove lock file
Remove-Item .agent/LOCK

# Status will return to ACTIVE
pnpm agent:status-premium -Quiet
# Output: ACTIVE - 0 violations
```

### Expected Behavior
- **Watchdog**: Stops processing cycles
- **Status**: Shows `LOCKED` state
- **New operations**: Blocked until lock removed
- **Existing operations**: Complete normally

## 🔧 Troubleshooting

### No ANSI Support
**Problem**: Progress bars show as raw escape sequences
**Solution**: 
```powershell
# Set environment variable
$env:NO_COLOR = "1"
pnpm agent:status-premium -Detailed

# Or use quiet mode
pnpm agent:status-premium -Quiet
```

### Jittery ETAs
**Problem**: ETA estimates bounce around
**Solution**: 
- Run multiple cycles to build EMA history
- Check `.agent/status.json` for EMA data
- EMA stabilizes after 10-15 cycles

### CI Headless Mode
**Problem**: Fancy features don't work in CI
**Solution**:
```yaml
# GitHub Actions
- name: Run Agent Check
  run: |
    $env:CI = "true"
    pnpm agent:guardrails-premium -Json
```

### Performance Issues
**Problem**: Slow progress or high CPU usage
**Solution**:
```powershell
# Check EMA metrics
pnpm agent:status-premium -Detailed

# Look for high values in:
# - setupSecs (should be <30s)
# - doctorSecs (should be <60s)  
# - guardrailsSecs (should be <30s)
```

### File Permission Errors
**Problem**: Cannot write to `.agent/` directory
**Solution**:
```powershell
# Check permissions
Get-Acl .agent

# Fix permissions (Windows)
icacls .agent /grant Everyone:F

# Or run as administrator
Start-Process powershell -Verb RunAs
```

## 📊 Monitoring & Alerts

### Key Metrics to Monitor

#### 1. `codex.jobs_processed` (Counter)
- **Rate > 0**: Queue is being processed
- **Rate = 0 + Queue > 0**: Processing stalled
- **Alert**: No jobs processed for 5+ minutes with non-empty queue

#### 2. `codex.guardrail_violations` (Counter)
- **Delta spikes**: New violations detected
- **Alert**: >10 violations in 1 hour
- **Action**: Create ticket for code review

#### 3. `watchdog.cycle.duration` (Histogram)
- **P95 < 300s**: Healthy cycle times
- **P95 > 300s**: Cycles taking too long
- **Alert**: P95 > 300s for 10+ minutes
- **Action**: Investigate performance bottlenecks

#### 4. `codex.agent.status`
- **Value = 1**: Agent active
- **Value = 0**: Agent locked/stopped
- **Alert**: Status != 1
- **Action**: Check for lock files or errors

### Dashboard Queries

```promql
# Jobs processed rate
rate(codex_jobs_processed_total[5m])

# Violations delta
delta(codex_guardrail_violations_total[1h])

# Cycle duration P95
histogram_quantile(0.95, rate(watchdog_cycle_duration_seconds_bucket[5m]))

# Agent status
codex_agent_status
```

## 🚀 Quick Commands

### Daily Health Check
```powershell
# Quick status
pnpm agent:status-premium -Quiet

# Detailed health
pnpm agent:status-premium -Detailed

# Check for violations
pnpm agent:guardrails-premium -Quiet
```

### Emergency Procedures
```powershell
# Stop all operations
"Emergency stop" | Set-Content .agent/LOCK

# Check what's running
pnpm agent:status-premium -Detailed

# Resume operations
Remove-Item .agent/LOCK
```

### CI/CD Integration
```powershell
# Validate in CI
pnpm agent:guardrails-premium -Json | ConvertFrom-Json | ForEach-Object {
    if ($_.violations -gt 0) { exit 1 }
}

# Check status in CI
pnpm agent:status-premium -Json | ConvertFrom-Json | ForEach-Object {
    if ($_.status -ne "active") { exit 1 }
}
```

## 📝 Log Files

### Key Files to Monitor
- `.agent/status.json` - Current agent status and EMA data
- `.agent/guardrails_report.json` - Latest violation report
- `TASKS.md` - Human-readable activity log
- `DECISIONS.md` - Agent decision log

### Log Rotation
- **Status files**: Kept for 30 days
- **Reports**: Kept for 7 days
- **Task logs**: Rotated at 10MB

## 🔄 Maintenance

### Weekly Tasks
- Review violation reports
- Check EMA metrics for performance trends
- Verify lock files are not stale
- Update budgets if needed

### Monthly Tasks
- Review and clean old log files
- Update golden output samples
- Review and update runbook
- Performance optimization review
