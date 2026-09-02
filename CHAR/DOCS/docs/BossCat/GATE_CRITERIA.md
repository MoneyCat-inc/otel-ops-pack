# BossCat Gate Criteria (Hard Gates)

- Performance: p95 < 500ms, error rate < 1%, throughput meets baseline (k6 thresholds)
- Resiliency: spike/stress recover; soak (≥30m) shows no leak/degradation
- Observability: HTTP/DB traces present; metrics captured; logs correlated with trace IDs
- Synthetic checks: canaries visible; chaos drill recovers to baseline
- ECRR: plan → preflight → edit → test → report; budgets respected

Artifacts

- Perf: `ALFA/TEST/load/k6/perf-gate-thresholds.js` (k6) and CI output (`gate-site-evidence.yml`)
- Synthetic trace: `scripts/synth-trace.ts` to OTLP `4318` (SigNoz collector); `5321` proves the Windows
  collector path
- Evidence: `artifacts/ecrr/gate/perf-verdict.json` (CI), `artifacts/gate-verification-results.json`
  (runtime; `DELT/ARTF/` holds dated copies)

