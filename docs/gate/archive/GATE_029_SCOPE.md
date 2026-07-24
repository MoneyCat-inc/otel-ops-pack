# Gate #029 — Single-Track Orchestration & Collector Path (5317)

**Gate ID:** #029  
**Title:** Deployment Orchestrator + Collector Path Verification  
**Date:** 2025-10-27  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Tracks:** 1 (Single-Track: Orchestration + 5317 Path Verification)

---

## 🎯 Objectives

### Single Track: Deployment Orchestrator + Collector Path Verification

**Goal:** Create a Windows/.NET deployment orchestrator with structured lifecycle management, deploy 2 test services, and verify the Windows OTel Collector path (port 5317) end-to-end.

---

## 📋 Success Criteria

### 1. Deployment Orchestrator (Windows/.NET)

**Must implement:**
- ✅ **Build/Verify Checks:**
  - Path validation (binaries, configs exist)
  - Binary verification (checksums, signatures if available)
  - Dependency checks (runtime, required ports)

- ✅ **Port Scanner & Bind Checks:**
  - Scan target ports before deployment
  - Verify ports are available or identify conflicts
  - Report which process holds conflicting ports

- ✅ **Process Lifecycle:**
  - Start → Health Check → Monitor → Stop
  - Bounded retries with exponential backoff
  - Configurable timeouts per phase
  - Graceful shutdown on failure

- ✅ **Structured Logs & Exit Codes:**
  - JSON-structured logs with timestamps
  - Exit codes: 0 (GREEN), 1 (AMBER), 2 (RED)
  - Clear error messages with remediation hints

### 2. Deploy 2 Services

**Services to deploy:**
1. **`bosscat-svc2-api`** (port 5556)
   - HTTP API service
   - Health endpoint: `GET /health`
   - Expected: HTTP 200 with JSON status

2. **`bosscat-svc3-worker`** (port 5557)
   - Worker/background service
   - Health endpoint: `GET /health` or heartbeat mechanism
   - Expected: HTTP 200 or periodic log output

**Deployment verification:**
- Both services start successfully
- Health checks return 200 (or expected response)
- Services can be stopped cleanly
- Logs captured during lifecycle

### 3. Collector Path 5317 Verification

**Route configuration:**
- One service sends to `http://127.0.0.1:5317` (Windows Collector)
- Collector forwards to SigNoz at port 14317
- Generate traffic to trigger trace/metric export

**Verification:**
- ✅ Spans reach SigNoz via Collector
- ✅ Metrics: `accepted_spans ≈ sent_spans` (within 5% tolerance)
- ✅ Service appears in SigNoz with correct service.name
- ✅ Screenshots captured showing traces in SigNoz

### 4. Telemetry & Overhead

**Capture for both services:**
- ✅ Traces visible in SigNoz
- ✅ Metrics visible in SigNoz
- ✅ Logs captured (file or event log)

**Overhead measurement:**
- ✅ Baseline: Run without instrumentation, measure latency
- ✅ Instrumented: Run with OTel, measure latency
- ✅ Overhead: `(instrumented - baseline) / baseline * 100%`
- ✅ Target: < 5% overhead
- ✅ Method + raw numbers archived in evidence

---

## 🛠️ Implementation Plan

### Phase 1: Orchestrator Script (Core)

**Script:** `scripts/windows/deploy-dotnet-service.ps1`

**Features:**
- Service deployment with lifecycle management
- Port conflict detection
- Health check validation
- Structured logging
- Exit code handling

**Inputs:**
- Service name
- Port number
- Binary path
- Health check URL
- Timeout configuration

**Outputs:**
- Deployment success/failure (exit code)
- Structured JSON logs
- Service PID (if started successfully)

### Phase 2: Multi-Service Orchestrator

**Script:** `scripts/windows/orchestrate-two-services.ps1`

**Features:**
- Deploy multiple services sequentially
- Coordinate health checks
- Aggregate status reporting
- Rollback on failure (stop all services)

**Services:**
1. `bosscat-svc2-api` (5556)
2. `bosscat-svc3-worker` (5557)

### Phase 3: Collector Path Verification

**Script:** `scripts/windows/health-check-otlp.ps1`

**Features:**
- Verify port 5317 listening
- Send synthetic trace to Collector
- Query SigNoz for trace arrival
- Calculate accepted_spans / sent_spans ratio
- Screenshot automation (if feasible)

### Phase 4: Overhead Measurement

**Script:** `scripts/windows/measure-overhead.ps1`

**Features:**
- Run service baseline (no OTel)
- Run service instrumented (with OTel)
- Compare latency (p50, p95, p99)
- Calculate overhead percentage
- Generate report with raw data

---

## 📦 Budget & Constraints

### Budget
- **Files:** ≤ 10 files
- **LOC:** ≤ 500 LOC total
- **Lanes:** DOCS + scripts/windows
- **Evidence:** artifacts/gate029/

### Constraints
- ✅ ECRR methodology required
- ✅ Budget compliance mandatory
- ✅ Never merge to trunk autonomously
- ✅ BossCat OEM approval required

---

## 📁 File Structure

### Scripts (scripts/windows/)
1. `deploy-dotnet-service.ps1` — Single service deployment
2. `orchestrate-two-services.ps1` — Multi-service coordinator
3. `health-check-otlp.ps1` — Collector path verification
4. `measure-overhead.ps1` — Performance measurement

### Services (to create or reference)
- `bosscat-svc2-api/` — HTTP API service
- `bosscat-svc3-worker/` — Worker service

### Evidence (artifacts/gate029/)
- `deployment-log.json` — Structured deployment logs
- `health-checks.json` — Health check results
- `collector-verification.json` — 5317 path metrics
- `overhead-report.json` — Performance comparison
- `*.png` — SigNoz screenshots

### Documentation
- `GATE_029_SCOPE.md` — This document
- `GATE_029_IMPLEMENTATION.md` — Implementation summary
- `GATE_029_EVIDENCE.md` — Evidence bundle

---

## ✅ Acceptance Checklist

### Orchestrator
- [ ] Runs idempotently (start → verify → stop)
- [ ] Bounded retry with exponential backoff
- [ ] Port conflict detection working
- [ ] Health checks validate services
- [ ] Structured logs generated
- [ ] Exit codes correct (0=GREEN, 1=AMBER, 2=RED)

### Services
- [ ] Both services deployed successfully
- [ ] Health checks pass (HTTP 200 or equivalent)
- [ ] Services can be stopped cleanly
- [ ] Logs captured

### Collector Path (5317)
- [ ] One service routes via Collector (5317)
- [ ] Traces visible in SigNoz
- [ ] `accepted_spans ≈ sent_spans` (within 5%)
- [ ] Screenshots captured

### Overhead
- [ ] Baseline measurement captured
- [ ] Instrumented measurement captured
- [ ] Overhead < 5%
- [ ] Method + raw numbers archived

### Documentation
- [ ] ECRR report generated
- [ ] Dashboard updated with Gate #029 entry
- [ ] Evidence bundle complete
- [ ] Tag: `gate-029-green-2025-10-27` (or AMBER)

---

## 🔒 Guardrails

### ECRR Compliance
- **Examine:** Capture current state before changes
- **Clean:** Deploy orchestrator + services
- **Report:** Generate evidence with metrics
- **Role:** Cursor{Implementer} under BossCat OEM authority

### Budget Tracking
| Component | Files | LOC | Status |
|-----------|-------|-----|--------|
| Orchestrator | 2-3 | ≤200 | Pending |
| Health checks | 1-2 | ≤100 | Pending |
| Services | 2 | ≤100 | Pending |
| Evidence | 3-4 | ≤100 | Pending |
| **Total** | **≤10** | **≤500** | **Within limits** |

### Roles
- **A (ALFA):** Cursor{Implementer} — Writer
- **B (BETA):** BossCat OEM — Monitor/Review
- **Two-person guard:** External merge authority required

---

## 🚀 Execution Sequence

### Step 1: Create Orchestrator (30-40 min)
```powershell
# Create deployment orchestrator
scripts/windows/deploy-dotnet-service.ps1

# Features: port scanning, health checks, lifecycle management
```

### Step 2: Create Services (20-30 min)
```csharp
// bosscat-svc2-api: Simple HTTP API
// bosscat-svc3-worker: Background worker with health endpoint
```

### Step 3: Orchestrate Deployment (15-20 min)
```powershell
# Deploy both services
scripts/windows/orchestrate-two-services.ps1

# Verify health checks pass
```

### Step 4: Verify Collector Path (15-20 min)
```powershell
# Configure one service to use Collector (5317)
# Generate traffic
# Verify in SigNoz
scripts/windows/health-check-otlp.ps1
```

### Step 5: Measure Overhead (15-20 min)
```powershell
# Baseline vs instrumented
scripts/windows/measure-overhead.ps1

# Generate report
```

### Step 6: Evidence Collection (10-15 min)
- Capture SigNoz screenshots
- Export metrics
- Generate ECRR report
- Update dashboard

---

## 📊 Evidence Requirements

### Screenshots
- [ ] SigNoz: Service visible via Collector (5317)
- [ ] SigNoz: Traces from service
- [ ] SigNoz: Metrics dashboard
- [ ] Deployment orchestrator output
- [ ] Health check results

### Metrics
- [ ] accepted_spans / sent_spans ratio
- [ ] Service latency (baseline)
- [ ] Service latency (instrumented)
- [ ] Overhead percentage
- [ ] Deployment success rate

### Logs
- [ ] Deployment log (JSON structured)
- [ ] Service startup logs
- [ ] Health check logs
- [ ] Collector verification logs

---

## ⚠️ Risk Mitigation

### Risk: Port Conflicts
**Mitigation:** Orchestrator scans ports before deployment, reports conflicts

### Risk: Service Startup Failures
**Mitigation:** Bounded retries with exponential backoff, clear error messages

### Risk: Collector Path Not Working
**Mitigation:** Health check script verifies end-to-end before declaring success

### Risk: Overhead > 5%
**Mitigation:** Measure and report actual overhead, adjust if needed

---

## ✅ Gate Completion Criteria

**Gate #029 is complete when:**
1. ✅ Orchestrator runs idempotently with bounded retry
2. ✅ Both services deploy and pass health checks
3. ✅ Collector path (5317) verified end-to-end in SigNoz
4. ✅ Overhead measured and < 5%
5. ✅ Evidence package complete (screenshots + metrics + logs)
6. ✅ ECRR report generated
7. ✅ Dashboard updated
8. ✅ BossCat OEM reviews and approves
9. ✅ Tag: `gate-029-green-2025-10-27` (or AMBER if partial)

---

**Scope Defined:** 2025-10-27  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM (Fubumaki)  
**Status:** ✅ **APPROVED — Ready to Execute**

**Call-sign:** @cat ready-for-gate : 029-ORCH-DEPLOY

**Seal:** 🐾 **Gate #029 Scope Document**
