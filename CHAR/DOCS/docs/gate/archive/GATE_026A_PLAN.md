# Gate #026A — Investigation Plan

**Gate ID:** #026A  
**Title:** .NET Auto-Instrumentation Telemetry Investigation  
**Created:** 2025-10-27  
**Status:** ⏳ PLANNED  
**Priority:** P2 (Independent from #026B+026C delivery)  
**Origin:** Deferred from Gate #026 Track A (telemetry blocker)

---

## 🎯 Objective

**Goal:** Debug and fix .NET auto-instrumentation to achieve zero-code OpenTelemetry for .NET workloads on Windows with verified telemetry end-to-end in SigNoz.

**Success Criteria:**
- ✅ dotnet-test-gate026 **spans visible** in SigNoz (incoming HTTP + outgoing HttpClient)
- ✅ **Metrics present** in SigNoz (ASP.NET Core request metrics + .NET runtime)
- ✅ **Logs with trace correlation** (if app emits structured logs)
- ✅ **Overhead ≤10%** (already measured at 2.63%, verified)

---

## 🚨 Problem Statement

**Issue:** Zero telemetry from dotnet-test-gate026 reaching SigNoz despite correct configuration.

**Verified Missing in SigNoz:**
- ❌ Traces: Query returned "no results"
- ❌ Logs: Query returned "no results"
- ❌ Service: Not listed on Services page

**What Works:**
- ✅ App runs without errors (all endpoints functional)
- ✅ Health check confirms instrumentation configured
- ✅ Overhead measured (2.63%, minimal impact)
- ✅ Windows OTel Collector running (service RUNNING)
- ✅ SigNoz operational (other services visible)

**What Doesn't Work:**
- ❌ .NET app → telemetry → SigNoz (complete telemetry failure)

---

## 🔍 Root Cause Hypotheses

### Hypothesis 1: Profiler Not Activating (PRIMARY SUSPECT)

**Theory:** The .NET profiler DLL is not being loaded by the runtime.

**Evidence:**
- App runs without errors (would crash if DLL had syntax errors)
- No telemetry generated at all
- Configuration looks correct

**Investigation Steps:**
1. **Check app console output:**
   - Look for OTel initialization messages
   - Search for profiler loading confirmations
   - Check for warnings/errors

2. **Enable .NET diagnostics:**
   ```powershell
   $env:COREHOST_TRACE=1
   $env:COREHOST_TRACEFILE="C:\otel\artifacts\corehost-trace.log"
   # Re-run app, check trace log for profiler loading
   ```

3. **Verify DLL dependencies:**
   ```powershell
   # Check if profiler DLL has missing dependencies
   dumpbin /dependents "C:\otel\dotnet-autoinstrumentation\win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
   ```

4. **Test with .NET diagnostic tools:**
   ```powershell
   dotnet-trace collect --process-id <pid>
   # Check if profiler shows up in diagnostics
   ```

**Expected Fix:**
- Profiler path correction
- Missing dependency installation
- .NET runtime compatibility fix

---

### Hypothesis 2: Telemetry Generated But Not Exported (SECONDARY)

**Theory:** Profiler is working but telemetry isn't reaching the exporter.

**Investigation Steps:**
1. **Add debug logging:**
   ```powershell
   $env:OTEL_LOG_LEVEL="debug"
   $env:OTEL_DOTNET_AUTO_LOG_DIRECTORY="C:\otel\artifacts\otel-logs"
   # Re-run app, check OTel logs
   ```

2. **Verify OTLP endpoint reachable:**
   ```powershell
   Test-NetConnection -ComputerName localhost -Port 5317
   curl http://localhost:5317/v1/traces -Method POST -Body "{}"
   ```

3. **Test direct to SigNoz:**
   ```powershell
   # Bypass Windows Collector
   $env:OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:14317"
   # Re-run app, check if telemetry appears
   ```

**Expected Fix:**
- Port configuration correction
- Endpoint URL fix
- Exporter initialization issue

---

### Hypothesis 3: Windows Collector Not Forwarding (TERTIARY)

**Theory:** Collector receives traces but doesn't forward to SigNoz.

**Investigation Steps:**
1. **Check collector metrics:**
   ```powershell
   curl http://localhost:8888/metrics | Select-String "otelcol_receiver_accepted_spans"
   curl http://localhost:8888/metrics | Select-String "otelcol_exporter_sent_spans"
   ```

2. **Review collector logs:**
   ```powershell
   Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 50
   ```

3. **Test collector OTLP endpoint:**
   ```powershell
   # Send synthetic trace to port 5317
   # Check if it appears in collector metrics
   ```

**Expected Fix:**
- Traces pipeline configuration correction
- Processor issue fix
- Exporter endpoint correction

---

## 🛠️ Investigation Plan

### Phase 1: Diagnostics Collection (30 min)

**Actions:**
1. Enable .NET runtime tracing (`COREHOST_TRACE=1`)
2. Enable OTel debug logging (`OTEL_LOG_LEVEL=debug`)
3. Re-run app with diagnostics
4. Collect all log files
5. Check Windows Collector metrics

**Evidence:**
- CoreHost trace log
- OTel debug logs
- Windows Collector metrics snapshot
- App console output

### Phase 2: Isolated Testing (30 min)

**Actions:**
1. **Test 1:** Minimal .NET console app with OTel
   - Create simplest possible .NET 8.0 console app
   - Add same profiler configuration
   - Check if telemetry appears

2. **Test 2:** Direct to SigNoz
   - Change endpoint to http://127.0.0.1:14317
   - Bypass Windows Collector
   - Check if telemetry appears

3. **Test 3:** Explicit OTel SDK
   - Add OpenTelemetry NuGet packages to app
   - Use explicit SDK (not auto-instrumentation)
   - Verify SDK approach works

**Evidence:**
- Test results for each scenario
- Comparison matrix (auto-instr vs SDK vs direct)

### Phase 3: Fix Implementation (variable time)

**Actions:**
1. Based on Phase 1+2 findings, implement fix
2. Re-verify with full test suite
3. Collect complete evidence package
4. Submit for approval

**Evidence:**
- SigNoz screenshots (traces, metrics, logs)
- Fix documentation
- Verification results

---

## 📊 Budget

**Already Spent (Track A Code):**
- 330 LOC (3 scripts)
- Code is ready, just needs telemetry fix

**Additional Budget (Investigation):**
- ≤200 LOC for fixes/diagnostics
- ≤5 files for test apps/scripts

**Total Gate #026A Budget:**
- ≤530 LOC (existing 330 + new 200)
- ≤8 files

---

## ✅ Success Criteria for Gate #026A

**Telemetry Verification:**
- ✅ Traces: dotnet-test-gate026 spans visible in SigNoz
  - Incoming HTTP spans (ASP.NET Core)
  - Outgoing HttpClient spans
  - Correct service.name and resource attributes

- ✅ Metrics: ASP.NET Core + .NET runtime metrics present
  - http.server.request.duration
  - http.client.request.duration
  - .NET GC, thread pool, memory metrics

- ✅ Logs: Log entries with trace correlation (if applicable)
  - Console.WriteLine outputs (if OTel captures)
  - Microsoft.Extensions.Logging (if app uses)
  - trace_id field present

- ✅ Overhead: ≤10% (already verified at 2.63%)

**Evidence Requirements:**
- SigNoz screenshots (traces, metrics, logs)
- Overhead comparison (baseline vs instrumented)
- Root cause documentation
- Fix implementation details

---

## 🎯 Timeline

**Phase 1 (Diagnostics):** 30 minutes - 1 hour  
**Phase 2 (Testing):** 30 minutes - 1 hour  
**Phase 3 (Fix):** Variable (depends on root cause)

**Total Estimate:** 2-8 hours (depends on complexity)

**Priority:** P2 — Independent from Gate #026B+026C (already delivered)

---

## 📂 Reference Materials

**Existing Track A Code:**
- `scripts/gate026/install-dotnet-autoinstrumentation.ps1`
- `scripts/gate026/run-dotnet-app-instrumented.ps1`
- `scripts/gate026/verify-dotnet-instrumentation.ps1`

**Investigation Reports:**
- `GATE_026_TRACK_A_BLOCKER.md`
- `GATE_026_CRITICAL_FINDINGS.md`

**Configuration:**
- `config.yaml` (Windows Collector, traces pipeline lines 96-107)
- `dotnet-test-app/Program.cs` (test application)

**Documentation:**
- OpenTelemetry .NET Auto-Instrumentation docs
- Windows OTel Collector configuration guides
- SigNoz troubleshooting guides

---

## ✅ Approval Criteria

**Gate #026A is complete when:**
1. ✅ dotnet-test-gate026 telemetry visible in SigNoz (all three signals)
2. ✅ Root cause documented and fix implemented
3. ✅ Overhead remains ≤10%
4. ✅ Evidence package complete (screenshots + metrics)
5. ✅ ECRR report generated
6. ✅ BossCat OEM reviews and approves

**Target:** TBD (based on investigation findings)

---

**Plan Created:** 2025-10-27 09:10:00 UTC  
**Authority:** Cursor{Implementer}  
**Origin:** Gate #026 Track A blocker  
**Status:** ⏳ Ready for Investigation

**Seal:** 🐾 **Gate #026A Investigation Plan**

_Track A (.NET auto-instrumentation) deferred from Gate #026 due to zero telemetry in SigNoz. Three hypotheses: profiler not activating (primary), telemetry not exported (secondary), collector not forwarding (tertiary). Investigation plan prepared with diagnostics, isolated testing, and fix implementation phases. Success criteria: spans + metrics + logs visible in SigNoz with ≤10% overhead._

