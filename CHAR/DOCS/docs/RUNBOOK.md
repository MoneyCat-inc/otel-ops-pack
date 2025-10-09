# codex-local Operational Runbook

## 🎯 **Overview**

This runbook provides operational procedures for managing the codex-local autonomous observability subsystem in production environments.

## 🚀 **Service Mode Operations**

### **Installation**
```powershell
# Install as Windows Service (requires Administrator)
pwsh -File scripts/agent/service-install.ps1

# Install with custom service name
pwsh -File scripts/agent/service-install.ps1 -ServiceName "my-codex-local"

# Force reinstall
pwsh -File scripts/agent/service-install.ps1 -Force
```

### **Service Management**
```powershell
# Check service status
sc query codex-local

# Start service
sc start codex-local

# Stop service
sc stop codex-local

# Restart service
sc stop codex-local && sc start codex-local

# View service logs
Get-Content ".agent/logs/service.out.log"
Get-Content ".agent/logs/service.err.log"
```

### **Uninstallation**
```powershell
# Uninstall service (requires Administrator)
pwsh -File scripts/agent/service-uninstall.ps1

# Keep log files during uninstall
pwsh -File scripts/agent/service-uninstall.ps1 -KeepLogs

# Force uninstall
pwsh -File scripts/agent/service-uninstall.ps1 -Force
```

## 🔧 **Agent Operations**

### **Basic Commands**
```powershell
# Health check
pnpm agent:doctor

# Status check
pnpm agent:status-premium

# Guardrail enforcement
pnpm agent:guardrails-premium

# Start watchdog
pnpm agent:start
```

### **Advanced Operations**
```powershell
# JSON output for CI
pnpm agent:status-premium -Json
pnpm agent:guardrails-premium -Json

# Quiet mode for scripting
pnpm agent:status-premium -Quiet

# Detailed diagnostics
pnpm agent:doctor -Verbose

# Policy compliance check
pnpm agent:policy-check
```

## 🔒 **Lock Management**

### **Emergency Lock**
```powershell
# Lock agent immediately
"emergency-maintenance" > .agent/LOCK

# Check lock status
pnpm agent:status-premium -Json | ConvertFrom-Json | Select-Object lock, status

# Remove lock
Remove-Item .agent/LOCK
```

### **Scheduled Maintenance**
```powershell
# Lock for scheduled maintenance
"maintenance-$(Get-Date -Format 'yyyy-MM-dd')" > .agent/LOCK

# Verify lock is active
pnpm agent:status-premium

# Remove lock after maintenance
Remove-Item .agent/LOCK
```

## 🚨 **Recovery Procedures**

### **Recovery Drill**
```powershell
# Run automated recovery test
pnpm agent:drill-recover

# This will:
# 1. Capture pre-lock status
# 2. Apply lock
# 3. Verify locked status
# 4. Remove lock
# 5. Verify post-lock status
# 6. Generate report
```

### **Service Recovery**
```powershell
# Check service health
sc query codex-local

# If service is stopped, restart
sc start codex-local

# Check logs for errors
Get-Content ".agent/logs/service.err.log" | Select-Object -Last 20

# If persistent issues, reinstall
pwsh -File scripts/agent/service-uninstall.ps1 -Force
pwsh -File scripts/agent/service-install.ps1
```

### **Configuration Recovery**
```powershell
# Backup current configuration
Copy-Item ".agent/config.json" ".agent/config.json.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Restore from backup
Copy-Item ".agent/config.json.backup.YYYYMMDD-HHMMSS" ".agent/config.json"

# Validate configuration
pnpm agent:doctor
```

## 📊 **Monitoring & Alerting**

### **Health Monitoring**
```powershell
# Continuous monitoring
pnpm agent:status-premium -Continuous

# Fleet-wide monitoring
pnpm agent:status-fleet

# JSON output for external monitoring
pnpm agent:status-premium -Json | ConvertFrom-Json | Select-Object state, lastUpdate
```

### **Performance Monitoring**
```powershell
# Check performance metrics
pnpm agent:status-premium -Json | ConvertFrom-Json | Select-Object ema

# Monitor guardrail performance
pnpm agent:guardrails-premium -Json | ConvertFrom-Json | Select-Object filesProcessed, violations
```

### **Telemetry Integration**
```powershell
# Send metrics to SigNoz
pnpm agent:telemetry

# Dry run telemetry
pnpm agent:telemetry-dry

# Check telemetry configuration
pnpm agent:status-premium -Json | ConvertFrom-Json | Select-Object metrics
```

## 🛡️ **Security Operations**

### **Policy Compliance**
```powershell
# Check policy compliance
pnpm agent:policy-check

# JSON output for CI
pnpm agent:policy-check -Json

# Verbose policy check
pnpm agent:policy-check -Verbose
```

### **Secrets Audit**
```powershell
# Check for secrets in logs
pnpm agent:test-secrets

# Validate environment
pnpm agent:test-determinism

# Check concurrency controls
pnpm agent:test-concurrency
```

### **SBOM Generation**
```powershell
# Generate Software Bill of Materials
pnpm agent:generate-sbom

# Verbose SBOM generation
pnpm agent:generate-sbom -Verbose

# Check SBOM location
Get-Content "docs/sbom/sbom-metadata.json" | ConvertFrom-Json
```

## 🔄 **Maintenance Procedures**

### **Regular Maintenance**
```powershell
# Weekly health check
pnpm agent:doctor -Verbose

# Monthly policy review
pnpm agent:policy-check -Verbose

# Quarterly SBOM update
pnpm agent:generate-sbom -Verbose
```

### **Update Procedures**
```powershell
# Backup current state
Copy-Item ".agent" ".agent.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Recurse

# Update dependencies
pnpm update

# Verify after update
pnpm agent:doctor

# Test all functions
pnpm agent:drill-recover
```

### **Cleanup Procedures**
```powershell
# Clean old log files
Get-ChildItem ".agent/logs" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item

# Clean old backups
Get-ChildItem ".agent" -Filter "*.backup.*" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-90) } | Remove-Item

# Clean temporary files
Get-ChildItem ".agent" -Filter "*.tmp" | Remove-Item -Force
```

## 🚨 **Troubleshooting**

### **Common Issues**

#### **Service Won't Start**
```powershell
# Check service status
sc query codex-local

# Check logs
Get-Content ".agent/logs/service.err.log" | Select-Object -Last 20

# Check permissions
Get-Acl ".agent" | Format-List

# Reinstall service
pwsh -File scripts/agent/service-uninstall.ps1 -Force
pwsh -File scripts/agent/service-install.ps1
```

#### **Lock Stuck**
```powershell
# Check lock file
Get-Content .agent/LOCK

# Force remove lock
Remove-Item .agent/LOCK -Force

# Verify status
pnpm agent:status-premium
```

#### **Policy Failures**
```powershell
# Check policy file
Test-Path "policies/codex.rego"

# Check OPA installation
Test-Path "scripts/agent/opa.exe"

# Run policy check with verbose output
pnpm agent:policy-check -Verbose
```

#### **Performance Issues**
```powershell
# Check system resources
Get-Process | Where-Object { $_.ProcessName -like "*node*" -or $_.ProcessName -like "*pwsh*" } | Select-Object ProcessName, CPU, WorkingSet

# Check log file sizes
Get-ChildItem ".agent/logs" | Select-Object Name, Length, LastWriteTime

# Monitor in real-time
pnpm agent:status-premium -Continuous
```

### **Emergency Procedures**

#### **Complete System Recovery**
```powershell
# Stop all services
sc stop codex-local

# Remove lock
Remove-Item .agent/LOCK -Force -ErrorAction SilentlyContinue

# Clean temporary files
Get-ChildItem ".agent" -Filter "*.tmp" | Remove-Item -Force

# Restart service
sc start codex-local

# Verify recovery
pnpm agent:drill-recover
```

#### **Data Recovery**
```powershell
# Check backup availability
Get-ChildItem ".agent" -Filter "*.backup.*" | Sort-Object LastWriteTime -Descending

# Restore from most recent backup
$latestBackup = Get-ChildItem ".agent" -Filter "*.backup.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Copy-Item $latestBackup.FullName ".agent" -Recurse -Force

# Verify restoration
pnpm agent:doctor
```

## 🔄 **Rollback Procedures**

### **Service Mode Rollback**
```powershell
# Stop and remove Windows service
nssm stop codex-local
nssm remove codex-local confirm

# Verify removal
Get-Service codex-local -ErrorAction SilentlyContinue
# Expected: Service not found
```

### **Agent Emergency Pause**
```powershell
# Create emergency lock
"emergency-rollback-$(Get-Date -Format 'yyyy-MM-dd-HHmm')" > .agent/LOCK

# Verify agent state changes to paused:lock within one cycle
pnpm agent:status-premium -Json | ConvertFrom-Json | Select state
# Expected: state = "paused:lock"
```

### **Policy Enforcement Disable**
```powershell
# Set environment variable to disable enforcement
$env:CODEX_POLICY_ENFORCE = "0"

# Doctor will warn but CI still runs read-only
pnpm agent:doctor
# Expected: Warning about policy enforcement disabled
```

### **CI Gates Override**
```yaml
# Add to PR with override-codex label
# Document who can apply this label (typically: maintainers, security team)
# CI jobs will skip codex-local checks
```

### **Complete System Rollback**
```powershell
# 1. Stop service
nssm stop codex-local

# 2. Create emergency lock
"complete-rollback" > .agent/LOCK

# 3. Disable policy enforcement
$env:CODEX_POLICY_ENFORCE = "0"

# 4. Revert to previous configuration
Copy-Item ".agent/config.json.backup.YYYYMMDD-HHMMSS" ".agent/config.json"

# 5. Verify rollback
pnpm agent:doctor
```

## 📞 **Support Contacts**

- **Primary Support**: ops@resonai.com
- **Emergency**: +1-XXX-XXX-XXXX
- **Documentation**: [GitHub Wiki](https://github.com/resonai/codex-local/wiki)
- **Issues**: [GitHub Issues](https://github.com/resonai/codex-local/issues)

## 📋 **Checklists**

### **Daily Operations**
- [ ] Check service status: `sc query codex-local`
- [ ] Review logs: `Get-Content ".agent/logs/service.out.log" | Select-Object -Last 10`
- [ ] Verify health: `pnpm agent:doctor`

### **Weekly Operations**
- [ ] Run recovery drill: `pnpm agent:drill-recover`
- [ ] Check policy compliance: `pnpm agent:policy-check`
- [ ] Review performance metrics: `pnpm agent:status-premium -Json`

### **Monthly Operations**
- [ ] Update SBOM: `pnpm agent:generate-sbom`
- [ ] Clean old logs and backups
- [ ] Review security audit: `pnpm agent:test-secrets`

### **Emergency Response**
- [ ] Assess impact and scope
- [ ] Implement immediate containment
- [ ] Execute recovery procedures
- [ ] Document incident and resolution
- [ ] Conduct post-incident review

---

**Last Updated**: 2025-09-27  
**Version**: 1.0.0  
**Next Review**: 2025-10-27
