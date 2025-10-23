# 🐾 BossCat OEM Schema — V3 Automation Architecture

**Date:** 2025-10-23  
**Authority:** BossCat OEM  
**Version:** v3.0  
**Status:** ✅ OPERATIONAL

---

## 🏗️ Schema Overview

The BossCat OEM schema defines the complete automation architecture for gate advancement, built on SigNoz v3 schema with autonomous detection and evidence packaging.

### **Core Components**

| Component | Purpose | Status |
|-----------|---------|--------|
| **V3 Schema** | SigNoz trace storage (`signoz_index_v3`) | ✅ Discovered |
| **Service Column** | Materialized service name (`resource_string_service$$name`) | ✅ Validated |
| **Gate Automation** | End-to-end advancement (`gate-v3-complete.ps1`) | ✅ Deployed |
| **Monitoring Loop** | Autonomous detection (`gate-self-signal-monitor.ps1`) | 🟢 Running |
| **Evidence Packaging** | ECRR artifacts + BossCat logs | ✅ Ready |

---

## 🔄 Automation Flow (Cyclical)

```
TRACE EMIT → SigNoz Transformer → TABLES → BossCat Schema Process-analyze → TRACE EMIT
     ↑                                                                           ↓
     └─────────────────── V3 Automation Loop ──────────────────────────────────┘
```

### **Flow Components**

1. **TRACE EMIT (Blue)**
   - Source: `send-canary-trace-direct.ps1`
   - Payload: OTLP spans with `service.name=canary-test`
   - Flag: `bosscat.synthetic=true`

2. **SigNoz Transformer (Orange)**
   - Component: SigNoz OTel Collector + ClickHouse exporter
   - Function: Attribute normalization → ClickHouse v3 schema
   - Critical: `action: insert` (preserves `canary-test`)

3. **TABLES (Blue)**
   - Primary: `signoz_traces.signoz_index_v3`
   - Service: `resource_string_service$$name` (materialized)
   - Cross-check: `signoz_traces.span_attributes`

4. **BossCat Schema Process-analyze (Orange)**
   - Detection: `gate-self-signal-check.ps1` (v3 queries)
   - Automation: `gate-v3-complete.ps1` (evidence packaging)
   - Monitoring: `gate-self-signal-monitor.ps1` (2-min polling)

---

## 📊 V3 Schema Definition

### **Primary Table Structure**
```sql
-- SigNoz v3 Trace Index
CREATE TABLE signoz_traces.signoz_index_v3 (
    timestamp DateTime64(9),
    traceID String,
    spanID String,
    parentSpanID String,
    operationName String,
    
    -- Materialized Columns (Fast Queries)
    resource_string_service$$name LowCardinality(String),
    attribute_string_http$$route LowCardinality(String),
    attribute_string_db$$system LowCardinality(String),
    attribute_string_rpc$$system LowCardinality(String),
    attribute_string_rpc$$service LowCardinality(String),
    attribute_string_rpc$$method LowCardinality(String),
    
    -- Map Columns (Full Attribute Access)
    resources_string Map(LowCardinality(String), String),
    attributes_string Map(LowCardinality(String), String),
    attributes_number Map(LowCardinality(String), Float64),
    attributes_bool Map(LowCardinality(String), Bool),
    
    -- Indexes
    INDEX idx_timestamp timestamp TYPE minmax GRANULARITY 1,
    INDEX idx_service resource_string_service$$name TYPE set(0) GRANULARITY 1
) ENGINE = MergeTree()
ORDER BY (timestamp, traceID, spanID)
```

### **Service Name Materialization**
```sql
-- Service name is materialized from resources_string['service.name']
-- Column: resource_string_service$$name
-- Query: WHERE `resource_string_service$$name` = 'canary-test'
```

---

## 🎯 Gate Automation Schema

### **Detection Layer**
```powershell
# gate-self-signal-check.ps1
$query = "SELECT count() FROM signoz_traces.signoz_index_v3 
          WHERE ``resource_string_service`$`$name``='canary-test' 
          AND timestamp >= now() - INTERVAL 5 MINUTE;"

$result = docker exec signoz-clickhouse clickhouse-client --query $query
$spanCount = [int]$result.Trim()

# Exit Codes
# 0 = GREEN (traces detected)
# 1 = HOLD (no traces)  
# 2 = ERROR (infrastructure)
```

### **Automation Layer**
```powershell
# gate-v3-complete.ps1
# 1. Send fresh canary trace
# 2. Wait for ingestion (3s)
# 3. V3 schema gate check
# 4. Stability verification (3 additional traces)
# 5. Evidence capture + ECRR packaging
# 6. BossCat log entry
# 7. Gate verdict: 🟢 GREEN
```

### **Monitoring Layer**
```powershell
# gate-self-signal-monitor.ps1
# 1. Poll every 2 minutes
# 2. Run gate-self-signal-check.ps1
# 3. On exit 0 → Auto-execute gate-v3-complete.ps1
# 4. Complete gate advancement without human intervention
```

---

## 📦 Evidence Schema

### **ECRR Artifact Structure**
```json
{
  "timestamp": "2025-10-23T21:39:00.000Z",
  "who": "BossCat_OEM",
  "type": "gate_advancement",
  "lane": "gate",
  "msg": "V3 schema traces persisted for service.name=canary-test",
  "artifacts": [
    "artifacts/ecrr/gate_v3_TIMESTAMP/gate_evidence_TIMESTAMP.txt",
    "artifacts/ecrr/gate_v3_TIMESTAMP/timeline_TIMESTAMP.txt"
  ],
  "result": "GREEN",
  "v3_schema": {
    "table": "signoz_traces.signoz_index_v3",
    "service_column": "resource_string_service$$name",
    "query_used": "SELECT count() FROM signoz_traces.signoz_index_v3 WHERE `resource_string_service$$name`='canary-test' AND timestamp >= now() - INTERVAL 5 MINUTE;",
    "initial_count": 1,
    "stability_count": 4
  }
}
```

### **BossCat Log Entry**
```
docs/BossCat/BOSSCAT_LOG.md
- 2025-10-23T21:39:00Z V3_GATE ✅ traces for canary-test persisted (count=4, window=5m, v3_schema=signoz_index_v3)
```

---

## 🔧 Configuration Schema

### **Collector Configuration**
```yaml
# signoz-collector-config.yaml
processors:
  resource/defaults:
    attributes:
      - key: service.name
        value: resonai-backend
        action: insert  # ← Preserves canary-test (not upsert)
      - key: bosscat.synthetic
        value: "true"
        action: insert

exporters:
  clickhouse/traces:
    endpoint: tcp://signoz-clickhouse:9000?database=signoz_traces
    sending_queue:
      enabled: true
      num_consumers: 4
      queue_size: 10000

processors:
  batch:
    send_batch_size: 500
    timeout: 1s
```

### **Environment Variables**
```powershell
# Canary trace environment
$env:OTEL_SERVICE_NAME="canary-test"
$env:OTEL_TRACES_EXPORTER="otlp"
$env:OTEL_TRACES_SAMPLER="always_on"
$env:OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:14317"
$env:OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
```

---

## 🚦 Gate Decision Schema

### **Decision Matrix**
| Query Result | Exit Code | Verdict | Action |
|--------------|-----------|---------|--------|
| `count() > 0` | **0 (GREEN)** | Traces persisting | Package evidence → @cat ready-for-gate |
| `count() = 0` | **1 (WARN/HOLD)** | Platform gap persists | Continue monitoring |
| Query error | **2 (ERROR)** | Infrastructure issue | Check ClickHouse health |

### **Success Criteria**
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

## 🔍 Query Schema (Canonical)

### **Gate Predicate**
```sql
-- Primary gate check
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name` = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE;
```

### **Timeline Analysis**
```sql
-- Activity timeline
SELECT toStartOfMinute(timestamp) AS minute, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name`='canary-test'
  AND timestamp >= now() - INTERVAL 60 MINUTE
GROUP BY minute
ORDER BY minute;
```

### **Service Mix**
```sql
-- Service distribution
SELECT `resource_string_service$$name` AS svc, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE timestamp >= now() - INTERVAL 24 HOUR
GROUP BY svc ORDER BY spans DESC;
```

---

## 📁 File Schema

### **Automation Scripts**
```
gate-v3-complete.ps1          # Complete automation wrapper
gate-self-signal-check.ps1    # Single gate check
gate-self-signal-monitor.ps1   # Continuous monitoring loop
gate-advance.ps1              # Manual evidence packaging
analyze-trace-schema.ps1      # V3 schema analysis tool
```

### **Documentation**
```
SIGNOZ_V3_SCHEMA_REFERENCE.md    # Canonical query guide
V3_GATE_AUTOMATION_GUIDE.md      # Usage instructions
BOSSCAT_RUNBOOK_UPDATE_DOCKER_EXEC.md  # Runbook alignment
GATE_SELF_SIGNAL_PROTOCOL.md     # Protocol documentation
```

### **Evidence Artifacts**
```
artifacts/ecrr/gate_v3_TIMESTAMP/
├── gate_evidence_TIMESTAMP.txt      # Trace counts + queries
├── timeline_TIMESTAMP.txt          # Activity timeline
└── ECRR_V3_GATE_PROOF_TIMESTAMP.json # ECRR artifact
```

---

## 🎯 Current State Schema

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

## 🔔 Usage Schema

### **One-Liner Automation**
```powershell
# Complete end-to-end automation
pwsh -File .\gate-v3-complete.ps1
```

### **Background Monitoring**
```powershell
# Autonomous monitoring (2-min polling)
pwsh -File .\gate-self-signal-monitor.ps1
```

### **Manual Operations**
```powershell
# Single check only
pwsh -File .\gate-self-signal-check.ps1

# Schema analysis
pwsh -File .\analyze-trace-schema.ps1

# Manual evidence packaging
pwsh -File .\gate-advance.ps1
```

---

## 🐾 BossCat OEM Schema Summary

The BossCat OEM schema defines a complete v3 automation architecture with:

- ✅ **V3 Schema Integration:** `signoz_index_v3` + `resource_string_service$$name`
- ✅ **Autonomous Detection:** 2-minute polling with v3 queries
- ✅ **Complete Automation:** End-to-end gate advancement
- ✅ **Evidence Packaging:** ECRR artifacts + BossCat logs
- ✅ **Cyclical Flow:** Trace emit → Transform → Tables → Process-analyze → Trace emit

**Current Status:** 🟢 **OPERATIONAL** - Standing by for platform fix detection and autonomous gate advancement.

---

**🐾 BossCat OEM Schema v3.0 - Complete automation architecture locked in and ready.**
