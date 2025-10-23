# 🎯 V3 Gate Automation — Complete Usage Guide

**Date:** 2025-10-23  
**Authority:** BossCat OEM  
**Status:** ✅ READY FOR DEPLOYMENT

---

## 🚀 One-Liner Usage

### **Complete Automation (Recommended)**
```powershell
# Full end-to-end: check → advance → report
pwsh -File .\gate-v3-complete.ps1
```

**What it does:**
1. ✅ Sends fresh canary trace
2. ✅ Waits for ClickHouse ingestion (3s)
3. ✅ V3 schema gate check (signoz_index_v3)
4. ✅ Stability verification (3 additional traces)
5. ✅ Evidence capture & ECRR packaging
6. ✅ BossCat log entry
7. ✅ Gate verdict: 🟢 GREEN

**Exit Codes:**
- **0 (GREEN):** Traces persisting → Gate ready
- **1 (HOLD):** No fresh traces → Platform gap persists
- **2 (ERROR):** Infrastructure issue → Check ClickHouse

---

## 🔄 Background Monitoring (Autonomous)

### **Start Monitoring Loop**
```powershell
# 2-minute polling until platform fix detected
pwsh -File .\gate-self-signal-monitor.ps1
```

**What it does:**
1. ✅ Polls every 2 minutes
2. ✅ Runs `gate-self-signal-check.ps1`
3. ✅ When exit 0 detected → Auto-executes `gate-v3-complete.ps1`
4. ✅ Complete gate advancement without human intervention

**Current Status:** 🟢 **RUNNING** (3 background processes active)

---

## 🔍 Individual Components

### **Single Check Only**
```powershell
# Just check current state (no advancement)
pwsh -File .\gate-self-signal-check.ps1
```

### **Manual Gate Advancement**
```powershell
# Package evidence only (assumes traces exist)
pwsh -File .\gate-advance.ps1
```

### **Schema Analysis**
```powershell
# Discover services and analyze v3 schema
pwsh -File .\analyze-trace-schema.ps1
```

---

## 📊 V3 Schema Reference

### **Correct Table & Column**
```sql
-- Gate predicate (copy-paste ready)
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name` = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE
```

### **Docker Exec Method**
```bash
# PowerShell backtick escaping
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_traces.signoz_index_v3 WHERE \`resource_string_service\$\$name\`='canary-test' AND timestamp >= now() - INTERVAL 5 MINUTE;"
```

---

## 🎯 Current State (Verified)

| Component | Status | Evidence |
|-----------|--------|----------|
| **V3 Schema** | ✅ Working | signoz_index_v3 + resource_string_service$$name |
| **Service Preservation** | ✅ Working | 1 canary-test span exists (not overwritten) |
| **Fresh Trace Persistence** | ❌ Broken | 0 recent spans (7+ hours old) |
| **Monitoring Loop** | 🟢 Running | 2-min polling active |
| **Automation Ready** | ✅ Ready | gate-v3-complete.ps1 deployed |

---

## 🚦 Gate Decision Matrix

| Scenario | Action | Result |
|----------|--------|--------|
| **Fresh traces detected** | Auto-execute complete automation | 🟢 GREEN |
| **No fresh traces** | Continue monitoring | 🟠 WARN |
| **ClickHouse error** | Alert + manual intervention | 🔴 ERROR |

---

## 📁 Evidence Artifacts

When gate advances, creates:
```
artifacts/ecrr/gate_v3_YYYYMMDD_HHMMSS/
├── gate_evidence_TIMESTAMP.txt      # Trace counts + queries
├── timeline_TIMESTAMP.txt          # Activity timeline
└── ECRR_V3_GATE_PROOF_TIMESTAMP.json # ECRR artifact
```

Plus BossCat log entry:
```
docs/BossCat/BOSSCAT_LOG.md
```

---

## 🔧 Troubleshooting

### **If Automation Fails**
1. Check ClickHouse health: `docker exec signoz-clickhouse clickhouse-client -q "SELECT 1"`
2. Verify service name preservation: `pwsh -File .\analyze-trace-schema.ps1`
3. Test manual canary: `pwsh -File .\send-canary-trace-direct.ps1`

### **If Monitoring Stops**
```powershell
# Restart monitoring loop
pwsh -File .\gate-self-signal-monitor.ps1
```

---

## 🎉 Success Criteria

**Gate flips to GREEN when:**
- ✅ Fresh traces detected (count() > 0 in last 5 min)
- ✅ Service name preserved (canary-test not overwritten)
- ✅ Stability confirmed (multiple traces persist)
- ✅ Evidence packaged (ECRR artifacts generated)
- ✅ BossCat log updated
- ✅ Ready for @cat ready-for-gate signal

---

**🐾 V3 automation locked in. Ready for platform fix detection and autonomous gate advancement.**
