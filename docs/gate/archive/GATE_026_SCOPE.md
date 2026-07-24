# Gate #026 — Scope & Objectives

**Gate ID:** #026  
**Title:** .NET Auto-Instrumentation + CI Performance Gates + ICF Telemetry  
**Date:** 2025-10-27  
**Authority:** BossCat OEM (Fubumaki)  
**Executor:** Cursor{Implementer}  
**Tracks:** 3 (A: .NET OTel, B: k6 CI Gates, C: ICF Telemetry)

---

## 🎯 Objectives

### Track A — .NET Auto-Instrumentation (Windows Host)

**Goal:** Enable zero-code OpenTelemetry for at least one production-relevant .NET workload on Windows; verify traces + metrics + log correlation end-to-end in SigNoz.

**Success Criteria:**
- ✅ **Spans:** Incoming HTTP (ASP.NET/Core) + outbound HttpClient spans visible with correct `service.name` and resource attributes
- ✅ **Metrics:** Request duration/count + .NET runtime/process metrics present
- ✅ **Logs:** If app uses Microsoft.Extensions.Logging or log4net, confirm trace-context log correlation
- ✅ **Overhead:** ≤5-10% impact measured in typical paths (before/after micro-check)

**Budget:** ≤10 files, ≤200 LOC

---

### Track B — CI Performance Gates (k6)

**Goal:** Add blocking load-test step to CI that fails on threshold breach; archive artifacts.

**Success Criteria:**
- ✅ k6 job runs against staging/ephemeral env and **fails pipeline on threshold breach** via exit code
- ✅ Thresholds set: `p(50) ≤ 900ms`, `p(95) ≤ 1200ms`, `error_rate < 1%` on key API/path
- ✅ Artifacts: JSON results + Grafana/SigNoz screenshots archived per run

**Budget:** ≤10 files, ≤200 LOC

---

### Track C — ICF Telemetry Hooks

**Goal:** Make convergence visible and auditable.

**Success Criteria:**
- ✅ **Convergence Index** + **Last 5 Improvement Actions** render on status/dashboard and in ECRR report appendix
- ✅ B-agent read-only review stays intact; budgets and two-person guard respected

**Budget:** ≤10 files, ≤200 LOC

---

## 🛠️ Implementation Strategy

### Track A: .NET Auto-Instrumentation

**Phase 1: Install & Configure**
1. Install OpenTelemetry .NET Auto-Instrumentation (PowerShell module)
2. Configure environment variables for target Windows service:
   - `CORECLR_ENABLE_PROFILING=1`
   - `CORECLR_PROFILER={918728DD-259F-4A6A-AC2B-B85E1B658318}`
   - `CORECLR_PROFILER_PATH`, `DOTNET_STARTUP_HOOKS`, `OTEL_DOTNET_AUTO_HOME`
   - `OTEL_SERVICE_NAME`, `OTEL_TRACES_EXPORTER=otlp`
   - `OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:14317`
3. Restart service

**Phase 2: Verify Coverage**
1. Test incoming HTTP route + outbound HttpClient call
2. Confirm spans appear in SigNoz
3. Verify ASP.NET/Core metrics (request duration/count)
4. Verify runtime/process metrics
5. Test log-trace correlation (if ILogger/log4net present)

**Phase 3: Measure Overhead**
1. Run steady-load test **before** agent enablement (baseline)
2. Enable agent and restart
3. Run same test **after** enablement
4. Record RPS/latency deltas (target: ≤5-10% overhead)

---

### Track B: k6 CI Performance Gates

**Phase 1: Design k6 Script**
1. Create k6 load test script with thresholds:
   ```javascript
   export const options = {
     thresholds: {
       http_req_failed: ['rate<0.01'],
       http_req_duration: ['p(50)<900', 'p(95)<1200']
     }
   };
   ```
2. Target key API endpoint (e.g., health check, primary route)

**Phase 2: GitHub Actions Integration**
1. Add k6 job to CI workflow
2. Configure threshold-based failure (k6 exits non-zero on breach)
3. Archive k6 JSON output as artifact
4. Capture SigNoz/Grafana screenshots

**Phase 3: Synthetic Trace Gate**
1. Before k6 load test, inject synthetic trace
2. Verify trace appears in SigNoz (observability gate)
3. If trace missing, fail before k6 runs

---

### Track C: ICF Telemetry Hooks

**Phase 1: Design Analyzer**
1. Create `scripts/icf/analyze-convergence.ps1` (or .ts)
2. Scan BOSSCAT_LOG.md + ECRR artifacts
3. Compute **Convergence Index** (e.g., trend of retries, drift, performance deltas)
4. Extract **Last 5 Improvement Actions**

**Phase 2: Dashboard Integration**
1. Update status dashboard with ICF section
2. Render Convergence Index + Recent Lessons Applied
3. Attach roll-up to ECRR report footer

**Phase 3: Guardrails**
1. Maintain A/B roles (writer/monitor)
2. Respect budgets (≤10 files, ≤200 LOC)
3. Keep kill-switch and two-person guard intact

---

## 📦 Evidence Requirements

### Per Track
- **Track A:**
  - SigNoz screenshots (traces, metrics, logs with correlation)
  - Overhead measurement (before/after)
  - Service configuration documentation
  - Verification test results

- **Track B:**
  - k6 script with thresholds
  - GitHub Actions workflow file
  - k6 JSON output (archived)
  - SigNoz/Grafana screenshots
  - CI run showing threshold failure (if triggered)

- **Track C:**
  - ICF analyzer script
  - Convergence Index calculation logic
  - Dashboard screenshot with ICF section
  - ECRR report with ICF appendix

### Overall
- `.agent/GATE_026_EVIDENCE.log` — Complete execution log
- `GATE_026_SCOPE.md` — This document
- ECRR report with all three tracks
- BossCat log one-liner
- Git tag: `gate-026-green-<YYYY-MM-DD>`

---

## 🔒 Lanes & Budgets

### Lane Allocation
- **DOCS lane:** Runbook/UI changes (Track C dashboard updates)
- **SSOT lane:** Artifacts and evidence
- **ICF lane:** Analyzer script (Track C)
- **CI lane:** GitHub Actions workflows (Track B)

### Budget Tracking
| Track | Files | LOC | Status |
|-------|-------|-----|--------|
| Track A | ≤10 | ≤200 | Pending |
| Track B | ≤10 | ≤200 | Pending |
| Track C | ≤10 | ≤200 | Pending |
| **Total** | **≤30** | **≤600** | **Within limits** |

### Roles
- **A (ALFA):** Writer — Implements changes
- **B (BETA):** Monitor — Reviews changes, read-only
- **Two-person guard:** Respected (external merge authority)

---

## 🚀 Execution Sequence

### Recommended Order
1. **Track A First** — Enable .NET agent, verify telemetry (foundational)
2. **Track B Second** — Wire CI gates with k6 (builds on Track A validation)
3. **Track C Third** — ICF surfacing (analysis of overall convergence)

### Milestones
- [ ] Track A: .NET agent enabled, spans+metrics+logs verified, overhead measured
- [ ] Track B: k6 CI job added, thresholds enforced, artifacts archived
- [ ] Track C: ICF analyzer created, dashboard updated, convergence visible
- [ ] Evidence: Complete package generated per ECRR
- [ ] Review: Submit to BossCat OEM for approval
- [ ] Tag: `gate-026-green-<date>` on approval

---

## ⚠️ Risk Mitigation

### Track A Risks
- **Risk:** Agent overhead exceeds 10%
- **Mitigation:** Disable specific instrumentations if needed (configurable via env vars)
- **Rollback:** Remove profiler env vars, restart service

### Track B Risks
- **Risk:** Thresholds too aggressive, blocking valid changes
- **Mitigation:** Start with generous thresholds (p50=900ms, p95=1200ms), tune based on baseline
- **Rollback:** Disable k6 job or adjust thresholds upward

### Track C Risks
- **Risk:** Convergence Index calculation complexity exceeds budget
- **Mitigation:** Keep analyzer simple (count retries, measure drift frequency)
- **Rollback:** Dashboard update is doc-only, easily reverted

---

## ✅ Gate Completion Criteria

**Gate #026 is complete when:**
1. All three tracks meet success criteria (verified via testing)
2. Evidence package is comprehensive (screenshots, metrics, logs, artifacts)
3. Budgets are respected (≤30 files, ≤600 LOC total)
4. ECRR report generated with all tracks documented
5. BossCat OEM reviews and approves
6. Git tag `gate-026-green-<date>` applied

**Target Date:** 2025-10-27 (complete within 24 hours)

---

**Scope Defined:** 2025-10-27 01:30:00 UTC  
**Executor:** Cursor{Implementer}  
**Authority:** BossCat OEM (Fubumaki)  
**Status:** ✅ Ready to Execute

**Seal:** 🐾 **Gate #026 Scope Document**

