# SigNoz Cheat Sheets Index

**Location**: `docs/cheat-sheets/`  
**Purpose**: Quick reference guides for common SigNoz operations and troubleshooting

## 📋 **Available Cheat Sheets**

### **Dashboard & Visualization**
- **`signoz-dashboard-troubleshooting.md`** - Dashboard "no panels" solutions
- **`signoz-dashboard-creation-cheatsheet.md`** - Complete dashboard creation guide
- **`SIGNOZ_QUERY_REFERENCE.md`** - Logs query syntax and examples

### **Data Issues & Troubleshooting**
- **`SIGNOZ_NO_DATA_SOLUTION.md`** - "No data" problem solutions
- **`SIGNOZ_NO_DATA_TROUBLESHOOTING.md`** - Step-by-step troubleshooting guide

## 🚀 **Quick Access Commands**

### **SigNoz URLs**
- **UI**: http://localhost:8080
- **Logs Explorer**: http://localhost:8080/logs
- **Health Check**: http://localhost:8080/api/v1/health

### **Common Queries**
```sql
-- Check for any logs
service.name = "windows-host"

-- Look for queue data
body contains "agent_queue"

-- Check recent activity
timestamp > now() - 15m
```

## 🔧 **Dashboard Creation Process**

1. **Test Data First**: Go to Logs → Explorer
2. **Use Logs Data Source**: Not Prometheus for queue data
3. **Expand Time Range**: Try "Last 24 hours" or "Last 7 days"
4. **Create Simple Test Panel**: `body contains "agent_queue"`
5. **Follow Complete Guide**: See `signoz-dashboard-creation-cheatsheet.md`

## 📊 **Expected Data Sources**

- **Queue Telemetry**: `C:/logs/queue/health.log`
- **Format**: JSON logs with `dataset="agent_queue"`
- **Table**: `signoz_logs.logs_v2`
- **Field**: `body` (contains JSON)

## 🎯 **Agent Instructions**

**ALWAYS CHECK HERE FIRST** before creating dashboards or troubleshooting SigNoz issues. These cheat sheets contain proven solutions for common problems.

---

*Last Updated: 2025-10-02*  
*Location: docs/cheat-sheets/*
