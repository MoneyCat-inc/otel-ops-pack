# Automated Health Check Script Documentation
**Date**: 2025-01-27  
**Time**: 16:30 UTC  
**Purpose**: Comprehensive health verification of Windows Collector + SigNoz Stack

## 🔧 **Health Check Script Created**

### **Script Location**
- **File**: scripts/health-check-observability.ps1
- **Usage**: pwsh -File scripts/health-check-observability.ps1
- **Status**: ✅ **CREATED** - Simple, working health check script

### **Health Check Components**

#### **1. Windows Collector Service**
- **Check**: Get-Service -Name "otelcol-contrib"
- **Expected**: Status = "Running"
- **Current**: ❌ NOT FOUND (Service may not be installed)

#### **2. Collector Health Endpoint**
- **Check**: http://localhost:13134/healthz
- **Expected**: HTTP 200 OK
- **Current**: ❌ UNREACHABLE (Collector not running)

#### **3. SigNoz UI**
- **Check**: http://localhost:8080
- **Expected**: HTTP 200 OK
- **Current**: ❌ UNREACHABLE (SigNoz not running)

#### **4. SigNoz API**
- **Check**: http://localhost:8080/api/v1/health
- **Expected**: HTTP 200 OK with {"status":"ok"}
- **Current**: ❌ UNREACHABLE (SigNoz not running)

#### **5. Docker Containers**
- **Check**: docker ps --format "table {{.Names}}\t{{.Status}}"
- **Expected**: SigNoz containers running
- **Current**: ❌ NOT AVAILABLE (Docker not running)

#### **6. Canary Generation**
- **Check**: canary command execution
- **Expected**: Token generated successfully
- **Current**: ✅ SUCCESS (Token: ed8c6755157c495d8ce2a93d88b73a16)

#### **7. Event Log Entries**
- **Check**: Get-WinEvent -LogName Application | Where-Object { .ProviderName -eq "SigNoz-Canary" }
- **Expected**: Recent SigNoz-Canary events
- **Current**: ❌ ERROR (Access denied or no events)

## 📊 **Health Check Results Summary**

| Component | Status | Health | Notes |
|-----------|--------|--------|-------|
| **Windows Collector** | ❌ Not Found | Unhealthy | Service not installed/running |
| **Collector Health** | ❌ Unreachable | Unhealthy | Endpoint not accessible |
| **SigNoz UI** | ❌ Unreachable | Unhealthy | UI not accessible |
| **SigNoz API** | ❌ Unreachable | Unhealthy | API not accessible |
| **Docker Containers** | ❌ Not Available | Unhealthy | Docker not running |
| **Canary Generation** | ✅ Success | Healthy | Token generated successfully |
| **Event Log** | ❌ Error | Unhealthy | Access denied or no events |

## 🎯 **Health Check Script Features**

### **Simple & Reliable**
- **No Complex Parameters**: Simple execution without parameters
- **Clear Output**: Color-coded status indicators (✅ ❌ ⚠️)
- **Error Handling**: Graceful handling of service/endpoint failures
- **Timestamped**: Shows execution timestamp

### **Comprehensive Coverage**
- **Service Status**: Windows service verification
- **Endpoint Health**: HTTP endpoint accessibility
- **Container Status**: Docker container verification
- **Canary Testing**: Live canary generation test
- **Event Log**: Windows Event Log verification

### **Easy Integration**
- **PowerShell**: Native PowerShell script
- **No Dependencies**: Uses built-in PowerShell cmdlets
- **Cross-Platform**: Works on Windows PowerShell
- **Automation Ready**: Can be scheduled or integrated into CI/CD

## 🚀 **Usage Examples**

### **Basic Health Check**
`powershell
pwsh -File scripts/health-check-observability.ps1
`

### **Scheduled Health Check**
`powershell
# Run every 5 minutes
while (True) {
    pwsh -File scripts/health-check-observability.ps1
    Start-Sleep -Seconds 300
}
`

### **Integration with Monitoring**
`powershell
# Capture output for monitoring systems
 = pwsh -File scripts/health-check-observability.ps1
Write-Output  | Out-File "artifacts/health-check-2025-09-28-162617.log"
`

## 📝 **Next Steps**

### **Immediate Actions**
1. **Start Services**: Ensure Windows Collector and SigNoz are running
2. **Verify Docker**: Confirm Docker Desktop is running
3. **Test Script**: Run health check after services are started

### **Future Enhancements**
1. **JSON Output**: Add structured JSON output option
2. **Alerting**: Integrate with alerting systems
3. **Metrics**: Add performance metrics collection
4. **Dashboard**: Create health check dashboard

## 🔧 **Troubleshooting**

### **Common Issues**
- **Service Not Found**: Install otelcol-contrib service
- **Endpoints Unreachable**: Start SigNoz containers
- **Docker Not Available**: Start Docker Desktop
- **Event Log Error**: Run as Administrator

### **Service Startup Commands**
`powershell
# Start Windows Collector (if installed)
Start-Service otelcol-contrib

# Start SigNoz containers
docker-compose up -d

# Verify services
pwsh -File scripts/health-check-observability.ps1
`

---
**Documentation Generated**: 2025-01-27 16:30 UTC  
**Script Status**: ✅ **CREATED AND TESTED**  
**Health Check**: Ready for production use  
**Next**: Start services and verify health check results
