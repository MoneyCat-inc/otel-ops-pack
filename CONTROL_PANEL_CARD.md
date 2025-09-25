# 🐾 Cat Nap Control Room — Control Panel Card

**IONA Error Observability Hub** | *Quick Reference Cheatsheet*

---

## 🚀 Quick Start (30s)

```powershell
# 1. Log Error
.\scripts\log-error.ps1 -Type "System Error" -Context "Test" -Impact "Demo" -Resolution "Fixed"

# 2. Export JSON  
.\scripts\export-errors.ps1 -OutputPath errors.json

# 3. Start Bots
node scripts/error-server.js

# 4. Open Control Room
start iona-error-dashboard.html
```

---

## 📊 Observability Triad

| **Component** | **Script** | **Endpoint** | **Purpose** |
|---------------|------------|--------------|-------------|
| 📊 **Metrics** | `emit-signoz-metrics.ps1` | `:14318/v1/metrics` | Error counts, resolution rates |
| 🔍 **Traces** | `emit-signoz-traces.ps1` | `:14318/v1/traces` | Individual error lifecycles |
| 📝 **Logs** | `emit-signoz-logs.ps1` | `:14318/v1/logs` | Structured error events |

---

## 🎯 Key Files

| **File** | **Location** | **Purpose** |
|----------|--------------|-------------|
| **Error Ledger** | `iona/IONA_ERRORS.md` | Single source of truth |
| **Dashboard** | `iona/iona-error-dashboard.html` | Real-time monitoring |
| **WebSocket Server** | `scripts/error-server.js` | Live updates |
| **Log Error** | `scripts/log-error.ps1` | Error creation |
| **Export JSON** | `scripts/export-errors.ps1` | Data export |

---

## 🌐 Endpoints & Ports

| **Service** | **URL** | **Port** | **Purpose** |
|-------------|---------|----------|-------------|
| **SigNoz UI** | `http://localhost:8080` | 8080 | Observability dashboard |
| **OTLP Metrics** | `http://localhost:14318/v1/metrics` | 14318 | Metrics ingestion |
| **OTLP Traces** | `http://localhost:14318/v1/traces` | 14318 | Traces ingestion |
| **OTLP Logs** | `http://localhost:14318/v1/logs` | 14318 | Logs ingestion |
| **WebSocket** | `ws://localhost:8080` | 8080 | Real-time updates |

---

## 🤖 Bot Commands

### PowerShell Bots
```powershell
# Log Error
.\scripts\log-error.ps1 -Type "Usage Error" -Context "Description" -Impact "Impact" -Resolution "Fix"

# Export Data
.\scripts\export-errors.ps1 -OutputPath errors.json -PrettyPrint

# Emit Metrics
.\scripts\emit-signoz-metrics.ps1 -MetricType "gauge" -MetricName "iona.errors.total" -MetricValue 5

# Emit Traces
.\scripts\emit-signoz-traces.ps1 -TraceName "iona.error.created" -ErrorId "2025-01-27-001" -LifecycleStage "created"

# Emit Logs
.\scripts\emit-signoz-logs.ps1 -LogLevel "INFO" -LogMessage "Error created" -ErrorId "2025-01-27-001" -LogEvent "error.created"
```

### Node.js Bot
```bash
# Start WebSocket Server
node scripts/error-server.js
# Output: 🚀 IONA Error WS server running on ws://localhost:8080
```

---

## 📈 Dashboard Controls

| **Button** | **Action** | **Purpose** |
|------------|------------|-------------|
| **Load Sample Data** | Demo with 5 errors | Testing |
| **Import JSON File** | Load exported data | Manual import |
| **Export Data** | Download current state | Backup |
| **Refresh Now** | Manual update | Force refresh |
| **Check Metrics** | Test SigNoz metrics | Health check |
| **Check Traces** | Test SigNoz traces | Health check |
| **Check Logs** | Test SigNoz logs | Health check |
| **Open SigNoz UI** | Launch SigNoz | Full observability |

---

## 🔍 SigNoz Queries

### Metrics
```sql
iona.errors.total
iona.errors.resolution_rate
iona.errors.open_count
```

### Traces
```sql
service.name = "iona-error-system"
error.id = "2025-01-27-001"
error.type = "System Error"
```

### Logs
```sql
service.name = "iona-error-system"
log.event = "error.created"
log.level = "ERROR"
```

---

## 🚨 Emergency Contacts

| **Issue** | **Contact** | **Response** |
|-----------|-------------|--------------|
| **System Down** | Cursor Agent | Immediate |
| **SigNoz Issues** | SigNoz Docs | 5 minutes |
| **Script Errors** | PowerShell Help | 2 minutes |
| **Cat Disturbed** | 🚨 **CRITICAL** | Immediate |

---

## 📋 Daily Ops Checklist

### Morning
- [ ] Start WebSocket: `node scripts/error-server.js`
- [ ] Open Dashboard: `iona-error-dashboard.html`
- [ ] Check SigNoz: `http://localhost:8080`
- [ ] Verify green status ✅

### Error Response
1. **Log**: `.\scripts\log-error.ps1 ...`
2. **Monitor**: Dashboard updates
3. **Investigate**: SigNoz drill-down
4. **Resolve**: Mark "✅ Fixed"

### End of Day
- [ ] Export: `.\scripts\export-errors.ps1 -OutputPath daily-errors.json`
- [ ] Review resolution rate
- [ ] Check unresolved errors
- [ ] Let cat nap peacefully 🌙

---

## 🎯 Success Metrics

| **Metric** | **Target** | **Current** |
|------------|------------|-------------|
| **Resolution Rate** | >80% | Auto-calculated |
| **Response Time** | <30s | Real-time |
| **Correlation** | 100% | error.id linked |
| **Cat Happiness** | Peaceful | Napping 🌙 |

---

## 🌙 Philosophy

> **"The best observability system is one where the cat can nap while the bots do laps."**

### Core Principles
- **Automation First**: Bots handle heavy lifting
- **Real-time Updates**: No manual refresh needed
- **Single Source of Truth**: IONA_ERRORS.md
- **Complete Correlation**: Metrics + Traces + Logs
- **Calm Efficiency**: Cat Nap Control Room aesthetic

---

## 🏆 Achievement Status

✅ **Complete Observability Triad**  
✅ **Real-time Dashboard**  
✅ **Automated Bot Ecosystem**  
✅ **SigNoz Integration**  
✅ **Comprehensive Documentation**  
✅ **Team Handoff Ready**  

**🌙 THE CAT NAPS PEACEFULLY WHILE THE BOTS DO LAPS 🌙**

---

*Control Panel Card v1.1 | Last Updated: 2025-01-27 | Status: Fully Operational*
