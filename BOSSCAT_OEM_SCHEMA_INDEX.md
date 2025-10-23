# 🐾 BossCat OEM Schema — V3 Automation Index

**Date:** 2025-10-23  
**Authority:** BossCat OEM  
**Version:** v3.0  
**Status:** ✅ OPERATIONAL

---

## 📚 Schema Documentation Index

### **Core Schema Files**

| File | Purpose | Status |
|------|---------|--------|
| `BOSSCAT_OEM_SCHEMA_V3.md` | Complete automation architecture | ✅ Complete |
| `BOSSCAT_OEM_SCHEMA_COMPONENTS.md` | Component definitions & data flow | ✅ Complete |
| `SIGNOZ_V3_SCHEMA_REFERENCE.md` | Canonical query guide | ✅ Complete |
| `V3_GATE_AUTOMATION_GUIDE.md` | Usage instructions | ✅ Complete |

### **Supporting Documentation**

| File | Purpose | Status |
|------|---------|--------|
| `BOSSCAT_RUNBOOK_UPDATE_DOCKER_EXEC.md` | Runbook alignment | ✅ Complete |
| `GATE_SELF_SIGNAL_PROTOCOL.md` | Protocol documentation | ✅ Complete |
| `GATE_GREEN_FLIP_PROCEDURE.md` | Gate advancement guide | ✅ Complete |
| `SIGNOZ_V3_SCHEMA_DISCOVERY.md` | Schema discovery notes | ✅ Complete |

---

## 🎯 Quick Reference

### **One-Liner Automation**
```powershell
# Complete end-to-end automation
pwsh -File .\gate-v3-complete.ps1
```

### **V3 Schema Query**
```sql
-- Gate predicate (copy-paste ready)
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name` = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE;
```

### **Docker Exec Method**
```bash
# PowerShell backtick escaping
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_traces.signoz_index_v3 WHERE \`resource_string_service\$\$name\`='canary-test' AND timestamp >= now() - INTERVAL 5 MINUTE;"
```

---

## 🔄 Automation Flow

```
TRACE EMIT → SigNoz Transformer → TABLES → BossCat Schema Process-analyze → TRACE EMIT
     ↑                                                                           ↓
     └─────────────────── V3 Automation Loop ──────────────────────────────────┘
```

### **Flow Components**
1. **TRACE EMIT (Blue):** `send-canary-trace-direct.ps1`
2. **SigNoz Transformer (Orange):** SigNoz OTel Collector + ClickHouse exporter
3. **TABLES (Blue):** `signoz_traces.signoz_index_v3` + `resource_string_service$$name`
4. **BossCat Schema Process-analyze (Orange):** `gate-self-signal-monitor.ps1` + `gate-v3-complete.ps1`

---

## 📊 Current State

### **Operational Status**
```yaml
v3_schema:
  table: "signoz_traces.signoz_index_v3"
  service_column: "resource_string_service$$name"
  method: "docker exec (HTTP 8123 not exposed)"
  status: "✅ WORKING"

service_preservation:
  action: "insert (not upsert)"
  evidence: "1 canary-test span exists (not overwritten)"
  status: "✅ WORKING"

fresh_trace_persistence:
  last_canary: "2025-10-23 14:25 UTC (7+ hours ago)"
  recent_query: "0 spans (5 min window)"
  status: "❌ BROKEN (platform gap)"

automation:
  monitoring_loop: "🟢 RUNNING (3 processes, 2-min polling)"
  gate_advancement: "✅ READY (auto-execute on detection)"
  evidence_packaging: "✅ READY (ECRR + BossCat logs)"
  status: "✅ OPERATIONAL"
```

---

## 🚦 Gate Decision Matrix

| Query Result | Exit Code | Verdict | Action |
|--------------|-----------|---------|--------|
| `count() > 0` | **0 (GREEN)** | Traces persisting | Package evidence → @cat ready-for-gate |
| `count() = 0` | **1 (WARN/HOLD)** | Platform gap persists | Continue monitoring |
| Query error | **2 (ERROR)** | Infrastructure issue | Check ClickHouse health |

---

## 🔧 Component Status

### **Automation Scripts**
| Script | Purpose | Status |
|--------|---------|--------|
| `gate-v3-complete.ps1` | Complete automation wrapper | ✅ Deployed |
| `gate-self-signal-check.ps1` | Single gate check | ✅ Updated |
| `gate-self-signal-monitor.ps1` | Continuous monitoring | 🟢 Running |
| `gate-advance.ps1` | Manual evidence packaging | ✅ Updated |
| `analyze-trace-schema.ps1` | V3 schema analysis | ✅ Working |

### **Evidence Components**
| Component | Purpose | Status |
|-----------|---------|--------|
| ECRR Artifacts | Gate advancement proof | ✅ Ready |
| BossCat Logs | Audit trail | ✅ Ready |
| Timeline Data | Activity analysis | ✅ Ready |
| Trace Counts | Quantitative proof | ✅ Ready |

---

## 🎯 Success Criteria

```yaml
gate_success:
  fresh_traces: "count() > 0 in last 5 minutes"
  service_preservation: "canary-test not overwritten"
  stability: "multiple traces persist"
  evidence: "ECRR artifacts generated"
  logging: "BossCat log updated"
  signal: "ready-for-gate posted"
```

---

## 🔔 Usage Examples

### **Complete Automation**
```powershell
# Full end-to-end automation
pwsh -File .\gate-v3-complete.ps1
```

### **Background Monitoring**
```powershell
# Autonomous monitoring (2-min polling)
pwsh -File .\gate-self-signal-monitor.ps1
```

### **Single Check**
```powershell
# Just check current state
pwsh -File .\gate-self-signal-check.ps1
```

### **Schema Analysis**
```powershell
# Discover services and analyze v3 schema
pwsh -File .\analyze-trace-schema.ps1
```

---

## 📁 File Structure

```
C:\otel\
├── BOSSCAT_OEM_SCHEMA_V3.md           # Complete schema definition
├── BOSSCAT_OEM_SCHEMA_COMPONENTS.md   # Component definitions
├── SIGNOZ_V3_SCHEMA_REFERENCE.md      # Canonical query guide
├── V3_GATE_AUTOMATION_GUIDE.md        # Usage instructions
├── gate-v3-complete.ps1               # Complete automation wrapper
├── gate-self-signal-check.ps1         # Single gate check
├── gate-self-signal-monitor.ps1       # Continuous monitoring loop
├── gate-advance.ps1                   # Manual evidence packaging
├── analyze-trace-schema.ps1           # V3 schema analysis tool
└── artifacts/ecrr/gate_v3_TIMESTAMP/  # Evidence artifacts
```

---

## 🐾 BossCat OEM Schema Summary

The BossCat OEM schema v3.0 defines a complete automation architecture with:

- ✅ **V3 Schema Integration:** `signoz_index_v3` + `resource_string_service$$name`
- ✅ **Autonomous Detection:** 2-minute polling with v3 queries
- ✅ **Complete Automation:** End-to-end gate advancement
- ✅ **Evidence Packaging:** ECRR artifacts + BossCat logs
- ✅ **Cyclical Flow:** Trace emit → Transform → Tables → Process-analyze → Trace emit

**Current Status:** 🟢 **OPERATIONAL** - Standing by for platform fix detection and autonomous gate advancement.

---

**🐾 BossCat OEM Schema v3.0 - Complete automation architecture locked in and ready.**
