# OTLP Ingest Uplift — Evidence Pack (YYYY-MM-DD)

**Status:** TEMPLATE — Use this structure for any performance uplift measurement campaign  
**Authority:** BossCat OEM  
**Purpose:** Evidence-backed performance claims with reproducible methodology

---

## Configuration

### Baseline Config
- **Commit/Tag:** `<git commit or tag>`
- **Collector:** OpenTelemetry Collector Contrib `<version>`
- **Exporter:** OTLP/gRPC
- **Batch Processor:**
  - `timeout: <value>`
  - `send_batch_size: <value>`
  - `send_batch_max_size: <value>`
- **Config File:** `<path/to/config.yaml>`

### New (Optimized) Config
- **Commit/Tag:** `<git commit or tag>`
- **Changes:**
  - `<specific parameter change 1>`
  - `<specific parameter change 2>`
  - `<specific parameter change 3>`
- **Config File:** `<path/to/config-optimized.yaml>`

### Environment
- **Hardware:** `<CPU model, cores, RAM>`
- **OS:** `<Windows 10/11, version, build>`
- **SigNoz Version:** `<v0.x.x>`
- **Collector Version:** `<otelcol-contrib vX.Y.Z>`
- **Network:** `<localhost loopback / docker bridge / network details>`
- **Power Plan:** `<High Performance / Balanced>`
- **Other Services:** `<running/stopped during test>`

---

## Test Methodology

### Synthetic Sender Configuration
- **Protocol:** OTLP/gRPC (port 4317) or OTLP/HTTP (port 4318)
- **Payload:** `<log structure, attributes, size>`
- **Rate:** `<logs/sec target or burst pattern>`
- **Duration:** 60 seconds per trial
- **Warmup:** `<cold start / 10s warmup / none>`

### Trial Procedure
1. **Reset state:** Restart Collector and SigNoz
2. **Wait for ready:** Verify all services healthy (30s settle)
3. **Execute synthetic sender:** Run for 60 seconds
4. **Capture metrics:** Query SigNoz for log count in window
5. **Calculate throughput:** `logs_received / 60 = logs/sec`
6. **Repeat:** 5 trials per variant (cold start each time)

### Measurement
- **Metric:** Logs/sec successfully ingested and visible in SigNoz
- **Query:** `SELECT count(*) FROM logs WHERE timestamp BETWEEN t_start AND t_end AND service_name = 'synthetic'`
- **Window:** Exact 60-second window from first log to last log

---

## Results

### Per-Trial Logs/Sec

| Variant | Trial 1 | Trial 2 | Trial 3 | Trial 4 | Trial 5 | Median |
|---------|---------|---------|---------|---------|---------|--------|
| **BASELINE** | - | - | - | - | - | **-** |
| **NEW** | - | - | - | - | - | **-** |

### Uplift Calculation

**Throughput Uplift (×)** = `median(NEW) / median(BASELINE)`

**Result:** `<calculated value>×`

---

## Statistical Confidence

### Bootstrap 95% Confidence Interval
- **Method:** Bootstrap resampling (10,000 iterations) on trial medians
- **95% CI:** `[<lower_bound>×, <upper_bound>×]`

### Publication Decision
- ✅ **Publish uplift if:** 95% CI lower bound ≥ 6.0×
- ⚠️ **Publish absolutes only if:** 95% CI lower bound < 6.0×
  - Format: "Baseline: X logs/sec → New: Y logs/sec (measured)"

### Statistical Notes
- Sample size: N=5 per variant (minimum for median stability)
- Variance analysis: `<coefficient of variation for each variant>`
- Outlier handling: `<none / removed trials with justification>`

---

## Artifacts

### SigNoz Screenshots
- **Location:** `artifacts/signoz_YYYYMMDD/*.png`
- **Contents:**
  - Baseline log count query result
  - New config log count query result
  - Dashboard view showing ingestion rate
  - Service health indicators

### Raw Data Exports
- **Location:** `artifacts/metrics_YYYYMMDD/*.json`
- **Files:**
  - `baseline_trial_1.json` through `baseline_trial_5.json`
  - `new_trial_1.json` through `new_trial_5.json`
  - `summary_statistics.json`

### Test Scripts
- **Synthetic sender:** `<path/to/sender.ps1 or sender.py>`
- **Verification script:** `<path/to/verify.ps1>`
- **Command used:** 
  ```powershell
  <exact command with all parameters>
  ```

### Hashes & Verification
```
SHA256 (baseline config): <hash>
SHA256 (new config): <hash>
SHA256 (synthetic sender): <hash>
Git commit: <commit hash>
```

---

## ECRR Compliance

### Examine
- **Pre-flight checks:** Baseline drift verification, service health confirmed
- **Environment captured:** Hardware, OS, versions, power plan documented
- **Test plan reviewed:** Methodology peer-reviewed and approved

### Clean (N/A for read-only tests)
- No production changes; local testing only

### Report
- **This document:** Complete evidence pack with reproducible methodology
- **Artifacts:** Screenshots, raw data, hashes archived
- **Signature:** BossCat OEM approved, cursor{implementer} executed

### Role
- **Executor:** cursor{implementer}
- **Reviewer:** BossCat OEM
- **Date:** YYYY-MM-DD
- **Authority:** BossCat OEM performance measurement framework

---

## Usage in Production Copy

### Allowed Site Language (Evidence-Backed)

**Option A: With verified uplift**
```markdown
**Performance:** Synthetic OTLP ingest shows **up to 7× throughput improvement** 
(baseline vs. tuned config, median of 5 trials, identical hardware).  
**See evidence →** [EVIDENCE_YYYY-MM-DD.md](docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md)
```

**Option B: Without sufficient confidence**
```markdown
**Performance:** Thresholds met. Synthetic OTLP ingest baseline vs. tuned config 
shows measurable improvement (median: X → Y logs/sec, N=5 trials).  
**See evidence →** [EVIDENCE_YYYY-MM-DD.md](docs/ecrr/ECRR_REPORTS/EVIDENCE_YYYY-MM-DD.md)
```

### Banned Language (Unverified)
- ❌ "77× faster"
- ❌ "196.7 logs/sec" (derived from unverified 77×)
- ❌ Any claim without evidence link
- ❌ "Fastest" / "Best" without context

---

## Scope & Limitations

### What This Measures
- ✅ **Ingest path performance:** Synthetic logs → OTLP → Collector → SigNoz
- ✅ **Local setup:** Single-machine configuration (typical for development/testing)
- ✅ **Configuration impact:** Effect of tuned Collector parameters

### What This Does NOT Measure
- ❌ **Production scale:** Multi-node, distributed deployments
- ❌ **End-to-end application:** Only OTLP ingest path, not full observability stack
- ❌ **Query performance:** SigNoz dashboard/query speed not measured
- ❌ **Real-world workloads:** Synthetic logs only, not production traffic patterns

### Marketing Copy Guidance
Keep claims **scoped to the test**:
- ✅ "OTLP ingest throughput improved 7× with tuned configuration"
- ❌ "7× faster than other observability platforms"

---

## Reproducibility Checklist

- [ ] Baseline config committed to Git
- [ ] New config committed to Git
- [ ] Environment fully documented (hardware, OS, versions)
- [ ] Synthetic sender script available
- [ ] 5+ trials executed per variant
- [ ] Raw data exported and archived
- [ ] SigNoz screenshots captured
- [ ] Statistical confidence calculated (95% CI)
- [ ] Publication decision documented (threshold met/not met)
- [ ] ECRR compliance verified
- [ ] BossCat OEM approval obtained

---

## Approval

**Executor:** cursor{implementer}  
**Authority:** BossCat OEM  
**Date:** YYYY-MM-DD  
**Status:** [DRAFT / APPROVED]

**BossCat OEM Certification:**
> This evidence pack follows BossCat OEM performance measurement framework. All claims 
> derived from this measurement are evidence-backed and reproducible. Any site copy 
> referencing this evidence must link directly to this document.

---

**Seal:** 🐾 **BossCat OEM Performance Measurement Framework**  
**Template Version:** 1.0 (2025-10-20)

_Use this template for any future performance uplift campaigns. No claims without evidence._ 🚀🐾

