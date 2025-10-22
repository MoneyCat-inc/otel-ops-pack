# Port 8889 Canary Behavior - Expected Connection Refusals

**Date:** 2025-10-22  
**Context:** Gate #008 Post-Approval Audit  
**Issue:** Canary logs show repeated connection refusals on `http://127.0.0.1:8889/metrics`

---

## Summary

**Port 8889 connection refusals are EXPECTED behavior and do NOT indicate a problem.**

The `canary-check-min.ps1` script implements a **fallback pattern** that tries port 8889 first, then falls back to port 8888. This provides resilience if the metrics endpoint configuration ever changes.

---

## Current Configuration

### Windows OTel Collector (`C:\otel\config.yaml`)
- **No prometheus exporter configured**
- **No explicit metrics endpoint on 8889**
- **Default internal metrics:** Port 8888 (implicit from collector)

### Canary Script (`canary-check-min.ps1`)
```powershell
function Get-MetricsCount {
  # Try 8889 then 8888
  $c = Get-AcceptedLogCount -Url $Metrics889
  if ($c -ge 0) { return @{ Count=$c; Url=$Metrics889 } }
  $c = Get-AcceptedLogCount -Url $Metrics888
  if ($c -ge 0) { return @{ Count=$c; Url=$Metrics888 } }
  return @{ Count=[int64](-1); Url="" }
}
```

**Behavior:**
1. Attempts connection to `http://127.0.0.1:8889/metrics`
2. Receives connection refused (expected - not configured)
3. Falls back to `http://127.0.0.1:8888/metrics`
4. Succeeds (port 8888 is serving metrics)
5. Canary test completes successfully

---

## Why This Pattern Exists

The fallback logic provides **operational flexibility**:
- If we add a prometheus exporter on 8889 in the future, canary auto-detects it
- If port 8888 is unavailable, canary can try alternate endpoints
- Graceful degradation without requiring script updates

---

## Log Interpretation

### Expected Log Pattern
```
Metrics fetch failed on http://127.0.0.1:8889/metrics: ...
[OK] Metrics Before: N
[OK] Metrics After: N+1
[OK] All checks passed
```

**This is SUCCESS.** The first line is informational (probe failed, fallback succeeded).

### Actual Failure Pattern
```
Metrics fetch failed on http://127.0.0.1:8889/metrics: ...
Metrics fetch failed on http://127.0.0.1:8888/metrics: ...
[FAIL] Could not reach metrics endpoint
```

**This would indicate a real problem** (both ports failed).

---

## Resolution Options

### Option A: Leave As-Is (RECOMMENDED)
- **Status quo:** Fallback logic works correctly
- **Pros:** Resilient to future config changes, zero operational impact
- **Cons:** "Failed" message in logs may confuse readers
- **Action:** Document this behavior (this document)

### Option B: Remove 8889 Probe
```powershell
function Get-MetricsCount {
  # Only check 8888
  $c = Get-AcceptedLogCount -Url $Metrics888
  if ($c -ge 0) { return @{ Count=$c; Url=$Metrics888 } }
  return @{ Count=[int64](-1); Url="" }
}
```
- **Pros:** Cleaner logs, no "failed" messages
- **Cons:** Loses fallback flexibility, requires script update if endpoint changes

### Option C: Add Prometheus Exporter to Config
```yaml
# Add to config.yaml exporters:
prometheus:
  endpoint: "0.0.0.0:8889"
  
# Add to service.pipelines.metrics:
metrics:
  receivers: [otlp]
  exporters: [prometheus, otlp]
```
- **Pros:** Exposes metrics on both ports for flexibility
- **Cons:** Requires collector restart, adds complexity, no clear benefit over 8888

---

## Recommendation

**Accept Option A (status quo) and document as expected behavior.**

**Rationale:**
1. ✅ Current behavior is functionally correct (canary tests pass)
2. ✅ Fallback logic provides operational resilience
3. ✅ No performance or security impact
4. ✅ Documentation (this file) addresses confusion

**No action required on canary script or collector config.**

---

## Related Evidence

- **Canary Script:** `canary-check-min.ps1` (lines 53-60)
- **Collector Config:** `C:\otel\config.yaml` (no prometheus exporter)
- **Port 8888 Status:** SERVING (verified in Gate #008 remediation)
- **Port 8889 Status:** Not configured (expected connection refused)
- **Canary Test Result:** PASSING (fallback succeeds)

---

**Verdict:** Port 8889 refusals are EXPECTED. No remediation needed. ✅

**Authority:** Cursor{Implementer}  
**Date:** 2025-10-22  
**Gate:** #008 Post-Approval Audit

