# Queue Crash Recovery Runbook

**Purpose**: Recovery procedures for the queue steward system in case of crashes, corruption, or operational issues.

**Scope**: Covers SQLite database recovery, driver fallback, emergency pause procedures, and canonical/shadow mode transitions.

**Current Mode**: **CANONICAL WRITES** (default since PR-D completion)
- New jobs write directly to `.agent/` canonical paths
- Shadow mode available for rollback via `QUEUE_SHADOW=1`

---

## 🚨 Emergency Procedures

### Immediate Pause
```bash
# Halt all queue processing instantly
touch .agent/LOCK

# Verify pause is active
pnpm agent:status
# Should show: "Lock Present: YES"
```

### Resume After Investigation
```bash
# Remove lock to resume processing
rm .agent/LOCK

# Verify resume
pnpm agent:status
# Should show: "Lock Present: NO"
```

---

## 🔧 Database Recovery

### SQLite Integrity Check
```bash
# Check database integrity
cd C:\otel
pnpm exec tsx -e "
const Database = require('better-sqlite3');
const db = new Database('.agent/queue.db');
const result = db.prepare('PRAGMA integrity_check').get();
console.log('Integrity check result:', result);
db.close();
"

# Expected output: { integrity_check: 'ok' }
```

### SQLite Corruption Recovery
If integrity check fails:

1. **Backup corrupted database**:
   ```bash
   cp .agent/queue.db .agent/queue.db.corrupted.$(date +%Y%m%d_%H%M%S)
   ```

2. **Restore from backup**:
   ```bash
   # Check for recent backups
   ls -la .agent/queue.db.backup.*
   
   # Restore most recent backup
   cp .agent/queue.db.backup.$(ls -t .agent/queue.db.backup.* | head -1 | cut -d. -f4) .agent/queue.db
   ```

3. **Fallback to JSON driver**:
   ```bash
   # Set environment variable
   export QUEUE_DRIVER=json
   
   # Or create .env.local with:
   echo "QUEUE_DRIVER=json" >> .env.local
   
   # Restart runner
   pnpm agent:runner
   ```

---

## 🔄 Driver Fallback Procedures

### SQLite → JSON Fallback
```bash
# 1. Pause processing
touch .agent/LOCK

# 2. Set JSON driver
export QUEUE_DRIVER=json

# 3. Migrate existing jobs (if needed)
pnpm agent:migrate

# 4. Resume processing
rm .agent/LOCK
pnpm agent:runner
```

### JSON → SQLite Recovery
```bash
# 1. Pause processing
touch .agent/LOCK

# 2. Set SQLite driver
export QUEUE_DRIVER=sqlite

# 3. Migrate JSON jobs to SQLite
pnpm agent:migrate

# 4. Verify migration
pnpm agent:status

# 5. Resume processing
rm .agent/LOCK
pnpm agent:runner
```

---

## 📊 Health Monitoring

### Queue Status Check
```bash
# Comprehensive status
pnpm agent:status

# Expected output:
# - Lock Present: NO
# - Driver: sqlite (or json)
# - Shadow Mode: ON/OFF
# - Queue Depth: <number>
# - Running Jobs: <number>
```

### Database Statistics
```bash
# SQLite stats
pnpm exec tsx -e "
const Database = require('better-sqlite3');
const db = new Database('.agent/queue.db');
const stats = db.prepare('SELECT status, COUNT(*) as count FROM jobs GROUP BY status').all();
console.log('Job status counts:', stats);
const runs = db.prepare('SELECT COUNT(*) as total_runs FROM runs').get();
console.log('Total runs:', runs);
db.close();
"
```

### Shadow vs Canonical Verification
```bash
# Run verification script
pnpm agent:verify-shadow-canonical

# Or PowerShell version
pwsh -File scripts/verify-shadow-canonical.ps1
```

---

## 🔄 Canonical/Shadow Mode Management

### Current Configuration
```bash
# Check current mode
pnpm agent:status
# Look for: "Shadow Mode: OFF" (canonical) or "Shadow Mode: ON" (shadow)
```

### Rollback to Shadow Mode (Emergency)
```bash
# Set environment variable
export QUEUE_SHADOW=1
# Or add to .env.local: QUEUE_SHADOW=1

# Restart runner to pick up new config
taskkill /F /IM node.exe  # Kill any running processes
pnpm agent:runner         # Restart with shadow mode

# Verify rollback
pnpm agent:status
# Should show: "Shadow Mode: ON"
```

### Return to Canonical Mode (Normal Operation)
```bash
# Set environment variable
export QUEUE_SHADOW=0
# Or add to .env.local: QUEUE_SHADOW=0

# Restart runner
taskkill /F /IM node.exe  # Kill any running processes
pnpm agent:runner         # Restart with canonical mode

# Verify canonical mode
pnpm agent:status
# Should show: "Shadow Mode: OFF"
```

### Verify Mode Transition
```bash
# Run verification to check canonical vs shadow artifacts
pnpm agent:verify
# Expected: Shows drift between shadow and canonical (normal after transition)
```

---

## 🛠️ Troubleshooting Guide

### Common Issues

#### 1. "Database is locked" Error
**Cause**: Multiple processes accessing SQLite database
**Solution**:
```bash
# Check for running processes
ps aux | grep agent:runner

# Kill stuck processes
pkill -f "agent:runner"

# Restart runner
pnpm agent:runner
```

#### 2. "No space left on device" Error
**Cause**: Disk space exhaustion
**Solution**:
```bash
# Check disk space
df -h

# Clean up old artifacts
find .agent/shadow -name "*.json" -mtime +7 -delete
find .agent -name "*.tmp" -delete

# Check database size
ls -lh .agent/queue.db
```

#### 3. "Permission denied" Error
**Cause**: File permission issues
**Solution**:
```bash
# Fix permissions
chmod 755 .agent
chmod 644 .agent/queue.db
chmod 755 .agent/shadow

# On Windows, run as administrator if needed
```

#### 4. Shadow Artifacts Not Created
**Cause**: Shadow mode disabled or path issues
**Solution**:
```bash
# Check shadow mode
echo $QUEUE_SHADOW

# Enable shadow mode
export QUEUE_SHADOW=1

# Verify shadow directory exists
ls -la .agent/shadow/
```

---

## 📋 Recovery Checklist

### Before Recovery
- [ ] Pause queue processing (`touch .agent/LOCK`)
- [ ] Document error messages and symptoms
- [ ] Check system resources (disk space, memory)
- [ ] Identify last known good state

### During Recovery
- [ ] Backup current state
- [ ] Run integrity checks
- [ ] Apply appropriate recovery procedure
- [ ] Verify database consistency
- [ ] Test queue operations

### After Recovery
- [ ] Resume queue processing (`rm .agent/LOCK`)
- [ ] Monitor for 24 hours
- [ ] Update documentation if new procedure discovered
- [ ] Report incident if critical

---

## 🔍 Diagnostic Commands

### System Health
```bash
# Check queue steward status
pnpm agent:status

# Check SigNoz metrics
curl -s http://localhost:8080/api/v1/health

# Check Windows collector
sc query otelcol-contrib

# Check queue metrics log
tail -f C:\logs\queue\health.log
```

### Database Diagnostics
```bash
# SQLite database info
pnpm exec tsx -e "
const Database = require('better-sqlite3');
const db = new Database('.agent/queue.db');
console.log('Database page count:', db.prepare('PRAGMA page_count').get());
console.log('Database page size:', db.prepare('PRAGMA page_size').get());
console.log('Database version:', db.prepare('PRAGMA user_version').get());
db.close();
"
```

### Log Analysis
```bash
# Check runner logs
grep -i error .agent/shadow/*.json

# Check metrics export
grep -i error C:\logs\queue\health.log

# Check SigNoz ingestion
curl -s "http://localhost:8080/api/v1/logs?query=dataset%3D%22agent_queue%22" | jq
```

---

## 📞 Escalation

### When to Escalate
- Database corruption that cannot be recovered
- Data loss detected
- System-wide queue processing failure
- Security incident suspected

### Contact Information
- **Primary**: Queue Steward Team
- **Secondary**: Platform Engineering
- **Emergency**: On-call Engineer

### Information to Provide
- Error messages and stack traces
- System state before failure
- Recovery steps attempted
- Current queue status output
- Database integrity check results

---

## 📚 Related Documentation

- [Queue Configuration Guide](../queue-configuration.md)
- [Shadow vs Canonical Verification](../shadow-canonical-verification.md)
- [SigNoz Integration Guide](../signoz-integration.md)
- [ECRR Compliance Report](../ECRR_REPORTS/)

---

*Last Updated: 2025-01-30*
*Version: 1.0*