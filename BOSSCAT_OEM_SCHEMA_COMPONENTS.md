# 🐾 BossCat OEM Schema — V3 Automation Components

**Date:** 2025-10-23  
**Authority:** BossCat OEM  
**Version:** v3.0  
**Status:** ✅ OPERATIONAL

---

## 🔧 Component Schema Definitions

### **1. V3 Schema Components**

| Component | Definition | Status |
|-----------|------------|--------|
| **Primary Table** | `signoz_traces.signoz_index_v3` | ✅ Discovered |
| **Service Column** | `resource_string_service$$name` | ✅ Materialized |
| **Query Method** | `docker exec signoz-clickhouse clickhouse-client` | ✅ Working |
| **HTTP Access** | `localhost:8123` | ❌ Not exposed |

### **2. Automation Components**

| Script | Purpose | Exit Codes | Status |
|--------|---------|------------|--------|
| `gate-v3-complete.ps1` | Complete automation wrapper | 0=GREEN, 1=HOLD, 2=ERROR | ✅ Deployed |
| `gate-self-signal-check.ps1` | Single gate check | 0=GREEN, 1=HOLD, 2=ERROR | ✅ Updated |
| `gate-self-signal-monitor.ps1` | Continuous monitoring | Auto-execute on exit 0 | 🟢 Running |
| `gate-advance.ps1` | Manual evidence packaging | 0=GREEN, 1=HOLD | ✅ Updated |
| `analyze-trace-schema.ps1` | V3 schema analysis | N/A | ✅ Working |

### **3. Evidence Components**

| Component | Purpose | Format | Status |
|-----------|---------|--------|--------|
| **ECRR Artifacts** | Gate advancement proof | JSON + TXT | ✅ Ready |
| **BossCat Logs** | Audit trail | Markdown | ✅ Ready |
| **Timeline Data** | Activity analysis | TXT | ✅ Ready |
| **Trace Counts** | Quantitative proof | TXT | ✅ Ready |

---

## 📊 Data Flow Schema

### **Input Data**
```yaml
canary_trace:
  service_name: "canary-test"
  synthetic_flag: "bosscat.synthetic=true"
  environment: "deployment.environment=canary"
  format: "OTLP HTTP/Protobuf"
  endpoint: "localhost:14317 (gRPC)"
```

### **Processing Data**
```yaml
signoz_transformer:
  collector: "SigNoz OTel Collector"
  processor: "resource/defaults (action: insert)"
  exporter: "clickhouse/traces"
  target: "signoz-clickhouse:9000"
  database: "signoz_traces"
```

### **Storage Data**
```yaml
clickhouse_v3:
  table: "signoz_index_v3"
  service_column: "resource_string_service$$name"
  materialized_from: "resources_string['service.name']"
  indexes: ["timestamp", "service_name"]
  engine: "MergeTree"
```

### **Output Data**
```yaml
gate_evidence:
  trace_count: "integer"
  timeline: "minute,spans"
  query_used: "SQL string"
  timestamp: "ISO 8601"
  result: "GREEN|WARN|ERROR"
```

---

## 🔄 Process Schema

### **Detection Process**
```yaml
detection:
  frequency: "2 minutes"
  query: "SELECT count() FROM signoz_index_v3 WHERE service='canary-test' AND timestamp >= now() - 5 MINUTE"
  method: "docker exec"
  timeout: "30 seconds"
  retry: "3 attempts"
```

### **Automation Process**
```yaml
automation:
  trigger: "exit code 0 from detection"
  steps:
    - "Send fresh canary trace"
    - "Wait 3 seconds for ingestion"
    - "V3 schema gate check"
    - "Stability verification (3 additional traces)"
    - "Evidence capture + ECRR packaging"
    - "BossCat log entry"
    - "Gate verdict: 🟢 GREEN"
  timeout: "60 seconds"
  rollback: "ECRR incident logging"
```

### **Evidence Process**
```yaml
evidence:
  directory: "artifacts/ecrr/gate_v3_TIMESTAMP/"
  files:
    - "gate_evidence_TIMESTAMP.txt"
    - "timeline_TIMESTAMP.txt"
    - "ECRR_V3_GATE_PROOF_TIMESTAMP.json"
  log_entry: "docs/BossCat/BOSSCAT_LOG.md"
  format: "UTF-8"
  retention: "30 days"
```

---

## 🎯 Configuration Schema

### **Environment Configuration**
```yaml
environment:
  otel_service_name: "canary-test"
  otel_traces_exporter: "otlp"
  otel_traces_sampler: "always_on"
  otel_exporter_otlp_endpoint: "http://localhost:14317"
  otel_exporter_otlp_protocol: "grpc"
  otel_exporter_otlp_headers: "{}"
```

### **Collector Configuration**
```yaml
collector:
  processors:
    resource_defaults:
      action: "insert"  # Preserves canary-test
      attributes:
        - key: "service.name"
          value: "resonai-backend"
        - key: "bosscat.synthetic"
          value: "true"
  
  exporters:
    clickhouse_traces:
      endpoint: "tcp://signoz-clickhouse:9000?database=signoz_traces"
      sending_queue:
        enabled: true
        num_consumers: 4
        queue_size: 10000
  
  processors:
    batch:
      send_batch_size: 500
      timeout: "1s"
```

### **Monitoring Configuration**
```yaml
monitoring:
  interval_seconds: 120  # 2 minutes
  quiet_mode: false
  max_checks: 1000
  timeout_seconds: 30
  retry_attempts: 3
```

---

## 🔍 Query Schema (Canonical)

### **Primary Gate Query**
```sql
-- V3 schema gate predicate
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name` = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE;
```

### **Timeline Query**
```sql
-- Activity timeline (last hour)
SELECT toStartOfMinute(timestamp) AS minute, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name`='canary-test'
  AND timestamp >= now() - INTERVAL 60 MINUTE
GROUP BY minute
ORDER BY minute;
```

### **Service Mix Query**
```sql
-- Service distribution (last 24 hours)
SELECT `resource_string_service$$name` AS svc, count() AS spans
FROM signoz_traces.signoz_index_v3
WHERE timestamp >= now() - INTERVAL 24 HOUR
GROUP BY svc ORDER BY spans DESC;
```

### **Last Seen Query**
```sql
-- Most recent canary-test trace
SELECT max(timestamp) AS last_seen
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name` = 'canary-test';
```

---

## 📁 File System Schema

### **Script Directory Structure**
```
C:\otel\
├── gate-v3-complete.ps1          # Complete automation wrapper
├── gate-self-signal-check.ps1    # Single gate check
├── gate-self-signal-monitor.ps1   # Continuous monitoring loop
├── gate-advance.ps1              # Manual evidence packaging
├── analyze-trace-schema.ps1      # V3 schema analysis tool
├── send-canary-trace-direct.ps1  # Canary trace generator
└── canary-test.ps1               # Original canary test
```

### **Documentation Structure**
```
C:\otel\
├── BOSSCAT_OEM_SCHEMA_V3.md           # Complete schema definition
├── SIGNOZ_V3_SCHEMA_REFERENCE.md      # Canonical query guide
├── V3_GATE_AUTOMATION_GUIDE.md        # Usage instructions
├── BOSSCAT_RUNBOOK_UPDATE_DOCKER_EXEC.md  # Runbook alignment
├── GATE_SELF_SIGNAL_PROTOCOL.md       # Protocol documentation
└── GATE_GREEN_FLIP_PROCEDURE.md       # Gate advancement guide
```

### **Evidence Structure**
```
C:\otel\artifacts\ecrr\gate_v3_TIMESTAMP\
├── gate_evidence_TIMESTAMP.txt        # Trace counts + queries
├── timeline_TIMESTAMP.txt             # Activity timeline
└── ECRR_V3_GATE_PROOF_TIMESTAMP.json # ECRR artifact
```

### **Log Structure**
```
C:\otel\docs\BossCat\
└── BOSSCAT_LOG.md                     # Audit trail
```

---

## 🚦 Decision Schema

### **Gate Decision Matrix**
```yaml
gate_decisions:
  green:
    condition: "count() > 0 in last 5 minutes"
    action: "Package evidence → @cat ready-for-gate"
    exit_code: 0
    verdict: "🟢 GREEN"
  
  warn:
    condition: "count() = 0 (platform gap persists)"
    action: "Continue monitoring"
    exit_code: 1
    verdict: "🟠 WARN"
  
  error:
    condition: "ClickHouse query failed"
    action: "Check infrastructure"
    exit_code: 2
    verdict: "🔴 ERROR"
```

### **Success Criteria**
```yaml
success_criteria:
  fresh_traces: "count() > 0 in last 5 minutes"
  service_preservation: "canary-test not overwritten"
  stability: "multiple traces persist"
  evidence: "ECRR artifacts generated"
  logging: "BossCat log updated"
  signal: "ready-for-gate posted"
```

---

## 🔔 Usage Schema

### **One-Liner Usage**
```powershell
# Complete automation
pwsh -File .\gate-v3-complete.ps1

# Background monitoring
pwsh -File .\gate-self-signal-monitor.ps1

# Single check
pwsh -File .\gate-self-signal-check.ps1

# Schema analysis
pwsh -File .\analyze-trace-schema.ps1
```

### **Dry Run Mode**
```powershell
# Test automation without execution
pwsh -File .\gate-v3-complete.ps1 -DryRun

# Verbose output
pwsh -File .\gate-v3-complete.ps1 -Verbose
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
