# Future Operations Guide - Windows Collector Monitoring
**Created**: 2025-10-02  
**Purpose**: Quick reference for future Docker and log source management

---

## 🐳 **Docker Service Management**

### **Current Status**
- **Docker Services**: Intentionally offline in development environment
- **Monitoring**: Shows as `[WARN]` with explanatory note
- **Impact**: Non-critical, does not affect observability stack

### **When Docker Comes Back Online**

#### **Option 1: Remove Warning Override**
```powershell
# Edit scripts/automated-service-monitoring.ps1
# Change Docker service configuration from:
@{
    Name = "Docker Services"
    Type = "process"
    Endpoint = "docker"
    Critical = $false
    Note = "Docker may be intentionally offline in development environments"
}

# To:
@{
    Name = "Docker Services"
    Type = "process"
    Endpoint = "docker"
    Critical = $true
}
```

#### **Option 2: Downgrade Warning**
```powershell
# Keep as non-critical but remove the note:
@{
    Name = "Docker Services"
    Type = "process"
    Endpoint = "docker"
    Critical = $false
}
```

#### **Verification After Change**
```powershell
# Test the updated monitoring
pwsh -File scripts\automated-service-monitoring.ps1

# Check scheduled task is still running
Get-ScheduledTask -TaskName "OTel-Service-Monitoring"
```

---

## 📊 **New Log Source Integration**

### **Step-by-Step Process**

#### **1. Add Log Source to Collector Config**
```yaml
# Edit config.yaml - add new receiver
receivers:
  filelog/new-source:
    include:
      - C:/logs/new-source/*.log
    start_at: end
    include_file_path: true
    poll_interval: 200ms

# Add to pipeline
service:
  pipelines:
    logs:
      receivers:
        - otlp
        - windowseventlog/application
        - windowseventlog/system
        - filelog/queue
        - filelog/canary
        - filelog/new-source  # Add here
```

#### **2. Add Saved Query**
```markdown
# Edit docs/signoz-saved-queries.md
# Add new query section:

# Query X: New Source Logs
# Purpose: Monitor new log source
# SigNoz UI: Logs → Add Filter → log.file.path contains "C:/logs/new-source/"
{
  "name": "New Source Logs",
  "description": "Logs from new source",
  "query": "log.file.path contains \"C:/logs/new-source/\"",
  "timeRange": "Last 1 hour",
  "category": "NewSource"
}
```

#### **3. Update Monitoring Script (if needed)**
```powershell
# If new source needs health monitoring, add to services array:
@{
    Name = "New Source Service"
    Type = "process"  # or "http" or "port"
    Endpoint = "new-source-process"
    Critical = $true  # or $false
}
```

#### **4. Re-baseline Monitoring**
```powershell
# Run monitoring sweep to establish new baseline
pwsh -File scripts\automated-service-monitoring.ps1

# Check results
Get-Content artifacts\service-monitoring.log -Tail 10

# Verify in SigNoz UI
# Open http://localhost:8080 → Logs → Apply new filter
```

#### **5. Test New Source**
```powershell
# Generate test logs
echo "Test log entry" >> C:\logs\new-source\test.log

# Wait 30 seconds, then check SigNoz
# Filter: log.file.path contains "C:/logs/new-source/"
```

---

## 🔄 **Monitoring Maintenance**

### **Regular Checks**
```powershell
# Weekly monitoring review
Get-Content artifacts\service-monitoring.log -Tail 50 | Select-String "ERROR\|ALERT"

# Check scheduled task status
Get-ScheduledTask -TaskName "OTel-Service-Monitoring"

# Review health check artifacts
Get-ChildItem artifacts\health-check-*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

### **Alert Configuration**
```powershell
# Enable notifications when needed
# Edit artifacts/alert-config.json
# Set webhook URLs or email addresses
# Restart monitoring to pick up changes
```

---

## 📋 **Quick Reference Commands**

### **Docker Management**
```powershell
# Check if Docker is running
Get-Process -Name "docker" -ErrorAction SilentlyContinue

# Start Docker Desktop (if installed)
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Update monitoring after Docker changes
pwsh -File scripts\automated-service-monitoring.ps1
```

### **Log Source Verification**
```powershell
# Check collector config
Get-Content config.yaml | Select-String "new-source"

# Test log generation
echo "$(Get-Date): Test entry" >> C:\logs\new-source\test.log

# Verify in SigNoz
# UI: http://localhost:8080 → Logs → Filter: log.file.path contains "C:/logs/new-source/"
```

### **Monitoring Status**
```powershell
# Current status
pwsh -File scripts\automated-service-monitoring.ps1

# Scheduled task
Get-ScheduledTask -TaskName "OTel-Service-Monitoring"

# Recent logs
Get-Content artifacts\service-monitoring.log -Tail 20
```

---

## ✅ **Success Criteria**

### **Docker Integration**
- ✅ Docker service shows as healthy in monitoring
- ✅ No false warnings in logs
- ✅ Scheduled task continues running

### **New Log Source**
- ✅ Logs appear in SigNoz UI with correct filter
- ✅ Monitoring script includes new source (if applicable)
- ✅ Saved query documented in signoz-saved-queries.md
- ✅ Health check baseline established

---

## 🎯 **Current System Status**

**Windows Collector**: ✅ PID 29172, 14h+ uptime, ports 5317/5318 listening  
**Monitoring**: ✅ 4/5 services healthy, Docker warning properly handled  
**Scheduled Task**: ✅ Ready state, 5-minute coverage  
**Documentation**: ✅ Complete with troubleshooting and saved queries  
**Next Actions**: ✅ Ready for Docker integration and new log sources

**🟢 ALL SYSTEMS OPERATIONAL - READY FOR FUTURE EXPANSION**
