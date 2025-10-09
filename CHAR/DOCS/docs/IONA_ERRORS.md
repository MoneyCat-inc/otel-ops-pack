# IONA Errors & Root Cause Analysis

**Maintained By:** BossCat Investigator Agent 🕵️  
**Last Updated:** 2025-10-07  
**Status:** Active Error Tracking

---

## Current Gate Blocker Investigation

**Gate Decision:** HOLD (25% readiness)  
**Investigation Date:** 2025-10-07 16:00-16:15 UTC

### Error #1: OTel Wiring Verification Failed

**Symptom:**
```
[FAIL] Service otelcol-contrib status is Stopped
[FAIL] Windows collector (OTLP/HTTP) port 5318 not reachable
```

**Evidence Location:**
- `artifacts/wiring-investigation.log`
- `artifacts/diagnostic-20251007-160340/diagnostic-results.json:23`

**Root Cause Analysis:**

#### Hypothesis A: Service Deliberately Disabled (CONFIRMED ✅)
**Evidence:**
- Service status: `Stopped`
- Start type: `Disabled`
- Last check: 2025-10-07 16:05 UTC

**Root Cause:** The Windows OTel Collector service (`otelcol-contrib`) is set to `Disabled` start type, preventing automatic startup.

**Impact:**
- No telemetry collection from Windows sources
- OTLP endpoints (5318 HTTP, 5317 gRPC) unreachable
- Breaks local → SigNoz telemetry pipeline
- IONA agent telemetry cannot reach SigNoz via local collector

**Resolution Path:**
1. Enable service: `Set-Service otelcol-contrib -StartupType Automatic`
2. Start service: `Start-Service otelcol-contrib`
3. Verify endpoints: `Test-NetConnection localhost -Port 5318`
4. Re-verify wiring: `pwsh -File scripts/verify-wiring.ps1`

---

#### Hypothesis B: Port Conflict (PENDING VALIDATION)
**Evidence:** Port 5318 not reachable even if service were running

**Investigation Needed:**
```powershell
# Check if another process is using ports
Get-NetTCPConnection -LocalPort 5318 -ErrorAction SilentlyContinue
Get-NetTCPConnection -LocalPort 5317 -ErrorAction SilentlyContinue
```

**Status:** Will validate after service start

---

### Error #2: Enterprise Readiness Below Threshold

**Symptom:**
```
Enterprise readiness: 50% (NOT READY)
Target: ≥75%
```

**Evidence Location:**
- `artifacts/diagnostic-20251007-160340/diagnostic-results.json:22`
- `artifacts/diagnostic-20251007-160340/enterprise-readiness.log`

**Root Cause Analysis:**

#### Hypothesis A: Cascading Failure from Collector Service (LIKELY)
**Reasoning:**
- Multiple checks in enterprise readiness depend on collector
- Dashboard exports may be failing without telemetry
- Workflow runs may be affected

**Evidence Needed:**
```powershell
# Re-run enterprise readiness after collector fix
pwsh -File scripts/enterprise-readiness-check.ps1 > artifacts/enterprise-post-fix.log

# Compare before/after scores
```

**Expected Outcome:** Score should improve to 75%+ after collector restoration

---

#### Hypothesis B: Dashboard Export Staleness (SECONDARY)
**Evidence:** Dashboard snapshots may not be current

**Investigation:**
```powershell
# Check recent snapshot dates
Get-ChildItem docs/observability/snapshots/* -Directory | 
    Sort-Object -Descending | 
    Select-Object -First 7 | 
    Select-Object Name, LastWriteTime
```

**Resolution:** Automated nightly export should resolve

---

### Error #3: Agent Health Degraded

**Symptom:**
```
Agent health check has warnings
Status: degraded
```

**Evidence Location:**
- `artifacts/diagnostic-20251007-160340/ecrr-diagnostic-report.md:14`
- `artifacts/diagnostic-20251007-160340/agent-doctor.log`

**Root Cause Analysis:**

#### Hypothesis A: Agent State Files Stale or Corrupt (POSSIBLE)
**Investigation Needed:**
```powershell
# Check agent state
cat .agent/status.json

# Check agent lock
Test-Path .agent/LOCK

# Run agent doctor for detailed output
pnpm agent:doctor
```

**Resolution:** May need agent configuration refresh

---

#### Hypothesis B: OTel SDK Initialization Failing (POSSIBLE)
**Evidence:** Agent uses `scripts/agent/otel.ts` for telemetry

**Investigation:**
```powershell
# Check if OTEL_EXPORTER_OTLP_ENDPOINT is set
$env:OTEL_EXPORTER_OTLP_ENDPOINT

# Should be: http://localhost:4318 or http://localhost:5318
```

**Expected:** Agent health will improve after collector is running

---

### Error #4: Analytics API Unreachable

**Symptom:**
```
[FAIL] Analytics API not reachable (is dev server running on port 3003?)
```

**Evidence Location:**
- `artifacts/wiring-investigation.log`

**Root Cause Analysis:**

#### Hypothesis A: Dev Server Not Running (EXPECTED)
**Reasoning:** This is a development-time service, not required for gate passage

**Classification:** 🟡 **WARNING** (not a blocker)

**Impact:** 
- Cannot test full analytics event flow
- End-to-end trace validation limited
- Does not block gate passage

**Resolution:** Start dev server when testing full pipeline
```powershell
# Optional: Start Resonai dev server
cd third_party/resonai
pnpm dev
```

**Gate Impact:** NONE (not a blocker for gate readiness)

---

## SigNoz Collector Status (HEALTHY ✅)

**Service:** `signoz-otel-collector` (Docker container)  
**Status:** Running  
**Version:** dev (v0.129.6)

**Log Analysis:**
- ✅ Collector operational
- ⚠️  Prometheus scrape warnings (expected - trying to scrape Windows collector)
- ✅ ClickHouse exporter working
- ✅ Trace ingestion pipeline healthy

**Conclusion:** SigNoz backend is healthy; issue is Windows collector → SigNoz connectivity

---

## Resolution Priority Matrix

| Error | Priority | Blocker? | Est. Time | Impact on Gate |
|-------|----------|----------|-----------|----------------|
| **#1: Collector Service Stopped** | 🔴 **P0** | YES | 5 min | +25% (1/4 → 2/4) |
| **#2: Enterprise Readiness Low** | 🔴 **P0** | YES | 10 min | +25% (2/4 → 3/4) |
| **#3: Agent Health Degraded** | 🟡 **P1** | NO (warning) | 5 min | +0% (side effect fix) |
| **#4: Analytics API Down** | 🟢 **P2** | NO | N/A | 0% (not required) |

**Critical Path:** Fix #1 → Re-test #2 → Address #3 → Re-run gate diagnostic

---

## Next Actions (Gap-Closer Agent 🩹)

### Phase 1: Restore Collector Service (5 minutes)
```powershell
# Enable and start service
Set-Service otelcol-contrib -StartupType Automatic
Start-Service otelcol-contrib

# Verify service
Get-Service otelcol-contrib | Select-Object Name, Status, StartType

# Verify ports
Test-NetConnection localhost -Port 5318
Test-NetConnection localhost -Port 5317
```

**Expected Result:** Service running, ports reachable

---

### Phase 2: Validate OTLP Endpoints (2 minutes)
```powershell
# Test HTTP endpoint
Invoke-WebRequest -Uri "http://localhost:5318" -Method Head -TimeoutSec 3

# Re-verify wiring
pwsh -File scripts/verify-wiring.ps1

# Capture success evidence
pwsh -File scripts/verify-wiring.ps1 | Tee-Object -FilePath artifacts/wiring-post-fix.log
```

**Expected Result:** Wiring verification PASSED

---

### Phase 3: Re-Run Enterprise Readiness (3 minutes)
```powershell
# Full enterprise check
pwsh -File scripts/enterprise-readiness-check.ps1 | Tee-Object -FilePath artifacts/enterprise-post-fix.log

# Check score improvement
# Target: ≥75% (ideally 90%+)
```

**Expected Result:** Enterprise readiness ≥ 75%

---

### Phase 4: Validate Agent Health (2 minutes)
```powershell
# Run agent doctor
pnpm agent:doctor | Tee-Object -FilePath artifacts/agent-post-fix.log

# Check for green status
```

**Expected Result:** Agent health = healthy (or acceptable warnings only)

---

### Phase 5: Gate Re-Assessment (3 minutes)
```powershell
# Full gate diagnostic with ECRR
pwsh -File scripts/diagnostic-shell-enhanced.ps1 -Mode gate -GenerateECRR

# Expected: Gate readiness ≥ 90%
# Expected: Status = ready or near_ready

# View report
cat artifacts/diagnostic-*/ecrr-diagnostic-report.md
```

**Expected Result:** Gate READY ✅

---

## Investigation Conclusion

**Root Causes Identified:**
1. ✅ Windows OTel Collector service disabled and stopped
2. ✅ Cascading failures in enterprise readiness checks
3. ⚠️  Agent health degraded (likely side effect)
4. ℹ️  Analytics API down (not a blocker)

**Confidence Level:** 🟢 **HIGH**

**Resolution Time Estimate:** 15-20 minutes total

**Gate Readiness Prediction:**
- Current: 25% (1/4 checks)
- After fixes: 90-100% (3.5-4/4 checks)
- Status: HOLD → READY ✅

---

**Next Agent:** Gap-Closer 🩹 (Execute resolution plan)

---

**Investigator Sign-Off:**  
🕵️ BossCat Investigator Agent  
**Date:** 2025-10-07 16:15 UTC  
**Evidence Package:** `artifacts/wiring-investigation.log`, service status, collector logs  
**Recommendation:** PROCEED with Gap-Closer remediation plan

## Gate Verification Findings (2025-10-09)

**Investigation Date:** 2025-10-09  
**Source:** Local BossCat verification run (post-tetragram-1.2)  
**Commit:** bf76f9b

### Current Anomalies

- **SigNoz UI/API unreachable** on `http://localhost:8080` (timeout). OTLP ports 5317/5318 not reachable.
- **Windows Collector service** `otelcol-contrib` present but Stopped.
- **Guardrails violations**: 2 unauthorized top-level directories: `gpu-buffers/`, `sidecars/`.
- **Script dependency** `BRAV/SCPT/quick-monitor.ps1` depends on missing `scripts/progress-indicators.ps1`.

### Suggested Remediations

- Start Windows Collector: `sc start otelcol-contrib`.
- Ensure SigNoz UI/API containers are running (port 8080 open).
- Fix script path references to use `BRAV\SCPT\progress-indicators.ps1`.
- Remove unauthorized directories (`gpu-buffers/`, `sidecars/`).

### Evidence

- `CHAR/ECRR/ECRR_REPORTS/ECRR_GATE_VERIFY_2025-10-09.md`
- Local verification artifacts

**Status:** Remediation in progress

---

*🐾 Updated: 2025-10-09*
