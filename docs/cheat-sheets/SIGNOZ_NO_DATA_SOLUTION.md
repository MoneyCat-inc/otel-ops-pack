# SigNoz "No Data" Solution Guide

**Issue**: Query syntax correct but returning "no data" in SigNoz  
**Root Cause**: OTel Collector service stopped, preventing log ingestion

## 🔍 **Problem Diagnosis**

✅ **Logs Exist**: Fresh canary logs generated at `C:\logs\windows-canary-test.log`  
✅ **Query Syntax**: Corrected and validated  
❌ **OTel Collector**: Service stopped, preventing ingestion  
✅ **SigNoz Health**: Running and accessible  

## 🚀 **Immediate Solutions**

### **Solution 1: Test Alternative Queries (Try Now)**

Since SigNoz is healthy, test these queries in **Logs → Explore**:

#### **Query 1: Broad Canary Search**
```
body contains "canary"
```

#### **Query 2: Message Content Search**
```
message contains "windows-canary"
```

#### **Query 3: Level-Based Search**
```
level = "INFO"
```

#### **Query 4: Service Field Search**
```
service exists
```

#### **Query 5: Recent Timestamp Search**
```
timestamp >= "2025-10-01T22:35:00Z"
```

### **Solution 2: Check SigNoz Internal Collector**

SigNoz might be using its own collector. Check:

1. **Go to SigNoz UI**: http://localhost:8080
2. **Navigate to**: Logs → Explore
3. **Set Time Range**: "Last 1 hour" or "Last 24 hours"
4. **Try Query**: `service exists` (should show any ingested logs)

### **Solution 3: Use SigNoz Query Builder**

1. **In SigNoz UI**: Logs → Explore
2. **Click**: "Query Builder" 
3. **Add Filters**:
   - Field: `body`
   - Operator: `contains`
   - Value: `canary`
4. **Apply**: See if any results appear

## 🔧 **Alternative Alert Configuration**

If the file-based logs aren't working, try this alert configuration:

### **Alert: Any Canary Activity**
```
Name: Canary Activity Detection
Query: body contains "canary"
Threshold: 1
Operator: below
Evaluation Window: 10m
```

### **Alert: INFO Level Logs**
```
Name: INFO Log Activity
Query: level = "INFO"
Threshold: 1
Operator: below
Evaluation Window: 15m
```

## 📊 **Working Query Examples**

Based on the diagnostic, these should work:

### **For Windows Canary Detection:**
```
body contains "windows-canary"
```

### **For Service-Based Detection:**
```
service = "canary-test"
```

### **For Test ID Detection:**
```
test_id = "canary-alert-test"
```

### **For Level-Based Detection:**
```
level = "INFO" AND body contains "canary"
```

## 🎯 **Step-by-Step Testing Process**

### **Step 1: Test Basic Queries**
1. Open SigNoz UI: http://localhost:8080
2. Go to **Logs → Explore**
3. Set time range to **"Last 24 hours"**
4. Try each query above one by one

### **Step 2: Check Field Explorer**
1. If any logs appear, click on one
2. Expand the fields to see exact field names
3. Use the exact field names in your alert query

### **Step 3: Create Alert**
1. Once you find a working query, create your alert
2. Use the exact query that returned results
3. Set appropriate thresholds and evaluation windows

## 🔄 **Long-term Solution: Fix OTel Collector**

### **Option 1: Restart OTel Collector**
```powershell
# Try to restart the service
Restart-Service otelcol-contrib

# Check if it started
sc query otelcol-contrib
```

### **Option 2: Use SigNoz Internal Collector**
Configure SigNoz to read logs directly from `C:\logs\` if possible.

### **Option 3: Alternative Log Ingestion**
Use SigNoz's file log receiver configuration to read from `C:\logs\`.

## 📋 **Quick Test Commands**

### **Generate Test Logs:**
```powershell
pwsh -File scripts/generate-windows-canary.ps1 -DurationMinutes 1 -IntervalSeconds 15
```

### **Check Log Files:**
```powershell
Get-Content C:\logs\windows-canary-test.log -TotalCount 2
```

### **Diagnose Issues:**
```powershell
pwsh -File scripts/diagnose-signoz-ingestion.ps1
```

## 🎯 **Expected Results**

After following the solutions above, you should see:

1. **Logs in SigNoz UI**: When using the correct query
2. **Working Alert**: Alert that triggers based on log presence/absence
3. **Proper Monitoring**: Continuous canary log monitoring

## 🚨 **If Still No Data**

### **Check These:**
1. **Time Range**: Make sure it includes when logs were generated (22:37 today)
2. **Field Names**: Use SigNoz field explorer to find exact field names
3. **Log Format**: Verify logs are in the expected JSON format
4. **SigNoz Configuration**: Check if SigNoz is configured to read from `C:\logs\`

### **Alternative Approach:**
Create a simple alert that monitors any log activity:
```
Query: level exists
Threshold: 1
Operator: below
Evaluation Window: 30m
```

## 📞 **Support Resources**

- **Troubleshooting Guide**: `docs/SIGNOZ_NO_DATA_TROUBLESHOOTING.md`
- **Query Syntax Fix**: `docs/SIGNOZ_QUERY_SYNTAX_FIX.md`
- **Alert Import Guide**: `docs/SIGNOZ_ALERT_IMPORT_GUIDE.md`
- **Diagnostic Script**: `scripts/diagnose-signoz-ingestion.ps1`

---
*Generated to solve SigNoz "no data" issues*
