# Gate #026 — Verification Execution Guide

**Date:** 2025-10-27  
**Executor:** Cursor{Implementer} / BossCat OEM  
**Status:** Track C ✅ Complete | Tracks A & B ⏳ Pending

---

## ✅ Track C — ICF Telemetry (COMPLETE)

### Execution Results

**Script:** `scripts/icf/analyze-convergence.ps1`  
**Status:** ✅ Executed successfully  
**Date:** 2025-10-27 08:28:39

**Convergence Index:** 51.77% (NEEDS ATTENTION)

**Metrics:**
- Total Log Entries: 57
- GREEN Gates: 34
- AMBER Gates: 5
- Retry/Rework Events: 3
- Drift Detections: 11
- Performance Improvements: 2
- Success Rate: 64.15%
- Drift Rate: 19.3%

**Assessment:** "NEEDS ATTENTION - High retry/drift rate"

**Analysis:**
The 51.77% CI reflects recent system state:
- 19.3% drift rate is elevated due to Gate #025 reconciliation (documentation drift resolution)
- 64.15% success rate shows majority of gates are GREEN (34/53 total outcomes)
- System is converging post-reconciliation, expected to improve as gates stabilize

**Dashboard Update:** ✅ Complete
- ICF section inserted into `docs/GATE_STATUS_DASHBOARD.md` (line 29)
- Metrics visible with full breakdown
- ICF doctrine included

**Evidence:**
- ✅ `artifacts/icf/convergence-report.json` generated
- ✅ Dashboard screenshot location: `docs/GATE_STATUS_DASHBOARD.md` lines 29-61

---

## ⏳ Track A — .NET Auto-Instrumentation (PENDING)

### Prerequisites

1. **Windows OTel Collector** — Must be running
   ```powershell
   sc query otelcol-contrib
   # Should show: STATE: 4 RUNNING
   ```

2. **SigNoz** — Must be accessible
   ```powershell
   curl http://localhost:8080/api/v1/health
   # Should return: {"status":"ok"}
   ```

3. **Docker** — SigNoz stack operational
   ```powershell
   docker ps | findstr signoz
   # Should show: signoz-clickhouse, signoz, signoz-otel-collector
   ```

### Execution Steps

#### Step 1: Install .NET Auto-Instrumentation (5 min)

```powershell
cd C:\otel
.\scripts\gate026\install-dotnet-autoinstrumentation.ps1
```

**Expected Output:**
- ✅ Downloaded from GitHub (opentelemetry-dotnet-instrumentation)
- ✅ Extracted to `C:\otel\dotnet-autoinstrumentation`
- ✅ Profiler DLL verified
- ✅ Startup Hook DLL verified

**Evidence Needed:**
- [ ] Console screenshot showing successful installation

#### Step 2: Run Instrumented App (Terminal 1)

```powershell
cd C:\otel
.\scripts\gate026\run-dotnet-app-instrumented.ps1
```

**Expected Output:**
- ✅ OTel environment variables set
- ✅ Service: dotnet-test-gate026
- ✅ OTLP Endpoint: http://127.0.0.1:5317
- ✅ App listening on http://localhost:5555

**Keep this terminal running** for the duration of testing.

#### Step 3: Verify Telemetry (Terminal 2, simultaneous)

```powershell
cd C:\otel
.\scripts\gate026\verify-dotnet-instrumentation.ps1
```

**Expected Output:**
- ✅ App is running
- ✅ Root endpoint responded
- ✅ Outbound HttpClient call succeeded
- ✅ Spans found in SigNoz (count > 0)
- ✅ Performance: avg/p95 times displayed

**Evidence Needed:**
- [ ] Console screenshot showing verification results
- [ ] Span count from SigNoz

#### Step 4: Capture SigNoz Screenshots

**Open SigNoz UI:** http://localhost:8080

**Screenshot 1 — Traces:**
- Navigate to: http://localhost:8080/traces
- Filter: `service.name = dotnet-test-gate026`
- Find traces with:
  - Incoming span: `GET /`
  - Incoming span: `GET /test`
  - Outgoing span: `HTTP GET` (to SigNoz API)
- **Evidence:** Screenshot showing both incoming and outgoing spans

**Screenshot 2 — Service Metrics:**
- Navigate to: http://localhost:8080/services/dotnet-test-gate026/metrics
- Verify presence of:
  - `http.server.request.duration` (ASP.NET Core)
  - `http.client.request.duration` (HttpClient)
  - `.NET` runtime metrics (GC, thread pool, etc.)
- **Evidence:** Screenshot showing metrics panels

**Screenshot 3 — Logs (if available):**
- Navigate to: http://localhost:8080/logs
- Filter: `service.name = dotnet-test-gate026`
- Check for:
  - Log entries with trace correlation
  - `trace_id` field present
- **Evidence:** Screenshot showing logs with trace_id (if logs are being captured)

#### Step 5: Baseline Comparison (Overhead Measurement)

**Stop instrumented app** (Ctrl+C in Terminal 1)

```powershell
# Terminal 1: Run WITHOUT instrumentation
.\scripts\gate026\run-dotnet-app-instrumented.ps1 -Baseline
```

**Expected Output:**
- App runs without profiler/OTel
- No instrumentation overhead

```powershell
# Terminal 2: Re-run verification
.\scripts\gate026\verify-dotnet-instrumentation.ps1
```

**Compare Performance:**
- Baseline avg/p95 vs Instrumented avg/p95
- Calculate overhead: `((Instrumented - Baseline) / Baseline) * 100`
- **Target:** Overhead ≤ 5-10%

**Evidence Needed:**
- [ ] Console screenshot: Baseline performance
- [ ] Overhead calculation: X% (should be ≤10%)

---

## ⏳ Track B — k6 CI Performance Gate (PENDING)

### Prerequisites

1. **GitHub Repository Access** — Push/PR permissions
2. **.NET Test App** — Built and committed
3. **Workflow File** — `.github/workflows/gate-026-performance.yml` committed

### Execution Options

#### Option A: Manual Workflow Dispatch (Recommended)

1. Navigate to: `https://github.com/<org>/<repo>/actions/workflows/gate-026-performance.yml`
2. Click: **"Run workflow"** button
3. Select branch: `main` (or feature branch with Gate #026 changes)
4. Optional: Override `target_url` if needed
5. Click: **"Run workflow"** to trigger

**Monitor Run:**
- Watch build steps in real-time
- Verify synthetic trace injection passes
- Verify k6 test execution
- Check threshold results (should PASS if app is healthy)

#### Option B: Create Test PR

```powershell
# Create test branch
git checkout -b test/gate-026-verification
git push origin test/gate-026-verification

# Create PR via GitHub UI
# Workflow will trigger automatically on PR
```

#### Option C: Local k6 Test (Optional Pre-Check)

```powershell
# Ensure .NET test app is running on localhost:5555
cd C:\otel
k6 run scripts\gate026\k6-performance-gate.js --env TARGET_URL=http://localhost:5555
```

**Expected Output:**
- 10 VUs running for 30 seconds
- Thresholds displayed (p50, p95, error rate)
- Exit code 0 if thresholds pass
- Exit code non-zero if thresholds fail

### Evidence Collection

**Screenshot 1 — GitHub Actions Run (PASS):**
- Workflow execution page showing ✅ green checkmark
- All steps completed successfully
- Job summary visible

**Screenshot 2 — Job Summary:**
- Click "Summary" tab in workflow run
- Shows:
  - "Performance Gate: PASS"
  - "P50 <= 900ms ✅"
  - "P95 <= 1200ms ✅"
  - "Error rate < 1% ✅"

**Screenshot 3 — Synthetic Trace Injection Step:**
- Expand "Synthetic Trace Injection (Observability Gate)" step
- Shows: "✅ Synthetic traces injected"

**Screenshot 4 — k6 Results:**
- Expand "Run k6 Performance Test" step
- Shows k6 output with:
  - Request stats
  - Response times (p50, p95)
  - Threshold results

**Artifact Download:**
- Click "Artifacts" section
- Download: `k6-results-<run_number>.json`
- Save to: `artifacts/k6-results-gate026.json`

**Evidence Needed:**
- [ ] GitHub Actions run screenshot (PASS state)
- [ ] Job summary screenshot
- [ ] k6 console output screenshot
- [ ] k6-results JSON artifact

### Optional: Threshold Failure Test

**Purpose:** Demonstrate blocking behavior

**Steps:**
1. Temporarily modify `.github/workflows/gate-026-performance.yml`
2. Change thresholds to aggressive values:
   ```yaml
   'http_req_duration': ['p(50)<10', 'p(95)<20']  # Impossible to meet
   ```
3. Trigger workflow
4. **Expected:** Workflow fails with ❌ red X
5. Job summary shows "Performance Gate: FAIL"
6. Revert changes

**Evidence Needed:**
- [ ] Optional: GitHub Actions run screenshot (FAIL state demonstrating blocking)

---

## 📦 Evidence Package Checklist

### Track A Evidence
- [ ] Installation console screenshot
- [ ] Verification console screenshot (instrumented)
- [ ] Verification console screenshot (baseline)
- [ ] SigNoz traces screenshot (incoming + outgoing spans)
- [ ] SigNoz metrics screenshot (ASP.NET Core + runtime)
- [ ] SigNoz logs screenshot (with trace correlation, if available)
- [ ] Overhead calculation: X% (baseline vs instrumented)

### Track B Evidence
- [ ] GitHub Actions run screenshot (PASS)
- [ ] Job summary screenshot with threshold details
- [ ] k6 console output screenshot
- [ ] k6-results JSON artifact
- [ ] Optional: GitHub Actions run screenshot (FAIL demo)

### Track C Evidence
- [x] ✅ `artifacts/icf/convergence-report.json`
- [x] ✅ Dashboard with ICF section (lines 29-61)
- [x] ✅ Convergence Index: 51.77%
- [x] ✅ Console output screenshot (already captured)

---

## 📊 Final Evidence Package Structure

```
artifacts/
├── icf/
│   └── convergence-report.json ✅
├── gate026/
│   ├── track-a-installation.png
│   ├── track-a-verification-instrumented.png
│   ├── track-a-verification-baseline.png
│   ├── signoz-traces.png
│   ├── signoz-metrics.png
│   ├── signoz-logs.png (if available)
│   ├── overhead-calculation.txt
│   ├── track-b-ci-pass.png
│   ├── track-b-job-summary.png
│   ├── track-b-k6-output.png
│   ├── k6-results-gate026.json
│   └── track-c-analyzer-output.png ✅

docs/
├── GATE_STATUS_DASHBOARD.md (updated with ICF) ✅
└── ecrr/ECRR_REPORTS/
    └── ECRR_GATE_026_VERIFICATION_20251027.md (to be generated)
```

---

## 🎯 Success Criteria

### Track A
- ✅ Spans visible in SigNoz (incoming HTTP + outgoing HttpClient)
- ✅ Metrics present (ASP.NET Core + .NET runtime)
- ✅ Logs with trace correlation (if supported by app)
- ✅ Overhead ≤ 10%

### Track B
- ✅ k6 workflow triggers successfully
- ✅ Synthetic trace injection passes
- ✅ Thresholds enforced (p50<=900ms, p95<=1200ms, error<1%)
- ✅ Pipeline blocks on threshold failure (exit code non-zero)
- ✅ Artifacts archived (14-day retention)

### Track C
- ✅ **COMPLETE** — Convergence Index computed (51.77%)
- ✅ **COMPLETE** — Dashboard updated with ICF section
- ✅ **COMPLETE** — Evidence JSON generated

---

## 🚦 Phase 2 Review Preparation

Once all evidence is collected:

1. **Generate Final ECRR Report:**
   - Update `CHAR/ECRR/ECRR_REPORTS/ECRR_GATE_026_VERIFICATION_20251027.md`
   - Include all screenshots, metrics, and findings
   - Document any deviations or issues

2. **Update Gate Status:**
   - Add Gate #026 entry to `docs/GATE_STATUS_DASHBOARD.md`
   - Status: ✅ VERIFIED or ⏳ PENDING based on results

3. **Submit to BossCat OEM:**
   - Evidence package complete
   - ECRR report finalized
   - Request Phase 2 review
   - Propose tag: `gate-026-green-2025-10-27`

---

**Verification Guide Generated:** 2025-10-27  
**Track C Status:** ✅ Complete  
**Tracks A & B Status:** ⏳ Awaiting Execution  
**Next Action:** Execute Track A and B verification steps, collect evidence

**Seal:** 🐾 **Gate #026 Verification Guide**


