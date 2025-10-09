# SigNoz Log Ingestion Verification Guide
**Date**: 2025-01-27  
**Time**: 16:45 UTC  
**Purpose**: Step-by-step guide to verify SigNoz log ingestion

## 🔍 **Manual SigNoz Verification Steps**

### **Step 1: Access SigNoz UI**
1. **Open Browser**: Navigate to http://localhost:8080
2. **Login**: Use default credentials (if required)
3. **Verify Access**: Confirm SigNoz UI loads successfully

### **Step 2: Check Logs Section**
1. **Navigate to Logs**: Click "Logs" in the left sidebar
2. **Set Time Range**: Select "Last 15 minutes" or "Last 1 hour"
3. **Verify Logs Present**: Confirm logs are being ingested

### **Step 3: Search for Canary Events**
1. **Add Filter**: Click "Add filter" button
2. **Filter Type**: Select "message" or "body"
3. **Filter Value**: Enter "SigNoz-Canary" or latest token
4. **Apply Filter**: Click "Apply" to filter logs
5. **Verify Results**: Confirm canary events appear in results

### **Step 4: Check Log Sources**
1. **Remove Filters**: Clear all filters to see all logs
2. **Check Sources**: Look for logs from different sources:
   - Windows Event Log entries
   - File log entries
   - SigNoz-Canary events
3. **Verify Volume**: Confirm reasonable log volume

### **Step 5: Test Real-time Ingestion**
1. **Generate New Canary**: Run canary command in terminal
2. **Note Token**: Record the generated token
3. **Refresh SigNoz**: Refresh the logs view
4. **Search Token**: Search for the new token
5. **Verify Ingestion**: Confirm new canary appears within 30 seconds

## 📊 **Expected Results**

### **Successful Ingestion Indicators**
- ✅ SigNoz UI loads without errors
- ✅ Logs section shows recent entries
- ✅ Canary events appear in search results
- ✅ Multiple log sources visible
- ✅ New canary events appear within 30 seconds
- ✅ Log volume appears reasonable (not empty, not overwhelming)

### **Troubleshooting Indicators**
- ❌ SigNoz UI doesn't load (check Docker containers)
- ❌ No logs visible (check collector configuration)
- ❌ Canary events not found (check Windows Event Log)
- ❌ Only one log source (check collector inputs)
- ❌ New canary doesn't appear (check OTLP pipeline)

## 🔧 **Verification Commands**

### **Quick Health Check**
`powershell
# Check SigNoz UI accessibility
Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing

# Check SigNoz API health
Invoke-WebRequest -Uri "http://localhost:8080/api/v1/health" -UseBasicParsing

# Generate canary for testing
canary
`

### **Log Source Verification**
`powershell
# Check Windows Event Log for SigNoz-Canary events
Get-WinEvent -LogName Application | Where-Object { .ProviderName -eq "SigNoz-Canary" } | Select-Object -First 5

# Check collector service status
Get-Service -Name "otelcol-contrib"

# Check Docker containers
docker ps --format "table {{.Names}}\t{{.Status}}"
`

## 📝 **Verification Checklist**

### **Pre-Verification**
- [ ] SigNoz containers running
- [ ] Windows Collector service running
- [ ] Canary generation working
- [ ] Health check script passing

### **SigNoz UI Verification**
- [ ] UI loads successfully
- [ ] Logs section accessible
- [ ] Time range selector working
- [ ] Filter functionality working

### **Log Ingestion Verification**
- [ ] Recent logs visible
- [ ] Canary events searchable
- [ ] Multiple log sources present
- [ ] Real-time ingestion working

### **Post-Verification**
- [ ] Dashboard creation ready
- [ ] Alert configuration ready
- [ ] Monitoring setup ready

## 🚀 **Next Steps After Verification**

### **If Ingestion Working**
1. **Create Dashboards**: Implement observability dashboards
2. **Configure Alerts**: Set up critical and warning alerts
3. **Test Alerting**: Verify alert notifications work
4. **Documentation**: Create runbooks and procedures

### **If Ingestion Issues**
1. **Check Collector Config**: Verify OTLP configuration
2. **Check Log Sources**: Verify Windows Event Log and file logs
3. **Check Network**: Verify localhost connectivity
4. **Check Permissions**: Verify service permissions

---
**Guide Generated**: 2025-01-27 16:45 UTC  
**Status**: Ready for manual verification  
**Next**: Follow verification steps and confirm log ingestion
