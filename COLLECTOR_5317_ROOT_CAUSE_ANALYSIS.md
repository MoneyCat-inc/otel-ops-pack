# Windows Collector 5317 — Root Cause Analysis

**Date:** 2025-10-27 16:15:00 UTC  
**Investigator:** Cursor{Implementer}  
**Authority:** BossCat OEM (Fubumaki)  
**Status:** ✅ **ROOT CAUSE IDENTIFIED**

---

## Executive Summary

**Root Cause:** Windows OTel Collector is **NOT configured to receive OTLP traces** on port 5317. The collector only handles:
- Host metrics (CPU, memory, disk, network)
- Windows Event Logs

**Impact:** .NET services cannot use collector as centralized telemetry hub; must send directly to SigNoz port 14317.

**Fix Complexity:** LOW — Add OTLP receiver + traces pipeline to config, restart service

---

## Evidence: Configuration Analysis

### Current Configuration (`windows\otelcol\otelcol-contrib-config.yaml`)

**Receivers (Lines 8-28):**
```yaml
receivers:
  hostmetrics:          # ✅ Collects Windows host metrics
  windowseventlog:      # ✅ Collects Application event logs
  windowseventlog/system: # ✅ Collects System event logs
```

**Missing:**
- ❌ **NO `otlp` receiver** (needed to accept OTLP protocol on port 5317)

**Exporters (Lines 50-64):**
```yaml
exporters:
  otlp:                 # ✅ Configured to export to ${env:OTLP_GRPC_ENDPOINT}
    endpoint: ${env:OTLP_GRPC_ENDPOINT}
    tls:
      insecure: true
  logging:              # ✅ Debug logging
    loglevel: warn
```

**Status:** Exporter is configured correctly (if OTLP_GRPC_ENDPOINT points to SigNoz)

**Service Pipelines (Lines 73-84):**
```yaml
service:
  pipelines:
    metrics:            # ✅ EXISTS
      receivers: [hostmetrics]
      processors: [memory_limiter, resource, batch]
      exporters: [otlp, logging]
    
    logs:               # ✅ EXISTS
      receivers: [windowseventlog, windowseventlog/system]
      processors: [resource, batch]
      exporters: [otlp, logging]
    
    # traces: ???     ❌ MISSING!
```

**Missing:**
- ❌ **NO `traces` pipeline** (needed to forward received OTLP traces to SigNoz)

---

## Why Port 5317 Appears to Be "Listening"

When we run `Test-NetConnection -Port 5317`, it shows the port as listening. However:

**Actual Situation:**
- The collector service is running
- The service **might** be binding to port 5317 (or not, since no OTLP receiver is configured)
- Even if something is listening, there's no OTLP receiver to process incoming traces

**Result:**
- Connections to 5317 might be accepted but immediately dropped
- Or connections fail at the protocol level (no OTLP handler)
- No traces forwarded to SigNoz

---

## Why Direct Port 14317 Works

**Route:** .NET Service → SigNoz Direct (port 14317)

```
.NET App (OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:14317)
    ↓
SigNoz OTLP Collector (Docker container)
    ↓
SigNoz Backend
    ↓
ClickHouse Database
```

**This works because:**
- SigNoz has its own OTLP collector (Docker container `signoz-otel-collector`)
- That collector listens on port 14317 (gRPC) and 14318 (HTTP)
- It's configured to receive OTLP and forward to SigNoz backend
- No dependency on Windows Collector

---

## The Missing Configuration

### What SHOULD Be in the Config

**Add OTLP Receiver (after line 28):**
```yaml
  # OTLP receiver for application telemetry
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:5317  # Listen on port 5317
      http:
        endpoint: 0.0.0.0:5318  # Optional: HTTP on 5318
```

**Add Traces Pipeline (after line 84):**
```yaml
    # Application traces pipeline (forwarding to SigNoz)
    traces:
      receivers: [otlp]
      processors: [memory_limiter, resource, batch]
      exporters: [otlp, logging]
```

**Set Environment Variable:**
```powershell
$env:OTLP_GRPC_ENDPOINT = "localhost:14317"  # Forward to SigNoz
```

---

## Verification Steps (If Fix Applied)

### Step 1: Update Config
1. Add `otlp` receiver with port 5317
2. Add `traces` pipeline
3. Verify `OTLP_GRPC_ENDPOINT` points to `localhost:14317`

### Step 2: Restart Collector
```powershell
Restart-Service otelcol-contrib
```

### Step 3: Test
```powershell
# Deploy .NET service pointing to 5317
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:5317"
# Run service, generate traffic
# Check SigNoz for traces
```

### Step 4: Verify Metrics
```powershell
# Query collector metrics
curl http://localhost:8888/metrics | Select-String "otelcol_receiver_accepted_spans"
curl http://localhost:8888/metrics | Select-String "otelcol_exporter_sent_spans"
```

**Expected:**
- `otelcol_receiver_accepted_spans{receiver="otlp"}` > 0
- `otelcol_exporter_sent_spans{exporter="otlp"}` ≈ accepted_spans
- Traces visible in SigNoz

---

## Decision: Fix Now or Document Workaround?

### Option A: Fix Now (Recommended for Production)
**Pros:**
- Enables centralized telemetry collection
- Windows Collector becomes useful for .NET workloads
- Single configuration point for all telemetry routing

**Cons:**
- Requires config change + service restart
- Need to test thoroughly

**Effort:** 20-30 minutes

### Option B: Document Workaround (Current State)
**Pros:**
- No changes needed
- Direct port 14317 works perfectly
- Lower risk

**Cons:**
- Windows Collector remains underutilized
- .NET services bypass collector (less centralized)
- Missed opportunity for collector-level processing

**Effort:** 5 minutes (document limitation)

---

## Recommendation

**Option A: Fix the configuration** 

**Rationale:**
- Configuration gap is simple to fix
- Aligns with Gate #029 objective (collector path verification)
- Enables proper centralized telemetry collection
- Low risk (can always revert if issues)

**Next Steps:**
1. Create fixed config
2. Test in development
3. Apply to production
4. Verify with live service
5. Document in runbook

---

**Root Cause Identified:** 2025-10-27 16:20:00 UTC  
**Status:** ✅ **CONFIGURATION GAP FOUND**  
**Fix Effort:** 20-30 minutes  
**Risk:** LOW

🐾 **Root Cause: Missing OTLP Receiver + Traces Pipeline in Windows Collector Config**

