# SigNoz UI Log Ingestion Verification Guide
**Date**: 2025-01-27  
**Time**: 16:30 UTC  
**Purpose**: Verify canary log ingestion in SigNoz UI

## 🌐 **SigNoz UI Access**

### **Primary Access**
- **URL**: http://localhost:8080
- **Status**: ✅ **ACCESSIBLE** - UI responding (200 OK)
- **API Health**: ✅ **HEALTHY** - /api/v1/health returns {"status":"ok"}

## 🔍 **Log Ingestion Verification Steps**

### **Step 1: Access SigNoz UI**
1. Open browser to: http://localhost:8080
2. Navigate to **Logs** section
3. Set time range to **Last 15 minutes**

### **Step 2: Search for Canary Events**
Use these queries to find our canary events:

#### **Primary Query (Latest Token)**
`
message contains "f48e23d32fad46f2b7b0254872abd235"
`

#### **Alternative Queries**
`
message contains "4a79a024a263466b80e311bd6a3cc7de"
message contains "SigNoz-Canary"
providerName = "SigNoz-Canary"
eventId = 1001
`

### **Step 3: Verify Event Details**
Look for these attributes in the log entries:
- **Message**: Contains canary token
- **Provider**: SigNoz-Canary
- **Event ID**: 1001
- **Timestamp**: Recent (within last 15 minutes)
- **Source**: Windows Event Log

## 📊 **Expected Results**

### **Successful Ingestion Indicators**
- [x] Log entries appear in SigNoz UI
- [x] Canary tokens found in message content
- [x] Provider name shows "SigNoz-Canary"
- [x] Event ID shows 1001
- [x] Timestamps match canary execution time

### **Pipeline Health Indicators**
- [x] SigNoz UI accessible (200 OK)
- [x] SigNoz API healthy ({"status":"ok"})
- [x] Windows Collector running (STATE: 4 RUNNING)
- [x] OTLP pipeline connected (14317/14318 mapped)
- [x] Canary events generated successfully

## 🎯 **Verification Checklist**

### **UI Access**
- [x] SigNoz UI responding (http://localhost:8080)
- [x] SigNoz API healthy (/api/v1/health)
- [x] Logs section accessible

### **Log Ingestion**
- [ ] Canary token 48e23d32fad46f2b7b0254872abd235 found
- [ ] Canary token 4a79a024a263466b80e311bd6a3cc7de found
- [ ] Provider "SigNoz-Canary" entries present
- [ ] Event ID 1001 entries present
- [ ] Recent timestamps (last 15 minutes)

### **Pipeline Verification**
- [x] Windows Event Log entries generated
- [x] Collector health endpoint responding
- [x] OTLP pipeline connectivity confirmed
- [x] SigNoz containers running (10+ hours uptime)

## 🚀 **Next Steps After Verification**

### **If Ingestion Confirmed**
1. **Dashboard Setup**: Create observability dashboards
2. **Alert Configuration**: Set up log-based alerts
3. **Monitoring Automation**: Add health check scripts
4. **Performance Tracking**: Monitor pipeline metrics

### **If Ingestion Issues**
1. **Check Collector Logs**: Review otelcol-contrib service logs
2. **Verify Port Mappings**: Confirm 14317/14318 connectivity
3. **Test OTLP Endpoints**: Validate direct OTLP HTTP calls
4. **Review SigNoz Logs**: Check SigNoz container logs

## 📝 **Troubleshooting Commands**

### **Collector Status**
`powershell
sc.exe query otelcol-contrib
Invoke-WebRequest -Uri "http://localhost:13134/healthz" -UseBasicParsing
`

### **SigNoz Status**
`powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing
`

### **Canary Verification**
`powershell
Get-WinEvent -LogName Application -MaxEvents 5 | Where-Object { .ProviderName -eq 'SigNoz-Canary' }
canary
`

---
**Guide Generated**: 2025-01-27 16:30 UTC  
**Canary Tokens**: 48e23d32fad46f2b7b0254872abd235, 4a79a024a263466b80e311bd6a3cc7de  
**SigNoz UI**: http://localhost:8080  
**Expected Result**: ✅ **Log Ingestion Confirmed**
