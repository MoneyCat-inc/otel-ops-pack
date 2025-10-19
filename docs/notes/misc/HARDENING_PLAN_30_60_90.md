# 🛡️ 30/60/90 Hardening Plan — Post-Gate #006

**Gate:** GATE-2025-10-10-BOSSCAT-006  
**Status:** Non-blocking enhancements  
**Authority:** BossCat OEM guidance  

---

## Overview

Progressive hardening plan aligned with immutable persona v1.1, strategic plan, and performance gate doctrine. All items are **non-blocking** and scheduled for Day-2+ operations.

---

## 📅 30 Days — Hygiene Guard

**Objective:** Keep snapshots trendable and hygiene evergreen

### Actions

1. **Monitor Weekly Re-Cert Snapshots**
   - Location: `docs/observability/snapshots/guardrails-recert-*.json`
   - Frequency: Review monthly
   - Goal: Ensure snapshot accumulation and trend visibility

2. **Add Stray Port Grep (Optional)**
   - Target: `.github/workflows/guardrails-recert.yml`
   - Purpose: Flag any new `:13133` references outside historical archives
   - Implementation:

   ```yaml
   - name: Check for stray legacy port refs
     run: |
       # Flag any new :13133 refs outside historical archives
       if rg --hidden --glob "!.git/**" --glob "!CHAR/PRSV/**" --glob "!CHAR/ECRR/**" --glob "!docs/observability/snapshots/**" "\b13133\b" > /dev/null 2>&1; then
         echo "::warning::Found :13133 references outside archives - consider hygiene pass"
       fi
   ```

3. **Review Guardrails Drift Trends**
   - Check for recurring issues
   - Document patterns
   - Adjust exemptions if justified

### Deliverables

- ✅ Weekly snapshots accumulating
- ✅ Optional stray port check added
- 📊 Monthly trend report (lightweight)

### Effort

**Time:** 1-2 hours/month  
**Priority:** Medium  
**Risk:** Low

---

## 📅 60 Days — Perf Gate Uplift

**Objective:** Pilot CI-native performance thresholds matching performance gate doctrine

### Actions

1. **Add k6 Load Test to CI**
   - Create `.github/workflows/perf-gate-k6.yml`
   - 60-second smoke test with threshold enforcement
   - Run on PR to main (or nightly)

2. **Define Performance SLOs**
   - Example: p95 latency < 500ms
   - Example: Error rate < 1%
   - Align with service requirements

3. **Implement Threshold Check**
   
   **Example k6 Script:**
   ```javascript
   import http from 'k6/http';
   import { check } from 'k6';
   
   export let options = {
     duration: '60s',
     vus: 10,
     thresholds: {
       'http_req_duration{p(95)}': ['value<500'], // p95 < 500ms
       'http_req_failed': ['rate<0.01'],          // <1% errors
     }
   };
   
   export default function () {
     let res = http.get('http://localhost:3000/api/health');
     check(res, { 'status is 200': (r) => r.status === 200 });
   }
   ```

4. **Upload Results as Evidence**
   - Store JSON results: `docs/observability/snapshots/perf/k6-<timestamp>.json`
   - Make gate-blocking on threshold breach
   - Trend over time for regression detection

### Workflow Example

```yaml
name: Performance Gate (k6)

on:
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  k6-perf:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Start services
        run: docker-compose up -d
      
      - name: Run k6 load test
        uses: grafana/k6-action@v0.3.1
        with:
          filename: BRAV/SCPT/perf-gate.js
          flags: --out json=k6-results.json
      
      - name: Upload results
        run: |
          mkdir -p docs/observability/snapshots/perf
          cp k6-results.json docs/observability/snapshots/perf/k6-$(date +%Y%m%d-%H%M%S).json
      
      - name: Check thresholds
        run: |
          if grep -q '"failed":true' k6-results.json; then
            echo "::error::Performance thresholds breached"
            exit 1
          fi
```

### Deliverables

- ✅ k6 workflow added
- ✅ Performance thresholds defined
- ✅ JSON results archived
- 📊 Threshold breach reporting

### Effort

**Time:** 4-6 hours initial setup  
**Priority:** High (if performance SLOs exist)  
**Risk:** Medium (may expose latency issues)

---

## 📅 90 Days — Service Telemetry

**Objective:** Enable production-grade observability for .NET services via OpenTelemetry auto-instrumentation

### Actions

1. **Select Pilot Services**
   - Start with 1-2 .NET services
   - Begin in staging environment
   - Tag: `deployment.environment=staging`

2. **Install OTel Auto-Instrumentation**
   
   **PowerShell (Windows):**
   ```powershell
   # Download latest release
   Invoke-WebRequest -Uri "https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/latest/download/otel-dotnet-auto-install.ps1" -OutFile install.ps1
   
   # Install
   .\install.ps1 -OtelDotNetAutoInstallDir "C:\Program Files\OpenTelemetry"
   ```

3. **Configure Environment Variables**
   
   **Service Configuration:**
   ```yaml
   environment:
     OTEL_EXPORTER_OTLP_ENDPOINT: "http://localhost:4318"
     OTEL_SERVICE_NAME: "resonai-service"
     OTEL_DOTNET_AUTO_TRACES_ENABLED: "true"
     OTEL_DOTNET_AUTO_METRICS_ENABLED: "true"
     OTEL_DOTNET_AUTO_LOGS_ENABLED: "false"  # Start with traces/metrics only
     OTEL_RESOURCE_ATTRIBUTES: "deployment.environment=staging,service.version=1.0.0"
     
     # Sampling (tune based on traffic)
     OTEL_TRACES_SAMPLER: "parentbased_traceidratio"
     OTEL_TRACES_SAMPLER_ARG: "0.1"  # 10% sampling
   ```

4. **Validate in SigNoz**
   - Navigate to SigNoz APM: `http://localhost:8080`
   - Check for service in service list
   - Verify traces are flowing
   - Review error rates and latency

5. **Tune Sampling**
   - Start conservative (10% sampling)
   - Monitor overhead (CPU/memory)
   - Adjust based on traffic volume
   - Increase for critical services

6. **Graduate to Production**
   - After successful staging validation (2-4 weeks)
   - Update `deployment.environment=production`
   - Monitor for 1 week
   - Expand to additional services

### Configuration Templates

**Minimal (Traces Only):**
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_SERVICE_NAME="my-service"
export OTEL_DOTNET_AUTO_TRACES_ENABLED="true"
```

**Full (Traces + Metrics):**
```bash
export OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4318"
export OTEL_SERVICE_NAME="my-service"
export OTEL_DOTNET_AUTO_TRACES_ENABLED="true"
export OTEL_DOTNET_AUTO_METRICS_ENABLED="true"
export OTEL_TRACES_SAMPLER="parentbased_traceidratio"
export OTEL_TRACES_SAMPLER_ARG="0.1"
export OTEL_RESOURCE_ATTRIBUTES="deployment.environment=staging,service.version=1.0.0"
```

### Deliverables

- ✅ OTel auto-instrumentation installed
- ✅ 1-2 services instrumented in staging
- ✅ Traces visible in SigNoz APM
- ✅ Sampling tuned for overhead
- 📊 Service dashboards created
- 📈 Error rate and latency metrics tracked

### Effort

**Time:** 8-12 hours (initial setup + tuning)  
**Priority:** Medium-High (depends on .NET service criticality)  
**Risk:** Low (zero-code changes, easily reversible)

---

## 📊 Success Metrics

### 30 Days
- Weekly snapshots accumulating: ✅/❌
- Stray port check active (optional): ✅/❌
- No guardrails drift detected: ✅/❌

### 60 Days
- k6 workflow active: ✅/❌
- Performance thresholds defined: ✅/❌
- Results archived and trendable: ✅/❌
- Zero threshold breaches (or documented exceptions): ✅/❌

### 90 Days
- OTel auto-instrumentation installed: ✅/❌
- 1-2 services instrumented in staging: ✅/❌
- Traces flowing to SigNoz: ✅/❌
- Dashboards created: ✅/❌
- Production rollout plan documented: ✅/❌

---

## 🛡️ Risk Mitigation

### 30 Days
- **Risk:** Snapshot bloat
- **Mitigation:** Automated cleanup (keep last 30 days)

### 60 Days
- **Risk:** Performance test false positives
- **Mitigation:** Tune thresholds; retry on failure

### 90 Days
- **Risk:** Service overhead from tracing
- **Mitigation:** Start with low sampling (10%); monitor CPU/memory

---

## 🧭 Alignment with BossCat Doctrine

**Local-First, Evidence-First:**
- All enhancements generate local artifacts
- Evidence flows to `docs/observability/snapshots/`
- No external dependencies for core operations

**Safety Budgets:**
- Each enhancement respects ≤2 jobs / ≤10 files / ≤200 LOC
- Changes are lane-scoped and incremental
- Kill-switch (`.agent/LOCK`) honored

**Performance Gate Doctrine:**
- k6 thresholds align with CI-native performance gates
- Artifacts are trendable and release-blocking
- Evidence-based decision making

---

## 📚 References

**OpenTelemetry .NET:**
- Docs: https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation
- Installation: https://opentelemetry.io/docs/instrumentation/net/automatic/

**k6 Performance Testing:**
- Docs: https://k6.io/docs/
- Thresholds: https://k6.io/docs/using-k6/thresholds/

**SigNoz APM:**
- UI: http://localhost:8080
- Docs: https://signoz.io/docs/

---

## 🐾 BossCat Endorsement

This hardening plan follows the "small, safe steps" mantra and aligns with:
- ✅ Immutable persona v1.1 (budgets, lanes, evidence)
- ✅ Strategic plan (local-first, evidence-first)
- ✅ Performance gate doctrine (CI-native thresholds)
- ✅ ECRR discipline (examine before acting)

**Status:** Non-blocking, Day-2+ enhancements  
**Priority:** Progressive hardening over 90 days  
**Risk:** Low (all reversible, no breaking changes)

---

**End of 30/60/90 Hardening Plan**

*MoneyCat Inc · Resonai [OTel] · BossCat Operations*

