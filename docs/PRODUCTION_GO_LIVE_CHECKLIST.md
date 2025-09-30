# Queue Steward Production Go-Live Checklist

**Purpose**: Final validation gate before production deployment of the Queue Steward pipeline.

**Scope**: Comprehensive health checks, configuration validation, and operational readiness verification.

**Status**: ✅ **READY FOR PRODUCTION** (All PRs A-D complete)

---

## 🚨 **Pre-Deployment Health Gates**

### **Environment Validation**
- [ ] **Environment Variables Set**:
  ```bash
  QUEUE_DRIVER=sqlite
  QUEUE_SHADOW=0
  QUEUE_WAL=1
  QUEUE_ENABLED=1
  QUEUE_MAX_JOBS=10
  QUEUE_MAX_CONCURRENCY=2
  QUEUE_ADMISSION_CAP=200
  QUEUE_METRICS=1
  ```
- [ ] **Database Paths Verified**:
  ```bash
  .agent/queue.db (SQLite with WAL)
  .agent/status.json (canonical status)
  C:\logs\queue\health.log (metrics export)
  ```

### **Service Dependencies**
- [ ] **Windows Collector Service**: `sc query otelcol-contrib` → `RUNNING`
- [ ] **SigNoz Stack**: `docker ps` → All containers healthy
- [ ] **ClickHouse**: `http://localhost:8080/api/v1/health` → `{"status":"ok"}`
- [ ] **OTLP Endpoints**: Ports 14317/14318 accessible

---

## 🔍 **System Health Verification**

### **Queue Steward Status**
```bash
# Run comprehensive status check
pnpm agent:status

# Expected output:
# ✅ Lock Present: NO
# ✅ Driver: sqlite
# ✅ Shadow Mode: OFF
# ✅ Queue Depth: <reasonable number>
# ✅ Running Jobs: <reasonable number>
# ✅ Admission Cap: 200
```

### **Database Integrity**
```bash
# SQLite integrity check
sqlite3 .agent/queue.db "PRAGMA integrity_check;"
# Expected: "ok"

# Check job distribution
sqlite3 .agent/queue.db "SELECT status, COUNT(*) FROM jobs GROUP BY status;"
# Expected: Mix of pending/completed/failed jobs
```

### **Canonical vs Shadow Verification**
```bash
# Run drift detection
pnpm agent:verify

# Expected: Shows drift between shadow (352) and canonical (14) artifacts
# This is NORMAL after canonical flip
```

---

## 📊 **Observability Validation**

### **SigNoz Ingestion**
```bash
# Check latest queue metrics in ClickHouse
# Query: SELECT * FROM signoz_logs.logs_v2 WHERE body LIKE '%queue_depth%' ORDER BY timestamp DESC LIMIT 5

# Expected: Recent metrics with queue_depth, running, p95_job_ms
```

### **Health Log Export**
```bash
# Check metrics log file
Get-Content -Path "C:\logs\queue\health.log" -Tail 10

# Expected: Recent JSON metrics entries
```

### **Service Worker Status**
```bash
# Verify offline isolation capability
# Navigate to http://localhost:3001
# Check browser console: Service Worker Status should show:
# - isSupported: true
# - isRegistered: true  
# - isActive: true
# - crossOriginIsolated: true
# - sharedArrayBufferAvailable: true
```

---

## 🧪 **Functional Testing**

### **Job Processing**
```bash
# Add test job and verify processing
pnpm agent:test-runner

# Expected: Jobs process successfully, metrics exported
```

### **Offline Isolation**
```bash
# Run Playwright tests
pnpm --filter resonai-mock playwright test tests/e2e/isolation-offline.e2e.spec.ts

# Expected: All tests pass, cross-origin isolation maintained
```

### **Admission Control**
```bash
# Verify queue capacity limits
# Check logs for: "Queue at capacity (X/200) - refusing new jobs"
```

---

## 🛡️ **Safety & Rollback Validation**

### **Emergency Procedures**
- [ ] **Lock Mechanism**: `touch .agent/LOCK` → Processing stops
- [ ] **Shadow Rollback**: `QUEUE_SHADOW=1` → Writes to shadow paths
- [ ] **Driver Fallback**: `QUEUE_DRIVER=json` → Falls back to JSON

### **Documentation**
- [ ] **Runbooks Updated**: `docs/runbooks/queue-crash-recovery.md`
- [ ] **Tasks Logged**: `TASKS.md` reflects all PR completions
- [ ] **Nightly Scripts**: `pnpm agent:nightly-verify` operational

---

## 🚀 **Deployment Readiness**

### **Configuration Files**
- [ ] **Queue Config**: `lib/config/queue.ts` properly configured
- [ ] **Environment**: `.env.local` has correct settings
- [ ] **Next.js Config**: `next.config.js` headers intact

### **Monitoring Setup**
- [ ] **SigNoz Dashboard**: Queue metrics visible
- [ ] **Alert Rules**: Configured for queue depth, failures
- [ ] **Log Aggregation**: ClickHouse ingestion working

### **Operational Procedures**
- [ ] **On-Call Runbooks**: Team familiar with emergency procedures
- [ ] **Monitoring Alerts**: Configured for production thresholds
- [ ] **Backup Procedures**: Database backup strategy in place

---

## ✅ **Final Go/No-Go Decision**

### **Green Light Criteria**
- [ ] All health gates pass
- [ ] Observability fully operational
- [ ] Functional tests green
- [ ] Safety procedures validated
- [ ] Team trained on operations

### **Red Light Blockers**
- [ ] Any health gate failures
- [ ] Missing observability
- [ ] Failed functional tests
- [ ] Safety procedures not validated
- [ ] Team not ready

---

## 🎯 **Post-Deployment Monitoring**

### **First 24 Hours**
- [ ] **Queue Depth**: Monitor for unusual spikes
- [ ] **Job Processing**: Verify successful completion rates
- [ ] **Metrics Export**: Confirm SigNoz ingestion
- [ ] **Error Rates**: Watch for unexpected failures

### **First Week**
- [ ] **Performance**: P95 latency within acceptable bounds
- [ ] **Stability**: No unexpected crashes or restarts
- [ ] **Resource Usage**: Memory/CPU within expected ranges
- [ ] **User Impact**: No degradation in application performance

---

## 📞 **Emergency Contacts**

**Primary**: Queue Steward Team Lead
**Secondary**: Platform Engineering
**Escalation**: CTO Office

**Emergency Procedures**: See `docs/runbooks/queue-crash-recovery.md`

---

## 🏆 **Success Metrics**

- **Uptime**: 99.9% availability
- **Latency**: P95 job processing < 5 seconds
- **Throughput**: Handle expected job volume
- **Observability**: All metrics visible in SigNoz
- **Recovery**: < 5 minute MTTR for common issues

---

**✅ READY FOR PRODUCTION DEPLOYMENT**

*This checklist ensures the Queue Steward system is production-ready with comprehensive monitoring, safety procedures, and operational excellence.*
