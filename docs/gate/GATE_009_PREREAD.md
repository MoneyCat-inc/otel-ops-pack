<!-- markdownlint-disable MD022 MD031 MD032 MD040 -->
# 🐾 Gate #009 Pre-Read

> **Path note (2026-09-02).** The V3 schema documents cited below moved to `docs/archive/BossCat/schema/`
> (2025 records); references updated in place.

**Status:** PREPARATION  
**Previous Gate:** #008 (APPROVED 2025-10-22, EDGE WRITER DEPLOYED 2025-10-23)  
**Target Date:** TBD  
**Prepared:** 2025-10-22
**Updated:** 2025-10-23 (Edge Writer & V3 Schema Integration)

---

## 🚀 **Major Update from Gate #008: Edge Writer Implementation**

**Date:** 2025-10-23T22:38:27Z  
**Status:** ✅ **DEPLOYED & OPERATIONAL**  
**Commits:** 38 commits (ab0244396 → 4bfbe8556)

### Edge Writer Architecture
```
Canary Emit → Edge Writer (14321) → ClickHouse v3 → BossCat Gate
             (OTLP HTTP)           (signoz_index_v3)
```

**Key Achievement:** Bypassed flaky SigNoz transformer hop, established direct write path to ClickHouse v3 schema.

### New Components (Gate #009 Baseline)
1. **signoz-writer Service**
   - Container: `signoz-writer` (signoz/signoz-otel-collector:latest)
   - Ports: 14320 (gRPC), 14321 (HTTP)
   - Purpose: Direct OTLP → ClickHouse v3 pipeline
   - Config: `signoz-writer.yaml`

2. **V3 Schema Queries**
   - Primary Table: `signoz_traces.signoz_index_v3`
   - Service Column: `resource_string_service$$name`
   - Canonical Query Method: `docker exec signoz-clickhouse clickhouse-client`

3. **Automation Scripts**
   - `bosscat-oem-v3-monitor.ps1` - Autonomous monitoring loop
   - `bosscat-oem-v3-check.ps1` - Single gate check
   - `bosscat-oem-v3-complete.ps1` - Complete gate advancement
   - `send-canary-trace-direct.ps1` - Edge writer canary routing

4. **Documentation**
   - `docs/archive/BossCat/schema/EDGE_WRITER_DEPLOYMENT_SUMMARY.md` - Complete reference
   - `docs/archive/BossCat/schema/SIGNOZ_V3_SCHEMA_REFERENCE.md` - V3 schema documentation
   - `docs/archive/BossCat/schema/BOSSCAT_OEM_SCHEMA_V3.md` - Automation architecture
   - `docs/archive/BossCat/schema/V3_GATE_AUTOMATION_GUIDE.md` - Usage guide

### Verified Metrics (2025-10-23)
- **Traces Persisting:** 66 spans (canary-test) in `signoz_index_v3`
- **Edge Writer Uptime:** Since 2025-10-23 22:01 UTC
- **CI/CD Verification:** BossCat Gate Verification PASSED (4/4 environments)
- **Security Scans:** Gitleaks, CodeQL, Trivy all GREEN

---

## 🎯 Gate #009 Focus Areas

### 1. Post-Launch Stability
- **Hub Production:** hub.resonai.uk operational health (first week metrics)
- **Bluesky Campaign:** Engagement metrics and growth tracking
- **Windows Collector:** Sustained uptime and metrics reliability

### 2. Iterative Convergence Monitoring
- Cycle-over-cycle improvement tracking
- Gate velocity optimization
- Documentation quality trends
- Remediation pattern analysis

### 3. Performance Baselines
- Pipeline latency trends
- Container resource usage
- Canary test success rates
- SigNoz query performance

---

## 📊 Performance Baselines from Gate #008

### System Metrics (Updated 2025-10-23)
```
Windows Collector:
  - Status: RUNNING
  - Uptime: Since 2025-10-22 09:20 UTC
  - Metrics Port: 8888 serving
  - Service: Automatic startup

Docker Containers:
  - Count: 8/8 healthy (NEW: signoz-writer added)
  - Services: 
    * signoz-otel-collector
    * signoz-writer (NEW - Edge Writer)
    * signoz
    * 3× otel-gpu-*
    * clickhouse
    * zookeeper

OTLP Endpoints:
  - Main Collector gRPC: 14317 operational
  - Main Collector HTTP: 14318 operational
  - Edge Writer gRPC: 14320 operational (NEW)
  - Edge Writer HTTP: 14321 operational (NEW)
  - UI: 8080 operational

SigNoz:
  - Health API: {"status":"ok"}
  - Version: v0.96.1
  - ClickHouse v3 Schema: ACTIVE
```

### Pipeline Performance (Updated 2025-10-23)
```
Canary Tests:
  - Status: PASSING (Edge Writer path)
  - End-to-end: SUCCESS
  - Traces: Delivered to port 14321 (Edge Writer)
  - Logs: Ingested to ClickHouse
  - V3 Schema: 66 spans confirmed in signoz_index_v3
  - Service Preservation: canary-test identity intact
  - Fresh traces: 2025-10-23 22:38:27

Edge Writer Performance:
  - P95 Ingest Latency: ≤ 5s (target)
  - Canary Persistence: ≥1 span/2 min (target)
  - Writer Availability: ≥99.9% (target)
  - Direct ClickHouse Write: Bypasses transformer hop
```

### Asset Metrics
```
HTML Files: 51 (verified)
ECRR Reports: 104 gate-related
Docker Services: 7
Critical Endpoints: 6 (Hub)
```

---

## 🎯 Gate #009 Success Criteria (Draft)

### GATE-CORE
- [x] Windows Collector: RUNNING with sustained uptime (> 7 days)
- [ ] Docker containers: 8/8 healthy with no restarts (NEW: signoz-writer)
- [ ] OTLP endpoints: All operational with < 200ms response
- [ ] Edge Writer: Operational with 14320/14321 ports (NEW)
- [ ] SigNoz health: "ok" status maintained
- [ ] Canary tests: 100% pass rate over 7 days (via Edge Writer)
- [ ] V3 Schema: Traces persisting to signoz_index_v3 (NEW)
- [ ] Metrics scraping: No "Failed to scrape" warnings

### GATE-SITE
- [ ] Hub production: 7 days uptime, all endpoints HTTP 200
- [ ] HTML files: Count stable at 51 (or documented changes)
- [ ] CSP: No violations reported
- [ ] Canonical reference: docs/comfort-cat/ current

### GOVERNANCE
- [ ] ECRR methodology: Continued 100% compliance
- [ ] Evidence trails: Comprehensive for new changes
- [ ] Working tree: Clean at gate assessment time
- [ ] No new IONA-MEDIUM or higher incidents

### NEW: POST-LAUNCH
- [ ] Hub metrics: Traffic data collected (if available)
- [ ] Bluesky growth: Follower count tracked, engagement measured
- [ ] Iterative convergence: Improvement trends documented
- [ ] No production incidents or rollbacks

---

## 📈 Canary Delta Tracking (Gate #008 Baseline)

### Baseline Metrics (Updated 2025-10-23)
```json
{
  "date": "2025-10-23",
  "gate": "8 → 9 transition",
  "edge_writer": {
    "status": "DEPLOYED",
    "container": "signoz-writer",
    "ports": {
      "grpc": 14320,
      "http": 14321
    },
    "uptime_since": "2025-10-23T22:01:28Z"
  },
  "canary_tests": {
    "total_runs": "~10",
    "success_rate": "100%",
    "avg_duration": "~30 seconds",
    "endpoints": {
      "traces": "http://localhost:14321/v1/traces",
      "logs": "http://localhost:14318/v1/logs"
    },
    "v3_schema": {
      "table": "signoz_traces.signoz_index_v3",
      "service_column": "resource_string_service$$name",
      "verified_spans": 66
    }
  },
  "windows_event_log": {
    "source": "SigNoz-Canary",
    "event_id": 1001,
    "delivery": "SUCCESS"
  },
  "file_log": {
    "path": "C:\\logs\\canary-test.log",
    "delivery": "SUCCESS"
  }
}
```

### Delta Targets for Gate #009
- Canary success rate: Maintain 100%
- Average duration: < 30 seconds
- Windows Event Log: 100% delivery
- File log: 100% delivery
- No failed deliveries over 7-day period

---

## 🔮 Iterative Convergence Indicators

### Gate Velocity
- **Gate #007 → #008:** 2 days (rapid iteration)
- **Target for #008 → #009:** 3-7 days (allow for stabilization)

### Remediation Quality
- **Gate #008:** 1 blocker (Windows Collector), 4 major issues
- **Target for #009:** 0 blockers, < 2 major issues

### Documentation Quality
- **Gate #008:** 4 Fubumaki review rounds needed
- **Target for #009:** ≤ 2 review rounds (better initial accuracy)

### Evidence Quality
- **Gate #008:** Multiple stale data instances
- **Target for #009:** All metrics verified before claiming

---

## 📋 Preparation Checklist for Gate #009

### Pre-Gate (1 Week Before Assessment)
- [ ] Run 7-day stability baseline
- [ ] Collect Hub traffic metrics
- [ ] Gather Bluesky growth data
- [ ] Review IONA_ERRORS.md for new incidents
- [ ] Verify all containers stable (no restarts)

### Gate Assessment
- [ ] Run full verification suite
- [ ] **Verify every claim before documenting** (lesson from Gate #008)
- [ ] Count explicitly: Docker containers, HTML files, etc.
- [ ] Check git status before claiming clean
- [ ] Run canary checks as part of verification
- [ ] Generate evidence with verified metrics only

### Evidence Generation
- [ ] Create gate verification JSON with baselines
- [ ] Generate ECRR report (if needed)
- [ ] Update dashboard with verified metrics
- [ ] Document any changes since Gate #008
- [ ] Include convergence indicators

---

## 🎓 Lessons from Gate #008 (Apply to #009)

### What NOT to Do
1. ❌ Don't claim status without verifying commands
2. ❌ Don't count containers/files from memory
3. ❌ Don't assume working tree is clean
4. ❌ Don't skip canary verification
5. ❌ Don't minimize blockers to P2

### What TO Do
1. ✅ Run verification commands for every claim
2. ✅ Count explicitly using actual commands
3. ✅ Always check git status
4. ✅ Verify canary checks before claiming success
5. ✅ Classify blockers accurately
6. ✅ Use qualitative descriptions for stability
7. ✅ Expect multiple review rounds

---

## 🚀 Next Steps for Gate #009

1. **Let systems stabilize** - 7 days minimum
2. **Collect metrics** - Hub, Bluesky, pipeline
3. **Run baseline** - Capture performance data
4. **Prepare evidence** - Verify before documenting
5. **Assessment** - Apply lessons from Gate #008
6. **Review** - Expect Fubumaki feedback
7. **Approve** - BossCat OEM decision

---

---

## 📚 **NEW: V3 Schema & Automation Documentation**

### Core Schema Files
1. **docs/archive/BossCat/schema/BOSSCAT_OEM_SCHEMA_V3.md** - Comprehensive BossCat OEM architecture
   - Automation framework
   - Gate discipline
   - Component definitions

2. **docs/archive/BossCat/schema/SIGNOZ_V3_SCHEMA_REFERENCE.md** - ClickHouse v3 schema
   - Table structures
   - Column mappings
   - Query examples

3. **docs/archive/BossCat/schema/EDGE_WRITER_DEPLOYMENT_SUMMARY.md** - Complete deployment reference
   - Architecture overview
   - SLOs & health monitors
   - Rollback procedures

4. **docs/archive/BossCat/schema/V3_GATE_AUTOMATION_GUIDE.md** - Usage guide
   - Monitoring loop
   - One-liner wrapper
   - Troubleshooting

### Automation Scripts
```powershell
# Background monitoring (2-min intervals)
pwsh -File .\bosscat-oem-v3-monitor.ps1

# Single gate check
pwsh -File .\bosscat-oem-v3-check.ps1

# Complete gate advancement
pwsh -File .\bosscat-oem-v3-complete.ps1

# Send canary to edge writer
pwsh -File .\send-canary-trace-direct.ps1
```

### V3 Schema Query Examples

**Canonical V3 Query (SSOT for Gate #009):**
```sql
-- Recent canary trace count (5 minutes) - AUTHORITATIVE
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE `resource_string_service$$name` = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE;
```

**Additional Queries:**
```sql
-- Recent canary trace count (alternative format)
SELECT count()
FROM signoz_traces.signoz_index_v3
WHERE resource_string_service$$name = 'canary-test'
  AND timestamp >= now() - INTERVAL 5 MINUTE;

-- Timeline (last 30 minutes, per minute)
SELECT toStartOfMinute(timestamp) AS t, count() AS n
FROM signoz_traces.signoz_index_v3
WHERE resource_string_service$$name = 'canary-test'
  AND timestamp >= now() - INTERVAL 30 MINUTE
GROUP BY t
ORDER BY t;
```

### Quick Operator Loop
```powershell
# 1) Emit canary
pwsh -File .\send-canary-trace-direct.ps1

# 2) Verify in v3 (docker exec)
docker exec signoz-clickhouse clickhouse-client --query `
  "SELECT count() FROM signoz_traces.signoz_index_v3
    WHERE resource_string_service$$name='canary-test'
      AND timestamp >= now() - INTERVAL 5 MINUTE;"
```

---

## 🎯 **Gate #009 New Requirements**

### Edge Writer Stability (NEW)
- [ ] 7-day uptime with no restarts
- [ ] P95 ingest latency ≤ 5s
- [ ] Canary persistence ≥1 span/2 min
- [ ] No insert errors in logs
- [ ] Ports 14320/14321 continuously available

**SLO Targets:**

| Metric                    | Target            | Alert Threshold       |
|---------------------------|-------------------|-----------------------|
| Ingest p95 (emit→v3)      | ≤ 5s              | > 15s                 |
| Canary persistence        | ≥ 1 span / 2 min  | 0 spans in 6 min      |
| Writer uptime (7 days)    | ≥ 99.9%           | >3 restarts/10 min    |

### V3 Schema Validation (NEW)
- [ ] All traces persisting to `signoz_index_v3`
- [ ] Service names preserved (no overwrites)
- [ ] `resource_string_service$$name` column functional
- [ ] Timeline queries returning expected results
- [ ] No schema migration issues

### Automation Health (NEW)
- [ ] V3 monitoring scripts operational
- [ ] Gate checks returning accurate results
- [ ] Complete automation wrapper functional
- [ ] Documentation aligned with implementation

---

## 🧯 **Edge Writer Rollback Procedure (ECRR-Safe)**

**If edge writer regresses or shows instability:**

1. **Stop edge writer service:**
   ```powershell
   docker stop signoz-writer
   ```

2. **Revert canary routing:**
   ```powershell
   # Edit send-canary-trace-direct.ps1
   # Change: http://localhost:14321/v1/traces
   # Back to: http://localhost:14318/v1/traces
   ```

3. **Verify old path operational:**
   ```powershell
   pwsh -File .\send-canary-trace-direct.ps1
   # Check logs arrive via main collector
   ```

4. **Attach ECRR incident note:**
   - Evidence: Error logs, trace counts, timeline
   - Impact: Gate returns to WARN
   - Next steps: Investigation required

**Blast Radius:** Controlled - only traces from canary affected, no production impact.

---

**Prepared:** 2025-10-22  
**Updated:** 2025-10-23 (Edge Writer & V3 Schema Integration)  
**Status:** Pre-read phase with major infrastructure update  
**Next Gate:** #009 (TBD)

🐾 _Gate #009 preparation - Edge Writer deployed, V3 schema active, automation operational_
