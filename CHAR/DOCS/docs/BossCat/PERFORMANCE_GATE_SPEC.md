# Performance Gate Specification

**Authority:** BossCat OEM Gate #006 P1-D  
**Lane:** SSOT  
**Status:** ✅ ACTIVE — enforced by `gate-026-performance.yml` (`performance-gate.yml` RETIRED 2026-08-03)

---

## 🎯 **Performance SLOs**

### Hard Thresholds (CI Gating)

```text
p95 latency:     < 200ms  ✅ (headline SLO)
Error rate:      < 1%     ✅
Pass rate:       ≥ 99%    ✅
```

### Monitoring (Non-Gating)

```text
p50 latency:     < 100ms  (monitor)
Max latency:     < 500ms  (monitor)
```

---

## 📊 **Implementation**

**Test Script:** `ALFA/TEST/load/k6/perf-gate-thresholds.js`

**k6 Thresholds:**

```javascript
thresholds: {
  http_req_duration: ['p(95)<200'],    // GATE: p95 < 200ms
  http_req_failed: ['rate<0.01'],      // GATE: error < 1%
  checks: ['rate>=0.99'],              // GATE: pass ≥ 99%
}
```

**Exit Behavior:**

- Thresholds met: Exit 0 ✅
- Any threshold breached: Exit non-zero ❌ (CI fails)

---

## 🔧 **Usage**

### Local Testing

```bash
k6 run ALFA/TEST/load/k6/perf-gate-thresholds.js
```

### CI Integration

```bash
pnpm perf:gate
# Exit 0: Pass | Exit 1: Fail (threshold breach)
```

---

## 📈 **Current Performance**

**Baseline (from gate verification, 2025-10 — re-measure before citing):**

- p95: 1.92ms (96% under SLO) ✅
- p50: ~1ms ✅
- Success rate: 99.97% ✅

**Throughput uplift:** 7× (the 77× figure was retracted repo-wide on 2025-10-20 — `BOSSCAT_LOG.md`,
`scripts/guard-inflated-metrics.ps1`)  
**Batch Latency:** <200ms target achieved

---

**Authority:** BossCat OEM P1-D  
**Seal:** 🐾 Performance Gate Specification

