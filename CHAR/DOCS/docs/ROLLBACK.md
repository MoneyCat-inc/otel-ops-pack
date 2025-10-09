# 🚨 Rollback Guide

Quick rollback procedures for the OTel Ops Pack when things go wrong.

## 🚀 Fast Rollback (Emergency)

### 1. Stop All Services
```powershell
# Stop Windows OTel Collector service
Stop-Service -Name "otelcol-contrib" -Force

# Stop SigNoz stack
docker compose -f compose/signoz.yml down

# Kill any remaining processes on key ports
.\scripts\kill-port.ps1 -Ports @(4317, 4318, 14317, 14318, 8080)
```

### 2. Restore Previous Configuration
```powershell
# If you have backups
Copy-Item "configs/otel/collector.yaml.backup" "configs/otel/collector.yaml" -Force
Copy-Item "compose/signoz.yml.backup" "compose/signoz.yml" -Force

# Or revert via git (if changes were committed)
git checkout HEAD~1 -- configs/otel/collector.yaml
git checkout HEAD~1 -- compose/signoz.yml
```

### 3. Restart Services
```powershell
# Start SigNoz stack
docker compose -f compose/signoz.yml up -d

# Wait for SigNoz to be ready
Start-Sleep -Seconds 30

# Start Windows OTel Collector
Start-Service -Name "otelcol-contrib"
```

### 4. Verify Rollback
```powershell
# Run health checks
.\scripts\verify-canary.ps1
pwsh .\tools\hygiene.ps1
```

## 🔧 Component-Specific Rollbacks

### OpenTelemetry Collector
```powershell
# Stop collector
Stop-Service -Name "otelcol-contrib" -Force

# Restore config
Copy-Item "configs/otel/collector.yaml.backup" "configs/otel/collector.yaml" -Force

# Restart collector
Start-Service -Name "otelcol-contrib"

# Verify
Get-Service -Name "otelcol-contrib"
```

### SigNoz Stack
```powershell
# Stop stack
docker compose -f compose/signoz.yml down

# Remove volumes (if data corruption)
docker volume prune -f

# Restore compose file
Copy-Item "compose/signoz.yml.backup" "compose/signoz.yml" -Force

# Start stack
docker compose -f compose/signoz.yml up -d

# Verify
docker ps
curl http://localhost:8080/health
```

### PowerShell Scripts
```powershell
# Revert script changes
git checkout HEAD~1 -- scripts/

# Or restore from backup
Copy-Item "scripts/*.backup" "scripts/" -Force

# Re-run hygiene check
pwsh .\tools\hygiene.ps1
```

## 📋 Pre-Rollback Checklist

- [ ] Identify the last known good state
- [ ] Backup current configuration files
- [ ] Document what went wrong
- [ ] Notify team of rollback plan
- [ ] Prepare rollback commands
- [ ] Test rollback procedure in staging (if available)

## 🔍 Post-Rollback Verification

### Health Checks
```powershell
# Basic connectivity
Test-NetConnection -ComputerName localhost -Port 4317
Test-NetConnection -ComputerName localhost -Port 4318
Test-NetConnection -ComputerName localhost -Port 14317
Test-NetConnection -ComputerName localhost -Port 14318
Test-NetConnection -ComputerName localhost -Port 8080

# Service status
Get-Service -Name "otelcol-contrib"
docker ps

# SigNoz UI
Start-Process "http://localhost:8080"
```

### Data Verification
```powershell
# Check if data is flowing
.\scripts\verify-canary.ps1

# Check SigNoz logs
docker logs signoz-otel-collector-1 --tail 50

# Check Windows Event Logs
Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object {$_.Id -eq 1001}
```

## 🚨 Emergency Contacts

- **On-call Engineer**: [Your contact info]
- **Escalation**: [Manager contact]
- **Documentation**: [Internal wiki link]

## 📝 Rollback Log Template

```
Rollback Date: [DATE]
Rollback Reason: [REASON]
Components Affected: [LIST]
Rollback Duration: [TIME]
Verification Status: [PASS/FAIL]
Lessons Learned: [NOTES]
```

## 🔄 Prevention

- Always test changes in staging first
- Keep configuration backups before major changes
- Use feature flags for risky changes
- Monitor system health continuously
- Document all changes with rollback procedures

---

**Remember**: When in doubt, rollback first, investigate later. It's better to have a working system than a broken one.