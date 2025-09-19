# OpenTelemetry Collector → SigNoz On-Call Runbook

## 🚨 **EMERGENCY CONTACTS & ESCALATION**

- **Primary**: [Your team contact]
- **Secondary**: [Backup contact]  
- **Escalation**: [Manager/Lead contact]
- **SigNoz Support**: [If applicable]

---

## ⚡ **QUICK STATUS CHECK (60 seconds)**

```powershell
# From any directory - run these three commands:
& 'C:\otel\green-sheet.ps1'         # Summary: service, path, health, metrics lines
& 'C:\otel\canary-check-min.ps1'    # Should print delta +1 and exit 0
Invoke-WebRequest -Uri http://127.0.0.1:13134/healthz -TimeoutSec 5 | ConvertFrom-Json
```

**Expected Output:**
- Service: Running
- Health: Server available (uptime: XXmXXs)
- Canary: "OK delta observed. before=XXX after=XXX"

---

## 🔧 **TROUBLESHOOTING GUIDE**

### **If Canary Fails**

#### **1. Health Endpoint Down**
```powershell
# Check health
Invoke-WebRequest http://127.0.0.1:13134/healthz

# If fails → restart service
Restart-Service otelcol-contrib
Start-Sleep 5
& 'C:\otel\canary-check-min.ps1'
```

#### **2. Metrics Unreachable**
```powershell
# Check port bindings
netstat -ano | findstr /R ":(5317|5318|8889|13134)\s"

# Check recent logs
Get-Content C:\otel\logs\*.last.txt -Tail 50

# If port conflict on metrics → restart service
Restart-Service otelcol-contrib
```

#### **3. Auto-Restart Policy Issues**
```powershell
# Check current policy
sc.exe qfailure otelcol-contrib

# Should show: 3 × RESTART with 60000ms delay
# If not → reapply:
sc.exe failure otelcol-contrib actions= restart/60000/restart/60000/restart/60000 reset= 86400
sc.exe failureflag otelcol-contrib 1
```

### **If Service Looks Running But No Delta**

```powershell
# Check if metrics are increasing over time
(Invoke-WebRequest http://127.0.0.1:8889/metrics -UseBasicParsing).Content `
  -split "`n" | ? {$_ -match 'otelcol_receiver_accepted_log_records'} | Measure-Object

# If flat → check upstream sources:
# - Application logs
# - File logs  
# - Windows Event Logs
# - Manual OTLP test (canary does this)
```

---

## 🔄 **CONFIGURATION CHANGES**

### **After Config Edits**
```powershell
# Apply new config
Copy-Item C:\otel\config-hardened-plus.yaml C:\otel\config.yaml -Force
Restart-Service otelcol-contrib

# Verify
& 'C:\otel\canary-check-min.ps1'
```

### **Config Drift Recovery**
```powershell
# Check for unexpected files or missing core scripts
& 'C:\otel\repo-clean-inventory.ps1'

# If config drift detected → restore baseline
Copy-Item C:\otel\config.yaml.backup C:\otel\config.yaml -Force
Restart-Service otelcol-contrib
& 'C:\otel\canary-check-min.ps1'
```

---

## 🧪 **TESTING & VERIFICATION**

### **Auto-Restart Verification (Admin Required)**
```powershell
# One-command proof of auto-restart
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe `
  -NoProfile -ExecutionPolicy Bypass -File "C:\otel\auto-restart-verify.ps1"
```

### **Regression Check (full stack)**
```powershell
& 'C:\otel\regression-check.ps1'
# Expected: "✅ REGRESSION CHECK PASSED"
```

---

## 📊 **MONITORING & ALERTS**

### **Scheduled Tasks Status**
```powershell
Get-ScheduledTask | Where-Object { $_.TaskName -like "otel_*" } | 
  Select-Object TaskName, State, LastRunTime, LastTaskResult
```

### **Alert Logs**
```powershell
Get-Content C:\otel\ALERTS.log -Tail 20
```

### **Windows Event Log**
```powershell
Get-WinEvent -FilterHashtable @{
  LogName = 'Application'
  Source = 'OTelOps'
  StartTime = (Get-Date).AddHours(-1)
} | Select-Object TimeCreated, Message
```

---

## 🚨 **SEVERE ISSUES**

### **Service Won't Start**
```powershell
# Check service logs
Get-EventLog -LogName Application -Source "OpenTelemetry Collector" -Newest 10

# Check config validation
& "C:\Program Files\OpenTelemetry Collector\otelcol-contrib.exe" --config "C:\otel\config.yaml" --dry-run

# Check port conflicts
netstat -ano | findstr ":5317\|:5318\|:8889\|:13134"
```

### **Queue Backpressure**
```powershell
# Check queue metrics
(Invoke-WebRequest http://127.0.0.1:8889/metrics -UseBasicParsing).Content `
  -split "`n" | ? {$_ -match 'otelcol_exporter_queue_size'}

# If queue > 1000 → restart service
Restart-Service otelcol-contrib
```

### **SigNoz Connectivity**
```powershell
# Check exporter metrics
(Invoke-WebRequest http://127.0.0.1:8889/metrics -UseBasicParsing).Content `
  -split "`n" | ? {$_ -match 'otelcol_exporter_send_failed_requests'}

# If failures > 0 → check network connectivity to SigNoz
```

---

## 📞 **ESCALATION CRITERIA**

**Escalate to Senior Team Member if:**
- Service won't start after 2 restart attempts
- Queue backpressure > 5000 items
- SigNoz connectivity failures > 10% for > 10 minutes
- Config drift detected > 3 times in 1 hour
- Auto-restart not working (verified via test script)

**Escalate to Manager if:**
- Data loss suspected
- Service down > 30 minutes
- Security incident suspected
- Multiple systems affected

---

## 📝 **POST-INCIDENT CHECKLIST**

- [ ] Service status verified
- [ ] Canary test passing
- [ ] Health endpoint responding
- [ ] Metrics endpoint responding
- [ ] Scheduled tasks running
- [ ] Alert logs reviewed
- [ ] Incident documented
- [ ] Root cause identified
- [ ] Prevention measures implemented

---

## 🔗 **QUICK LINKS**

- **Service Management**: `Start-Service otelcol-contrib`, `Stop-Service otelcol-contrib`, `Restart-Service otelcol-contrib`
- **Status Checks**: `C:\otel\green-sheet.ps1`, `C:\otel\quick-all-green.ps1`
- **Testing**: `C:\otel\canary-check-min.ps1`, `C:\otel\regression-check.ps1`
- **Logs**: `C:\otel\logs\`, `C:\otel\ALERTS.log`
- **Config**: `C:\otel\config.yaml`
- **Backups**: `C:\otel\backups\`

---

*Last Updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*
*Pipeline Version: 1.0.0*
