# Investor Demo - Narrative Script

**Duration:** 7 minutes  
**Authority:** BossCat OEM  
**Phase:** Phase 1 - Wire Signals & Story

---

## Pre-Demo Setup (5 minutes before)

### 1. Verify Infrastructure
```powershell
# Check all containers running
docker ps | findstr /i "signoz pm-engine redis"

# Verify SigNoz accessible
curl http://localhost:8080/api/v1/health
# Expected: {"status":"ok"}

# Check Windows Collector
sc query otelcol-contrib
# Expected: STATE: 4 RUNNING
```

### 2. Start Demo Services
```powershell
# Terminal 1: Start bosscat-svc2-api (port 5556)
cd C:\otel
pwsh .\scripts\demo\deploy-demo-service.ps1 -ServiceName "bosscat-svc2-api" -Port 5556 -EnableDemo

# Terminal 2: Start bosscat-svc3-worker (port 5557)  
pwsh .\scripts\demo\deploy-demo-service.ps1 -ServiceName "bosscat-svc3-worker" -Port 5557 -EnableDemo
```

### 3. Verify Telemetry Flowing
```powershell
# Run telemetry verification
pwsh .\scripts\demo\verify-telemetry.ps1
# Expected: All checks GREEN
```

### 4. Open Key Windows
- **Tab 1:** http://localhost:8080 (SigNoz Dashboard)
- **Tab 2:** file:///C:/otel/docs/demo/data-room.html (Data Room)
- **Tab 3:** file:///C:/otel/docs/status.html (Executive Status)
- **Tab 4:** This script (for reference)

---

## Demo Storyline (7 minutes)

### 0:00 - 1:00 | Introduction & Healthy System View

**Talking Points:**
- "We've built an observability platform that proves operational safety through automated telemetry and performance gates."
- "What you're seeing is a production-grade .NET service with zero-code OpenTelemetry instrumentation."

**Actions:**
1. **Show Executive Dashboard** (status.html or SigNoz)
   - Point out: P95 latency ~112ms, Error rate 0%, Baseline traffic

2. **Open Data Room** (data-room.html)
   - "This is our test harness - we can generate controlled traffic and chaos scenarios on demand"

3. **Start Laminar Flow**
   - Click "Start" on **Laminar Flow** scenario
   - Show live metrics updating: 10 RPS steady baseline

**Expected State:**
- Metrics: P95 ~112ms, Error 0%, RPS 10
- All tiles GREEN
- Traffic flowing to both svc2-api and svc3-worker

**Curl Commands (Backup):**
```powershell
# Test svc2-api health
curl http://localhost:5556/health

# Test svc3-worker health  
curl http://localhost:5557/health

# Generate test request
curl http://localhost:5556/test
```

---

### 1:00 - 2:30 | Load Proof & Performance Gate

**Talking Points:**
- "We use k6 load tests with hard thresholds - the pipeline automatically fails if SLAs are breached."
- "Every build includes synthetic trace injection for end-to-end verification."

**Actions:**
1. **Show CI Perf Report** (if available)
   - Open `.github/workflows/perf-gate-demo.yml` results
   - Highlight: Thresholds met (p95 <300ms), Green badge
   - Point to: Trace-linked results (trace IDs correlated)

2. **Run Canary Test** (Data Room)
   - Click "Run Once" on **Canary Test**
   - Show action log: "Canary test complete - check SigNoz for trace"

3. **Verify in SigNoz**
   - Navigate to SigNoz Traces tab
   - Filter: `service.name = "bosscat-svc2-api"`
   - Show: Recent canary trace with full span hierarchy
   - Drill into: Request → svc2 → svc3 → response

**Expected State:**
- Canary trace visible in SigNoz (≤5s latency)
- Span tree shows: incoming HTTP → HttpClient outgoing → worker processing
- Logs correlated with trace_id

**SigNoz Queries (Reference):**
```
# Traces
service.name = "bosscat-svc2-api" AND demo.phase = "phase1"

# Logs with correlation
message contains "demo" AND trace_id exists

# Metrics
p95(duration) by (service.name)
```

---

### 2:30 - 4:30 | Chaos Drill & Resilience

**Talking Points:**
- "Real-world systems face faults. Our Data Room lets us inject chaos to prove resilience."
- "Watch how the system detects degradation, alerts, and provides drill-down visibility."

**Actions:**
1. **Inject Network Delay** (Data Room)
   - Click "Inject" on **Network Delay** scenario
   - Point out: Chaos warning banner appears
   - Watch metrics: P95 jumps to ~550ms (red)

2. **Show Alert Firing** (if configured)
   - Check SigNoz Alerts tab
   - Or show console: "Latency threshold breached: p95=550ms >300ms target"

3. **Drill Down in SigNoz**
   - Navigate to Traces tab
   - Filter for slow traces: `duration > 500ms`
   - Open a slow trace, show span duration breakdown
   - Point out: Network delay visible in HttpClient span

4. **Optional: "Explain This Trace"** (Phase 3 feature)
   - If Bedrock integrated: Click "Explain" button
   - AI summary: "Network latency spike detected between svc2 and svc3. Outgoing HttpClient span shows 500ms delay..."

**Expected State:**
- Metrics: P95 ~550ms (RED), Error 0%, RPS 10
- Chaos indicator: Active
- Traces show latency spike
- (Optional) Alert fired

**Manual Trace Inspection:**
```
Open SigNoz → Traces → Filter: duration > 500ms
Trace structure:
├─ GET /test (total: 550ms)
   ├─ ASP.NET Core server (10ms)
   ├─ HttpClient outgoing (520ms) ← BOTTLENECK
   └─ svc3-worker processing (15ms)
```

---

### 4:30 - 5:30 | Recovery & ECRR Evidence

**Talking Points:**
- "When issues occur, we follow ECRR: Evidence → Contain → Rollback → Report."
- "Watch the system return to healthy state with full evidence capture."

**Actions:**
1. **Clear Chaos** (Data Room)
   - Click "Clear" on **Network Delay** scenario
   - Show: Chaos warning disappears
   - Watch metrics: P95 returns to ~112ms (green)

2. **Show ECRR Evidence** (Terminal)
   ```powershell
   # Show action log from Data Room
   # Point to timestamps and state transitions
   ```

3. **Verify Recovery in SigNoz**
   - Navigate to Services tab
   - Show: Error rate 0%, Latency normalized
   - Open recent trace: Back to fast response times

**Expected State:**
- Metrics: P95 ~112ms (GREEN), Error 0%, RPS 10
- All chaos cleared
- System stable

---

### 5:30 - 7:00 | Safety Proof & Governance

**Talking Points:**
- "Every change follows disciplined agent workflows with budgets and evidence trails."
- "No silent merges, no runaway automation - full auditability."

**Actions:**
1. **Show BOSSCAT_LOG**
   ```powershell
   # Open docs/BossCat/BOSSCAT_LOG.md
   # Highlight recent entries:
   # - Budget compliance (≤200 LOC per job)
   # - Lane discipline (docs lane only)
   # - Gate approvals (BossCat OEM signed)
   ```

2. **Show Agent Artifacts**
   ```powershell
   # Navigate to .agent/ directory
   dir .agent\
   
   # Show: PLAN.md, EVIDENCE.log, preflight checks
   # Point out: No JOB.lock (clean state)
   ```

3. **Explain A/B Agent Pattern**
   - "Agent A writes code under strict budgets"
   - "Agent B monitors and verifies - never writes"
   - "BossCat OEM approves at gates using `@cat ready-for-gate` signal"

4. **Show Gate Protocol** (Optional)
   ```powershell
   # Open docs/comfort-cat/GATE_PROTOCOL.md
   # Highlight:
   # - Evidence requirements
   # - Pass/fail criteria  
   # - No merges by bots rule
   ```

**Expected State:**
- BOSSCAT_LOG shows complete audit trail
- Evidence artifacts present and timestamped
- No active locks
- Budget compliance verified

---

## Post-Demo Q&A Paths

### "Show me a specific trace"
1. SigNoz → Traces → Pick any recent trace
2. Expand span tree
3. Show attributes: service.name, trace_id, http.method, etc.
4. Navigate to Logs tab → Filter by trace_id → Show correlated logs

### "What if the database is slow?"
1. Data Room → Start **CPU Throttle** chaos
2. Show P95 increases
3. Navigate to specific slow trace
4. Point out: Processing span duration increased

### "How do you verify performance regressions?"
1. Show `.github/workflows/perf-gate-demo.yml`
2. Point to k6 thresholds: `p95 < 300ms`, `errors < 1%`
3. Explain: Pipeline fails on breach, blocks promotion

### "What about production incidents?"
1. Show `docs/CANARY_INCIDENT_TEMPLATE.md`
2. Explain: Standardized format
3. Point to ECRR artifacts captured during chaos drill

### "How do you control the AI agents?"
1. Show `.agent/PLAN.md` (current plan)
2. Show `docs/comfort-cat/ROLES.md` (authority hierarchy)
3. Explain: Budgets (≤200 LOC/job), Lanes (docs only), Single-writer lock

---

## Fallback Screenshots (Pre-captured)

Store in `artifacts/demo/screenshots/`:
- `01-healthy-dashboard.png` - Green baseline metrics
- `02-data-room-active.png` - Traffic scenarios running
- `03-signoz-trace-detail.png` - Full span tree with attributes
- `04-chaos-active.png` - Network delay metrics (red)
- `05-slow-trace-drilldown.png` - Bottleneck span highlighted
- `06-bosscat-log.png` - Audit trail excerpt
- `07-agent-artifacts.png` - Evidence files

---

## Troubleshooting (Quick Fixes)

### Services not responding
```powershell
# Check processes
Get-Process dotnet | Select-Object Id, ProcessName, CPU

# Restart if needed
# Ctrl+C in service terminals, rerun deploy-demo-service.ps1
```

### SigNoz not showing traces
```powershell
# Check collector
sc query otelcol-contrib

# Verify endpoint
curl http://localhost:14317
# Should connect (even if no response body)

# Check service env
# Ensure OTEL_EXPORTER_OTLP_ENDPOINT = http://127.0.0.1:14317
```

### Data Room not loading
```powershell
# Verify file exists
Test-Path C:\otel\docs\demo\data-room.html

# Open directly
start C:\otel\docs\demo\data-room.html
```

### Metrics stuck at 0
- Refresh Data Room page
- Verify Laminar Flow is running (green status badge)
- Check browser console for errors (F12)

---

## Success Metrics Checklist

Before demo:
- [ ] All 15 containers operational (docker ps)
- [ ] SigNoz health: {"status":"ok"}
- [ ] Both services responding on 5556/5557
- [ ] Telemetry verification: All GREEN
- [ ] Data Room loads and buttons work
- [ ] SigNoz shows recent traces (≤5min old)
- [ ] BOSSCAT_LOG has recent entries
- [ ] No .agent/JOB.lock present

After demo:
- [ ] Laminar flow stopped
- [ ] All chaos scenarios cleared
- [ ] Metrics returned to baseline
- [ ] Q&A questions answered with live evidence
- [ ] Evidence bundle captured (if requested)

---

**Authority:** BossCat OEM  
**Version:** Phase 1.0  
**Last Updated:** 2025-10-28

🐾 Ready for investor demonstration

