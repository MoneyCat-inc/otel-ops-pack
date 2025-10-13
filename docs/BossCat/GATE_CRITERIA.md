# BossCat Gate Criteria (Hard Gates)

- Performance: p95 < 500ms, error rate < 1%, throughput meets baseline (k6 thresholds)
- Resiliency: spike/stress recover; soak (≥30m) shows no leak/degradation
- Observability: HTTP/DB traces present; metrics captured; logs correlated with trace IDs
- Synthetic checks: canaries visible; chaos drill recovers to baseline
- ECRR: plan → preflight → edit → test → report; budgets respected

Artifacts
- Perf: `tests/perf/gate.js` (k6) and CI output
- Synthetic trace: `scripts/synth-trace.ts` to OTLP 14318
- Evidence: `artifacts/ecrr/gate/LATEST.md`, `DELT/ARTF/gate-verification-results.json`

