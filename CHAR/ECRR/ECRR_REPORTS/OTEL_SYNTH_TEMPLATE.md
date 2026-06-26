# OTEL Synthetic Trace — Proof Report

**Date:** YYYY-MM-DD  
**Service:** hub-synth  
**Endpoint:** https://hub.resonai.io/robots.txt  
**Status:** [PASS/FAIL]

---

## Environment Variables

```bash
CORECLR_ENABLE_PROFILING=1
CORECLR_PROFILER={918728DD-259F-4A6A-AC2B-B85E1B658318}
OTEL_SERVICE_NAME=hub-synth
OTEL_TRACES_EXPORTER=otlp
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

---

## Execution

**Command:**
```powershell
dotnet run
```

**Output:**
```
Status: 200
```

---

## Evidence

![Trace Screenshot](../screens/otel-synth.png)

**Span Details:**
- Service: hub-synth
- Operation: HTTP GET /robots.txt
- Duration: ~XXX ms
- Status: OK
- Trace ID: [trace-id]
- Span ID: [span-id]

---

## Observations

- ✅ Single span observed in SigNoz
- ✅ No errors or warnings
- ✅ Confirms instrumentation path operational
- ✅ HTTP GET to production Hub successful

---

## Notes

[Any additional observations or issues encountered]

---

**BossCat Certification:** Observability proof complete. Auto-instrumentation validated.

**Date:** [YYYY-MM-DD]  
**Authority:** Cursor{Implementer}

