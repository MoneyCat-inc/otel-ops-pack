# Queue Steward Operator Package

**Complete enterprise-grade operational tooling for the Queue Steward background worker system.**

---

## 🚀 **Quick Start**

### **For On-Call Engineers**
1. **Emergency**: Open `docs/QUEUE_STEWARD_DAY2_OPS_CHEAT_SHEET.md`
2. **Health Check**: Run `pnpm agent:status`
3. **Diagnostics**: Run `pwsh -File scripts/collect-queue-diagnostics.ps1`

### **For Operations Teams**
1. **Setup**: Follow `docs/QUEUE_STEWARD_GO_LIVE_CHECKLIST.md`
2. **Schedule**: Run `pwsh -File scripts/setup-nightly-task.ps1` (Windows) or `bash scripts/setup-nightly-cron.sh` (Linux/macOS)
3. **Monitor**: Use `docs/QUEUE_STEWARD_OPERATOR_QUICK_REFERENCE.md` for detailed procedures

---

## 📚 **Documentation Hierarchy**

### **🚀 Day-2 Ops Cheat Sheet** (Single Page)
**File**: `docs/QUEUE_STEWARD_DAY2_OPS_CHEAT_SHEET.md`  
**Audience**: On-call engineers  
**Purpose**: Emergency response and quick health checks  
**Format**: ASCII-only, copy-pasteable commands

### **📋 Operator Quick Reference** (Comprehensive)
**File**: `docs/QUEUE_STEWARD_OPERATOR_QUICK_REFERENCE.md`  
**Audience**: Operations teams, escalation handlers  
**Purpose**: Detailed procedures, troubleshooting, automation  
**Format**: ASCII-only, comprehensive coverage

### **✅ Go-Live Checklist** (Deployment)
**File**: `docs/QUEUE_STEWARD_GO_LIVE_CHECKLIST.md`  
**Audience**: DevOps engineers, deployment teams  
**Purpose**: Production deployment validation  
**Format**: Step-by-step checklist with evidence collection

### **🚨 Crash Recovery Runbook** (Emergency)
**File**: `docs/runbooks/queue-crash-recovery.md`  
**Audience**: Senior engineers, incident commanders  
**Purpose**: Emergency recovery procedures  
**Format**: Detailed troubleshooting and rollback procedures

### **📊 SigNoz Alert Guide** (Observability)
**File**: `docs/SIGNOZ_ECRR_COMPLIANCE_ALERT_GUIDE.md`  
**Audience**: Observability teams, compliance officers  
**Purpose**: Dashboard setup and alert configuration  
**Format**: SQL queries and alert rules

---

## 🛠️ **Automation Scripts**

### **Diagnostics & Monitoring**
- `scripts/collect-queue-diagnostics.ps1` - On-demand artifact collection
- `scripts/nightly-queue-diagnostics.ps1` - Automated nightly with canary + cleanup
- `scripts/canary-test.ps1` - End-to-end pipeline validation

### **Scheduling Setup**
- `scripts/setup-nightly-task.ps1` - Windows Task Scheduler automation
- `scripts/setup-nightly-cron.sh` - Linux/macOS cron automation

### **Verification & Testing**
- `scripts/agent/nightly-verify.ps1` - Shadow/canonical drift verification
- `scripts/verify-shadow-canonical.ps1` - PowerShell verification script

---

## 📦 **NPM Integration**

### **Available Commands**
```bash
# Status & Health
pnpm agent:status                    # Queue status snapshot
pnpm agent:verify                    # Shadow/canonical verification
pnpm agent:runner                    # Start background runner

# Diagnostics & Testing
pnpm agent:nightly-diagnostics       # Run nightly diagnostics
pnpm agent:nightly-verify            # Run nightly verification

# Development & Testing
pnpm agent:test                      # Run unit tests
pnpm agent:test-runner               # Test runner functionality
pnpm agent:migrate                   # Migrate JSON to SQLite
```

---

## 🎯 **Key Features**

### **Emergency Response**
- ✅ **Instant Pause**: `.agent/LOCK` mechanism stops all processing
- ✅ **Health Verification**: Multi-layer health checks with clear baselines
- ✅ **Escalation Package**: Automated artifact collection for incident response

### **Observability**
- ✅ **SigNoz Integration**: Real-time dashboards and alerting
- ✅ **Health Logs**: Structured telemetry with configurable export
- ✅ **Canary Testing**: End-to-end pipeline validation

### **Automation**
- ✅ **Nightly Diagnostics**: Automated health checks with cleanup
- ✅ **Cross-Platform Scheduling**: Windows Task Scheduler + Linux/macOS cron
- ✅ **Event Log Integration**: Windows Event Log for monitoring integration

### **Governance**
- ✅ **ECRR Compliance**: Examine → Clean → Report → Role methodology
- ✅ **Audit Trail**: Comprehensive artifact collection and retention
- ✅ **Exit Codes**: Standardized status reporting for automation

---

## 🔧 **System Requirements**

### **Platform Support**
- ✅ **Windows**: PowerShell 5.1+ or PowerShell Core 7+
- ✅ **Linux**: PowerShell Core 7+ (Ubuntu 18.04+, CentOS 7+)
- ✅ **macOS**: PowerShell Core 7+ (macOS 10.14+)

### **Dependencies**
- ✅ **PowerShell Core**: Cross-platform PowerShell runtime
- ✅ **Node.js**: 18+ for TypeScript execution
- ✅ **SigNoz**: Local observability stack (Docker Compose)
- ✅ **Windows Collector**: OpenTelemetry Collector service (Windows only)

### **Permissions**
- ✅ **Windows**: Administrator privileges for Task Scheduler setup
- ✅ **Linux/macOS**: Standard user permissions for cron setup
- ✅ **File System**: Read/write access to `artifacts/` directory

---

## 🚀 **Production Readiness**

### **Deployment Checklist**
- [ ] Run `docs/QUEUE_STEWARD_GO_LIVE_CHECKLIST.md` validation
- [ ] Configure nightly scheduling (`scripts/setup-nightly-task.ps1` or `scripts/setup-nightly-cron.sh`)
- [ ] Import SigNoz alerts from `docs/SIGNOZ_ECRR_COMPLIANCE_ALERT_GUIDE.md`
- [ ] Train on-call team with `docs/QUEUE_STEWARD_DAY2_OPS_CHEAT_SHEET.md`

### **Monitoring Setup**
- [ ] Queue depth alerts (< 100 warning, < 200 critical)
- [ ] Error rate alerts (< 5% warning, < 10% critical)
- [ ] Processing gap alerts (> 10min warning, > 15min critical)
- [ ] Nightly diagnostics success/failure notifications

### **Operational Procedures**
- [ ] Daily: Review nightly diagnostics summary
- [ ] Weekly: Audit alert history and adjust thresholds
- [ ] Monthly: Review dashboard performance and compliance queries

---

## 📞 **Support & Escalation**

### **Level 1**: On-Call Engineer
- Use Day-2 Ops Cheat Sheet for immediate response
- Collect diagnostics package for escalation

### **Level 2**: Operations Team
- Use Operator Quick Reference for detailed troubleshooting
- Follow crash recovery runbook for complex issues

### **Level 3**: Engineering Team
- Review escalation package artifacts
- Access full system logs and configuration

---

**Last Updated**: 2025-09-30  
**Maintainer**: Observability Copilot  
**Status**: Production Ready ✅

---

> 💡 **Pro Tip**: Start with the Day-2 Ops Cheat Sheet for immediate needs, then dive into the comprehensive Quick Reference for detailed procedures.
