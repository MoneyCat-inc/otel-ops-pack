# Queue Crash Recovery Runbook

This runbook provides step-by-step procedures for recovering from queue system crashes and failures.

## Quick Recovery Commands

### Check Queue Health
```bash
# Check SQLite database integrity
npm run agent:status

# Verify shadow vs canonical artifacts
tsx scripts/agent/verify-shadow-canonical.ts ready

# Test SQLite functionality
npm run agent:test-sqlite
```

### Emergency Rollback
```bash
# Rollback to shadow mode
export QUEUE_SHADOW=1
npm run agent:status

# Rollback to JSON queue
export QUEUE_DRIVER=json
npm run agent:status
```

## Detailed Recovery Procedures

### 1. SQLite Database Corruption

**Symptoms:**
- Agent status shows errors
- Jobs not processing
- Database integrity check fails

**Recovery Steps:**

1. **Check Database Integrity**
   ```bash
   tsx -e "
   import { AgentDatabase } from './scripts/agent/db';
   const db = new AgentDatabase('.agent/queue.db', false);
   const integrity = db.integrityCheck();
   console.log('Integrity check:', integrity ? 'PASS' : 'FAIL');
   db.close();
   "
   ```

2. **If Integrity Check Fails:**
   ```bash
   # Backup corrupted database
   cp .agent/queue.db .agent/queue.db.corrupted.$(date +%Y%m%d_%H%M%S)
   
   # Remove corrupted database
   rm .agent/queue.db
   
   # Recreate from JSON queue
   npm run agent:migrate
   ```

3. **Verify Recovery:**
   ```bash
   npm run agent:status
   npm run agent:test-sqlite
   ```

### 2. WAL File Issues

**Symptoms:**
- Database locked errors
- WAL file growing large
- Performance degradation

**Recovery Steps:**

1. **Check WAL Size**
   ```bash
   tsx -e "
   import { AgentDatabase } from './scripts/agent/db';
   const db = new AgentDatabase('.agent/queue.db', true);
   const walSize = db.getWalSize();
   console.log('WAL size:', walSize, 'pages');
   db.close();
   "
   ```

2. **Force WAL Checkpoint**
   ```bash
   tsx -e "
   import { AgentDatabase } from './scripts/agent/db';
   const db = new AgentDatabase('.agent/queue.db', true);
   db.checkpoint();
   console.log('WAL checkpoint completed');
   db.close();
   "
   ```

3. **If WAL Issues Persist:**
   ```bash
   # Disable WAL mode temporarily
   export QUEUE_WAL=0
   npm run agent:status
   ```

### 3. Shadow vs Canonical Mismatch

**Symptoms:**
- Verification fails
- Inconsistent artifacts
- Flip operation fails

**Recovery Steps:**

1. **Run Full Verification**
   ```bash
   tsx scripts/agent/verify-shadow-canonical.ts report
   ```

2. **If Differences Found:**
   ```bash
   # Force shadow mode
   export QUEUE_SHADOW=1
   
   # Run jobs to regenerate shadow artifacts
   npm run agent:runner
   
   # Verify again
   tsx scripts/agent/verify-shadow-canonical.ts verify
   ```

3. **Manual Artifact Sync:**
   ```bash
   # Copy canonical to shadow
   cp .agent/status.json .agent/shadow/status.json
   cp .agent/agent_queue.json .agent/shadow/agent_queue.json
   cp .agent/runs.json .agent/shadow/runs.json
   ```

### 4. Service Worker Offline Issues

**Symptoms:**
- Offline isolation tests fail
- CrossOriginIsolated=false when offline
- AudioWorklet loading fails offline

**Recovery Steps:**

1. **Check Service Worker Registration**
   ```bash
   # Test offline isolation
   npm run test:isolation-offline
   ```

2. **Clear Service Worker Cache**
   ```bash
   # In browser dev tools:
   # Application > Storage > Clear storage > Clear site data
   ```

3. **Re-register Service Worker**
   ```bash
   # Restart development server
   npm run dev
   ```

### 5. Complete System Reset

**When to Use:**
- Multiple components failing
- Unrecoverable corruption
- Need clean slate

**Recovery Steps:**

1. **Stop All Services**
   ```bash
   # Stop any running agents
   pkill -f "agent:runner"
   pkill -f "watchdog"
   ```

2. **Clean All Artifacts**
   ```bash
   # Remove all queue artifacts
   rm -rf .agent/queue.db*
   rm -rf .agent/shadow/
   rm -f .agent/status.json
   rm -f .agent/runs.json
   
   # Keep agent_queue.json as backup
   cp .agent/agent_queue.json .agent/agent_queue.json.backup
   ```

3. **Reset Environment**
   ```bash
   export QUEUE_DRIVER=json
   export QUEUE_WAL=0
   export QUEUE_SHADOW=1
   ```

4. **Reinitialize System**
   ```bash
   # Start with JSON queue
   npm run agent:status
   
   # Migrate to SQLite when ready
   export QUEUE_DRIVER=sqlite
   npm run agent:migrate
   
   # Test functionality
   npm run agent:test-sqlite
   ```

## Prevention Measures

### Regular Maintenance

1. **Daily Health Checks**
   ```bash
   # Add to cron or scheduled task
   npm run agent:status > .agent/health-$(date +%Y%m%d).log
   ```

2. **Weekly Integrity Checks**
   ```bash
   # Add to weekly maintenance
   tsx scripts/agent/verify-shadow-canonical.ts stability 5 10000
   ```

3. **Monthly Cleanup**
   ```bash
   # Clean old artifacts
   find .agent -name "*.backup.*" -mtime +30 -delete
   ```

### Monitoring Alerts

1. **Queue Depth Monitoring**
   - Alert if queue depth > 100
   - Alert if no jobs processed in 1 hour

2. **Database Health Monitoring**
   - Alert if integrity check fails
   - Alert if WAL size > 1000 pages

3. **Shadow/Canonical Monitoring**
   - Alert if verification fails
   - Alert if artifacts differ

## Emergency Contacts

- **Primary:** DevOps Team
- **Secondary:** Backend Team
- **Escalation:** Engineering Manager

## Recovery Time Objectives

- **Critical Issues:** < 15 minutes
- **Major Issues:** < 1 hour
- **Minor Issues:** < 4 hours
- **Complete Reset:** < 2 hours

## Post-Recovery Checklist

- [ ] Queue processing resumes
- [ ] All tests pass
- [ ] Monitoring alerts clear
- [ ] Documentation updated
- [ ] Root cause analysis completed
- [ ] Prevention measures implemented



