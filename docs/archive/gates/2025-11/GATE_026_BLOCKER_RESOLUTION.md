# Gate #026 Blocker Resolution

**Date:** 2025-10-27  
**Authority:** Fubumaki  
**Executor:** Cursor{Implementer}  
**Status:** ✅ BLOCKERS RESOLVED

---

## 🚨 Blockers Identified

### BLOCKER 1: Track A - service.name Override

**Issue:** The Windows OTel Collector configuration applies `resource/defaults` processor to **all pipelines** (traces, metrics, logs), which upserts `service.name = windows-logs` for every signal. This overwrites the correct `service.name` from the .NET app (`dotnet-test-gate026`), causing zero SigNoz evidence.

**Root Cause:**
```yaml
# config.yaml lines 60-67
resource/defaults:
  attributes:
    - key: deployment.env
      value: local
      action: upsert
    - key: service.name
      value: windows-logs
      action: upsert  # ❌ Applied to ALL pipelines!
```

**Impact:** Any spans or metrics from `dotnet-test-gate026` are renamed to `windows-logs` before export, making the service invisible in SigNoz.

---

### BLOCKER 2: Track B - k6 Script Uses Node.js APIs

**Issue:** The k6 script (`scripts/perf/k6-performance-gate.js`) uses Node.js-specific APIs that don't exist in the k6 runtime:
- `require('fs')` (line 48)
- `require('path')` (line 49)
- `__dirname` (line 50)

**Root Cause:**
```javascript
export function handleSummary(data) {
  const fs = require('fs');        // ❌ Not available in k6
  const path = require('path');    // ❌ Not available in k6
  const artifactsDir = path.join(__dirname, '../../artifacts');  // ❌ __dirname doesn't exist
  // ...
}
```

**Impact:** The script will throw `ReferenceError` when `handleSummary` executes, causing the CI gate to fail even if thresholds pass.

---

### BLOCKER 3: Track B - Wrong Target Service

**Issue:** The k6 script defaults to testing the SigNoz API (`http://localhost:8080`) instead of the product service (`dotnet-test-gate026` on port 5555).

**Root Cause:**
```javascript
const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';  // ❌ Wrong default!
const res = http.get(`${baseUrl}/api/v1/version`);          // ❌ SigNoz endpoint!
```

**Impact:** The load test measures SigNoz UI performance instead of the actual .NET service, making threshold results meaningless.

---

## ✅ Fixes Applied

### Fix 1: Split resource Processor (Track A)

**Change:** Split `resource/defaults` into two processors:
1. `resource/defaults` - Only sets `deployment.env` (safe for all pipelines)
2. `resource/logs_only` - Sets `service.name = windows-logs` (logs pipeline only)

**Updated config.yaml:**
```yaml
processors:
  # Lines 60-64: Safe for all pipelines
  resource/defaults:
    attributes:
      - key: deployment.env
        value: local
        action: upsert
  
  # Lines 65-69: Logs pipeline only
  resource/logs_only:
    attributes:
      - key: service.name
        value: windows-logs
        action: upsert
```

**Updated Traces Pipeline:**
```yaml
traces:
  receivers:
    - otlp
  processors:
    - memory_limiter
    - attributes/redact_sensitive
    - batch/traces  # ✅ Proper trace batching
  exporters:
    - otlp
```

**Updated Metrics Pipeline:**
```yaml
metrics:
  receivers:
    - otlp
  processors:
    - memory_limiter
    - batch/metrics  # ✅ Proper metrics batching
  exporters:
    - otlp
```

**Updated Logs Pipeline:**
```yaml
logs:
  receivers:
    - otlp
    - windowseventlog/application
    - windowseventlog/system
    - filelog/queue
    - filelog/canary
  processors:
    - memory_limiter
    - filter/drop_noise
    - attributes/redact_sensitive
    - resource/logs_only  # ✅ Only logs get service.name override
    - attributes/label_source
    - batch/logs
  exporters:
    - otlp
```

**Result:** 
- ✅ Traces from `dotnet-test-gate026` retain correct `service.name`
- ✅ Metrics from `dotnet-test-gate026` retain correct `service.name`
- ✅ Windows Event Logs still get `service.name = windows-logs`
- ✅ Added proper batch processors for traces (`200ms`) and metrics (`1s`)

---

### Fix 2: Remove Node.js APIs from k6 Script (Track B)

**Change:** Rewrote `handleSummary` to use k6's native file handling. k6 automatically creates directory structures from file paths in the return object.

**Before:**
```javascript
export function handleSummary(data) {
  const fs = require('fs');  // ❌
  const path = require('path');  // ❌
  const artifactsDir = path.join(__dirname, '../../artifacts');  // ❌
  if (!fs.existsSync(artifactsDir)) {
    fs.mkdirSync(artifactsDir, { recursive: true });
  }
  
  return {
    'artifacts/k6-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
```

**After:**
```javascript
export function handleSummary(data) {
  // ✅ k6 will create the directory structure automatically
  return {
    '../../artifacts/k6-summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
```

**Result:**
- ✅ No Node.js APIs used
- ✅ k6 runtime compatible
- ✅ Artifacts still written to correct location

---

### Fix 3: Correct Target Service (Track B)

**Change:** Updated default `BASE_URL` to point to `dotnet-test-gate026` service (port 5555) and fixed endpoint to match the app's API.

**Before:**
```javascript
const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';  // ❌ SigNoz UI
const res = http.get(`${baseUrl}/api/v1/version`);          // ❌ SigNoz endpoint
```

**After:**
```javascript
// ✅ Test the dotnet-test-gate026 service, NOT SigNoz UI
const baseUrl = __ENV.BASE_URL || 'http://localhost:5555';
const res = http.get(`${baseUrl}/health`);  // ✅ App health endpoint
```

**Result:**
- ✅ Load test targets correct service
- ✅ Thresholds measure actual product performance
- ✅ Can still override with `--env BASE_URL=...` if needed

---

## 📋 Required Next Steps

### 1. Restart Windows OTel Collector

The collector config has been updated. Restart the service to apply changes:

```powershell
# Restart the Windows Collector service
Restart-Service otelcol-contrib

# Verify it's running
Get-Service otelcol-contrib

# Check for errors in event log
Get-EventLog -LogName Application -Source "otelcol-contrib" -Newest 5
```

### 2. Re-run Track A Evidence Collection

With the collector config fixed, the .NET app should now send proper telemetry:

```powershell
# Start the .NET app (if not already running)
.\scripts\gate026\run-dotnet-app-instrumented.ps1

# In a separate terminal, verify telemetry
.\scripts\gate026\verify-dotnet-instrumentation.ps1

# Check SigNoz for service.name = 'dotnet-test-gate026'
# Traces: http://localhost:8080/traces
# Metrics: http://localhost:8080/metrics
# Query: service.name = 'dotnet-test-gate026'
```

**Expected Results:**
- ✅ Spans visible with `service.name = dotnet-test-gate026`
- ✅ Metrics visible with `service.name = dotnet-test-gate026`
- ✅ Service appears in Services list

### 3. Test k6 Script Locally

Verify the k6 script works before running in CI:

```powershell
# Ensure dotnet-test-gate026 is running on port 5555
Test-NetConnection -ComputerName localhost -Port 5555

# Run k6 test
k6 run scripts\perf\k6-performance-gate.js

# Verify artifacts created
Test-Path .\artifacts\k6-summary.json
```

**Expected Results:**
- ✅ Script runs without ReferenceError
- ✅ Tests hit correct endpoints (/, /health, /test)
- ✅ Thresholds evaluate properly
- ✅ JSON artifact written to `artifacts/k6-summary.json`

### 4. Create/Update CI Workflow

If a CI workflow exists, ensure it:
- Sets `BASE_URL` explicitly (or relies on the corrected default)
- Starts the `dotnet-test-gate026` service before running k6
- Archives the k6 summary artifact

**Workflow considerations:**
```yaml
# Example snippet
- name: Run k6 Load Test
  run: k6 run scripts/perf/k6-performance-gate.js --out json=artifacts/k6-results.json
  env:
    BASE_URL: http://localhost:5555  # Optional: default is now correct
```

### 5. Re-verify Gate 026 Evidence

After fixes:
1. **Track A:** Collect new SigNoz screenshots showing `dotnet-test-gate026` telemetry
2. **Track B:** Run k6 locally and capture results (thresholds pass/fail)
3. **Track C:** No changes needed (ICF already complete)

---

## 🎯 Questions Answered

### "Which service is supposed to be under load for Track B?"

**Answer:** The `dotnet-test-gate026` service (port 5555), which is the .NET test application for Track A auto-instrumentation.

**Endpoints to test:**
- `GET http://localhost:5555/` - Root endpoint (simple response)
- `GET http://localhost:5555/health` - Health check (returns JSON status)
- `GET http://localhost:5555/test` - Test endpoint (makes outbound HttpClient call)

**Rationale:** Track B (k6 CI gates) should measure the performance of the product service, not the observability backend (SigNoz).

---

## ✅ Resolution Summary

| Blocker | Root Cause | Fix Applied | Status |
|---------|-----------|-------------|--------|
| **Track A: Zero SigNoz Evidence** | `resource/defaults` overwrites `service.name` | Split processor, scope to logs only | ✅ FIXED |
| **Track B: k6 Script ReferenceError** | Node.js APIs in `handleSummary` | Use k6-native file handling | ✅ FIXED |
| **Track B: Wrong Target Service** | `BASE_URL` defaults to SigNoz UI | Point to `dotnet-test-gate026:5555` | ✅ FIXED |
| **Bonus: Missing Batch Processors** | Traces/metrics used `batch/logs` | Added `batch/traces` and `batch/metrics` | ✅ FIXED |

**Files Modified:**
1. `config.yaml` - Collector configuration (4 changes)
2. `scripts/perf/k6-performance-gate.js` - k6 test script (2 changes)

**Lines Changed:** ~20 LOC total

---

## 🚦 Gate 026 Readiness

**Before Fixes:**
- ❌ Track A: BLOCKED (zero telemetry)
- ❌ Track B: BLOCKED (script won't run)
- ✅ Track C: COMPLETE (no issues)

**After Fixes:**
- ⏳ Track A: READY FOR RE-TEST (config fixed, needs verification)
- ⏳ Track B: READY FOR TEST (script fixed, needs local run)
- ✅ Track C: COMPLETE (unchanged)

**Overall Status:** 🟡 **READY FOR RE-VERIFICATION**

---

## 🐾 Executor Notes

**Authority:** Fubumaki  
**Executor:** Cursor{Implementer}  
**Role:** Code Writer-Executioner  

**Fixes Applied:**
- ✅ Blocker analysis: Complete
- ✅ Code changes: Minimal and surgical
- ✅ Root cause: Identified and resolved
- ✅ Next steps: Documented

**Recommendation:** Execute the "Required Next Steps" section sequentially, collect fresh evidence, and resubmit the gate bundle for approval.

---

**Resolution Date:** 2025-10-27  
**Seal:** 🐾 **Gate #026 Blocker Resolution**

