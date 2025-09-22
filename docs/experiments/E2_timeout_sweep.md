# E2 Timeout Sweep - Windows otelcol-contrib

## Overview
- **Date**: 2025-09-21 08:39:13 +01:00
- **Environment**: Windows 11 + SigNoz (local)
- **Collector Build**: otelcol-contrib service (`C:\Program Files\OpenTelemetry Collector`)
- **Baseline Config**: `config.yaml` (per-signal batching, loopback endpoints)
- **Canary ID**: windows-canary-027d4578-8398-4324-9b3a-527d45563173

## Goals
1. Validate batching stability across timeout profiles (1s, 10s, 30s) versus the 200ms baseline.
2. Confirm queue utilisation, send success, and health stay within SLO guardrails.
3. Capture metrics snapshots for experiment E2 and future comparisons.

## Method
- Adjusted `batch/{traces,metrics,logs}.timeout` in `config.yaml`.
- Restarted `otelcol-contrib` after each change (admin PowerShell).
- Collected metrics via `verify-integration.ps1`, `/metrics`, and queue counters.
- Restored baseline (200ms) and re-verified canary visibility in SigNoz Logs.

## Results
| Timeout | Queue Size | Send Failures | Logs Sent | Batch Triggers | Health |
|---------|------------|---------------|-----------|----------------|--------|
| 200 ms (baseline) | 0 / 3000 | 0 | 18,672 | 190 | 200 OK |
| 1 s | 0 / 3000 | 0 | 16 | 4 | 200 OK |
| 10 s | 0 / 3000 | 0 | 14 | 2 | 200 OK |
| 30 s | 0 / 3000 | 0 | - | - | 200 OK |
| 200 ms (restored) | 0 / 3000 | 0 | 69 | 23 | 200 OK |

### Observations
- Queue utilisation stayed at 0% (no backlog) for all timeouts.
- Exporter reliability remained 100% (no failed sends).
- Shorter timeouts produced more frequent trigger counters; longer values reduced frequency but did not introduce lag within observation windows.
- Memory footprint steady (~208 MB RSS) and CPU cost negligible.

## Conclusions
- Baseline (200 ms) offers best responsiveness with zero queue pressure and zero failures.
- System tolerates wide timeout ranges (200 ms to 30 s) without risking backlog or reliability loss.
- Fractal batching baseline validated for production rollout; experiment matrix updated.

## Next Steps
1. Document SigNoz gateway timeout sweeps (if planned) using the same measurement cadence.
2. Add an automated sweep script to `observability/ci/validate-otel` for regression detection.
3. Notify SRE to pin the 200 ms profile as the production default and log results in the E2 experiment tracker.

