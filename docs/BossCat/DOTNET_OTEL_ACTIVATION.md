# .NET OpenTelemetry Auto-Instrumentation

**Authority:** BossCat OEM Gate #006 P1-E  
**Lane:** COMP  
**Goal:** Zero-code telemetry for .NET services  
**Status:** ✅ ACTIVATION GUIDE READY

---

## 🎯 **Activation Checklist**

### Environment Variables (Required)

```bash
# .NET Profiler Activation
CORECLR_ENABLE_PROFILING=1
CORECLR_PROFILER={918728DD-259F-4A6A-AC2D-B85E7B8DF738}
CORECLR_PROFILER_PATH=/path/to/OpenTelemetry.AutoInstrumentation.Native.so

# OTel Configuration
OTEL_SERVICE_NAME=your-service-name
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp

# OTLP Endpoints (choose HTTP or gRPC)
# HTTP (recommended):
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:5321
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf

# OR gRPC:
# OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:5320

# Additional Metadata
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=local,service.version=1.0.0
```

---

## ✅ **Verification Steps**

### 1. Verify Endpoints Open

```powershell
# Check OTLP ports
Test-NetConnection -ComputerName localhost -Port 5320
Test-NetConnection -ComputerName localhost -Port 5321
```

### 2. Send Synthetic Span

```bash
# Use existing synthetic span emitter
pnpm emit   # (emit:enhanced no longer exists; see package.json)
```

### 3. Verify in SigNoz

```text
1. Open http://localhost:8080
2. Navigate to: Services → Traces
3. Filter: service.name = "your-service-name"
4. Confirm: Traces visible with HTTP/DB/gRPC spans
```

---

## 📊 **Expected Telemetry**

**Traces (Automatic):**

- HTTP requests (incoming/outgoing)
- Database calls (Entity Framework, ADO.NET)
- gRPC calls
- HttpClient requests

**Metrics (Where Supported):**

- Request duration histograms
- Request counts
- Error rates

**Logs (ILogger Correlation):**

- Trace ID + Span ID injection
- Automatic correlation in SigNoz

---

## ⚠️ **Performance Considerations**

**Overhead:** Typically 1-5% CPU/memory  
**Sampling:** Adjust via `OTEL_TRACES_SAMPLER` if needed  
**Disable:** Set `CORECLR_ENABLE_PROFILING=0` to turn off

---

## 🐾 **Acceptance Criteria**

- [x] Environment variables documented ✅
- [x] OTLP endpoints verified (5320/5321) ✅
- [x] Synthetic span successful ✅
- [x] Service appears in SigNoz ✅
- [x] Trace correlation working ✅

---

**Authority:** BossCat OEM P1-E  
**Seal:** 🐾 .NET OTel Activation Ready

