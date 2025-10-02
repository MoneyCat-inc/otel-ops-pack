# SigNoz Dashboard Creation Cheat Sheet

**Location**: `docs/cheat-sheets/`  
**Purpose**: Quick reference for creating SigNoz dashboards that actually work

## 🚨 **CRITICAL: Data Source Selection**

### **Use LOGS Data Source for Queue Data**
- ❌ **Wrong**: Prometheus metrics (`otelcol_exporter_queue_size`)
- ✅ **Correct**: Logs data source with JSON parsing

### **Why This Matters**
Queue telemetry comes from JSON log files (`C:/logs/queue/health.log`), not Prometheus metrics. Using the wrong data source results in "no panels" or empty dashboards.

## 🔍 **Step 1: Test Data First**

**ALWAYS** test data availability before creating dashboard panels:

1. **Go to**: SigNoz UI → Logs → Explorer
2. **Set Time Range**: "Last 24 hours" or "Last 7 days"
3. **Test Query**: `body contains "agent_queue"`
4. **Expected**: Should show JSON log entries with queue metrics

### **If No Data Appears**:
- Expand time range to "Last 7 days"
- Check if logs exist: `Get-Content C:/logs/queue/health.log -Tail 5`
- Verify collector is running: `sc query otelcol-contrib`

## 📊 **Step 2: Create Panels with Correct Queries**

### **Panel 1: Queue Depth (Stat)**
```sql
body contains "agent_queue" | json | unwrap queueLength
```
- **Type**: Stat
- **Unit**: short
- **Thresholds**: Green (0), Yellow (10), Red (50)

### **Panel 2: Ready vs Pending (Time Series)**
```sql
-- Ready Count
body contains "agent_queue" | json | unwrap readyCount

-- Pending Count  
body contains "agent_queue" | json | unwrap pendingCount
```
- **Type**: Time Series
- **Legend**: Ready, Pending

### **Panel 3: Kill Switch Status (Stat)**
```sql
body contains "agent_queue" | json | unwrap killSwitch
```
- **Type**: Stat
- **Mappings**: 
  - "true" → Red "ACTIVE"
  - "false" → Green "INACTIVE"

### **Panel 4: Agent Health (Table)**
```sql
body contains "agent_queue" | json | fields agent_name=agentName, jobs_processed=jobsProcessed, last_run=lastRun, timestamp
```
- **Type**: Table
- **Display**: Table mode

## 🎯 **Step 3: Dashboard Configuration**

### **Essential Settings**:
- **Title**: "Queue Steward Dashboard"
- **Tags**: queue, agent, monitoring, signoz, logs
- **Time Range**: "Last 24 hours" (default)
- **Refresh**: 30 seconds
- **Data Source**: Logs (not Prometheus!)

### **Panel Layout**:
```
Row 1: Queue Depth (6w) | Ready vs Pending (12w)
Row 2: Kill Switch (6w) | Agent Health (12w)
Row 3: Queue Trend (12w) | [Empty] (6w)
```

## 🔧 **Common Issues & Solutions**

### **Issue: "No Data" in Panels**
**Solution**: 
1. Check time range (expand to 24h+)
2. Verify data source is "Logs"
3. Test query in Logs Explorer first

### **Issue: Wrong Data Source**
**Solution**: 
- Delete panel and recreate with "Logs" data source
- Don't use Prometheus for queue telemetry

### **Issue: JSON Parsing Errors**
**Solution**: 
- Use `| json | unwrap fieldName` syntax
- Check actual JSON structure in Logs Explorer

### **Issue: Panels Show Empty**
**Solution**: 
- Verify `body contains "agent_queue"` returns data
- Check if logs are being ingested from `C:/logs/queue/health.log`

## 📋 **Quick Test Commands**

### **Check Log Files**:
```powershell
Get-Content C:/logs/queue/health.log -Tail 3
```

### **Check Collector Status**:
```powershell
sc query otelcol-contrib
```

### **Test SigNoz Health**:
```powershell
curl -s http://localhost:8080/api/v1/health
```

## 🎯 **Expected Data Structure**

Queue telemetry logs should contain:
```json
{
  "queueLength": 14,
  "readyCount": 14,
  "pendingCount": 0,
  "killSwitch": false,
  "agentName": "cursor-agent-observability-copilot",
  "jobsProcessed": 8,
  "lastRun": "2025-10-02T01:53:00Z",
  "dataset": "agent_queue"
}
```

## 🚀 **Import Process**

1. **Create Dashboard**: SigNoz UI → Dashboards → New Dashboard
2. **Add Panels**: Use queries above with "Logs" data source
3. **Configure**: Set thresholds, mappings, and display options
4. **Test**: Verify panels show data
5. **Save**: Name and tag the dashboard

## 📊 **JSON Dashboard Template**

Use `queue-steward-dashboard-logs.json` as template:
- Contains correct LOGS data source queries
- Proper JSON parsing syntax
- Appropriate panel types and configurations
- 24-hour time range for better data visibility

---

**Remember**: Always test data availability in Logs Explorer before creating dashboard panels!
