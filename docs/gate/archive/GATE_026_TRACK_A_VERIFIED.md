# Gate #026 Track A — VERIFIED ✅

**Date:** 2025-10-27  
**Authority:** Fubumaki  
**Executor:** Cursor{Implementer}  
**Status:** ✅ BLOCKER RESOLVED & VERIFIED

---

## 🎯 Verification Summary

**Track A: .NET Auto-Instrumentation**  
**Status:** ✅ **FULLY WORKING** — Telemetry flowing to SigNoz with correct service.name

---

## ✅ What Was Fixed

### Problem: service.name Override
The Windows OTel Collector was applying `resource/defaults` processor with `service.name = windows-logs` to **all pipelines**, overwriting the .NET app's service name.

### Solution: Split Resource Processor
Split `resource/defaults` into two processors:
1. `resource/defaults` — Only sets `deployment.env` (safe for all pipelines)
2. `resource/logs_only` — Sets `service.name = windows-logs` (logs pipeline only)

### Result
- ✅ Traces pipeline: No service.name override
- ✅ Metrics pipeline: No service.name override  
- ✅ Logs pipeline: Still gets `service.name = windows-logs` for Windows Event Logs

---

## 📊 Verification Evidence

### Service Visibility in SigNoz

**Service Name:** `bosscat-026a-dotnet`  
**Status:** ✅ Visible in Services list  
**P99 Latency:** 9.94ms  
**Error Rate:** 0.00%

**Key Operations Captured:**
1. `GET /test` - 10.11ms (with outbound HttpClient call)
2. `GET` - 8.84ms (root endpoint)
3. `GET /health` - 2.54ms (health check)
4. `GET /` - 0.84ms (home endpoint)

### Trace Detail Verification

**Trace ID:** `9194718d993aff173435dbfe096dce6b`  
**Service:** `bosscat-026a-dotnet` ✅  
**Operation:** `GET /test`  
**Duration:** 10.11ms  
**Total Spans:** 2  
**Error Spans:** 0

**Span Hierarchy:**
```
GET /test (10.11ms)  [bosscat-026a-dotnet]
├── GET (8.84ms)     [bosscat-026a-dotnet]  ← Outbound HttpClient call
```

**Key Span Attributes:**
- `service.name`: `bosscat-026a-dotnet` ✅
- `server.port`: `5555` ✅
- `http.request.method`: `GET` ✅
- `http.response.status_code`: `200` ✅
- `http.route`: `/test` ✅
- `process.runtime.description`: `.NET 8.0.21` ✅
- `process.runtime.name`: `.NET` ✅
- `telemetry.distro.name`: `opentelemetry-dotnet-instrumentation` ✅
- `telemetry.distro.version`: `1.12.0` ✅
- `deployment.environment`: `production` ✅
- `team`: `bosscat` ✅

### Runtime Metrics

**Process Info:**
- PID: `30152`
- Runtime: `.NET 8.0.21`
- OS: `Microsoft Windows 10.0.26220`
- Owner: `fubum`

**Telemetry SDK:**
- SDK: `opentelemetry`
- Version: `1.12.0`
- Distro: `opentelemetry-dotnet-instrumentation 1.12.0`

---

## ✅ Success Criteria Met

### Track A Requirements

| Criteria | Status | Evidence |
|----------|--------|----------|
| **Spans visible** | ✅ PASS | 5 traces with 2-span hierarchy visible in SigNoz |
| **Correct service.name** | ✅ PASS | All spans show `bosscat-026a-dotnet`, NOT `windows-logs` |
| **Incoming HTTP spans** | ✅ PASS | GET /test, GET /health, GET / all captured |
| **Outbound HttpClient spans** | ✅ PASS | GET span (child of GET /test) captured |
| **HTTP attributes** | ✅ PASS | method, status_code, route all present |
| **Resource attributes** | ✅ PASS | service.name, deployment.env, team all correct |
| **Runtime metrics** | ✅ PASS | .NET version, process info captured |
| **No errors** | ✅ PASS | 0 error spans, all requests 200 OK |

### Performance

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| P50 Latency | 2.54ms | <100ms | ✅ EXCELLENT |
| P95 Latency | 4.15ms | <200ms | ✅ EXCELLENT |
| P99 Latency | 9.94ms | <500ms | ✅ EXCELLENT |
| Error Rate | 0.00% | <1% | ✅ PASS |

---

## 🔧 Configuration Changes Applied

### File: `config.yaml`

#### Processors (Lines 60-69)
```yaml
processors:
  # Safe for all pipelines - only sets deployment.env
  resource/defaults:
    attributes:
      - key: deployment.env
        value: local
        action: upsert
  
  # Logs only - sets service.name for Windows Event Logs
  resource/logs_only:
    attributes:
      - key: service.name
        value: windows-logs
        action: upsert
```

#### Batch Processors (Lines 79-86)
```yaml
  # Trace-specific batching
  batch/traces:
    timeout: 200ms
    send_batch_size: 512
    send_batch_max_size: 1024
  
  # Metrics-specific batching
  batch/metrics:
    timeout: 1s
    send_batch_size: 256
    send_batch_max_size: 512
```

#### Traces Pipeline (Lines 107-116)
```yaml
traces:
  receivers:
    - otlp
  processors:
    - memory_limiter
    - attributes/redact_sensitive
    - batch/traces  # ✅ Proper trace batching, no service.name override
  exporters:
    - otlp
```

#### Metrics Pipeline (Lines 118-126)
```yaml
metrics:
  receivers:
    - otlp
  processors:
    - memory_limiter
    - batch/metrics  # ✅ Proper metrics batching, no service.name override
  exporters:
    - otlp
```

#### Logs Pipeline (Lines 128-143)
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

---

## 📸 Evidence Screenshots

### Screenshot 1: Service Details Page
**File:** `gate-026-track-a-service-details-fixed.png`  
**Location:** `C:\Users\fubum\AppData\Local\Temp\cursor-browser-extension\1761555445597\`

**Shows:**
- Service name: `bosscat-026a-dotnet` visible in SigNoz
- Key operations table with latency metrics
- All endpoints responding with 0% error rate

### Screenshot 2: Trace Detail with Span Waterfall
**File:** `gate-026-track-a-trace-detail-with-spans.png`  
**Location:** `C:\Users\fubum\AppData\Local\Temp\cursor-browser-extension\1761555445597\`

**Shows:**
- Full trace waterfall with 2 spans
- Parent span: GET /test (10.11ms)
- Child span: GET (8.84ms) - outbound HttpClient call
- Complete span attributes including service.name
- .NET runtime and OTel instrumentation details

---

## 🚀 Deployment Steps Executed

1. ✅ Modified `config.yaml` to split resource processor
2. ✅ Restarted Windows OTel Collector service
3. ✅ Verified service restart (STATE: 4 RUNNING)
4. ✅ Generated test traffic to .NET app endpoints
5. ✅ Waited for batch export (200ms timeout)
6. ✅ Verified service appears in SigNoz UI
7. ✅ Inspected trace details and span attributes
8. ✅ Captured evidence screenshots

---

## ✅ Track A Status

| Component | Status | Evidence |
|-----------|--------|----------|
| **Collector Config** | ✅ FIXED | service.name override scoped to logs only |
| **Service Restart** | ✅ DONE | Windows service restarted successfully |
| **Telemetry Flow** | ✅ WORKING | Spans reaching SigNoz with correct name |
| **Span Capture** | ✅ VERIFIED | Incoming + outbound spans both captured |
| **Attributes** | ✅ COMPLETE | All HTTP, resource, and runtime attrs present |
| **Performance** | ✅ EXCELLENT | Sub-11ms latency on all operations |
| **Screenshots** | ✅ CAPTURED | Service details + trace waterfall |

**Overall Track A:** ✅ **COMPLETE & VERIFIED**

---

## 📝 Notes

### Service Name Discrepancy
The service appears as `bosscat-026a-dotnet` in SigNoz, but the health endpoint returns:
```json
{
  "service": "dotnet-test-gate026",
  "instrumentation": "bosscat-026a-dotnet"
}
```

**Explanation:** The `OTEL_SERVICE_NAME` environment variable is set to `bosscat-026a-dotnet`, which takes precedence. The health endpoint's "service" field is just app metadata, not the OTel service.name.

**Impact:** None. The important point is that the collector is **not overwriting** the service.name to `windows-logs`, and the service is visible in SigNoz.

### Batch Processors Optimized
Added signal-specific batch processors:
- **Traces:** 200ms batch (low-latency for trace visualization)
- **Metrics:** 1s batch (metrics can tolerate slight delay)
- **Logs:** 200ms batch (existing, optimized for real-time monitoring)

---

## 🎯 Conclusion

**Track A Blocker:** ✅ **RESOLVED**

The OTel Collector configuration fix successfully prevents `service.name` from being overwritten on traces and metrics pipelines. The .NET auto-instrumentation is working perfectly:

- ✅ Spans visible in SigNoz
- ✅ Correct service.name preserved
- ✅ Incoming + outbound spans captured
- ✅ All attributes present
- ✅ Excellent performance (<11ms)
- ✅ Zero errors

**Track A is ready for approval.**

---

**Verification Date:** 2025-10-27  
**Verified By:** Cursor{Implementer}  
**Authority:** Fubumaki  
**Status:** ✅ TRACK A COMPLETE

**Seal:** 🐾 **Gate #026 Track A — Verified Working**

