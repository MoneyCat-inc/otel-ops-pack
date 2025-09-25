# 🐾 Cat Nap Control Room — Operator's Manual

**IONA Error Observability Hub** | *Where bots run laps and cats nap in peace*

---

## 🚀 Quick Start (30 seconds)

```powershell
# 1. Log an error
.\scripts\log-error.ps1 -Type "System Error" -Context "Test error" -Impact "Demo" -Resolution "Fixed"

# 2. Export to JSON
.\scripts\export-errors.ps1 -OutputPath errors.json

# 3. Start the bots
node scripts/error-server.js

# 4. Open Control Room
start iona-error-dashboard.html
```

**Status**: ✅ All systems operational | 🌙 Cat napping peacefully

---

## 📊 The Observability Triad

| **Component** | **Purpose** | **Endpoint** | **Status Check** |
|---------------|-------------|--------------|------------------|
| 📊 **Metrics** | Error counts, resolution rates | `http://localhost:14318/v1/metrics` | Dashboard → Check Metrics |
| 🔍 **Traces** | Individual error lifecycles | `http://localhost:14318/v1/traces` | Dashboard → Check Traces |
| 📝 **Logs** | Structured error events | `http://localhost:14318/v1/logs` | Dashboard → Check Logs |
| 📈 **Dashboard** | Real-time monitoring | `iona-error-dashboard.html` | WebSocket + Polling |
| 🌙 **SigNoz** | Unified observability | `http://localhost:8080` | Dashboard → Open SigNoz UI |

---

## 🎯 Error Types & Lifecycle

### Error Types
- **Usage Error** → INFO level logs
- **System Error** → ERROR level logs  
- **Guardrail Violation** → WARN level logs

### Lifecycle Stages
1. **Created** → Metrics + Traces + Logs emitted
2. **Open** → Tracked in dashboard, visible in SigNoz
3. **Resolved** → Status updated, resolution rate calculated

---

## 🔧 Bot Commands

### PowerShell Bots
```powershell
# Log new error
.\scripts\log-error.ps1 -Type "System Error" -Context "Description" -Impact "Impact" -Resolution "Fix"

# Export current state
.\scripts\export-errors.ps1 -OutputPath errors.json -PrettyPrint

# Emit metrics only
.\scripts\emit-signoz-metrics.ps1 -MetricType "gauge" -MetricName "iona.errors.total" -MetricValue 5

# Emit traces only  
.\scripts\emit-signoz-traces.ps1 -TraceName "iona.error.created" -ErrorId "2025-01-27-001" -LifecycleStage "created"

# Emit logs only
.\scripts\emit-signoz-logs.ps1 -LogLevel "INFO" -LogMessage "Error created" -ErrorId "2025-01-27-001" -LogEvent "error.created"
```

### Node.js Bot
```bash
# Start WebSocket server + SigNoz broadcaster
node scripts/error-server.js

# Output: 🚀 IONA Error WS server running on ws://localhost:8080
```

---

## 📈 Dashboard Controls

| **Button** | **Action** | **Purpose** |
|------------|------------|-------------|
| **Load Sample Data** | Demo with 5 sample errors | Testing & onboarding |
| **Import JSON File** | Load exported error data | Manual data import |
| **Export Data** | Download current state | Backup & sharing |
| **Refresh Now** | Manual update | Force refresh |
| **Check Metrics** | Test SigNoz metrics endpoint | Health check |
| **Check Traces** | Test SigNoz traces endpoint | Health check |
| **Check Logs** | Test SigNoz logs endpoint | Health check |
| **Open SigNoz UI** | Launch SigNoz interface | Full observability |

---

## 🌙 SigNoz Queries

### Metrics Queries
```sql
-- Error count over time
iona.errors.total

-- Resolution rate trend  
iona.errors.resolution_rate

-- Open error count
iona.errors.open_count
```

### Trace Queries
```sql
-- All error traces
service.name = "iona-error-system"

-- Specific error by ID
error.id = "2025-01-27-001"

-- Error types
error.type = "System Error"
```

### Log Queries
```sql
-- All IONA error logs
service.name = "iona-error-system"

-- Error creation events
log.event = "error.created"

-- Error resolution events
log.event = "error.resolved"

-- By severity level
log.level = "ERROR"
```

---

## 🔍 Troubleshooting

| **Issue** | **Symptom** | **Fix** |
|-----------|-------------|---------|
| **WebSocket disconnected** | Dashboard shows "retrying..." | Check `node scripts/error-server.js` is running |
| **SigNoz unavailable** | Status shows "❌ Unavailable" | Verify SigNoz running on `http://localhost:8080` |
| **No data in dashboard** | "No data available" | Run `.\scripts\export-errors.ps1 -OutputPath errors.json` |
| **Metrics not updating** | SigNoz shows old data | Check `http://localhost:14318` endpoint |
| **File not found** | PowerShell errors | Ensure scripts in `C:\otel\scripts\` |

---

## 📋 Daily Operations

### Morning Checklist
- [ ] Start WebSocket server: `node scripts/error-server.js`
- [ ] Open dashboard: `iona-error-dashboard.html`
- [ ] Check SigNoz UI: `http://localhost:8080`
- [ ] Verify all status indicators green ✅

### Error Response
1. **Log the error**: `.\scripts\log-error.ps1 ...`
2. **Monitor dashboard**: Watch real-time updates
3. **Investigate in SigNoz**: Drill down via traces/logs
4. **Resolve & update**: Mark status as "✅ Fixed"

### End of Day
- [ ] Export final state: `.\scripts\export-errors.ps1 -OutputPath daily-errors.json`
- [ ] Review resolution rate in dashboard
- [ ] Check SigNoz for any unresolved errors
- [ ] Let the cat nap peacefully 🌙

---

## 🎭 The Cat Nap Philosophy

> **"The best observability system is one where the cat can nap while the bots do laps."**

### Principles
- **Automation First**: Bots handle the heavy lifting
- **Real-time Updates**: No manual refresh needed
- **Single Source of Truth**: `IONA_ERRORS.md` is authoritative
- **Complete Correlation**: Metrics + Traces + Logs linked by `error.id`
- **Calm Efficiency**: "Cat Nap Control Room" aesthetic throughout

### Success Metrics
- **Resolution Rate**: Target >80%
- **Response Time**: Errors visible in dashboard <30s
- **Correlation**: All three observability pillars linked
- **Cat Happiness**: Peaceful napping without interruption 🌙

---

## 📞 Emergency Contacts

| **Issue** | **Contact** | **Response Time** |
|-----------|-------------|-------------------|
| **System Down** | Cursor Agent | Immediate |
| **SigNoz Issues** | SigNoz Documentation | 5 minutes |
| **Script Errors** | PowerShell Help | 2 minutes |
| **Cat Disturbed** | 🚨 **CRITICAL** | Immediate |

---

## 🏆 Achievement Unlocked

**✅ Complete Observability Triad**
- 📊 Metrics: Automated error tracking
- 🔍 Traces: Individual error exploration  
- 📝 Logs: Structured event correlation
- 📈 Dashboard: Real-time monitoring
- 🌙 SigNoz: Unified observability stack

**The Cat Nap Control Room is fully operational. The bots are running laps. The cat is napping peacefully. All is well.** 🐾✨

---

*Last Updated: 2025-01-27 | Version: 1.1 | Status: Fully Operational*
